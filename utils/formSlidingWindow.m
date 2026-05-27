function X = formSlidingWindow(samples, L)
    % formSlidingWindow: Groups symbol-rate samples into a sliding window.
    % Inputs:
    %   samples: vector of aligned received samples (length N)
    %   L: window radius. The window size will be W = 2*L + 1.
    % Outputs:
    %   X: matrix of size N x W, where each row is the window centered at sample k.
    
    N = length(samples);
    W = 2 * L + 1;
    
    % Zero-pad boundary edges to handle transients at start and end
    padded = [zeros(L, 1); samples(:); zeros(L, 1)];
    
    X = zeros(N, W);
    for k = 1:N
        X(k, :) = padded(k : k + W - 1).';
    end
end
