function [MenuName,chansX,chansXok]=SetExtPSMT(chansXstr,names,chankey,CFname)
% Determine signals to extract from SWX records
%
% PSM Tools called from SetExtPSMT:
%   promptyn
%
%  Last modified 03/04/03.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

MenuName=''; chansX=[]; chansXok=0;
if ~ischar(chansXstr)
  chansXstr=['chansX=[' num2str(chansXstr) '];'];
end
eval(chansXstr);

FNname='SetExtPSMT';  %Internal name of this utility

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
%Define PSMT signal types
%PDC signal types
  SigTypes=str2mat('Time','Freq','VFrq','VMag','VAng','IMag','IAng','MW  ','MVar');
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
%Load PSMT custom menus
%keyboard
chansMenuC=''; chansSC='';
if ~isempty(deblank(which('PSMTmenu')))
  [chansMenuC,chansSC]=PSMTmenu('','',CFname,nsigs);
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
ProcessCom='PSMT signal extraction';
[MenuName,chansX,chansXok]=SigSelect(chansX,names,chankey,...)
   CFname,SigTypes,chansMenuC,chansSC,ProcessCom);
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