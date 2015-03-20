function [TxyangD]=PSMunwrap(TxyangDW,UWmode,plusfrac)
% [TxyangD]=PSMunwrap(TxyangDW,UWmode,plusfrac);
%	
% jfh phase unwrapping logic
% Angle data is assumed to be in degrees
% UWmode = 0:  Unwrapped angle data starts on interval (-360 0]
% UWmode = 1:  Unwrapped angle data starts at initial angle
% plusfrac*180 is test level for wrapping jump (default=0.90)
%
% Last modified 09/20/02.   jfh

if ~exist('UWmode'),   UWmode=[]; end
if isempty(UWmode),    UWmode=0;  end
if ~exist('plusfrac'), plusfrac=[];   end
if isempty(plusfrac),  plusfrac=0.90; end
plusfrac=max(plusfrac,0.60); plusfrac=min(plusfrac,1.00);

TxyangD=TxyangDW;
dims=size(TxyangD);
if dims(2)>dims(1)
  disp(['In PSMunwrap: WARNING - dimensions = ' num2str(dims)])
  pause
end

npts=size(TxyangD,1);
if UWmode==0
  if TxyangD(1)>0, TxyangD(1)=TxyangD(1)-360; end
  if TxyangD(1)<=-360
  	wraps=fix(TxyangD(1)/360);
	  TxyangD(1)=TxyangD(1)-wraps*360;
  end
end
for i=2:npts,
	dth=TxyangD(i)-TxyangD(i-1);
	wraps=fix(dth/360);
	dth=dth-wraps*360;
	if dth>(180*plusfrac), dth=dth-360; end
	if dth<-(180/plusfrac), dth=dth+360; end
	TxyangD(i)=TxyangD(i-1)+dth;
end

return

%end of PSMT utility

