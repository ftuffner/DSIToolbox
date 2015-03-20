 function [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,ListPath,DataPath]...
      =PPSMload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
   
% Read data acquired on a BPA PPSM
%
% [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,ListPath,DataPath]...
%     =PPSMload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
%      loadopt,rmsopt,saveopt,trackX);
%
% NOMENCLATURE WARNINGS:
%   - PPSMsigsX is an array extracted from a BPA PPSM
%   - PSMsigsX  is an array extracted from any PSM (power system monitor)
%   - Hardware channels are numbered [0:N-1]
%   - Signals to extract are numbered [1:N]
%   - Signals extracted are numbered [1:N+1], with time axis at column 1
%
% PSM Tools called from PPSMload:
%	PPSMread
%   SetExtPPSM
%   PSMsave
%   promptyn
%   PSM2Date
%   
% Modified 12/06/02   jfh
% Modified 02/16/04   Henry Huang   PPSM special format. 
% Modified 06/17/04   jfh     
% Modified 10/18/06   Ning Zhou to add macro function

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


global PSMtype CFname PSMfiles PSMreftimes

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

if 0
    keyboard
    save Debug_14
elseif 0
    clear all 
    close all
    clc
    load Debug_14
    funLoadMacro()
    PSMMacro.RunMode=1;  %run macro
%     PSMMacro.RunMode=0;  %record macro
%    PSMMacro.RunMode=-1; %normal orperation
end

if ~exist('CFname'), CFname=''; end
SaveFile='';

chansXstr=chansX;
if ~ischar(chansX)
  chansXstr=['chansX=[' num2str(chansXstr) '];'];
end
eval(chansXstr);

%*************************************************************************
if isempty(PSMfiles)
  disp(['In PPSMload: Seeking PSMfiles to load' ])
  for N=1:10
    [filename,pathname]=uigetfile(['*.*'],'Locate file to retrieve:');
    if filename(1)==0|pathname(1)==0
      disp('No file indicated -- done'), break
    end
    if N==1, DataPath=pathname; PSMfiles=filename;
	    eval(['cd ' '''' pathname '''']) 
    else PSMfiles=str2mat(PSMfiles,filename); end
  end
end
%*************************************************************************

%*************************************************************************
%Display & document main control parameters
nXfiles=size(PSMfiles,1);
% str1=['In PPSMload: Load option = ' sprintf('%3.1i',loadopt)];
if loadopt == 1
    str1=['In PPSMload: Load option = PPSM data'];
elseif loadopt == 2     % PPSM Special data. Henry
    str1=['In PPSMload: Load option = PPSM Spcial data'];
else
    str1=['In PPSMload: Load option not recoganized!!!']; return;
end
str2=['In PPSMload: Seeking data from ' sprintf('%2.1i',nXfiles) ' files:'];
disp(str1); disp(str2)
disp(PSMfiles)
CaseCom=str2mat(CaseCom,str1,str2);
%*************************************************************************

%Clear storage
PSMsigsX=[]; PSMreftimes=[];
chankeyX=''; namesX='';
tstep = 0;      % default to 0 to avoid error when return without menu selected. Henry 

%*************************************************************************
%Initialize plot headers
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '  casetime=' casetime];
%*************************************************************************

%*********************************************************************
%Determine Signals Available & Configuration File (DAS Listing)


disp('   Determine Signals & Configuration File (DAS Listing):')
names='';
%keyboard;
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'PPSMload_PSMsigsX'), PSMMacro.PPSMload_PSMsigsX=NaN; end
if ~isfield(PSMMacro, 'PPSMload_channels'), PSMMacro.PPSMload_channels=NaN; end
if ~isfield(PSMMacro, 'PPSMload_names'), PSMMacro.PPSMload_names=NaN; end
if ~isfield(PSMMacro, 'PPSMload_units'), PSMMacro.PPSMload_units=NaN; end
if ~isfield(PSMMacro, 'PPSMload_delay'), PSMMacro.PPSMload_delay=NaN; end
if ~isfield(PSMMacro, 'PPSMload_DataPath'), PSMMacro.PPSMload_DataPath=NaN; end
if ~isfield(PSMMacro, 'PPSMload_DataNames'), PSMMacro.PPSMload_DataNames=''; end
if ~isfield(PSMMacro, 'PPSMload_PPSMlist'), PSMMacro.PPSMload_PPSMlist=NaN; end
if ~isfield(PSMMacro, 'PPSMload_errmsg'), PSMMacro.PPSMload_errmsg=NaN; end

if (PSMMacro.RunMode<1 || isempty(PSMMacro.PPSMload_DataNames))      % Not in Macro playing mode or selection not defined in a macro
    if loadopt == 1
        [PSMsigsX,channels,names,units,delay,DataPath,DataNames,PPSMlist,errmsg]=...
            PPSMread(DataPath,PSMfiles(1,:),CFname,[],1,1);
    elseif loadopt == 2     % PPSM Special data. Henry
        [PSMsigsX,channels,names,units,delay,DataPath,DataNames,PPSMlist,errmsg]=...
            PPSM_splread(DataPath,PSMfiles(1,:),CFname,[],1,1);
    end
else
    PSMsigsX=PSMMacro.PPSMload_PSMsigsX;
    channels=PSMMacro.PPSMload_channels;
    names=PSMMacro.PPSMload_names;
    units=PSMMacro.PPSMload_units;
    delay=PSMMacro.PPSMload_delay;
    DataPath=PSMMacro.PPSMload_DataPath;
    DataNames=PSMMacro.PPSMload_DataNames;
    PPSMlist=PSMMacro.PPSMload_PPSMlist;
    errmsg=PSMMacro.PPSMload_errmsg;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PPSMload_PSMsigsX=PSMsigsX;
        PSMMacro.PPSMload_channels=channels;
        PSMMacro.PPSMload_names=names;
        PSMMacro.PPSMload_units=units;
        PSMMacro.PPSMload_delay=delay;
        PSMMacro.PPSMload_DataPath=DataPath;
        PSMMacro.PPSMload_DataNames=DataNames;
        PSMMacro.PPSMload_PPSMlist=PPSMlist;
        PSMMacro.PPSMload_errmsg=errmsg;
    else
        PSMMacro.PPSMload_PSMsigsX=NaN;
        PSMMacro.PPSMload_channels=NaN;
        PSMMacro.PPSMload_names=NaN;
        PSMMacro.PPSMload_units=NaN;
        PSMMacro.PPSMload_delay=NaN;
        PSMMacro.PPSMload_DataPath=NaN;
        PSMMacro.PPSMload_DataNames='';
        PSMMacro.PPSMload_PPSMlist=NaN;
        PSMMacro.PPSMload_errmsg=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%---------------------------------------------------
    

if isempty(PPSMlist)&~isempty(names)
  PPSMlist='INTERNAL LISTING';
end
if isempty(PPSMlist)
  disp('In PPSMload: No Configuration File provided -- return'), return
end
[ListPath,ListName]=PSMparse(PPSMlist);
CFname=ListName;  %Configuration file name
%Construct key to available signals
chankey='%   time'; ncols=size(names,1);
chanN=['   ';'  0'];  %Add hardware channel numbers to names
for N=3:ncols
  txt=[sprintf('%3.0i',N-2) '  '];chanN=str2mat(chanN,txt);
end
names=[chanN names];
for N=2:ncols   %Ignore time axis added in PPSMread
  linetxt=['%' (sprintf('%6.3i',N-1)) '  ' names(N,:)];
  chankey=str2mat(chankey,linetxt);
end
%*********************************************************************

%*********************************************************************
%Determine signals to extract
[MenuName,chansX,chansXok,names,chankey]=SetExtPPSM(chansXstr,names,chankey,CFname);
  if ~chansXok, disp('No menu selected - return'), return, end
  str1=['Starting menu = ' MenuName]; %keyboard
  CaseCom=str2mat(CaseCom,str1);
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
%*********************************************************************

%*************************************************************************
%Proceed to extract data
disp('   Extracting signals: Dialog window may open')
PSMtype='PPSM';
ppsmlist=PPSMlist;
if ~isempty(findstr('INTERNAL LISTING',PPSMlist))
  ppsmlist='';
end
for nXfile=1:nXfiles     %Start of main extraction loop
  PSMfile=deblank(PSMfiles(nXfile,:)); %keyboard
  if loadopt == 1
      [NewSigsX,channels,namesX,units,delay,DataPath,DataNames,ppsmlist,pfildat,errmsg]...
          =PPSMread(DataPath,PSMfile,ppsmlist,chansX,decfacX,trackX);
  elseif loadopt == 2       % PPSM Special data. Henry
      [NewSigsX,channels,namesX,units,delay,DataPath,DataNames,ppsmlist,pfildat,errmsg]...
          =PPSM_splread(DataPath,PSMfile,ppsmlist,chansX,decfacX,trackX);
  end
  %namesX, plot(NewSigsX(:,1),NewSigsX(:,2))
  %Test for empty data array
  if isempty(NewSigsX)
    disp(['In PPSMload: No signals for ' PSMfile ' -- return'])
	  PSMtype='none';
    return
  end
  if ~isempty(names) %names may have been adjusted in SetExtPPSM
    namesX=str2mat('Time',names(chansX+1,:)); 
  end 
  reftime=pfildat(1);  %LabVIEW convention is seconds since start of 1904   
  offset=(datenum(1904,1,1,0,0,0)-datenum(1900,1,1,0,0,0));
  offset=offset*(24*60*60);
  PSMreftime=reftime+offset;  %PSM convention is seconds since start of 1900
  S1=['PPSM File Extracted = ' PSMfile];  disp(S1)
  CaseCom=str2mat(CaseCom,S1);
  maxpoints=size(NewSigsX,1); 
  tstep=NewSigsX(2,1)-NewSigsX(1,1); maxtime=(maxpoints-1)*tstep;
  maxtime=(maxpoints-1)*tstep;
  S1=sprintf('Time Step = %10.5f    Max Time = %8.3f', [tstep maxtime]);
  S2=[sprintf('PPSM Reference Time = %10.5f', PSMreftime) ' Seconds'];
  PSMdatestr=PSM2Date(PSMreftime); 
  S3=['PPSM Reference Time = ' PSMdatestr ' GMT Standard'];
  disp(S1); disp(S2); disp(S3)
  CaseCom=str2mat(CaseCom,S1,S2,S3);
  NewSigsX(:,1)=[0:maxpoints-1]'*tstep;
  if nXfile==1
    PSMreftimes=PSMreftime;
    PSMsigsX=NewSigsX;
  else 
    PSMreftimes=[PSMreftimes PSMreftime];
    NewSigsX(:,1)=NewSigsX(:,1)+(PSMreftimes(nXfile)-PSMreftimes(1));
    RefTpts=round((PSMreftimes(nXfile)-PSMreftimes(nXfile-1))/tstep);
    if RefTpts==maxpoints, PSMsigsX=[PSMsigsX',NewSigsX']'; 
    else EndChecks
    end
  end
end     %End of main extraction loop
nfiles=size(PSMfiles,1);
maxpoints=size(PSMsigsX,1); 
maxtime=PSMsigsX(maxpoints,1);
S1=sprintf('In PPSMload: %4.0i Files Extracted:',nfiles);
S2=sprintf('Time axis has been inserted at column 1 of signal array');
S3=sprintf('No decimation during signal extraction');
S4=sprintf('Time Step = %10.5f    Max Time = %8.3f', [tstep maxtime]);
if decfacX>1
  S3=sprintf('Decimation factor= %3.0i',decfacX);
  S4=sprintf('Decimation Time Step = %10.5f    Max Time = %8.3f', [tstep maxtime]);
end
SS=str2mat(' ',S1,S2,S3,S4);
disp(SS)
CaseCom=str2mat(CaseCom,SS);
S1=['Configuration file = ' CFname]; disp(S1)
CaseCom=str2mat(CaseCom,S1,' ');
%************************************************************************

%************************************************************************
disp(['In PPSMload: Size PSMsigsX = ' num2str(size(PSMsigsX))])
%************************************************************************

%************************************************************************
%Define final channel key
[chankeyX]=names2chans(namesX)
%Extend & display case documentation array
CaseCom=str2mat(CaseCom,chankeyX);
%*************************************************************************

disp('Returning from PPSMload')
disp(' ')
return

%end of PSMT utility
