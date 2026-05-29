function out = mlpEqualizerScratch()
    % mlpEqualizerScratch: Struct helper containing MLP training and prediction functions.
    % This file contains subfunctions that can be accessed via struct fields.
    out.train = @trainMlp;
    out.predict = @predictMlp;
end

function [W1, b1, W2, b2, W3, b3] = trainMlp(X, Y, hidden1, hidden2, epochs, lr, batchSize)
    % trainMlp: Trains a 3-layer MLP (Input -> Hidden1 -> Hidden2 -> Output)
    % Inputs:
    %   X: Training inputs (N x inputDim)
    %   Y: Target outputs (N x 1)
    %   hidden1: Number of neurons in hidden layer 1 (10-20)
    %   hidden2: Number of neurons in hidden layer 2 (10-20)
    %   epochs: Number of training epochs
    %   lr: Learning rate
    %   batchSize: Mini-batch size
    
    [N, inputDim] = size(X);
    
    % 1. Xavier/Glorot weight initialization
    W1 = randn(hidden1, inputDim) * sqrt(2 / (inputDim + hidden1));
    b1 = zeros(hidden1, 1);
    W2 = randn(hidden2, hidden1) * sqrt(2 / (hidden1 + hidden2));
    b2 = zeros(hidden2, 1);
    W3 = randn(1, hidden2) * sqrt(2 / (hidden2 + 1));
    b3 = zeros(1, 1);
    
    numBatches = floor(N / batchSize);
    
    for epoch = 1:epochs
        % Shuffle training data at the start of each epoch
        idx = randperm(N);
        X_shuffled = X(idx, :);
        Y_shuffled = Y(idx);
        
        lossSum = 0;
        
        for b = 1:numBatches
            startIdx = (b-1)*batchSize + 1;
            endIdx = b*batchSize;
            
            x_batch = X_shuffled(startIdx:endIdx, :).'; % Dim: inputDim x batchSize
            y_batch = Y_shuffled(startIdx:endIdx).';     % Dim: 1 x batchSize
            
            % --- Forward Pass ---
            z1 = W1 * x_batch + b1;
            a1 = tanh(z1);
            
            z2 = W2 * a1 + b2;
            a2 = tanh(z2);
            
            y_pred = W3 * a2 + b3; % Linear output activation for regression
            
            % --- Loss calculation (Mean Squared Error) ---
            error = y_pred - y_batch;
            lossSum = lossSum + sum(error.^2, 'all');
            
            % --- Backward Pass (Backpropagation) ---
            dy = error / batchSize;
            
            dW3 = dy * a2.';
            db3 = sum(dy, 2);
            
            da2 = W3.' * dy;
            dz2 = da2 .* (1 - a2.^2); % derivative of tanh
            dW2 = dz2 * a1.';
            db2 = sum(dz2, 2);
            
            da1 = W2.' * dz2;
            dz1 = da1 .* (1 - a1.^2);
            dW1 = dz1 * x_batch.';
            db1 = sum(dz1, 2);
            
            % --- Parameter Updates ---
            W3 = W3 - lr * dW3;
            b3 = b3 - lr * db3;
            W2 = W2 - lr * dW2;
            b2 = b2 - lr * db2;
            W1 = W1 - lr * dW1;
            b1 = b1 - lr * db1;
        end
        
        % Log progress every 10 epochs
        if mod(epoch, 10) == 0 || epoch == 1
            mse = lossSum / (numBatches * batchSize);
            fprintf('  Epoch %d/%d - MSE Loss: %.6f\n', epoch, epochs, mse);
        end
    end
end

function y_pred = predictMlp(X, W1, b1, W2, b2, W3, b3)
    % predictMlp: Computes output of the trained MLP
    % Input: X (N x inputDim)
    % Output: y_pred (N x 1)
    
    a1 = tanh(W1 * X.' + b1);
    a2 = tanh(W2 * a1 + b2);
    y_pred = (W3 * a2 + b3).';
end
