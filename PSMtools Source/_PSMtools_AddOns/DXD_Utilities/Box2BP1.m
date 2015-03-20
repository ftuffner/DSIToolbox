function [ND,DD]=Box2BP1(FLP,F1,F2,simrate)
%
% Last modified 07/08/02.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%Filter transformation equations: (Proakis, p. 649)
% wp      = cutoff frequency of given LP filter
% [w1 w2] = desired passband for BP filter
% alph    = cos((w2+w1)/2)/cos((w2-w1)/2)
% kfac    = cot((w2-w1)/2)*tan(wp/2)
% a1      = -2*alph*kfac/(kfac+1)
% a2      = (kfac-1)/(kfac+1)
% 
% Substitution:
%                -2     -1
%  -1           z  -a1*z  + a2
% Z       = - ------------------------------  
%                 -2     -1
%             a2*z  -a1*z  + 1

%[ND,DD]=Box2BP1(60,250,320,720);
%[ND,DD]=Box2BP1(100,300,490,1000);

%help conv; help filter;
 
%simrate=720; 
%FLP=60; F1=100; F2=40;

Nyquist=simrate/2;
fac=pi/Nyquist;
wp=FLP*fac; w1=F1*fac; w2=F2*fac;

alph=cos((w2+w1)/2)/cos((w2-w1)/2);
kfac=cot((w2-w1)/2)*tan(wp/2);
a1  =-2*alph*kfac/(kfac+1);
a2  =(kfac-1)/(kfac+1);
num=-[a2 -a1 1]; den=[1 -a1 a2];

%Build LP boxcar
Nbox=round(simrate/FLP);
Bbox=ones(Nbox,1); 
Ptitle{1}=['IN Box2BP1:'];
Ptitle{2}=['LP Boxcar: wp=[' num2str(wp) ']'];
[resp2,W]=freqz(Bbox,1,256,simrate);
figure; plot(W,abs(resp2)); title(Ptitle)

%Transform LP boxcar
ND=zeros(1,Nbox*2+1);
DD=1;
for M=1:Nbox
  NDT=1; 
  for M1=1:M
    NDT=conv(NDT,num);
  end
  for M2=M+1:Nbox
    NDT=conv(NDT,den);
  end
  ND=ND+NDT;
  DD=conv(DD,den);
end
Ptitle{1}=['IN Box2BP1:'];
Ptitle{2}=['BP Boxcar: wp=[' num2str(wp) ']'];
[resp2,W]=freqz(ND,DD,256,simrate);
figure; plot(W,abs(resp2)); title(Ptitle)

%end of PSMT utility Box2BP1

