function  [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
    =SWXload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
     loadopt,rmsopt,saveopt,trackX);
% SWXload.m is the main driver in the logic that retrieves and 
% restructures swing export (SWX) data that is stored in column form.
%  [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,...
%      DataPath]...
%    =SWXload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
%      loadopt,rmsopt,saveopt,trackX);
%
% Special functions used:
%	SetExtSWX
%   cread
%   PTIprntRead
%   PTIrawcRead
%   DFRread
%   PSMresamp
%   promptyn,promptnv
%   PSMsave
%   
%  Modified 02/05/04.  Henry Huang.  Add DFR data reader
%  Modified 02/09/04.  Henry Huang.  Sort data matrix by ascending time order
%  Modified 04/27/04.  jfh.
%  Modified 10/18/2006  Ning Zhou.  Add Macro function

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

if ~exist('CFname'), CFname=''; end
SaveFile='';

chansXstr=chansX;
if ~ischar(chansX)
  chansXstr=['chansX=[' num2str(chansXstr) '];'];
end
eval(chansXstr);

%*************************************************************************
if isempty(PSMfiles)
  disp(['In SWXload: Seeking names for files to load' ])
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
str1=['In SWXload: Load option = ' num2str(loadopt)];
str2=['In SWXload: Seeking data from ' num2str(nXfiles) ' files:'];
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
% for recording position and total points of each Y data matrix. Henry
posY=zeros(1,nXfiles); maxYpts=zeros(1,nXfiles);    
for nXfile=1:nXfiles     %Start of main extraction loop
  PSMfile=deblank(PSMfiles(nXfile,:));
  fname=[DataPath PSMfile];
  CaseCom=str2mat(CaseCom,PSMfile);
  if (loadopt==1)|(loadopt==2)
    [y,comment,fname,names,reftime,tstepE]=cread(fname);
  end
  if loadopt==3
    [y,comment,fname,names,reftime,tstepE]=PTIprntRead(fname);
  end
  if loadopt==4
    [y,comment,fname,names,reftime,tstepE]=PTIrawcRead(fname);
  end 
  if loadopt==5
    ctag=''; NoHead=0; NoSigs=0; dsep='';
    [y,comment,fname,names,reftime,tstepE]=DFRread(fname,ctag,NoHead,NoSigs,dsep,nXfile);
  end 
  if isempty(y)
    disp(['In SWXread: EMPTY DATA ARRAY'])
    %disp(['In SWXread: Invoking "keyboard" command - Enter "return" when you are finished'])
    %keyboard
    nXfiles=nXfile-1; break
  end
  time=y(:,1);
  %%%maxpoints=length(y); - Modified 3/16/2009 by ftuffner
  [maxpoints,junk]=size(y);
  tsteps=time(2:maxpoints)-time(1:maxpoints-1);
  if nXfile==1
    posY(nXfile)=1; maxYpts(nXfile)=maxpoints; %Record position and data points for the 1st Y. Henry
    CaseCom=str2mat(CaseCom,comment);
    PSMreftimes=reftime;
    %Determine signals to keep
    chankey=names2chans(names); 
    chansX=1:maxpoints; namesX=names; 
    [MenuName,chansXN,chansXok]=SetExtSWX(chansXstr,names,chankey,CFname);
    if chansXok
      str1=['Starting menu = ' MenuName];
      CaseCom=str2mat(CaseCom,str1);
      chansX=chansXN;
    end
    if chansX(1)~=1, chansX=[1 chansX]; end   
    namesX=names(chansX,:); chankeyX=names2chans(namesX); 
    %Downsize signal array
    PSMsigsX=y(:,chansX);
    tstep=tstepE;
    maxtstep=max(tsteps); 
    if tstepE<=0, tstep=maxtstep; end
  else
    posY(nXfile)=posY(nXfile-1)+maxYpts(nXfile-1); maxYpts(nXfile)=maxpoints; % record position and data points for Y. Henry
    PSMreftimes=[PSMreftimes reftime];
    PSMsigsX=[PSMsigsX' y(:,chansX)']';
  end
end
clear y;
%************************************************************************* 

%************************************************************************* 
disp('  '); 
str1=['In SWXload: Data extracted from ' num2str(nXfiles) ' files:'];
disp(str1)
if isempty(PSMsigsX)
  PSMtype='none';
  disp('In SWXload: Empty signal array -- return'), return
end
str2=['In SWXload: Size PSMsigsX = ' num2str(size(PSMsigsX))];
disp(str2)
%*************************************************************************  

%*************************************************************************  
% Resort data matrix PSMsigsX by ascending time order. Henry
if (loadopt==5)&(nXfiles>1) %Need better test here 
  disp(' ')
  ReTime=promptyn('In SWXload: Resort by ascending time order?','y');
  if ReTime
    [timeSort, idx]=sortrows([PSMreftimes' PSMsigsX(posY,1)], [1 2]);
    disp('  ')
    disp(['In SWXread: Data files are resorted by ascending time order as:'])
    disp('  ')
    disp(['            PSMfiles = '])
    disp('  ')
    disp(PSMfiles(idx,:))
    PSMreftimes=timeSort(:,1)';
    y=PSMsigsX; %Storage requirements can be excessive for very large cases!!
    PSMsigsX=[]; 
    for i=1:nXfiles  
      locs1=posY(idx(i)):posY(idx(i))+maxYpts(idx(i))-1;
      y(locs1,1)=y(locs1,1)+PSMreftimes(i)-PSMreftimes(1);  %time ref to the first ref time.
      PSMsigsX = [PSMsigsX; y(locs1,:)];
    end
  end
end
%*************************************************************************  

%*************************************************************************  
%Review & clean up SWX data
DRevt0=clock;
str=['In SWXload: Starting data review at ' datestr(now)];
disp(str)
time=PSMsigsX(:,1);
maxpoints=size(PSMsigsX,1);
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
  Ptitle{1}='Checking SWX time steps';
  title(Ptitle)
  xlabel('Time in Samples')
  ylabel('Time Steps')
end
n1=3; if ~isempty(swlocs), n1=max(swlocs)+3; end
tstep=tstepE;
maxtstep=max(tsteps(n1:maxpoints-3)); 
if tstepE<=0, tstep=maxtstep; end
SampleRate=1/tstep;  %Use these values!
N=min(find(time>0));  %Trim off initial half-steps
while tsteps(N)>0.9*tstep
  N=N-1;
  if N==0, break, end
end
startpoint=N+1;
N=maxpoints-1;  %Trim off final half-steps
while tsteps(N)<0.9*tstep
  N=N-1;
  if N==0, break, end
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
time=PSMsigsX(:,1);
maxpoints=size(PSMsigsX,1);
tsteps=time(2:maxpoints)-time(1:maxpoints-1);
eps=0.001*tstep;
swlocs=find(abs(time(1:maxpoints-1)-time(2:maxpoints))<eps)';
swtimes=time(swlocs);
strs='In SWXload: Characteristics of extracted data';
strs=str2mat(strs,['  tstep      = ' num2str(tstep)]);
strs=str2mat(strs,['  SampleRate = ' num2str(SampleRate)]);
if ~isempty(swlocs)
  strs=str2mat(strs,['  Time axis indicates ' num2str(length(swlocs)) ' switching times']);
  for n=1:length(swlocs)
    strs=str2mat(strs,['    Switch time ' num2str(n) ' = ' sprintf('%3.6f',swtimes(n))]);
  end
end
disp(strs); %keyboard
CaseCom=str2mat(CaseCom,strs);
tstepsA=tsteps(find(tsteps>0));
Lmax=find(tstepsA==max(tstepsA)); Lmax=Lmax(1); 
Lmin=find(tstepsA==min(tstepsA)); Lmin=Lmin(1);
maxfrac=tstepsA(Lmax)/tstep; minfrac=tstepsA(Lmin)/tstep;
roughness=max(abs(maxfrac-1),abs(minfrac-1));
smoothdef=0.001; smoothfrac=smoothdef;
roughtime=roughness>smoothdef;
if roughtime
  str1=['  Irregular time steps:'];
  str2=['  Maximum time step =' sprintf('%1.3f',maxfrac) '  of standard'];
  str2=[str2 ' at time= ' sprintf('%4.4f',time(Lmax))];
  str3=['  Minimum time step =' sprintf('%1.3f',minfrac) '  of standard'];
  str3=[str3 ' at time= ' sprintf('%4.4f',time(Lmin))];
  strs=str2mat(str1,str2,str3); disp(strs)
  CaseCom=str2mat(CaseCom,strs);
  h=figure; plot(time)
  Ptitle{1}='Irregular time steps';
  title(Ptitle)
  xlabel('Time in Samples')
  ylabel('Time in seconds')
  h=figure; plot(tsteps)
  Ptitle{1}='Irregular time steps';
  title(Ptitle)
  xlabel('Time in Samples')
  ylabel('Time Steps')
end
%Determine elapsed time for fike read
DRevtime=etime(clock,DRevt0);
str=['In SWXload: Data review time = ' num2str(DRevtime) ' seconds'];
disp(str); comment=str2mat(comment,str);
%*************************************************************************  

%*************************************************************************
%Logic for signal resampling
decfacX=max(fix(decfacX),1);
maxpoints=size(PSMsigsX,1);
deftag='n'; if decfacX>1|roughtime, deftag=''; end

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'SWXload_resample'), PSMMacro.SWXload_resample=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.SWXload_resample))      % Not in Macro playing mode or selection not defined in a macro
    resample=promptyn('In SWXload: Resample raw data?',deftag);
else
    resample=PSMMacro.SWXload_resample;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SWXload_resample=resample;
    else
        PSMMacro.SWXload_resample=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% resample=promptyn('In SWXload: Resample raw data?',deftag);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

if resample
  tstartRS=PSMsigsX(1,1); upsfac=1; %keyboard
  [CaseCom,namesX,PSMsigsRS,tstartRS,tstep,upsfac,decfacX]...
     =PSMresamp(caseID,casetime,CaseCom,namesX,PSMsigsX,...
      tstartRS,tstep,upsfac,decfacX);
  %size(PSMsigsRS)   
  if isempty(PSMsigsRS)
    strs='In SWXload: Resampled data array is empty--Using original data';
  else
    PSMsigsX=PSMsigsRS; clear PSMsigsRS;
    maxpoints=size(PSMsigsX,1);
    strs='In SWXload: Raw data resampled as follows:';
    strs=str2mat(strs,['  Upsampling factor = ' num2str(upsfac)]);
    strs=str2mat(strs,['  Decimation factor = ' num2str(decfacX)]);
    strs=str2mat(strs,['  Final maxpoints   = ' num2str(maxpoints)]);
  end
  CaseCom=str2mat(CaseCom,strs); disp(strs); disp(' ')
end
simrate=1/tstep;
Nyquist=0.5*simrate;
%*************************************************************************

%*************************************************************************  
%Complete loading process
chankeyX=names2chans(namesX);
if isempty(CFname), CFname=['SWX Data Type ' num2str(loadopt)]; end
nsigs=size(namesX,1);
AngTypes=str2mat('VAng','IAng','VAngL','IAngL');
Ntypes=size(AngTypes,1);
AsigsIN=[];
for I=1:Ntypes
  AngTypeI=deblank(AngTypes(I,:));
  for N=1:nsigs
    teststr=[namesX(N,:) ' '];
    Ltest=findstr(AngTypeI,teststr);
    if ~isempty(Ltest)
      test=strcmp(teststr(Ltest+length(AngTypeI)),' ');
      if test
        AsigsIN=[AsigsIN N];
      end     
    end
  end
end
if ~isempty(AsigsIN)
  disp('In SWXload: Angle signals found are')
  disp(chankeyX(AsigsIN,:))

	%%%%%%%%%% Modification by d3x593 - 1-13-2011 - Macro it (sort of)
	if ~isfield(PSMMacro, 'SWXload_unwrap'), PSMMacro.SWXload_unwrap=NaN; end
	if (PSMMacro.RunMode<1 || isnan(PSMMacro.SWXload_unwrap))      % Not in Macro playing mode or selection not defined in a macro
		Unwrp=promptyn('In SWXload: Phase unwrap these signals?','y');	
	else
		Unwrp=PSMMacro.SWXload_unwrap;
	end
  %Unwrp=promptyn('In SWXload: Phase unwrap these signals?','y');	
	%%%%%%%%%%% End Macro mod

  if Unwrp
	disp('In SWXload: unwrapping');
    for N=1:length(AsigsIN)
      loc=AsigsIN(N);
      PSMsigsX(:,loc)=PSMunwrap(PSMsigsX(:,loc));
    end
  end
end
%*************************************************************************  

disp('Returning from SWXload')
disp(' ')
return

%end of PSMT function

