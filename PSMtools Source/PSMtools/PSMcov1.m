function [CaseComCV,SaveFileCV,namesCV,TRangeCV,tstepCV,...
     maxlagT]...
    =PSMcov1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansA,TRange,tstep,decfac,...
     maxlagT,WinType,Covpars);
 

% PSMcov1 produces Cov spectra and Covelations (sliding window or ringdowns) 
%
%	  [CaseComCV,SaveFileCV,namesCV,TRangeCV,tstepCV,...
%    MaxMinSave,MaxMinTSave]...
%   =PSMcov1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%    chansA,TRange,tstep,decfac,...
%    CovTrnd,WinType,Covpars);
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
%    CovTrnd      detrending control
%    WinType      (not used)
%    nCov         number of points in each Cov cell
%    CovPars      (spare object for later use)
%
% OUTPUTS:
%    CaseComCV     case comments, showing PSMcov1 operations 
%    SaveFileCV    (not used)
%    namesCV       names for signals analyzed
%    TRangeCV      time range of actual analysis
%    tstepCV       time step for PSMsigsX after decimation
%    MaxMinSave   Max and min values for each signal
%    MaxMinTSave  Times when max and min values occured
%
% PSM Tools called from PSMcov1:
%   CaseTags
%   ShowRange
%   CaseComPlot
%   promptyn, promptnv
%
% NOTES:
%
%  Last modified 06/24/02.   jfh
%  Modified 10/18/2006  by Ning Zhou to add macro function

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
    save Debug_11
elseif 0
    clear all 
    close all
    clc
    load Debug_11
    funLoadMacro()
    PSMMacro.RunMode=1;  %run macro
%     PSMMacro.RunMode=0;  %record macro
%    PSMMacro.RunMode=-1; %normal orperation
end

disp(' ')
CSname='PSMcov1';
LcaseID=caseID;
disp(['In ' CSname ': Local caseID = ' LcaseID])
disp('   Special covariance calculations')

set(0,'DefaultTextInterpreter','none')

%Clear outputs
CaseComCV=''; SaveFileCV='';
namesCV=namesX;,TRangeCV=TRange; tstepCV=tstep;

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
if ~isfield(PSMMacro, 'PSMcov1_setok'), PSMMacro.PSMcov1_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn('In PSMcov1: Generate new case tags?', 'n');
else
    setok=PSMMacro.PSMcov1_setok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMcov1_setok=setok;
    else
        PSMMacro.PSMcov1_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%setok=promptyn('In PSMcov1: Generate new case tags?', 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if setok
  disp(['Generating new case tags for case ' LcaseID ':'])
  [LcaseID,casetime,CaseComCV,Gtags]=CaseTags(LcaseID);
  CaseComCV=str2mat('New case tags in PSMcov1:',CaseComCV,CaseCom);
else
  CaseComCV=CaseCom;
  Gtags=str2mat(LcaseID,casetime);
end
%*************************************************************************

%*************************************************************************
%Generate case/time stamp for plots
Ptitle{1}=' ';
Ptitle{2}=['LcaseID=' LcaseID '  casetime=' casetime];
%*************************************************************************

%*************************************************************************
%Logic for local decimation
decfac=max(fix(decfac),1);
maxpoints=size(PSMsigsX,1);
if decfac>1
  str1=sprintf('In PSMcov1: Local decimation by decfac=%4.3i',decfac);
  disp(str1)
  setok=promptyn('Is this ok?', 'y');
  if ~setok
	  disp('Invoking "keyboard" command - Enter "return" when you are finished')
	  keyboard
  end
  PSMsigsX=PSMsigsX(1:decfac:maxpoints,:);
  maxpoints=size(PSMsigsX,1);
  str2=sprintf('In PSMcov1: local maxpoints=%6.0i',maxpoints);
  disp(str2)
  CaseComCV=str2mat(CaseComCV,str1,str2);
end
tstepCV=tstep*decfac;
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
  RTmax=(size(PSMsigsX,1)-1)*tstepCV;
  time=(0:tstepCV:RTmax);
  RTmin=time(1);
  RTmax=time(maxpoints);
  tstart=RTmin; tstop=RTmax;
end
disp(sprintf('  [maxpoints nsigsX] = %6.0i %4.0i', maxpoints, nsigsX))
disp(sprintf('  Record time span   = %6.2f %6.2f', RTmin,RTmax))
%*************************************************************************

%*************************************************************************
disp(' ')
disp('In PSMcov1: Select channels to analyze')
locbase=1; maxtrys=10;
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'PSMcov1_chansAok'), PSMMacro.PSMcov1_chansAok=NaN; end
if ~isfield(PSMMacro, 'PSMcov1_namesA'), PSMMacro.PSMcov1_namesA=NaN; end
if ~isfield(PSMMacro, 'PSMcov1_chansA'), PSMMacro.PSMcov1_chansA=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_chansAok))      % Not in Macro playing mode or selection not defined in a macro
    [chansA,namesA,chansAok]=PickList2(namesX,chansA,locbase,maxtrys);
else
    chansAok=PSMMacro.PSMcov1_chansAok;
    namesA=PSMMacro.PSMcov1_namesA;
    chansA=PSMMacro.PSMcov1_chansA;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMcov1_chansAok=chansAok;
        PSMMacro.PSMcov1_namesA=namesA;
        PSMMacro.PSMcov1_chansA=chansA;
    else
        PSMMacro.PSMcov1_chansAok=NaN;
        PSMMacro.PSMcov1_namesA=NaN;
        PSMMacro.PSMcov1_chansA=NaN;
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
if ~isfield(PSMMacro, 'PSMcov1_TRangeCk'), PSMMacro.PSMcov1_TRangeCk=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_TRangeCk))      % Not in Macro playing mode or selection not defined in a macro
    TRangeCk=promptyn('In PSMcov1: Verify time range?', 'n');
else
    TRangeCk=PSMMacro.PSMcov1_TRangeCk;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMcov1_TRangeCk=TRangeCk;
    else
        PSMMacro.PSMcov1_TRangeCk=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%TRangeCk=promptyn('In PSMcov1: Verify time range?', 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if TRangeCk
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    %keyboard;
    if ~isfield(PSMMacro, 'PSMcov1_TRangeCVok'), PSMMacro.PSMcov1_TRangeCVok=NaN; end
    if ~isfield(PSMMacro, 'PSMcov1_tstart02'), PSMMacro.PSMcov1_tstart02=NaN; end
    if ~isfield(PSMMacro, 'PSMcov1_tstop02'), PSMMacro.PSMcov1_tstop02=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_TRangeCVok))      % Not in Macro playing mode or selection not defined in a macro
          DispSig=3; maxtrys=10;
          [TRangeCV,nrange,TRangeCVok]=ShowRange(PSMsigsX,namesX,DispSig,...
            [tstart tstop],tstep,maxtrys);
          if TRangeCVok
            tstart=TRangeCV(1); tstop=TRangeCV(2);
          end
    else
        TRangeCVok=PSMMacro.PSMcov1_TRangeCVok;
        tstart=PSMMacro.PSMcov1_tstart02;
        tstop=PSMMacro.PSMcov1_tstop02;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMcov1_TRangeCVok=TRangeCVok;
            PSMMacro.PSMcov1_tstart02=tstart;
            PSMMacro.PSMcov1_tstop02=tstop;
        else
            PSMMacro.PSMcov1_TRangeCVok=NaN;
            PSMMacro.PSMcov1_tstart02=NaN;
            PSMMacro.PSMcov1_tstop02=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 10/18/06
    %---------------------------------------------------
  
end
%*************************************************************************

%*************************************************************************
%Set parameters for Covariance analysis
if ~exist('maxlagT'), maxlagT=[]; end
if isempty(maxlagT)
  nCov=promptnv('In PSMcov1: Enter maximum lag time: ', '100');
end
maxlagT=min(maxlagT,tstop);
Covok=0; maxtrys=5;

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'PSMcov1_Covok'), PSMMacro.PSMcov1_Covok=NaN; end
if ~isfield(PSMMacro, 'PSMcov1_tstart'), PSMMacro.PSMcov1_tstart=NaN; end
if ~isfield(PSMMacro, 'PSMcov1_tstop'), PSMMacro.PSMcov1_tstop=NaN; end
if ~isfield(PSMMacro, 'PSMcov1_maxlagT'), PSMMacro.PSMcov1_maxlagT=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_Covok))      % Not in Macro playing mode or selection not defined in a macro
    disp(' ')
    for i=1:maxtrys
      tstop =max(tstop,TRangeCV(1));  tstop =min(tstop,TRangeCV(2)); 
      tstart=max(tstart,TRangeCV(1)); tstart=min(tstart,tstop); 
      maxlagT=max(maxlagT,0); maxlagT=min(maxlagT,(tstop-tstart));
      if ~Covok
        disp(' ')
        disp('In PSMcov1: Set covariance controls:')
        disp(sprintf('  tstart     = %6.2f   tstop = %6.2f', tstart,tstop))
        disp(sprintf('  maxlagT    = %6.2i ', maxlagT))
          Covok=promptyn('Is this ok?', 'y');
          if ~Covok
          disp('Use keyboard to set covariance controls:')
            disp('Invoking "keyboard" command - Enter "return" when you are finished')
          keyboard
        end
      end
    end
else
    Covok=PSMMacro.PSMcov1_Covok;
    tstart=PSMMacro.PSMcov1_tstart;
    tstop=PSMMacro.PSMcov1_tstop;
    maxlagT=PSMMacro.PSMcov1_maxlagT;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMcov1_Covok=Covok;
        PSMMacro.PSMcov1_tstart=tstart;
        PSMMacro.PSMcov1_tstop=tstop;
        PSMMacro.PSMcov1_maxlagT=maxlagT;
    else
        PSMMacro.PSMcov1_Covok=NaN;
        PSMMacro.PSMcov1_tstart=NaN;
        PSMMacro.PSMcov1_tstop=NaN;
        PSMMacro.PSMcov1_maxlagT=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%---------------------------------------------------


if ~Covok
  str=sprintf('Sorry -%5i chances is all you get!',maxtrys);
  disp([str,' Returning to invoking Matlab function'])
  return
end
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMcov1_biasok'), PSMMacro.PSMcov1_biasok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_biasok))      % Not in Macro playing mode or selection not defined in a macro
    biasok=promptyn('Use biased estimator?', 'y');
else
    biasok=PSMMacro.PSMcov1_biasok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMcov1_biasok=biasok;
    else
        PSMMacro.PSMcov1_biasok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%biasok=promptyn('Use biased estimator?', 'y');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


Covdat1=sprintf('tstart = %6.2f   tstop = %6.2f', tstart,tstop);
if decfac>1
  Covdat1=[Covdat1 sprintf('decfac= %6.2i',decfac)];
end
Covdat2=sprintf('maxlagT = %6.2f', maxlagT);
if biasok, BiasTag='biased'; 
else BiasTag='unbiased'; end
str=['Using ' BiasTag ' estimator'];
CaseComCV=str2mat(CaseComCV,Covdat1,Covdat2);
%*************************************************************************

%*************************************************************************
%Analyze signals
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMcov1_ShowTsigs'), PSMMacro.PSMcov1_ShowTsigs=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_ShowTsigs))      % Not in Macro playing mode or selection not defined in a macro
    ShowTsigs=promptyn('In PSMspec1: Show time signals?', 'n');
else
    ShowTsigs=PSMMacro.PSMcov1_ShowTsigs;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMcov1_ShowTsigs=ShowTsigs;
    else
        PSMMacro.PSMcov1_ShowTsigs=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%ShowTsigs=promptyn('In PSMspec1: Show time signals?', 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


CovLen=length(PSMsigsX(:,1));
maxlagN=fix(maxlagT/tstep)-1;
eps=tstep*1.e-6;
p1=fix((tstart-RTmin)/tstep+1);
pf=fix(min([(tstop-RTmin+1+eps)/tstep+1,maxpoints]));
lagsT=[0:maxlagN]'*tstep; 
nsigsA=length(chansA);
if ShowTsigs
  for N=1:nsigsA
    nsig=chansA(N);
    h=figure; plot(PSMsigsX(p1:pf,1),PSMsigsX(p1:pf,nsig))
    Ptitle{1}=namesX(nsig,:);
	  title(Ptitle)
	  xlabel('Time in Seconds'); 
    set(gca,'TickDir','out')
  end
end
namesN='time';
AddOn=deblank(which('xcov'));  %Check presence of PSMT add-on
AddOn=~isempty(AddOn);
if ~AddOn
  disp('In PSMcov1: Cannot find Matlab function XCOV ')
  disp('  Signal Processing Toolbox may not be installed')
  disp('  Will user slower function in PSM Tools')
end  
if AddOn
  AutoRing=lagsT; 
  for N=1:nsigsA  %Autocovariances only
    nsig=chansA(N);
    namesN=str2mat(namesN,['AutoCov ' namesX(nsig,:)]);
    AutoCovM=xcov(PSMsigsX(p1:pf,nsig),maxlagN,BiasTag);
    Cloc=fix(size(AutoCovM,1)/2)+1;
    AutoRingM=AutoCovM(Cloc:size(AutoCovM,1),:);
    maxlagN=min(size(AutoRingM,1),size(AutoRing,1));
    AutoRing=[AutoRing(1:maxlagN,:) AutoRingM(1:maxlagN)];
  end
else
  AutoCov=PSMautocov(PSMsigsX(p1:pf,chansA),maxlagN,BiasTag);
  AutoRing=[lagsT(1:maxlagN) AutoCov(1:maxlagN,:)];
end
namesCV='time';
for N=1:nsigsA  %Autocovariances only
  nsig=chansA(N);
  namesCV=str2mat(namesCV,['ACV ' namesX(nsig,:)]);
end
disp('In PSMcov1: covariance names are')
disp(namesCV)
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMcov1_keybdok03'), PSMMacro.PSMcov1_keybdok03=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_keybdok03))      % Not in Macro playing mode or selection not defined in a macro
    keybdok=promptyn(['In PSMcov1: Do you want the keyboard? '], '');
    if keybdok
      disp(['In PSMcov1: Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
    end
else
    keybdok=PSMMacro.PSMcov1_keybdok03;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMcov1_keybdok03=keybdok;
    else
        PSMMacro.PSMcov1_keybdok03=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



%*************************************************************************

%*************************************************************************
%Logic to plot covariance functions
for Npsets=1:20
    disp(' ')
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    %     if ~isfield(PSMMacro, 'PSMcov1_setok02'), PSMMacro.PSMcov1_setok02=NaN; end
    %     if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_setok02))      % Not in Macro playing mode or selection not defined in a macro
    %         setok=promptyn(['In PSMcov1: Batch plots of covariance functions? '], '');
    %     else
    %         setok=PSMMacro.PSMcov1_setok02;
    %     end
    % 
    %     if PSMMacro.RunMode==0      % if in macro record mode 
    %         if PSMMacro.PauseMode==0            % if record mode is not paused
    %             PSMMacro.PSMcov1_setok02=setok;
    %         else
    %             PSMMacro.PSMcov1_setok02=NaN;
    %         end
    %         save(PSMMacro.MacroName,'PSMMacro');
    %     end
    if PSMMacro.RunMode<2
        setok=promptyn(['In PSMcov1: Batch plots of covariance functions? '], '');
    else
        setok=0;
    end
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
  
  
  if ~setok, break, end
  if ~isempty(get(0,'Children'))  %Test for open plots
        %----------------------------------------------------
        % Begin: Macro selection ZN 10/18/06
        if ~isfield(PSMMacro, 'PSMcov1_closeok'), PSMMacro.PSMcov1_closeok=NaN; end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_closeok))      % Not in Macro playing mode or selection not defined in a macro
            closeok=promptyn('In PSMcov1: Close all plots? ', 'y');
        else
            closeok=PSMMacro.PSMcov1_closeok;
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PSMcov1_closeok=closeok;
            else
                PSMMacro.PSMcov1_closeok=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        % closeok=promptyn('In PSMcov1: Close all plots? ', 'y');
        % End: Macro selection ZN 10/18/06
        %----------------------------------------------------
        if closeok, close all; end    %Close all plots
  end
  [maxpts nCVfuns]=size(AutoRing);
  chansP=2:nCVfuns;            %Signals to plot
  decfac=1;                    %Decimation factor
  t1=AutoRing(1,1);            %Initial processing time
  t2=AutoRing(maxpts,1);       %Final processing time
  TRange=[t1 t2];              %Processing range
  if Npsets>1    %Use value from prior plot cycle
    TRange=TRangeP;
  end
  Xchan=1;
  PlotPars=[];
  [CaseComP,SaveFileP,namesP,TRangeP,tstepP]...
    =PSMplot2(LcaseID,casetime,CaseComCV,namesCV,AutoRing,...
     chansP,TRange,tstep,decfac,...
     Xchan,PlotPars);

% if PSMMacro.RunMode>=1
%      break;
%  end
end  %Terminate plot loop for filtered signals

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMcov1_keybdok'), PSMMacro.PSMcov1_keybdok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_keybdok))      % Not in Macro playing mode or selection not defined in a macro
    keybdok=promptyn(['In PSMcov1: Do you want the keyboard? '], 'n');
    if keybdok
      disp(['In PSMcov1: Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
    end
else
    keybdok=PSMMacro.PSMcov1_keybdok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMcov1_keybdok=keybdok;
    else
        PSMMacro.PSMcov1_keybdok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

%*************************************************************************

%*************************************************************************

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMcov1_setok03'), PSMMacro.PSMcov1_setok03=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_setok03))      % Not in Macro playing mode or selection not defined in a macro
  setok=promptyn(['In PSMcov1: Launch ringdown tool? '], '');
else
    setok=PSMMacro.PSMcov1_setok03;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMcov1_setok03=setok;
    else
        PSMMacro.PSMcov1_setok03=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%setok=promptyn(['In PSMcov1: Launch ringdown tool? '], '');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


for N=1:1
  AddOn=deblank(which('Ringdown'));  %Check presence of PSMT add-on
  if isempty(AddOn)
    disp(['In ' CSname ': Cannot find this PSMT Add-On '])
    setok=0;  
  end  
  if ~setok, disp('Proceeding to next processing phase'), break, end
  InSig=[]; FixedPoles=[];
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMcov1_keybdok02'), PSMMacro.PSMcov1_keybdok02=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMcov1_keybdok02))      % Not in Macro playing mode or selection not defined in a macro
        keybdok=promptyn(['In In PSMcov1: Do you want the keyboard first? '], 'n');
        if keybdok
          disp(['In PSMcov1: Invoking "keyboard" command - Enter "return" when you are finished'])
          keyboard
        end
    else
        keybdok=PSMMacro.PSMcov1_keybdok02;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMcov1_keybdok02=keybdok;
        else
            PSMMacro.PSMcov1_keybdok02=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
  rguiopts.copyplotfcn='PSMlabl';
  rguiopts.copyplotargs={LcaseID casetime};
  ringdown(AutoRing,namesCV,InSig,FixedPoles,rguiopts);
end
%*************************************************************************

%*************************************************************************
%(call to PSMsave??)
%*************************************************************************


disp('Return from PSMcov1')
return

%end of PSMT function

