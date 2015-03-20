% Case Script PSMlaunch.m
%
% PSMlaunch is a utility for launching various special cases of PSMbrowser.
%    
%
% Modified 06/08/05.    jfh   Revised example list
% Modified 05/11/2006.  ZN    Add event scan function
% Modified 10/18/06.    ZN    Revised to add more macro function
%
% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
if mislocked('funLoadMacro')
    munlock('funLoadMacro');
end
% End: Macro definition ZN 03/31/06
%----------------------------------------------------

%^^^^^^^^^^^^^^^^^
while 1   %Start of WHILE loop for data processing operations
%^^^^^^^^^^^^^^^^^
clear all		%clear all working variables
close all		%close all plot windows
echo off


%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
clc
pathName=tempdir;
MacroFile=fullfile(pathName, 'MacroDefault.mat');
subDispPrompt;
disp('Note: the macro is a file stored in your computer.');
disp(['     The macro file name is :  "', MacroFile, '".' ]);



global PSMMacro                      % Macro Structure  
[LockStatus, Key]=funLoadMacro();    % macro initialization 
%funLoadMacro() 

% End: Macro definition ZN 03/31/06
%----------------------------------------------------

global Kprompt ynprompt nvprompt
Kprompt=0;   %sets general-purpose "keyboard" commands within m-files off
ynprompt=1;	 %sets "y or n" prompts within m-files on
nvprompt=1;	 %sets numerical value prompts within m-files on

LaunchName='PSMlaunch';  %Internal name of this case script
%disp(['In Case Script ' LaunchName])

%************************************************************************
%Menu of cases to launch
CaseNos=[1];          CaseTypes='WSCCbrowser';     %[CUSTOM]
CaseNos=[CaseNos  2]; CaseTypes=str2mat(CaseTypes,'PSMbrowser');
CaseNos=[CaseNos  3]; CaseTypes=str2mat(CaseTypes,'BPA_PDCdatapost');
CaseNos=[CaseNos  4]; CaseTypes=str2mat(CaseTypes,'BPA_MMcase');
CaseNos=[CaseNos  8]; CaseTypes=str2mat(CaseTypes,'PDC_Alias');
CaseNos=[CaseNos 21]; CaseTypes=str2mat(CaseTypes,'PDCbrowse_Ex1');
CaseNos=[CaseNos 23]; CaseTypes=str2mat(CaseTypes,'PSDScase_Ex2');
CaseNos=[CaseNos 24]; CaseTypes=str2mat(CaseTypes,'PTIPRNT_Ex1');
CaseNos=[CaseNos 25]; CaseTypes=str2mat(CaseTypes,'PTIPRNT_Ex2');
CaseNos=[CaseNos 26]; CaseTypes=str2mat(CaseTypes,'PTIRAWC_Ex3');
CaseNos=[CaseNos 41]; CaseTypes=str2mat(CaseTypes,'Matlab_Ex1');
CaseNos=[CaseNos 42]; CaseTypes=str2mat(CaseTypes,'Matlab_Ex2');
CaseNos=[CaseNos 43]; CaseTypes=str2mat(CaseTypes,'BoxFilt_Ex1');
CaseNos=[CaseNos 44]; CaseTypes=str2mat(CaseTypes,'SincFilt_Ex1');
CaseNos=[CaseNos 45]; CaseTypes=str2mat(CaseTypes,'TriFilt_Ex1');
CaseNos=[CaseNos 61]; CaseTypes=str2mat(CaseTypes,'PDCrobust_Ex1');
CaseNos=[CaseNos 70]; CaseTypes=str2mat(CaseTypes,'Batch_Event_Scan');
CaseNos=[CaseNos 90]; CaseTypes=str2mat(CaseTypes,'Macro_(R)ecord');
CaseNos=[CaseNos 91]; CaseTypes=str2mat(CaseTypes,'Macro_(P)lay_(G)o');
CaseNos=[CaseNos 92]; CaseTypes=str2mat(CaseTypes,'Macro_(S)top');
CaseNos=[CaseNos 97]; CaseTypes=str2mat(CaseTypes,'keyboard');
CaseNos=[CaseNos 99]; CaseTypes=str2mat(CaseTypes,'end case sequence');
%************************************************************************

%************************************************************************
%Menu selection of processing type
%[Automate later for Rerun cases]
disp(' '); disp(' ');
disp('%************************************************************************')
disp(' ')
disp(['In Case Script ' LaunchName ':'])
NCaseTypes=size(CaseTypes,1);
disp('Select case type: Options are')
for N=1:NCaseTypes
  disp([sprintf('  %2.0i  ',CaseNos(N)) CaseTypes(N,:)]); 
end
disp(' ');
prompt=['Indicate case type - enter number from list above'];


%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end

if 0
    if (PSMMacro.RunMode==0)
        prompt=['[Recording] Indicate case type - enter number from list above'];
    elseif (PSMMacro.RunMode==1)
        prompt=['[Playing] Indicate case type - enter number from list above'];
    end
end

%if (PSMMacro.RunMode<1 || PSMMacro.PSMlaunch_CaseL<0 )     % "Not in Macro playing mode" or "selection not defined in a macro"
if ~isfield(PSMMacro, 'PSMlaunch_CaseL'), PSMMacro.PSMlaunch_CaseL=-1; end
if (PSMMacro.RunMode<2 || PSMMacro.PSMlaunch_CaseL<0 )      % "Not in Macro batch playing mode" or "selection not defined in a macro" 
    CaseL=promptnv(prompt,2);
elseif PSMMacro.RunMode==1      % Macro running mode ZN
    CaseL=PSMMacro.PSMlaunch_CaseL;
end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------


if isempty(CaseL),CaseL=0; end 
CaseLoc=find(CaseL==CaseNos);
if isempty(CaseLoc)
   disp(['Selected case type ' num2str(CaseL) ' is not valid'])
   CaseLoc=1; 
end
CaseL=CaseNos(CaseLoc); 

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if (PSMMacro.RunMode==0 && CaseL<90)     % if in macro recordning mode 
    PSMMacro.PSMlaunch_CaseL=CaseL;
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------


if CaseL<90  %Launch selected case
  LaunchCase=deblank(CaseTypes(CaseLoc,:));
  disp(['Indicated case type = ' num2str(CaseL) ': ' LaunchCase])
  disp(' ')
  
  %----------------------------------------------------
  % Begin: Macro selection ZN 03/31/06
  if (PSMMacro.RunMode==0 || PSMMacro.PSMlaunch_CaseL<0 )      % if in macro definition mode   
     launchok=promptyn(['Launch case ' LaunchCase '? '],'y');
  else
     launchok='y';
  end
  % End: Macro selection ZN 03/31/06
  %----------------------------------------------------
  
  launchck=deblank(which(LaunchCase));  %Check presence
  if isempty(launchck)
    disp(['In ' LaunchName ': Cannot find case ' LaunchCase])
    launchok=0;
    disp(' '); disp('Processing is paused--Press any key to continue')
    pause  
  end  
  if launchok
      
    %disp(LaunchCase) 
    eval(LaunchCase);
    
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    LockCtrl=1; KeyCtrl=0; MacroNum=0; RunMode=-1; PauseMode=0; % open the lock and hibernate the macro
    [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
    %save(PSMMacro.MacroName,'PSMMacro');
    if mislocked('funLoadMacro')
        munlock('funLoadMacro');
    end
    disp('Macro stopped!')
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
  end
else  %Special operations
  
  %----------------------------------------------------
  % Begin: Macro selection ZN 03/31/06
   if CaseL==90         % record macro
       LockCtrl=1; KeyCtrl=0;   MacroNum=0;   RunMode=0;   PauseMode=0;
       [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
       save(PSMMacro.MacroName,'PSMMacro');
       disp('Macro (R)ecording Started !')
      
   elseif CaseL==91     % play a macro
       LockCtrl=1;   KeyCtrl=0;   MacroNum=0;   RunMode=1;   PauseMode=0;
       [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
       save(PSMMacro.MacroName,'PSMMacro');
       disp('Macro (P)laying Started !')
   elseif CaseL==92      %hibernate (stop) a macro
        LockCtrl=0; KeyCtrl=0; MacroNum=0; RunMode=-1; PauseMode=0; % open the lock and hibernate the macro
        [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
        save(PSMMacro.MacroName,'PSMMacro');
        disp('Macro (S)topped!')
    end
  % End: Macro selection ZN 03/31/06
  %----------------------------------------------------
  
  if CaseL==97
    keybdok=promptyn(['In ' LaunchName ': Do you want the keyboard? '], '');
    if keybdok
      disp(['In ' LaunchName ': Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
    end
  end
  if CaseL==99
    endok=promptyn(['In ' LaunchName ': End case launch sequence? '], '');
    if endok, break, end
  end
end
%************************************************************************

%^^^^^^^^^^^^^^^^^
end  %Termination of WHILE loop for processing operations
%^^^^^^^^^^^^^^^^^

disp(' ')
disp(['In ' LaunchName ': CASE SEQUENCE COMPLETE'])
keybdok=promptyn(['In ' LaunchName ': Do you want the keyboard? '], 'n');
if keybdok
  disp(['In ' LaunchName ': Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end
disp(' ')
disp(' ')
disp(' ')
disp(' ')
disp(' ')
disp(' ')
disp(' ')
disp(' ')
disp('********************************************************************');
disp('*  Thank you!                                                      *');
disp('*                                                                  *');
disp('*   To reload the DSI toolbox, please type in "PSMlaunchMacro".    *');
disp('*                                                                  *')
disp('*******************************************************************');
disp(' ');
disp(' ');
disp(['   Your macro file is stored in:  "', MacroFile, '". ' ]);
%end of PSMT case script

