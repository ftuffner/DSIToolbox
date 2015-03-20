function rhat=RHATFUNC(x,Q,w)
%****************************
%Usage:  rhat=RHATFUNC(x,Q,w)
%inputs:
%   x=data
%   Q+1 = length of correlation function to be estimated
%   w = window (column vector) (note length of window needs to be the blk lngth)
%   (NOTE:  WINDOW FEATURE CURRENTLY DISABLED)
%output:
%   rhat = estimated autocorrelation function of length Q+1
%
% Updated 12/3/99
% JWP
% Classic biased estimate of autocorrelation function
%****************************
L=length(x);    %number of samples of data
rhat=zeros(Q+1,1);   %initialize correlation function to zero
for i=0:Q;
  rhat(i+1)=sum(x((i+1):L).*conj(x(1:(L-i))));
end
rhat=rhat/L;  %dividing by L results in the classic biased estimate
