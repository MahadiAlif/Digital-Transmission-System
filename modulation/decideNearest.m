function decided = decideNearest(samples, centroids, alphabet)
decided = zeros(size(samples));
for k = 1:numel(samples)
    [~, idx] = min(abs(samples(k) - centroids));
    decided(k) = alphabet(idx);
end
end
