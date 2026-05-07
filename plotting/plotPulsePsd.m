function plotPulsePsd(cfg, pulses)
names = fieldnames(pulses);
M = 4;
numBits = 5e4;
fig = figure('Name', 'Transmit PSD', 'Color', 'w');
hold on; grid on;

for p = 1:numel(names)
    [symbols, ~] = pamGrayMap(randi([0 1], numBits, 1), M);
    w = zeros(numel(symbols) * cfg.SpS, 1);
    w(1:cfg.SpS:end) = symbols;
    x = filter(pulses.(names{p}), 1, w);
    [f, Pxx] = simplePsd(x, cfg.SpS);
    plot(f, 10 * log10(Pxx / max(Pxx) + eps), 'LineWidth', 1.2, ...
        'DisplayName', names{p});
end

xlim([-3 3]);
ylim([-80 5]);
xlabel('Normalized frequency f/R_s');
ylabel('PSD [dB, normalized]');
title('Transmit power spectral density, PAM-4');
legend('Location', 'southwest');
saveas(fig, fullfile(cfg.resultsDir, 'tx_psd.png'));
end
