function [CaseComF,SaveFileF,namesF,TRangeF,tstepF,...
      PSMsigsF,FilPars]...
     =PSMfilt(caseID,casetime,CaseCom,namesX,PSMsigsX,...
      chansA,TRange,tstep,decfac,FilType,FilPars);
% Bulk filtering of PSM signals
%
%   [CaseComF,SaveFileF,namesF,TRangeF,tstepF,...
%     PSMsigsF,FilPars]...
%    =PSMfilt(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%     chansA,TRange,tstep,decfac,FilType,FilPars);
%
%  INPUTS:
%    caseID       name for present case
%    casetime     time when present case was initiated
%    CaseCom      case comments
%    namesX       signal names
%    PSMsigsX     signal data to be processed
%    chansA       channels to process (presently all signals)
%    TRange       time range to process
%    tstep        time step for PSMsigsX
%    decfac		    decimation factor
%    FilType      type of filtering
%    FilPars
%
%  OUTPUTS:
%    CaseComF     case comments, showing PSMfilt operations
%    SaveFileF    file name for filtered data (if saved)
%    PSMsigsF    filtered signals (perhaps decimated)
%    tstepF       time step for PSMsigsF
%    (others)
%
% PSMT functions called from PSMfilt:
%	PickList1
%   PSMSinc
%   PSMButr4
%   SincHP
%   PSMbox
%   PSMplot2
%   promptyn
%   PSMsave
% 
% NOTES:
% a) PSM data has minimal filtering, to allow changes in sample rates.
% b) Further display and analysis is usually preceeded by filtering.
%    Logic below is preliminary but typical.
% c) This routine is not specialized to PSM data!
%
% Modified 104/12/04.   jfh
% Modified 10/18/2006   Ning Zhou fro implementation of macro function

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

global PSMtype CFname PSMfiles PSMreftimes
%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
%keyboard
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

 
if 0
    keyboard
    save Debug_06
   
elseif 0
    clear all 
    close all
    clc
    load Debug_06
    funLoadMacro()
    PSMMacro.RunMode=1;  %run macro
%    PSMMacro.RunMode=0;  %record macro
%    PSMMacro.RunMode=-1; %normal orperation
end

disp(' ')
FNname='PSMfilt';
LcaseID=caseID;
disp(['In ' FNname ': Local caseID = ' LcaseID])

set(0,'DefaultTextInterpreter','none')

%Clear outputs
CaseComF=''; SaveFileF='';
namesF=namesX; TRangeF=TRange; tstepF=tstep;
PSMsigsF=[];

%Check inputs
if isempty(FilType),   FilType=[2 2];      end 
if length(FilType)==1, FilType(2)=[2];     end 
if isempty(FilPars),   FilPars=[0.05 1.0]; end

%Processsing is done for all channels provided as inputs

%*************************************************************************
%Generate case identification, for stamping on plots and other outputs  

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMfilt_setok'), PSMMacro.PSMfilt_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn(['In ' FNname ': Generate new case tags? '],'n');
else
    setok=PSMMacro.PSMfilt_setok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMfilt_setok=setok;
    else
        PSMMacro.PSMfilt_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% setok=promptyn(['In ' FNname ': Generate new case tags? '],'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

if setok
  disp(['Generating new case tags for case ' caseID ':'])
  [caseID,casetime,CaseComF,Gtags]=CaseTags(caseID);
  CaseComF=str2mat('New case tags in PSMfilt:',CaseComF,CaseCom);
else
  CaseComF=CaseCom;
  Gtags=str2mat(caseID,casetime);	
end
%*************************************************************************

%*************************************************************************
%Revise signal names to indicate filtering
disp(' ')
FStag='Flt';
disp(['In ' FNname ': Default tag for filtered signal = ' FStag])

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMfilt_TagsEdit'), PSMMacro.PSMfilt_TagsEdit=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_TagsEdit))      % Not in Macro playing mode or selection not defined in a macro
    TagsEdit=input(['In ' FNname ': Enter custom tag (else return) '],'s');
    if isempty(TagsEdit)
        TagsEdit=' ';
    end
else
    TagsEdit=PSMMacro.PSMfilt_TagsEdit;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMfilt_TagsEdit=TagsEdit;
    else
        PSMMacro.PSMfilt_TagsEdit=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% TagsEdit=input(['In ' FNname ': Enter custom tag (else return) '],'s');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if ~isempty(TagsEdit), FStag=TagsEdit; end
namesF=namesX(1,:); 
Lapp=size(namesX,1); 
for L=2:Lapp
  namesF=str2mat(namesF,[namesX(L,:) FStag]);
end  
disp(['In ' FNname ': Tag for filtered signal = ' FStag])
chankeyF=names2chans(namesF);
%*************************************************************************

%*************************************************************************
%Initialize plot headers
Ptitle{1}=' ';
Ptitle{2}=['LcaseID=' LcaseID '  casetime=' casetime];
%*************************************************************************

%*************************************************************************
%Logic for local decimation of present (unfiltered) data
decfac=max(fix(decfac),1);
maxpoints=size(PSMsigsX,1);
tstepF=tstep;
deftag='n'; if decfac>1, deftag=''; end
disp(['In PSMfilt: Sample rate = ' num2str(1/tstep) ' sps'])

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMfilt_rawdecimate'), PSMMacro.PSMfilt_rawdecimate=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_rawdecimate))      % Not in Macro playing mode or selection not defined in a macro
    rawdecimate=promptyn('   Local decimation of present data? ',deftag);
else
    rawdecimate=PSMMacro.PSMfilt_rawdecimate;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMfilt_rawdecimate=rawdecimate;
    else
        PSMMacro.PSMfilt_rawdecimate=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%rawdecimate=promptyn('   Local decimation of present data? ',deftag);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if rawdecimate
    disp(sprintf('In PSMfilt: Local decimation factor =%4.0i',decfac))
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/12/2007
    if ~isfield(PSMMacro, 'PSMfilt_setok03'), PSMMacro.PSMfilt_setok03=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_setok03))      % Not in Macro playing mode or selection not defined in a macro
        setok=promptyn('   Is this decimation factor ok? ', 'y');
    else
        setok=PSMMacro.PSMfilt_setok03;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMfilt_setok03=setok;
        else
            PSMMacro.PSMfilt_setok03=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 02/12/2007
    %----------------------------------------------------
  
  if ~setok
    decfac=promptnv('   Enter new decimation factor: ',decfac);
	  decfac=max(fix(decfac),1);
  end
else
  decfac=1;
end
if decfac>1
  disp(' ')
  disp(sprintf('In PSMfilt: Decimating present data'))
  tstart=PSMsigsX(1,1); upsfac=1; 
  [CaseCom,namesX,PSMsigsX,tstartRS,tstepRS,upsfac,decfac]...
     =PSMresamp(caseID,casetime,CaseCom,namesX,PSMsigsX,...
      tstart,tstep,upsfac,decfac);
  maxpoints=size(PSMsigsX,1);
	tstepF=tstepRS; NyquistF=0.5/tstepF;
  strs=['In PSMfilt: Local decimation factor = ' num2str(decfac)];
  strs=str2mat(strs,['  Local sample rate = ' num2str(1/tstepF) ' sps'])
  strs=str2mat(strs,['  Local Nyquist     = ' num2str(NyquistF)]);
  strs=str2mat(strs,['  Local maxpoints   = ' num2str(maxpoints)]);
  disp(strs)
  CaseComF=str2mat(CaseComF,strs);
	decfac=1;
  setok=promptyn('In PSMfilt: Filter decimated data? ', 'n');
  if ~setok
    PSMsigsF=PSMsigsX;
    return
  end
end
simrate=1/tstepF;
Nyquist=0.5*simrate;
%*************************************************************************

%*************************************************************************
%Set time-plot parameters
[maxpoints nsigsX]=size(PSMsigsX);
if ~isempty(findstr('time',lower(namesX(1,:))))
  startchan=2;
  time=PSMsigsX(:,1);
  tmax=time(maxpoints);
else
  startchan=1;
  tmax=(size(PSMsigsX,1)-1)*tstepF;
  time=(0:tstepF:tmax);
end
%disp(sprintf('startchan = %3.0i', startchan)) 
%disp(sprintf('[maxpoints nsigsX tmax] = %6.0i %4.0i %7.2f', [maxpoints nsigsX tmax]))
Gtags=str2mat(caseID,casetime);
%*************************************************************************

%*************************************************************************
%Remove signal offsets
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMfilt_offtrend'), PSMMacro.PSMfilt_offtrend=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_offtrend))      % Not in Macro playing mode or selection not defined in a macro
    offtrend=promptyn('In PSMfilt: Remove signal offsets?', 'y');
else
    offtrend=PSMMacro.PSMfilt_offtrend;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMfilt_offtrend=offtrend;
    else
        PSMMacro.PSMfilt_offtrend=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% offtrend=promptyn('In PSMfilt: Remove signal offsets?', 'y');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


sigoffsets=zeros(nsigsX,1);
if offtrend
  for j=startchan:nsigsX
    sigoffsets(j)=PSMsigsX(1,j);
	  trend=ones(maxpoints,1)*sigoffsets(j);
    PSMsigsX(:,j)=PSMsigsX(:,j)-trend;
  end
  clear trend;
  CaseComF=str2mat(CaseComF,'In PSMfilt: Signal offsets have been removed');
end
%*************************************************************************

%*************************************************************************
%Select signal filtering type
disp(' ')
disp('In PSMfilt: Select signal filtering type')
FilTypes=('No Smoothing or Filtering');
FilTypes=str2mat(FilTypes,'Smoothing with Moving-Average (MA) filter');
FilTypes=str2mat(FilTypes,'General filtering with Butterworth filter');
FilTypes=str2mat(FilTypes,'Moving-Average (MA) activity filter');
FilTypes=str2mat(FilTypes,'Moving-Average "Boxcar" filter');
locbase=0; maxtrys=5;
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'PSMfilt_FilTypeok'), PSMMacro.PSMfilt_FilTypeok=NaN; end
if ~isfield(PSMMacro, 'PSMfilt_FilName'), PSMMacro.PSMfilt_FilName=NaN; end
if ~isfield(PSMMacro, 'PSMfilt_FilType_1'), PSMMacro.PSMfilt_FilType_1=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_FilTypeok))      % Not in Macro playing mode or selection not defined in a macro
    [FilType(1),FilName,FilTypeok]=PickList1(FilTypes,FilType(1),locbase,maxtrys);
else
    FilTypeok=PSMMacro.PSMfilt_FilTypeok;
    FilName=PSMMacro.PSMfilt_FilName;
    FilType(1)=PSMMacro.PSMfilt_FilType_1;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMfilt_FilTypeok=FilTypeok;
        PSMMacro.PSMfilt_FilName=FilName;
        PSMMacro.PSMfilt_FilType_1=FilType(1);
    else
        PSMMacro.PSMfilt_FilTypeok=NaN;
        PSMMacro.PSMfilt_FilName=NaN;
        PSMMacro.PSMfilt_FilType_1=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% [FilType(1),FilName,FilTypeok]=PickList1(FilTypes,FilType(1),locbase,maxtrys);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if ~FilTypeok
  disp('In PSMfilt: Filtering type not determined')
  disp(' Returning to invoking Matlab function.')
  return
end
%*************************************************************************

%*************************************************************************
%Perform Filter Operations
Filtered=1;
if FilType(1)==0
  PSMsigsF=PSMsigsX;
  FilData='(No Smoothing or Filtering)';
  return
end

if FilType(1)==1
  [CaseComF,PSMsigsF,FilData,Filtered]...
    =PSMSinc(caseID,casetime,CaseComF,PSMsigsX,tstepF,startchan,FilPars);
end
if FilType(1)==2
  [CaseComF,PSMsigsF,FilData,Filtered]...
   =PSMButr4(caseID,casetime,CaseComF,PSMsigsX,tstepF,startchan,FilType,FilPars);
end
if FilType(1)==3
   [CaseComF,PSMsigsF,FilData,Filtered]...
    =SincHP(caseID,casetime,CaseComF,PSMsigsX,tstepF,startchan,FilType,FilPars);
end
if FilType(1)==4
   [CaseComF,PSMsigsF,FilData,Filtered]...
    =PSMbox(caseID,casetime,CaseComF,PSMsigsX,tstepF,startchan,FilType,FilPars);
end
if startchan>1, PSMsigsF(:,1)=PSMsigsX(:,1); end
%*************************************************************************

%*************************************************************************
Show=0;
if Filtered
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMfilt_Show'), PSMMacro.PSMfilt_Show=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_Show))      % Not in Macro playing mode or selection not defined in a macro
        Show=promptyn('In PSMfilt:  Show sample of filter effects?', 'n');
    else
        Show=PSMMacro.PSMfilt_Show;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMfilt_Show=Show;
        else
            PSMMacro.PSMfilt_Show=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % Show=promptyn('In PSMfilt:  Show sample of filter effects?', 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
end

if Show
  sigch=min(2,size(namesX,1));	%select channel for sample plot
  figure;  %Full plot
  plot (time,[PSMsigsX(:,sigch) PSMsigsF(:,sigch)])
  Ptitle{1}=['Filter Effects:' namesX(sigch,:)];
  title(Ptitle)
  xlabel('Time in Seconds')
  set(gca,'TickDir','out')
  figure;  %Detailed plot
  n1=1; n2=fix(min(50*simrate,maxpoints));
  plot (time(n1:n2),[PSMsigsX(n1:n2,sigch) PSMsigsF(n1:n2,sigch)])
  Ptitle{1}=['Filter Effects:' namesX(sigch,:)];
  title(Ptitle)
  xlabel('Time in Seconds')
  set(gca,'TickDir','out')
  disp('Processing paused - press any key to continue')
  pause
end
%*************************************************************************

%*************************************************************************
%Logic to restore signal offsets
offrestore=0;

if offtrend
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMfilt_offrestore'), PSMMacro.PSMfilt_offrestore=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_offrestore))      % Not in Macro playing mode or selection not defined in a macro
        offrestore=promptyn('In PSMfilt:  Restore signal offsets?', '');
    else
        offrestore=PSMMacro.PSMfilt_offrestore;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMfilt_offrestore=offrestore;
        else
            PSMMacro.PSMfilt_offrestore=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %  offrestore=promptyn('In PSMfilt:  Restore signal offsets?', '');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
end

if offrestore
  for j=startchan:nsigsX
	  trend=ones(maxpoints,1)*sigoffsets(j);
    PSMsigsF(:,j)=PSMsigsF(:,j)+trend;
  end
  clear trend;
  CaseComF=str2mat(CaseComF,'In PSMfilt: Signal offsets have been restored');
end
%*************************************************************************

if ~Filtered
  disp('In PSMfilt: Data not filtered - returning');
  NamesF=namesX;
  return
end

%*************************************************************************
%Logic for final decimation of filtered data
decfac=max(fix(decfac),1);
maxpoints=size(PSMsigsF,1);
if decfac>0   %Always ask
  disp(['In PSMfilt: Sample rate = ' num2str(1/tstepF) ' sps'])
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMfilt_fildecimate'), PSMMacro.PSMfilt_fildecimate=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_fildecimate))      % Not in Macro playing mode or selection not defined in a macro
        fildecimate=promptyn('  Decimate filtered data?', 'n');
    else
        fildecimate=PSMMacro.PSMfilt_fildecimate;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMfilt_fildecimate=fildecimate;
        else
            PSMMacro.PSMfilt_fildecimate=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % fildecimate=promptyn('  Decimate filtered data?', 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
  
  
  
  if fildecimate
    
    disp(sprintf('In PSMfilt: Final decimation factor =%4.0i',decfac))
    
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMfilt_decfac'), PSMMacro.PSMfilt_decfac=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_decfac))      % Not in Macro playing mode or selection not defined in a macro
        setok=promptyn('  Is this decimation factor ok? ', 'y');
        if ~setok
          decfac=input('  Enter new decimation factor: ');
          decfac=max(fix(decfac),1);
        end
    else
        decfac=PSMMacro.PSMfilt_decfac;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMfilt_decfac=decfac;
        else
            PSMMacro.PSMfilt_decfac=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
    
    
    tstart=PSMsigsF(1,1); upsfac=1; 
    [CaseComF,namesF,PSMsigsF,tstartRS,tstepRS,upsfac,decfac]...
     =PSMresamp(caseID,casetime,CaseComF,namesX,PSMsigsF,...
      tstart,tstepF,upsfac,decfac);
    maxpoints=size(PSMsigsF,1);
	  tstepF=tstepRS; NyquistF=0.5/tstepF;
    strs=['In PSMfilt: Filtered decimation factor = ' num2str(decfac)];
    strs=str2mat(strs,['  Filtered sample rate = ' num2str(1/tstepF) ' sps'])
    strs=str2mat(strs,['  Filtered Nyquist     = ' num2str(NyquistF)]);
    strs=str2mat(strs,['  Filtered maxpoints   = ' num2str(maxpoints)]);
    disp(strs)
    CaseComF=str2mat(CaseComF,strs);
  end
end
%*************************************************************************

%*************************************************************************
%Logic to plot filtered signals
for Npsets=1:20
    disp(' ')
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMfilt_setok02'), PSMMacro.PSMfilt_setok02=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMfilt_setok02))      % Not in Macro playing mode or selection not defined in a macro
       setok=promptyn('In PSMfilt: Batch plots of filtered signals? ', '');
    else
        setok=PSMMacro.PSMfilt_setok02;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMfilt_setok02=setok;
        else
            PSMMacro.PSMfilt_setok02=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %   setok=promptyn('In PSMfilt: Batch plots of filtered signals? ', '');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------

  
  if ~setok, break, end
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn('In PSMcov1: Close all plots? ', 'y');
    if closeok, close all; end    %Close all plots
  end
  maxpoints=size(PSMsigsF,1);   %Number of points in record
  nsigs    =size(PSMsigsF,2);   %Number of signals in record
  chansP=[2:nsigs];             %Signals to plot
  decfac=1;                     %Decimation factor
  n1=1; n2=maxpoints;
  t1=PSMsigsF(n1,1);            %Initial processing time
  t2=PSMsigsF(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  if Npsets>1    %Use value from prior plot cycle
    TRange=TRangeP;
  end
  Xchan=1;
  PlotPars=[];
  [CaseComP,SaveFileP,namesP,TRangeP,tstepP]...
    =PSMplot2(caseID,casetime,CaseComF,namesF,PSMsigsF(n1:n2,:),...
     chansP,TRange,tstepF,decfac,...
     Xchan,PlotPars);
  keybdok=promptyn(['In PSMfilt: Do you want the keyboard? '], 'n');
  if keybdok
    disp(['In PSMfilt: Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end  %Terminate plot loop for filtered signals
%*************************************************************************


return

%end of PSMT function



