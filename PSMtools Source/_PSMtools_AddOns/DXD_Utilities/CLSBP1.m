% PSMtools Utility CLSBP1
%
% Last modified 07/21/02.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%help fircls
% From Matlab example:
  n  = 30;
  f  = [0 0.40 0.8 1];
  f  = [0 0.04 0.3 1];
  a  = [0 1 0];
  up = [ 0.01 1.001  0.2]; 
  lo = [-0.01 0.999 -0.2];
  b  = fircls(n,f,a,up,lo);
 [resp2,W]=freqz(b,1,256,2);
 figure; plot(W,abs(resp2));
%help firls

 

simrate=720; Nyquist=simrate/2;

N=40;  %Filter order
BL=[0  1    0];    %Band levels 
BE=[45 110 210 360];  %Band edges

N=20; BE=[0 18 180 360]; 
UL=[ 0.01 1.0001  0.8]; 
LL=[-0.01 0.9999 -0.8];
BCLS=fircls(N,BE/Nyquist,BL,UL,LL);   %BP filter
Ptitle{1}=['IN CLSBP1: N=' num2str(N) '  BE=[' num2str(BE) ']'];
Ptitle{2}=['UL=[' num2str(UL) ']  LL=[' num2str(LL) ']'];
%figure; plot(BCLS); title(Ptitle)
[resp2,W]=freqz(BCLS,1,256,simrate);
figure; plot(W,abs(resp2)); title(Ptitle)



%end of PSMT utility CLSBP1

