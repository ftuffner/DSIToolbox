function [CaseComN,namesN,PSMsigsX,RefType,RefSigN,RefSig]...
    =PDCrefsig(caseID,CaseCom,namesX,PSMsigsX,...
     RefType,RefSigN,RefSig,tstep);
 
% PDCrefsig permits the user to select a designated reference signal for
% angle, frequency, and some other signal types.  This reference signal 
% is then subtracted from all signals of that same type.  
% WARNING  - Strings for signal types can be case sensitive!!
%  
% Intended primarily for PDC data, but can be used experimentally with
% data from other sources.
%
% [CaseComN,namesN,PSMsigsX,RefType,RefSigN,RefSig]...
%    =PDCrefsig(caseID,CaseCom,namesN,PSMsigsX,...
%    RefType,RefSigN,RefSig,tstep);
%
% Special functions used:
%	  PickList1
%   PSMunwrap
%   promptyn,promptnv
%   
% Modified 08/04/04.  jfh  Added EFreqL to menu of reference types
% Modified 10/18/2006  Ning Zhou, Added macro function

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
%keyboard
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

 
if 0
    keyboard
    save Debug_05
   
elseif 0
    clear all 
    close all
    clc
    load Debug_05
    funLoadMacro()
    PSMMacro.RunMode=1;  %run macro
%    PSMMacro.RunMode=0;  %record macro
%    PSMMacro.RunMode=-1; %normal orperation
end
 
if ~exist('RefType'), RefType=''; end
if ~exist('RefSigN'), RefSigN=[]; end
if ~exist('RefSig'),  RefSig=[];  end
if ~exist('tstep'),   tstep=[];   end

disp(' ')
disp('In PDCrefsig:')

CaseComN=CaseCom; namesN=namesX;
RefSig=[];
[maxpts nsigs]=size(PSMsigsX); %PSMsigsX is array of PSM Signals

%************************************************************************
AngType='AngL';
DifNype=0; EstFrqTag='';

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PDCrefsig_EstFrq'), PSMMacro.PDCrefsig_EstFrq=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCrefsig_EstFrq))      % Not in Macro playing mode or selection not defined in a macro
    EstFrq=promptyn(['In PDCrefsig: Estimate frequencies from ' AngType ' signals? '],'');
else
    EstFrq=PSMMacro.PDCrefsig_EstFrq;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PDCrefsig_EstFrq=EstFrq;
    else
        PSMMacro.PDCrefsig_EstFrq=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%EstFrq=promptyn(['In PDCrefsig: Estimate frequencies from ' AngType ' signals? '],'');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------




if EstFrq
  if isempty(tstep)
    disp('No value for tstep -- estimation supressed')
    EstFrq=0;
  else
    UnWrap=1; Efq=zeros(maxpts,1); Elocs=2:(maxpts-1);
    DiftypesN=str2mat('Central Difference','Backward Difference','Forward Difference');
    EstFrqTags=str2mat('_CD','_BD','_FD');
    DifNtype=3; locbase=1; maxtrys=5;
    
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PDCrefsig_DifTypeok'), PSMMacro.PDCrefsig_DifTypeok=NaN; end
    if ~isfield(PSMMacro, 'PDCrefsig_DifType'), PSMMacro.PDCrefsig_DifType=NaN; end
    if ~isfield(PSMMacro, 'PDCrefsig_DifNype'), PSMMacro.PDCrefsig_DifNype=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCrefsig_DifTypeok))      % Not in Macro playing mode or selection not defined in a macro
        [DifNype,DifType,DifTypeok]=PickList1(DiftypesN,DifNtype,locbase,maxtrys);
    else
        DifTypeok=PSMMacro.PDCrefsig_DifTypeok;
        DifType=PSMMacro.PDCrefsig_DifType;
        DifNype=PSMMacro.PDCrefsig_DifNype;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCrefsig_DifTypeok=DifTypeok;
            PSMMacro.PDCrefsig_DifType=DifType;
            PSMMacro.PDCrefsig_DifNype=DifNype;
        else
            PSMMacro.PDCrefsig_DifTypeok=NaN;
            PSMMacro.PDCrefsig_DifType=NaN;
            PSMMacro.PDCrefsig_DifNype=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % [DifNype,DifType,DifTypeok]=PickList1(DiftypesN,DifNtype,locbase,maxtrys);
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
    
    
    
    disp(['In PDCrefsig: Estimating frequencies with ' DiftypesN(DifNype,:) ' logic'])
    disp('    WARNING: No outlier controls yet')
    EstFrqTag=EstFrqTags(DifNype,:);
  end
end
if ~EstFrq
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PDCrefsig_UnWrap'), PSMMacro.PDCrefsig_UnWrap=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCrefsig_UnWrap))      % Not in Macro playing mode or selection not defined in a macro
        UnWrap=promptyn(['In PDCrefsig: Unwrap ' AngType ' signals? '],'');
    else
        UnWrap=PSMMacro.PDCrefsig_UnWrap;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCrefsig_UnWrap=UnWrap;
        else
            PSMMacro.PDCrefsig_UnWrap=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % UnWrap=promptyn(['In PDCrefsig: Unwrap ' AngType ' signals? '],'');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
end
%************************************************************************

%************************************************************************
%Phase unwrapping & Frequency estimation 
[lines chars]=size(namesN);
if UnWrap
  for N=1:lines  %Scan for angle signals
    teststr=[namesN(N,:)];
    Ltest=findstr(AngType,teststr);
    if ~isempty(Ltest)
      disp(['  Unwrapping ' teststr]) 
      PSMsigsX(:,N)=PSMunwrap(PSMsigsX(:,N));
      if EstFrq %Frequency estimation logic
        if DifNype==1 %central diference
          Efq(Elocs)=(PSMsigsX(Elocs+1,N)-PSMsigsX(Elocs-1,N))/(2*tstep*360)+60; 
          Efq(1)=Efq(2); Efq(maxpts)=Efq(maxpts-1);
        end
        if DifNype==2  %backward diference
          Efq(Elocs)=(PSMsigsX(Elocs,N)-PSMsigsX(Elocs-1,N))/(tstep*360)+60; 
          Efq(1)=Efq(2); Efq(maxpts)=Efq(maxpts-1);
        end
        if DifNype==3  %forward diference
          Efq(Elocs)=(PSMsigsX(Elocs+1,N)-PSMsigsX(Elocs,N))/(tstep*360)+60; 
          Efq(1)=Efq(2); Efq(maxpts)=Efq(maxpts-1);
        end 
        PSMsigsX=[PSMsigsX Efq];
        teststr=[teststr(1:(Ltest-3)) 'EFreqL' EstFrqTag];
        namesN=str2mat(namesN,teststr);    
      end
    end
  end
end
%************************************************************************

prompt=['In PDCrefsig: Determine relative angles & frequencies? Else return '];

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PDCrefsig_setok'), PSMMacro.PDCrefsig_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCrefsig_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn(prompt,'y');
else
    setok=PSMMacro.PDCrefsig_setok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PDCrefsig_setok=setok;
    else
        PSMMacro.PDCrefsig_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% setok=promptyn(prompt,'y');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if ~setok, return, end

%************************************************************************
%Determine reference signal type
RefType=deblank(RefType); %keyboard
%PDC signal types
RefTypes=str2mat('VAng','IAng','Freq','VAngL','IAngL','FreqL');
RefTypes=str2mat(RefTypes,'VAngA','IAngA','FreqA','VAngR','IAngR','FreqR');
RefTypes=str2mat(RefTypes,'VAngLX','IAngLX','FreqLX');
RefTypes=str2mat(RefTypes,'EFreqL_CD','EFreqL_BD','EFreqL_FD');
%NtypesG=size(RefTypes,1);
%PSLF signal types
RefTypes=str2mat(RefTypes,'Gang','Gfrq');
%PTI signal types
RefTypes=str2mat(RefTypes,'ANGL ','FREQ ','SPD  ');
NtypesG=size(RefTypes,1);
RefTypes=str2mat(RefTypes,'special type','none');
Ntypes=size(RefTypes,1); 
%names2chans(RefTypes)
%names2chans(namesN)
TypesLoc=1:Ntypes;
[lines chars]=size(namesN);
GPSlost=[];
for I=1:NtypesG
  RefTypeI=deblank(RefTypes(I,:));
  RsigsIN=[];
  for N=1:lines
    teststr=[namesN(N,:) ' '];
    Ltest=findstr(RefTypeI,teststr);
    if ~isempty(Ltest)
      teststrE=teststr(Ltest+length(RefTypeI));
      testB=strcmp(teststrE,' ');
      if testB
        if N==1, RsigsIN=N;
        else RsigsIN=[RsigsIN N];
        end
      end
      teststrX=teststr(Ltest:(Ltest+length(RefTypeI)));
      GPStest1=~isempty(strmatch('vanglx',lower(teststrX)));
      GPStest2=~isempty(strmatch('ianglx',lower(teststrX)));
      GPStest3=~isempty(strmatch('freqlx',lower(teststrX)));
      GPStest=GPStest1|GPStest2|GPStest3;
      if GPStest
        if isempty(GPSlost), disp('In PDCrefsig: GPS synch lost for signal'); end
        disp(['  ' namesN(N,:)])
        GPSlost=[GPSlost N];
      end     
    end
  end
  if length(RsigsIN)<2, TypesLoc(I)=0; end
end
TypesLocN=find(TypesLoc>0);
RefTypesN=RefTypes(TypesLocN,:);
NtypesN=size(RefTypesN,1);
RefNtype=0; SpecialType=0;
if ~isempty(RefType)
  for N=1:NtypesN
    teststr=[deblank(RefTypesN(N,:)) ' '];
    Ltest=findstr(RefType,teststr);
    if ~isempty(Ltest) 
      test=strcmp(teststr(Ltest+length(RefType)),' ');
      if test, RefNtype=N; break, end
    end
  end
end
if RefNtype==0, RefNtype=1; end
RefType=deblank(RefTypesN(RefNtype,:));
disp(' ')
disp(['In PDCrefsig: Initial signal type for referencing is RefType=' RefType])
disp( '   WARNING  - Strings for signal types can be case sensitive')
locbase=1; maxtrys=5;

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PDCrefsig_RefTypeok'), PSMMacro.PDCrefsig_RefTypeok=NaN; end
if ~isfield(PSMMacro, 'PDCrefsig_RefType'), PSMMacro.PDCrefsig_RefType=NaN; end
if ~isfield(PSMMacro, 'PDCrefsig_RefNype'), PSMMacro.PDCrefsig_RefNype=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCrefsig_RefTypeok))      % Not in Macro playing mode or selection not defined in a macro
    [RefNype,RefType,RefTypeok]=PickList1(RefTypesN,RefNtype,locbase,maxtrys);
else
    RefTypeok=PSMMacro.PDCrefsig_RefTypeok;
    RefType=PSMMacro.PDCrefsig_RefType;
    RefNype=PSMMacro.PDCrefsig_RefNype;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PDCrefsig_RefTypeok=RefTypeok;
        PSMMacro.PDCrefsig_RefType=RefType;
        PSMMacro.PDCrefsig_RefNype=RefNype;
    else
        PSMMacro.PDCrefsig_RefTypeok=NaN;
        PSMMacro.PDCrefsig_RefType=NaN;
        PSMMacro.PDCrefsig_RefNype=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% [RefNype,RefType,RefTypeok]=PickList1(RefTypesN,RefNtype,locbase,maxtrys);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if ~RefTypeok
  disp( 'In PDCrefsig: Signal referencing type not determined')
  disp(['              PSM type = ' PSMtype]) 
  RefType='NONE';
  return
end
if findstr('special type',lower(RefType))
  SpecialType=1;
  disp('In PDCrefsig: Special reference type has been requested')
  SpclTag=input(['Enter tag for special type signal (else return) '],'s');
  if ~isempty(SpclTag), RefType=SpclTag; end
end
%************************************************************************

%************************************************************************
%Determine reference signal and signals to change
RefType=deblank(RefType);
RsigsN=[];
[lines chars]=size(namesN);
for N=1:lines
  teststr=[namesN(N,:) ' '];
  Ltest=findstr(RefType,teststr);
  if ~isempty(Ltest)
    teststrE=teststr(Ltest+length(RefType));
    test=strcmp(teststrE,' ');
    if test
      if N==1, RsigsN=N;
      else RsigsN=[RsigsN N];
      end
    end
    GPStest=strcmp(teststrE,'X');
    if GPStest
      disp('In PDCrefsig: GPS synch lost for signal')
      disp(['  ' namesN(N,:)])
      useok=promptyn('Include among referenced signals? ','');
      if useok
        if N==1, RsigsN=N;
        else RsigsN=[RsigsN N];
        end
      end
    end     
  end
end
if isempty(RsigsN)
  disp(['In PDCrefsig: No signals of type ' RefType])
  
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/08/07
    if ~isfield(PSMMacro, 'PDCrefsig_keybdok'), PSMMacro.PDCrefsig_keybdok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCrefsig_keybdok))      % Not in Macro playing mode or selection not defined in a macro
        keybdok=promptyn(['Do you want the keyboard? '], '');
    else
        keybdok=PSMMacro.PDCrefsig_keybdok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCrefsig_keybdok=keybdok;
        else
            PSMMacro.PDCrefsig_keybdok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % keybdok=promptyn(['Do you want the keyboard? '], '');
    % End: Macro selection ZN 02/08/07
    %----------------------------------------------------
  
  
  
  if keybdok
    disp('In PDCrefsig: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  else
    RefType='NONE';
    return
  end
end
if length(RsigsN)==1
  disp(['In PDCrefsig: Just 1 signal of type ' RefType ' - Returning'])
  RefType='NONE';
  return
end
disp(' ')
disp(['In PDCrefsig: Select reference signal of type ' RefType])
locbase=1; maxtrys=5;
RefSigN=RsigsN(1);
options=str2mat(namesN(RsigsN,:), 'none'); InPick=1;

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PDCrefsig_refok'), PSMMacro.PDCrefsig_refok=NaN; end
if ~isfield(PSMMacro, 'PDCrefsig_RefName'), PSMMacro.PDCrefsig_RefName=NaN; end
if ~isfield(PSMMacro, 'PDCrefsig_RefSigN'), PSMMacro.PDCrefsig_RefSigN=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCrefsig_refok))      % Not in Macro playing mode or selection not defined in a macro
    [RefSigN,RefName,refok]=PickList1(options,InPick,locbase,maxtrys,RsigsN);
else
    refok=PSMMacro.PDCrefsig_refok;
    RefName=PSMMacro.PDCrefsig_RefName;
    RefSigN=PSMMacro.PDCrefsig_RefSigN;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PDCrefsig_refok=refok;
        PSMMacro.PDCrefsig_RefName=RefName;
        PSMMacro.PDCrefsig_RefSigN=RefSigN;
    else
        PSMMacro.PDCrefsig_refok=NaN;
        PSMMacro.PDCrefsig_RefName=NaN;
        PSMMacro.PDCrefsig_RefSigN=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% [RefSigN,RefName,refok]=PickList1(options,InPick,locbase,maxtrys,RsigsN);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if findstr('none',lower(RefName)), refok=0; end
if ~refok
  RefType='NONE'; 
  return
end
RefSigN=RsigsN(RefSigN);
str1=[sprintf('Reference = %5.2i   ', RefSigN) RefName];
disp(str1)
CaseComS=str2mat(CaseCom,str1);
%************************************************************************

%************************************************************************
%Determine how to ammend names for referenced signals
RefNtypeS=0; appok=0; TagInc=0; %keyboard
str=deblank(lower(RefType));
LastChar=str(length(str));
if ~strcmp(LastChar,'l')
  TagInc=1;
end
if SpecialType
  for N=1:Ntypes
    teststr=[deblank(lower(RefTypes(N,:))) ' '];
    Ltest=findstr(lower(RefType),teststr);
    if ~isempty(Ltest) 
      test=strcmp(teststr(Ltest+length(RefType)),' ');
      if test, RefNtypeS=N; break, end
    end
  end
  if RefNtypeS==0
    disp(['  Signal type ' RefType ' is not a variation from the standard list -'])
    disp( '  Referenced signals will be appended at the end of signal array')
    appok=1; TagInc=1;
  end 
end
%************************************************************************

%************************************************************************
%Determine where to place referenced signals
if ~appok
  disp(' ')
  str='Referenced signals can overstore original signals, ';
  str=str2mat(str,'or else be appended at end of signal array:');
  disp(str)
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PDCrefsig_appok'), PSMMacro.PDCrefsig_appok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCrefsig_appok))      % Not in Macro playing mode or selection not defined in a macro
        appok=promptyn('Append referenced signals at end of signal array? ','y');
    else
        appok=PSMMacro.PDCrefsig_appok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCrefsig_appok=appok;
        else
            PSMMacro.PDCrefsig_appok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % appok=promptyn('Append referenced signals at end of signal array? ','y');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
end
%************************************************************************

%************************************************************************
%Determine relative angles or frequencies
RefType=deblank(RefType);
disp(' ')
str1=[RefType ' reference     = ' RefName];
disp(['In PDCrefsig: ' str1]); 
CaseComN=str2mat(CaseComN,str1);
RefSig=PSMsigsX(:,RefSigN);
tagL=length(deblank(RefType)); %keyboard
%testL=findstr('X',RefType);
L=max(findstr(RefType,RefName));
Loc=L+tagL-1+TagInc;
RefName(Loc)='A';  %Indicate absolute quantity
if appok %Append absolute reference signal
  PSMsigsX=[PSMsigsX,RefSig];
  namesN=str2mat(namesN,RefName);
else
  PSMsigsX(:,RefSigN)=RefSig;
  namesN(RefSigN,:)=RefName;
end
str1=num2str(length(RsigsN));
disp(['In PDCrefsig: ' str1 ' signals to reference']) 
for n=1:length(RsigsN)
  N=RsigsN(n);
  strN=namesN(N,:);
  disp(['In PDCrefsig: ' RefType ' referencing for ' strN])
  PSMsigR=PSMsigsX(:,N)-RefSig;
  %Unwrap & shift angles
  if ~isempty(findstr('Ang',namesN(N,:)))
    [PSMsigR]=PSMunwrap(PSMsigR,1);
    LW=1:10; WMax=max(abs(PSMsigR(LW))); 
    LWM=find(abs(PSMsigR(LW))==WMax); LWM=LWM(1);
    wraps=round(PSMsigR(LWM)/360);
    %disp([num2str(max(PSMsigR(LW))) ' ' num2str(min(PSMsigR(LW))) ' ' num2str(wraps)])
    PSMsigR=PSMsigR-wraps*360;
    if max(PSMsigR(LW))<0,    PSMsigR=PSMsigR+360; end
    if max(PSMsigR(LW))>185,  PSMsigR=PSMsigR-360; end
    %disp([num2str(max(PSMsigR(LW))) ' ' num2str(min(PSMsigR(LW)))])
  end
  L=max(findstr(RefType,strN));
  Loc=L+tagL-1+TagInc;
  strN(Loc)='R';  %Indicate relative quantity
  if appok
    PSMsigsX=[PSMsigsX,PSMsigR];
    namesN=str2mat(namesN,strN);
  else  
    PSMsigsX(:,N)=PSMsigR;
    namesN(N,:)=strN;
  end
end
%************************************************************************

%end of PSMT utility