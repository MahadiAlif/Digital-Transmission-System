function [B, A] = singlePoleImpulseInvariance(f3dB, SpS)
a = exp(-2 * pi * f3dB / SpS);
B = 1 - a;
A = [1 -a];
end
