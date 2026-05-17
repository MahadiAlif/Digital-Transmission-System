function ber = theoreticalPamBer(M, EbN0dB)
bps = log2(M);
EbN0 = 10.^(EbN0dB / 10);
arg = sqrt(6 * bps ./ (M^2 - 1) .* EbN0);
ber = 2 * (M - 1) / (M * bps) * qfunLocal(arg);
end
