function [setok]=promptyn(query,default)
% [setok]=promptyn(query,default) 
%
% Function PROMPTYN prompts the user for a yes/no response to QUERY:
%   - empty return is equivalent to entering DEFAULT
%   - y  is interpreted as "yes", producing SETOK=1; else SETOK=0
%   - DEFAULT is returned automatically if DEFAULT(1) not empty or blank, and
%       if nvprompt=0 in "global Kprompt ynprompt nvprompt"
% This version also recognizes the following special commands:
%   keyboard  
%   quit
%   exit
%
% Last modified 04/28/03.  jfh
% Last modified 10/18/2005 zn for macro

%Global controls on prompt defaults
global Kprompt ynprompt nvprompt

%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
global PSMMacro         % Macro Structure  
%keyboard
% End: Macro definition ZN 03/31/06
%----------------------------------------------------

if ~exist('default'), default=' '; end
if isempty(default),  default=' '; end
if isempty(ynprompt)|default==' ', usedef=0; else usedef=~ynprompt; end

deftext=sprintf('[%s]',default);
%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
if PSMMacro.RunMode>=0,  usedef=0; end          % block the default selection for the 'Macro Run & Recording mode'

InputRetry=1;
while InputRetry
    InputRetry=0;
    if  PSMMacro.RunMode==0
        if PSMMacro.PauseMode==0
            query2=['[Macro (R)ecording]  ', query];
        else
            query2=['[Macro being (W)iped]  ', query];;
        end
    elseif PSMMacro.RunMode==1 
            query2=['[Macro (P)laying]  ', query];        
    else
         query2=query;        
    end
    prompt=[query2 ' Enter y or n ' deftext ':  '];    
% End: Macro definition ZN 03/31/06
%----------------------------------------------------    
    
    if usedef
      disp(prompt); setyn=default(1);
    else 
      setyn=input(prompt,'s'); 
      if isempty(setyn), setyn=default; end
    end
    Kbdok1=strcmp(lower(setyn(1)),'k');  %String comparison
    if Kbdok1  %Confirm Keyboard command
      disp(['In promptyn: User input starts with K: setok=' setyn])
      prompt=['In promptyn: Do you want the keyboard?  Enter y or n [y]:  '];
      QKbdok1=input(prompt,'s'); if isempty(QKbdok1), QKbdok1='y'; end
      QKbdok2=strcmp(lower(QKbdok1(1)),'y');  %String comparison
      if QKbdok2
        disp('In promptyn: Invoking "keyboard" command - Enter "return" when you are finished')
        keyboard
      end
    end
    %----------------------------------------------------
    % Begin: Macro definition ZN 10/18/06
    % keyboard
    if  PSMMacro.RunMode==0                    % in recording mode
        setpause=strcmp(lower(setyn(1)),'w');  %String comparison
        if setpause
            InputRetry=1;
            if PSMMacro.PauseMode==0
                PSMMacro.PauseMode=1;
                disp('Macro Recording being (W)iped! ')
                
                LockCtrl=1; KeyCtrl=0;   MacroNum=0;   RunMode=0;   PauseMode=1;
                [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
                save(PSMMacro.MacroName,'PSMMacro');
            else
                PSMMacro.PauseMode=0;
                disp('Macro record restarted! ')
                LockCtrl=1; KeyCtrl=0;   MacroNum=0;   RunMode=0;   PauseMode=0;
                [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
                save(PSMMacro.MacroName,'PSMMacro');
            end
        end
    end                                        
    
    setplay=strcmp(lower(setyn(1)),'r');  %String comparison
    if setplay
        InputRetry=1;
        PSMMacro.RunMode=0;               % switch to macro recording mode
        PSMMacro.PauseMode=0;
        disp('Macro (R)ecording Started! ')
        
        LockCtrl=1; KeyCtrl=0;   MacroNum=0;   RunMode=0;   PauseMode=0;
        [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
        save(PSMMacro.MacroName,'PSMMacro');
    end
        
    setplay=strcmp(lower(setyn(1)),'p');  %String comparison
    setplay2=strcmp(lower(setyn(1)),'g');  %String comparison
    if setplay || setplay2
        InputRetry=1;
        PSMMacro.RunMode=1;               % switch to macro playing mode
        disp('(M)acro Playing Started! ');
        
        LockCtrl=1;   KeyCtrl=0;   MacroNum=0;   RunMode=1;   PauseMode=0;
        [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
        save(PSMMacro.MacroName,'PSMMacro');
    end
    
    setplay=strcmp(lower(setyn(1)),'s');  %String comparison
    if setplay
        InputRetry=1;
        PSMMacro.RunMode=-1;               % switch to macro stoping mode
        disp('Macro (S)topped! ');
        
         LockCtrl=0; KeyCtrl=0; MacroNum=0; RunMode=-1; PauseMode=0; % open the lock and hibernate the macro
         [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
         save(PSMMacro.MacroName,'PSMMacro');
    end
    
    setplay=strcmp(lower(setyn(1)),'v');  %String comparison 02/13/2007 by Ning Zhou
    if setplay                          % view and edit macro 
        InputRetry=1;
        subMacroEdit;                   % edit macro

        %LockCtrl=0; KeyCtrl=0; MacroNum=0; RunMode=-1; PauseMode=0; % open the lock and hibernate the macro
        %[LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);

    end

    % End: Macro definition ZN 10/18/06
    %----------------------------------------------------

    setquit=strcmp(lower(setyn(1)),'q');  %String comparison
    setexit=strcmp(lower(setyn(1)),'e');  %String comparison
    if setquit|setexit  %Confirm Quit/Exit command
      disp(['In promptyn: User input starts with Q or E: setok=' setyn])
      prompt=['In promptyn: Quit/Exit Matlab?  Enter y or n [n]:  '];
      QEok1=input(prompt,'s'); if isempty(QEok1), QEok1='n'; end
      QEok2=strcmp(lower(QEok1(1)),'y');  %String comparison
      if QEok2
        disp('In promptyn: Quit/Exit command confirmed - Closing Matlab')
        quit
      end
    end
    
end
setok=strcmp(lower(setyn(1)),'y');  %String comparison

%end of PSMT m-file


