function sync = findBestPamSampling(yClean, symbols, alphabet, SpS)
maxLag = min(6 * SpS, floor(numel(yClean) / SpS) - 10);
bestScore = inf;
sync = struct('offset', 1, 'lag', 0, 'centroids', alphabet);

for offset = 1:SpS
    stream = yClean(offset:SpS:end);
    for lag = 0:maxLag
        n = min(numel(symbols), numel(stream) - lag);
        if n < 50
            continue;
        end

        s = stream(lag + (1:n));
        a = symbols(1:n);
        centroids = zeros(size(alphabet));
        for k = 1:numel(alphabet)
            idx = a == alphabet(k);
            centroids(k) = mean(s(idx));
        end

        if any(~isfinite(centroids)) || any(diff(centroids) <= 0)
            continue;
        end

        predicted = interp1(alphabet, centroids, a, 'linear', 'extrap');
        eyeOpening = min(diff(centroids));
        score = mean((s - predicted).^2) / max(eyeOpening^2, eps) - 0.05 * eyeOpening;

        if score < bestScore
            bestScore = score;
            sync.offset = offset;
            sync.lag = lag;
            sync.centroids = centroids;
        end
    end
end
end
