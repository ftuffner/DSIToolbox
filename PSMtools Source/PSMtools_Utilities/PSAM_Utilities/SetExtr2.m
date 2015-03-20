function [chansX,chansXok]=SetExtr2(chansXstr,names,chankey,ListName)
% Determine signals to extract from PSAM records
% 
% NOMENCLATURE WARNINGS:
%   - PSMsigsX  is an array extracted from any PSM (power system monitor)
%   - PSAM Hardware channels are numbered [1:N]
%   - Signals to extract are numbered [1:N+1], with time axis at column 1
%
% PSM Tools called from SetExtr2:
%   PSAMmenu
%   promptyn
%
%  Last modified 09/09/99.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


%*********************************************************************
nsigs=size(names,1)-1;
disp(' ')
disp(sprintf('In SetExtr2: Number of stored signals=%3.3i',nsigs))
%disp('   Time axis will be inserted at column 1')
setok=promptyn('In SetExtr2: Display full channel key? ', 'y');
if setok
  disp(chankey)
  disp('   Left column shows indexing for signals')
  disp(' ')
  disp('In SetExtr2: Processing is paused - press any key to continue')
  pause
end
%*********************************************************************

%*********************************************************************
%Define convenience menus
[chansMenu,chansS]=PSAMmenu(ListName,nsigs);
%*********************************************************************

%*********************************************************************
%Review starting menu for signal selection
MenuName='In SetExtr2: Initial User Selections';
if ~ischar(chansXstr)
  chansXstr=['chansX=[' num2str(chansXstr) '];'];
end
chansX=[]; chansXok=0;
eval(chansXstr);
chansX=chansX(find(chansX<=nsigs+1)); chansX0=chansX;
nsigsX=size(chansX,2);
if nsigsX>0 
  disp('In SetExtr2: Initial value of chansXstr follows:')
  locsok=chansX<=(nsigs+1); chansX=chansX(locsok);
  disp(chansX);
  for N=1:nsigsX
    col=chansX(N);
    disp(['     '  chankey(col,:)]);
  end
  chansXok=promptyn('Are these the signals to extract? ', '');
end
if chansXok
  disp('Initial value of chansX accepted:')
  disp('Returning to invoking Matlab function.')
  return
end
%*********************************************************************

%*********************************************************************
%Determine starting menu for signal selection
MenuName='In SetExtr2: Interactive User Selections';
menus=size(chansMenu,1);
if findstr('Initial user selections',chansMenu(1,:))
  chansS=str2mat(['[' num2str(chansX0) ']'],chansS(2:menus,:));
end
MenuOk=0;  maxtrys=10;
for i=1:maxtrys
  disp(' ')
  disp('Select starting menu for signal extraction: Preset options are')
  if ~MenuOk
    for N=1:menus
      disp(['     ' (sprintf('%4.3i',N)) '  ' chansMenu(N,:)])
    end
    disp('  ')
    prompt=['   Select starting menu - enter 1 to ' sprintf('%3.2i',menus) ' '];
    menu=promptnv(prompt,'');
    menu=max(1,menu); menu=min(menus,menu);
    disp(['   Menu ' sprintf('%4.3i',menu) ': ' chansMenu(menu,:)])
    chansX=eval(chansS(menu,:)); nsigsX=size(chansX,2);
    for N=1:nsigsX
      col=chansX(N);
      disp(['     '  chankey(col,:)]);
    end
    MenuOk=promptyn('   Is this the right menu to start with? ', 'y');
	  if MenuOk, MenuName=chansMenu(menu,:); break, end
  end
end
if ~MenuOk
  EXCOM=sprintf('SORRY -%5i chances is all you get!',maxtrys);
  MenuName='NONE';
  disp([EXCOM,'Returning to invoking Matlab function.'])
  return
end
%*********************************************************************

%*********************************************************************
%Process special cases
if findstr('No channels',MenuName)
  MenuName='NONE';  EXCOM='No signals desired - ';
  disp([EXCOM,'Returning to invoking Matlab function.'])
  disp(' ')
  return
end
%*********************************************************************

%*************************************************************************
%Logic for sorting by signal type (not supported yet)
disp(' ')
if findstr('Sort by signal type',MenuName)
  MenuName='NONE';  EXCOM='Option not supported yet - ';
  disp([EXCOM,'Using first menu.'])
  disp(' ')
  menu=1; chansX=eval(chansS(menu,:));
end
%*************************************************************************

%*********************************************************************
%Display/Edit starting menu for signal selection
disp(' ')
chansXok=0;  maxtrys=10;
for i=1:maxtrys
  if ~chansXok
    nsigsX=size(chansX,2);
    disp('   PRESENT MENU FOLLOWS:')
    for N=1:nsigsX
      col=chansX(N);
      disp(['     '  chankey(col,:)]);
    end
    setok=promptyn('   Do you want to edit this menu? ', '');
    if setok 
      disp('   Select signal numbers for extraction:')
      disp('   Left column shows indexing for signals')
      disp('   Present value of chansX follows:')
      chansXS=['chansX=[' num2str(chansX) ']'];
	    disp(chansXS)
      EXCOM='  Invoking "keyboard" command - use arrow keys to select and edit example,';
      disp(str2mat(EXCOM,'  Type "return" when you are finished!!'))
      MenuName=[MenuName '(modified)'];
      keyboard
    else chansXok=1;
    end
  end
  if chansXok, break, end
end
if ~chansXok
  EXCOM=sprintf('SORRY -%5i chances is all you get!',maxtrys);
  MenuName='NONE';
  disp([EXCOM,' Returning to invoking Matlab function.'])
  return
end
%*********************************************************************


return

%end of PSM script