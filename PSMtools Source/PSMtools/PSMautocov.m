function [AutoCov]=PSMautocov(sigs,maxlagN,mode)
%  PSMautocov calculates the autocovariance sequence 
%  for each column of real array sigs.
%  
%  Default is the unbiased estimate 
%  (each lag normalized by number of summed points)
%
%  [AutoCov]=PSMautocov(sigs,maxlagN,mode);
%
% Inputs:
%
% Outputs:
%
% Special functions called by PSMautocov:
%
% Last change 06/14/01.  jfh

[maxpts nsigs]=size(sigs);
if isempty(maxlagN), maxlagN=maxpts; end
maxlagN=max(maxlagN,0); maxlagN=min(maxlagN,maxpts); 
AutoCov=zeros(maxlagN,nsigs);
for N=1:nsigs
  sig=sigs(:,N); sig=sig-mean(sig)*ones(maxpts,1);
  for lagN=1:maxlagN
    npts=maxpts-lagN+1;
    AutoCov(lagN,N)=sum(sig(1:npts).*sig(lagN:maxpts))/npts;
  end
end

%end of PSMT function