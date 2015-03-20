% Case Script PSMbrowser.m
%
% Standard version of PSMbrowser
% Other versions have special features for convenience
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
%   PickSigsN
%   PSMplot2
%   PDCrefsig
%   PSMfilt
%   PSMspec1
%   PSMhist1 
%   Ringdown GUI (PSMT add-on)
%   PRSdisp1 (utilites for Ringdown GUI)
%   PSMcov1 
%   ModeMeterM   (PSMT add-on)   
%   EventScan1   (under development)
%   DXDcalcs1    (PSMT add-on)
%   SpecialDisp  (user provided)
%   PSMsave
%   CkTsteps
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
%    enough that it has always been done manually within PSMbrowser.
%    A menu option for this will be added when time allows.
%    
%
% Modified 05/19/05.  jfh  CDpath logic  
% Modified 09/07/05.  jfh  Try/Catch logic for major processing options 
% Modified 03/31/06   zn   to add maro functions
% Modified 03/03/14   fkt  Add SQL item and more functions


% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

clear all		%clear all working variables
close all		%close all plot windows

%Attempt to load JAR support for SQL
%Must be done before global declarations, or it breaks them
funApplySQLJAR;

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMpaths PSMreftimes

%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
global PSMMacro         % Macro Structure  
if isempty(PSMMacro)
    funLoadMacro(); 
end
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
% End: Macro definition ZN 03/31/06
%----------------------------------------------------
%User should change local script name if custom features are added
CSname='PSMbrowser';  %Internal name of this case script
disp(['In Case Script ' CSname])

%*************************************************************************
%General initialization
logfile='';
SaveFile=''; CFname=''; CaseHead=''; 
PSMsigsX=[]; PSMsigsF=[]; tstepF=[]; filtered=0;
DXDsigs =[]; DXDnames=''; CaseComDXD='';
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
MaxFiles=30;     %Maximum number of PSM files to load
defsok=0;        %Control for standard default returns  
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
%Build case header
str1=['In PSM Utility ' CSname ': '];
strs=[str1 'General browsing of PSM data files'];
strs=str2mat(strs,' ');
CaseHead=strs;
disp(CaseHead)
%*************************************************************************

%*************************************************************************
%Set path to working directory 
%Set default path
CDfile='PSMsave';
Nup=1; %Levels up from folder containing CDfile
if ~isempty(CDfile)
  command=['CDloc=which(' '''' CDfile '''' ');'];
  eval(command)
  ind=find(CDloc=='\'); 
  last=ind(max(size(ind))-Nup); 
  CDpath0=CDloc(1:last);
end
if isempty(CDpath), CDpath=CDpath0; end
if ~isempty(CDpath)
  disp(['Setting path to custom working directory: CDpath = ' CDpath])
  try
    command=['cd(' '''' CDpath '''' ');'];  eval(command);
  catch
    disp(['Cannot find custom directory ' CDpath])
    disp(['Reverting to PSMtools directory ' CDpath0])
    try
      command=['cd(' '''' CDpath0 '''' ');'];  eval(command);
    catch
      disp(['Cannot find PSWMtools directory ' CDpath0])
    end
  end
end
CDpath=cd; disp(['In ' CSname ': Starting directory = ' CDpath])
command=['addpath(' '''' CDpath '''' ');']; eval(command)
%*************************************************************************

%************************************************************************
%Generate case identification, for stamping on plots and other outputs  
disp(' ')
disp(['In ' CSname ': Define new case tags']);
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
   %----------------------------------------------------
   % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMbrowser_defsok'), PSMMacro.PSMbrowser_defsok=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_defsok))      % Macro definition mode or selection not defined in a macro
        defsok=promptyn(['In ' CSname ': Use standard defaults for present case? '], 'n');
    else
        defsok=PSMMacro.PSMbrowser_defsok;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_defsok=defsok;
        else
            PSMMacro.PSMbrowser_defsok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
 
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
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro, 'PSMbrowser_logok'), PSMMacro.PSMbrowser_logok=NaN;end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_logok))      % Macro definition mode or selection not defined in a macro
   logok=promptyn(['In ' CSname ': Logfile for present case? '], 'n');
else
   logok=PSMMacro.PSMbrowser_logok;
end
    
if PSMMacro.RunMode==0      % if in macro definition mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbrowser_logok=logok;
    else
         PSMMacro.PSMbrowser_logok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------



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
PSMfiles='';    %Clear data file name array
PSMpaths='';    %Clear data file path array
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
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro, 'PSMbrowser_extractok'), PSMMacro.PSMbrowser_extractok=NaN;end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_extractok))      % Macro definition mode or selection not defined in a macro
   extractok=promptyn(['In ' CSname ': Extract/link signals from PSM source files? '], 'y');
else
   extractok=PSMMacro.PSMbrowser_extractok;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbrowser_extractok=extractok;
    else
        PSMMacro.PSMbrowser_extractok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------




if extractok
  %Indicate signals to extract & keep -- can modify later in processing
  chansX=[1 2:10];  %Initial defaults 
  if ~isempty(findstr('ppsm',lower(PSMtype)))
    chansX=[2:10];  %Initial defaults for PPSM
  end 
  ChainCase=''; DataPost='';
  PSMload
  if ~extractok
    retry=promptyn('Try again on signal extraction? ','');
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
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMbrowser_retrieveok'), PSMMacro.PSMbrowser_retrieveok=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_retrieveok))      % Macro definition mode or selection not defined in a macro
       retrieveok=promptyn(['In ' CSname ': Retrieve/merge previously extracted PSM signals? '], 'y');
    else
       retrieveok=PSMMacro.PSMbrowser_retrieveok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_retrieveok=retrieveok;
        else
            PSMMacro.PSMbrowser_retrieveok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
  
  
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
time=PSMsigsX(:,1);
[maxpoints,nsigs]=size(PSMsigsX); 
namesX0=namesX;
[namesX]=BstringOut(namesX0,' ',2);  %Delete extra blanks
chankeyX=names2chans(namesX);
if size(namesX,2)<size(namesX0,2)
  disp(['In ' CSname ': Contracting signal names']) 
end
disp(' ')
disp(sprintf(['In Case Script ' CSname ': Number of extracted signals = %3.0i'],nsigs))
disp(['caseID = ' caseID])

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro, 'PSMbrowser_dispok'), PSMMacro.PSMbrowser_dispok=NaN;end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_dispok))      % Macro definition mode or selection not defined in a macro
    dispok=promptyn('Display channel key? ', 'n');
else
    dispok=PSMMacro.PSMbrowser_dispok;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbrowser_dispok=dispok;
    else
        PSMMacro.PSMbrowser_dispok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------



if dispok
  disp('Key to extracted signals:')
  disp(chankeyX)
end

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if (PSMMacro.RunMode<1)
    keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
else
    keybdok=0;
end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------    

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
OpNos=[OpNos 10]; OpTypes=str2mat(OpTypes,'User Interfaced Functions');
OpNos=[OpNos 20]; OpTypes=str2mat(OpTypes,'ModeMeter GUI');
OpNos=[OpNos 21]; OpTypes=str2mat(OpTypes,'ModeMeter');
OpNos=[OpNos 22]; OpTypes=str2mat(OpTypes,'EventScan');
OpNos=[OpNos 41]; OpTypes=str2mat(OpTypes,'Phasor Utilities');
OpNos=[OpNos 42]; OpTypes=str2mat(OpTypes,'Backload Phasor Results');
OpNos=[OpNos 51]; OpTypes=str2mat(OpTypes,'Special Displays');
OpNos=[OpNos 90]; OpTypes=str2mat(OpTypes,'Macro (R)ecord');
OpNos=[OpNos 91]; OpTypes=str2mat(OpTypes,'Macro (P)lay (G)o');
OpNos=[OpNos 92]; OpTypes=str2mat(OpTypes,'Macro (S)top');
OpNos=[OpNos 94]; OpTypes=str2mat(OpTypes,'DownSelect Signals');
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
chansP0=[];
chansF0=[];
chansA0=[];
chansMM0=[]; refchansMM0=[]; 

%^^^^^^^^^^^^^^^^^
Ppass=0;
while 1   %Start of WHILE loop for data processing operations
Ppass=Ppass+1;
%^^^^^^^^^^^^^^^^^
disp(' ');
disp(' ');
subDispPrompt
disp(' ');
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
  
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro,'PSMbrowser_OpTypeN'), PSMMacro.PSMbrowser_OpTypeN=NaN; end
%   if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_OpTypeN))      % Not in Macro playing mode or selection not defined in a macro
    if (PSMMacro.RunMode<2 || isnan(PSMMacro.PSMbrowser_OpTypeN))      % Not in Macro batch playing mode or selection not defined in a macro        
          OpTypeN=promptnv(prompt,OpDef);
          if isempty(OpTypeN),OpTypeN=0; end 
    else
          OpTypeN=PSMMacro.PSMbrowser_OpTypeN;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if (PSMMacro.PauseMode==0 )          % if record mode is not paused
            if OpTypeN<90
                PSMMacro.PSMbrowser_OpTypeN=OpTypeN;
            end
        else
            PSMMacro.PSMbrowser_OpTypeN=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
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

disp(['   Indicated processing type = ' num2str(OpTypeN) ': ' OpTypes(OpLoc,:)]);

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
try
switch Data_Op       %Start of SWITCH logic for data processing operations
%^^^^^^^^^^^^^^^^^

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
case 'Macro (R)ecord'
    LockCtrl=1; KeyCtrl=99;   MacroNum=0;   RunMode=0;   PauseMode=0;
    [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
    if (Key~=99)            % not be able to lock the Macro
        PSMMacro.RunMode=0;
    end
    disp('Macro Recording Started !');
case 'Macro (P)lay (G)o'
     LockCtrl=1;   KeyCtrl=99;   MacroNum=0;   RunMode=1;   PauseMode=0;
     [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
    if (Key~=99)            % not be able to lock the Macro
        PSMMacro.RunMode=1;
    end
    disp('Macro Playing Started !');
case 'Macro (S)top'
     LockCtrl=1; KeyCtrl=99; MacroNum=0; RunMode=-1; PauseMode=0; % open the lock and hibernate the macro
     [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
     if (Key~=99)            % not be able to lock the Macro
        PSMMacro.RunMode=-1;
     end
     disp('Macro stopped!');
% End: Macro selection ZN 03/31/06
%----------------------------------------------------    

%************************************************************************
case 'Batch Plots'
disp(' ')
prompt=['In ' CSname ': Batch plots of extracted signals? '];
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMbrowser_setok'), PSMMacro.PSMbrowser_setok=NaN; end
    if (PSMMacro.RunMode<2 || isnan(PSMMacro.PSMbrowser_setok))      % Not in Macro playing mode or selection not defined in a macro
        setok=promptyn(prompt,AutoOpDef);
    else
        setok=PSMMacro.PSMbrowser_setok;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_setok=setok;
        else
            PSMMacro.PSMbrowser_setok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------



for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMbrowser_closeok'), PSMMacro.PSMbrowser_closeok=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_closeok))      % Not in Macro playing mode or selection not defined in a macro
        closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    else
        closeok=PSMMacro.PSMbrowser_closeok;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_closeok=closeok;
        else
            PSMMacro.PSMbrowser_closeok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------  
    
    
    if closeok, close all; end    %Close all plots
  end
  [maxpoints,nsigs]=size(PSMsigsX); 
  if isempty(chansP0)           %Signals to plot
    chansP=[2:nsigs];
  else
    chansP=chansP0;
  end
  decfac=1;                     %Decimation factor
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  Xchan=1;                      %Channel for horizontal axis
  PlotPars=[];                  %(For later use)


  
  [CaseComP,SaveFileP,namesP,TRangeP,tstepP,chansP0]...
    =PSMplot2(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
     chansP,TRange,tstep,decfac,...
     Xchan,PlotPars);
 %----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if (PSMMacro.RunMode<1)
    keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
else
    keybdok=0;
end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------    
%  keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
    if 0
      NPsigs=length(chansP0); PPt=1;
      for N=1:NPsigs
        loc=chansP0(N);
        Pline=[chankeyX(loc,:) ' = ' num2str(PSMsigsX(PPt,loc))];
        disp(Pline)
      end
    end
  end
  
   %----------------------------------------------------
   % Begin: Macro selection ZN 03/31/06
   if PSMMacro.RunMode==2 || PSMMacro.RunMode==0           % if in the macro play or record mode
       StopMacroOk=promptyn(['In ' CSname ': Do you want the stop macro? '], 'y');
       if StopMacroOk
            PSMMacro.RunMode=-1;        % macro stopped and macro is in the hibernate mode
            disp(['In ' CSname ': Macro is stopped (hibernated).'])
       end
   end
   % End: Macro selection ZN 03/31/06
   %----------------------------------------------------

   
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
  RefType='VAngL'; RefSigN=[]; RefSig=[];
  [CaseCom,namesX,PSMsigsX,RefType,RefSigN,RefSig]...
    =PDCrefsig(caseID,CaseCom,namesX,PSMsigsX,...
     RefType,RefSigN,RefSig,tstep);
  chankeyX=names2chans(namesX);
  %----------------------------------------------------
  % Begin: Macro selection ZN 03/31/06
  if (PSMMacro.RunMode<1)
        keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
  else
      keybdok=0;
  end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------    
 
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
        %----------------------------------------------------
        % Begin: Macro selection ZN 03/31/06
        if ~isfield(PSMMacro, 'PSMbrowser_closeok03'), PSMMacro.PSMbrowser_closeok03=NaN;end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_closeok03))      % Not in Macro playing mode or selection not defined in a macro
           closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
        else
            closeok=PSMMacro.PSMbrowser_closeok03;
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PSMbrowser_closeok03=closeok;
            else
                PSMMacro.PSMbrowser_closeok03=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        % End: Macro selection ZN 03/31/06
        %----------------------------------------------------
        %closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
        if closeok, close all; end    %Close all plots
  end
  [maxpoints,nsigs]=size(PSMsigsX); 
  if isempty(chansF0)           %Signals to plot
    chansF=[2:nsigs];
  else
    chansF=chansP0;
  end
  decfac=1;                     %Decimation factor
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange =[t1 t2];              %Processing range
  FilType=[2 2];                %Bandpass filtering 
  FilPars=[0.05 1.0];           %Corner frequencies
  [CaseComF,SaveFileF,namesF,TRangeF,tstepF,PSMsigsF,FilPars]...
    =PSMfilt(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
     chansF,TRange,tstep,decfac,FilType,FilPars);
 end %Terminate local case loop
%*************************************************************************

%*************************************************************************
case 'Backload Filtered'
disp(' ')
prompt=['In ' CSname ': Backload filtered signals into working signals? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  if isempty(PSMsigsF)
     disp('   NO FILTERED SIGNALS -- GOING TO NEXT OPERATION'); break
  end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  prompt=['  Replace working signals by filtered signals? '];


    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMbrowser_RepOK'), PSMMacro.PSMbrowser_RepOK=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_RepOK))      % Not in Macro playing mode or selection not defined in a macro
        RepOK=promptyn(prompt);
    else
        RepOK=PSMMacro.PSMbrowser_RepOK;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_RepOK=RepOK;
        else
            PSMMacro.PSMbrowser_RepOK=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------  
  
  
  if RepOK
    str='Replacing working signals by filtered signals';
    CaseCom=str2mat(CaseComF,str); disp(str)
    PSMsigsX=PSMsigsF;
    namesX=namesF; 
    tstep=tstepF;
    clear PSMsigsF
  end
  AppOK=0;
  if ~RepOK
    prompt=['  Append filtered signals to working signals? '];
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMbrowser_AppOK'), PSMMacro.PSMbrowser_AppOK=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_AppOK))      % Not in Macro playing mode or selection not defined in a macro
        AppOK=promptyn(prompt);
    else
        AppOK=PSMMacro.PSMbrowser_AppOK;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_AppOK=AppOK;
        else
            PSMMacro.PSMbrowser_AppOK=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
    
  end
  if AppOK 
    [maxptsX nsigsX]=size(PSMsigsX);
    [maxptsF nsigsF]=size(PSMsigsF);
    if maxptsF~=maxptsX  %Apply dimensional checks etc (need more)
      disp(['In ' CSname ': Cannot append filtered signals to working signals'])
      disp('  Dimensional mismatch: ')
      strX=['    Number of points in working signals  = ' num2str(maxptsX)];
      strX=[strX '  tstep=' num2str(tstepF)];
      strF=['    Number of points in filtered signals = ' num2str(maxptsF)];
      strF=[strF '  tstep=' num2str(tstep)];
      disp(strX); disp(strF)
      break
    end
    str='Appending filtered signals to working signals';
    CaseCom=str2mat(CaseCom,CaseComF,str); disp(str)
    PSMsigsX=[PSMsigsX PSMsigsF(:,2:nsigsF)];
    namesX=str2mat(namesX,namesF(2:nsigsF,:));
    clear PSMsigsF
  end  
  chankeyX=names2chans(namesX);
  [maxpoints,nsigs]=size(PSMsigsX); 
  time=PSMsigsX(:,1); 
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
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMbrowser_closeok05'), PSMMacro.PSMbrowser_closeok05=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_closeok05))      % Not in Macro playing mode or selection not defined in a macro
        closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    else
        closeok=PSMMacro.PSMbrowser_closeok05;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_closeok05=closeok;
        else
            PSMMacro.PSMbrowser_closeok05=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------  
    if closeok, close all; end    %Close all plots
  end
  [maxpoints,nsigs]=size(PSMsigsX); 
  if isempty(chansA0)           %Signals to analyze
    chansA=[2:nsigs];
    refchan=0;                  %Reference signal or channel
  else
    chansA=chansA0;
  end
  decfac=1;                     %Decimation factor
  Nyquist=0.5/tstep;            %Nyquist frequency
  SpecTrnd=1;                   %Trend removal mode
  WinType=2;                    %Hanning window
  FFTtype='';                   %FFT processing type
  nfft=1024*2;                  %Number of FFT points
  lap=0.90;                     %Window overlap (%)
  Frange=[0 Nyquist];           %Full frequency range
  Frange=[0 1.2];               %Frequency range to display
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  FFTpars=[];
  [CaseComS,SaveFileS,namesS,TRangeS,tstepS,...
   refchan,refname,fftfrq,PxxSave,PyySave,TxySave,CxySave,chansA0]...
    =PSMspec1(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
     chansA,TRange,tstep,decfac,...
     refchan,SpecTrnd,WinType,nfft,lap,Frange,FFTpars);
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if (PSMMacro.RunMode<1)
        keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
    else
        keybdok=0;
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------    

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
     %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMbrowser_closeok06'), PSMMacro.PSMbrowser_closeok06=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_closeok06))      % Not in Macro playing mode or selection not defined in a macro
        closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    else
        closeok=PSMMacro.PSMbrowser_closeok06;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_closeok06=closeok;
        else
            PSMMacro.PSMbrowser_closeok06=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------    
    
    if closeok, close all; end    %Close all plots
  end
  [maxpoints,nsigs]=size(PSMsigsX); 
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
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMbrowser_closeok07'), PSMMacro.PSMbrowser_closeok07=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_closeok07))      % Not in Macro playing mode or selection not defined in a macro
       closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    else
        closeok=PSMMacro.PSMbrowser_closeok07;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_closeok07=closeok;
        else
            PSMMacro.PSMbrowser_closeok07=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------    
    if closeok, close all; end    %Close all plots
  end
  InSig=[]; FixedPoles=[];
  %StepIn =[Tsw1,00; tmax,stepHt];
  %PulseIn=[Tsw1,0;Tsw2,pulsHt];
  %InSig=PulseIn;
  [maxpoints nsigs]=size(PSMsigsX);
  rgulocs=2:nsigs;  %All signals
  time=PSMsigsX(:,1);
  n1=1; n2=maxpoints; timeN=time;
  smoothdef=0.03;
  [CaseCom,timeNN,tstepN,swlocs,roughlocs,smoothdef]...
    =CkTsteps(caseID,casetime,CaseCom,time,tstep,smoothdef);
  if ~isempty(swlocs)
    disp(['In ' CSname ': Time axis indicates ' num2str(length(swlocs)) ' switching  times'])
    n1=max(swlocs)+2; 
    disp(['Ringdown analysis delayed to ' num2str(time(n1)) ' seconds n1= ' num2str(n1) ' samples'])
  end
  if ~isempty(roughlocs)
    n2locs=roughlocs(find(roughlocs>=n1));
    if ~isempty(n2locs)
      n2=n2locs(1)-1;
      disp(['Ringdown analysis limited to ' num2str(time(n2)) ' seconds n2= ' num2str(n2) ' samples'])
    end
  end 
  timeN=time(n1)+(0:n2-n1)'*tstep;
  if (n2-n1)<10
    disp(['Ringdown analysis limited to ' num2str(time(n2)) ' seconds n2= ' num2str(n2) ' samples'])
    disp('Record too short for Prony analyis:')
    disp('Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
  if (n2-n1)<10
    disp(['Ringdown analysis limited to ' num2str(time(n2)) ' seconds n2= ' num2str(n2) ' samples'])
    disp('Record too short for Prony analyis -- Return'), break
  end
  
   %----------------------------------------------------
   % Begin: Macro selection ZN 02/08/07
    if ~isfield(PSMMacro, 'PSMbrowser_keybdok'), PSMMacro.PSMbrowser_keybdok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_keybdok))      % Not in Macro playing mode or selection not defined in a macro
        keybdok=promptyn(['In ' CSname ': Do you want the keyboard first? '],'n');
    else
        keybdok=PSMMacro.PSMbrowser_keybdok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_keybdok=keybdok;
        else
            PSMMacro.PSMbrowser_keybdok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %   keybdok=promptyn(['In ' CSname ': Do you want the keyboard first?
    %   '],'n');
    % End: Macro selection ZN 02/08/07
    %----------------------------------------------------
    

  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
    %rgulocs=[2 78];  %Special selection
  end
  timeN=time(n1)+(0:n2-n1)'*tstep;
  
   %----------------------------------------------------
   % Begin: Macro selection ZN 02/08/07
    if ~isfield(PSMMacro, 'PSMbrowser_menusok'), PSMMacro.PSMbrowser_menusok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_menusok))      % Not in Macro playing mode or selection not defined in a macro
        menusok=promptyn(['In ' CSname ': Do you want signal selection menus? '], '');
    else
        menusok=PSMMacro.PSMbrowser_menusok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_menusok=menusok;
        else
            PSMMacro.PSMbrowser_menusok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %   menusok=promptyn(['In ' CSname ': Do you want signal selection
    %   menus? '], '');
    % End: Macro selection ZN 02/08/07
    %----------------------------------------------------

  

  if menusok %Select signals to process
    disp(' ')
    disp(['In ' CSname ':  Select signals for input to GUI']);
    PRcom='input to GUI';
    
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/08/2007
    if ~isfield(PSMMacro, 'PSMbrowser_chansPok'), PSMMacro.PSMbrowser_chansPok=NaN;end
    if ~isfield(PSMMacro, 'PSMbrowser_chansP'), PSMMacro.PSMbrowser_chansP=''; end
    if ~isfield(PSMMacro, 'PSMbrowser_MenuName'), PSMMacro.PSMbrowser_MenuName='';end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_chansPok))      % Not in Macro playing mode or selection not defined in a macro
        [MenuName,chansP,chansPok]=PickSigsN(rgulocs,namesX,chankeyX,'',PRcom);
        %[MenuName,chansP,chansPok]=PickSigsN(chansP,namesX,chankeyX,'','plotting');
    else
        chansPok=PSMMacro.PSMbrowser_chansPok;
        chansP=PSMMacro.PSMbrowser_chansP;
        MenuName=PSMMacro.PSMbrowser_MenuName;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_chansPok=chansPok;
            PSMMacro.PSMbrowser_chansP=chansP;
            PSMMacro.PSMbrowser_MenuName=MenuName;
        else
            PSMMacro.PSMbrowser_chansPok=NaN;
            PSMMacro.PSMbrowser_chansP='';
            PSMMacro.PSMbrowser_MenuName='';
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 02/08/2007
    %----------------------------------------------------  
    
    
    if ~chansPok
      disp(' No menu selections')
      chansP=[];
    end
    locsP=find(chansP>1); chansP=chansP(locsP);
    if ~isempty(chansP), rgulocs=chansP; end
  end
  timeN=timeN(1:(n2-n1+1)); %Safety check
  rguiopts.copyplotfcn='PSMlabl';
  rguiopts.copyplotargs={caseID casetime};
  ringdown([timeN PSMsigsX(n1:n2,rgulocs)],namesX(rgulocs,:),InSig,FixedPoles,rguiopts);
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
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMbrowser_closeok08'), PSMMacro.PSMbrowser_closeok08=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_closeok08))      % Not in Macro playing mode or selection not defined in a macro
       closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    else
        closeok=PSMMacro.PSMbrowser_closeok08;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_closeok08=closeok;
        else
            PSMMacro.PSMbrowser_closeok08=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------  
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
        %----------------------------------------------------
        % Begin: Macro selection ZN 03/31/06
        if ~isfield(PSMMacro, 'PSMbrowser_closeok09'), PSMMacro.PSMbrowser_closeok09=NaN;end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_closeok09))      % Not in Macro playing mode or selection not defined in a macro
           closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
        else
            closeok=PSMMacro.PSMbrowser_closeok09;
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PSMbrowser_closeok09=closeok;
            else
                PSMMacro.PSMbrowser_closeok09=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        % End: Macro selection ZN 03/31/06
        %----------------------------------------------------
        if closeok, close all; end    %Close all plots
  end
  [maxpoints,nsigs]=size(PSMsigsX); 
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
case 'User Interfaced Functions'
disp(' ')
prompt=['In ' CSname ': Do General User Interface Functions? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next user functions'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
        %----------------------------------------------------
        % Begin: Macro selection ZN 03/31/06
        if ~isfield(PSMMacro, 'PSMbrowser_closeok10'), PSMMacro.PSMbrowser_closeok10=NaN;end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_closeok10))      % Not in Macro playing mode or selection not defined in a macro
           closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
        else
            closeok=PSMMacro.PSMbrowser_closeok10;
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PSMbrowser_closeok10=closeok;
            else
                PSMMacro.PSMbrowser_closeok10=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        % End: Macro selection ZN 03/31/06
        %----------------------------------------------------
        if closeok, close all; end    %Close all plots
  end
  
  %Call the overview function - pass everything relevant in and pull
  %everything relevant back out -- avoids globals internally
  [CFname,PSMfiles,PSMsigsX,chankeyX,tstep,CaseCom,PSMreftimes,...
      PSMtype,namesX]=funUserFunctionInterface(CFname,PSMfiles,...
      PSMsigsX,chankeyX,tstep,CaseCom,PSMreftimes,PSMtype,namesX);
  
end   %Terminate local case loop
%*************************************************************************

%??
%************************************************************************
case 'ModeMeter GUI'    %PSMT add-on by Ning Zhou 08/21/2008
disp(' ')
prompt=['In ' CSname ': Launch ModeMeter GUI? '];
setok=promptyn(prompt,AutoOpDef);


for N=1:1
  AddOn=deblank(which('ModeMeterOfflineDemo'));  %Check presence of PSMT add-on
  if isempty(AddOn)
    disp(['In ' CSname ': Cannot find PSMT Add-On called [ModeMeterOfflineDemo]'])
    setok=0;  
  end  
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];

  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');     
    if closeok, close all; end    %Close all plots
  end
    clear functions
    ModeMeterOfflineDemo
%   [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
%     chansMM0,refchansMM0]...
%     =ModeMeterM(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%      chansMM,TRange,tstep,decfac,...
%      refchansMM,SpecTrnd,WinType,TbarMM,lapMM,Frange,decfrq,MMpars);
end %Terminate local case loop
%************************************************************************

%??





%************************************************************************
case 'ModeMeter'    %PSMT add-on
disp(' ')
prompt=['In ' CSname ': Launch ModeMeter? '];

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMbrowser_setok21'), PSMMacro.PSMbrowser_setok21=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_setok21))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn(prompt,AutoOpDef);
else
    setok=PSMMacro.PSMbrowser_setok21;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbrowser_setok21=setok;
    else
        PSMMacro.PSMbrowser_setok21=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% setok=promptyn(prompt,AutoOpDef);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


for N=1:1
  AddOn=deblank(which('ModeMeterM'));  %Check presence of PSMT add-on
  if isempty(AddOn)
    disp(['In ' CSname ': Cannot find PSMT Add-On called ModeMeterM'])
    setok=0;  
  end  
  if ~setok, disp('Proceeding to next processing phase'), break, end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMbrowser_closeok21'), PSMMacro.PSMbrowser_closeok21=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_closeok21))      % Not in Macro playing mode or selection not defined in a macro
        closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    else
        closeok=PSMMacro.PSMbrowser_closeok21;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMbrowser_closeok21=closeok;
        else
            PSMMacro.PSMbrowser_closeok21=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------    

    if closeok, close all; end    %Close all plots
  end
  [maxpoints,nsigs]=size(PSMsigsX); 
  if isempty(chansMM0)          %Output signals for ModeMeter
    chansMM=[2:nsigs];
  else
    chansMM=chansMM0;
  end   
  refchansMM=refchansMM0;       %Input signals for ModeMeter
  decfac=1;                     %Decimation factor
  SpecTrnd=1;                   %Trend removal mode
  WinType=0;                    %Boxcar data window
  TbarMM=120; 	                %Length of processing window in seconds
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
  clear functions
  [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
    chansMM0,refchansMM0]...
    =ModeMeterM(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansMM,TRange,tstep,decfac,...
     refchansMM,SpecTrnd,WinType,TbarMM,lapMM,Frange,decfrq,MMpars);
end %Terminate local case loop
%************************************************************************

%*************************************************************************
case 'EventScan'
disp(' ')
prompt=['In ' CSname ': Scan for fast-event signatures? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  
  %disp(['In ' CSname ': EventScan logic not ready for use'])
  %keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
  %if keybdok
  %  disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
  %  keyboard
  %end
  % break
  
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  if ~isempty(get(0,'Children'))  %Test for open plots
        %----------------------------------------------------
        % Begin: Macro selection ZN 03/31/06
        if ~isfield(PSMMacro, 'PSMbrowser_closeok70'), PSMMacro.PSMbrowser_closeok70=NaN;end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_closeok70))      % Not in Macro playing mode or selection not defined in a macro
           closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
        else
            closeok=PSMMacro.PSMbrowser_closeok70;
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PSMbrowser_closeok70=closeok;
            else
                PSMMacro.PSMbrowser_closeok70=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        % End: Macro selection ZN 03/31/06
        %----------------------------------------------------
    if closeok, close all; end    %Close all plots
  end
  [maxpoints,nsigs]=size(PSMsigsX); 
  chansA=[2:5];                 %Signals to analyze
  decfac=1;                     %Decimation factor
  n1=1; n2=maxpoints;
  t1=PSMsigsX(n1,1);            %Initial processing time
  t2=PSMsigsX(n2,1);            %Final processing time
  TRange=[t1 t2];               %Processing range
  EScanpars=[];
%   keyboard%
%  if ~isfield(PSMMacro, 'EventScan1_PathName'), PSMMacro.EventScan1_PathName=''; end
%  if isempty(PSMMacro.EventScan1_PathName)
   if isempty(PSMpaths)
       PSMMacro.EventScan1_PathName='';
   else
       PSMMacro.EventScan1_PathName=PSMpaths(1,:);
   end
%  end
  
 % if ~isfield(PSMMacro, 'EventScan1_LogFname'), PSMMacro.EventScan1_LogFname=''; end
 % if isempty(PSMMacro.EventScan1_LogFname)
      CurDateStr=datestr(now,'yyyymmddHHMM');
      PSMMacro.EventScan1_LogFname=['ESlogM', CurDateStr,'.xls'];
 % end
  
  PSMMacro.EventScan1_PSMfilesIndex=1;
  [CaseComES,SaveFileES,namesES,TRangeES,ESAlarmLogReady, ESAlarmLevel]...
    =EventScan1(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
     chansA,TRange,tstep,decfac,EScanpars);
 
  disp(' ');
  disp('-------------------------------------------------------------------------- ');
  if ESAlarmLevel
      disp(['In ' CSname ': Event Scan has been finished for the data ']);
      disp(['      Highest detected alaram level = ', num2str(ESAlarmLevel)]);
      if ESAlarmLogReady
         disp('      The summary is stored in the file ')
         disp(['      [',  PSMMacro.EventScan1_PathName, PSMMacro.EventScan1_LogFname, ' ]']);
         disp('--------------------------------------------------------------------------- ');
         ESInspectOk=promptyn(['In ' CSname ': Do you want to inspect it? '], 'y');
         if ESInspectOk
             winopen([PSMMacro.EventScan1_PathName, PSMMacro.EventScan1_LogFname]);
         end
      else
         disp('      The summary is printed on the screen because the log file cannot be openned!! ') 
         disp('--------------------------------------------------------------------------- ');
         disp(' press any key to continue ... ');  pause;
      end
  else
      disp(['In ' CSname ': No special events are detected for the extracted data. ']);
      disp('--------------------------------------------------------------------------- ');
      disp(' press any key to continue ... ');
      pause
  end
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
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if (PSMMacro.RunMode<1)
        keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
    else
        keybdok=0;
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------    

  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end
%************************************************************************

%************************************************************************
case 'Backload Phasor Results'
disp(' ')
prompt=['In ' CSname ': Replace extracted signals by derived phasor signals? '];
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro, 'PSMbrowser_setok42'), PSMMacro.PSMbrowser_setok42=NaN;end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbrowser_setok42))      % Macro definition mode or selection not defined in a macro
    setok=promptyn(prompt,AutoOpDef);
else
    setok=PSMMacro.PSMbrowser_setok42;
end

if PSMMacro.RunMode==0      % if in macro definition mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbrowser_setok42=setok;
    else
        PSMMacro.PSMbrowser_setok42=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%setok=promptyn(prompt,AutoOpDef);
% End: Macro selection ZN 03/31/06
%----------------------------------------------------

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
  [maxpoints,nsigs]=size(PSMsigsX); 
  SpecialDisp
end
%************************************************************************

%*************************************************************************
case 'DownSelect Signals'
disp(' ')
prompt=['In ' CSname ': DownSelect Signals? '];
setok=promptyn(prompt,AutoOpDef);
for N=1:1
  if ~setok, disp('Proceeding to next processing phase'), break, end
  newtags=promptyn(['In ' CSname ': Generate new case tags? '], 'n');
  if newtags
    disp(['Generating new case tags for case ' caseID ':'])
    [caseID,casetime,CaseCom,Gtags]=CaseTags(caseID);
  end
  [maxpoints nsigs]=size(PSMsigsX); PRcom='DownSelecting';
  [MenuName,chansN,chansNok]=PickSigsN(1:nsigs,namesX,chankeyX,CSname,PRcom);
  if isempty(chansN)
     disp('   NO SIGNALS SELECTED -- GOING TO NEXT OPERATION'); break
  end
  if chansN(1)~=1, chansN(1)=1, ; end
  OpHist=str2mat(OpHist,Data_Op); OpHistN=[OpHistN OpTypeN];
  str='DownSelecting signals:';
  CaseCom=str2mat(CaseCom,str); disp(str)
  PSMsigsX=PSMsigsX(:,chansN);
  namesX=namesX(chansN,:); chankeyX=names2chans(namesX);
  time=PSMsigsX(:,1);   
  [maxpoints nsigs]=size(PSMsigsX);
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
  newtags=promptyn(['In ' CSname ':  Reset case tags and comments file? '], '');
  if newtags
    disp(['Define new case tags for case ' caseID ':'])
    CaseCom='';
    [caseID,casetime,CaseCom,Gtags]=CaseTags(caseID);
  end
  extractok=0;
  ChainCase=''; PSMfiles=''; CFname='';  PSMtype=''; 
  GetRange=''; loadopt=''; rmsopt=''; 
  PSMMacro.RunMode=-1;       % stop the Macro before loading new data
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
  [maxpoints,nsigs]=size(PSMsigsX); 
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
    if isempty(str1)
      strs=['Sorry: Logfile ' logfile ' not found on Matlab path'];
    else
      str2=['In ' CSname ': Logfile stored at location shown below:'];
      strs=str2mat(str2,str1); 
    end
    disp(strs)
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
end    %Termination of SWITCH logic for processing operations
catch  %Recovery for TRY logic
  disp(' ')
  disp(['In ' CSname ': Error return from operation ' num2str(OpTypeN) ': ' OpTypes(OpLoc,:)])
  keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end    %Termination of TRY logic for processing operations
end    %Termination of WHILE loop for processing operations
%^^^^^^^^^^^^^^^^^


%end of PSMT case script

