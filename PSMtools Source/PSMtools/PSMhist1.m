function [CaseComH,SaveFileH,namesH,TRangeH,tstepH,...
     MaxMinSave,MaxMinTSave]...
    =PSMhist1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansA,TRange,tstep,decfac,...
     HistTrnd,WinType,nHist,Histpars);
% PSMhist1 produces Hist spectra and correlations (sliding window or ringdowns) 
%
%	  [CaseComH,SaveFileH,namesH,TRangeH,tstepH,...
%    MaxMinSave,MaxMinTSave]...
%   =PSMhist1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
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
%    CaseComH     case comments, showing PSMhist1 operations 
%    SaveFileH    (not used)
%    namesH       names for signals analyzed
%    TRangeH      time range of actual analysis
%    tstepH       time step for PSMsigsX after decimation
%    MaxMinSave   Max and min values for each signal
%    MaxMinTSave  Times when max and min values occured
%
% PSM Tools called from PSMhist1:
%   CaseTags
%   ShowRange
%   CaseComPlot
%   promptyn, promptnv
%
% NOTES:
%
%  Modified 06/28/04  jfh  Comments
%  Modified 02/15/06  jfh  Cosmetics
%  Modified 10/18/2006 Ning Zhou to add macro function
%

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

% Following code added by JMJ to allow new default linewidth values for plot traces
  defaultLineLineWidth=get(0,'DefaultLineLineWidth');
% defaultLineLineWidth=get(0,'DefaultLineLineWidth') + 0.5;

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

 
if 0
    keyboard
    save Debug_09
elseif 0
    clear all 
    close all
    clc
    load Debug_09
    funLoadMacro()
    PSMMacro.RunMode=1;  %run macro
%     PSMMacro.RunMode=0;  %record macro
%    PSMMacro.RunMode=-1; %normal orperation
end
%keyboard
disp(' ')
disp('In PSMhist1:')

set(0,'DefaultTextInterpreter','none')

if nargin~=13 %0 ????? 
	disp('In PSMhist1: Wrong number of inputs!!')
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

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMhist1_setok'), PSMMacro.PSMhist1_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMhist1_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn('In PSMhist1: Generate new case tags?', 'n');
else
    setok=PSMMacro.PSMhist1_setok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMhist1_setok=setok;
    else
        PSMMacro.PSMhist1_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%setok=promptyn(['In ' FNname ': Generate new case tags? '], 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

if setok
  disp(['Generating new case tags for case ' caseID ':'])
  [caseID,casetime,CaseComH,Gtags]=CaseTags(caseID);
  CaseComH=str2mat('New case tags in PSMhist1:',CaseComH,CaseCom);
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
  str1=sprintf('In PSMhist1: Local decimation by decfac=%4.3i',decfac);
  disp(str1)
  setok=promptyn('Is this ok?', 'y');
  if ~setok
    disp('Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
  PSMsigsX=PSMsigsX(1:decfac:maxpoints,:);
  maxpoints=size(PSMsigsX,1);
  str2=sprintf('In PSMhist1: local maxpoints=%6.0i',maxpoints);
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
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMhist1_offtrend'), PSMMacro.PSMhist1_offtrend=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMhist1_offtrend))      % Not in Macro playing mode or selection not defined in a macro
    offtrend=promptyn('In PSMhist1: Remove signal offsets?', 'y');
else
    offtrend=PSMMacro.PSMhist1_offtrend;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMhist1_offtrend=offtrend;
    else
        PSMMacro.PSMhist1_offtrend=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%offtrend=promptyn('In PSMhist1: Remove signal offsets?', 'y');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if offtrend
  CaseComH=str2mat(CaseComH,'In PSMhist1: Signal offsets will be removed');
else
  HistTrnd=0;
end
%*************************************************************************

%*************************************************************************
disp(' ')
disp('In PSMhist1: Select channels to analyze')
locbase=1; maxtrys=10;

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'PSMhist1_chansAok'), PSMMacro.PSMhist1_chansAok=NaN; end
if ~isfield(PSMMacro, 'PSMhist1_namesA'), PSMMacro.PSMhist1_namesA=NaN; end
if ~isfield(PSMMacro, 'PSMhist1_chansA'), PSMMacro.PSMhist1_chansA=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMhist1_chansAok))      % Not in Macro playing mode or selection not defined in a macro
    [chansA,namesA,chansAok]=PickList2(namesX,chansA,locbase,maxtrys);
else
    chansAok=PSMMacro.PSMhist1_chansAok;
    namesA=PSMMacro.PSMhist1_namesA;
    chansA=PSMMacro.PSMhist1_chansA;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMhist1_chansAok=chansAok;
        PSMMacro.PSMhist1_namesA=namesA;
        PSMMacro.PSMhist1_chansA=chansA;
    else
        PSMMacro.PSMhist1_chansAok=NaN;
        PSMMacro.PSMhist1_namesA=NaN;
        PSMMacro.PSMhist1_chansA=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% [chansA,namesA,chansAok]=PickList2(namesX,chansA,locbase,maxtrys);
% End: Macro selection ZN 10/18/06
%---------------------------------------------------


if ~chansAok
  disp(' Returning to invoking Matlab function.')
  return
end
%*************************************************************************

%*************************************************************************
disp(' ')

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMhist1_TRangeCk'), PSMMacro.PSMhist1_TRangeCk=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMhist1_TRangeCk))      % Not in Macro playing mode or selection not defined in a macro
    TRangeCk=promptyn('In PSMhist1: Verify time range?', 'n');
else
    TRangeCk=PSMMacro.PSMhist1_TRangeCk;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMhist1_TRangeCk=TRangeCk;
    else
        PSMMacro.PSMhist1_TRangeCk=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%TRangeCk=promptyn('In PSMhist1: Verify time range?', 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if TRangeCk
  DispSig=3; maxtrys=10;
  [TRangeH,nrange,TRangeHok]=ShowRange(PSMsigsX,namesX,DispSig,...
    [tstart tstop],tstep,maxtrys);
  if TRangeHok
    tstart=TRangeH(1); tstop=TRangeH(2);
  end
end
%*************************************************************************

%*************************************************************************
%Set parameters for histogram analysis
if ~exist('nHist'), Nhist=[]; end
if isempty(nHist)|nHist<10
  nHist=promptnv('In PSMhist1: Enter number of Histogram cells: ', '100');
end
Histok=0; maxtrys=5;
disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'PSMhist1_Histok'), PSMMacro.PSMhist1_Histok=NaN; end
if ~isfield(PSMMacro, 'PSMhist1_HistTrnd'), PSMMacro.PSMhist1_HistTrnd=NaN; end
if ~isfield(PSMMacro, 'PSMhist1_nHist'), PSMMacro.PSMhist1_nHist=NaN; end
if ~isfield(PSMMacro, 'PSMhist1_tstart'), PSMMacro.PSMhist1_tstart=NaN; end
if ~isfield(PSMMacro, 'PSMhist1_tstop'), PSMMacro.PSMhist1_tstop=NaN; end

if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMhist1_Histok))      % Not in Macro playing mode or selection not defined in a macro
    for i=1:maxtrys
      if ~Histok
        disp(' ')
        disp('In PSMhist1: Settings for Histogram processing')
        disp(sprintf('  tstart = %6.2f   tstop = %6.2f', tstart,tstop))
        disp(sprintf('  nHist   = %6.2i ', nHist))
        disp(sprintf('  Signal Detrending: HistTrnd = %2.2i', HistTrnd))
        Histok=promptyn('Is this ok? ','y');
        if ~Histok
          disp('Use keyboard to set Histogram data:')
          disp('Invoking "keyboard" command - Enter "return" when you are finished')
          keyboard
        end
      end
    end
else
    Histok=PSMMacro.PSMhist1_Histok;
    HistTrnd=PSMMacro.PSMhist1_HistTrnd;
    nHist=PSMMacro.PSMhist1_nHist;
    tstart=PSMMacro.PSMhist1_tstart;
    tstop=PSMMacro.PSMhist1_tstop;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMhist1_Histok=Histok;
        PSMMacro.PSMhist1_HistTrnd=HistTrnd;
        PSMMacro.PSMhist1_nHist=nHist;
        PSMMacro.PSMhist1_tstart=tstart;
        PSMMacro.PSMhist1_tstop=tstop;
    else
        PSMMacro.PSMhist1_Histok=NaN;
        PSMMacro.PSMhist1_HistTrnd=NaN;
        PSMMacro.PSMhist1_nHist=NaN;
        PSMMacro.PSMhist1_tstart=NaN;
        PSMMacro.PSMhist1_tstop=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%---------------------------------------------------

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

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMhist1_KeepPlot'), PSMMacro.PSMhist1_KeepPlot=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMhist1_KeepPlot))      % Not in Macro playing mode or selection not defined in a macro
    KeepPlot=promptyn('In PSMhist1: Plot hardcopy or other operations?', 'y');
else
    KeepPlot=PSMMacro.PSMhist1_KeepPlot;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMhist1_KeepPlot=KeepPlot;
    else
        PSMMacro.PSMhist1_KeepPlot=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%KeepPlot=promptyn('In PSMhist1: Plot hardcopy or other operations?', 'y');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if KeepPlot
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    %keyboard;
    if ~isfield(PSMMacro, 'PSMhist1_ShowHist'), PSMMacro.PSMhist1_ShowHist=NaN; end
    if ~isfield(PSMMacro, 'PSMhist1_ShowTsigs'), PSMMacro.PSMhist1_ShowTsigs=NaN; end
    if ~isfield(PSMMacro, 'PSMhist1_PrintPlot'), PSMMacro.PSMhist1_PrintPlot=NaN; end
    if ~isfield(PSMMacro, 'PSMhist1_SavePlot'), PSMMacro.PSMhist1_SavePlot=NaN; end


    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMhist1_ShowHist))      % Not in Macro playing mode or selection not defined in a macro
          ShowHist =promptyn('In PSMhist1: Show Histograms?', 'y');
          ShowTsigs=promptyn('In PSMhist1: Show time signals?', 'n');
          PrintPlot=promptyn('In PSMhist1: Print generated plots?', '');
          SavePlot =promptyn('In PSMhist1: Save generated plots to file(s)?', 'n');
    else
        ShowHist=PSMMacro.PSMhist1_ShowHist;
        ShowTsigs=PSMMacro.PSMhist1_ShowTsigs;
        PrintPlot=PSMMacro.PSMhist1_PrintPlot;
        SavePlot=PSMMacro.PSMhist1_SavePlot;

    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMhist1_ShowHist=ShowHist;
            PSMMacro.PSMhist1_ShowTsigs=ShowTsigs;
            PSMMacro.PSMhist1_PrintPlot=PrintPlot;
            PSMMacro.PSMhist1_SavePlot=SavePlot;
        else
            PSMMacro.PSMhist1_ShowHist=NaN;
            PSMMacro.PSMhist1_ShowTsigs=NaN;
            PSMMacro.PSMhist1_PrintPlot=NaN;
            PSMMacro.PSMhist1_SavePlot=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 10/18/06
    %---------------------------------------------------

  
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
VarSave=zeros(nsigsA,1);
%keyboard
disp('Histogram Results:')
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
  VarSave(n)=var(sig2F);
  disp(['Signal = ' name2])
  disp(sprintf('  tstart  = %6.2f  tstop  = %6.2f',tstart,tstop))
  disp(sprintf('  Maximum = %6.2f  at time= %6.2f',MaxH, MaxMinTSave(n,1)))
  disp(sprintf('  Minimum = %6.2f  at time= %6.2f',MinH, MaxMinTSave(n,2)))
  disp(sprintf('  Variance= %6.2f  Std Dev= %6.2f',VarSave(n), sqrt(VarSave(n))))
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
    if PrintPlot, print -f; end
    if SavePlot
	  SaveP=[SaveFileP num2str(h)];
      eval(['print -deps ' SaveP]);
	end
  end
  if ShowHist
    [sig2H,XB]=hist(sig2F,nHist);
    h=figure; %Initiate new figure
	plotno=sprintf('P%2.0i: ',h);
	lineh=plot(XB,sig2H);
    set(lineh(1),'LineWidth',defaultLineLineWidth)
    Ptitle{1}=[plotno name2];
	title(Ptitle)
    str=sprintf('Value Distribution: Std Dev= %6.2f',sqrt(VarSave(n)));
	xlabel(str); 
    ylabel('Histogram');
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


disp('Return from PSMhist1.m')
return

%end of PSMT function

