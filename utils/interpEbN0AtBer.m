function value = interpEbN0AtBer(EbN0dB, ber, target)
ber = max(ber, realmin);
if all(ber > target) || all(ber < target)
    value = NaN;
    return;
end

x = log10(ber(:));
y = EbN0dB(:);
[xUnique, ia] = unique(x, 'stable');
yUnique = y(ia);
if numel(xUnique) < 2
    value = NaN;
else
    value = interp1(xUnique, yUnique, log10(target), 'linear');
end
end
