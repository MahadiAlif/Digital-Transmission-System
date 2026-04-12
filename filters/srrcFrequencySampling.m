function h = srrcFrequencySampling(beta, spanSymbols, SpS)
N = spanSymbols * SpS + 1;
if mod(N, 2) == 0
    N = N + 1;
end

freq = (-floor(N / 2):floor(N / 2)).' / N * SpS;
af = abs(freq);
Hrc = zeros(size(freq));

pass = af <= (1 - beta) / 2;
roll = af > (1 - beta) / 2 & af <= (1 + beta) / 2;
Hrc(pass) = 1;
Hrc(roll) = 0.5 * (1 + cos(pi / beta * (af(roll) - (1 - beta) / 2)));

Hsrrc = sqrt(Hrc);
h = fftshift(real(ifft(ifftshift(Hsrrc))));
h = h(:).' .* hammingLocal(numel(h)).';
h = h / sqrt(sum(h.^2));
end
