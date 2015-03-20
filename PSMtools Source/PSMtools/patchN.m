function [patch]=patchN(PSMsigsX,N,n1,n2,Npts);
% Linear interpolation across bad data
% [patch]=patchN(PSMsigsX,N,n1,n2,Npts);
%
% Npts=ceil((time(n2)-time(n1))/tstep)+1;
% PSMsigsX(:,N)=[PSMsigsX(1:(n1-1),N)' patch' PSMsigsX((n2+1):maxpoints,N)']';
%
% Last modified 04/26/02.  jfh
 
%keyboard
val1=PSMsigsX(n1,N); val2=PSMsigsX(n2,N);
pts=[0:Npts-1]'; w2=pts/Npts; w1=1-w2;
%figure; plot([w1 w2])
patch=zeros(Npts,length(N));
patch=w1*val1+w2*val2;
%figure; plot(patch)

return

%end of PSMT utility