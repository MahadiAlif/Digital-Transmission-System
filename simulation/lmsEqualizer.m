function [y_equalized, w] = lmsEqualizer(samples, trueSymbols, numTaps, mu)
    % lmsEqualizer: Standard symbol-spaced LMS linear equalizer for baseline comparison.
    % Inputs:
    %   samples: vector of received samples (length N)
    %   trueSymbols: target transmitted symbols (length N)
    %   numTaps: number of equalizer filter taps (should be odd, e.g. 9)
    %   mu: LMS learning rate (step size)
    % Outputs:
    %   y_equalized: equalized output samples (length N)
    %   w: trained filter tap weights
    
    N = length(samples);
    w = zeros(numTaps, 1);
    w(floor(numTaps/2) + 1) = 1; % Initialize with a central spike (identity filter)
    y_equalized = zeros(N, 1);
    
    L = floor(numTaps / 2);
    % Pad boundary edges
    padded = [zeros(L, 1); samples(:); zeros(L, 1)];
    
    % Adaptive LMS training loop
    for k = 1:N
        x_k = padded(k : k + numTaps - 1);
        y_equalized(k) = w.' * x_k;
        
        % Calculate error
        error = trueSymbols(k) - y_equalized(k);
        
        % Update weights
        w = w + mu * error * x_k;
    end
end
