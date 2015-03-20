function [VectorB,patched,BnkPts1,PlotNo]=PDCpatch1(VectorA,NameA,patchop,...
   BnkLevel,BnkFactor,patched,LogPatch,PlotPatch,BnkPts0,BnkTag)
% PDCpatch1.m patches through missing or invalid PDC data points.
% Present logic provides linear interpolation only.
%
% [VectorB,patched,BnkPts1,PlotNo]=PDCpatch1(VectorA,NameA,patchop,...
%    BnkLevel,BnkFactor,patched,LogPatch,PlotPatch,BnkPts0,BnkTag);
%
% Interpolates across outlier data in scalar coordinates.
%
% Last modified 02/13/03.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%disp('In PDCpatch1:')

LogPatch=LogPatch>0;
NameA=deblank(NameA);

if ~exist('BnkPts0'), BnkPts0=[]; end
if ~exist('BnkTag'),  BnkTag =0;  end  %Special value denoting bad data point

VectorB=VectorA;
if ~isreal(VectorA)
  if LogPatch
    disp('In PDCpathch1: Entered vector is complex--Calling PDCpatch2')
  end
  [VectorB,patched,BnkPts1,PlotNo]=PDCpatch2(VectorA,NameA,patchop,BnkLevel,BnkFactor,...
     patched,LogPatch,PlotPatch,BnkPts0,BnkTag);  
  return
end
patched=0;
BnkPts1=[]; PlotNo=0;

if patchop<=0, return, end

%*************************************************************************
%Start of patch logic for outliers
MaxPts=max(size(VectorB)); %keyboard
for pass=1:2 %Start of pass loop
  %Determine bad data points
  if ~isempty(BnkPts0)
    if pass==1
      BnkPts=BnkPts0;
    end
    if pass==2
      locs2=find(BnkPts0==1|BnkPts0==MaxPts);
      if isempty(locs2), break, end
      BnkPts=BnkPts0(locs2); %keyboard
    end
  else
    BnkPts=find(abs(VectorB)<=BnkLevel|abs(VectorB)==abs(BnkTag));
    BnkPts=sort(BnkPts);
  end
  if pass==1, BnkPts1=BnkPts; end 
  NBnkPts=length(BnkPts); %keyboard
  if NBnkPts<=0, return, end
 	if LogPatch
    disp(sprintf('In PDCpatch1: BlankLevel = %5.3f BlankFactor =%5.3f',BnkLevel,BnkFactor))
    disp(sprintf('In PDCpatch1: Pass = %2.0i: Number of blank points =%4.0i',pass,NBnkPts))
  end
  if NBnkPts==MaxPts
    if LogPatch
      disp(sprintf('In PDCpatch1: Pass = %2.0i: Number of blank points =%4.0i',pass,NBnkPts))
	    disp(sprintf('In PDCpatch1: Blank record - Return to calling function'))
	  end
    patched=-1; return
  end
  if NBnkPts>=BnkFactor*MaxPts
    if LogPatch
      disp(sprintf('In PDCpatch1: Pass = %2.0i: Number of blank points =%4.0i',pass,NBnkPts))
	    disp(sprintf('In PDCpatch1: Too many blanks - Return to calling function'))
    end
	  patched=-2; return
  end
  BnkPtsE=[BnkPts' 0]';
  %*************************************************************************
  %Repair bad data points for this pass
  %LogPatch=1; PlotPatch=1; %Diagnostic
  spans=0;
  i=1; n1=BnkPts(i);
  for n=1:NBnkPts
	  width=1;
	  while BnkPtsE(i+1)==BnkPtsE(i)+1
	  	width=width+1; i=i+1;
	  end
	  n2=BnkPts(i); spans=spans+1;
	  if LogPatch
      str=sprintf('In PDCpatch1: Blank data span %3.0i: Width= %3.0i: ',spans,width);
      str=[str sprintf('points [%5.0i : %5.0i]',n1,n2)];
      disp(str)
    end
	  if n1>1&n2<MaxPts  %Interior points
		  step=(VectorB(n2+1)-VectorB(n1-1))/(n2-n1+2);
		  for j=n1:n2
			  VectorB(j)=VectorB(n1-1)+(j-n1+1)*step;
	    end
	 	  patched=1;
    end
	  if pass==2&n1==1&n2<MaxPts-1  %Left-end points
		  step=(VectorB(n2+2)-VectorB(n2+1));
		  for j=n1:n2
		 	  VectorB(j)=VectorB(n2+1)+(j-n2-1)*step;
	    end
	 	  patched=1;
	  end
    if pass==2&n1>1&n2==MaxPts    %Right-end points
		  step=(VectorB(n1-1)-VectorB(n1-2));
		  for j=n1:n2
        VectorB(j)=VectorB(n1-1)+(j-n1+1)*step;
	    end
	 	  patched=1;
	  end
	  if (i)==NBnkPts, break, end
	    i=i+1;
	    n1=BnkPts(i);
  end
  if (pass==2)&patched>0&PlotPatch
    PlotNo=figure;   %set up new plot
    disp(['In PDCpatch1: Plot ' num2str(PlotNo) ' for vector patching']) 
	  %plot([abs(VectorA) abs(VectorB)])
	   plot([VectorA VectorB])
	  title(['PDCpatch1 repair of ' NameA])
	  set(gca,'TickDir','out')
	  disp(sprintf('Plot No. %3.0i',PlotNo))
	  if NBnkPts>50
	    disp('In PDCpatch1: Rough data - invoking PAUSE command for closer viewing') 
      disp('              Press any key to continue')
	    pause
    end
  end
  %*************************************************************************
end  %Termination of pass loop

return

%end of PSMT utility
