function runJournalEqualizerValidation(cfg, pulses)
    % runJournalEqualizerValidation: Generates all comparative curves and complexity analyses
    % for the proposed Volterra-PWL-MLP Journal Paper.
    
    fprintf('\n========================================================\n');
    fprintf('Running IEEE Journal Equalizer Validation Framework\n');
    fprintf('========================================================\n');
    
    M = 16;
    bps = log2(M);
    pulseName = 'SRRC';
    txPulse = pulses.(pulseName);
    rxPulse = fliplr(txPulse);
    
    % Narrow single-pole receiver filter causing strong ISI
    targetBw = 0.54;
    [rxB, rxA] = singlePoleImpulseInvariance(targetBw, cfg.SpS);
    
    % Strong non-linear HPA compression coefficient (to show LMS failure)
    useNonLinearity = true;
    alpha = 0.12; 
    
    % Parameters for Standard MLP
    L_std = 5; % Input window size W = 11
    hidden1_std = 15;
    hidden2_std = 10;
    
    % Parameters for Proposed Volterra-PWL-MLP
    D_volt = 4; % Memory depth D = 4 -> 10 features (5 linear, 4 quadratic, 1 cubic)
    hidden_volt = 5; % Tiny hidden layer
    
    % 1. Generate Training Data at Eb/N0 = 22 dB
    fprintf('Generating training dataset (60k symbols) at Eb/N0 = 22 dB...\n');
    numTrainBits = 60000 * bps;
    trainOut = simulatePamAwgnWithDistortion(M, numTrainBits, 22, cfg.SpS, txPulse, rxB, rxA, useNonLinearity, alpha);
    
    % 2. Train LMS Equalizer
    fprintf('Training LMS Linear Equalizer (11 taps)...\n');
    [~, w_lms] = lmsEqualizer(trainOut.samples, trainOut.symbolsTx, 11, 0.005);
    
    % 3. Train Standard MLP (Float Tanh)
    fprintf('Training Standard MLP (11 inputs, hidden: 15 -> 10, Standard Tanh)...\n');
    X_train_std = formSlidingWindow(trainOut.samples, L_std);
    mlpStd = mlpEqualizerScratch();
    [W1_std, b1_std, W2_std, b2_std, W3_std, b3_std] = mlpStd.train(X_train_std, trainOut.symbolsTx, ...
        hidden1_std, hidden2_std, 120, 0.01, 64);
    
    % 4. Train Proposed Volterra-PWL-MLP (10 inputs, hidden: 5, PWL-Tanh)
    fprintf('Training Proposed Volterra-PWL-MLP (10 inputs, hidden: 5, PWL-Tanh)...\n');
    X_train_volt = extractVolterraFeatures(trainOut.samples, D_volt);
    vMlp = volterraMlpEqualizer();
    [W1_v, b1_v, W2_v, b2_v] = vMlp.train(X_train_volt, trainOut.symbolsTx, ...
        hidden_volt, 120, 0.01, 64);
    
    % 5. Test Performance Sweep
    ebn0_list = 10:2:24;
    ber_none = zeros(size(ebn0_list));
    ber_lms = zeros(size(ebn0_list));
    ber_mlp_std = zeros(size(ebn0_list));
    ber_mlp_volt = zeros(size(ebn0_list));
    % Sweep stub
end

    % Proposed Volterra-PWL-MLP:
    %   - Feature extraction: 4 quadratic mults + 1 cubic mult = 5 mults
    %   - Layer 1: 10 inputs * 5 neurons = 50 mults (activations are multiplier-free PWL!)
    %   - Layer 2: 5 neurons * 1 output = 5 mults
    %   - Total: 5 + 50 + 5 = 60 mults
    
    mult_counts = [11, 325, 60];
    labels = {'LMS Linear', 'Standard MLP', 'Proposed Volterra-PWL-MLP'};
    
    fig2 = figure('Name', 'Computational Complexity Comparison', 'Color', 'w');
    bar(mult_counts, 0.5, 'FaceColor', [0.15 0.55 0.85]);
    set(gca, 'XTickLabel', labels);
    ylabel('Number of Multiplications per Symbol');
    title('Computational Complexity Analysis (DSP Overhead)');
    grid on;
    % Add text labels on top of bars
    for i = 1:numel(mult_counts)
        text(i, mult_counts(i) + 10, num2str(mult_counts(i)), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    end
    saveas(fig2, fullfile(cfg.resultsDir, 'journal_complexity_comparison.png'));
    
    fprintf('\nJournal validation plots saved successfully to: %s\n', cfg.resultsDir);
end

function out = simulatePamAwgnWithDistortion(M, numBits, EbN0dB, SpS, txPulse, rxB, rxA, useNonLinearity, alpha)
    bps = log2(M);
    numBits = floor(numBits / bps) * bps;
    bitsTx = randi([0 1], numBits, 1);
    [symbolsTx, alphabet] = pamGrayMap(bitsTx, M);
    
    w = zeros(numel(symbolsTx) * SpS, 1);
    w(1:SpS:end) = symbolsTx;
    xTx = filter(txPulse, 1, w);
    
    if useNonLinearity
        xTx = xTx - alpha * (xTx.^3);
    end
    
    yClean = filter(rxB, rxA, xTx);
    sync = findBestPamSampling(yClean, symbolsTx, alphabet, SpS);
    
    EbN0 = 10.^(EbN0dB / 10);
    Eb = mean(alphabet.^2) / bps;
    N0 = Eb / EbN0;
    noiseSigma = sqrt(N0 / 2);
    
    y = filter(rxB, rxA, xTx + noiseSigma * randn(size(xTx)));
    
    [samples, symbolsAligned, bitsAligned] = takeAlignedSamples(y, symbolsTx, bitsTx, bps, sync, SpS);
    
    % Slicer and Demapping
    symbolsRx = decideNearest(samples, sync.centroids, alphabet);
    bitsRx = pamGrayDemap(symbolsRx, M, alphabet);
    
    usableBits = min(numel(bitsAligned), numel(bitsRx));
    bitsAligned = bitsAligned(1:usableBits);
    bitsRx = bitsRx(1:usableBits);
    
    out.samples = samples;
    out.symbolsTx = symbolsAligned;
    out.symbolsTxBits = bitsAligned;
    out.sync = sync;
    out.alphabet = alphabet;
    out.ber = mean(bitsRx ~= bitsAligned);
end