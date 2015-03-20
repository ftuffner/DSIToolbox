function [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
    =SQLload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
     loadopt,rmsopt,saveopt,trackX)
% SQLload.m is the main driver for loading signals from an SQL
% database into the DSI toolbox.  Note that all appropriate
% configurations must have occurred, otherwise this won't work.
% 
%  [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,...
%      DataPath]...
%    =SQLload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
%      loadopt,rmsopt,saveopt,trackX);
%
% Special functions used:
%   promptyn,promptnv
%   PSMsave
%   
% Adapted from SQLload.m March 3, 2014 by Frank Tuffner
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

%*************************************************************************
%Display & document main control parameters
str2=['In SQLload: Seeking data from database files:'];
disp(str2)
disp(PSMfiles)
CaseCom=str2mat(CaseCom,str2);
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
if ~isfield(PSMMacro, 'SQLload_chansXok'), PSMMacro.SQLload_chansXok=NaN; end
if ~isfield(PSMMacro, 'SQLload_chansX'), PSMMacro.SQLload_chansX=NaN; end
if ~isfield(PSMMacro, 'SQLload_MenuName'), PSMMacro.SQLload_MenuName=NaN; end
if ~(PSMMacro.RunMode<1 || isnan(PSMMacro.SQLload_chansXok))      % Not in Macro playing mode or selection not defined in a macro
    chansXok=PSMMacro.SQLload_chansXok;
    chansX=PSMMacro.SQLload_chansX;
    MenuName=PSMMacro.SQLload_MenuName;
end
%End macro reading section

%*************************************************************************
%Proceed to extract data
%keyboard;


PSMtype='SQL'; %keyboard
disp('Loading file database using parameters in SQL_Config.cfg')

%Read data
[CaseComR,PSMreftimes,chankeyX,namesX,PSMsigsX,chansX,chansXok,tstep]=funReadSQL;

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

strs=['  Start time = ' PSM2Date(StartTime)];
strs=str2mat(strs,['  End time   = ' PSM2Date(EndTime)]);
CaseCom=str2mat(CaseCom,strs); disp(strs); 

PSMreftimes=RefTimesR;
PSMsigsX=Sigs; %clear Sigs;
PSMsigsX(:,1)=PSMsigsX(:,1)-RefTimesR(1); 
[~,nsigs]=size(PSMsigsX);
disp('In SQLload:');
namesX=names(1:nsigs,:);
%Test for empty data array
if isempty(PSMsigsX)
  PSMtype='none';
  disp('In SQLload: No signals -- return'), return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Macro record portion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SQLload_chansXok=chansXok;
        PSMMacro.SQLload_chansX=chansX;
        PSMMacro.SQLload_MenuName=MenuName;
    else
        PSMMacro.SQLload_chansXok=NaN;
        PSMMacro.SQLload_chansX=NaN;
        PSMMacro.SQLload_MenuName=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end macro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~chansXok, disp('No menu selected - return'), return, end
str1=['Starting menu = ' MenuName];
CaseCom=str2mat(CaseCom,str1);
%*********************************************************************

%*************************************************************************  
%Review & clean up data


%disp('In PSMTload:'), keyboard
time=PSMsigsX(:,1);
maxpoints=size(PSMsigsX,1);
tsteps=time(2:maxpoints)-time(1:maxpoints-1);
swlocs=find(time(1:maxpoints-1)==time(2:maxpoints));
strs='In SQLload: Characteristics of extracted data';
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
  rawdecimate=promptyn('In SQLload: Decimate raw data?',deftag);
  if rawdecimate
    disp(sprintf('In SQLload: Decimation factor =%4.0i',decfacX))
    setok=promptyn('   Is this decimation factor ok? ', 'y');
    if ~setok
      decfacX=promptnv('   Enter new decimation factor: ',decfacX);
	    decfacX=max(fix(decfacX),1);
    end
    PSMsigsX=PSMsigsX(1:decfacX:maxpoints,:);
    maxpoints=size(PSMsigsX,1);
	  tstep=tstep*decfacX;
    strs=['In SQLload: Decimation factor = ' num2str(decfacX)];
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
CFname='SQL data';
ListName='none';
%*************************************************************************  

disp('Returning from SQLload')
disp(' ')
return

%end of PSMT function

