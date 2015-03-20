function [MenuName,chansX,chansXok]=SetExtSWX(chansXstr,names,chankey,CFname)
% Determine signals to extract from SWX records
%
% PSM Tools called from SetExtSWX:
%   SWXmenu
%   SigSelect
%   promptyn
%
%  Last modified 03/04/03.  jfh
%  Last Modeified 10/18/2006. Ning Zhou to add macro function

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
%
%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

MenuName=''; chansX=[]; chansXok=0;
if ~ischar(chansXstr)
  chansXstr=['chansX=[' num2str(chansXstr) '];'];
end
eval(chansXstr);

FNname='SetExtSWX';  %Internal name of this utility

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
%Define SWX signal types
%PDC signal types
  SigTypes=str2mat('Time','Freq','VFrq','VMag','VAng','IMag','IAng','MW  ','MVar');
  SigTypes=str2mat(SigTypes,'FreqL','VAngL','FreqR','VAngR','FreqA','VAngA','VAngX');
%PSLF signal types
  SigTypes=str2mat(SigTypes,'vbus   VMag','abus   VAng','fbus   Freq');
  SigTypes=str2mat(SigTypes,'pbr    MW  ','qbr    Mvar','pif    MW  ','qif    Mvar');
  SigTypes=str2mat(SigTypes,'pacr   MW  ','qacr   Mvar','paci   MW  ','qaci   Mvar');
  SigTypes=str2mat(SigTypes,'ang    Gang','spd    Gfrq','pg     MW  ','qg     Mvar');
%PTI signal types
  SigTypes=str2mat(SigTypes,'POWR ','ANGL ','FREQ ','SPD  ','VARS ');
  SigTypes=str2mat(SigTypes,'PMEC ','VREF ','EFD  ','ETRM ','AUX  ');
%*********************************************************************

%*********************************************************************
%Load SWX custom menus
%keyboard
chansMenuC=''; chansSC='';
if isempty(deblank(which('SWXmenu')))
  str=['In ' FNname ': Utility SWXmenu not found -- No custom menus'];
  disp(str)
else
 [chansMenuC,chansSC]=SWXmenu('','',CFname,nsigs);
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
ProcessCom='SWX signal extraction';

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard%
if ~isfield(PSMMacro, 'SetExtSWX_chansXok'), PSMMacro.SetExtSWX_chansXok=NaN;end
if ~isfield(PSMMacro, 'SetExtSWX_chansX'), PSMMacro.SetExtSWX_chansX=NaN; end
if ~isfield(PSMMacro, 'SetExtSWX_MenuName'), PSMMacro.SetExtSWX_MenuName='';end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.SetExtSWX_chansXok) || PSMMacro.SetExtSWX_chansXok==0)      % 'Macro record mode' or 'selection was not defined in a macro'
    [MenuName,chansX,chansXok]=SigSelect(chansX,names,chankey,...)
        CFname,SigTypes,chansMenuC,chansSC,ProcessCom);
     if (PSMMacro.RunMode==2)               %Batch Macro Mode;
        PSMMacro.SetExtSWX_chansXok=chansXok;
        PSMMacro.SetExtSWX_chansX=chansX;
        PSMMacro.SetExtSWX_MenuName=MenuName;
     end
else
    chansXok=PSMMacro.SetExtSWX_chansXok;
    if isempty(PSMMacro.SetExtSWX_chansX)
        chansX=1:size(names,1);                 % select all channels of data
    else
        chansX=PSMMacro.SetExtSWX_chansX;
    end
    MenuName=PSMMacro.SetExtSWX_MenuName;
end

if PSMMacro.RunMode==0      % if in macro definition mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SetExtSWX_chansXok=chansXok;
        PSMMacro.SetExtSWX_chansX=chansX;
        PSMMacro.SetExtSWX_MenuName=MenuName;
    else
        PSMMacro.SetExtSWX_chansXok=NaN;
        PSMMacro.SetExtSWX_chansX=NaN;
        PSMMacro.SetExtSWX_MenuName='';
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
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