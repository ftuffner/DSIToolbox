function [Abutters,Bbutters,FrespM,stepresp]=BuildBF(FilType,HPfrq,LPfrq,BFordM,FilNames,...
		  Xrange,Yrange,simrate,steppts,spcyc,Ptags)
%
%	 [Abutters,Bbutters,FrespM,stepresp]=BuildBF(FilType,HPfrq,LPfrq,BFordM,FilNames,...
%		  Xrange,Yrange,simrate,steppts,spcyc,Ptags)
%		  
%	a)	Uses PSM Tools function "ezbutter" to build a series of Butterworth filters.
%	b)	Allowed values for "FilType" are 'low', 'high', "pass', and 'stop'.
%       Can also use 'LP', 'BP', and 'HP'.
%	c)	To supress calculation and display of step response set steppts<=10.
%	d)	For step response in cycles, set spcyc > 1.  This is the assumed 
%		number of samples per cycle.
%
% PSMT functions called from BuildBF:
%   ezbutter
%   TrfCalcZ
%   DataTrim
%
%	THIS FUNCTION HAS A LOT OF OPTIONS--READ THE CODE!!
%
% Last modified 03/28/02.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


global Kprompt ynprompt

str1=['In BuildBF: FilType = ' FilType];
disp(str1)
Nfilts=size(BFordM,2);
tstep=1/simrate;
NoSteps=steppts<=10;

Abutters=1; Bbutters=1;
FrespM=0; stepresp=0;
if FilType<=0  %Test for null filter
  disp(['In BuildBF: FilType = ' FilType ': No filter constructed'])
  return
end 

Nyquist=0.5*simrate;
Abutters=zeros(Nfilts,max(BFordM)+1);
Bbutters=zeros(Nfilts,max(BFordM)+1);
FrespM=zeros(1024,Nfilts);

showstep=steppts>0;		%Enter negative steppts to supress step plot
steppts=abs(steppts);
if ~NoSteps
	steptime=(0:(steppts-1))*tstep;
	stepsig=ones(steppts,1);
	stepsig(1:10)=zeros(10,1);
	stepresp=zeros(steppts,Nfilts);
end
FilType=deblank(FilType);
for j=1:Nfilts		%Generate filter series
  BB=0;
  if strcmp(FilType,'low')|strcmp(FilType,'LP')
  	[BB,AA]=ezbutter(BFordM(j),LPfrq/Nyquist,LPfrq/Nyquist,'low');
  end
  if strcmp(FilType,'high')|strcmp(FilType,'HP')
  	[BB,AA]=ezbutter(BFordM(j),HPfrq/Nyquist,HPfrq/Nyquist,'high');
  end
  if strcmp(FilType,'pass')|strcmp(FilType,'BP')
  	[BB,AA]=ezbutter(BFordM(j),HPfrq/Nyquist,LPfrq/Nyquist,'pass');
  end
  if strcmp(FilType,'stop')
  	[BB,AA]=ezbutter(BFordM(j),HPfrq/Nyquist,LPfrq/Nyquist,'stop');
  end
  if max(size(BB))==0
    str1=['In BuildBF:' FilType ' filter  not recognised'];
	  str1=str2mat(str1,'In BuildBF: Invoking "keyboard" command:');
    disp(str2mat(str1,'  FilType "return" when you are finished.'))
    keyboard
  end
  Abutters(j,1:size(AA,2))=AA;
  Bbutters(j,1:size(BB,2))=BB;
  [Fresp,frq]=TrfCalcZ(BB,AA,1024,simrate);
  FrespM(:,j)=Fresp;
  if ~NoSteps
    if FilType(2)==1, steppts=fix(5/(LPfrq*tstep));  end
    if FilType(2)==2, steppts=fix(5/(HPfrq*tstep)); end
    if FilType(2)==3, steppts=1000; end
    stepresp(:,j)=filter(BB,AA,stepsig); 
  end	
end
FrespD1=FrespM;		%Save for later use
frqD1=frq;

range=Xrange(1,2)-Xrange(1,1);
if range <=0, return, end
if isempty(Ptags), return, end

%Plot frequency responses
FrespM=[FrespM(:,1) FrespM];  %Colors match step plots
Gain=abs(FrespM); Phase=angle(FrespM)*360/(2*pi);
for j=1:size(Phase,2), Phase(:,j)=PSMunwrap(Phase(:,j)); end
xrng=Xrange(1,:); yrng=Yrange(1,:);
figure;
plot(frq,db(Gain)); Ptitle{1}=['In BuildBF: dB Gain Response: ' FilNames(1,:)];
Ptitle{2}=[Ptags(1,:)];
title(Ptitle)
xlabel('Frequency in Hertz'); Ylabel('Gain in dB')
set (gca,'xlim',xrng); set (gca,'ylim',yrng)
set(gca,'TickDir','out')     %jfh preference
figure;
plot(frq,Gain); Ptitle{1}=['In BuildBF: Scalar Gain Response: ' FilNames(1,:)];
Ptitle{2}=[Ptags(1,:)];
title(Ptitle)
xlabel('Frequency in Hertz'); Ylabel('Scalar Gain')
set (gca,'xlim',xrng); set (gca,'ylim',[0 1.1])
set(gca,'TickDir','out')     %jfh preference
figure;
plot(frq,Phase); Ptitle{1}=['In BuildBF: Phase Response: ' FilNames(1,:)];
Ptitle{2}=[Ptags(1,:)];
title(Ptitle)
xlabel('Frequency in Hertz'); Ylabel('Phase in Degrees')
set (gca,'xlim',xrng);
set(gca,'TickDir','out')     %jfh preference

if NoSteps, return, end

%Plot step responses
  figure;
  if showstep,stepresp=[stepsig stepresp]; end;
  if strcmp(FilType,'low')
    yrng=[0 1.5]; 
    plot(steptime,DataTrim([stepresp],yrng));
  else
    plot(steptime,[stepresp]);
  end
  Ptitle{1}=['In BuildBF: Step Response: ' FilNames(1,:)];
  Ptitle{2}=[Ptags(1,:)];
  title(Ptitle)
  xlabel('Time in Seconds'); Ylabel('Filter Output')
  set(gca,'TickDir','out')    %jfh preference
  if strcmp(FilType,'low'), set (gca,'ylim',yrng), end
keybdok=promptyn('In BuildBF: Do you want the keyboard? ', 'n');
if keybdok
  disp('In BuildBF: Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end

return

%end of PSMT function

