clear; close all; clc;

% TLC Virtual LAB#2 - IEEE Journal Validation Entry Point.
% Evaluates the proposed Volterra-PWL-MLP Equalizer under severe non-linear ISI.
% Generates final comparative plots and complexity statistics.

projectRoot = fileparts(mfilename('fullpath'));
addpath(fullfile(projectRoot, 'config'));
addpath(fullfile(projectRoot, 'filters'));
addpath(fullfile(projectRoot, 'modulation'));
addpath(fullfile(projectRoot, 'plotting'));
addpath(fullfile(projectRoot, 'simulation'));
addpath(fullfile(projectRoot, 'utils'));

rng(7); % Set seed for reproducibility

% Load standard project config
cfg = lab2Config(projectRoot);
pulses = buildTxPulses(cfg);

% Run the IEEE Journal Equalizer Validation Framework
runJournalEqualizerValidation(cfg, pulses);

fprintf('\nJournal project run complete. Figures saved in %s\n', cfg.resultsDir);
