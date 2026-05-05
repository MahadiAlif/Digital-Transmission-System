function plotFilterSynthesisEvidence(cfg, pulses)
fig = figure('Name', 'Digital filter synthesis evidence', 'Color', 'w');
tiledlayout(2, 1);

nexttile;
[B, A] = singlePoleImpulseInvariance(0.5, cfg.SpS);
[H, f] = freqz(B, A, 4096, cfg.SpS);
Ha = 1 ./ sqrt(1 + (f / 0.5).^2);
plot(f, 20 * log10(abs(H) + eps), 'LineWidth', 1.2);
hold on; grid on;
plot(f, 20 * log10(Ha + eps), '--', 'LineWidth', 1.0);
xlim([0 3]);
ylim([-35 2]);
xlabel('Normalized frequency f/R_s');
ylabel('|H(f)| [dB]');
title('Single-pole impulse invariance, f_{3dB}=0.5 R_s');
legend('digital', 'analog target');

nexttile;
[Hn, fn] = freqz(pulses.NRZ, 1, 4096, cfg.SpS);
[Hs, fs] = freqz(pulses.SRRC, 1, 4096, cfg.SpS);
plot(fn, 20 * log10(abs(Hn) / max(abs(Hn)) + eps), 'LineWidth', 1.1);
hold on; grid on;
plot(fs, 20 * log10(abs(Hs) / max(abs(Hs)) + eps), 'LineWidth', 1.1);
xline((1 + cfg.srrcBeta) / 2, ':', 'SRRC occupied band');
xlim([0 3]);
ylim([-60 3]);
xlabel('Normalized frequency f/R_s');
ylabel('Normalized |H(f)| [dB]');
title('Pulse-shaping filters in the signal band');
legend('NRZ', 'SRRC');

saveas(fig, fullfile(cfg.resultsDir, 'filter_synthesis_evidence.png'));
end
