% function [pathname]=pdc2mat(pathname)
%
% Interactive translation of PDC records into Matlab formats.  Options include
%   Formats:
%     Matlab format 1 (individual variables with generic names)
%     Matlab format 2 (array variables with geographic names)
%     Matlab format 3 (structure variables -- to be added later)
%     (additional future options)
%   Modification of default name for translated file
%   Appending of configuration data to translated file 
%
% PSM Tools called from pdc2mat:
%   PDCread1
%   inicopy
%   inipars2
%   promptyn
%
% Last modified 12/22/00.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

disp(' ')
disp('In m-file pdc2mat.m')
disp('Stand-alone utility for translating PDC binary files into other formats')
disp('User can append configuration data if desired')
disp(' ')

SaveFile=''; CFname='none'; initext=''; 

%************************************************************************
%Determine desired format for translated file
query='In pdc2mat: Enter Matlab format for translated file (1 or 2)';
default=2;
[matfmt]=promptnv(query, default);
matfmt=max(1,matfmt); matfmt=min(2,matfmt);
Comment=['In pdc2mat: Translating into Matlab format ' sprintf('%1.0i',matfmt)];
disp(Comment)
%************************************************************************

%************************************************************************
%Locate and translate indicated files
PDCfiles='';  DCfilesN='';  %Empty data name array
for N=1:50
  disp(' ')
  disp('Top of file translation loop:')
  if N>1, disp('Processing is paused -- press any key to continue'); pause; end
  prompt=['Locate .dst file ' sprintf('%2.1i',N) ' to translate (else press Cancel to end)'];
  disp(prompt)
  [filename,pathname]=uigetfile([''],prompt);
  if filename(1)==0|pathname(1)==0
	disp('No file indicated -- done'), break
  end
  if N==1, eval(['cd ' '''' pathname '''']); end 
  transok=1;
  pdcfname=[pathname filename];
  L1=findstr('.',filename); L2=length(filename);
  if isempty(L1)|isempty(L2)
    transok=0;
    disp(' ')
    disp(['In pdc2mat: Bad file name = ' filename])
    disp('Processing paused - press any key to continue')
    pause
  end
  tag1=filename(L1:L2); tag2='X.mat'; %Temporary 'X' for checkout purposes
  if isempty(findstr(tag1,'.dst'))
    transok=0;
    disp(' ')
    disp(['In pdc2mat: Bad file name = ' filename])
    disp('Processing paused - press any key to continue')
    pause
  end
  SaveFile=[filename(1:L1-1) tag2];
  nameok=0;
  if transok
    for ntry=1:5
      prompt=['In pdc2mat: SaveFile = ' SaveFile ' Is this ok? '];
      nameok=promptyn(prompt, 'y');
      if nameok, disp('  SaveFile name accepted'), break, end
      disp(' ')
      disp('In pdc2mat: Enter new name for SaveFile:')
      disp( '  EXAMPLE FOLLOWS:')
      disp(['  SaveFile=' '''' SaveFile ''''])
	    disp( '  Invoking "keyboard" command - Enter "return" when you are finished');
      keyboard
    end
    if ntry==5 & ~nameok
      disp('SORRY - 5 tries is all you get!  Try again on next cycle.')
      disp(' ')
    end
  end
  transok=nameok;
  if transok
    SavePath=''; %SavePath=[cd '\'];
    [errmsg,varnames]=pdcread1(pdcfname,matfmt,[SavePath SaveFile]);
    %eval(['save ' SaveFile ' ' 'L1'])
    %eval(['which ' SaveFile])
    if ~isempty(errmsg)
      transok=0;
      disp(['In pdc2mat: ' errmsg])
      disp('Processing paused - press any key to continue')
      pause
    end
  end
  if transok
    if isempty(PDCfiles)
      PDCfiles =filename;
      PDCfilesN=SaveFile;
    else
      PDCfiles =str2mat(PDCfiles ,filename);
      PDCfilesN=str2mat(PDCfilesN,SaveFile);
    end
    disp(' ')
    prompt=['In pdc2mat: Append Configuration File to SaveFile ' SaveFile '? '];
    wantCF=promptyn(prompt, 'y');
    if wantCF
      fname=''; ctag=';';
      [initext,fname,CFname]=inicopy(fname,ctag);
      disp(['In pdc2mat: CFname = ' CFname])
      [PMUtags,PMUnames,VIcon,PhsrNames,comment,samplerate]=inipars2(initext,ctag);
      CFok=1;  %Comparison tests to verify correct configuration file
      [npmus taglen]=size(PMUtags);
      if matfmt==1
        for K=1:npmus
          nphsrsK=sum(VIcon(:,1,K)==1|VIcon(:,1,K)==2);
          for N=1:nphsrsK
            signameG=[sprintf('pmu%2.0iphsr%2.0i',K-1,N-1)];
            bloc=signameG==' '; signameG(bloc)='0';
            taglen=size(signameG,2);
            match=strncmp(signameG,varnames,taglen); check=sum(match);
            CFok=CFok*(check==1);  %Each phasor name should appear 1 time
          end  
        end
      end
      if matfmt==2
        for npmu=1:npmus
          match=strncmp(PMUtags(npmu,1:taglen),varnames,taglen); check=sum(match);
          CFok=CFok*(check>=3);  %Should be at least 3 variable names per PMU
        end
      end
      if CFok
        S1=['In PDCload4: Appending configuration data ' CFname ' to ' SaveFile];
        disp(S1);
        %Need extension to SaveFile name to accommodate "fancy" path names
        str=['save ' SaveFile ' CFname  ']; eval([str '-append'])
        str=['save ' SaveFile ' initext ']; eval([str '-append'])
      else
        disp('In pdc2mat: configuration file not consistent with extracted data')
        disp( '  Invoking "keyboard" command - Enter "return" when you are finished');
        keyboard
      end
    end
  end
end
%************************************************************************

%************************************************************************
%Summary of files translated -- refine later
nXfiles=size(PDCfiles,1);        %number of files to load
disp(' ')
disp(['Number of files translated = ' sprintf('%2.1i',nXfiles)])
disp('Original files are')
disp(PDCfiles)
disp(' ')
disp('Translated files are')
disp(PDCfilesN)

%************************************************************************

disp(' ')
pathname=cd;
disp('Return from pdc2mat')
return

%end of jfh m-file

