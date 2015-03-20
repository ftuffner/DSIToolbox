function [CaseComH,SaveFileH,namesH,TRangeH,tstepH,...
     MaxMinSave,MaxMinTSave]...
    =PSMsigCors(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansA,TRange,tstep,decfac,...
     HistTrnd,WinType,nHist,Histpars);
% PSMsigCors produces Hist spectra and correlations (sliding window or ringdowns) 
%
%	  [CaseComH,SaveFileH,namesH,TRangeH,tstepH,...
%    MaxMinSave,MaxMinTSave]...
%   =PSMsigCors(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%    chansA,TRange,tstep,decfac,...
%    HistTrnd,WinType,nHist,Histpars);
%
% INPUTS:
%    caseID       name for present case
%    casetime     time when present case was initiated
%    CaseCom      case comments
%    namesX       signal names
%    PSMsigsX     signal data to be processed
%    chansA       indices for signals to analyze
%    TRange       time range for analysis
%    tstep        time step for PSMsigsX
%    decfac		    decimation factor
%    HistTrnd     detrending control
%    WinType      (not used)
%    nHist         number of points in each Hist cell
%    HistPars     (spare object for later use)
%
% OUTPUTS:
%    CaseComH     case comments, showing PSMsigCors operations 
%    SaveFileH    (not used)
%    namesH       names for signals analyzed
%    TRangeH      time range of actual analysis
%    tstepH       time step for PSMsigsX after decimation
%    MaxMinSave   Max and min values for each signal
%    MaxMinTSave  Times when max and min values occured
%
% PSM Tools called from PSMsigCors:
%   CaseTags
%   ShowRange
%   CaseComPlot
%   promptyn, promptnv
%
% NOTES:
%
%  Last modified 02/19/01.   jfh

% Following code added by JMJ to allow new default linewidth values for plot traces
  defaultLineLineWidth=get(0,'DefaultLineLineWidth');
% defaultLineLineWidth=get(0,'DefaultLineLineWidth') + 0.5;

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

disp(' ')
disp('In PSMsigCors:')

set(0,'DefaultTextInterpreter','none')

if nargin~=13
	disp('In PSMsigCors: Wrong number of inputs!!')
	disp('Invoking "keyboard" command - Enter "return" when you are finished')
	keyboard
end

%Clear outputs
CaseComH=''; SaveFileH='';
namesH=namesX;,TRangeH=TRange; tstepH=tstep;
MaxMinSave=[]; MaxMinTSave=[]; 

chansAstr=chansA;
if ~ischar(chansAstr)
  chansAstr=['chansA=[' num2str(chansAstr) '];'];
end
eval(chansAstr)
chankeyX=names2chans(namesX,1);

%*************************************************************************
%Generate case identification, for stamping on plots and other outputs  
setok=promptyn('In PSMsigCors: Generate new case tags?', 'n');
if setok
  disp(['Generating new case tags for case ' caseID ':'])
  [caseID,casetime,CaseComH,Gtags]=CaseTags(caseID);
  CaseComH=str2mat('New case tags in PSMsigCors:',CaseComH,CaseCom);
else
  CaseComH=CaseCom;
  Gtags=str2mat(caseID,casetime);
end
%*************************************************************************

%*************************************************************************
%Generate case/time stamp for plots
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '  casetime=' casetime];
%*************************************************************************

%*************************************************************************
%Logic for local decimation
decfac=max(fix(decfac),1);
maxpoints=size(PSMsigsX,1);
if decfac>1
  str1=sprintf('In PSMsigCors: Local decimation by decfac=%4.3i',decfac);
  disp(str1)
  setok=promptyn('Is this ok?', 'y');
  if ~setok
	  disp('Invoking "keyboard" command - Enter "return" when you are finished')
	  keyboard
  end
  PSMsigsX=PSMsigsX(1:decfac:maxpoints,:);
  maxpoints=size(PSMsigsX,1);
  str2=sprintf('In PSMsigCors: local maxpoints=%6.0i',maxpoints);
  disp(str2)
  CaseComH=str2mat(CaseComH,str1,str2);
end
tstepH=tstep*decfac;
%*************************************************************************

%*************************************************************************
%Determine record time parameters
maxpoints=size(PSMsigsX,1);
nsigsX=size(PSMsigsX,2);
str=lower(namesX(1,:));
if findstr(str,'time')
  startchan=2;
  time=PSMsigsX(:,1);
  RTmin=time(1);
  RTmax=time(maxpoints);
  tstart=max(RTmin,TRange(1)); tstop=min(RTmax,TRange(2));
else
  startchan=1;
  RTmax=(size(PSMsigsX,1)-1)*tstepH;
  time=(0:tstepH:RTmax);
  RTmin=time(1);
  RTmax=time(maxpoints);
  tstart=RTmin; tstop=RTmax;
end
disp(sprintf('  [maxpoints nsigsX] = %6.0i %4.0i', maxpoints, nsigsX))
disp(sprintf('  Record time span   = %6.2f %6.2f', RTmin,RTmax))
%*************************************************************************

%*************************************************************************
%Control for removing signal offsets
offtrend=promptyn('In PSMsigCors: Remove signal offsets?', 'y');
if offtrend
  CaseComH=str2mat(CaseComH,'In PSMsigCors: Signal offsets will be removed');
else
  HistTrnd=0;
end
%*************************************************************************

%*************************************************************************
disp(' ')
disp('In PSMsigCors: Select channels to analyze')
locbase=1; maxtrys=10;
[chansA,namesA,chansAok]=PickList2(namesX,chansA,locbase,maxtrys);
if ~chansAok
  disp(' Returning to invoking Matlab function.')
  return
end
%*************************************************************************

%*************************************************************************
disp(' ')
TRangeCk=promptyn('In PSMsigCors: Verify time range?', 'n');
if TRangeCk
  DispSig=3; maxtrys=10;
  [TRangeH,nrange,TRangeHok]=ShowRange(PSMsigsX,namesX,DispSig,...
    [tstart tstop],tstep,maxtrys);
  if TRangeHok
    tstart=TRangeH(1); tstop=TRangeH(2)
  end
end
%*************************************************************************

%*************************************************************************
%Set parameters for histogram analysis
if ~exist('nHist'), Nhist=[]; end
if isempty(nHist)|nHist<10
  nHist=promptnv('In PSMsigCors: Enter number of Histogram cells: ', '100');
end
Histok=0; maxtrys=5;
disp(' ')
for i=1:maxtrys
  if ~Histok
    disp(' ')
    disp('In PSMsigCors: Set Histogram data:')
    disp(sprintf('  tstart = %6.2f   tstop = %6.2f', tstart,tstop))
    disp(sprintf('  nHist   = %6.2i ', nHist))
    disp(sprintf('  Signal Detrending: HistTrnd = %2.2i', HistTrnd))
	  Histok=promptyn('Is this ok?', 'y');
	  if ~Histok
      disp('Use keyboard to set Histogram data:')
	    disp('Invoking "keyboard" command - Enter "return" when you are finished')
      keyboard
    end
  end
end
if ~Histok
  str=sprintf('Sorry -%5i chances is all you get!',maxtrys);
  disp([str,' Returning to invoking Matlab function.'])
  return
end
Histdat1=sprintf('tstart = %6.2f   tstop = %6.2f', tstart,tstop);
if decfac>1
  Histdat1=[Histdat1 sprintf('decfac= %6.2i',decfac)];
end
Histdat2=sprintf('nHist = %6.2i  Signal Detrending = %2.2i', nHist, HistTrnd);
CaseComH=str2mat(CaseComH,Histdat1,Histdat2);
%*************************************************************************

%*************************************************************************
%Extract names for signals to process
nsigsA=max(size(chansA));
namesES=namesX(chansA,:);
CaseComH=str2mat(CaseComH,'Signals for analysis:');
CaseComH=str2mat(CaseComH,namesH);
%*************************************************************************

%*************************************************************************
%Plot control logic
%Check desired operations
SaveFileP='none';
ShowHist =0; ShowTsigs=0;
PrintPlot=0; SavePlot=0;
KeepPlot=promptyn('In PSMsigCors: Plot hardcopy or other operations?', 'y');
if KeepPlot
  ShowHist=promptyn('In PSMsigCors: Show Histograms?', 'y');
  ShowTsigs=promptyn('In PSMsigCors: Show time signals?', 'n');
  PrintPlot=promptyn('In PSMsigCors: Print generated plots?', '');
  SavePlot=promptyn('In PSMsigCors: Save generated plots to file(s)?', 'n');
  if SavePlot
    %SaveFileP=[casetime(10:11) casetime(13:14) casetime(16:17) 'S']	%long version
     SaveFileP=[casetime(13:14) casetime(16:17) 'S']	%short version
  end
end
%*************************************************************************

%*************************************************************************
%Generate case header plot
CaseComPlot(CaseCom,Ptitle,PrintPlot,SavePlot,SaveFileP)
%*************************************************************************

%*************************************************************************
%Analyze signals
simrate=1/tstepH;
eps=tstep*1.e-6;
p1=fix((tstart-RTmin)*simrate+1);
pf=fix(min([(tstop-RTmin+1+eps)*simrate+1,maxpoints]));
namesH=[];
L=fix(min([size(namesX(1,:),2) 60]));  %trimmed signal name length
disp(sprintf('PROCESSING %2.0i SIGNALS: ',nsigsA))
time=PSMsigsX(p1:pf,1);
MaxMinSave=zeros(nsigsA,2); MaxMinTSave=zeros(nsigsA,2); 
%keyboard
for n=1:nsigsA  %Main loop for analyzing designated signals
  j=chansA(n);
  name2=namesX(j,:);
  namesH=str2mat(namesH,name2);
  sig2F=PSMsigsX(p1:pf,j);
  if offtrend
    sig2F=Detrend1(sig2F,HistTrnd);
  end
  MaxH=max(sig2F); MinH=min(sig2F);
  MaxMinSave(n,1)=MaxH; MaxMinTSave(n,1)=time(max(find(sig2F==MaxH)));
  MaxMinSave(n,2)=MinH; MaxMinTSave(n,2)=time(max(find(sig2F==MinH)));
  if ShowTsigs
    h=figure; %Initiate new figure
	  plotno=sprintf('P%2.0i: ',h);
	  lineh=plot(time,[sig2F]);
%   set(lineh(1),'LineWidth',[1.0])
    set(lineh(1),'LineWidth',defaultLineLineWidth)
    Ptitle{1}=[plotno name2];
	  title(Ptitle)
	  xlabel('Time in Seconds'); ylabel('Signal')
    set(gca,'TickDir','out')
    if PrintPlot, print -f,     end
    if SavePlot
	    SaveP=[SaveFileP num2str(h)];
      eval(['print -deps ' SaveP]);
	  end
  end
  if ShowHist
    sig2H=hist(sig2F,nHist);
    h=figure; %Initiate new figure
	  plotno=sprintf('P%2.0i: ',h);
	  lineh=plot(sig2H);
%   set(lineh(1),'LineWidth',[1.0])
    set(lineh(1),'LineWidth',defaultLineLineWidth)
    Ptitle{1}=[plotno name2];
	  title(Ptitle)
	  xlabel('Value Distribution'); ylabel('Histogram')
    set(gca,'TickDir','out')
    if PrintPlot, print -f,     end
    if SavePlot
	    SaveP=[SaveFileP num2str(h)];
      eval(['print -deps ' SaveP]);
	  end
  end
end
namesH=namesH(2:nsigsA+1,:);
disp('PROCESSING DONE')
%*************************************************************************

%*************************************************************************
%(No call to PSMsave)
%*************************************************************************


disp('Return from PSMsigCors')
return

%end of PSMT function

