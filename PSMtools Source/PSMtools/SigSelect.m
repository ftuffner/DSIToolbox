function [MenuName,chansX,chansXok]=SigSelect(chansX,names,chankey,...
  CFname,SigTypes,chansMenuC,chansSC,Comment)
% Determine signals to select for processing
% 
% PSM Tools called from SigSelect:
%   PSMmenuEdit (internal function)
%   promptyn, promptnv
%
% Modified 05/19/05 by jfh.  Changed some defaults & prompts
% Modified 07/12/05 by Henry Huang.  Changed some defaults & prompts

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

global Kprompt ynprompt nvprompt
ynprompt0=ynprompt; ynprompt=1; %sets "y or n" prompts within m-files on
nvprompt0=nvprompt; nvprompt=1; %sets numerical value prompts within m-files on

MenuName=''; chansXok=0;
if ischar(chansX), eval(chansX); end
if ~exist('Comment'), Comment='Processing'; end

FNname='SigSelect';  %Internal name of this utility

%*********************************************************************
strs=['In ' FNname ': Automatic defaults suspended'];
strs=str2mat(strs,['  Select signals for ' Comment]);
disp(strs)
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
setok=promptyn('In SigSelect: Display full channel key? ', 'n');
if setok
  disp(chankey)
  disp('   Left column shows indexing for signals (including time)')
  disp(' ')
  disp('In SigSelect: Processing is paused - press any key to continue')
  pause
end
%*********************************************************************

%*********************************************************************
%Review starting menu for signal selection
MenuName='In SigSelect: Initial User Selections';
chansX=chansX(find(chansX>0)); 
chansX=chansX(find(chansX<=nsigs)); 
chansX0=chansX;
nsigsX=length(chansX);
MenuOk=0; MenuEditOK='';
if nsigsX>0 
  disp(' ')
  disp('In SigSelect: Initial value of chansX follows:')
  chansX=chansX(find(chansX>0)); 
  chansX=chansX(find(chansX<=nsigs)); 
  disp(['  chansX=[' num2str(chansX) '];']);
  for N=1:nsigsX
    col=chansX(N);
    disp(['     '  chankey(col,:)]);
  end
  prompt=['Use this as starting menu for ' Comment '? ']; 
  if findstr( 'modemeter', lower(Comment))     % make default to 'y' for Modemeter case. Henry 07/12/05
      MenuOk=promptyn(prompt,'y');
  else
  MenuOk=promptyn(prompt,'');
  end
end
if MenuOk
  if findstr( 'modemeter', lower(Comment))     % make default to 'y' for Modemeter case. Henry 07/12/05
      MenuEditOK=promptyn('Do you want to edit this menu? ', 'y');
  else
  MenuEditOK=promptyn('Do you want to edit this menu? ', '');
  end
  chansXok=~MenuEditOK;
  if chansXok
    disp('Initial value of chansX accepted:')
    disp('Returning to invoking Matlab function')
    ynprompt=ynprompt0; nvprompt=nvprompt0;
    return
  else
    [MenuName,chansX,chansXok]=PSMmenuEdit(MenuName,chansX,names,chankey,...
      CFname,SigTypes,chansMenuC,chansSC,Comment,MenuEditOK);
    ynprompt=ynprompt0; nvprompt=nvprompt0;
    return
  end
end
%*********************************************************************

%*********************************************************************
%Define generic menus
MenuTypes=1:5; %For future use 
chansMenu=('Initial user selections');
chansS=['[' num2str(chansX0) ']'];
chansMenu=str2mat(chansMenu,'All channels');
chansS=str2mat(chansS,['[1:' num2str(nsigs) ']']);
chansMenu=str2mat(chansMenu,'No channels--exit');
chansS=str2mat(chansS,'[]');
chansMenu=str2mat(chansMenu,'Interactive selection of channels');
chansS=str2mat(chansS,'[]');
chansMenu=str2mat(chansMenu,'Sort by signal type');
chansS=str2mat(chansS,'[]');
%*********************************************************************

%*********************************************************************
%Append custom menus
if ~isempty(chansMenuC)
  chansMenu=str2mat(chansMenu,chansMenuC);
  chansS=str2mat(chansS,chansSC);
  MenuTypes=1:size(chansMenu,1);
end
%*********************************************************************

%*********************************************************************
%Determine starting menu for signal selection
chansX=[]; MenuName=''; SortSigs='';
menus=size(chansMenu,1);
MenuOk=0;  maxtrys=menus+5;
for I=1:maxtrys
  disp(' ')
  disp('Building signal selection list: Submenu options are')
  for N=1:menus
    disp(['     ' (sprintf('%4.3i',N)) '  ' chansMenu(N,:)])
  end
  disp('  ')
  prompt=['   Select submenu - enter 1 to ' sprintf('%3.0i',menus) ' '];
  menu=promptnv(prompt,[2]);
  if ~isempty(menu)
    menu=max(1,menu); menu=min(menus,menu);
    disp(['   Submenu ' sprintf('%4.3i',menu) ': ' chansMenu(menu,:)])
    chansXN=eval(chansS(menu,:)); 
    chansXN=chansXN(find(chansXN<=nsigs));
    nsigsXN=length(chansXN);
    for N=1:nsigsXN
      col=chansXN(N);
      disp(['     '  chankey(col,:)]);
    end
    addok=promptyn('Add this submenu to selection list? ', 'y');    % add default 'y', Henry 07/12/05
  else
    addok=0;
  end
  if addok
    MenuOk=1;  %At least one submemu has been selected 
    if isempty(MenuName), MenuName=chansMenu(menu,:);
    else MenuName='Multiple Submenus'; end
    chansX=[chansX chansXN];
    SortSigs=findstr('Sort by signal type',chansMenu(menu,:));
    if SortSigs, break, end
    InterActive=findstr('Interactive selection',chansMenu(menu,:));
    if InterActive, break, end
  end
  addok=promptyn('Add more submenus? ', '');
  if ~addok, break, end
  if I==maxtrys
    disp(sprintf('SORRY: %5.0i chances is all you get! ',maxtrys));
  end
end
if ~MenuOk
  chansX=0; chansXok=0;
  MenuName='NONE';  str1='No signals selected - ';
  disp([str1,'Returning to invoking Matlab function.'])
  disp(' ')
  ynprompt=ynprompt0; nvprompt=nvprompt0;
  return
end
%*********************************************************************

%*********************************************************************
%Process special cases
if isempty(MenuName), MenuName='none'; end
if findstr('No channels',MenuName)|findstr('none',lower(MenuName))
  chansX=0; chansXok=0;
  MenuName='NONE';  
  str1=['In ' FNname ': No signals selected - '];
  disp([str1,'Returning to invoking Matlab function'])
  disp(' ')
  ynprompt=ynprompt0; nvprompt=nvprompt0;
  return
end
%*********************************************************************

%*************************************************************************
%Logic for sorting by signal type
disp(' ')
MatchCase=0; %keyboard
SigTypes0=SigTypes;
%SigTypes=SigTypes0;
if SortSigs
  disp(['In ' FNname ': Sorting by signal type'])
  Ntypes=size(SigTypes,1);
  TypesLoc=1:Ntypes;
  [lines chars]=size(names);
  for I=1:Ntypes
    SigTypeI=deblank(SigTypes(I,:));
    SigTypesIN=[];
    for N=1:lines
      teststr=[names(N,:) ' '];
      Ltest=findstr(SigTypeI,teststr);
      if ~MatchCase, Ltest=findstr(lower(SigTypeI),lower(teststr)); end
      if ~isempty(Ltest)
        %test=strcmp(teststr(Ltest+length(SigTypeI)),' ');
        test=1;
        if test, SigTypesIN=[SigTypesIN N]; end
      end
    end
    if isempty(SigTypesIN), TypesLoc(I)=0; end
  end
  TypesLoc=find(TypesLoc>0);
  SigTypes=SigTypes(TypesLoc,:);
  Ntypes=size(SigTypes,1);
  SortSigs=SortSigs&Ntypes;
  %Locate signals by type
  LocTypes=zeros(Ntypes,nsigs);
  for nsig=1:nsigs 
    sigstr=names(nsig,:);
    for ntype=1:Ntypes
      SigType=deblank(SigTypes(ntype,:));
      Ltest=findstr(SigType,sigstr);
      if ~MatchCase, Ltest=findstr(lower(SigType),lower(sigstr)); end
      if ~isempty(Ltest)
        LocTypes(ntype,nsig)=nsig;
      end
    end
  end
  maxtrys=20; TypeDef=2;
  for I=1:maxtrys
    Ntypes=size(SigTypes,1); NtypesD=Ntypes+2;
    SigTypesD=str2mat(SigTypes,'special type','end');
    Types9899=[98 99]+fix(Ntypes/100);
    SortTypes=[1:Ntypes Types9899];
    disp(' ')
    disp(['In ' FNname ': Sorting options are'])
    for n=1:NtypesD
      disp(['% ' sprintf('%3.0i',SortTypes(n)) ' ' SigTypesD(n,:)])
    end
    prompt=['Select a value from list above: '];
    SortType=promptnv(prompt,TypeDef); TypeDef=99;
    if isempty(SortType), SortType=2; end
    SortType=max(SortType,1); SortType=min(SortType,SortTypes(NtypesD));
    if ~isempty(find(SortType==Types9899(2)))
      ntype=0;
      addok=promptyn('Add more signals to selection list? ', '');
      if ~addok, break, end
    end
    if ~isempty(find(SortType==Types9899(1)))
      spcltype=promptyn('Define special type signal? ', 'n');
      if spcltype
        SigType='';
        SpclTag=input(['Enter tag for special type signal (else return) '],'s');
        if ~isempty(SpclTag), SigType=SpclTag; end
        if ~isempty(SigType)
          SigTypes=str2mat(SigType,SigTypes); SortType=1;
          Ntypes=size(SigTypes,1);
        end
      end
    end
    chansXN=[]; ntype=SortType;
    if ntype<=Ntypes
      MatchCase=promptyn('Match cases in signal names? ', '');
      SigType=deblank(SigTypes(ntype,:));
      for nsig=1:nsigs      %Locate signals of indicated type
        sigstr=names(nsig,:);
        Ltest=findstr(SigType,sigstr);
        if ~MatchCase, Ltest=findstr(lower(SigType),lower(sigstr)); end
        if ~isempty(Ltest)
          chansXN=[chansXN nsig];
        end
      end
    else
      SigType=['Type ' num2str(ntype)];
    end
    if isempty(chansXN)
      if isempty(find(SortType==Types9899))
        disp(['No ' SigType ' signals available'])
      end          
    else
      disp([SigType ' signals available:'])
      disp(chankey(chansXN,:))
      Typeok=promptyn('Add these signals to selection list? ', 'y');
      if Typeok
        chansX=[chansX chansXN]; 
      end
    end
    if I==maxtrys
      disp(sprintf('SORRY: %5.0i chances is all you get!',maxtrys))
    end
  end
end
%*************************************************************************

MenuEditOK='';
[MenuName,chansX,chansXok]=PSMmenuEdit(MenuName,chansX,names,chankey,...
   CFname,SigTypes,chansMenuC,chansSC,Comment,MenuEditOK);

ynprompt=ynprompt0; nvprompt=nvprompt0;
return

%end of PSMT function

%###################################################################
function [MenuName,chansX,chansXok]=PSMmenuEdit(MenuName,chansX,names,chankey,...
  CFname,SigTypes,chansMenuC,chansSC,Comment,MenuEditOK)
% Determine signals to process
% 
% PSM Tools called from PSMmenuEdit:
%   promptyn, promptnv
%
%  Modified 05/17/04.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

global Kprompt ynprompt nvprompt

FNname='PSMmenuEdit';  %Internal name of this utility

nsigs=size(names,1);
if ~exist('MenuEditOK'), MenuEditOK=''; end
if ~isempty(MenuEditOK)&(~MenuEditOK), MenuEditOK=''; end

%*********************************************************************
%Display/Edit starting menu for signal selection
disp(' ')
if isempty(chansX), chansX=0; end
if chansX==0, chansX=1; end
chansXok=0;  maxtrys=10;
for I=1:maxtrys
  if ~chansXok
    chansX=chansX(find(chansX>0)); 
    chansX=chansX(find(chansX<=nsigs));
    %if isempty(chansX), chansX=1; end
    disp(['In ' FNname ' (internal to SigSelect): PRESENT MENU FOLLOWS'])
    if isempty(chansX)
      disp('  ChansX = [empty]')
    else
      nsigsX=length(chansX);
      for N=1:nsigsX
        col=chansX(N);
        disp(['     '  chankey(col,:)]);
      end
    end
    if MenuEditOK&(I==1)
      setok=1;
    else
      setok=promptyn('   Do you want to edit this menu? ', '');
    end
    if setok 
      disp(['   Select signal numbers for ' Comment ':'])
      disp( '   Left column shows indexing for signals')
      disp( '   Present value of chansX follows:')
      chansXS=['chansX=[' num2str(chansX) ']'];
	    disp(chansXS)
      str1='  Invoking "keyboard" command - use arrow keys to select and edit example,';
      disp(str2mat(str1,'  Type "return" when you are finished!!'))
      if isempty(findstr(MenuName,'(modified)'))
        MenuName=[MenuName '(modified)'];
      end
      keyboard
    else chansXok=1;
    end
  end
  if chansXok, break, end
  if I==maxtrys
    disp(sprintf('SORRY: %5.0i chances is all you get!',maxtrys))
  end
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



