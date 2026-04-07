function cfg = lab2Config(projectRoot)
cfg.Mlist = [2 4 8 16];
cfg.SpS = 16;
cfg.srrcBeta = 0.25;
cfg.srrcSpan = 12;                 % symbols
cfg.EbN0dB = 0:2:22;
cfg.berTarget = 1e-3;
cfg.numBitsValidation = 2e5;       % increase for final reports if needed
cfg.numBitsOptimization = 1e5;
cfg.minErrorsHint = 100;
cfg.singlePoleBw = linspace(0.08, 2.0, 25); % normalized to Rs
cfg.resultsDir = fullfile(projectRoot, 'results_lab2');

if strcmpi(getenv('TLC_LAB2_FAST'), '1')
    cfg.Mlist = [2 4];
    cfg.EbN0dB = 0:6:18;
    cfg.numBitsValidation = 2e4;
    cfg.numBitsOptimization = 1e4;
    cfg.singlePoleBw = linspace(0.15, 1.5, 6);
end

if ~exist(cfg.resultsDir, 'dir')
    mkdir(cfg.resultsDir);
end
end
