function [ScanFiles,DataPath]=PSMscanFiles(PSMtype)
% Generate list of PSM files to scan
% This version assumes time-sequential file names 
%
%  [ScanFiles]=PSMscanFiles(PSMtype);
%
% PSM Tools called from PSMscanFiles:
%   ynprompt, nvprompt
%
%
% Modified 01/29/03.  jfh
% Modified 02/13/04.  Henry Huang
% Modified 07/14/06.  jfh  Provided return for DataPath
%
% 02/17/04, Add PPSM Special data file extension -'.mat'. Henry.
% 02/13/04, Add SWX file extension -'.d**' for Transcan format. Henry.
% 02/09/04, Add SWX file scan assuming filename extensions-'.swx','.txt','.dat'. Henry.
% 12/09/13, Add CFF file extension for unified-file COMTRADE reading
 
% By J. F. Hauer, Pacific Northwest National Lboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%global Kprompt ynprompt nvprompt
%global PSMtype CFname PSMfiles PSMreftimes

disp(['In PSMscanFiles: PSMtype = ' PSMtype])

ScanFiles=''; DataPath='';

%************************************************************************
%Determine range of PSM source files for data to extract
strx='*.*';
if ~isempty(findstr('PDC',PSMtype)), strx='*.dst'; end
if ~isempty(findstr('CFF',PSMtype)), strx='*.cff'; end
firstok=0; lastok=0;
firstFile=''; firstPath='';
lastFile =''; lastPath ='';
for N=1:6
  disp('  ')
  prompt='Locate first file to process';
  disp(prompt)
  disp('Processing paused - press any key to continue'); pause
  [filename,pathname]=uigetfile([strx],prompt);
  if filename(1)==0|pathname(1)==0
    retok=promptyn('No file selected -- return? ', 'n');
    if retok, return, end
  end
  disp(['  First file to process = ' filename])
  firstok=promptyn('  Is this ok? ', 'y');
  if firstok
    firstFile=filename; firstPath=pathname;
    disp('In PSMscanFiles: Changing to directory shown below:')
    disp(pathname)
	eval(['cd ' '''' pathname ''''])
    DataPath=pathname;
    break 
  end
end
for N=1:6
  disp('  ')
  prompt='Locate last file to process';
  disp(prompt)
  disp('Processing paused - press any key to continue'); pause
  [filename,pathname]=uigetfile([strx],prompt);
  if filename(1)==0|pathname(1)==0
    retok=promptyn('No file selected -- return? ', 'n');
    if retok, return, end
  end
  if isempty(lastPath), lastPath=firstPath; end
  if isempty(findstr(firstPath,lastPath))
    disp(' ')
    disp('PATHS DO NOT MATCH: Not supported by present code')
    disp(['  firstPath = ' firstPath])
    disp(['  lastPath  = ' lastPath])
    lastok=0;
  else  
   disp(['  Last file to process = ' filename])
   lastok=promptyn('  Is this ok? ', 'y');
    if lastok
      lastFile=filename; lastPath=pathname; break 
    end
  end
end
if ~(firstok&lastok)
  disp('In PSMscanFiles: Improper file selections -- return'); return
end
%************************************************************************

%************************************************************************
%Determine files available for processing
PSMworkDir=dir; PSMdirNames={};
PSMdirNo=length(PSMworkDir);
PSMdirNames=char(PSMworkDir.name);
PSMdirNames=sortrows(PSMdirNames);
datLocs=[]; iniLocs=[];
for N=1:PSMdirNo
  str=deblank(PSMdirNames(N,:)); lenS=length(str);
  if ~isempty(findstr('PDC',PSMtype))
    if lenS>=14
      if ~isempty(findstr('.dst',str)) | ~isempty(findstr('.DST',str)), datLocs=[datLocs N]; end    % add UPPER case. Henry
      if ~isempty(findstr('.ini',str)) | ~isempty(findstr('.INI',str)), iniLocs=[iniLocs N]; end    % add UPPER case. Henry
    end
  elseif ~isempty(findstr('PPSM Special',PSMtype))
    if lenS>=18
      if ~isempty(findstr('.mat',lower(str))), datLocs=[datLocs N]; end 
    end
  elseif ~isempty(findstr('PPSM',PSMtype))
    if lenS>=18
      if isempty(findstr('.',str(lenS-3:lenS))), datLocs=[datLocs N]; end 
    end
  elseif ~isempty(findstr('SWX',PSMtype))   % SWX file. Henry
    if lenS>=8
      if ~isempty(findstr('.swx',str)) | ~isempty(findstr('.txt',str)) | ~isempty(findstr('.dat',str)) | ~isempty(findstr('.d',str))
          datLocs=[datLocs N]; 
      elseif ~isempty(findstr('.SWX',str)) | ~isempty(findstr('.TXT',str)) | ~isempty(findstr('.DAT',str)) | ~isempty(findstr('.D',str))
          datLocs=[datLocs N]; 
      end 
    end
  elseif (~isempty(findstr('.cff',str)) | ~isempty(findstr('.cff',str)))
      datLocs=[datLocs N];
  else   %Take a guess!
    if lenS>=8
      datLocs=[datLocs N]; 
    end
  end
end
PSMdatFiles=''; PSMiniFiles='';
if ~isempty(datLocs)
  PSMdatFiles=char(PSMdirNames(datLocs,:));
end
if ~isempty(datLocs)
  PSMiniFiles=char(PSMdirNames(iniLocs,:));
end
%************************************************************************

%************************************************************************
%Determine all files to scan
firstLoc=[]; lastLoc=[];
for N=1:length(datLocs)
  if ~isempty(findstr(firstFile,PSMdatFiles(N,:))), firstLoc=N; end
  if ~isempty(findstr(lastFile, PSMdatFiles(N,:))), lastLoc=N;  end
end
scanlocs=[firstLoc:lastLoc];
ScanFiles=PSMdatFiles(scanlocs,:);
%************************************************************************

%************************************************************************
%Verify file selections
disp(' ')
disp(['In PSMscanFiles: Files to scan are on path shown below'])
disp(['  ' DataPath])
disp(['First and last files to scan are'])
disp(['  firstFile  = ' firstFile])
disp(['  lastFile   = ' lastFile])
disp(['  Number of files to scan = ' num2str(size(ScanFiles,1))])
disp(' ')
filesok=promptyn('In PSMscanFiles: Is this ok? ', 'y');
if ~filesok
  retok=promptyn('Return from PSMscanFiles? ', 'y');
  if retok
	  disp('In PSMscanFiles: File names not accepted -- return'),
    extractok=0; diary off, return
  else
    disp('Invoking "keyboard" command -  Type "return" when you are done')
    keyboard
  end
end
%************************************************************************

%end of PSMT utility

