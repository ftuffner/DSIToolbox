function [MenuName,chansX,chansXok]=PickSigsP(chansXstr,names,chankey,...
          CFname,ProcessCom)
% Select signals by channel number or type
% 
% PSM Tools called from PickSigsP:
%   PickMenu
%   SigSelect
%   promptyn, promptnv
%
%  Last modified 02/17/04.  jfh

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
if ~exist('CFname'),      CFname=''; end
if ~exist('ProcessCom'),  ProcessCom=''; end
if isempty(ProcessCom), ProcessCom='processing'; end

FNname='PickSigsN';  %Internal name of this utility

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
  SigTypes=str2mat(  'Time','Freq' ,'VMag' ,'VAng','IMag','IAng','MW  ','MVar');
  SigTypes=str2mat(SigTypes,'FreqL','FreqR','FreqA','FreqLX','FreqRX','FreqAX');
  SigTypes=str2mat(SigTypes,'VAngL','VAngR','VAngA','VAngLX','VAngRX','VAngAX');
  SigTypes=str2mat(SigTypes,'IAngL','IAngR','IAngA','IAngLX','IAngRX','IAngAX');
  SigTypes=str2mat(SigTypes,'VFrq');
%PSLF signal types
  SigTypes=str2mat(SigTypes,'vbus   VMag','abus   VAng','fbus   Freq');
  SigTypes=str2mat(SigTypes,'pbr    MW  ','qbr    Mvar','pif    MW  ','qif    Mvar');
  SigTypes=str2mat(SigTypes,'pacr   MW  ','qacr   Mvar','paci   MW  ','qaci   Mvar');
  SigTypes=str2mat(SigTypes,'ang    Gang','spd    Gfrq','pg     MW  ','qg     Mvar');
%PTI signal types
  SigTypes=str2mat(SigTypes,'POWR ','VARS ','PMEC ','VREF ','EFD  ','ETRM ','AUX  ');
  SigTypes=str2mat(SigTypes,'ANG  ','ANGL ','ANGR ','ANGA ');
  SigTypes=str2mat(SigTypes,'FREQ ','FREQL','FREQR','FREQA');
  SigTypes=str2mat(SigTypes,'SPD  ','SPDL ','SPDR ','SPDA ');
%*********************************************************************

%*********************************************************************
%Load custom menus
%keyboard
chansMenuC=''; chansSC='';
if isempty(deblank(which('PickMenu')))
  str=['In ' FNname ': Utility PickMenu not found -- No custom menus'];
  disp(str)
else
  [chansMenuC,chansSC]=PickMenu('','',CFname,nsigs);
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
%Determine signals to process
[MenuName,chansX,chansXok]=SigSelect(chansX,names,chankey,...)
   CFname,SigTypes,chansMenuC,chansSC,ProcessCom);
%*********************************************************************

%*********************************************************************
if TimeOK
  %if chansX(1)~=1, chansX=[1 chansX]; end
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

