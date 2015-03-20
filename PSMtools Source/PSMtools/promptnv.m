function [Nval]=promptnv(query, default)
% [Nval]=promptnv(query, default)
%
% Function PROMPTNV prompts the user for a numerical value response to QUERY:
%   - empty return is equivalent to entering DEFAULT
%   - other returns are interpreted as numerical values
%   - DEFAULT is returned automatically if DEFAULT(1) not empty or blank, and
%       if nvprompt=0 in "global Kprompt ynprompt nvprompt"  
%
% Last modified 01/08/01.  jfh
% Last Modified 10/18/2006. Ning Zhou to add macro function

%Global controls on prompt defaults
global Kprompt ynprompt nvprompt
%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
if ~isfield(PSMMacro,'PauseMode'), PSMMacro.PauseMode=0; end
% End: Macro definition   ZN  10/18/06
%----------------------------------------------------
%keyboard




if ~exist('default'), default=[]; end
if isempty(nvprompt)|isempty(default), usedef=0; else usedef=~nvprompt; end

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
if PSMMacro.RunMode>=0,  usedef=0; end          % block the default selection for the 'Macro Run & Recording mode'
InputRetry=1;
while InputRetry
    InputRetry=0;
    if  PSMMacro.RunMode==0
        if PSMMacro.PauseMode==0
            query2=['[Macro (R)ecording]  ', query];
        else
            query2=['[Macro being (W)iped]  ', query];
        end
    elseif PSMMacro.RunMode==1 
            query2=['[Macro (P)lay (G)o]  ', query];        
    else
         query2=query;        
    end
% End: Macro definition ZN 10/18/06
%----------------------------------------------------  

    deftext=sprintf('[%s]',num2str(default));
    prompt=[query2 ' ' deftext ':  '];
    %prompt=[query ' ' deftext ':  '];
    if usedef
        disp(prompt); Nval=default;
    else 
        %----------------------------------------------------
        % Begin: Macro definition ZN 10/18/06
        StrVal=input(prompt,'s');
        if isfield(PSMMacro,'MacroName')
            if  PSMMacro.RunMode==0                    % in recording mode
                setpause=strcmp(lower(StrVal),'w');  %String comparison
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
                        disp('Macro Record Restarted! ')
                        LockCtrl=1; KeyCtrl=0;   MacroNum=0;   RunMode=0;   PauseMode=0;
                        [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
                        save(PSMMacro.MacroName,'PSMMacro');
                   %    disp('Macro (R)ecording Started !')
                    end
                end
            end                                        

            setplay=strcmp(lower(StrVal),'r');  %String comparison
            if setplay
                InputRetry=1;
                PSMMacro.RunMode=0;               % switch to macro recording mode
                PSMMacro.PauseMode=0;
                disp('Macro (R)ecording Started! ');
                LockCtrl=1; KeyCtrl=0;   MacroNum=0;   RunMode=0;   PauseMode=0;
                [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
                save(PSMMacro.MacroName,'PSMMacro');
            end

            setplay=strcmp(lower(StrVal),'p');  %String comparison
            setplay2=strcmp(lower(StrVal),'g');  %String comparison
            if setplay || setplay2
                InputRetry=1;
                PSMMacro.RunMode=1;               % switch to macro playing mode
                disp('Macro (P)laying Started! ');
                LockCtrl=1;   KeyCtrl=0;   MacroNum=0;   RunMode=1;   PauseMode=0;
                [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
                save(PSMMacro.MacroName,'PSMMacro');
            end

            setplay=strcmp(lower(StrVal),'s');  %String comparison
            if setplay
                InputRetry=1;
                PSMMacro.RunMode=-1;               % switch to macro stoping mode
                disp('Macro (S)topped! ');

                LockCtrl=0; KeyCtrl=0; MacroNum=0; RunMode=-1; PauseMode=0; % open the lock and hibernate the macro
                [LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
                save(PSMMacro.MacroName,'PSMMacro');
            end
            
            setplay=strcmp(lower(StrVal),'v');  %String comparison 02/13/2007 by Ning Zhou
            if setplay                          % view and edit macro 
                InputRetry=1;
                %PSMMacro.RunMode=-1;               
                subMacroEdit;                    % edit macro
                %LockCtrl=0; KeyCtrl=0; MacroNum=0; RunMode=-1; PauseMode=0; % open the lock and hibernate the macro
                %[LockStatus, Key]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode);
            end
        end

        % Nval=input(prompt); 
        % if isempty(Nval), Nval=default; end
        % keyboard
        if ~InputRetry
            if isempty(StrVal) 
                Nval=default; 
            else
                Nval=str2num(StrVal);    
                if isempty(Nval) 
                   InputRetry=1;
                   disp(['"', StrVal, '" is not a valid input!']);
                end
            end
       
        end
        % End: Macro definition ZN 10/18/06
        %----------------------------------------------------  
    end
end
%end of PSMT m-file
