function [samples, symbolsAligned, bitsAligned] = takeAlignedSamples(y, symbols, bits, bps, sync, SpS)
stream = y(sync.offset:SpS:end);
first = sync.lag + 1;
availableSymbols = min(numel(symbols), numel(stream) - sync.lag);
samples = stream(first:first + availableSymbols - 1);
symbolsAligned = symbols(1:availableSymbols);
bitsAligned = bits(1:availableSymbols * bps);
end
