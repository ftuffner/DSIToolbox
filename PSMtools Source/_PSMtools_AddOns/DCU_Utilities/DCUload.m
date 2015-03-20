function [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
   =DCUload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
    loadopt,rmsopt,saveopt,trackX)
% DCUload.m is the main driver for loading signals recorded on a
% PNNL developed Data Capture Unit #2 (DCU2) 	
% 
% DCUload.m is the main driver in the logic that retrieves and 
% restructures PDC data saved as .mat files.
%  [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
%  =DCUload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
%   loadopt,rmsopt,saveopt,trackX);
%
% Special functions used:
%	  promptyn,promptnv
%   PSMsave
%   
% Last modified 02/19/02.  jfh

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

%*************************************************************************
if isempty(PSMfiles)
  disp(['In DCUload: Seeking names for files to load' ])
  for N=1:10
    [filename,pathname]=uigetfile(['*.*'],'Locate file to retrieve:');
    if filename(1)==0|pathname(1)==0
      disp('No file indicated -- done'), break
    end
    if N==1
      DataPath=pathname;
      PDCfiles(N,:)=filename;
	    eval(['cd ' '''' pathname '''']) 
    else PSMfiles=str2mat(PSMfiles,filename); end
  end
end
%*************************************************************************

%*************************************************************************
%Display & document main control parameters
nXfiles=size(PSMfiles,1);
str1=['In DCUload: Load option = ' sprintf('%3.1i',loadopt)];
str2=['In DCUload: Seeking data from ' sprintf('%2.1i',nXfiles) ' files:'];
disp(str1)
disp(str2)
disp(PSMfiles)
CaseCom=str2mat(CaseCom,str1,str2);
%*************************************************************************

%Clear storage
PSMsigsX=[]; RefTimes=[];
chankeyX=''; namesX='';

%*************************************************************************
%Proceed to extract data
PSMtype='DCU1';
for nXfile=1:nXfiles     %Start of main extraction loop
  PSMfile=PSMfiles(nXfile,:);
  CaseCom=str2mat(CaseCom,PSMfile);
  eval(['load ' PSMfile])
  if (loadopt==2)
    if nXfile==1
      PSMtype='DCU2';
      PSMsigsX=double(BinaryData);
      namesX=char(Names);
      clockrate=10000000;
      pulses=round(clockrate/SampleRate);
      SampleRate=clockrate/pulses
      tstep=1/SampleRate
    else PSMsigsX=[PSMsigsX' double(BinaryData)']';
    end
  end
end
%Test for empty data array
if isempty(PSMsigsX)
	PSMtype='none';
  disp('In DCUload: No signals -- return'), return
end
str1=sprintf('In DCUload: tstep      = %6.6f',tstep);
str2=sprintf('In DCUload: SampleRate = %6.6f',SampleRate);
disp(str1)
disp(str2)
CaseCom=str2mat(CaseCom,str1,str2);
%*************************************************************************  

%*************************************************************************
%Logic for signal decimation
decfacX=max(round(decfacX),1);
maxpoints=size(PSMsigsX,1);
EXCOM1=sprintf('In DCUload: Local decimation by decfacX=%4.3i',decfacX);
disp(EXCOM1)
setok=promptyn('Is this ok?', 'y');
if ~setok
	disp('Invoking "keyboard" command - Enter "return" when you are finished')
	keyboard
end
decfacX=max(round(decfacX),1);
if decfacX>1
  PSMsigsX=PSMsigsX(1:decfacX:maxpoints,:);
  maxpoints=size(PSMsigsX,1);
  EXCOM2=sprintf('In DCUload: Decimated maxpoints=%6.0i',maxpoints);
  disp(EXCOM2)
  CaseCom=str2mat(CaseCom,EXCOM1,EXCOM2);
  tstep=tstep*decfacX;
end
%*************************************************************************

%*************************************************************************  
%Complete loading process
maxpoints=size(PSMsigsX,1);
nsigs=size(PSMsigsX,2);
sigscale=ones(1,nsigs)  %Temporary fix
%PSMsigsX=PSMsigsX.*sigscale;
time=[0:maxpoints-1]'*tstep;
PSMsigsX=[time PSMsigsX];
namesX=str2mat('Time',namesX);
chankeyX=names2chans(namesX);
CFname='none';
%*************************************************************************  

disp('Returning from DCUload')
disp(' ')
return

%end of PSM script

