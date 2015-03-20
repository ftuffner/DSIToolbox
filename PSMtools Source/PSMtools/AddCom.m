function [CaseCom]=AddCom(CaseCom)
% AddCom permits the user to add lines to case comment array CaseCom
%
%  function [CaseCom]=AddCom(CaseCom)
%
%  [Last modified 12/20/00.  jfh]
%  [Last modified 03/31/20/06.  Zn to add macro]

global Kprompt ynprompt nvprompt
%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
global PSMMacro         % Macro Structure  
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
% End: Macro definition ZN 03/31/06
%----------------------------------------------------

for n=1:20
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro,'AddCom_lineok')
        PSMMacro.AddCom_lineok=NaN;
    end
        
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.AddCom_lineok))      % 'Macro record mode' or 'selection was not defined in a macro'
        lineok=promptyn('In AddCom:  Add a line of text to Case Comments? ', 'n');
    else
        lineok=PSMMacro.AddCom_lineok;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.AddCom_lineok=lineok;
        else
            PSMMacro.AddCom_lineok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------

    if ~lineok, return, end
    newline=input([ 'Type New Line: '],'s');
    CaseCom=str2mat(CaseCom,newline);
end

