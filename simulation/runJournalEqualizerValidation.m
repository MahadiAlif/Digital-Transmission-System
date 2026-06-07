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
    
    fprintf('\nEvaluating all models over Eb/N0 sweep...\n');
    for k = 1:numel(ebn0_list)
        EbN0_val = ebn0_list(k);
        testOut = simulatePamAwgnWithDistortion(M, cfg.numBitsValidation, EbN0_val, cfg.SpS, txPulse, rxB, rxA, useNonLinearity, alpha);
        
        % A. Baseline (No Equalizer)
        ber_none(k) = testOut.ber;
        
        % B. LMS Equalizer
        X_test_std = formSlidingWindow(testOut.samples, L_std);
        y_lms = zeros(length(testOut.samples), 1);
        for i = 1:length(testOut.samples)
            y_lms(i) = w_lms.' * X_test_std(i, :).';
        end
        sym_lms = decideNearest(y_lms, testOut.alphabet, testOut.alphabet);
        bits_lms = pamGrayDemap(sym_lms, M, testOut.alphabet);
        ber_lms(k) = mean(bits_lms ~= testOut.symbolsTxBits);
        
        % C. Standard MLP Equalizer
        y_mlp_std = mlpStd.predict(X_test_std, W1_std, b1_std, W2_std, b2_std, W3_std, b3_std);
        sym_mlp_std = decideNearest(y_mlp_std, testOut.alphabet, testOut.alphabet);
        bits_mlp_std = pamGrayDemap(sym_mlp_std, M, testOut.alphabet);
        ber_mlp_std(k) = mean(bits_mlp_std ~= testOut.symbolsTxBits);
        
        % D. Proposed Volterra-PWL-MLP Equalizer
        X_test_volt = extractVolterraFeatures(testOut.samples, D_volt);
        y_mlp_v = vMlp.predict(X_test_volt, W1_v, b1_v, W2_v, b2_v);
        sym_mlp_v = decideNearest(y_mlp_v, testOut.alphabet, testOut.alphabet);
        bits_mlp_v = pamGrayDemap(sym_mlp_v, M, testOut.alphabet);
        ber_mlp_volt(k) = mean(bits_mlp_v ~= testOut.symbolsTxBits);
        
        fprintf('  Eb/N0 = %d dB | Baseline: %.5f | LMS: %.5f | Std MLP: %.5f | Proposed Volterra-PWL-MLP: %.5f\n', ...
            EbN0_val, ber_none(k), ber_lms(k), ber_mlp_std(k), ber_mlp_volt(k));
    end
    
    % 6. Save data structure
    results.ebn0_list = ebn0_list;
    results.ber_none = ber_none;
    results.ber_lms = ber_lms;
    results.ber_mlp_std = ber_mlp_std;
    results.ber_mlp_volt = ber_mlp_volt;
    save(fullfile(cfg.resultsDir, 'journal_evaluation_results.mat'), 'results');
    
    % 7. Plot Comparative BER Curves
    fig1 = figure('Name', 'IEEE Journal BER Comparison', 'Color', 'w');
    semilogy(ebn0_list, ber_none, 'r-o', 'LineWidth', 1.5, 'DisplayName', 'No Equalizer (Baseline)'); hold on; grid on;
    semilogy(ebn0_list, ber_lms, 'b--d', 'LineWidth', 1.5, 'DisplayName', 'LMS Linear Equalizer');
    semilogy(ebn0_list, ber_mlp_std, 'k-^', 'LineWidth', 1.5, 'DisplayName', 'Standard Float MLP (11x15x10x1)');
    semilogy(ebn0_list, ber_mlp_volt, 'g-s', 'LineWidth', 2.0, 'DisplayName', 'Proposed Volterra-PWL-MLP (10x5x1)');
    yline(cfg.berTarget, 'm:', 'Target BER (10^{-3})', 'LineWidth', 1.2);
    xlabel('E_b/N_0 [dB]'); ylabel('Bit Error Rate (BER)');
    title('PAM-16 Equalizer Performance in Non-linear HPA Channel');
    ylim([1e-4 1]); legend('Location', 'southwest');
    saveas(fig1, fullfile(cfg.resultsDir, 'journal_ber_curves.png'));
    
    % 8. Computational Complexity Analysis (Multiplication Count per Symbol)
    % LMS: 11 mults
    % Standard MLP: 11 inputs * 15 + 15 * 10 + 10 * 1 = 325 mults (+ CORDIC tanh)
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
