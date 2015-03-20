function [r,alpha,p]=RtrueCt(b,a,L,fs)
%*********************
%Usage:  [r,alpha,p]=RtrueCt(b,a,L,fs)
%true correlation function for continuous time system
%Inputs:
%    b=[b0 b1 ... bM]  %numerator in the s-domain
%       (decending powers of s)
%    a=[1 a1 ... aN]   %denominator in the s-domain
%       (decending powers of s)
%    L=max lag to be calculated
%    fs=sampling rate
%Outputs:
%    r=true autocorrelation function of length L
%    alpha=true residues of the autocorrelation function
%    p=true poles of the auto correlation function
%where N>M
%no repeat roots of a
%*********************
%
%Modified version of John Pierre Matlab utility
%Last modified 09/29/03  jfh

N=length(a)-1;  %system order
M=length(b)-1;  %numerator order
Ts=1/fs;  %sampling period
[gamma,p,k]=residue(b,a);  %partial fracton of innovation filter
alpha=zeros(size(gamma));
for i=1:N,		%find alpha's from gamma's and poles
   q=-p(i);
   qbvect=q.^(M:-1:-0).';
   qavect=q.^(N:-1:0).';
   alpha(i)=gamma(i)*(b*qbvect)/(a*qavect);
end
L
keyboard
if 0
  %[A,B,C,D]=par2ss(resN,polN,thru);
  NUM=b; DEN=a;
  fstep=0.01; Fmax=4*25.6;
  wHz=[0:fstep:Fmax]';   %frequency in Hz
  FrespI=TrfCalcS(NUM,DEN,wHz);
  figure; plot(wHz,db(FrespI)); 
  set(gca,'xlim',[0 2])
  set(gca,'ylim',[-40 10])
  xlabel('Frequency in Hertz')
  title('Frequency Response for System Model')
  disp('ERROR IN CODE TO FOLLOW:'); pause
  NUM=poly(alpha); 
  DEN1=a; DEN2=-poly(-p);
  Fresp1=TrfCalcS(NUM,DEN1,wHz);
  Fresp2=TrfCalcS(NUM,DEN2,wHz);
  figure; plot(wHz,db(Fresp1+Fresp2)); 
  set(gca,'xlim',[0 2])
  %set(gca,'ylim',[-40 10])
  xlabel('Frequency in Hertz')
  title('Frequency Response for Ideal AutoCovariance')
end
for k=0:L
   r(k+1)=alpha.'*exp(p*Ts*k);
end
r=real(r);
if size(r,2)>size(r,1), r=r'; end

%End of John Pierre Matlab utility
