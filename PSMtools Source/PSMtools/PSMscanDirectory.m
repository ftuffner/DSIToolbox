function [ScanFiles, DataPath, FileType]=PSMscanDirectory(PSMtype, DataPathIn, FileType)
% Generate list of PSM files to scan
% This version assumes time-sequential file names 
%
%  [ScanFiles]=PSMscanDirectory(PSMtype);
%
% PSM Tools called from PSMscanFiles:
%   ynprompt, nvprompt
%
% Created based on PSMscanFiles(PSMtype) by Ning Zhou;
%  FileType: appendixes of the files (i.e. 'dst', 'ini');
%
% 02/17/04, Add PPSM Special data file extension -'.mat'. Henry.
% 02/13/04, Add SWX file extension -'.d**' for Transcan format. Henry.
% 02/09/04, Add SWX file scan assuming filename extensions-'.swx','.txt','.dat'. Henry.
% 12/09/13, Add CFF file scan for COMTRADE Frank Tuffner.
 
% By J. F. Hauer, Pacific Northwest National Lboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%global Kprompt ynprompt nvprompt
%global PSMtype CFname PSMfiles PSMreftimes


disp(['In PSMscanDirectory: PSMtype = ' PSMtype])

ScanFiles=''; DataPath='';

%************************************************************************
%Determine range of PSM source files for data to extract
%keyboard;
if isdir(DataPathIn)
    DataPath=DataPathIn;
    strx='*.*';
    if ~isempty(findstr('PDC',PSMtype)), strx='*.dst'; end
    if ~isempty(findstr('CFF',PSMtype)), strx='*.cff'; end
    if ~isempty(FileType), strx=['*',FileType]; end

    if isdir(DataPath)
        cd(DataPath);
        AllFiles=dir(fullfile(DataPath,strx));
        tempFiles=char(AllFiles(:).name);
        fSeq=[];
        for fIndex=1:length(AllFiles)
            if ~AllFiles(fIndex).isdir
                fSeq=[fSeq;fIndex];
            end
        end
        ScanFiles=tempFiles(fSeq,:);
    end
    
    disp(' ');      
    disp([' All the ', strx, ' files under the following directory are to be processed: ']);
    disp(['    "', DataPath,'"']);
    disp([' With current loop, the files to process are:  ']);
    disp(ScanFiles)
    disp(' ');

else
     strx='*.*';
     if ~isempty(findstr('PDC',PSMtype)), strx='*.dst'; end
     if ~isempty(findstr('CFF',PSMtype)), strx='*.cff'; end
     if ~isempty(FileType), strx=['*',FileType]; end
     firstok=0; lastok=0;
     firstFile=''; firstPath='';
     lastFile =''; lastPath ='';
     for N=1:6
          disp('  ')
          prompt='Locate an example file to process in the directory';
          disp(prompt)
          disp('Processing paused - press any key to continue'); pause
          [filename,pathname]=uigetfile([strx],prompt);
          if filename(1)==0|pathname(1)==0
            retok=promptyn('No file selected -- return? ', 'n');
            if retok, 
                return;
            else
                continue;
            end
          end
          
         if isdir(pathname)
             DataPath=pathname;
             [pathstr, name, ext] = fileparts(filename);
             [pathstr2, name2, ext2] = fileparts(name);
             if isempty(ext)
                  FileType=[name(1:3) '*.'];
              else
                  FileType=[ext2 ext];
              end
              strx=['*',FileType];  
              AllFiles=dir(fullfile(DataPath,strx));
              tempFiles=char(AllFiles(:).name);
              fSeq=[];
              for fIndex=1:length(AllFiles)
                  if ~AllFiles(fIndex).isdir
                      fSeq=[fSeq;fIndex];
                  end
              end
              ScanFiles=tempFiles(fSeq,:);
         end
         disp(' ');      
         disp([' All the ', strx, ' files under the following directory are to be processed: ']);
         disp(['    "', DataPath,'"']);
         disp([' With current loop, the files to process are:  ']);
         disp(ScanFiles)
         disp(' ');
         firstok=promptyn('  Is this ok? ', 'y');
         if firstok
             cd(DataPath);
             break 
         else
             ScanFiles='';
         end
     end
    
    if N>=7         % maximum trying number exceed.
        return;
    end
end


