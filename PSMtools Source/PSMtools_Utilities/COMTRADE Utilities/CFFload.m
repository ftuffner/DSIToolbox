function [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
    =CFFload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
     loadopt,rmsopt,saveopt,trackX)
% CFFload.m is the main driver for loading signals output in single-file
% COMTRADE format (*.cff)
% 
%  [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,...
%      DataPath]...
%    =CFFload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
%      loadopt,rmsopt,saveopt,trackX);
%
% Special functions used:
%   promptyn,promptnv
%   PSMsave
%   
% Created from PSMTLoad.m by Frank Tuffner, 12/09/2013
% Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

global PSMtype CFname PSMfiles PSMpaths PSMreftimes

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

if ~exist('CFname'), CFname=''; end
SaveFile='';

chansXstr=chansX;
if ~ischar(chansX)
  chansXstr=['chansX=[' num2str(chansXstr) '];'];
end
eval(chansXstr);

%*************************************************************************
if isempty(PSMfiles)
  disp(['In CFFload: Seeking names for files to load' ])
  for N=1:10
    [filename,pathname]=uigetfile(['*.mat'],'Locate file to retrieve:');
    if filename(1)==0|pathname(1)==0
      disp('No file indicated -- done'), break
    end
    filename=char(filename); pathname=char(pathname);
    if N==1
	    eval(['cd ' '''' pathname ''''])
      DataPath=pathname;  %Used??
      PDCfiles(N,:)=filename;
      PSMpaths(N,:)=pathname;
    else 
      PSMfiles=str2mat(PSMfiles,filename);
      PSMpaths=str2mat(PSMpaths,pathname); 
    end
    disp('Files already selected:'); disp(PSMfiles)
  end
end
%*************************************************************************

if ~isempty(DataPath)
  DataPath=deblank(DataPath); L=size(DataPath,2);
  if ~strcmp(DataPath(L),'\'), DataPath=[DataPath '\']; end
end

%*************************************************************************
%Display & document main control parameters
nXfiles=size(PSMfiles,1);
str1=['In CFFload: Load option = ' sprintf('%3.1i',loadopt)];
str2=['In CFFload: Seeking data from ' sprintf('%2.1i',nXfiles) ' files:'];
disp(str1); disp(str2)
disp(PSMfiles)
CaseCom=str2mat(CaseCom,str1,str2);
%*************************************************************************

%Clear storage
PSMsigsX=[]; RefTimes=[];
chankeyX=''; namesX='';
chansXok=0;
MenuName='';

%*************************************************************************
%Initialize plot headers
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '  casetime=' casetime];
%*************************************************************************


%Macro items
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'CFFload_chansXok'), PSMMacro.CFFload_chansXok=NaN; end
if ~isfield(PSMMacro, 'CFFload_chansX'), PSMMacro.CFFload_chansX=NaN; end
if ~isfield(PSMMacro, 'CFFload_MenuName'), PSMMacro.CFFload_MenuName=NaN; end
if ~(PSMMacro.RunMode<1 || isnan(PSMMacro.CFFload_chansXok))      % Not in Macro playing mode or selection not defined in a macro
    chansXok=PSMMacro.CFFload_chansXok;
    chansX=PSMMacro.CFFload_chansX;
    MenuName=PSMMacro.CFFload_MenuName;
end
%End macro reading section

%*************************************************************************
%Proceed to extract data
%keyboard;
for nXfile=1:nXfiles     %Start of main extraction loop
  PSMfileN=deblank(char(PSMfiles(nXfile,:)));
% PSMpathN=deblank(char(PSMpaths(nXfile,:)));       % original (ZN)
  PSMpathN=DataPath;                                % modified (ZN 10/18/2006)

  CaseCom=str2mat(CaseCom,PSMfileN);
  disp(['File ' num2str(nXfile) ' is ' PSMfileN ':'])
  if loadopt==1
    PSMtype='CFF'; %keyboard
    pfname=[PSMpathN PSMfileN];
    disp(['Loading file ' num2str(nXfile) ': ' PSMfileN])
    
    %Read data
    [CaseComR,PSMreftimes,chankeyX,namesX,PSMsigsX,chansX,chansXok,MenuName,tstep]=funReadCFF(pfname,chansX,CFname,nXfile,chansXok,MenuName);
    
    if ~exist('CaseComR'),CaseComR='[No comments retrieved]'; end
    if ~exist('PSMreftimes'),PSMreftimes=[]; end
    if isempty(PSMreftimes),PSMreftimes=0; end
    CaseCom=str2mat(CaseCom,CaseComR);
    if tstep==0, tstep=tstepF; end
    if isempty(findstr('time',lower(namesX(1,:))))
      disp(['No time axis indicated in namesX: first name = ' namesX(1,:)])
      disp(['Constructing time axis using tstep = ' num2str(tstep)])
      maxpts=size(PSMsigsX,1);
      time=[0:maxpts-1]'*tstep(1);
      PSMsigsX=[time PSMsigsX];
      namesX=str2mat('Time',namesX);
      chankeyX=names2chans(namesX);
    end
    if abs(PSMsigsX(1,1))<tstep/10, PSMsigsX(1,1)=0; end
    time=PSMsigsX(:,1); maxpts=length(time);
    tspan=[time(1) time(maxpts)];
    StartTime=PSMreftimes(1)+tspan(1);
    EndTime  =PSMreftimes(1)+tspan(2);
    PSMsigsX(:,1)=PSMreftimes(1)+time;
    
    if nXfile==1
      Sigs=PSMsigsX;
      names=namesX;
      RefTimesR=PSMreftimes(1);
      tsteps=tstep;
      [maxpoints,nsigs]=size(Sigs);
      tstepMax=max(Sigs(2:maxpoints,1)-Sigs(1:maxpoints-1,1));
      SampleRate=round(1/tstep); tstep=1/SampleRate;
      TspanR=tspan;
      StartTimesR=StartTime;
      EndTimesR=EndTime;
    else 
      Sigs=[Sigs' PSMsigsX']';
      names=str2mat(names,namesX); %Diagnostic information
      RefTimesR=[RefTimesR; PSMreftimes(1)];
      tsteps=[tsteps' tstep']';
      TspanR=[TspanR' tspan']';
      StartTimesR=[StartTimesR' StartTime']';
      EndTimesR=[EndTimesR' EndTime']';
    end
    strs=['  Start time = ' PSM2Date(StartTime)];
    strs=str2mat(strs,['  End time   = ' PSM2Date(EndTime)]);
    CaseCom=str2mat(CaseCom,strs); disp(strs); 
  else
    loadopt
    disp(['LOAD OPTION NOT RECOGNIZED -- processing paused'])
    pause
    return
  end
  %if loadopt==1, break, end
end
PSMreftimes=RefTimesR;
PSMsigsX=Sigs; %clear Sigs;
PSMsigsX(:,1)=PSMsigsX(:,1)-RefTimesR(1); 
[~,nsigs]=size(PSMsigsX);
disp('In CFFload:');
namesX=names(1:nsigs,:);
%Test for empty data array
if isempty(PSMsigsX)
  PSMtype='none';
  disp('In PSMTload: No signals -- return'), return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Macro record portion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.CFFload_chansXok=chansXok;
        PSMMacro.CFFload_chansX=chansX;
        PSMMacro.CFFload_MenuName=MenuName;
    else
        PSMMacro.CFFload_chansXok=NaN;
        PSMMacro.CFFload_chansX=NaN;
        PSMMacro.CFFload_MenuName=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end macro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~chansXok, disp('No menu selected - return'), return, end
str1=['Starting menu = ' MenuName];
CaseCom=str2mat(CaseCom,str1);
if 0  %Display chansX
  nsigs=length(chansX);
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
%*********************************************************************

%*************************************************************************  
%Review & clean up data


%disp('In PSMTload:'), keyboard
time=PSMsigsX(:,1);
maxpoints=size(PSMsigsX,1);
tsteps=time(2:maxpoints)-time(1:maxpoints-1);
swlocs=find(time(1:maxpoints-1)==time(2:maxpoints));
strs='In CFFload: Characteristics of extracted data';
strs=str2mat(strs,['  tstep      = ' num2str(tstep)]);
strs=str2mat(strs,['  SampleRate = ' num2str(SampleRate)]);
if ~isempty(swlocs)
  strs=str2mat(strs,['  Time axis indicates ' num2str(length(swlocs)) ' switching times']);
  swtimes=time(swlocs);
  for nsw=1:length(swlocs)
    strs=str2mat(strs,['    Switch time ' num2str(nsw) ' = ' num2str(swtimes(nsw))]);
  end
end
CTlocs=find(tsteps~=0);
tstepmin=min(tsteps(CTlocs)); tstepmax=max(tsteps(CTlocs));
if abs(tstepmin-tstepmax)>tstepmax*0.01
  strs=str2mat(strs,['  Irregular time steps:']);
  strs=str2mat(strs,['    Minimum tstep = ' num2str(tstepmin)]);
  strs=str2mat(strs,['    Maximum tstep = ' num2str(tstepmax)]);
  h=figure;
  plot(time)
  Ptitle{1}='Irregular time steps';
  title(Ptitle)
  xlabel('Time in Samples')
  ylabel('Time in seconds')
  h=figure;
  plot(tsteps)
  Ptitle{1}='Irregular time steps';
  title(Ptitle)
  xlabel('Time in Samples')
  ylabel('Time Steps')
end
disp(strs)
CaseCom=str2mat(CaseCom,strs);
%*************************************************************************  

%*************************************************************************
%Logic for signal decimation
decfacX=max(fix(decfacX),1);
maxpoints=size(PSMsigsX,1);
deftag='n'; if decfacX>1, deftag=''; end
if decfacX>1
  rawdecimate=promptyn('In CFFload: Decimate raw data?',deftag);
  if rawdecimate
    disp(sprintf('In CFFload: Decimation factor =%4.0i',decfacX))
    setok=promptyn('   Is this decimation factor ok? ', 'y');
    if ~setok
      decfacX=promptnv('   Enter new decimation factor: ',decfacX);
	    decfacX=max(fix(decfacX),1);
    end
    PSMsigsX=PSMsigsX(1:decfacX:maxpoints,:);
    maxpoints=size(PSMsigsX,1);
	  tstep=tstep*decfacX;
    strs=['In CFFload: Decimation factor = ' num2str(decfacX)];
    strs=str2mat(strs,['   Decimated maxpoints = ' num2str(maxpoints)]);
    disp(strs)
    CaseCom=str2mat(CaseCom,strs);
  end
end
simrate=1/tstep;
Nyquist=0.5*simrate;
%*************************************************************************

%*************************************************************************  
%Complete loading process
chankeyX=names2chans(namesX);
CFname='CFF data';
ListName='none';
%*************************************************************************  

disp('Returning from CFFload')
disp(' ')
return

%end of PSMT function

