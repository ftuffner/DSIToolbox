% Custom Script SpecialDisp.m
%
% Users can use this as a link to custom codes
%
% Modified 04/13/04.  jfh
% Modified 10/18/2006  Ning Zhou to add macro function

% By J. F. Hauer, Pacific Northwest National Laboratory. 

if 0
    keyboard
    save Debug_13
elseif 0
    clear all 
    close all
    clc
    load Debug_13
    funLoadMacro()
    PSMMacro.RunMode=1;  %run macro
%   PSMMacro.RunMode=0;  %record macro
%   PSMMacro.RunMode=-1; %normal orperation
end

%Call user-provided custom code
%Robust050902A_PSMT   %[CUSTOM EXAMPLE]
%Robust091902A_PSMT   %[CUSTOM EXAMPLE]
%Robust091902B_PSMT   %[CUSTOM EXAMPLE]
 
RobustCode='Robust091902B_PSMT'; %keyboard

disp(' '); disp('In Custom Utility SpecialDisp:')
disp(['Indicated user utility = ' RobustCode])
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro, 'SpecialDisp_launchok'), PSMMacro.SpecialDisp_launchok=NaN;end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.SpecialDisp_launchok))      % Macro definition mode or selection not defined in a macro
    launchok=promptyn(['Launch utility ' RobustCode '? '],'y');
else
    launchok=PSMMacro.SpecialDisp_launchok;
end

if PSMMacro.RunMode==0      % if in macro definition mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SpecialDisp_launchok=launchok;
    else
        PSMMacro.SpecialDisp_launchok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%launchok=promptyn(['Launch utility ' RobustCode '? '],'y');
% End: Macro selection ZN 03/31/06
%----------------------------------------------------


launchck=deblank(which(RobustCode));  %Check presence
if isempty(launchck)
  disp(['In SpecialDisp: Cannot find case ' RobustCode])
    launchok=0;  
else
  if launchok
    eval(RobustCode);
  end
end
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro, 'SpecialDisp_keybdok'), PSMMacro.SpecialDisp_keybdok=NaN;end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.SpecialDisp_keybdok))      % Macro definition mode or selection not defined in a macro
    keybdok=promptyn(['In SpecialDisp: Do you want the keyboard? '], '');
else
    keybdok=PSMMacro.SpecialDisp_keybdok;
end

if PSMMacro.RunMode==0      % if in macro definition mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SpecialDisp_keybdok=keybdok;
    else
        PSMMacro.SpecialDisp_keybdok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%keybdok=promptyn(['In SpecialDisp: Do you want the keyboard? '], '');
% End: Macro selection ZN 03/31/06
%----------------------------------------------------


if keybdok
  disp(['In SpecialDisp: Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end

disp('Return from SpecialDisp')
disp(' ')
return

%end of PSMT utility
