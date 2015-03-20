function [TX,TXI]=seqTXmats
% Transformation Matrices for symmetrical components
% [J. F. Hauer - Pacific NW Laboratory] 
%
% [symmetrical componsents]=[TX][observed quantities]
%
%set conversions
global PI DPI DEG DEGI;

% construct reference phasors for symmetrical components
refrot=2*PI/3;
AOP=exp(j*refrot);
AOP2=AOP*AOP;
TX=ones(3,3);
TX(1:2,2:3)=[AOP,AOP2;AOP2,AOP];
TX=TX/3;
TXI=ones(3,3);
TXI(2:3,1:2)=[AOP2,AOP;AOP,AOP2];

%end of PSM script




