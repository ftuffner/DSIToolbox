% PSMtools script EndChecks.m
%
% Functions provided:
%   Signal extraction from PSM raw files
%   Saving extracted signals to Matlab files in PSM standard format
%
%
% Special functions used:
%
%   
% Last modified 12/12/00.  jfh
% Last Modified 5/11/2006. Ning Zhou for Macro (automatic execution)

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end   % zn for macro

newpoints=size(NewSigsX,1); 
RefTpts=round((PSMreftimes(nXfile)-PSMreftimes(nXfile-1))/tstep);
if RefTpts>newpoints
  recgap=RefTpts-newpoints;
  strs=['In EndChecks: ' sprintf('%4.0i',recgap) ' point gap between records'];
  strs=str2mat(strs,['   ' PSMfiles(nXfile-1,:)]);
  strs=str2mat(strs,['   ' PSMfiles(nXfile  ,:)]);
  disp(strs)
  
  %----------------------------------------------------
  % Begin: Macro selection ZN 05/11/06
    if  ~isfield(PSMMacro, 'EndChecks_keybdok'), PSMMacro.EndChecks_keybdok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.EndChecks_keybdok))      % 'Macro record mode' or 'selection was not defined in a macro'
        keybdok=promptyn('In EndChecks: Do you want the keyboard? ', 'n');
    else
        keybdok=PSMMacro.EndChecks_keybdok;
    end
    
    if PSMMacro.RunMode==0      % if in macro recording mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.EndChecks_keybdok=keybdok;
        else
            PSMMacro.EndChecks_keybdok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 05/11/06
    %----------------------------------------------------

  
  if keybdok
    disp('In EndChecks: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
  
  %----------------------------------------------------
  % Begin: Macro selection ZN 05/11/06
    if ~isfield(PSMMacro, 'EndChecks_fillok'), PSMMacro.EndChecks_fillok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.EndChecks_fillok))      % 'Macro record mode' or 'selection was not defined in a macro'
        fillok=promptyn('In EndChecks: Linear fill across record gap? ', 'n');
    else
        fillok=PSMMacro.EndChecks_fillok;
    end
    
    if PSMMacro.RunMode==0      % if in macro recording mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.EndChecks_fillok=fillok;
        else
            PSMMacro.EndChecks_fillok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 05/11/06
    %----------------------------------------------------
 
  %keyboard%
  if fillok
    str1='In EndChecks: Linear fill across record gap';  disp(str1)
    LeftN=size(PSMsigsX,1);
    LeftVal=PSMsigsX(LeftN,:); RightVal=NewSigsX(1,:);
    SigFill=zeros(recgap,length(LeftVal));
    for loc=1:recgap
      fac1=loc/(recgap+1); fac2=1-fac1;
      SigFill(loc,:)=fac2*LeftVal+fac1*RightVal;
    end
    %plot(SigFill(:,1))  %Time axis
    PSMsigsX=[PSMsigsX',SigFill',NewSigsX']';
    %plot(PSMsigsX(LeftN-100:LeftN+100,1))
  else
    str1='In EndChecks: No fill across record gap'; disp(str1)
    PSMsigsX=[PSMsigsX',NewSigsX']';
  end
  CaseCom=str2mat(CaseCom,strs,str1);
end
if RefTpts<newpoints
  reclap=newpoints-RefTpts;
  strs=['In EndChecks: ' sprintf('%4.0i',reclap) ' point overlap across records'];
  strs=str2mat(strs,['   ' PSMfiles(nXfile-1,:)]);
  strs=str2mat(strs,['   ' PSMfiles(nXfile  ,:)]);
  disp(strs)
  
  %----------------------------------------------------
  % Begin: Macro selection ZN 05/11/06
    if ~isfield(PSMMacro, 'EndChecks_keybdok02'), PSMMacro.EndChecks_keybdok02=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.EndChecks_keybdok02))      % 'Macro record mode' or 'selection was not defined in a macro'
        keybdok=promptyn('In EndChecks: Do you want the keyboard? ', 'n');
    else
        keybdok=PSMMacro.EndChecks_keybdok02;
    end
    
    if PSMMacro.RunMode==0      % if in macro recording mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.EndChecks_keybdok02=keybdok;
        else
            PSMMacro.EndChecks_keybdok02=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
  % End: Macro selection ZN 05/11/06
  %----------------------------------------------------
  
  
  if keybdok
    disp('In EndChecks: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end

  
  
  %----------------------------------------------------
  % Begin: Macro selection ZN 05/11/06
    if ~isfield(PSMMacro, 'EndChecks_omitok'), PSMMacro.EndChecks_omitok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.EndChecks_omitok))      % 'Macro record mode' or 'selection was not defined in a macro'
        omitok=promptyn('In EndChecks: Omit surplus points? ', 'y');
    else
        omitok=PSMMacro.EndChecks_omitok;
    end
    
    if PSMMacro.RunMode==0      % if in macro recording mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.EndChecks_omitok=omitok;
        else
            PSMMacro.EndChecks_omitok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
  % End: Macro selection ZN 05/11/06
  %----------------------------------------------------
  
  if omitok
    str1='In EndChecks: Omitting surplus points';  disp(str1)
    PSMsigsX=[PSMsigsX',NewSigsX(reclap+1:newpoints,:)']';
  else
    str1='In EndChecks: Keeping surplus points';  disp(str1)
    PSMsigsX=[PSMsigsX',NewSigsX(1:newpoints,:)']';
  end
  CaseCom=str2mat(CaseCom,str1);
end

%end of PSM script
