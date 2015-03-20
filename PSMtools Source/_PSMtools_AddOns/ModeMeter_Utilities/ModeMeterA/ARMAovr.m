function [a,spoles,zpoles,cnd]=ARMAovr(rhat,N,K,M,Fs)
% [a,spoles,zpoles,rhat]=ARMAovr(x,N,K,M,Fs)
%
% inputs:  
%  rhat = estimated correlation function
%  N    = order of the denominator
%	 K    = length of autocorrelation function used
%  M    = order of numerator (note M=0 for AR)
%  Fs   = sampling rate
%
% outputs:
%   a      = polynomial
%   spoles = poles in s-plane
%   zpoles = poles in z-plane
%   cnd    = condition number for Toeplitz correlation matrix 
%
%  Updated 12/3/99 -- JWP
%***********************************
 
R=toeplitz(rhat((M+1):(M+K)),[rhat((M+1):-1:2);rhat(1:(N-M))]); %form Toeplitz correlation matrix
cnd=cond(R);
rvector=diag(diag(rhat((M+2):K+M+1))); %diagdiag makes sure its a column vector
ashort=pinv(R)*rvector;  % solve least squares problem using pseudo inverse
a=[1;-ashort];   % characteristic equation coefficients
zpoles=roots(a);  % z-plane poles
spoles=log(zpoles)*Fs; % s-plane poles

%end of ModeMeter script
