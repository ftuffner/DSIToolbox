function PDC_Alias
% PSM utility PDC_Alias
% PDC_Alias copies dst files to new locations, with new names.
% Generic names are then substituted for locational information.  	
%
% Special functions used:
%   DSTalias0
%	promptyn
%   
% Last modified 06/23/03.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

FNname='PDC_Alias';
disp(' ')
disp(['In ' FNname ': Changing datasource names in PDCfiles'])
disp(' ') 

%*************************************************************************
%Define starting directory for data extraction
 CDpath='';
%CDpath='c:\Monitor Analysis (WSCC)'  %[CUSTOM]
%Set path to working directory 
if isempty(CDpath)
  CDfile=FNname;
  Nup=1; %Levels up from folder containing CDfile
  if ~isempty(CDfile)
    disp(['Setting path to working directory: CD file = ' CDfile])
    disp('User may want to customize this later')
    command=['CDloc=which(' '''' CDfile '''' ');'];
    eval(command)
    ind=find(CDloc=='\'); 
     last=ind(max(size(ind))-Nup); 
    CDpath=CDloc(1:last);
  end
end
command=['cd(' '''' CDpath '''' ');'];
eval(command);
str=cd; disp(['In ' FNname ': Starting directory = ' str])
%*************************************************************************

%*************************************************************************
%Determine files to process
PSMtype='PDC'; PSMfiles=''; MaxFiles=99;
if isempty(PSMfiles)
  disp(['In ' FNname ': Seeking PDCfiles to process' ])
  for N=1:MaxFiles
     disp('  ')
    prompt=['Locate file ' sprintf('%2.1i',N) ' to load (else press Cancel to end)'];
    disp(prompt)
    if MaxFiles>1,disp('Processing paused - press any key to continue'); pause; end
    strx='*.*';
    if ~isempty(findstr('PDC',PSMtype)), strx='*.dst'; end
    [filename,pathname]=uigetfile([strx],prompt);
    if filename(1)==0|pathname(1)==0
	    disp('Selections complete -- processing'), break
    end
    if N==1
	    disp(['In ' FNname ': Changing to directory shown below'])
      disp(pathname)
	    eval(['cd ' '''' pathname ''''])
      PSMfiles(N,:)=filename;
    else
      PSMfiles=str2mat(PSMfiles,filename); 
    end
    disp('Files already selected:'); disp(PSMfiles)
  end
  nXfiles=size(PSMfiles,1);        %number of files to load
  disp(' ')
  disp(['Number of files to load = ' sprintf('%2.1i',nXfiles)])
  if nXfiles>0
    disp('File names in array PSMfiles are')
    disp(PSMfiles)
  end
  filesok=promptyn(['In ' FNname ': Is this ok? '], 'y');
  if ~filesok|nXfiles==0
	  disp(['In ' FNname ': No file load operations -- return'])
    return
  end
end
%*************************************************************************

%*************************************************************************
%Modify source names in PDC files
AliasOK=promptyn(['In ' FNname ': Modify source names in selected PDCfiles? '], '');
%help DSTalias0
if AliasOK
  %keyboard
  disp(['In ' FNname ': Launching dialog box for Master configuration file'])
  [n,p]=uigetfile('*.*','Select Master configuration file for sourcename modification:');
  if n==0
    disp('No file selected -- return')
    return 
  end;
  inifile0=[p n];
  [fid,message]=fopen(inifile0,'r');
  if fid<0; error(message); end;
  DataPath=cd;
  opts.verbose=1;
  [PSMfilesA,errmsg]=dstalias0(DataPath,PSMfiles,inifile0,DataPath,opts);
  if ~isempty(errmsg)
    disp(' '); disp('ERROR RETURN from DSTaliasO:')
    disp(errmsg); disp(' ')
  end
  disp(' ')
  if isempty(PSMfilesA)
    disp(['In ' FNname ': No files changed']); disp(' ')
    AliasOK=0; 
  else
    disp(['In ' FNname ': Results of PDC rename operations']) 
    NfilesA=size(PSMfilesA,1); NfilesS=size(PSMfiles,1);
    if NfilesA~=NfilesS
      disp(['In ' FNname ': Wrong number of modified files'])
    end
    nbksS=max([length(PSMfiles(1,:)) ,4]); bksS=blanks(nbksS);
    nbksA=max([length(PSMfilesA(1,:)),4]); bksA=blanks(nbksA);
    MaxNames=max([NfilesS,NfilesA]);
    for N=1:MaxNames
      str1=bksS; if N<=NfilesS, str1=PSMfiles(N,:) ; end
      str2=bksA; if N<=NfilesA, str2=PSMfilesA(N,:); end
      disp(['  ' str1 '  ' str2])
    end
  end
end
%*************************************************************************

keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '], 'n');
if keybdok
  disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end

disp(['Return from ' FNname]) 
disp(' ');

return

%end of PSMT utility

%=========================================================================
function [setok]=promptyn(query,default)
% [setok]=promptyn(query,default) 
%
% Function PROMPTYN prompts the user for a yes/no response to QUERY:
%   - empty return is equivalent to entering DEFAULT
%   - y  is interpreted as "yes", producing SETOK=1; else SETOK=0
%   - DEFAULT is returned automatically if DEFAULT(1) not empty or blank, and
%       if nvprompt=0 in "global Kprompt ynprompt nvprompt"
% This version also recognizes the following special commands:
%   keyboard  
%   quit
%   exit
%
% Last modified 04/28/03.  jfh

%Global controls on prompt defaults
global Kprompt ynprompt nvprompt

if ~exist('default'), default=' '; end
if isempty(default),  default=' '; end
if isempty(ynprompt)|default==' ', usedef=0; else usedef=~ynprompt; end

deftext=sprintf('[%s]',default);
prompt=[query ' Enter y or n ' deftext ':  '];
if usedef
  disp(prompt); setyn=default(1);
else 
  setyn=input(prompt,'s'); 
  if isempty(setyn), setyn=default; end
end
Kbdok1=strcmp(lower(setyn(1)),'k');  %String comparison
if Kbdok1  %Confirm Keyboard command
  disp(['In promptyn: User input starts with K: setok=' setyn])
  prompt=['In promptyn: Do you want the keyboard?  Enter y or n [y]:  '];
  QKbdok1=input(prompt,'s'); if isempty(QKbdok1), QKbdok1='y'; end
  QKbdok2=strcmp(lower(QKbdok1(1)),'y');  %String comparison
  if QKbdok2
    disp('In promptyn: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
end
setquit=strcmp(lower(setyn(1)),'q');  %String comparison
setexit=strcmp(lower(setyn(1)),'e');  %String comparison
if setquit|setexit  %Confirm Quit/Exit command
  disp(['In promptyn: User input starts with Q or E: setok=' setyn])
  prompt=['In promptyn: Quit/Exit Matlab?  Enter y or n [n]:  '];
  QEok1=input(prompt,'s'); if isempty(QEok1), QEok1='n'; end
  QEok2=strcmp(lower(QEok1(1)),'y');  %String comparison
  if QEok2
    disp('In promptyn: Quit/Exit command confirmed - Closing Matlab')
    quit
  end
end
setok=strcmp(lower(setyn(1)),'y');  %String comparison

%end of PSMT m-file


