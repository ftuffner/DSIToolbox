% Case Script PSMreload.m
% Retrieves and processes .mat files saved in PSMtools format
% Functions provided by PSMreload:
%    Timestamp editing
%    Signal resampling
%    Automatic renaming of signals to facilitate sorting 
%    Parallel merging of multiple files
%    Saving of merged data

%
% PSM Tools called from PSMload:
%   PSMnamesCk
%   PSM2Date, Date2PSM
%   PSMresamp
%   names2chans
%   promptyn, promptnv
%   vec2mat
%
% Last modified 08/18/03.  jfh
% Last modified 02/19/07.  Ning Zhou to add macro function

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%keyboard;
%load debug01
%PSMMacro.RunMode=1; 

disp(' ')
disp('In PSMreload: Merge operations for standard PSMT files')
strs='Functions provided by PSMreload:';
strs=str2mat(strs,'  Timestamp editing');
strs=str2mat(strs,'  Signal resampling');
strs=str2mat(strs,'  Automatic renaming of signals to facilitate sorting'); 
strs=str2mat(strs,'  Parallel merging of multiple files');
strs=str2mat(strs,'  Saving of merged data');
disp(strs)
disp(' ')

%************************************************************************
%Determine files to retrieve
retrieveok=1; mergeok=0;
PSMfilesR=PSMfiles; PSMtype='.mat';

%----------------------------------------------------
% Begin: Macro selection ZN 02/19/07
if ~isfield(PSMMacro, 'PSMreload_PSMfilesR'), PSMMacro.PSMreload_PSMfilesR='';end
if ~isfield(PSMMacro, 'PSMreload_pathname'), PSMMacro.PSMreload_pathname='';end
if (PSMMacro.RunMode<1 || isempty(PSMMacro.PSMreload_PSMfilesR))      % Macro definition mode or selection not defined in a macro
    %????????????????????????????
    if retrieveok
      if isempty(PSMfilesR)
        disp('In PSMreload: Select individual files to reload:')
        disp(['caseID = ' caseID])
        for N=1:30
          disp('  ')
          prompt=['Locate file ' num2str(N) ' to reload (else press Cancel to end)'];
          disp(prompt)
          disp('Processing paused - press any key to continue'); pause
          strx='*.mat';

          [filename,pathname]=uigetfile([strx],prompt);

          if filename(1)==0|pathname(1)==0
            disp('Selections complete -- processing'), break
          end
          if N==1
            disp('In PSMreload: Changing to directory shown below:')
            disp(pathname)
            eval(['cd ' '''' pathname ''''])
            PSMfilesR(N,:)=filename;
          else
            PSMfilesR=str2mat(PSMfilesR,filename); 
          end
          addpath(pathname);  %Temporary addition to Matlab path
          disp('Files already selected:'); disp(PSMfilesR)
        end
      end
      nRfiles=size(PSMfilesR,1);        %number of files to reload
      disp(' ')
      disp(['Number of files to reload = ' sprintf('%2.1i',nRfiles)])
      if nRfiles>0
        disp('File names in array PSMfilesR are')
        disp(PSMfilesR)
      end
      filesok=promptyn('In PSMreload: Is this ok? ', 'y');
      if ~filesok|nRfiles==0
        retok=promptyn('Return from PSMreload? ', 'y');
        if retok
          disp('In PSMreload: No file reload operations -- return'),
          retrieveok=0; diary off, return
        end
        disp('Invoking "keyboard" command -  Type "return" when you are done')
        keyboard
      end
    end

    %????????????????????????????
else
   PSMfilesR=PSMMacro.PSMreload_PSMfilesR;
   pathname=PSMMacro.PSMreload_pathname;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMreload_PSMfilesR=PSMfilesR;
        PSMMacro.PSMreload_pathname=pathname;
    else
        PSMMacro.PSMreload_PSMfilesR='';
        PSMMacro.PSMreload_pathname='';
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
nRfiles=size(PSMfilesR,1);        %number of files to reload
% End: Macro selection ZN 02/19/07
%----------------------------------------------------

%************************************************************************

%************************************************************************
%Examine contents of files to retrieve
disp(' ')
disp('In PSMreload: Scanning contents of files selected to reload')
timefill =-5000; TimeVecs =[];  
Atimefill=-5;    Atimevecs=[];
RecPoints=zeros(nRfiles,1);
for Rfile=1:nRfiles  %Scan contents & time ranges
  disp(' ')
  PSMtype=''; PSMreftimes=0; tstep=0; tstepF=0;
  disp(['Contents of File ' num2str(Rfile) ': ' PSMfilesR(Rfile,:)])
  pfname=['''' deblank(PSMfilesR(Rfile,:)) ''''];
  eval(['whos -file ' pfname])
  eval(['load '  pfname ' PSMsigsX namesX PSMtype PSMreftimes tstep'])
  if isempty(PSMsigsX)
    eval(['load '  pfname ' PSMsigsF namesX PSMreftimes tstep tstepF'])
    PSMsigsX=PSMsigsF; tstep=tstepF; 
  end
  if isempty(PSMtype), PSMtype='unknown'; end
  if isempty(PSMreftimes), PSMreftimes=0; end
  if tstep==0, tstep=tstepF; end
  eval(['MS=whos(' '''-file''' ',' pfname ',' '''PSMsigsX''' ');'])
  if isempty(char(MS.name))
    eval(['MS=whos(' '''-file''' ',' pfname ',' '''PSMsigsF''' ');'])
  end 
  if isempty(char(MS.name))
    disp(' ')
    disp('In PSMreload: Indicated file is not in standard PSMT form')
    disp('  Cannot find PSMsigsX or PSMsigsF -- Return')
    disp(' ')
    return 
  end
  psmsize=MS.size; maxpts=psmsize(1);
  %WARNING: tstep may be an array for successive merges 
  if isempty(findstr('time',lower(namesX(1,:))))
    disp(['No time axis indicated in namesX: first name = ' namesX(1,:)])
    disp(['Constructing time axis using tstep = ' num2str(tstep)])
    maxpts=size(PSMsigsX,1);
    time=[0:maxpts-1]'*tstep(1);
    PSMsigsX=[time PSMsigsX];
    namesX=str2mat('Time',namesX);
    chankeyX=names2chans(namesX);
  end
  time=PSMsigsX(:,1); maxpts=length(time);
  RecPoints(Rfile)=maxpts;
  Atime=time+PSMreftimes(1);
  TimeVecs=vec2mat(TimeVecs,time,timefill);
  StartTime=Atime(1);
  EndTime  =Atime(maxpts);
  if Rfile==1
    PSMtypesR=PSMtype;
    RefTimesR=PSMreftimes(1);
    tsteps=tstep;
    PSMsizeR=psmsize;
    StartTimesR=StartTime;
    EndTimesR=EndTime;
    DecFacR=1;  %Initialize local decimation factor
  else 
    PSMtypesR=str2mat(PSMtypesR,PSMtype);
    RefTimesR=[RefTimesR; PSMreftimes(1)];
    tsteps=[tsteps' tstep']';
    PSMsizeR=[PSMsizeR' MS.size']';  maxpts=MS.size(1);
    StartTimesR=[StartTimesR' StartTime']';
    EndTimesR=[EndTimesR' EndTime']';
    DecFacR=[DecFacR' 1']';
  end
end
%************************************************************************

%************************************************************************
%Set resampling controls
srates=(1./tsteps);
for Rfile=1:nRfiles  
  srate=srates(Rfile);
  if mod(srate,1)<0.05, srates(Rfile)=floor(srate); end
  if mod(srate,1)>0.95, srates(Rfile)=ceil(srate);  end
end
if max(mod(srates,1))~=0
  disp('In PSMreload: Fractional sample rate(s)')
  disp(srates)
  disp('Processing paused - press any key to continue'); pause
end
tsteps=(1./srates); tstepsD=tsteps;
NewRate=srates(1);
RSpars=[srates ones(nRfiles,3)]; RSpars(:,4)=NewRate;
ratesok=0;
if max(srates)~=min(srates)
  disp('In PSMreload: Sample rates not equal-values are')
  disp(srates)
  for defrate=min(srates):-1:1
    if max(mod(srates/defrate,1))==0, break, end
  end
  disp(['Common sampling rate = ' num2str(defrate)])
  NewRate=defrate;
  RSpars(:,4)=NewRate; RSpars(:,3)=srates/NewRate;
  ratesok=promptyn('Is decimation to this rate ok? ', '');
end
maxtrys=8;
for i=1:maxtrys
  if ~ratesok
    disp('Set controls for general resampling:')
    disp('New sampling rate must be obtainable by integer upsampling then integer decimation') 
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/19/07
    if ~isfield(PSMMacro, 'PSMreload_NewRate'), PSMMacro.PSMreload_NewRate=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMreload_NewRate))      % Macro definition mode or selection not defined in a macro
        %????????????????????????????
        NewRate=promptnv('Enter integer value for final sample rate: ',[NewRate]);
        NewRate=round(NewRate);
        %????????????????????????????
    else
       NewRate=PSMMacro.PSMreload_NewRate;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMreload_NewRate=NewRate;
        else
            PSMMacro.PSMreload_NewRate=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 02/19/07
    %----------------------------------------------------
    RSok=1; RSpars=[srates zeros(nRfiles,3)];
    for Rfile=1:nRfiles
      fac=NewRate/srates(Rfile);
      upsN=0; decN=0; 
      for N=1:5000
        M=fac*N;
        if abs(round(M)-M)<0.0001
          upsN=M; decN=N; 
          RSpars(Rfile,:)=[srates(Rfile) upsN decN NewRate]; 
          break
        end
      end
      RSNok=upsN>0&decN>0;
      if ~RSNok
        RSok=0;
        disp(['File ' num2str(Rfile) ': No resampling solution found for Newrate = ' num2str(Newrate)])
      end
    end
    if RSok
      disp(['In PSMreload: Resampling parameters for NewRate = ' num2str(NewRate)])
      disp(RSpars)
      
        %----------------------------------------------------
        % Begin: Macro selection ZN 02/19/07
        if ~isfield(PSMMacro, 'PSMreload_ratesok'), PSMMacro.PSMreload_ratesok=NaN;end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMreload_ratesok))      % Macro definition mode or selection not defined in a macro
            %????????????????????????????
            ratesok=promptyn('Is this ok? ', 'y');
            %????????????????????????????
        else
           ratesok=PSMMacro.PSMreload_ratesok;
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PSMreload_ratesok=ratesok;
            else
                PSMMacro.PSMreload_ratesok=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        % End: Macro selection ZN 02/19/07
        %----------------------------------------------------
      
      
      if ratesok
        break
      end
    else
      disp(['In PSMreload: Resampling not allowed for NewRate = ' num2str(NewRate)])
      disp('New sampling rate must be obtainable by integer upsampling then integer decimation')
      disp('Original sample rates are'); disp(srates) 
    end
  end
end
if ~ratesok
  disp(sprintf('Sorry -%5i chances is all you get!',maxtrys))
  disp('In PSMreload: No file reload operations -- return'),
  retrieveok=0; diary off, return
end
%************************************************************************

%************************************************************************
%Confirm/amend file time stamps
disp(' ')
disp('In PSMreload: Confirming time stamps');
stampsok=0; maxtrys=5;
for i=1:maxtrys
  if ~stampsok
    for Rfile=1:nRfiles  
      disp(' ')
      pfname1=deblank(PSMfilesR(Rfile,:));
      disp(['File ' num2str(Rfile) ': ' pfname1])
      StartDatestr=PSM2Date(StartTimesR(Rfile)); 
      disp(['  Rec Start Time = ' StartDatestr ' GMT Standard'])
        %----------------------------------------------------
        % Begin: Macro selection ZN 02/19/07
        if ~isfield(PSMMacro, 'PSMreload_stampok'), PSMMacro.PSMreload_stampok=NaN;end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMreload_stampok))      % Macro definition mode or selection not defined in a macro
            %????????????????????????????
            stampok=promptyn('  Is this value ok? ','y');
            %????????????????????????????
        else
           stampok=PSMMacro.PSMreload_stampok;
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PSMreload_stampok=stampok;
            else
                PSMMacro.PSMreload_stampok=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        % End: Macro selection ZN 02/19/07
        %----------------------------------------------------
      
      
      if ~stampok
        prompt2='Enter reference time in format 10-Aug-1996 15:48:46.133: ';
        DateString=input(prompt2,'s');
        if isempty(DateString), DateString=StartDatestr; end
        NewTime=Date2PSM(DateString); StartDatestr=PSM2Date(NewTime); 
        disp(['  Rec Start Time = ' StartDatestr ' GMT Standard'])
        Shift=NewTime-StartTimesR(Rfile);
        RefTimesR(Rfile)  =RefTimesR(Rfile)  +Shift;
        StartTimesR(Rfile)=StartTimesR(Rfile)+Shift;
        EndTimesR(Rfile)  =EndTimesR(Rfile  )+Shift;
        prompt3=['Backload new reference times into ' pfname1 '?  '];
        BkLoad=promptyn(prompt3,'');
        if BkLoad  
           pfname2=['''' pfname1 ''''];
           eval(['load ' pfname2 ' PSMreftimes'])
           PSMreftimes=PSMreftimes+Shift;
           eval(['save '  pfname2 ' PSMreftimes -append'])
           disp('Backloaded reference times are')
           disp(PSM2Date(PSMreftimes))
         end
      end
    end
    
%    keyboard
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/19/07
    if ~isfield(PSMMacro, 'PSMreload_stampsok2'), PSMMacro.PSMreload_stampsok2=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMreload_stampsok2))      % Macro definition mode or selection not defined in a macro
        %????????????????????????????
        stampsok=promptyn('Are all reference time values ok? ','y');
        %????????????????????????????
    else
       stampsok=PSMMacro.PSMreload_stampsok2;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMreload_stampsok2=stampsok;
        else
            PSMMacro.PSMreload_stampsok2=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 02/19/07
    %----------------------------------------------------
    
    if stampsok 
        break; 
    end
  end
end
if ~stampsok
  disp(sprintf('Sorry -%5i chances is all you get!',maxtrys))
  continueok=promptyn('Continue processing? ','y');
	if ~continueok
    disp('In PSMreload: No file reload operations -- return'),
    retrieveok=0; diary off, return
  end
end
%************************************************************************

%************************************************************************
%Display record parameters
allSWX=1;
for Rfile=1:nRfiles  
  allSWX=allSWX*~isempty(strmatch('SWX',deblank(PSMtypesR(Rfile,:))));
end
disp(' ')
disp('Record parameters based on initial time stamps:')
for Rfile=1:nRfiles  
  disp(' ')
  disp(['File ' num2str(Rfile) ': ' PSMfilesR(Rfile,:)])
  %NOTE: PSM absolute time is measured in seconds starting at 1-Jan-1900
  %      Matlab absolute time is measured in days starting at 1-Jan-0000 
  isSWX=strmatch('SWX',deblank(PSMtypesR(Rfile,:)));
  RefDatestr=PSM2Date(RefTimesR(Rfile)); 
  StartDatestr=PSM2Date(StartTimesR(Rfile)); 
  EndDatestr=PSM2Date(EndTimesR(Rfile)); 
  Tbar=PSMsizeR(Rfile,1)*tsteps(Rfile);
  upsfac=RSpars(Rfile,2); decfac=RSpars(Rfile,3);
  str1=['  Reference Time = ' RefDatestr ' GMT Standard'];
  str2=['  Rec Start Time = ' StartDatestr ' GMT Standard'];
  str3=['  Rec End Time   = ' EndDatestr ' GMT Standard'];
  str4=['  Time step = ' num2str(tsteps(Rfile)) ' seconds'];
  str5=['  Record length  = ' num2str(Tbar) ' seconds'];
  str6=['  Nominal resampling  = ' num2str([upsfac decfac])];
  strs=str2mat(str1,str2,str3,str4,str5,str6); disp(strs)
end
%************************************************************************

%************************************************************************
%Determine absolute time axes
for Rfile=1:nRfiles
  locs=find(TimeVecs(:,Rfile)>timefill);
  time=TimeVecs(locs,Rfile);
  Atime=time+RefTimesR(Rfile);
  Atimevecs=vec2mat(Atimevecs,Atime,Atimefill);
end
%************************************************************************

%************************************************************************
%Determine merge window
FirstRef   =min(RefTimesR);            LastRef  =max(RefTimesR);
FirstStart =min(Atimevecs(1,:));       LastStart=max(Atimevecs(1,:));
FirstEnd   =min(max(Atimevecs(:,:)));  LastEnd  =max(max(Atimevecs(:,:)));
disp(' ')
disp('In PSMreload:  Limits for maximum merge window are')
disp(['  LastStart = ' num2str(LastStart) ' = ' PSM2Date(LastStart)])
disp(['  FirstEnd  = ' num2str(FirstEnd ) ' = ' PSM2Date(FirstEnd )])
if LastStart>FirstEnd
  disp(' ')
  disp('In PSMreload: Note that records do not overlap -- bad reference times?')
  disp('Reference times RefTimesR shown below: (seconds since 01-Jan-1900 00:00:00)')
  disp(RefTimesR)
  disp('Processing paused - press any key to continue'); pause
  keybdok=promptyn('Do you want to edit RefTimesR? ','n');
  if keybdok
    disp(['In PSMreload: Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
    %Revise absolute time axes
    for Rfile=1:nRfiles
      locs=find(TimeVecs(:,Rfile)>timefill);
      time=TimeVecs(locs,Rfile);
      Atime=time+RefTimesR(Rfile);
      Atimevecs=vec2mat(Atimevecs,Atime,Atimefill);
    end
    FirstRef   =min(RefTimesR);            LastRef  =max(RefTimesR);
    FirstStart =min(Atimevecs(1,:));       LastStart=max(Atimevecs(1,:));
    FirstEnd   =min(max(Atimevecs(:,:)));  LastEnd  =max(max(Atimevecs(:,:)));
    disp(' ')
    disp('In PSMreload:  Limits for maximum merge window are')
    disp(['  LastStart = ' num2str(LastStart) ' = ' PSM2Date(LastStart)])
    disp(['  FirstEnd  = ' num2str(FirstEnd ) ' = ' PSM2Date(FirstEnd )])
  end
  if ~keybdok|LastStart>FirstEnd
    disp('In PSMreload: Bad parameters -- returning')
    return 
  end
end

%----------------------------------------------------
% Begin: Macro selection ZN 02/19/07
if ~isfield(PSMMacro, 'PSMreload_Xrangeok'), PSMMacro.PSMreload_Xrangeok=NaN;end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMreload_Xrangeok))      % Macro definition mode or selection not defined in a macro
    %????????????????????????????
    Xrangeok=promptyn('Use these limits? ', 'y');
    %????????????????????????????
else
   Xrangeok=PSMMacro.PSMreload_Xrangeok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMreload_Xrangeok=Xrangeok;
    else
        PSMMacro.PSMreload_Xrangeok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 02/19/07
%----------------------------------------------------



if ~Xrangeok
  disp('Invoking "keyboard" command -  Type "return" when you are done')
  keyboard
end
%************************************************************************

%************************************************************************
%Execute file retrieve/merge loop
mergeok=nRfiles>=1;
disp([' ';' '])
disp('In PSMreload: Starting file retrieve/merge loop')
LMerge=[]; CFnames='';
for Rfile=1:nRfiles
  disp(['File ' num2str(Rfile) ' is ' PSMfilesR(Rfile,:) ':'])
  pfname=['''' deblank(PSMfilesR(Rfile,:)) ''''];
  disp('Contents of indicated file');
  eval(['whos -file ' pfname])
  eval(['varlist=who(' '''-file''' ',' pfname  ');']);
  %loadok=promptyn('In PSMreload: Load indicated file? ', 'y');
  loadok=1;  %Else add code to update scanned file quantities
  if ~loadok
	if Rfile==1&nRfiles==1
      disp('In PSMreload: No file load operations -- return') 
      retrieveok=0; mergeok=0; diary off, return
    else
	    disp('In PSMreload: Skipping this file ')
      break 
    end
  end
  CaseComSave=CaseCom;      %May be overwritten
  CaseCom=''; CaseComR='';  %File will contain one or the other
  PSMtype=''; PSMreftimes=0; tstep=0; tstepF=0;
  eval(['load ' pfname])
  if ~isempty(CaseCom), CaseComR=CaseCom; end
  if isempty(PSMtype), PSMtype='unknown'; end
  if isempty(CFname),  CFname= 'unknown'; end
  if Rfile==1, CFnames=CFname;
  else CFnames=str2mat(CFnames,CFname);
  end
if isempty(PSMreftimes), PSMreftimes=0; end
  if tstep==0, tstep=tstepF; end
  if tstep==0
    disp('In PSMreload: Zero time step for retrieved data') 
    disp('Invoking "keyboard" command -  enter "return" when you are done')
    disp('To skip this file, enter "break" and then "return"')
    keyboard
  end
  if isempty(findstr('time',lower(namesX(1,:))))
    disp(['No time axis indicated in namesX: first name = ' namesX(1,:)])
    disp(['Constructing time axis using tstep = ' num2str(tstep)])
    maxpts=size(PSMsigsX,1);
    time=[0:maxpts-1]'*tstep(1);
    PSMsigsX=[time PSMsigsX];
    namesX=str2mat('Time',namesX);
    chankeyX=names2chans(namesX);
  end
  str1='In PSMreload: Data retrieved from file below';
  str2=['  ' pfname];
  disp(str1); disp(str2)
  CaseComSave=str2mat(CaseComSave,' ',str1,str2);
  isSWX=strmatch('SWX',deblank(PSMtype));
  PSMnamesCk  %Standardize variable names for retrieved data
  [nPSMpts nchans]=size(PSMsigsX);
  evec=abs((Atimevecs(:,Rfile))-LastStart);
  L1=find(evec==min(evec)); %Rfile,L1,Atimevecs(L1,Rfile)-LastStart
  evec=abs((Atimevecs(:,Rfile))-FirstEnd);
  L2=find(evec==min(evec)); %Rfile,L1,Atimevecs(L2,Rfile)-FirstEnd
  LMerge=[LMerge [L1 L2]'];
  upsfac=RSpars(Rfile,2); decfac=RSpars(Rfile,3);
  tstepD=tstep*decfac/upsfac; %keyboard
  disp(['  Size retrieved PSMsigsX = ' num2str(size(PSMsigsX))])
  PSMsigsX(:,1)=Atimevecs(1:nPSMpts,Rfile)-LastStart;
  namesX0=namesX;
  namesX=BstringOut(namesX,' ',2); %Remove surplus blanks  
  if Rfile==1
    nPSMchans=nchans;
    AllNames=namesX;
    if mergeok
      tstartRS=PSMsigsX(L1,1);
      if upsfac==1&decfac==1 %Need roughness test also?
        AllSigs=PSMsigsX(L1:L2,:);
      else
        [CaseCom,namesX,AllSigs,tstartRS,tstep,upsfac,decfac]...
         =PSMresamp(caseID,casetime,CaseCom,namesX,PSMsigsX(L1:L2,:),...
          tstartRS,tstep,upsfac,decfac); 
      end   
    else
      PSMsigsX=[]; AllSigs =[];
    end
    Tpointer=1; TimeChans=[1];
    tstepsD=tstepD;
  else
    nPSMchans=[nPSMchans' nchans']';
    for L=1:nchans
      str=[namesX(L,:)];
      if L==1, namesXX=str;
      else
        namesXX=str2mat(namesXX,str);
      end
    end
    AllNames=str2mat(AllNames,namesXX);
    tstartRS=PSMsigsX(L1,1);
    if upsfac==1&decfac==1 %Need roughness test also?
      PSMsigsX=PSMsigsX(L1:L2,:);
    else
      [CaseCom,namesX,PSMsigsX,tstartRS,tstep,upsfac,decfac]...
       =PSMresamp(caseID,casetime,CaseCom,namesX,PSMsigsX(L1:L2,:),...
        tstartRS,tstep,upsfac,decfac);    
    end
    Npts=min(size(AllSigs,1),size(PSMsigsX,1));
    AllSigs=[AllSigs(1:Npts,:) PSMsigsX(1:Npts,:)]; clear PSMsigsX;
    TimeChans=[TimeChans Tpointer];  
    tstepsD=[tstepsD' tstepD']';     %Time steps for decimated data  
  end
  Tpointer=Tpointer+nchans;
  tstepsR=(tstep);  %Time step for retrieved data
  S1='Start of retrieved comments file CaseComR:';
  S2='End of retrieved comments file CaseComR';
  CaseComSave=str2mat(CaseComSave,S1,CaseComR,S2);
  CaseCom=CaseComSave;
end  %End of file retrieve/merge loop
%************************************************************************

%************************************************************************
%Remove surplus blanks from signal names
%Extend signal names to indicate merged files (optional)
AllNames=BstringOut(AllNames,' ',2); %Remove surplus blanks  
MFtags=''; ApTags=0;
%if nRfiles>1
%----------------------------------------------------
% Begin: Macro selection ZN 02/19/07
if ~isfield(PSMMacro, 'PSMreload_ApTags'), PSMMacro.PSMreload_ApTags=NaN;end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMreload_ApTags))      % Macro definition mode or selection not defined in a macro
    %????????????????????????????
    ApTags=promptyn('In PSMreload: Append tags to indicate MergeFiles? ', '');
    %????????????????????????????
else
   ApTags=PSMMacro.PSMreload_ApTags;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMreload_ApTags=ApTags;
    else
        PSMMacro.PSMreload_ApTags=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 02/19/07
%----------------------------------------------------
%end
if ApTags
  disp('In PSMreload: Default MergeFile tags are')
  for Rfile=1:nRfiles
    numstr=num2str(Rfile); 
    if length(numstr)<2, numstr=['0' numstr]; end
    str=['MF' numstr]; 
    if Rfile==1
      MFtags=str;
    else
      MFtags=str2mat(MFtags,str);
    end
    disp(['  ' MFtags(Rfile,:)])
  end
  TagsEdit=promptyn('In PSMreload: Enter custom MergeFile tags? ', '');
  if TagsEdit
    disp('In PSMreload: CFnames are')
    disp(CFnames)
    MFtags='';
    for Rfile=1:nRfiles   
      prompt=['Enter MFtag for MergeFile ' num2str(Rfile) ': '] ;
	  str=input(prompt,'s');
      if Rfile==1
        MFtags=str;
      else
        MFtags=str2mat(MFtags,str);
      end
      disp(['  ' MFtags(Rfile,:)])
    end
  end
end
if ApTags  %Extend signal names
  AllNamesX=AllNames; 
  AllNames='';
  loc=1;
  for Rfile=1:nRfiles
    nchans=nPSMchans(Rfile);
    for L=1:nchans
      if loc==1, AllNames=AllNamesX(loc,:);
      else 
        numstr=num2str(Rfile); if length(numstr)<2, numstr=['0' numstr]; end
        str=[AllNamesX(loc,:) ' ' MFtags(Rfile,:)];  
        AllNames=str2mat(AllNames,str);
      end
      loc=loc+1;
    end
  end
end
%************************************************************************

%************************************************************************
%Verify time axis alignment for merged files'
if mergeok
  tstep=tstepsD;
  disp('In PSMreload: Verifying time axis alignment for merged files')
  if (max(tstepsD)-min(tstepsD))>0.01*max(tstepsD)
    disp('In PSMreload: Timestep anomalies')
    tstepsD
  end
  PSMreftimes(1)=LastStart; 
  PSMdatenum=num2str (PSMreftimes(1));
  PSMdatestr=PSM2Date(PSMreftimes(1)); 
  S2=['Integrated PSM Reference Time = ' PSMdatenum ' Seconds'];      disp(S2)
  S3=['Integrated PSM Reference Time = ' PSMdatestr ' GMT Standard']; disp(S3)
  CaseCom=str2mat(CaseCom,' ',S2,S3);
  namesX=AllNames; clear AllNames;
  chankeyX=names2chans(namesX);
  PSMsigsX=AllSigs; clear AllSigs;
  maxpoints=size(PSMsigsX,1);
  if min(size(PSMsigsX))<1
    disp(' ')
    disp('In PSMreload: Files to merge do not overlap')
    disp('If intent is to concatinate files, not merge them, then')
    disp('files should be loaded as .mat (NOT reloaded)') 
    disp('Returning from PSMreload')
    disp(' ')
    retrieveok=0; mergeok=0; diary off, return
  end
  StartEps=PSMsigsX(1,TimeChans);
  locs=find(abs(StartEps)<0.01*tstep(1));
  PSMsigsX(1,TimeChans(locs))=0;
  disp('Local start times for aligned records:')
  for N=1:nRfiles  %length(TimeChans)
    disp(PSMsigsX(1,TimeChans(N)))
  end
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/19/07
    if ~isfield(PSMMacro, 'PSMreload_keybdok'), PSMMacro.PSMreload_keybdok=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMreload_keybdok))      % Macro definition mode or selection not defined in a macro
        %????????????????????????????
        keybdok=promptyn(['In PSMreload: Do you want the keyboard? '], 'n');
        %????????????????????????????
    else
       keybdok=PSMMacro.PSMreload_keybdok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMreload_keybdok=keybdok;
        else
            PSMMacro.PSMreload_keybdok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 02/19/07
    %----------------------------------------------------  

  
  if keybdok
    disp(['In PSMreload: Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
  StartEps=PSMsigsX(1,1);
  if (abs(StartEps)>0)&(abs(StartEps)<0.05*tstep(1))
    str=['In PSMreload: Changing local start time from ' num2str(StartEps)];
    str=[str ' to zero']; disp(str)
    PSMsigsX(1,1)=0;
  end 
  RecStart=PSM2Date(PSMsigsX(1,1)+PSMreftimes(1)); 
  RecEnd  =PSM2Date(PSMsigsX(maxpoints,1)+PSMreftimes(1));
  S2=['Record Start Time = ' RecStart ' GMT Standard']; disp(S2)
  S3=['Record End Time   = ' RecEnd   ' GMT Standard']; disp(S3)
  CaseCom=str2mat(CaseCom,S2,S3);
end
%************************************************************************

%************************************************************************
%Complete file reloading
strs=['In PSMreload: Size PSMsigsX = ' num2str(size(PSMsigsX))];
disp(strs)
PSMtype='.mat';
CFname='PSMT Reload';
PSMfiles=PSMfilesR; 
%PSMreftimes=RefTimesR;
AbsRefTime=LastStart; 
if ~exist('tstep'), tstep=0; end
if isempty(tstep) , tstep=0; end
if tstep==0, tstep=PSMsigsX(2,1)-PSMsigsX(1,1); end
tstep=tstep(1);
PSMfiles=PSMfilesR;
if ~isempty(PSMfiles)
  disp(' ')
  if isempty(PSMreftimes), PSMreftimes=0; end
  AbsRefStr=PSM2Date(AbsRefTime);
  strs=['In PSMreload: Size PSMsigsX = ' num2str(size(PSMsigsX))];
  strs=str2mat(strs,'Data extracted from the following files:', PSMfiles);
  str=['Reference for absolute time calculations is AbsRefTime = '];
  str=[str sprintf('%2.12e',AbsRefTime) ' seconds'];
  strs=str2mat(strs,str,['Equivalent GMT standard time = ' AbsRefStr ]);
  CaseCom=str2mat(CaseCom,strs); disp(strs)
end
%************************************************************************

%************************************************************************
%%Delete extra blanks in signal names 
namesX=BstringOut(namesX,' ',2);  %Remove surplus blanks 
chankeyX=names2chans(namesX);
CaseCom=str2mat(CaseCom,'Start of resumed processing:');
CaseComR=CaseCom;
%************************************************************************

%*************************************************************************
%Optional data save to file
disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 02/19/07
if ~isfield(PSMMacro, 'PSMreload_savesok'), PSMMacro.PSMreload_savesok=NaN;end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMreload_savesok))      % Macro definition mode or selection not defined in a macro
    %????????????????????????????
    savesok=promptyn('In PSMreload: Invoke utility to save extracted signals? ', '');
    %????????????????????????????
else
   savesok=PSMMacro.PSMreload_savesok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMreload_savesok=savesok;
    else
        PSMMacro.PSMreload_savesok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 02/19/07
%----------------------------------------------------  


if savesok
  disp('In PSMreload: Loop for saving data to files:')
  CaseComR=CaseCom;
  for tries=1:10
    disp(' ')
    SaveFile='';
    SaveList=['PSMtype PSMsigsX tstep namesX chankeyX CaseComR PSMfiles PSMreftimes CFname'];
    PSMsave
    if isempty(SaveFile), break, end
  end
end
%*************************************************************************

disp('Return from PSMreload')
disp(' ')

%end of PSMT utility
