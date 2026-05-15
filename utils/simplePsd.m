function [f, Pxx] = simplePsd(x, SpS)
nfft = 8192;
x = x(:) - mean(x);
if numel(x) < nfft
    x(end + 1:nfft) = 0;
end
step = nfft / 2;
numSeg = floor((numel(x) - nfft) / step) + 1;
win = hammingLocal(nfft);
Pxx = zeros(nfft, 1);
for k = 1:numSeg
    idx = (1:nfft) + (k - 1) * step;
    X = fftshift(fft(x(idx) .* win, nfft));
    Pxx = Pxx + abs(X).^2 / sum(win.^2);
end
Pxx = Pxx / max(numSeg, 1);
f = (-nfft / 2:nfft / 2 - 1).' / nfft * SpS;
end
