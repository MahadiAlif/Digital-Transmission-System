function X_feat = extractVolterraFeatures(samples, D)
    % extractVolterraFeatures: Generates low-order non-linear Volterra features.
    % Inputs:
    %   samples: vector of received symbol-rate samples (length N)
    %   D: memory depth (number of past symbols to consider)
    % Outputs:
    %   X_feat: matrix of size N x V containing linear and non-linear features.
    
    N = length(samples);
    padded = [zeros(D, 1); samples(:)];
    
    % Feature counts:
    % - Linear terms: y(k), y(k-1), ..., y(k-D) -> D+1 terms
    % - Quadratic cross-terms: y(k)*y(k-1), y(k-1)*y(k-2), ..., y(k)*y(k-2)...
    % For a manageable complexity, we will select:
    % 1. Linear taps: y(k-d) for d = 0...D
    % 2. Major Quadratic taps: y(k)*y(k-d) for d = 1...D
    % 3. Major Cubic tap: y(k)^3 (self-nonlinearity)
    
    numLinear = D + 1;
    numQuadratic = D;
    numCubic = 1;
    totalFeatures = numLinear + numQuadratic + numCubic;
    
    X_feat = zeros(N, totalFeatures);
    for k = 1:N
        % Get sliding window of size D+1 from current and past samples
        % win contains: [y(k-D), ..., y(k-1), y(k)]
        win = padded(k : k + D);
        win_rev = flipud(win); % win_rev contains: [y(k), y(k-1), ..., y(k-D)]
        
        % 1. Linear features
        X_feat(k, 1:numLinear) = win_rev.';
        
        % 2. Quadratic features: y(k)*y(k-d) for d = 1...D
        quad = zeros(1, numQuadratic);
        for d = 1:D
            quad(d) = win_rev(1) * win_rev(d+1);
        end
        X_feat(k, numLinear + (1:numQuadratic)) = quad;
        
        % 3. Cubic feature: y(k)^3
        X_feat(k, end) = win_rev(1)^3;
    end
end
