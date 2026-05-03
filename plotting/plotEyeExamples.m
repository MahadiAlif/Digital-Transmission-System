function plotEyeExamples(cfg, txPulse, rxB, M, EbN0dB, tag, rxA)
if nargin < 7
    rxA = 1;
end

numBits = 4000;
bps = log2(M);
bits = randi([0 1], floor(numBits / bps) * bps, 1);
[symbols, alphabet] = pamGrayMap(bits, M);
w = zeros(numel(symbols) * cfg.SpS, 1);
w(1:cfg.SpS:end) = symbols;
x = filter(txPulse, 1, w);
clean = filter(rxB, rxA, x);
sync = findBestPamSampling(clean, symbols, alphabet, cfg.SpS);

Eb = mean(alphabet.^2) / bps;
N0 = Eb / 10^(EbN0dB / 10);
noisy = filter(rxB, rxA, x + sqrt(N0 / 2) * randn(size(x)));

fig = figure('Name', ['Eye - ' tag], 'Color', 'w');
tiledlayout(1, 2);
nexttile;
drawEye(clean, cfg.SpS, sync.offset + sync.lag * cfg.SpS, ...
    sprintf('%s noiseless', strrep(tag, '_', '\_')));
nexttile;
drawEye(noisy, cfg.SpS, sync.offset + sync.lag * cfg.SpS, ...
    sprintf('%s at E_b/N_0 %.2f dB', strrep(tag, '_', '\_'), EbN0dB));

saveas(fig, fullfile(cfg.resultsDir, ['eye_' tag '.png']));
end
