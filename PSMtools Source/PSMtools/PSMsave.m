% PSM utility PSMsave.m 
% Saves PSM data to a file.  Options are
%   .mat file in standard PSMtools format
%   .txt file SWX format 1
%
% PSMsave requires a value for "SaveList": for example,
%  
%  SaveList='PSMtype PSMsigsX tstep  namesX chankeyX CaseComR PSMfiles PSMreftimes CFname';
%  SaveList='PSMtype PSMsigsF tstepF namesX chankeyX CaseComF PSMfiles PSMreftimes CFname';
%  SaveList='PMUsigs PMUfreqs tstep PMUtags PMUnames PhsrNames VIcon CFname CaseCom PDCfileX';
%  SaveList='refname fftfrq PxxSave PyySave TxySave CxySave tstepS namesS chankeyX CaseComS PSMfiles';
%
% PSM Tools called from PSMsave:
%   ShowRange
%   promptyn
%
% Modified 12/14/05.  jfh  Added -V6 qualification for Matlab 7 or higher
% NOTE: Some portions of code are specialized to saving PSMsigsX--needs to be fixed
% Modified 04/02/05.  zn   Macro function

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%Standard SaveList='PSMtype PSMsigsX tstep  namesX chankeyX CaseComR PSMfiles PSMreftimes CFname';
%Filtered SaveList='PSMtype PSMsigsF tstepF namesX chankeyX CaseComF PSMfiles PSMreftimes CFname';
%Spectral SaveList='refname fftfrq PxxSave PyySave TxySave CxySave tstepS namesS chankeyX CaseComS PSMfiles';
%PDCload4 SaveList='PMUsigs PMUfreqs tstep PMUtags PMUnames PhsrNames VIcon CFname CaseComPDC PDCfileX';
%PMUload  SaveList='PSMtype PSMsigsX tstep namesX chankeyX CaseComPMU PSMfiles PSMreftimes CFname';

%persistent FileSaveN

%Tag added to default name for SaveFile

%load debugPSMsave.mat
%PSMMacro.RunMode=-1

if ~exist('FileSaveN'), FileSaveN=1; end
if isempty('FileSaveN'), FileSaveN=1; end
SaveTags='ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
FileSaveN=max(FileSaveN,1);
if FileSaveN>length(SaveTags), FileSaveN=1; end

 SaveFile='';
%if ~exist('SaveFile'),SaveFile=''; end
if ~exist('SaveList'), SaveList=''; end
if ~exist('CaseCom'),  CaseCom ='';  end
if ~exist('CaseComR'), CaseComR=''; end

if ~exist('CFname'),   CFname  =''; end
tabchar='	';

%Determine name of Case Comment array
SaveList=[SaveList ' '];
L1=findstr('CaseCom',SaveList); CaseComName='';
if ~isempty(L1)
  L2=L1+6;
  while (strcmp(SaveList(L2+1),' '))==0
    L2=L2+1;
  end
  CaseComName=deblank([SaveList(L1:L2)]);
else
  CaseComName='CaseComR';
  SaveList=[SaveList ' ' CaseComName];
end

%*************************************************************************
%Test for save operation
disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
    if ~isfield(PSMMacro,'PSMsave_saveok'), PSMMacro.PSMsave_saveok=NaN; end
        
    if (PSMMacro.RunMode<2 || isnan(PSMMacro.PSMsave_saveok))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
        saveok=promptyn('In PSMsave: Save results data to a file? ','');
    else
        saveok=PSMMacro.PSMsave_saveok;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMsave_saveok=saveok;
        else
            PSMMacro.PSMsave_saveok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------

if ~saveok
  disp('Return from PSMsave - save operations refused by user')
  return
end
%*************************************************************************

%*************************************************************************
%Determine Matlab version
%help ver
VNtag='';
A=ver('matlab'); VN=str2num(A.Version);
if VN>=7.0, VNtag=' -V6 '; end
%*************************************************************************

%*************************************************************************
%Verify SaveList
if isempty(SaveList)
  disp('In PSMsave: No SaveList -- using default below')
  SaveList=['PSMtype PSMsigsX tstep namesX chankeyX CaseComR PSMfiles PSMreftimes CFname']
  listok=promptyn('Is this ok? ','y');
  if ~listok
    str1='In PSMsave: Invoking "keyboard" command:';
    disp(str2mat(str1,'  Type "return" when you are finished.'))
    keyboard
  end
end
%*************************************************************************

%*************************************************************************
%Determine name and type of save file
nameok=0;
if saveok
    
  %----------------------------------------------------  
  % start: write the DST files by ZN 05/11/2007
  if ~isfield(PSMMacro, 'PSMsave_DSTXok'), PSMMacro.PSMsave_DSTXok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMsave_DSTXok))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
        DSTXok=promptyn('In PSMsave: Save as DST files?','');
    else
        DSTXok=PSMMacro.PSMsave_DSTXok;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMsave_DSTXok=DSTXok;
        else
            PSMMacro.PSMsave_DSTXok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
  end
    
  if DSTXok
     funDSIMat2DST02(PSMsigsX,PSMreftimes,namesX,tstep); 
  end
  % end: write the DST files by ZN 05/11/2007
  %----------------------------------------------------  
  
  %----------------------------------------------------
  % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMsave_SWXok'), PSMMacro.PSMsave_SWXok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMsave_SWXok))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
        SWXok=promptyn('In PSMsave: Save as tabbed ascii? (else binary) ','');
    else
        SWXok=PSMMacro.PSMsave_SWXok;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMsave_SWXok=SWXok;
        else
            PSMMacro.PSMsave_SWXok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
  % End: Macro selection ZN 03/31/06
  %----------------------------------------------------  
  
 
  maxtrys=8;
  for i=1:maxtrys
    if ~nameok
      SaveFile=[caseID SaveTags(FileSaveN)];
      SaveFile=deblank(SaveFile);
      locs=findstr(' ',SaveFile); SaveFile(locs)='_';
      if SWXok, SaveFile=[SaveFile '.SWX']; end
  	  disp(['In PSMsave: Present caseID = ' caseID])
      disp(['In PSMsave:  SaveFile = ' SaveFile])
     %----------------------------------------------------
     % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMsave_nameok'), PSMMacro.PSMsave_nameok=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMsave_nameok))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
        nameok=promptyn('Is this ok? ','y');
    else
        nameok=PSMMacro.PSMsave_nameok;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMsave_nameok=nameok;
        else
            PSMMacro.PSMsave_nameok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------  
    
      
	  if nameok, break, end
      prompt='In PSMsave: Enter file name for saved signals: ';
	  SaveFile=input(prompt,'s');
      SaveFile=deblank(SaveFile);
      locs=findstr(' ',SaveFile); SaveFile(locs)='_';
      disp(['SaveFile name = ' SaveFile])
	  nameok=promptyn('Is this ok? ','y');
      if isempty(SaveFile), nameok=0; end
      if findstr('none',lower(SaveFile))
        disp('Return from PSMsave - save operations refused by user')
        SaveList='';
        return
      end
    end
  end
  if isempty(SaveFile), nameok=0; end
  if isempty(deblank(SaveFile)), nameok=0; end
  if ~nameok
    disp(sprintf('Sorry -%5.0i chances is all you get!',maxtrys))
    disp(['in PSMsave: Using SaveFile = ' SaveFile])
  end
end
SaveFile=deblank(SaveFile);
len=size(SaveFile,2); 
Ftype='';
dotloc=findstr(SaveFile,'.');
if isempty(dotloc), Ftype='';  
else Ftype=SaveFile(dotloc:len); 
end
%*************************************************************************

%*************************************************************************
%Abbreviated save for special data
TrimName='';
if ~isempty(findstr(SaveList,'PSMsigsX')), TrimName='PSMsigsX'; end  
if ~isempty(findstr(SaveList,'PSMsigsF')), TrimName='PSMsigsF'; end  
if isempty(TrimName)
  disp(['In PSMsave: Save to .mat file'])
  if isempty(findstr(Ftype,'.mat')), SaveFile=[SaveFile '.mat']; end 
  SaveCommand=['save ' SaveFile ' ' SaveList VNtag];
  disp(['   SaveCommand=' SaveCommand])
  disp(' ')
  keyboardok=promptyn('Do you want the keyboard? ','n');
  if keyboardok
    str1='In PSMsave: Invoking "keyboard" command:';
    disp(str2mat(str1,'  Type "return" when you are finished.'))
    keyboard
  end
  eval(SaveCommand); FileSaveN=FileSaveN+1;
  str1='In PSMsave: Data saved in file indicated below:';
  command=['strN=which(' '''' SaveFile '''' ');']; eval(command)
  nchars=length(strN);
  if nchars>80
    L=findstr('\',strN); LL=find(L<=80); L=L(max(LL));
    strN=str2mat(strN(1:L),strN(L+1:nchars));
  end
  disp(str2mat(str1,strN));
  %CaseCom=str2mat(CaseCom,str1,strN); 
  [CaseCom]=Char2Blank(CaseCom,tabchar);  %Replace tabs
  CaseComR=CaseCom; 
  command=['save ' SaveFile ' CaseComR -append' VNtag]; eval(command)
  return
end
%*************************************************************************

%Save full signal array
command=['PSMsigsFull=' TrimName ';']; eval(command);  %FIND WAY TO AVOID THIS!!

%*************************************************************************
%Set time reference & time range for data save
disp(' ')
PSMreftimesSave=PSMreftimes;
AdjRefDate=0;
if PSMreftimes(1)>0
  RefDatestr=PSM2Date(PSMreftimes(1)); 
  disp(['In PSMsave: Time reference = ' RefDatestr ])
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMsave_AdjRefDate'), PSMMacro.PSMsave_AdjRefDate=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMsave_AdjRefDate))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
        AdjRefDate=promptyn('In PSMsave: Adjust time reference?', 'n');
    else
        AdjRefDate=PSMMacro.PSMsave_AdjRefDate;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMsave_AdjRefDate=AdjRefDate;
        else
            PSMMacro.PSMsave_AdjRefDate=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------  
  
  
  if AdjRefDate
    promptAdj='Enter time reference in format 10-Aug-1996 15:48:46.133: ';
    DateString=input(promptAdj,'s');
    if isempty(DateString), DateString=RefDatestr; end
    NewTime=Date2PSM(DateString); StartDatestr=PSM2Date(NewTime); 
    disp(['  Adjusted time reference = ' StartDatestr])
    ShiftSecs=NewTime-PSMreftimes(1);
    ShiftPts=round(ShiftSecs/tstep);
    PSMreftimes=PSMreftimes+ShiftSecs;
    PSMsigsFull(:,1)=PSMsigsFull(:,1)-ShiftSecs;
    TRange=[];
  end
end
[maxpoints nsigs]=size(PSMsigsFull);
nrange=[1 maxpoints];
if ~exist('TRange'), TRange=[]; end
if isempty(TRange),  TRange=[PSMsigsFull(1,1) PSMsigsFull(maxpoints,1)]; end
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMsave_TRangeCk'), PSMMacro.PSMsave_TRangeCk=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMsave_TRangeCk))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
        TRangeCk=promptyn('In PSMsave: Verify time range?', 'n');
    else
        TRangeCk=PSMMacro.PSMsave_TRangeCk;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMsave_TRangeCk=TRangeCk;
        else
            PSMMacro.PSMsave_TRangeCk=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  

if TRangeCk
  DispSig=min(3,nsigs); maxtrys=8;
  [SaveRange,nrange,SaveRangeok]=ShowRange(PSMsigsFull,namesX,DispSig,TRange,tstep,maxtrys);
  if ~SaveRangeok
    disp(' Returning to invoking Matlab function.'); return
  end
end
%Determine save range in samples
n1=nrange(1); n2=nrange(2);
SaveTrim=n1>1|n2<maxpoints;
if SaveTrim&(~SWXok)
  if isempty(TrimName)
    n1=1; n2=maxpoints;
    disp('SORRY - SAVE TRIM FAILED.  Nonstandard SaveList shown below:')
    disp(['  ' SaveList])
    disp('  ')
    keyboardok=promptyn('Do you want the keyboard to edit SaveList? ','y');
    if keyboardok
      str1='In PSMsave: Invoking "keyboard" command:';
      disp(str2mat(str1,'  Type "return" when you are finished.'))
      keyboard
    end
  end
end
if AdjRefDate
  KeepTadj=promptyn('In PSMsave: Apply time adjustments to workspace data?', '');
  if KeepTadj
    PSMreftimesSave=PSMreftimes;
    PSMsigsFull=PSMsigsFull(n1:n2,:);
    if(abs(PSMsigsFull(1,1))<tstep/10), PSMsigsFull(1,1)=0; end 
    command=[TrimName '=PSMsigsFull;']; eval(command); 
    [maxpoints nsigs]=size(PSMsigsFull);
    n1=1; n2=maxpoints;
  end
end
%*************************************************************************

%*************************************************************************
%Test for overly long CaseComR
TrimCC=0;
CClines=size(CaseComR,1); MaxCClines=120;
if CClines>MaxCClines
  str='In PSMsave: Retrievable case processing log CaseComR exceeds ';
  str=[str sprintf('%3.0i',MaxCClines) ' lines']; disp(str)
  %----------------------------------------------------
  % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMsave_TrimCC'), PSMMacro.PSMsave_TrimCC=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMsave_TrimCC))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
        TrimCC=promptyn('Trim CaseComR to basic information? ','y');
    else
        TrimCC=PSMMacro.PSMsave_TrimCC;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMsave_TrimCC=TrimCC;
        else
            PSMMacro.PSMsave_TrimCC=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  

  
end
if TrimCC
  for L=1:CClines
    line=CaseComR(L,:);
    if ~isempty(findstr('Case Time =',line)), break, end
  end
  CC=CaseComR(1:L,:);
  CC=str2mat(CC,' ','(comments here trimmed out)',' ');
  maxpoints=size(PSMsigsX,1);
  RecStart=PSM2Date(PSMsigsX(1,1)+PSMreftimes(1)); 
  RecEnd  =PSM2Date(PSMsigsX(maxpoints,1)+PSMreftimes(1));
  S2=['Record Start Time = ' RecStart ' GMT Standard'];
  S3=['Record End Time   = ' RecEnd   ' GMT Standard'];
  CC=str2mat(CC,S2,S3);
  strs=['Size PSMsigsX = ' num2str(size(PSMsigsX))];
  strs=str2mat(strs,'Data extracted from the following files:', PSMfiles);
  AbsRefStr=PSM2Date(PSMreftimes(1));
  str=['Reference time = '];
  str=[str sprintf('%2.12e',PSMreftimes(1)) ' seconds'];
  strs=str2mat(strs,str,['Equivalent GMT standard time = ' AbsRefStr ]);
  CC=str2mat(CC,strs);
  CaseComR=CC;
end
%*************************************************************************

%*************************************************************************
%Save data to indicated .mat or .txt file
SaveTrim=n1>1|n2<maxpoints;
if SaveTrim
  str1=sprintf('Saved record trimmed to SaveRange = [ %6.2f %6.2f ] sec', SaveRange);
  disp(str1); 
  if ~isempty(findstr(TrimName,'PSMsigsX')),
    CaseComR=str2mat(CaseComR,str1); 
    PSMsigsX=PSMsigsX(n1:n2,:);
    if abs(PSMsigsX(1,1))<tstep/10, PSMsigsX(1,1)=0; end
  end  
  if ~isempty(findstr(TrimName,'PSMsigsF')),
    CaseComF=str2mat(CaseComF,str1); 
    PSMsigsF=PSMsigsF(n1:n2,:);
    if abs(PSMsigsF(1,1))<tstep/10, PSMsigsF(1,1)=0; end
  end  
end
if ~SWXok   %save to .mat file
  disp(['In PSMsave: Save to .mat file'])
  if isempty(findstr(Ftype,'.mat')), SaveFile=[SaveFile '.mat']; end 
  SaveCommand=['save ' SaveFile ' ' SaveList VNtag];
  disp(['   SaveCommand=' SaveCommand])
  disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro, 'PSMsave_keyboardok'), PSMMacro.PSMsave_keyboardok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMsave_keyboardok))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
        keyboardok=promptyn('Do you want the keyboard? ','n');
    else
        keyboardok=PSMMacro.PSMsave_keyboardok;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMsave_keyboardok=keyboardok;
        else
            PSMMacro.PSMsave_keyboardok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  

  
  if keyboardok
    str1='In PSMsave: Invoking "keyboard" command:';
    disp(str2mat(str1,'  Type "return" when you are finished.'))
    keyboard
  end
  eval(SaveCommand); FileSaveN=FileSaveN+1;
  str1='In PSMsave: Data saved in file indicated below:';
  command=['strN=which(' '''' SaveFile '''' ');']; eval(command);
  nchars=length(strN);
  if nchars>80
    L=findstr('\',strN); LL=find(L<=80); L=L(max(LL));
    strN=str2mat(strN(1:L),strN(L+1:nchars));
  end
  disp(str2mat(str1,strN));
  %CaseComR=str2mat(CaseComR,str1,strN); 
  [CaseComR]=Char2Blank(CaseComR,tabchar);  %Replace tabs
  command=['save ' SaveFile ' CaseComR -append' VNtag]; eval(command)
  CaseCom=str2mat(CaseCom,str1,strN);
  [CaseCom]=Char2Blank(CaseCom,tabchar);  %Replace tabs 
end
if SWXok  %save to .txt file
  disp(['In PSMsave: Save to .txt file']); %keyboard
  if isempty(findstr(Ftype,'.txt')), SaveFile=[SaveFile '.txt']; end
  nsigs=size(PSMsigsX,2);
  swxdata.title=caseID;
  swxdata.comments=CaseComR;
  swxdata.DateString=PSM2Date(PSMreftimes(1));
  swxdata.timestep=tstep;
  swxdata.names=namesX(1:nsigs,:);
  command=['swxdata.timdat=' TrimName '(:,1);']; eval(command)
  command=['swxdata.sigdat=' TrimName '(:,2:nsigs);']; eval(command)
  SWXwrite(SaveFile,swxdata); FileSaveN=FileSaveN+1;
  %Determine location of saved file
  str1='In PSMsave: Data saved in file indicated below:';
  command=['strN=which(' '''' SaveFile '''' ');']; eval(command)
  nchars=length(strN);
  if nchars>80
    L=findstr('\',strN); LL=find(L<=80); L=L(max(LL));
    strN=str2mat(strN(1:L),strN(L+1:nchars));
  end
  disp(str2mat(str1,strN));
  %CaseCom=str2mat(CaseCom,str1,strN);
  [CaseCom]=Char2Blank(CaseCom,tabchar);  %Replace tabs 
end
if SaveTrim, command=[TrimName '=PSMsigsFull;']; eval(command); end
%*************************************************************************

%Restore settings
PSMreftimes=PSMreftimesSave;
clear PSMsigsFull

disp('Return from PSMsave')

return


%end of PSMT utility

