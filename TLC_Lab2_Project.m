clear; close all; clc;

% TLC Virtual LAB#2 - modular PAM-M digital transmission simulator.
% Results are saved in ./results_lab2.

projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'filters'));
addpath(fullfile(projectRoot, 'modulation'));
addpath(fullfile(projectRoot, 'plotting'));
addpath(fullfile(projectRoot, 'simulation'));
addpath(fullfile(projectRoot, 'utils'));

rng(7);

cfg = lab2Config(projectRoot);
pulses = buildTxPulses(cfg);

plotFilterSynthesisEvidence(cfg, pulses);
plotPulsePsd(cfg, pulses);

validation = runMatchedFilterValidation(cfg, pulses);
optimization = runSinglePoleOptimization(cfg, pulses);

save(fullfile(cfg.resultsDir, 'lab2_results.mat'), 'cfg', 'pulses', ...
    'validation', 'optimization');

fprintf('\nDone. Results saved in %s\n', cfg.resultsDir);
