function [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
    =PSMTload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
     loadopt,rmsopt,saveopt,trackX);

% PSMTload.m is the main driver for loading signals already saved
% as .mat files in standard PSMT format
% 
%  [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,...
%      DataPath]...
%    =PSMTload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
%      loadopt,rmsopt,saveopt,trackX);
%
% Special functions used:
%   SetExtPSMT
%   promptyn,promptnv
%   PSMsave
%   
% Modified 05/13/04.  jfh
% Modified 10/18/2006. Ning Zhou to add macro function.

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
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
  disp(['In PSMTload: Seeking names for files to load' ])
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
str1=['In PSMTload: Load option = ' sprintf('%3.1i',loadopt)];
str2=['In PSMTload: Seeking data from ' sprintf('%2.1i',nXfiles) ' files:'];
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
%keyboard;
for nXfile=1:nXfiles     %Start of main extraction loop
  PSMfileN=deblank(char(PSMfiles(nXfile,:)));
% PSMpathN=deblank(char(PSMpaths(nXfile,:)));       % original (ZN)
  PSMpathN=DataPath;                                % modified (ZN 10/18/2006)

  CaseCom=str2mat(CaseCom,PSMfileN);
  disp(['File ' num2str(nXfile) ' is ' PSMfileN ':'])
  if loadopt==1
    PSMtype='PSMT'; %keyboard
    pfname=['''' [PSMpathN PSMfileN] ''''];
    eval(['MS=whos(' '''-file''' ',' pfname ',' '''PSMsigsX''' ');'])
    if isempty(char(MS.name))
      eval(['MS=whos(' '''-file''' ',' pfname ',' '''PSMsigsF''' ');'])
    end 
    if isempty(char(MS.name))
      disp(' ')
      disp('In PSMTload: Indicated file is not in standard PSMT form')
      disp('  Cannot find PSMsigsX or PSMsigsF -- Return')
      disp(' ')
      return 
    end
    PSMsigsX=[];
    disp(['Loading file ' num2str(nXfile) ': ' PSMfileN])
    eval(['load '  pfname ' CaseComR PSMsigsX namesX PSMreftimes tstep'])
    if isempty(PSMsigsX)
      eval(['load '  pfname ' CaseComR PSMsigsF namesX PSMreftimes tstep tstepF'])
      PSMsigsX=PSMsigsF; tstep=tstepF; 
    end
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
      [maxpoints nsigs]=size(Sigs);
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
    CaseCom=str2mat(CaseCom,str1); disp(strs); 
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
[maxpoints nsigs]=size(PSMsigsX);
disp('In PSMTload:');
namesX=names(1:nsigs,:);
%Test for empty data array
if isempty(PSMsigsX)
  PSMtype='none';
  disp('In PSMTload: No signals -- return'), return
end
%*************************************************************************  

%*********************************************************************
%Determine signals to keep
chankey=names2chans(namesX);
MenuName='All signals';
chansX=[1:nsigs]; chansXok=1; %keyboard

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'PSMTload_chansXok'), PSMMacro.PSMTload_chansXok=NaN; end
if ~isfield(PSMMacro, 'PSMTload_chansX'), PSMMacro.PSMTload_chansX=NaN; end
if ~isfield(PSMMacro, 'PSMTload_MenuName'), PSMMacro.PSMTload_MenuName=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMTload_chansXok))      % Not in Macro playing mode or selection not defined in a macro
    [MenuName,chansX,chansXok]=SetExtPSMT(chansXstr,namesX,chankey,CFname);
else
    chansXok=PSMMacro.PSMTload_chansXok;
    chansX=PSMMacro.PSMTload_chansX;
    MenuName=PSMMacro.PSMTload_MenuName;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMTload_chansXok=chansXok;
        PSMMacro.PSMTload_chansX=chansX;
        PSMMacro.PSMTload_MenuName=MenuName;
    else
        PSMMacro.PSMTload_chansXok=NaN;
        PSMMacro.PSMTload_chansX=NaN;
        PSMMacro.PSMTload_MenuName=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%[MenuName,chansX,chansXok]=SetExtPSMT(chansXstr,namesX,chankey,CFname);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


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
%Downsize signal array
if chansX(1)~=1, chansX=[1 chansX]; end
PSMsigsX=PSMsigsX(:,chansX); namesX=namesX(chansX,:);
%*********************************************************************

%*************************************************************************  
%Review & clean up data
if 0  %Start of supressed logic
time=PSMsigsX(:,1);
maxpoints=size(PSMsigsX,1);  %keyboard
while time(maxpoints)==time(maxpoints-1)
  maxpoints=maxpoints-1;
end
PSMsigsX=PSMsigsX(1:maxpoints,:);
time=PSMsigsX(:,1);
tsteps=time(2:maxpoints)-time(1:maxpoints-1);
swlocs=find(time(1:maxpoints-1)==time(2:maxpoints));
if ~isempty(swlocs)
  h=figure;
  plot(tsteps)
  Ptitle{1}='Checking time steps';
  title(Ptitle)
  xlabel('Time in Samples')
  ylabel('Time Steps')
end
n1=3; if ~isempty(swlocs), n1=max(swlocs)+3; end
tstep=max(tsteps(n1:maxpoints-3)); SampleRate=1/tstep;  %Use these values!
N=min(find(time>0));  %Trim off initial half-steps
while tsteps(N)>0.9*tstep
  N=N-1;
  if N==0, break, end
end
startpoint=N+1;
N=maxpoints-1;  %Trim off final half-steps
while tsteps(N)<0.9*tstep
  N=N-1;
end
maxpoints=N;
PSMsigsX=PSMsigsX(startpoint:maxpoints,:);
maxpoints=size(PSMsigsX,1);
time=PSMsigsX(:,1);
swlocs=find(time(1:maxpoints-1)==time(2:maxpoints));
tst1=0.5*tstep; tst2=0.5*tstep;
keeploc=1;
for N=2:maxpoints-1
  tvalN=time(N);
  stepN=time(N+1)-tvalN;
  swstep=min(abs(tvalN-time(swlocs)));
  keep=stepN>tst1;
  if ~isempty(swstep)
    keep=(keep&abs(swstep)>tst2)|swstep==0;
  end
  %disp([N tvalN swstep keep])
  if keep, keeploc=[keeploc N]; end
  %if ~keep, disp([N tvalN swstep]), end
end
keeploc=keeploc(find(keeploc<maxpoints));
keeploc=[keeploc maxpoints];
PSMsigsX=PSMsigsX(keeploc,:);
end %End of supressed logic

%disp('In PSMTload:'), keyboard
time=PSMsigsX(:,1);
maxpoints=size(PSMsigsX,1);
tsteps=time(2:maxpoints)-time(1:maxpoints-1);
swlocs=find(time(1:maxpoints-1)==time(2:maxpoints));
strs='In PSMTload: Characteristics of extracted data';
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
  rawdecimate=promptyn('In PSMTload: Decimate raw data?',deftag);
  if rawdecimate
    disp(sprintf('In PSMTload: Decimation factor =%4.0i',decfacX))
    setok=promptyn('   Is this decimation factor ok? ', 'y');
    if ~setok
      decfacX=promptnv('   Enter new decimation factor: ',decfacX);
	    decfacX=max(fix(decfacX),1);
    end
    PSMsigsX=PSMsigsX(1:decfacX:maxpoints,:);
    maxpoints=size(PSMsigsX,1);
	  tstep=tstep*decfacX;
    strs=['In PSMTload: Decimation factor = ' num2str(decfacX)];
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
CFname='PSMT data';
ListName='none';
%*************************************************************************  

disp('Returning from PSMTload')
disp(' ')
return

%end of PSMT function

