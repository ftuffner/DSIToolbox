% Case Script PTIcase_Ex1.m
%
% PSMbrowser version PTIcase_Ex1: 
%   Example #1 for use of PSMbrowser to postprocess swing export (SWX) 
%   data from PTI stability program PSS/E.
%   SWX data assumed to be in PTI PRNT format
%
% PSMbrowser serves as a "breadboard" workstation for engineering analysis
% of power system performance data obtained from measurement systems or
% computer simulation programs.
%
%  PSMbrowser functionalities:
%    Extraction of signals from sequences of PSM raw files
%    Translation of extracted signals into standard Matlab or ASCII formats
%    Retrieval of signals previously translated and stored in standard form 
%    Merging of retrieved signals from multiple standard-form files
%    Signal plotting, with optional hardcopy and save to files
%    Signal filtering & plotting, with optional hardcopy 
%    Fourier analysis of raw or filtered signals
%    Launching of Ringdown GUI (Prony & Fourier)
%    Launching of other Matlab based add-ons
%    Processing done by the user under keyboard control
%    Saving of processing results in standard Matlab or ASCII formats
%    (Various other things)
%
%    NOTE: THIS VERSION OF PSMBROWSER HAS PROTOTYPE LOGIC FOR ARCHIVE SCANNING
%
% PSM Tools called from PSMbrowser:
%   CaseTags
%   PSMload, PSMreload
%   PSMplot2
%   PDCrefsig
%   PSMfilt
%   PSMspec1
%   PSMhist1 
%   Ringdown GUI (PSMT add-on)
%   PRSdisp1 (utilites for Ringdown GUI)
%   PSMcov1 
%   ModeMeterA   (PSMT add-on)   
%   EventScan1   (under development)
%   DXDcalcs1    (PSMT add-on)
%   SpecialDisp  (user provided)
%   PSMsave
%   promptyn, promptnv
%   (others)
%
% Related functions: 
%   DXDutilities (digital transducer logic)
%   special browsers
%
% USER NOTE #1: Customizing optional path to working directory
%   Lower in PSMbrowser there is a comment line or a command line that contains
%   text like
%     CDpath='e:\Monitor Analysis (WSCC)\;
%   Unless CDpath is empty, later code uses the indicated path to set the initial 
%   PSMbrowser working directory.  The user can revise this line into an appropriate
%   command that indicates some other path. 
%
% USER NOTE #2: Case scripts
%    Sometimes a complex processing case must be rerun at some future time.  
%    To facilitate this, the user should
%     a) Appropriately rename the PSMbrowser script file, and change the 
%        internal messages accordingly.
%     b) Modify the processing controls, internal documentation, and 
%        perhaps some present defaults within the new case script.
%    The case can then be rerun by entering the script name into the
%    Matlab Command Window.       
%  
% USER NOTE #3: Custom menus for signal extraction
%    Convenience menus for indicating the signals to extract are provided 
%    by functions with names like PDCmenu or PPSMmenu.  The user can 
%    customize these menus rather easily, but must provide a correct name
%    (CFname) for the PSM configuration file.
%
% USER NOTE #4: Combining signals
%    Some users may want to form new signals as specific combinations
%    of the signals already present.  This is straightforward, but rare 
%    enough that it has always been done manually within PSMbrowser.  A
%    menu option for this will be added when time allows.
%    
%
% Last modified 09/19/02.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

clear all		%clear all working variables
close all		%close all plot windows

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

%User should change local script name if custom features are added
CSname='PTIcase_Ex1';  %Internal name of this case script [CUSTOM]
disp(['In Case Script ' CSname])

%*************************************************************************
%General initialization
logfile='';
SaveFile=''; CFname=''; CaseHead=''; 
PSMsigsX=[]; PSMsigsF=[]; tstepF=[]; filtered=0;
DXDsigs =[];
ChainCase=''; %Control for scanning of archives or real-time data stream

%Set desired prompts
Kprompt=0;   %sets general-purpose "keyboard" commands within m-files off
ynprompt=1;	 %sets "y or n" prompts within m-files on
nvprompt=1;	 %sets numerical value prompts within m-files on
%*************************************************************************

%*************************************************************************
%Clear history data for repeat case (future functionality)
OldCaseHist=[];
OldOpHist=''; OldOpHistN=[];
%Define preset portion of processing sequence
%OldOpHistN=[1 96 99 98 7];  %Example
AutoOpOK=0; %Applies only to operations specified by OldOpHistN 
%*************************************************************************

%*************************************************************************
%Hard-wired defaults (user may want to customize these)
PSMtype='';      %Clear PSM type 
MaxFiles=1;      %Maximum number of PSM files to load  [CUSTOM]
defsok=1;        %Control for standard default returns [CUSTOM]  
if defsok
  disp(['In ' CSname ': Using standard defaults for all prompt returns:'])
  ynprompt=0; nvprompt=0;
  str1='  STANDARD DEFAULTS IN USE'; disp(str1)
end
%Define starting directory for data extraction
 CDpath='';
%CDpath='c:\Monitor Analysis (WSCC)'  %[CUSTOM]
%*************************************************************************

%*************************************************************************
%Define case header (unique to this case script)
%User should modify case header if custom features are added to case script
CaseHead='';  %Clear case header
%Build case header [CUSTOM]
str1=['In PSM Utility ' CSname ': '];
strs=[str1 'Example #1 for postprocessing of transient stability results'];
strs=str2mat(strs,'SWX data is a ringdown case from PTI stability program PSS/E');
strs=str2mat(strs,'Data format is PTI PRNT');
strs=str2mat(strs,' ');
CaseHead=strs;
disp(CaseHead)
%*************************************************************************

%*************************************************************************
%Set path to working directory 
if isempty(CDpath)
  CDfile='PSMsave';
  Nup=1; %Levels up from folder containing CDfile
  if ~isempty(CDfile)
    disp(['Setting path to working directory: CD file = ' CDfile])
    disp('User may want to customize this later')
    command=['CDloc=which(' '''' CDfile '''' ');'];
    eval(command)
    ind=find(CDloc=='\'); 
     last=ind(max(size(ind))-Nup); 
    CDpath=CDloc(1:last);
  end
end
command=['cd(' '''' CDpath '''' ');'];
eval(command);
str=cd; disp(['In ' CSname ': Starting directory = ' str])
%*************************************************************************

%************************************************************************
%Generate case identification, for stamping on plots and other outputs  
disp(' ')
disp(['In ' CSname ': Define local case tags']);
[caseID,casetime,CaseCom]=CaseTags(CSname);
caseID0=caseID; %Root value of caseID
%************************************************************************

%*************************************************************************
%Add CaseHead to CaseCom
CaseCom=str2mat(CaseCom,CaseHead);
%*************************************************************************

%************************************************************************
%Optional use of standard defaults  
disp(' ')
if ~defsok
  defsok=promptyn(['In ' CSname ': Use standard defaults for present case? '], 'n');
end
if defsok
  disp(['In ' CSname ': Using standard defaults for all prompt returns:'])
  ynprompt=0; nvprompt=0;
  str1='  STANDARD DEFAULTS ARE IN USE'; disp(str1)
  CaseCom=str2mat(CaseCom,str1);
else
  disp(['In ' CSname ': Standard defaults declined'])
end
%************************************************************************

%************************************************************************
%Optional logfile for present case  
disp(' ')
logok=promptyn(['In ' CSname ': Logfile for present case? '], 'n');
if logok
  disp(['In ' CSname ': Opening Logfile ' logfile ' for present case:'])
  logfile=[caseID '.log']; diary(logfile);
  command=['str1=which(' '''' logfile '''' ');']; eval(command);
  str2=['In ' CSname ': Logfile stored at location shown below:'];
  strs=str2mat(str2,str1);
  CaseCom=str2mat(CaseCom,strs); disp(CaseCom)
  disp(' ')
else
  disp('No Logfile for this case')
end
%************************************************************************

%************************************************************************
%Prespecify files containing signals of interest
PSMtype='PDC';  %Set default for PSM type
DataPath='';    %Clear data path
CFname='';	   	%Clear configuration file name
PSMfiles='';		%Clear data name array
%SWX Example    %[CUSTOM]
PSMtype='SWX';
CFname='PTI PRNT';
PSMfiles='';    %Indicate PTI example case if desired
if ~isempty(PSMfiles)
  disp(['In ' CSname ': Preset file names in array PSMfiles are'])
  disp(PSMfiles)
  filesok=promptyn(['In ' CSname ': Is this ok? '], 'y');
  if ~filesok
    disp('Clearing preset file names')
    DataPath=''; PSMfiles='';
  end
end
%************************************************************************

%************************************************************************
%Logic to extract signals from PSM data
disp(' ');
extractok=promptyn(['In ' CSname ': Extract/link signals from PSM source files? '], 'y');
if extractok
  %Indicate signals to extract & keep -- can modify later in processing
  %First entry should be 1 (indicating time axis)
  chansX=[1 2:10];   %Initial default
  chansX=[1 2:999];  %All possible signals [CUSTOM]
  ChainCase=''; DataPost='';
  PSMload
  if ~extractok
    retry=promptyn('Try again on signal extraction? ','n');
    if retry
      ChainCase=''; PSMfiles=''; GetRange=''; 
      PSMload
    end
  end
end
%************************************************************************

%************************************************************************
%Logic to retrieve previously extracted PSM signals
retrieveok=0;
if ~extractok
  disp(' ');
  retrieveok=promptyn(['In ' CSname ': Retrieve/merge previously extracted PSM signals? '], 'y');
  if ~retrieveok
	  disp(['In ' CSname ': No file load operations -- return']),
    retrieveok=0; diary off; return
  else
    ChainCase=0;
    PSMreload
    if filtered
	    disp(['In ' CSname ': Variable names indicate filtered signals'])
      setok=promptyn('Restart case? ', 'n');
      if setok, disp('Terminating case'), retrieveok=0; diary off;
      return, end
    end
  end
end
%************************************************************************

%************************************************************************
%Test for empty data array
if isempty(PSMsigsX)
  disp(['In ' CSname ': No signals -- return']), return
end
%************************************************************************

%************************************************************************
%Display for key to extracted signals
time=PSMsigsX(:,1); maxpoints=length(time);
Nsigs=size(PSMsigsX,2); %keyboard 
namesX0=namesX;
[namesX]=BstringOut(namesX0,' ',2);  %Delete extra blanks
chankeyX=names2chans(namesX);
if size(namesX,2)<size(namesX0,2)
  disp(['In ' CSname ': Contracting signal names']) 
end
disp(' ')
disp(sprintf(['In ' CSname ': Number of extracted signals = %3.0i'], Nsigs))
dispok=promptyn('Display channel key? ', 'n');
if dispok
  disp('Key to extracted signals:')
  disp(chankeyX)
end
keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
if keybdok
  disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end
%************************************************************************

%************************************************************************
%Menu of processing operations
OpNos=[1];        OpTypes='Batch Plots';
OpNos=[OpNos 2];  OpTypes=str2mat(OpTypes,'Angle/Freq Refs');
OpNos=[OpNos 3];  OpTypes=str2mat(OpTypes,'Filter/Decimate');
OpNos=[OpNos 4];  OpTypes=str2mat(OpTypes,'Backload Filtered');
OpNos=[OpNos 5];  OpTypes=str2mat(OpTypes,'Fourier');
OpNos=[OpNos 6];  OpTypes=str2mat(OpTypes,'Histograms');
OpNos=[OpNos 7];  OpTypes=str2mat(OpTypes,'Ringdown GUI');
OpNos=[OpNos 8];  OpTypes=str2mat(OpTypes,'Ringdown Utilities');
OpNos=[OpNos 9];  OpTypes=str2mat(OpTypes,'AutoCorrelations');
OpNos=[OpNos 21]; OpTypes=str2mat(OpTypes,'ModeMeter');
OpNos=[OpNos 22]; OpTypes=str2mat(OpTypes,'EventScan');
OpNos=[OpNos 41]; OpTypes=str2mat(OpTypes,'Phasor Utilities');
OpNos=[OpNos 42]; OpTypes=str2mat(OpTypes,'Backload Phasor Results');
OpNos=[OpNos 51]; OpTypes=str2mat(OpTypes,'Special Displays');
OpNos=[OpNos 94]; OpTypes=str2mat(OpTypes,'Downselect Signals');
OpNos=[OpNos 95]; OpTypes=str2mat(OpTypes,'Load new data');
OpNos=[OpNos 96]; OpTypes=str2mat(OpTypes,'save results');
OpNos=[OpNos 97]; OpTypes=str2mat(OpTypes,'keyboard');
OpNos=[OpNos 98]; OpTypes=str2mat(OpTypes,'Defaults on/off');
OpNos=[OpNos 99]; OpTypes=str2mat(OpTypes,'end case');
%************************************************************************

%Begin Case History
CaseHist=CaseCom(1:2,:);
OpHist='NEW CASE';
OpHistN=0;

%^^^^^^^^^^^^^^^^^
Ppass=0;
while 1   %Start of WHILE loop for data processing operations
Ppass=Ppass+1;
%^^^^^^^^^^^^^^^^^

%************************************************************************
%Menu selection of processing type
%[Automate later for Rerun cases]
disp(' ')
disp(['In Case Script ' CSname ':'])
disp(['caseID = ' caseID])
AutoOpDef='';
NOpTypes=size(OpTypes,1);
disp('Select processing type: Options are')
for N=1:NOpTypes
  disp([sprintf('   %2.0i  ',OpNos(N)) OpTypes(N,:)]); 
end
disp(' ');
prompt=['   Indicate processing type - enter number from list above'];
if Ppass>length(OldOpHistN)
  OpDef=1;
  if nvprompt==0, OpDef=[]; end    %Standard defaults are on
  OpTypeN=promptnv(prompt,OpDef);
  if isempty(OpTypeN),OpTypeN=0; end 
else
  if AutoOpOK, AutoOpDef='y'; end
  OpDef=OldOpHistN(Ppass);
  OpTypeN=promptnv(prompt,max(OpDef,1));
end
OpLoc=find(OpTypeN==OpNos);
if isempty(OpLoc)
  disp(['    Selected processing type ' num2str(OpTypeN) ' is not valid'])
  OpLoc=1; 
end
OpTypeN=OpNos(OpLoc);
Data_Op=deblank(OpTypes(OpLoc,:));
disp(['   Indicated processing type = ' num2str(OpTypeN) ': ' OpTypes(OpLoc,:)])
%************************************************************************

%************************************************************************
%GUI selection of processing type
GUI2=0;  %Supress GUI for processing loop
if GUI2
  if Ppass==1
    %PSM_ButtonsP2  %Initialize GUI for processing options
  end
  BP2_Op='';
  figure(FigNo_GUI2)
  waitforbuttonpress
  Data_Op=deblank(BP2_Op)
  %keyboard
end
%************************************************************************

%^^^^^^^^^^^^^^^^^
Data_Op=deblank(Data_Op);
switch Data_Op       %Start of SWITCH logic for data processing operations
%^^^^^^^^^^^^^^^^^

%************************************************************************
case 'Batch Plots'
disp(' ')
prompt=['In ' CSname ': Batch plots of extracted signals? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  maxpoints=size(PSMsigsX,1);   %Number of points in record
  nsigs    =size(PSMsigsX,2);   %Number of signals in record
  chansP=[2:nsigs];             %Signals to plot
  decfac=1;                     %Decimation factor
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  Xchan=1;                      %Channel for horizontal axis
  PlotPars=[];                  %(For later use)
  [CaseComP,SaveFileP,namesP,TRangeP,tstepP]...
    =PSMplot2(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
     chansP,TRange,tstep,decfac,...
     Xchan,PlotPars);
  keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end   %Terminate local case loop
%*************************************************************************

%*************************************************************************
case 'Angle/Freq Refs'
disp(' ')
prompt=['In ' CSname ': Determine relative angles & frequencies? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  RefType='VangL'; RefSigN=[]; RefSig=[];
  [CaseCom,namesX,PSMsigsX,RefType,RefSigN,RefSig]...
    =PDCrefsig(caseID,CaseCom,namesX,PSMsigsX,...
     RefType,RefSigN,RefSig);
  chankeyX=names2chans(namesX);
  keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end   %Terminate local case loop
%************************************************************************

%*************************************************************************
case 'Filter/Decimate'
disp(' ')
prompt=['In ' CSname ': Filter/Decimate extracted signals? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  maxpoints=size(PSMsigsX,1);   %Number of points in record
  nsigs    =size(PSMsigsX,2);   %Number of signals in record
  chansA=[2:nsigs];             %Signals to analyze
  decfac=1;                     %Decimation factor
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange =[t1 t2];              %Processing range
  FilType=[2 2];                %Bandpass filtering 
  FilPars=[0.05 1.0];           %Corner frequencies
  [CaseComF,SaveFileF,namesF,TRangeF,tstepF,PSMsigsF,FilPars]...
    =PSMfilt(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
     chansA,TRange,tstep,decfac,FilType,FilPars);
 end %Terminate local case loop
%*************************************************************************

%*************************************************************************
case 'Backload Filtered'
disp(' ')
prompt=['In ' CSname ': Replace extracted signals by filtered signals? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  if isempty(PSMsigsF)
     disp('   NO FILTERED SIGNALS -- GOING TO NEXT OPERATION'); break
  end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  str='Replacing extracted signals by filtered signals';
  CaseCom=CaseComF;
  CaseCom=str2mat(CaseCom,str); disp(str)
  PSMsigsX=PSMsigsF; PSMsigsF=[];
  namesX=namesF; chankeyX=names2chans(namesX);
  time=PSMsigsX(:,1); tstep=tstepF;  
  [nsigs maxpoints]=size(PSMsigsX);
  disp('Updated key to signals:')
  disp(chankeyX); disp(' ')
end %Terminate local case loop
%*************************************************************************

%*************************************************************************
case 'Fourier'
disp(' ')
prompt=['In ' CSname ': Perform Fourier analysis? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  maxpoints=size(PSMsigsX,1);   %Number of points in record
  nsigs    =size(PSMsigsX,2);   %Number of signals in record
  chansA=[2:nsigs];             %Signals to analyze
  refchan=0;                    %Reference signal or channel
  decfac=1;                     %Decimation factor
  SpecTrnd=1;                   %Trend removal mode
  WinType=2;                    %Hanning window
  FFTtype='';                   %FFT processing type
  nfft=1024*2;                  %Number of FFT points
  lap=0.90;                     %Window overlap (%)
  Nyquist=0.5/tstep;            %Nyquist frequency
  Frange=[0 Nyquist];           %Full frequency range
  Frange=[0 1.2];               %Frequency range to display
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  FFTpars=[];
  [CaseComS,SaveFileS,namesS,TRangeS,tstepS,...
    refchan,refname,fftfrq,PxxSave,PyySave,TxySave,CxySave]...
    =PSMspec1(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
     chansA,TRange,tstep,decfac,...
     refchan,SpecTrnd,WinType,nfft,lap,Frange,FFTpars);
  keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
    %Trial code for selective display of transfer function data
    %SN=5; Clevel=0.2; 
    %n1=fix(length(fftfrq)*Frange(1)/Nyquist)+1;
    %n2=round(length(fftfrq)*Frange(2)/Nyquist);
    %plot(CxySave(n1:n2,SN))
    %ind=find(CxySave(n1:n2,SN)>Clevel); xdat=fftfrq(ind);
    %plot(xdat,CxySave(ind,SN),'g.',xdat,abs(TxySave(ind,SN)),'r.',...
    %  xdat,angle(TxySave(ind,SN)),'b.')
  end
end %Terminate local case loop
%*************************************************************************

%************************************************************************
%Data_Op='Histograms';
case 'Histograms'
disp(' ')
prompt=['In ' CSname ': Do Histogram analysis? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  maxpoints=size(PSMsigsX,1);   %Number of points in record
  nsigs    =size(PSMsigsX,2);   %Number of signals in record
  chansA=[2:nsigs];             %Signals to analyze
  decfac=1;                     %Decimation factor
  HistTrnd=1;                   %Trend removal mode
  nHist=100;                    %Number of Histogram points
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  Histpars=[];
  [CaseComH,SaveFileH,namesH,TRangeH,tstepH,...
    MaxMinSave,MaxMinTSave]...
    =PSMhist1(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
     chansA,TRange,tstep,decfac,...
     HistTrnd,0,nHist,Histpars);
  disp(' ')
  disp('Display for signal limits:')
  nsigsA=size(MaxMinSave,1);
  for n=1:nsigsA
    str1=[sprintf('%3.2i  ',n) namesH(n,:)];
    str2=[sprintf('     [Max Min] = [%7.4f %7.4f]',MaxMinSave(n,:))];
    str2=[str2 sprintf('  at times  [%7.4f %7.4f]',MaxMinTSave(n,:))];
    disp(' '); disp(str2mat(str1,str2))
  end
end   %Terminate local case loop
%*************************************************************************

%*************************************************************************
case 'Ringdown GUI'    %PSMT add-on
disp(' ')
prompt=['In ' CSname ': Launch ringdown tool? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  AddOn=deblank(which('Ringdown'));  %Check presence of PSMT add-on
  if isempty(AddOn)
    disp(['In ' CSname ': Cannot find PSMT Add-On called Ringdown'])
    setok=0;  
  end  
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  InSig=[]; FixedPoles=[];
  %StepIn =[Tsw1,00; tmax,stepHt];
  %PulseIn=[Tsw1,0;Tsw2,pulsHt];
  %InSig=PulseIn;
  [maxpoints nsigs]=size(PSMsigsX);
  rgulocs=2:nsigs;  %All signals
  n1=1; timeN=time;
  swlocs=find(time(1:maxpoints-3)==time(2:maxpoints-2));
  if ~isempty(swlocs)
    disp(['In ' CSname ': Time axis indicates ' num2str(length(swlocs)) ' switching  times'])
    n1=max(swlocs); timeN=time(n1)+(0:maxpoints-n1)'*tstep;
    disp(['Ringdown analysis delayed to ' num2str(timeN(1)) ' seconds'])
  end
  keybdok=promptyn(['In ' CSname ': Do you want the keyboard first? '], 'n');
  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
    %rgulocs=[2 78];  %Special selection
  end
  rguiopts.copyplotfcn='PSMlabl';
  rguiopts.copyplotargs={caseID casetime};
  ringdown([timeN PSMsigsX(n1:maxpoints,rgulocs)],namesX(rgulocs,:),InSig,FixedPoles,rguiopts);
end   %Terminate local case loop
%*************************************************************************

%*************************************************************************
case 'Ringdown Utilities'    %PSMT add-on
disp(' ')
prompt=['In ' CSname ': Launch Ringdown utilities for existing Prony solution? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  AddOn=deblank(which('PRSdisp1'));  %Check presence of PSMT add-on
  if isempty(AddOn)
    disp(['In ' CSname ': Cannot find PSMT Add-On called PRSdisp1'])
    setok=0;  
  end  
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  ynprompt=1; nvprompt=1;
  disp(['In ' CSname ': Standard defaults off'])
  [CaseCom,PRSmodel,PRSpoles]=...
    PRSdisp1(caseID,casetime,CaseCom,namesX,PSMsigsX,tstep);
end
%************************************************************************

%************************************************************************
case 'AutoCorrelations'
disp(' ')
prompt=['In ' CSname ': Do autocorrelation analysis? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  maxpoints=size(PSMsigsX,1);   %Number of points in record
  nsigs    =size(PSMsigsX,2);   %Number of signals in record
  chansA=[2:nsigs];             %Signals to analyze
  decfac=1;                     %Decimation factor
  maxlagT=100;                  %Maximum lag in seconds
  WinType=0;                    %Window type
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  Covpars=[];                   %spare for later use
  [CaseComCV,SaveFileCV,namesCV,TRangeCV,tstepCV,...
     maxlagT]...
    =PSMcov1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansA,TRange,tstep,decfac,...
     maxlagT,WinType,Covpars);
end   %Terminate local case loop
%*************************************************************************

%************************************************************************
case 'ModeMeter'    %PSMT add-on
disp(' ')
prompt=['In ' CSname ': Launch ModeMeter? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  AddOn=deblank(which('ModeMeterA'));  %Check presence of PSMT add-on
  if isempty(AddOn)
    disp(['In ' CSname ': Cannot find PSMT Add-On called ModeMeterA'])
    setok=0;  
  end  
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  disp(chankeyX)
  chansMM=[2];                  %Signals to analyze
  decfac=1;                     %Decimation factor
  refchan=0;                    %Reference signal or channel
  SpecTrnd=1;                   %Trend removal mode
  WinType=0;                    %Boxcar data window
  TbarMM=120; 	                 %Length of processing window in seconds
  lapMM=0.80;                   %Window overlap (pu)
  Nyquist=0.5/tstep;            %Nyquist frequency
  Frange=[0 Nyquist];           %Full frequency range
  Frange=[0 2];                 %Frequency range to display
  decfrq=5;                     %Final sample rate of processed data
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  MMpars=[];
  disp(['Signals for ModeMeter: ' namesX(chansMM(1),:)]);
  clear functions
  [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
    spoles,zpoles]...
    =ModeMeterA(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
     chansMM,TRange,tstep,decfac,...
     refchan,SpecTrnd,WinType,TbarMM,lapMM,Frange,decfrq,MMpars);
end %Terminate local case loop
%************************************************************************

%*************************************************************************
case 'EventScan'
disp(' ')
prompt=['In ' CSname ': Scan for fast-event signatures? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  disp(['In ' CSname ': EventScan logic not ready for use'])
  keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
  break
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  maxpoints=size(PSMsigsX,1);   %Number of points in record
  nsigs    =size(PSMsigsX,2);   %Number of signals in record
  chansA=[2:5];                 %Signals to analyze
  decfac=1;                     %Decimation factor
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  EScanpars=[];
  [CaseComES,SaveFileES,namesES,TRangeES,tstepES,...
    ESlog]...
    =EventScan1(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
     chansA,TRange,tstep,decfac,...
     SigMeans,EScanpars);
end   %Terminate local case loop
%************************************************************************

%*************************************************************************
case 'Phasor Utilities'    %PSMT add-on
disp(' ')
prompt=['In ' CSname ': Launch utilities to process phasors or point-on-wave signals? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  AddOn=deblank(which('DXDcalcs1'));  %Check presence of PSMT add-on
  if isempty(AddOn)
    disp(['In ' CSname ': Cannot find PSMT Add-On called DXDcalcs1'])
    setok=0;  
  end  
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  ynprompt=1; nvprompt=1;
  disp(['In ' CSname ': Standard defaults off'])
  [CaseComDXD,DXDnames,tstepDXD,DXDsigs,DXDpars]=...
     DXDcalcs1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     tstep,PSMfiles);
end
%************************************************************************

%************************************************************************
case 'Backload Phasor Results'
disp(' ')
prompt=['In ' CSname ': Replace extracted signals by derived phasor signals? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  if isempty(DXDsigs)
     disp('   NO PHASOR SIGNALS -- GOING TO NEXT OPERATION'); break
  end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  str='Replacing extracted signals by derived phasor signals';
  CaseCom=CaseComDXD;
  CaseCom=str2mat(CaseCom,str); disp(str)
  PSMsigsX=DXDsigs; DXDsigs=[];
  namesX=DXDnames; chankeyX=names2chans(namesX);
  time=PSMsigsX(:,1); tstep=tstepDXD;  
  [maxpoints nsigs]=size(PSMsigsX);
  disp('Updated key to signals:')
  disp(chankeyX); disp(' ')
end %Terminate local case loop
%*************************************************************************

%************************************************************************
case 'Special Displays'
prompt=['In ' CSname ': Special Displays? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  AddOn=deblank(which('SpecialDisp'));  %Check presence of PSMT add-on
  if isempty(AddOn)
    disp(['In ' CSname ': Cannot find PSMT Add-On called SpecialDisp'])
    setok=0;  
  end  
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  SpecialDisp
end
%************************************************************************

%*************************************************************************
case 'Downselect Signals'
disp(' ')
prompt=['In ' CSname ': Downselect Signals? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  newtags=promptyn(['In ' CSname ': Generate new case tags? '], 'n');
  if newtags
    disp(['Generating new case tags for case ' caseID ':'])
    [caseID,casetime,CaseCom,Gtags]=CaseTags(caseID);
  end
  [MenuName,chansN,chansNok]=PickSigs(1:nsigs,namesX,chankeyX,CSname);
  if isempty(chansN)
     disp('   NO SIGNALS SELECTED -- GOING TO NEXT OPERATION'); break
  end
  if chansN(1)~=1, chansN(1)=1, ; end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  str='Downselecting signals:';
  CaseCom=str2mat(CaseCom,str); disp(str)
  PSMsigsX=PSMsigsX(:,chansN);
  namesX=namesX(chansN,:); chankeyX=names2chans(namesX);
  time=PSMsigsX(:,1);   
  [nsigs maxpoints]=size(PSMsigsX);
  disp('Updated key to signals:')
  disp(chankeyX); disp(' ')
end %Terminate local case loop
%*************************************************************************

%************************************************************************
case 'Load new data'
prompt=['In ' CSname ': Load new data? '];
setok=promptyn(prompt,'');
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  newtags=promptyn(['In ' CSname ': Generate new case tags? '], 'n');
  if newtags
    disp(['Generating new case tags for case ' caseID ':'])
    [caseID,casetime,CaseCom,Gtags]=CaseTags(caseID);
  end
  extractok=0;
  ChainCase=''; PSMfiles=''; CFname='';  PSMtype=''; 
  GetRange=''; loadopt=''; rmsopt=''; 
  PSMload
  if ~extractok==1, 
    disp('New data not loaded')
    disp(' ');
    retrieveok=promptyn(['In ' CSname ': Retrieve/merge previously extracted PSM signals? '], 'y');
    if retrieveok
      ChainCase=0;
      PSMreload
    end
  end
end
%************************************************************************

%************************************************************************
%Optional data save to file
case 'save results'
disp(' ')
disp('Loop for saving data to files:')
for tries=1:10
  disp(' ')
  disp(['In ' CSname ': Invoking utility to save extracted signals'])
  maxpoints=size(PSMsigsX,1);   %Number of points in record
  nsigs    =size(PSMsigsX,2);   %Number of signals in record
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  CaseComR=CaseCom;
  SaveList=['PSMtype PSMsigsX tstep namesX chankeyX CaseComR PSMfiles PSMreftimes CFname'];
  PSMsave
  if isempty(SaveFile), break, end
end
%************************************************************************

%************************************************************************
case 'keyboard'
  keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], '');
  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
%************************************************************************

%************************************************************************
case 'Defaults on/off'
%Optional use of standard defaults  
disp(' ')
defsok=promptyn(['In ' CSname ': Use standard defaults for case remainder? '], '');
if defsok
  disp(['In ' CSname ': Using standard defaults for all prompt returns:'])
  ynprompt=0; nvprompt=0;
  str1='  STANDARD DEFAULTS ARE IN USE'; disp(str1)
  CaseCom=str2mat(CaseCom,str1);
else
  ynprompt=1; nvprompt=1;
  disp(['In ' CSname ': Standard defaults declined'])
end
%************************************************************************

%************************************************************************
case 'end case'
endok=promptyn(['In ' CSname ': End this case? '], '');
if endok
  disp(['In ' CSname ': Ending present case - Return from ' CSname])
  if ~isempty(logfile)
    command=['str1=which(' '''' logfile '''' ');']; eval(command);
    str2=['In ' CSname ': Logfile stored at location shown below:'];
    strs=str2mat(str2,str1); disp(strs)
    CaseCom=str2mat(CaseCom,strs);
  end
  %Temporary diagnostics for future development of case rerun capability
  CaseHist=CaseHist;
  OpHist=OpHist;
  OpHistN=OpHistN;
  diary off; return
end
%************************************************************************

%^^^^^^^^^^^^^^^^^
end  %Termination of SWITCH logic for processing operations
end  %Termination of WHILE loop for processing operations
%^^^^^^^^^^^^^^^^^


%end of PSMT case script

