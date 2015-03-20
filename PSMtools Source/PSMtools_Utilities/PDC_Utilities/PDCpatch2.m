function [PhasorB,patched,BnkPts1,PlotNo]=PDCpatch2(PhasorA,NameA,patchop,...
   BnkLevel,BnkFactor,patched,LogPatch,PlotPatch,BnkPts0,BnkTag)
% PDCpatch2.m patches through missing or invalid PDC data points.
% Present logic provides linear interpolation only.
%
% [PhasorB,patched,BnkPts1,PlotNo]=PDCpatch2(PhasorA,NameA,patchop,...
%    BnkLevel,BnkFactor,patched,LogPatch,PlotPatch,BnkPts0,BnkTag);
%
% Interpolates across outlier data in polar coordinates.
%
% Last modified 02/13/03.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

LogPatch=LogPatch>0;
NameA=deblank(NameA);

if ~exist('BnkPts0'), BnkPts0=[]; end
if ~exist('BnkTag'),  BnkTag =0;  end  %Special value denoting bad data point

%disp('In PDCpatch2:')

PhasorB=PhasorA;
if isreal(PhasorA)
  if LogPatch
    disp('In PDCpathch2: Entered vector is not complex--Calling PDCpatch1')
  end
  [PhasorB,patched,BnkPts1,PlotNo]=PDCpatch1(PhasorA,NameA,patchop,BnkLevel,BnkFactor,...
     patched,LogPatch,PlotPatch,BnkPts0,BnkTag);  
  return
end
patched=0;
BnkPts1=[]; PlotNo=0;

if patchop<=0, return, end

%*************************************************************************
%Start of patch logic for outliers
MaxPts=max(size(PhasorB)); %keyboard
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
    BnkPts=find(abs(PhasorB)<=BnkLevel|abs(PhasorB)==BnkTag);
    BnkPts=sort(BnkPts);
  end
  if pass==1, BnkPts1=BnkPts; end 
  NBnkPts=length(BnkPts); %keyboard
  if NBnkPts<=0, return, end
  if LogPatch
    disp(sprintf('In PDCpatch2: BlankLevel = %5.3f BlankFactor =%5.3f',BnkLevel,BnkFactor))
    disp(sprintf('In PDCpatch2: Pass = %2.0i: Number of blank points =%4.0i',pass,NBnkPts))
  end
  if NBnkPts==MaxPts
    if LogPatch
      disp(sprintf('In PDCpatch2: Pass = %2.0i: Number of blank points =%4.0i',pass,NBnkPts))
	    disp(sprintf('In PDCpatch2: Blank record - Return to calling function'))
	  end
    patched=-1; return
  end
  if NBnkPts>=BnkFactor*MaxPts
    if LogPatch
      disp(sprintf('In PDCpatch2: Pass = %2.0i: Number of blank points =%4.0i',pass,NBnkPts))
	    disp(sprintf('In PDCpatch2: Too many blanks - Return to calling function'))
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
      str=sprintf('In PDCpatch2: Blank data span %3.0i: Width= %3.0i: ',spans,width);
      str=[str sprintf('points [%5.0i : %5.0i]',n1,n2)];
      disp(str)
    end
	  if n1>1&n2<MaxPts  %Interior points
		  %step=(PhasorB(n2+1)-PhasorB(n1-1))/(n2-n1+2);
	    Len1=abs(PhasorB(n1-1)); Ang1=angle(PhasorB(n1-1));
	    Lstep=(abs  (PhasorB(n2+1))-Len1)/(n2-n1+2);
	    Astep=(angle(PhasorB(n2+1))-Ang1)/(n2-n1+2);
		  for j=n1:n2
			  %PhasorB(j)=PhasorB(n1-1)+(j-n1+1)*step;
			  Lenj=Len1+(j-n1+1)*Lstep; Angj=Ang1+(j-n1+1)*Astep;
			  PhasorB(j)=Lenj*exp(sqrt(-1)*Angj);
	    end
	 	  patched=1;
	  end
	  if pass==2&n1==1&n2<MaxPts-1  %Left-end points
		  %step=(PhasorB(n2+2)-PhasorB(n2+1));
	    Len1=abs(PhasorB(n2+1)); Ang1=angle(PhasorB(n2+1));
	    Lstep=(abs  (PhasorB(n2+2))-Len1);
	 	  Astep=(angle(PhasorB(n2+2))-Ang1);	
		  for j=n1:n2
		 	  %PhasorB(j)=PhasorB(n2+1)+(j-n2-1)*step;
			  Lenj=Len1+(j-n2-1)*Lstep; Angj=Ang1+(j-n2-1)*Astep;
			  PhasorB(j)=Lenj*exp(sqrt(-1)*Angj);
	    end
	 	  patched=1;
	  end
	  if pass==2&n1>1&n2==MaxPts    %Right-end points
		  %step=(PhasorB(n1-1)-PhasorB(n1-2));
		  Len2=abs(PhasorB(n1-1)); Ang2=angle(PhasorB(n1-1));
	    Lstep=(Len2-abs  (PhasorB(n1-2)));
		  Astep=(Ang2-angle(PhasorB(n1-2)));	
		  for j=n1:n2
			  %PhasorB(j)=PhasorB(n1-1)+(j-n1+1)*step;
	      Lenj=Len2+(j-n1+1)*Lstep; Angj=Ang2+(j-n1+1)*Astep;
			  PhasorB(j)=Lenj*exp(sqrt(-1)*Angj);
	    end
	 	  patched=1;
    end
	  i=i+1;
	  if (i)>NBnkPts, break, end
	  n1=BnkPts(i);
  end
  if (pass==2)&patched>0&PlotPatch
    PlotNo=figure;  %set up new plot
    disp(['In PDCpatch2: Plot ' num2str(PlotNo) ' for phasor patching']) 
	  plot([abs(PhasorA) abs(PhasorB)])
	  title(['PDCpatch2 repair of ' NameA])
	  set(gca,'TickDir','out')
	  disp(sprintf('Plot No. %3.0i',PlotNo))
	  if NBnkPts>50
	    disp('In PDCpatch2: Rough data - invoking PAUSE command for closer viewing') 
      disp('              Press any key to continue')
	    pause
    end
  end
%*************************************************************************
end  %Termination of pass loop

return

%end of PSMT utility

