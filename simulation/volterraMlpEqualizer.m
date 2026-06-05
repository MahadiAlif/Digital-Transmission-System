function out = volterraMlpEqualizer()
    out.train = @trainVolterraMlp;
    out.predict = @predictVolterraMlp;
end

function [W1, b1, W2, b2] = trainVolterraMlp(X, Y, hidden1, epochs, lr, batchSize)
    error('Not implemented');
end

function y_pred = predictVolterraMlp(X, W1, b1, W2, b2)
    % predictVolterraMlp: Computes output of the trained Volterra-PWL-MLP
    a1 = pwlTanh(W1 * X.' + b1);
    y_pred = (W2 * a1 + b2).';
end