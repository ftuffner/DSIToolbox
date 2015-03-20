% PSMtools Utility CLSBP1
%
% Last modified 07/03/02.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%help REMEZ
simrate=720; Nyquist=simrate/2;

N=40;  %Filter order
BL=[1  1   0   0];    %Band levels 
BE=[45 110 210 360];  %Band edges
Wts=[60 1]; %Band weights

N=40; BE=[45 110 210 360]; Wts=[60 1]; 
N=38; BE=[45 125 220 360]; Wts=[80 1]; 
BREM=REMEZ(20,[0 0.4 0.5 1],[1 1 0 0]); %LP filter
BREM=REMEZ(20,[0 0.4 0.5 1],[1 1 0 0],[50 1]); %LP filter
BREM=REMEZ(N,BE/Nyquist,BL,Wts,'h');   %BP filter
Ptitle{1}=['BE =[' num2str(BE) ']'];
Ptitle{2}=['N=' num2str(N) '  Wts=[' num2str(Wts) ']'];
%figure; plot(BREM); title(Ptitle)
[resp2,W]=freqz(BREM,1,256,simrate);
figure; plot(W,abs(resp2)); title(Ptitle)



%end of PSMT utility CLSBP1

