function y = pwlTanh(x)
    % pwlTanh: Multiplier-free Piecewise-Linear (PWL) tanh approximation.
    % In hardware, multiplication by 0.5 is a bit-shift (>> 1).
    
    y = zeros(size(x));
    
    % Region 1: x < -1.5 -> y = -1
    idx1 = x < -1.5;
    y(idx1) = -1;
    
    % Region 2: -1.5 <= x < -0.5 -> y = 0.5 * x - 0.25
    idx2 = (x >= -1.5) & (x < -0.5);
    y(idx2) = 0.5 * x(idx2) - 0.25;
    
    % Region 3: -0.5 <= x <= 0.5 -> y = x
    idx3 = (x >= -0.5) & (x <= 0.5);
    y(idx3) = x(idx3);
    
    % Region 4: 0.5 < x <= 1.5 -> y = 0.5 * x + 0.25
    idx4 = (x > 0.5) & (x <= 1.5);
    y(idx4) = 0.5 * x(idx4) + 0.25;
    
    % Region 5: x > 1.5 -> y = 1
    idx5 = x > 1.5;
    y(idx5) = 1;
end
