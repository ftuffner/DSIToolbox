function [r,alpha,p]=TrueCovZ(b,a,L)
%*********************
%Usage:  [r,alpha,p]=TrueCovZ(b,a,L)
%Inputs:
%    b=[b0 b1 ... bM]  %numerator in the z-domain
%    a=[1 a1 ... aN]   %denominator in the z-domain
%    L=max lag to be calculated
%Outputs:
%    r=true autocorrelation function of length L
%    alpha=true residues of the autocorrelation function
%    p=true poles of the auto correlation function
%where N>M
%no repeat roots of a
%see Papoulis, 3rd ed. pg. 410
%*********************
%
%Last modified 10/30/01  jfh

N=length(a)-1;  %system order
M=length(b)-1;  %numerator order
[gamma,p,k]=residuez(b,a);  %partial fracton of innovation filter
alpha=zeros(size(gamma));
for i=1:N,		%find alpha's from gamma's and poles
   q=conj(1/p(i));
   qbvect=q.^(0:-1:-M)';
   qavect=q.^(0:-1:-N)';
   alpha(i)=gamma(i)*(b*qbvect)/(a*qavect);
end
for k=0:L
   r(k+1)=alpha.'*(p.^k);
end

%End of John Pierre Matlab utility

