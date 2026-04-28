function out = simulatePamAwgn(M, numBits, EbN0dB, SpS, txPulse, rxB, rxA)
if nargin < 7
    rxA = 1;
end

bps = log2(M);
numBits = floor(numBits / bps) * bps;
bitsTx = randi([0 1], numBits, 1);
[symbolsTx, alphabet] = pamGrayMap(bitsTx, M);

w = zeros(numel(symbolsTx) * SpS, 1);
w(1:SpS:end) = symbolsTx;
xTx = filter(txPulse, 1, w);
yClean = filter(rxB, rxA, xTx);

sync = findBestPamSampling(yClean, symbolsTx, alphabet, SpS);

EbN0 = 10.^(EbN0dB / 10);
Eb = mean(alphabet.^2) / bps;
N0 = Eb / EbN0;
noiseSigma = sqrt(N0 / 2);

y = filter(rxB, rxA, xTx + noiseSigma * randn(size(xTx)));
[samples, symbolsAligned, bitsAligned] = takeAlignedSamples(y, symbolsTx, ...
    bitsTx, bps, sync, SpS);

symbolsRx = decideNearest(samples, sync.centroids, alphabet);
bitsRx = pamGrayDemap(symbolsRx, M, alphabet);

usableBits = min(numel(bitsAligned), numel(bitsRx));
bitsAligned = bitsAligned(1:usableBits);
bitsRx = bitsRx(1:usableBits);
usableSymbols = floor(usableBits / bps);

symTx = symbolsAligned(1:usableSymbols);
symRx = symbolsRx(1:usableSymbols);

out.ber = mean(bitsRx ~= bitsAligned);
out.ser = mean(symRx ~= symTx);
out.numBits = usableBits;
out.numBitErrors = sum(bitsRx ~= bitsAligned);
out.samples = samples;
out.symbolsTx = symbolsAligned;
out.sync = sync;
end
