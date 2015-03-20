function [r,alpha,Poles]=TrueCovS(b,a,L,fs)
%*********************
%John Pierre Matlab utility
%Usage:  [r,alpha,p]=TrueCovS(b,a,L,fs)
%true correlation function for continuous time system
%Inputs:
%    b=[b0 b1 ... bM]  %numerator in the s-domain
%    a=[1 a1 ... aN]   %denominator in the s-domain
%    L=max lag to be calculated
%    fs=sampling rate
%Outputs:
%    r=true autocorrelation function of length L
%    alpha=true residues of the autocorrelation function
%    Poles=true poles of the autocorrelation function
%where N>M
%no repeat roots of a
%*********************
%
%Last modified 01/29/02  jfh

disp('In TrueCovS:')
disp('WARNING--THERE IS SOMETHING WRONG WITH THIS CODE!!!')
disp('Use RtrueCt instead')
pause

N=length(a)-1;  %system order
M=length(b)-1;  %numerator order
Ts=1/fs;  %sampling period
[gamma,Poles,K]=residue(b,a);  %partial fracton of innovation filter
alpha=zeros(size(gamma));

%Find alpha's from gamma's and poles
for i=1:N  		
   q=-Poles(i);
   qbvect=q.^(M:-1:0).';
   qavect=q.^(N:-1:0).';
   alpha(i)=gamma(i)*(b*qbvect)/(a*qavect);
end

for k=0:L
   r(k+1)=alpha.'*exp(Poles*Ts*k);
end
if size(r,2)>size(r,1), r=r'; end

if 1  %Diagnostics with alternate logic:
  disp('In TrueCovS'); keyboard; %disp(gamma)
  bconj=b.*((-1).^(M:-1:0));
  aconj=a.*((-1).^(N:-1:0));
  disp('[b'' bconj''] = ')
  disp([b' bconj'])
  disp('[a'' aconj''] = ')
  disp([a' aconj'])
  disp('A'' = '); A=conv(a,aconj); disp(A')
  disp('B'' = '); B=conv(b,bconj); disp(B')
  disp('roots(B) = '); disp(roots(B)), 
  disp('roots(A) = '); disp(roots(A))
  disp('residue(b,a) = '); disp(residue(b,a))
  disp('alpha = '); disp(alpha)
  disp('residue(B,A) = '); disp(residue(B,A))
  figure; plot([real(r) imag(r)])
  Time=[0:L]*Ts; thru=0;
  [A,B,C,D]=par2ss(alpha,Poles,thru);
  AcovCk=impulse(A,B,C,D,1,Time);
  figure; plot([real(r) AcovCk])
end

%Return r as real column vector
r=real(r);  if r(1)<0; r=-r; end  %Should we do this???

%End of John Pierre Matlab utility
