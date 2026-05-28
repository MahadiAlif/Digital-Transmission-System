function out = mlpEqualizerScratch()
    out.train = @trainMlp;
    out.predict = @predictMlp;
end

function [W1, b1, W2, b2, W3, b3] = trainMlp(X, Y, hidden1, hidden2, epochs, lr, batchSize)
    % Placeholder for training
    error('Not implemented yet');
end

function y_pred = predictMlp(X, W1, b1, W2, b2, W3, b3)
    % predictMlp: Computes output of the trained MLP
    % Input: X (N x inputDim)
    % Output: y_pred (N x 1)
    
    a1 = tanh(W1 * X.' + b1);
    a2 = tanh(W2 * a1 + b2);
    y_pred = (W3 * a2 + b3).';
end