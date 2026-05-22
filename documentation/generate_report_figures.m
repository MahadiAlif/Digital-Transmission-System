clear; close all; clc;

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'filters'));
addpath(fullfile(projectRoot, 'modulation'));
addpath(fullfile(projectRoot, 'plotting'));
addpath(fullfile(projectRoot, 'simulation'));
addpath(fullfile(projectRoot, 'utils'));

rng(11);

cfg = lab2Config(projectRoot);
cfg.Mlist = [2 4 8 16];
cfg.EbN0dB = 0:4:32;
cfg.numBitsValidation = 5e4;
cfg.numBitsOptimization = 2e4;
cfg.singlePoleBw = linspace(0.12, 1.8, 9);
cfg.resultsDir = fullfile(projectRoot, 'documentation', 'figures');

if ~exist(cfg.resultsDir, 'dir')
    mkdir(cfg.resultsDir);
end

pulses = buildTxPulses(cfg);

plotFilterSynthesisEvidence(cfg, pulses);
plotPulsePsd(cfg, pulses);

validation = runMatchedFilterValidation(cfg, pulses);
optimization = runSinglePoleOptimization(cfg, pulses);

save(fullfile(cfg.resultsDir, 'report_results.mat'), 'cfg', 'pulses', ...
    'validation', 'optimization');

fprintf('\nReport figures saved in %s\n', cfg.resultsDir);
