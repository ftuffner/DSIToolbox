function [MenuName,chansX,chansXok,names,chankey]=SetExtPPSM(chansXstr,names,chankey,CFname)
% Determine signals to extract from PPSM records
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
% PSM Tools called from SetExtPPSM:
%   PPSMmenu
%   SigSelect
%   promptyn
%
%  Last modified 10/07/03.  jfh
%  Last modified 10/18/2006  Ning Zhou to add macro function

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

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

FNname='SetExtPPSM';  %Internal name of this utility

%*********************************************************************
nsigs=size(names,1)-1;
TimeOK=~isempty(findstr('time',lower(names(1,1:4))));
disp(' ')
str=['In ' FNname ': Number of stored signals=' num2str(nsigs)];
disp(str)
disp('   Time axis will be inserted at column 1')
%keyboard
%*********************************************************************

%*********************************************************************
%Check for null signals
NulChans=[];
for N=2:nsigs+1
  tstr=lower(names(N,:));
  NulSig=~isempty(findstr(tstr,'not found'));
  NulSig=NulSig|~isempty(findstr(tstr,'spare'));
  NulSig=NulSig|~isempty(findstr(tstr,'empty'));
  if NulSig, NulChans=[NulChans N-1]; end
end
Nulls=length(NulChans); NullsOut=0;
if Nulls>0
    disp(sprintf('Data indicates %3i null channels: ',Nulls));
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'SetExtPPSM_NullsOut'), PSMMacro.SetExtPPSM_NullsOut=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.SetExtPPSM_NullsOut))      % Not in Macro playing mode or selection not defined in a macro
        NullsOut=promptyn('Do you want to supress null channels? ', 'n');;
    else
        NullsOut=PSMMacro.SetExtPPSM_NullsOut;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.SetExtPPSM_NullsOut=NullsOut;
        else
            PSMMacro.SetExtPPSM_NullsOut=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % NullsOut=promptyn('Do you want to supress null channels? ', 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
end
if NullsOut,chansX=IndSift(chansX,NulChans); end 
%*********************************************************************

%*********************************************************************
%Define PPSM signal types
SigTypes=str2mat('Time','(Hz) ','(kV)','spare','(Amps)','spare','(MW)','(MVAR)');
SigTypes=str2mat(SigTypes,'spcl','end ');
Rename=1;
if Rename %Standardize PPSM signal types to PDC conventions
  disp('In SetExtPPSM: Standardizing signal types to PDC conventions')
  SigTypes0=SigTypes;
  SigTypes =str2mat('Time','FreqL','VMag','VAngL','IMag ' ,'IAngL','MW  ','MVar');
  SigTypes =str2mat(SigTypes,'spcl','end ');
  ntypes=size(SigTypes,1);
  TypeTags='Time';
  for nsig=2:nsigs+1
    strsig=lower(deblank(names(nsig,:))); L2=length(strsig);
    typefound='';
    for ntype=2:ntypes
      SigType=deblank(SigTypes0(ntype,:)); L1=L2-length(SigType)+1;
      if ~isempty(findstr(lower(SigType),strsig(L1:L2)))
        typefound=SigTypes(ntype,:); 
        names(nsig,L1:L2)=' ';
        break
      end
    end
    %disp([names(nsig,:) ' ' typefound])
    TypeTags=str2mat(TypeTags,typefound);
  end
  namesN=[names(1,:) ' ' TypeTags(1,:)];
  for nsig=2:nsigs+1
    namesN=str2mat(namesN,[names(nsig,:) ' ' TypeTags(nsig,:)]);
    %disp(namesN(nsig,:))
  end
  [names]=BstringOut(namesN,' ',2);  %Delete extra blanks
  chankey=str2mat(deblank(chankey(1,:)),names2chans(names(2:nsigs+1,:)));
end
%*********************************************************************

%*********************************************************************
%Load PPSM custom menus

chansMenuC=''; chansSC='';
if isempty(deblank(which('PPSMmenu')))
  str=['In ' FNname ': Utility PPSMmenu not found -- No custom menus'];
  disp(str)
else
  [chansMenuC,chansSC]=PPSMmenu('','',CFname,nsigs);
end
if ~isempty(chansMenuC)
  if isempty(deblank(chansMenuC(1,:)))
    NmenusC=size(chansMenuC,1);
    if NmenusC>1
      chansMenuC=chansMenuC(2:NmenusC,:);
      chansSC=chansSC(2:NmenusC,:);
    else
      chansMenuC='';
      chansSC='';
    end
  end
end
NmenusC=size(chansMenuC,1);
%*********************************************************************

%*********************************************************************
%Determine signals to extract
LL=2:nsigs; %keyboard
ProcessCom='PPSM signal extraction';
%keyboard
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard%
if ~isfield(PSMMacro, 'SetExtPPSM_chansXok'), PSMMacro.SetExtPPSM_chansXok=NaN;end
if ~isfield(PSMMacro, 'SetExtPPSM_chansX'), PSMMacro.SetExtPPSM_chansX=NaN; end
if ~isfield(PSMMacro, 'SetExtPPSM_MenuName'), PSMMacro.SetExtPPSM_MenuName='';end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.SetExtPPSM_chansXok) || PSMMacro.SetExtPPSM_chansXok==0)      % 'Macro record mode' or 'selection was not defined in a macro'
    [MenuName,chansX,chansXok]=SigSelect(chansX,names(LL,:),chankey(LL,:),...)
       CFname,SigTypes,chansMenuC,chansSC,ProcessCom);
     if (PSMMacro.RunMode==2)               %Batch Macro Mode;
        PSMMacro.SetExtPPSM_chansXok=chansXok;
        PSMMacro.SetExtPPSM_chansX=chansX;
        PSMMacro.SetExtPPSM_MenuName=MenuName;
     end
else
    chansXok=PSMMacro.SetExtPPSM_chansXok;
    if isempty(PSMMacro.SetExtPPSM_chansX)
        chansX=1:size(names,1);                 % select all channels of data
    else
        chansX=PSMMacro.SetExtPPSM_chansX;
    end
    MenuName=PSMMacro.SetExtPPSM_MenuName;
end

if PSMMacro.RunMode==0      % if in macro definition mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SetExtPPSM_chansXok=chansXok;
        PSMMacro.SetExtPPSM_chansX=chansX;
        PSMMacro.SetExtPPSM_MenuName=MenuName;
    else
        PSMMacro.SetExtPPSM_chansXok=NaN;
        PSMMacro.SetExtPPSM_chansX=NaN;
        PSMMacro.SetExtPPSM_MenuName='';
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
