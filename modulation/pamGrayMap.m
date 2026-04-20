function [symbols, alphabet] = pamGrayMap(bits, M)
bps = log2(M);
alphabet = (-(M - 1):2:(M - 1)).';
alphabet = alphabet / sqrt(mean(alphabet.^2));
bitGroups = reshape(bits, bps, []).';
binaryIndex = bitGroups * (2.^(bps - 1:-1:0)).';
grayIndex = bitxor(binaryIndex, floor(binaryIndex / 2));
symbols = alphabet(grayIndex + 1);
end
