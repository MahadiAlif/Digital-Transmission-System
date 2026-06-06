function out = volterraMlpEqualizer()
    % volterraMlpEqualizer: Training and prediction functions for the proposed Volterra-PWL-MLP.
    % Uses Volterra-extracted features and multiplier-free piecewise-linear activations.
    out.train = @trainVolterraMlp;
    out.predict = @predictVolterraMlp;
end

function [W1, b1, W2, b2] = trainVolterraMlp(X, Y, hidden1, epochs, lr, batchSize)
    % trainVolterraMlp: Trains a 2-layer MLP (Input -> Hidden1 (PWL-Tanh) -> Output (Linear))
    % Inputs:
    %   X: Training inputs (N x inputDim) where inputs are Volterra features
    %   Y: Target symbols (N x 1)
    %   hidden1: Number of hidden neurons (typically small: 4 to 6)
    %   epochs: Number of training epochs
    %   lr: Learning rate
    %   batchSize: Mini-batch size
    
    [N, inputDim] = size(X);
    
    % Xavier initialization
    W1 = randn(hidden1, inputDim) * sqrt(2 / (inputDim + hidden1));
    b1 = zeros(hidden1, 1);
    W2 = randn(1, hidden1) * sqrt(2 / (hidden1 + 1));
    b2 = zeros(1, 1);
    
    numBatches = floor(N / batchSize);
    
    for epoch = 1:epochs
        idx = randperm(N);
        X_sh = X(idx, :);
        Y_sh = Y(idx);
        
        for b = 1:numBatches
            startIdx = (b-1)*batchSize + 1;
            endIdx = b*batchSize;
            
            x_batch = X_sh(startIdx:endIdx, :).'; % Dim: inputDim x batchSize
            y_batch = Y_sh(startIdx:endIdx).';     % Dim: 1 x batchSize
            
            % --- Forward Pass ---
            z1 = W1 * x_batch + b1;
            a1 = pwlTanh(z1);
            
            y_pred = W2 * a1 + b2; % Linear output layer
            
            % --- Backward Pass ---
            dy = (y_pred - y_batch) / batchSize;
            
            dW2 = dy * a1.';
            db2 = sum(dy, 2);
            
            da1 = W2.' * dy;
            
            % Derivative of PWL-Tanh:
            % 1.0 for |z| <= 0.5
            % 0.5 for 0.5 < |z| <= 1.5
            % 0.0 for |z| > 1.5
            dz1 = zeros(size(z1));
            abs_z1 = abs(z1);
            dz1(abs_z1 <= 0.5) = 1.0;
            dz1((abs_z1 > 0.5) & (abs_z1 <= 1.5)) = 0.5;
            
            dz1 = da1 .* dz1;
            
            dW1 = dz1 * x_batch.';
            db1 = sum(dz1, 2);
            
            % --- Weight Update ---
            W2 = W2 - lr * dW2;
            b2 = b2 - lr * db2;
            W1 = W1 - lr * dW1;
            b1 = b1 - lr * db1;
        end
    end
end

function y_pred = predictVolterraMlp(X, W1, b1, W2, b2)
    % predictVolterraMlp: Computes output of the trained Volterra-PWL-MLP
    a1 = pwlTanh(W1 * X.' + b1);
    y_pred = (W2 * a1 + b2).';
end
