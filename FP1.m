clear all
close all
clc


alfa=[-1;1];


%PAM-2
bits=randi([0 1],1e3,1);
symbols=alfa(bits+1);


% Train of delta (carrying symbols)
SpS=4;
w=upsample(symbols,SpS);


% NRZ pulse shaping
% A=1;
% B=ones(1,SpS);
% x_TX=filter(B,A,w);


% RZ pulse shaping
A=1;
B=ones(1,SpS/2);
x_TX=filter(B,A,w);


% eyediagram
eyediagram(x_TX,2*SpS,2*SpS);


figure(1);
freqz(B,A);
