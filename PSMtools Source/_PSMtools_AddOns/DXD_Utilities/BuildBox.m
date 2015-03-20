function [Abox,Bbox,BrespM,stepresp]=BuildBox(FilType,HPfrq,LPfrq,BFordM,FilNames,...
		  Xrange,Yrange,samplerate,steppts,spcyc,Ptags)
%
%	 [Abox,Bbox,BrespM,stepresp]=BuildBox(FilType,HPfrq,LPfrq,BFordM,FilNames,...
%		  Xrange,Yrange,samplerate,steppts,spcyc,Ptags)
%		  
%	a)Builds series of Boxcar filters.
%	b)	Filter defined by first null frequency, LPfrq.
%	c)	To supress calculation and display of step response set steppts<=10.
%	d)	For step response in cycles, set spcyc > 1.  This is the assumed 
%		number of samples per cycle.
%
%  Functions called:
%     TrfCalcZ (REPLACE WITH freqz?)
%     DataTrim
%
%	THIS FUNCTION HAS A LOT OF OPTIONS--READ THE CODE!!
%
% Last modified 09/19/07.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


global Kprompt ynprompt

str=['In BuildBox: FilType = ' FilType];
disp(str)
Nfilts=size(BFordM,2);

Abox=1; Bbox=1;
BrespM=0; stepresp=0;
if FilType<=0  %Test for null filter
  disp(['In BuildBox: ' sprintf('FilType =%4.0i',FilType) ': No filter constructed'])
  return
end 

Nyquist=0.5*samplerate;
Abox=zeros(Nfilts,max(BFordM)+1);
Bbox=zeros(Nfilts,max(BFordM)+1);
BrespM=zeros(1024,Nfilts);

showstep=steppts>0;		%Enter negative steppts to supress step plot
steppts=abs(steppts);
if steppts>10
	unit=max(spcyc,1);
	Tlabel='Cycles';
	if unit==1, unit=max(unit,samplerate); Tlabel='Seconds'; end
	steptime=(0:(steppts-1))/unit;
	stepsig=ones(steppts,1);
	stepsig(1:10)=zeros(10,1);
	stepresp=zeros(steppts,Nfilts);
end
for j=1:Nfilts		%Generate filter series
  tbar=1/LPfrq;
  Boxpts=round(tbar*samplerate);     
  BB=ones(1,Boxpts); %Set boxcar weights
  if length(BB)==0
    str=['In BuildBox: ' FilType ' filter  not recognised'];
	str=str2mat(str,'In BuildBox: Invoking "keyboard" command:');
    disp(str2mat(str,'   Type "return" when you are finished.'))
    keyboard
  end
  AA=1;
  BB=BB/sum(BB);     %Normalize filter weights    
  Abox(j,1:size(AA,2))=AA;
  Bbox(j,1:size(BB,2))=BB;
  [Bresp,frq]=TrfCalcZ(BB,AA,1024,samplerate);
  BrespM(:,j)=Bresp;
  if steppts>10, stepresp(:,j)=filter(BB,AA,stepsig); end	
end
BrespD1=BrespM;		%Save for later use
frqD1=frq;

range=Xrange(1,2)-Xrange(1,1);
if range <=0, return, end
if isempty(Ptags), return, end

%Plot frequency responses
  h=figure;
  xrng=Xrange(1,:); yrng=Yrange(1,:);
  plot(DataTrim(frq,xrng),DataTrim(20*log10(abs(BrespM)),yrng));
  Ptitle{1}=['In BuildBox: Gain Response: ' FilNames(1,:)];
  Ptitle{2}=['Filter Order = ' num2str(length(BB)) ' samplerate = ' num2str(samplerate)];
  title(Ptitle)
  xlabel('Frequency in Hertz'); Ylabel('Gain in dB')
  set (gca,'xlim',xrng); set (gca,'ylim',yrng)
  set(gca,'TickDir','out')     %jfh preference

if steppts<=10, return, end

%Plot step responses
  h=figure;
  if showstep,stepresp=[stepsig stepresp]; end;
  if strcmp(FilType,'low')
    yrng=[0 1.5]; 
    plot(steptime,DataTrim([stepresp],yrng));
  else
    plot(steptime,[stepresp]);
  end
  Ptitle{1}=['In BuildBox: Step Response: ' FilNames(1,:)];
  Ptitle{2}=[Ptags(1,:)];
  title(Ptitle)
  xlabel(['Time in ' Tlabel]); Ylabel('Filter Output')
  set(gca,'TickDir','out')     %jfh preference
  if strcmp(FilType,'low'), set (gca,'ylim',yrng), end

return

%end of PSMT utility
