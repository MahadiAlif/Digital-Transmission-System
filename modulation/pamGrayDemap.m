function bits = pamGrayDemap(symbols, M, alphabet)
bps = log2(M);
idx = zeros(numel(symbols), 1);
for k = 1:numel(symbols)
    [~, idx(k)] = min(abs(symbols(k) - alphabet));
end
grayIndex = idx - 1;
binaryIndex = grayToBinary(grayIndex);
bits = zeros(numel(symbols), bps);
for b = 1:bps
    bits(:, b) = bitget(binaryIndex, bps - b + 1);
end
bits = reshape(bits.', [], 1);
end
