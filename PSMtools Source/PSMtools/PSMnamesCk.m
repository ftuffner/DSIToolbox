% Case Script PSMnamesCk.m
% Logic to standardize names of retrieved PSM data
%
%
% PSM Tools called from PSMnamesCk:
%   PSMsave, ...
%
% Last modified 05/24/01.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

disp('In PSMnamesCk:')

namesCkok=1;
if namesCkok
  Varnames=strvcat(varlist);
  %Old SaveListB    =['PSMtype PSMsigsX tstep namesX chankeyX CaseComR DataNames RefTimesR'];
  %Standard SaveList=['PSMtype PSMsigsX tstep namesX chankeyX CaseComR PSMfiles PSMreftimes CFname'];
  %Filtered SaveList=['PSMtype PSMsigsF tstepF namesX chankeyX CaseComF PSMfiles PSMreftimes CFname'];
  %command=['exist(' '''QQ''' ')']
  PSMTnames=str2mat('PSMtype','PSMsigsX','tstep','namesX','chankeyX');
  PSMTnames=str2mat(PSMTnames,'CaseComR','PSMfiles','PSMreftimes');
  Nvars1=size(Varnames,1); Nvars2=size(PSMTnames,1);
  VarFound=zeros(Nvars2,1); NotFound=0;
  for N2=1:Nvars2
    name2=deblank(PSMTnames(N2,:));
    for N1=1:Nvars1
      name1=deblank(Varnames(N1,:));
      if strcmp(name1,name2), VarFound(N2)=N1; end;
      if strcmp(name2,'PSMsigsX')&strcmp(name1,'PSMsigsF')
        PSMsigsX=PSMsigsF; PSMsigsF=[]; VarFound(N2)=1;
        str1='Retrieved signal array is named PSMsigsF -- renamed to PSMsigsX';
        disp(str1); filtered=1;
      end
      if strcmp(name2,'CaseComR')&strcmp(name1,'CaseCom')
        CaseComR=CaseCom; VarFound(N2)=1;
        str1='Retrieved Case Processing file is named CaseCom -- renamed to CaseComR';
        disp(str1)
      end
      if strcmp(name2,'CaseComR')&strcmp(name1,'CaseComF')
        CaseComR=CaseComF; VarFound(N2)=1;
        str1='Retrieved Case Processing file is named CaseComF -- renamed to CaseComR';
        disp(str1)
      end
      if strcmp(name2,'tstep')&strcmp(name1,'tstepF')
        tstep=tstepF; tstepF=[]; VarFound(N2)=1;
        str1='Retrieved time step is named tstepF -- renamed to tstep';
        disp(str1)
      end
    end
    if VarFound(N2) str1=[name2 '  found'];
    else  str1=[name2 '  not found'];
      disp(str1); eval([name1 '=[];']);
      NotFound=NotFound+1;  
    end
  end
  if NotFound
    disp(' ')
    disp('Standard stored varibles for PSMtools are'); disp(PSMTnames)
    disp('Giving you the keyboard to rename variables -  Type "return" when you are done')
    disp(' ')
    disp('Retrieved variables are'); disp(Varnames)
    keyboard
  end
end

disp('Return from PSMnamesCk')


%end of PSMT utility



