function [MenuName,chansX,chansXok]=SetExtPDC(chansXstr,names,chankey,CFname)
% Determine signals to extract from PDC records
% 
% NOMENCLATURE WARNINGS:
%   - PSMsigsX  is an array extracted from any PSM (power system monitor)
%  FOR PPSM DATA:
%    - Hardware channels are numbered [0:N-1]
%    - Signals to extract are numbered [1:N]
%    - Signals extracted are numbered [1:N+1], with time axis at column 1
%  FOR PDC DATA:
%   - PDC RMS signals are numbered [1:N]
%   - Signals to extract are numbered [1:N+1], with time axis at column 1
%
% PSM Tools called from SetExtPDC:
%   PDCmenu
%   SigSelect
%   promptyn, promptnv
%
%  Last modified 03/04/03.  jfh
%  Last Modified 04/01/06.  ZN for adding the macro

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
global PSMMacro         % Macro Structure  
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
% End: Macro definition ZN 03/31/06
%----------------------------------------------------

MenuName=''; chansX=[]; chansXok=0;
if ~ischar(chansXstr)
  chansXstr=['chansX=[' num2str(chansXstr) '];'];
end
eval(chansXstr);

FNname='SetExtPDC';  %Internal name of this utility

%*********************************************************************
nsigs=size(names,1);
TimeOK=~isempty(findstr('time',lower(names(1,1:4))));
disp(' ')
str=['In ' FNname ': Number of stored signals=' num2str(nsigs)];
disp(str)
if TimeOK
  disp('   Includes time axis inserted at column 1')
else
  disp('   WARNING: NO TIME AXIS FOUND AT COLUMN 1')
end
%*********************************************************************

%*********************************************************************
%Define PDC signal types
SigTypes=str2mat('Time','Freq','VMag','VAng','IMag','IAng','MW  ','Mvar');
SigTypes=str2mat(SigTypes,'FreqL','VAngL','FreqR','VAngR','FreqA','VAngA','VAngX');
SigTypes=str2mat(SigTypes,'spcl','end ');
%*********************************************************************

%*********************************************************************
%Load PDC custom menus
%keyboard
chansMenuC=''; chansSC='';
if isempty(deblank(which('PDCmenu')))
  str=['In ' FNname ': Utility PDCmenu not found -- No custom menus'];
  disp(str)
else
  [chansMenuC,chansSC]=PDCmenu('','',CFname,nsigs);
end
if ~isempty(chansMenuC)
  if isempty(deblank(chansMenuC(1,:)))
    NmenusC=size(chansMenuC,1);
    if NmenusC>1
      chansMenuC=chansMenuC(2:NmenusC,:);
      chansSC=chansSC(2:NmenusC,:);
    else
      chansMenuC=''; chansSC='';
    end
  end
end
NmenusC=size(chansMenuC,1);
%*********************************************************************

%*********************************************************************
%Determine signals to extract
ProcessCom='PDC signal extraction';
%keyboard%
if ~isfield(PSMMacro, 'SetExtPDC_chansXok'), PSMMacro.SetExtPDC_chansXok=NaN;end
if ~isfield(PSMMacro, 'SetExtPDC_chansX'), PSMMacro.SetExtPDC_chansX=NaN; end
if ~isfield(PSMMacro, 'SetExtPDC_MenuName'), PSMMacro.SetExtPDC_MenuName='';end
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
%keyboard%
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.SetExtPDC_chansXok) || PSMMacro.SetExtPDC_chansXok==0)      % 'Macro record mode' or 'selection was not defined in a macro'
        [MenuName,chansX,chansXok]=SigSelect(chansX,names,chankey,...)
               CFname,SigTypes,chansMenuC,chansSC,ProcessCom);
         if (PSMMacro.RunMode==2)               %Batch Macro Mode;
            PSMMacro.SetExtPDC_chansXok=chansXok;
            PSMMacro.SetExtPDC_chansX=chansX;
            PSMMacro.SetExtPDC_MenuName=MenuName;
         end
    else
        chansXok=PSMMacro.SetExtPDC_chansXok;
        if isempty(PSMMacro.SetExtPDC_chansX)
            chansX=1:size(names,1);                 % select all channels of data
        else
            chansX=PSMMacro.SetExtPDC_chansX;
        end
        MenuName=PSMMacro.SetExtPDC_MenuName;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.SetExtPDC_chansXok=chansXok;
            PSMMacro.SetExtPDC_chansX=chansX;
            PSMMacro.SetExtPDC_MenuName=MenuName;
        else
            PSMMacro.SetExtPDC_chansXok=NaN;
            PSMMacro.SetExtPDC_chansX=NaN;
            PSMMacro.SetExtPDC_MenuName='';
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------
%*********************************************************************

%*********************************************************************
if TimeOK
  if chansX(1)~=1, chansX=[1 chansX]; end
end
if ~chansXok
  chansX=0; chansXok=0;
  MenuName='NONE';  
  str1=['In ' FNname ': No signals selected - '];
  disp([str1,'Returning to invoking Matlab function'])
  disp(' ')
  return
end
%*********************************************************************

return

%end of PSMT function

