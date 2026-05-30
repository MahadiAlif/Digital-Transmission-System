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
    % Test code stub
end

function out = simulatePamAwgnWithDistortion(M, numBits, EbN0dB, SpS, txPulse, rxB, rxA, useNonLinearity, alpha)
    bps = log2(M);
    numBits = floor(numBits / bps) * bps;
    bitsTx = randi([0 1], numBits, 1);
    [symbolsTx, alphabet] = pamGrayMap(bitsTx, M);
    w = zeros(numel(symbolsTx) * SpS, 1);
    w(1:SpS:end) = symbolsTx;
    xTx = filter(txPulse, 1, w);
    yClean = filter(rxB, rxA, xTx);
    sync = findBestPamSampling(yClean, symbolsTx, alphabet, SpS);
    out.samples = yClean;
    out.symbolsTx = symbolsTx;
end
