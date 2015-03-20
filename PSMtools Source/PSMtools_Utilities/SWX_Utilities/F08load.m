function [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
    =F08load(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
     loadopt,rmsopt,saveopt,trackX);

% F08load.m is the main driver for loading signals recorded on a
% 
% F08load.m is the main driver in the logic that retrieves and 
% restructures swing export (F08) data.
%  [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,...
%      DataPath]...
%    =F08load(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
%      loadopt,rmsopt,saveopt,trackX);
%
% Special functions used:
%	  cread
%   promptyn,promptnv
%   PSMsave
%   
% Last modified 06/22/01.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


global PSMtype CFname PSMfiles PSMreftimes
if ~exist('CFname'), CFname=''; end
SaveFile='';

chansXstr=chansX;
if ~ischar(chansX)
  chansXstr=['chansX=[' num2str(chansXstr) '];'];
end
eval(chansXstr);

%*************************************************************************
if isempty(PSMfiles)
  disp(['In F08load: Seeking names for files to load' ])
  for N=1:10
    [filename,pathname]=uigetfile(['*.*'],'Locate file to retrieve:');
    if filename(1)==0|pathname(1)==0
      disp('No file indicated -- done'), break
    end
    if N==1, PDCfiles(N,:)=filename;
	    eval(['cd ' '''' pathname ''''])
      DataPath=pathname; 
    else PSMfiles=str2mat(PSMfiles,filename); end
  end
end
%*************************************************************************

%*************************************************************************
%Display & document main control parameters
nXfiles=size(PSMfiles,1);
str1=['In F08load: Load option = ' sprintf('%3.1i',loadopt)];
str2=['In F08load: Seeking data from ' sprintf('%2.1i',nXfiles) ' files:'];
disp(str1); disp(str2)
disp(PSMfiles)
CaseCom=str2mat(CaseCom,str1,str2);
%*************************************************************************

%Clear storage
PSMsigsX=[]; RefTimes=[];
chankeyX=''; namesX='';

%*************************************************************************
%Initialize plot headers
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '  casetime=' casetime];
%*************************************************************************

%*************************************************************************
%Proceed to extract data
for nXfile=1:nXfiles     %Start of main extraction loop
  PSMfile=deblank(PSMfiles(nXfile,:));
  CaseCom=str2mat(CaseCom,PSMfile);
  if loadopt==1
    PSMtype='F081'; %keyboard
    fname=[DataPath PSMfile];
    [y,comment,fname,names]=F08read(fname);
    if nXfile==1
      CaseCom=str2mat(CaseCom,comment);
      PSMsigsX=y;
      namesX=names;
      maxpoints=max(size(y));
      tstep=max(y(2:maxpoints,1)-y(1:maxpoints-1,1));
      SampleRate=1/tstep;
    else
      PSMsigsX=[PSMsigsX' y']';
    end
  else
    loadopt
    disp(['LOAD OPTION NOT RECOGNIZED -- processing paused'])
    pause
    return
  end
  if loadopt==1, break, end
end
%Test for empty data array
if isempty(PSMsigsX)
	PSMtype='none';
  disp('In F08load: No signals -- return'), return
end
clear y;
%*************************************************************************  

%*********************************************************************
%Determine signals to keep
if 0 %No code yet for SetExtF08
chankey=names2chans(names);
[MenuName,chansX,chansXok]=SetExtF08(chansXstr,names,chankey,CFname);
if ~chansXok, disp('No menu selected - return'), return, end
str1=['Starting menu = ' MenuName];
CaseCom=str2mat(CaseCom,str1);
if 0  %Display chansX
  nsigs=max(size(chansX));
  str1='chansX='; disp(str1)
  CaseCom=str2mat(CaseCom,str1);
  for n1=1:15:nsigs
    n2=min(n1+15-1,nsigs);
    str1=[' ' num2str(chansX(n1:n2))]; 
    if n1==1, str1(1)='['; end
    if n2==nsigs, str1=[str1 ']']; end
    disp(str1)
    CaseCom=str2mat(CaseCom,str1);
  end
end
%Downsize signal array
if chansX(1)~=1, chansX=[1 chansX]; end
PSMsigsX=PSMsigsX(:,chansX); namesX=namesX(chansX,:);
end
%*********************************************************************

%*************************************************************************  
%Review & clean up F08 data
%disp('In F08load:'); keyboard
%*************************************************************************  

%*************************************************************************
%Logic for signal decimation
simrate=1/tstep;
Nyquist=0.5*simrate;
%*************************************************************************

%*************************************************************************  
%Complete loading process
chankeyX=names2chans(namesX);
PSMreftimes=[];
CFname='F08 Data';
ListName='none';
CaseComR=CaseCom;
%*************************************************************************  

%*************************************************************************
%Optional data save to file
disp(' ')
savesok=promptyn('In F08load: Invoke utility to save extracted signals? ', 'n');
if savesok
  disp('In F08load: Loop for saving data to files:')
  for tries=1:10
    disp(' ')
    SaveFile='';
    SaveList=['PSMtype PSMsigsX tstep namesX chankeyX CaseComR PSMfiles PSMreftimes CFname'];
    PSMsave
    if isempty(SaveFile), break, end
  end
end
%*************************************************************************

disp('Returning from F08load')
disp(' ')
return

%end of PSMT function

