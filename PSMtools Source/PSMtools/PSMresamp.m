function [CaseCom,namesX,PSMsigsRS,tstartRS,tstepRS,upsfac,decfac]...
     =PSMresamp(caseID,casetime,CaseCom,namesX,PSMsigsX,...
      tstart,tstep,upsfac,decfac);
% Resampling & repair of PSM signal records 
% Repeat points (switching times for simulation cases) are retained
% Missing points will be filled in if their locations fit original sampling
% WARNING: this code does not cure all possible record defects!!
% 
%  [CaseCom,namesX,PSMsigsRS,tstepRS,upsfac,decfac]...
%    =PSMresamp(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%     tstep,upsfac,decfac);
%
%  INPUTS:
%    caseID       name for present case
%    casetime     time when present case was initiated
%    CaseCom      case comments
%    namesX       signal names
%    PSMsigsX     signal data to be processed
%    tstart       nominal time for start of resampling process
%    tstep        time step for PSMsigsX
%    upsfac		    upsampling factor (integer)
%    decfac		    decimation factor (intgeger)
%
%  OUTPUTS:
%    PSMsigsRS    resampled signal data
%    tstartRS     actual time for start of resampling process
%    tstepRS      time step after resampling
%
% PSMT functions called from PSMresamp:
%   PSMupsamp (enclosed)
%   PSMretime (enclosed)
%   promptyn 
%
% NOTE: tstart logic not provided yet!!
%
% Last modified 05/27/04.   jfh
% Last Modified 10/20/2006  by Ning Zhou to add Macro function

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%

%Clear outputs

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

PSMsigsRS=[]; tstartRS=[]; tstepRS=[];
PSMsigsRS=PSMsigsX;

disp('In PSMresamp:'); %keyboard

if isempty(tstart), tstart=PSMsigsX(1,1); end
if isempty(tstep),  tstep=PSMsigsX(2,1)-PSMsigsX(1,1); end
upsfac=max(fix(upsfac),1); 
decfac=max(fix(decfac),1);
str1=['In PSMresamp: upsfac = ' num2str(upsfac) '  decfac = ' num2str(decfac)];
str2=[' tstep  = ' num2str(tstep) '  Size of input array = ' num2str(size(PSMsigsX))];
str3=[' tstart = ' num2str(tstart)];
strs=str2mat(str1,str2,str3);
CaseCom=str2mat(CaseCom,strs); disp(strs)

tstart0 =tstart;
tstartRS=tstart;
tstepUS=tstep/upsfac; tstepDS=tstepUS/decfac; tstepRS=tstepDS; 

%*************************************************************************
%Test for repeat points (usually .SWX switching times)
time=PSMsigsX(:,1); [maxpoints nsigs]=size(PSMsigsX);
tsteps=time(2:maxpoints)-time(1:maxpoints-1);
eps=0.001*tstep;
swlocs=find(abs(time(1:maxpoints-1)-time(2:maxpoints))<eps)';
swtimes=time(swlocs);
if ~isempty(swlocs)
  h=figure; plot(tsteps)
  Ptitle{1}='Checking SWX time steps';
  title(Ptitle)
  xlabel('Time in Samples')
  ylabel('Time Steps')
  if size(swlocs,1)>1, swlocs=swlocs'; end
  strs=['In PSMresamp: Number of switching times = ' num2str(length(swlocs))];
  strs=str2mat(strs,'  Switching times are');
  for n=1:length(swlocs)
    strs=str2mat(strs,['    Switch time ' num2str(n) ' = ' sprintf('%3.6f',swtimes(n))]);
  end
  disp(strs) 
end

if PSMMacro.RunMode<1  
    keybdok=promptyn('In PSMresamp: Do you want the keyboard? ', '');
    if keybdok
      disp('In PSMresamp: Invoking "keyboard" command - Enter "return" when you are finished')
      keyboard
    end
end
%*************************************************************************

%*************************************************************************
%Establish smooth time base for internal calculations
%Check smoothness of time axis (except spacing of repeated points)
timeN=time; tstepsN=tsteps;
tstepsA=tsteps(find(tsteps>0)); Nsteps=length(tstepsA);
Lmax=find(tstepsA==max(tstepsA)); Lmax=Lmax(1); 
Lmin=find(tstepsA==min(tstepsA)); Lmin=Lmin(1);
maxfrac=tstepsA(Lmax)/tstep; minfrac=tstepsA(Lmin)/tstep;
str1=['In PSMresamp:'];
str2=['  Maximum time step =' sprintf('%1.3f',maxfrac) '  of standard'];
str2=[str2 ' at time= ' sprintf('%4.4f',time(Lmax))];
str3=['  Minimum time step =' sprintf('%1.3f',minfrac) '  of standard'];
str3=[str3 ' at time= ' sprintf('%4.4f',time(Lmin))];
strs=str2mat(str1,str2,str3); disp(strs)

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06

if ~isfield(PSMMacro, 'PSMresamp_CheckTimeok'), PSMMacro.PSMresamp_CheckTimeok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMresamp_CheckTimeok))      % Not in Macro playing mode or selection not defined in a macro
    CheckTimeok=promptyn('In PSMresamp: Check uniformity of time axis? ', '');
else
    CheckTimeok=PSMMacro.PSMresamp_CheckTimeok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMresamp_CheckTimeok=CheckTimeok;
    else
        PSMMacro.PSMresamp_CheckTimeok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% CheckTimeok=promptyn('In PSMresamp: Check uniformity of time axis? ', '');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if CheckTimeok
  timeA=PSMretime(time,swlocs,tstep); 
  timeError=(time-timeA)/tstep; %plot(timeError)
  absTerror=abs(timeError); maxTerror=max(absTerror);
  Lmax=find(absTerror==maxTerror); Lmax=Lmax(1); 
  str1=['  Maximum time error =' sprintf('%1.3f',maxTerror) '  X tstep'];
  str1=[str1 ' at time= ' sprintf('%4.4f',time(Lmax))];
  disp(str1)
  roughness=max(abs(maxfrac-1),abs(minfrac-1));
  smoothdef=0.001;
  roughtime=roughness>smoothdef;
  roughtime=roughtime|maxTerror>smoothdef;
  timeN=timeA;
  if roughtime
    str1=['In PSMresamp: Time axis not uniform']; disp(str1)
    figure; plot(timeA,timeError)
    Ptitle{1}='Time Error (normalized on nominal tstep)';
    title(Ptitle)
    xlabel('Uniformed Time')
    ylabel('Time Error')
  end
  tstepsN=timeN(2:maxpoints)-timeN(1:maxpoints-1);
  str1=['In PSMresamp: Time axis has been smoothed for internal calculations'];
  disp(str1)
  prompt='Export smoothed time axis in final results? ';

    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06

    if ~isfield(PSMMacro, 'PSMresamp_keepsmooth'), PSMMacro.PSMresamp_keepsmooth=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMresamp_keepsmooth))      % Not in Macro playing mode or selection not defined in a macro
        keepsmooth=promptyn(prompt,'y');
    else
        keepsmooth=PSMMacro.PSMresamp_keepsmooth;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMresamp_keepsmooth=keepsmooth;
        else
            PSMMacro.PSMresamp_keepsmooth=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %  keepsmooth=promptyn(prompt,'y');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
 
  
  if keepsmooth
    PSMsigsX(:,1)=timeN;
    str1='In PSMresamp: Smoothed time axis included in final results';
    disp(str1); CaseCom=str2mat(CaseCom,str1);  
  end  
  PSMsigsRS=PSMsigsX;
end

if PSMMacro.RunMode<1  
    keybdok=promptyn('In PSMresamp: Do you want the keyboard? ', 'n');
    if keybdok
      disp('In PSMresamp: Invoking "keyboard" command - Enter "return" when you are finished')
      keyboard
    end
end
%*************************************************************************

%*************************************************************************
%Shift tstart to accommodate switching times
%[NEED CODE HERE] 
%*************************************************************************

%*************************************************************************
%Upsampling plus decimation - process by signal points
%Upsample via linear interpolation between adjacent time points
%Decimate each upsampled signal as it is produced
if upsfac>1&decfac>1
  disp(['In PSMresamp: Upsampling by factor of upsfac = ' num2str(upsfac)]);
  disp(['In PSMresamp: decimating by factor of decfac = ' num2str(decfac)]);
  time=timeN; tsteps=tstepsN; %Use smoothed time axis
  tstepUS=tstep/upsfac; tstepDS=tstepUS/decfac; tstepRS=tstepDS; 
  %Upsample time axis
  [timeUS,tstepUS]...
    =PSMupsamp(time,time,tsteps,swlocs,...
     tstart,tstep,upsfac);
  maxptsUS=length(timeUS);
  tstepsUS=timeUS(2:maxptsUS)-timeUS(1:maxptsUS-1);
  %Determine decimation integers
  if isempty(swlocs)
    locsD=1:decfac:maxptsUS; %Uniformly decimated
  else
    eps=0.001*tstepUS;
    swlocsUS=find(abs(timeUS(1:maxptsUS-1)-timeUS(2:maxptsUS))<eps)';
    locsA=find(abs(tstepsUS-tstepUS)<eps);
    locsA=[locsA' maxptsUS]';
    locsD1=1:decfac:length(locsA); %Uniformly decimated
    locsD=locsA(locsD1); %figure, plot(timeUS(locsD))
    locsD=[locsD' swlocsUS];
    locsD=sort(locsD);
  end
  PSMsigsRS=[]; 
  for N=1:nsigs %To avoid excessive storage
    [sigUS,tstepUS]...
      =PSMupsamp(PSMsigsX(:,N),time,tsteps,swlocs,...
       tstart,tstep,upsfac);
    sigRS=sigUS(locsD);
    PSMsigsRS=[PSMsigsRS sigRS];
  end
  %figure, plot(PSMsigsUS(:,1))
  timeRS=PSMsigsRS(:,1); [maxptsRS nsigs]=size(PSMsigsRS);
  figure; plot(time,PSMsigsX(:,2),timeRS,PSMsigsRS(:,2))
  title('Original vs. resampled signal'); xlabel('Time in Seconds')
  tstepsRS=timeRS(2:maxptsRS)-timeRS(1:maxptsRS-1);
  eps=0.001*tstepRS;
  swlocsRS=find(abs(timeRS(1:maxptsRS-1)-timeRS(2:maxptsRS))<eps)';
  swtimesRS=timeRS(swlocsRS); numsw=length(swlocsRS);
  disp(['In PSMresamp: Size of resampled array = ' num2str(size(PSMsigsRS))])
  strs=['In PSMresamp: Number of switching times in resampled array = ' num2str(numsw)];
  if numsw>0
    strs=str2mat(strs,'  Switching times are');
    for n=1:length(swlocsRS)
      strs=str2mat(strs,['   ' sprintf('%3.6f',swtimesRS(n))]); 
    end
  end
  disp(strs) 
  keybdok=promptyn('In PSMresamp: Do you want the keyboard? ', 'n');
  if keybdok
    disp('In PSMresamp: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
  return
end %End of resampling logic
%*************************************************************************

%*************************************************************************
%Upsampling only - process by signal vectors
%Upsample via linear interpolation between adjacent time points
if upsfac>1&decfac<=1
  disp(['In PSMresamp: Upsampling by factor of upsfac = ' num2str(upsfac)]);
  time=timeN; tsteps=tstepsN; %Use smoothed time axis
  [PSMsigsUS,tstepUS]...
     =PSMupsamp(PSMsigsX,time,tsteps,swlocs,...
      tstart,tstep,upsfac);
  %figure, plot(PSMsigsUS(:,1))
  timeUS=PSMsigsUS(:,1); [maxptsUS nsigs]=size(PSMsigsUS);
  figure; plot(time,PSMsigsX(:,3),timeUS,PSMsigsUS(:,3))
  title('Original vs. upsampled signal'); xlabel('Time in Seconds')
  tstepsUS=timeUS(2:maxptsUS)-timeUS(1:maxptsUS-1);
  eps=0.001*tstepUS;
  swlocsUS=find(abs(timeUS(1:maxptsUS-1)-timeUS(2:maxptsUS))<eps)';
  swtimesUS=timeUS(swlocsUS);
  disp(['In PSMresamp: Size of upsampled array = ' num2str(size(PSMsigsUS))])
  strs=['In PSMresamp: Number of switching times in upsampled array = ' num2str(length(swlocsUS))];
  strs=str2mat(strs,'  Switching times are');
  for n=1:length(swlocsUS)
    strs=str2mat(strs,['   ' sprintf('%3.6f',swtimesUS(n))]); 
  end
  disp(strs) 
  keybdok=promptyn('In PSMresamp: Do you want the keyboard? ', 'n');
  if keybdok
    disp('In PSMresamp: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
  PSMsigsRS=PSMsigsUS; tstepRS=tstepUS;
  return
end %End of upsampling logic
%*************************************************************************

%*************************************************************************
%Decimation only - process by signal vectors
if upsfac<=1&decfac>1
  disp(['In PSMresamp: decimating by factor of decfac = ' num2str(decfac)]);
  time=timeN; tsteps=tstepsN; %Use smoothed time axis
  tstepDS=tstep*decfac;
  if isempty(swlocs)
    PSMsigsRS=PSMsigsX(1:decfac:maxpoints,:); tstepRS=tstepDS;
    disp(['In PSMresamp: Size of decimated array = ' num2str(size(PSMsigsRS))])
    return
  end
  eps=0.001*tstep;
  locsA=find(abs(tsteps-tstep)<eps);
  locsA=[locsA' maxpoints]';
  locsD1=1:decfac:length(locsA); %Uniformly decimated
  locsD=locsA(locsD1);
  locsD=[locsD' swlocs];
  locsD=sort(locsD);
  %figure; timeD=time(locsD); plot(timeD)
  maxptsD=length(locsD);
  dblpts=find(locsD(1:maxptsD-1)==locsD(2:maxptsD));
  if ~isempty(dblpts)
    disp('In PSMresamp: Problem - double points after decimation') 
    disp('In PSMresamp: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
% keyboard
  PSMsigsDS=PSMsigsX(locsD,:); %figure, plot(PSMsigsDS(:,1))
  timeDS=PSMsigsDS(:,1); [maxptsDS nsigs]=size(PSMsigsDS);
  if nsigs>=3
      figure; plot(time,PSMsigsX(:,3),timeDS,PSMsigsDS(:,3))
      title('Original vs. decimated signal'); xlabel('Time in Seconds')
  end
  tstepsDS=timeDS(2:maxptsDS)-timeDS(1:maxptsDS-1);
  eps=0.001*tstepDS;
  swlocsDS=find(abs(timeDS(1:maxptsDS-1)-timeDS(2:maxptsDS))<eps)';
  swtimesDS=timeUS(swlocsDS);
  disp(['In PSMresamp: Size of decimated array = ' num2str(size(PSMsigsDS))])
  strs=['In PSMresamp: Number of switching times in decimated array = ' num2str(length(swlocsDS))];
  strs=str2mat(strs,'  Switching times are');
  for n=1:length(swlocsDS)
    strs=str2mat(strs,['   ' sprintf('%3.6f',swtimesDS(n))]); 
  end
  disp(strs) 
   keybdok=promptyn('In PSMresamp: Do you want the keyboard? ', 'n');
  if keybdok
    disp('In PSMresamp: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
  PSMsigsRS=PSMsigsDS; tstepRS=tstepDS;
  return
end %End of decimation logic
%*************************************************************************

return
%end of PSMT function

%-------------------------------------------------------------------------
%Subfunction for PSMresamp
function [sigsUS,tstepUS]...
     =PSMupsamp(sigsX,time,tsteps,swlocs,...
      tstart,tstep,upsfac);
%
[maxpoints nsigs]=size(sigsX);
tstepUS=tstep/upsfac; 
LX=[1 swlocs maxpoints]; Nspans=length(LX)-1;
sigsUS=[]; 
for N=1:Nspans
  M1=LX(N); M2=LX(N+1)-1;
  for m=M1:M2
    vec1=sigsX(m,:); vec2=sigsX(m+1,:);
    tstepM=time(m+1)-time(m);
    if tstepM<=0  %Switch time
      sigsUS=[sigsUS vec2'];
    else  
      Npts=round(tstepM/tstepUS);
      pts=[0:Npts]'; w2=pts/(Npts); w1=1-w2;
      patch=zeros(nsigs,Npts);
      patch=[w1*vec1+w2*vec2]'; %figure; plot([vec1(1) patch(1,:) vec2(1)])
      sigsUS=[sigsUS patch(:,1:Npts)];
    end
  end
end
sigsUS=sigsUS';
return

%end of PSMT subfunction

%-------------------------------------------------------------------------
%Subfunction for PSMresamp
function [timeRT]=PSMretime(time,swlocs,tstep);
%
maxpoints=length(time);
LX=[1 swlocs maxpoints]; Nspans=length(LX)-1;
time0=time-time(1); 
tsteps0=time0(2:maxpoints)-time0(1:maxpoints-1);
eps=0.001*tstep;
locs=find(abs(tsteps0-tstep)<eps);
tsteps0(locs)=tstep; 
time0=zeros(maxpoints,1);
for m=1:maxpoints-1, time0(m+1)=time0(m)+tsteps0(m); end
tsteps0=time0(2:maxpoints)-time0(1:maxpoints-1);
timeRT=[];
for N=1:Nspans
  M1=LX(N); M2=LX(N+1)-1;
  if N==Nspans, M2=M2+1; end
  for m=M1:M2
    swtimeB=0;
    if m>1
      swtimeB=(time0(m)-time0(m-1))<=0;
      if  swtimeB
        timeRT=[timeRT max(timeRT)];
      end
    end 
    if ~swtimeB
      timeM=time0(m);
      swtimeA=0;
      if ~isempty(swlocs)
        swtimeA=~isempty(find(m==swlocs));
      end
      if swtimeA  %Switch time
        timeRT=[timeRT timeM];
      else  
        RNtime=round(timeM/tstep)*tstep;
        if (abs(timeM-RNtime))<eps, timeM=RNtime; end
        timeRT=[timeRT timeM];
      end
    end
  end
end
if size(timeRT,1)<size(timeRT,2), timeRT=timeRT'; end
timeRT=timeRT+time(1); 
return

%end of PSMT subfunction





