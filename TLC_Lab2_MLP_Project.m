clear; close all; clc;

% TLC Virtual LAB#2 - Thesis Extension: MLP Non-Linear Equalizer for PAM-16.
% Resolves the PAM-16 single-pole receiver failure.
% Results are saved in ./results_lab2.

projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'filters'));
addpath(fullfile(projectRoot, 'modulation'));
addpath(fullfile(projectRoot, 'plotting'));
addpath(fullfile(projectRoot, 'simulation'));
addpath(fullfile(projectRoot, 'utils'));

rng(7); % Set seed for reproducibility

% Load original project configurations
cfg = lab2Config(projectRoot);
pulses = buildTxPulses(cfg);

% Run the new MLP-Assisted validation runner
mlpResults = runMlpAssistedValidation(cfg, pulses);

% Save MLP results to a separate MAT file
save(fullfile(cfg.resultsDir, 'lab2_mlp_results.mat'), 'cfg', 'pulses', 'mlpResults');

fprintf('\nMLP thesis extension done. Results saved in %s\n', cfg.resultsDir);
