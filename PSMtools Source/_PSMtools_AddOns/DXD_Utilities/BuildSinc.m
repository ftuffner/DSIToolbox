function [Asinc,Bsinc,BrespM,stepresp]=BuildSinc(FilType,HPfrq,LPfrq,BFordM,FilNames,...
		  Xrange,Yrange,simrate,steppts,spcyc,Ptags)
%
%	 [Asinc,Bsinc,BrespM,stepresp]=BuildSinc(FilType,HPfrq,LPfrq,BFordM,FilNames,...
%		  Xrange,Yrange,simrate,steppts,spcyc,Ptags)
%		  
%	a)Builds series of sinc filters.
%	b)	Filter defined by first null frequency, LPfrq.
%	c)	To supress calculation and display of step response set steppts<=10.
%	d)	For step response in cycles, set spcyc > 1.  This is the assumed 
%		number of samples per cycle.
%
%  Functions called:
%     TrfCalcZ
%     DataTrim
%
%	THIS FUNCTION HAS A LOT OF OPTIONS--READ THE CODE!!
%
% Last modified 07/03/02.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

global Kprompt ynprompt

str=['In BuildSinc: FilType = ' FilType];
disp(str)
Nfilts=size(BFordM,2);
Nfilts=1;  %Temporary precaution

Asinc=1; Bsinc=1;
BrespM=0; stepresp=0;
if FilType<=0  %Test for null filter
  disp(['In BuildSinc: ' sprintf('FilType =%4.0i',FilType) ': No filter constructed'])
  return
end
HPfrq=0;
fcorner0=LPfrq;
SincFac=BFordM;

Nyquist=0.5*simrate;
%Asinc=zeros(Nfilts,max(BFordM)+1);
%Bsinc=zeros(Nfilts,max(BFordM)+1);
BrespM=zeros(1024,Nfilts);

showstep=steppts>0;		%Enter negative steppts to supress step plot
steppts=abs(steppts);
if steppts>10
	unit=max(spcyc,1);
	Tlabel='Cycles';
	if unit==1, unit=max(unit,simrate); Tlabel='Seconds'; end
	steptime=(0:(steppts-1))/unit;
	stepsig=ones(steppts,1);
	stepsig(1:10)=zeros(10,1);
	stepresp=zeros(steppts,Nfilts);
end
range=Xrange(1,2)-Xrange(1,1);  %Test for other displays & prompts

str='NOTES:';
str=str2mat(str,' a) Filter Sinc0 is a basic Sinc filter of "Sincpts" points');
str=str2mat(str,' b) Filter Sinc1 is filter Sinc0 plus a Hamming window');
str=str2mat(str,' c) [Sinc0 Sinc1] will have -6 dB corners in the general range');
str=str2mat(str,'    of [1 2]*fcorner0.  Just where depends upon SincFac.');
str=str2mat(str,' d) Use SincFac=[2 1 0.5] for a [low medium high] order filter');
%disp(str)

for j=1:Nfilts		%Generate filter series
  fcorner0=LPfrq;		%lowpass corner frequency in Hertz
  if range
    disp('INITIAL SETTINGS:')
    disp(sprintf('fcorner0=%3.3f',fcorner0))
    disp(sprintf('SincFac= %3.3f',SincFac))
    setok=promptyn('In BuildSinc: Is this ok?', 'y');
    if ~setok
      str='In BuildSinc: Invoking "keyboard command for modification of filter values.';
      disp(str2mat(str,'  Type "return" when you are finished.'))
      keyboard
    end
  end
  Nyquist=0.5*simrate;
  ncorner=fcorner0/Nyquist; 
  Sincpts=fix(0.5*simrate/SincFac)*2;	%Force an even number
  SincRange=ncorner*(-Sincpts:Sincpts);
  I=find(SincRange);
  SincWts=ones(size(SincRange));
  SincWts(I)=sin(pi*SincRange(I))./(pi*SincRange(I));
  HamWts=0.54-0.46*cos(2*pi*(0:2*Sincpts)/(2*Sincpts));
  BSinc0=ncorner*SincWts;
  BSinc1=BSinc0.*HamWts;
  BSinc0=BSinc0/sum(BSinc0);
  BSinc1=BSinc1/sum(BSinc1);
  AA=1;
  BB=BSinc1;
  Asinc=AA;
  Bsinc=BB;
  [Bresp,frq]=TrfCalcZ(BB,AA,1024,simrate);
  BrespM(:,j)=Bresp;
  if steppts>10, stepresp(:,j)=filter(BB,AA,stepsig); end	
end
BrespD1=BrespM;		%Save for later use
frqD1=frq;

range=Xrange(1,2)-Xrange(1,1);
if range <=0, return, end
if isempty(Ptags), return, end

%Plot frequency responses
  figure;
  plot(BSinc1)
  Ptitle{1}=['In BuildSinc: Filter Weights: ' FilNames(1,:)];
  Ptitle{2}=[Ptags(1,:)];
  title(Ptitle)
  set(gca,'TickDir','out')
  figure;
  xrng=Xrange(1,:); yrng=Yrange(1,:);
  plot(DataTrim(frq,xrng),DataTrim(20*log10(abs(BrespM)),yrng));
  Ptitle{1}=['In BuildSinc: Gain Response: ' FilNames(1,:)];
  Ptitle{2}=[Ptags(1,:)];
  title(Ptitle)
  xlabel('Frequency in Hertz'); Ylabel('Gain in dB')
  set (gca,'xlim',xrng); set (gca,'ylim',yrng)
  set(gca,'TickDir','out')     %jfh preference

if steppts<=10, return, end

%Plot step responses
  figure;
  if showstep,stepresp=[stepsig stepresp]; end;
  if strcmp(FilType,'low')
    yrng=[0 1.5]; 
    plot(steptime,DataTrim([stepresp],yrng));
  else
    plot(steptime,[stepresp]);
  end
  Ptitle{1}=['In BuildSinc: Step Response: ' FilNames(1,:)];
  Ptitle{2}=[Ptags(1,:)];
  title(Ptitle)
  xlabel(['Time in ' Tlabel]); Ylabel('Filter Output')
  set(gca,'TickDir','out')     %jfh preference
  if strcmp(FilType,'low'), set (gca,'ylim',yrng), end

return

%end of jfh m-file

