function results = runMlpAssistedValidation(cfg, pulses)
    % runMlpAssistedValidation: Evaluates MLP and LMS equalizers for PAM-16.
    % Under severe ISI (single-pole receiver) and non-linear distortion.
    
    fprintf('\n==================================================\n');
    fprintf('Running MLP-Assisted PAM-16 Equalizer Evaluation\n');
    fprintf('==================================================\n');
    
    % 1. Simulation settings
    M = 16; % Target PAM-16 where single-pole baseline fails to meet 1e-3 BER
    bps = log2(M);
    pulseName = 'SRRC';
    txPulse = pulses.(pulseName);
    rxPulse = fliplr(txPulse);
    
    % We use a narrow single-pole filter to generate severe ISI
    targetBw = 0.54; 
    [rxB, rxA] = singlePoleImpulseInvariance(targetBw, cfg.SpS);
    
    % Non-linear channel distortion parameter (Saleh-like 3rd order compression)
    % Set to 0.0 to evaluate pure linear ISI, or 0.05 for non-linear ISI
    useNonLinearity = true;
    alpha = 0.05; 
    
    L = 5; % Window radius (W = 2*L + 1 = 11 inputs)
    W = 2*L + 1;
    
    % 2. Generate training data at a moderate SNR (20 dB)
    fprintf('Generating training data (50k symbols) at Eb/N0 = 20 dB...\n');
    numTrainBits = 50000 * bps;
    trainOut = simulatePamAwgnWithDistortion(M, numTrainBits, 20, cfg.SpS, txPulse, rxB, rxA, useNonLinearity, alpha);
    
    % Build sliding window inputs and targets
    X_train = formSlidingWindow(trainOut.samples, L);
    Y_train = trainOut.symbolsTx;
    
    % 3. Train MLP Equalizer (Scratch Implementation)
    fprintf('Training MLP Equalizer (hidden: 15 -> 10, lr: 0.01, epochs: 120)...\n');
    mlp = mlpEqualizerScratch();
    hidden1 = 15;
    hidden2 = 10;
    epochs = 120;
    lr = 0.01;
    batchSize = 64;
    
    [W1, b1, W2, b2, W3, b3] = mlp.train(X_train, Y_train, hidden1, hidden2, epochs, lr, batchSize);
    
    % 4. Train LMS Equalizer (Linear Baseline)
    fprintf('Training LMS Linear Equalizer (11 taps, mu: 0.01)...\n');
    [~, w_lms] = lmsEqualizer(trainOut.samples, Y_train, W, 0.01);
    
    % 5. Test Performance across different Eb/N0
    ebn0_list = 10:2:24;
    ber_none = zeros(size(ebn0_list));
    ber_lms = zeros(size(ebn0_list));
    ber_mlp = zeros(size(ebn0_list));
    
    fprintf('\nEvaluating equalizers over Eb/N0 sweep...\n');
    for k = 1:numel(ebn0_list)
        EbN0_val = ebn0_list(k);
        testOut = simulatePamAwgnWithDistortion(M, cfg.numBitsValidation, EbN0_val, cfg.SpS, txPulse, rxB, rxA, useNonLinearity, alpha);
        
        % A. Baseline (No Equalization)
        ber_none(k) = testOut.ber;
        
        % B. LMS Equalization
        X_test = formSlidingWindow(testOut.samples, L);
        y_lms = zeros(length(testOut.samples), 1);
        for i = 1:length(testOut.samples)
            y_lms(i) = w_lms.' * X_test(i, :).';
        end
        sym_lms = decideNearest(y_lms, testOut.alphabet, testOut.alphabet);
        bits_lms = pamGrayDemap(sym_lms, M, testOut.alphabet);
        ber_lms(k) = mean(bits_lms ~= testOut.symbolsTxBits);
        
        % MLP stub
    end
end

function out = simulatePamAwgnWithDistortion(M, numBits, EbN0dB, SpS, txPulse, rxB, rxA, useNonLinearity, alpha)
    % Custom local transceiver simulator supporting non-linear transmitter compression.
    bps = log2(M);
    numBits = floor(numBits / bps) * bps;
    bitsTx = randi([0 1], numBits, 1);
    [symbolsTx, alphabet] = pamGrayMap(bitsTx, M);
    
    w = zeros(numel(symbolsTx) * SpS, 1);
    w(1:SpS:end) = symbolsTx;
    xTx = filter(txPulse, 1, w);
    
    % Apply non-linear HPA distortion if enabled
    if useNonLinearity
        xTx = xTx - alpha * (xTx.^3);
    end
    
    yClean = filter(rxB, rxA, xTx);
    sync = findBestPamSampling(yClean, symbolsTx, alphabet, SpS);
    
    EbN0 = 10.^(EbN0dB / 10);
    Eb = mean(alphabet.^2) / bps;
    N0 = Eb / EbN0;
    noiseSigma = sqrt(N0 / 2);
    
    % Channel noise addition
    noise = noiseSigma * randn(size(xTx));
    y = filter(rxB, rxA, xTx + noise);
    
    [samples, symbolsAligned, bitsAligned] = takeAlignedSamples(y, symbolsTx, bitsTx, bps, sync, SpS);
    
    % Decision and demapping to compute baseline BER
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