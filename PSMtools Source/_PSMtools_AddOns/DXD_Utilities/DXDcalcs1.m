 function [CaseCom,DXDnames,tstepD,DXDsigsX,DXDpars]=...
             DXDcalcs1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
             tstep,PSMfiles);
        
% Applies digital transducer (DXD) processing to point-on-wave signals 
%
% [CaseCom,DXDnames,tstepD,DXDsigs,DXDpars]=...
%    DXDcalcs1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%    tstep,PSMfiles);
%
% Rows of FilPars contain [FilType,HPfrq,LPfrq,FiltOrd,decfac]
% Use FilType 1,2,3 for 'LP', 'BP', and 'HP' filters
% Zero value for FilType produces null filter (gain==1)
% Decimation follows filtering
%
% NOTE: Phasors rotated & scaled for rough match to conventions 
% of Macrodyne PMU, as determine from Olinda data of 03/27/93 
% 
% Special functions called:
%   DXDmod1
%   BstringOut
%   promptyn
%   DXDcplots
%
% Last modified 08/01/05.  jfh
%  Modified 10/18/2006  by Ning Zhou to add macro function

% By J. F. Hauer, Pacific Northwest National Laboratory.
% Modified 10/18/2006  by Ning Zhou to add macro function

%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%Initialize outputs

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

if 0
    keyboard
    save Debug_12
elseif 0
    clear all 
    close all
    clc
    load Debug_12
    funLoadMacro()
    PSMMacro.RunMode=1;  %run macro
%     PSMMacro.RunMode=0;  %record macro
%    PSMMacro.RunMode=-1; %normal orperation
end


DXDnames=''; 
tstepD=tstep; DXDsigsX=[]; DXDpars=[];

disp(' ')
CSname='DXDcalcs1';
disp(['In ' CSname ': Phasor Calculations'])

%Initialize plot headers
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '    casetime=' casetime];

[namesX]=BstringOut(namesX,' ',2);  %Delete extra blanks

%*************************************************************************
%Determine signals for phasor calculations
chankeyX=names2chans(namesX);
[maxpoints nsigs]=size(PSMsigsX);
samplerate=1/tstep;
str1=['In ' CSname ': Phasor Calculations'];
str2=sprintf('Initial samplerate = %5.3f', samplerate);
strs=str2mat(str1,str2); disp(strs)
CaseCom=str2mat(CaseCom,strs);
LocVsigs=[]; LocIsigs=[];
if nsigs==2,LocVsigs=2;   LocIsigs=[] ; end
if nsigs==3,LocVsigs=2;   LocIsigs=3  ; end
if nsigs==4,LocVsigs=2:4; LocIsigs=[] ; end
if nsigs>=7,LocVsigs=2:4; LocIsigs=5:7; end
disp('Signals available:')
disp(chankeyX)
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'DXDcalcs1_LocVsigs'), PSMMacro.DXDcalcs1_LocVsigs=NaN; end
if ~isfield(PSMMacro, 'DXDcalcs1_LocIsigs'), PSMMacro.DXDcalcs1_LocIsigs=NaN; end
if ~isfield(PSMMacro, 'DXDcalcs1_keybdok'), PSMMacro.DXDcalcs1_keybdok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_keybdok))      % Not in Macro playing mode or selection not defined in a macro
    disp('Signals indicted for processing:');
    disp(['Voltage signals: LocVsigs = ' num2str(LocVsigs)])
    if ~isempty(LocVsigs), disp(chankeyX(LocVsigs,:)), end
    disp(['Current signals: LocIsigs = ' num2str(LocIsigs)])
    if ~isempty(LocIsigs), disp(chankeyX(LocIsigs,:)), end
    keybdok=~promptyn('Are these the signals to process? ', 'y');
    if keybdok
      disp('  Invoking "keyboard" command - Enter "return" when you are finished')
      disp('  EXAMPLE:  LocVsigs=[2 3 4]; LocIsigs=[5 6 7]; return')
      keyboard
      %LocVsigs=[2 3]; LocIsigs=[4 5];
    end
else
    LocVsigs=PSMMacro.DXDcalcs1_LocVsigs;
    LocIsigs=PSMMacro.DXDcalcs1_LocIsigs;
    keybdok=PSMMacro.DXDcalcs1_keybdok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.DXDcalcs1_LocVsigs=LocVsigs;
        PSMMacro.DXDcalcs1_LocIsigs=LocIsigs;
        PSMMacro.DXDcalcs1_keybdok=keybdok;
    else
        PSMMacro.DXDcalcs1_LocVsigs=NaN;
        PSMMacro.DXDcalcs1_LocIsigs=NaN;
        PSMMacro.DXDcalcs1_keybdok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%---------------------------------------------------

   
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'DXDcalcs1_PMUcalcs'), PSMMacro.DXDcalcs1_PMUcalcs=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_PMUcalcs))      % Not in Macro playing mode or selection not defined in a macro
    PMUcalcs=~promptyn(['Are these signals phasor components? '], 'n');
else
    PMUcalcs=PSMMacro.DXDcalcs1_PMUcalcs;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.DXDcalcs1_PMUcalcs=PMUcalcs;
    else
        PSMMacro.DXDcalcs1_PMUcalcs=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%PMUcalcs=~promptyn(['Are these signals phasor components? '], 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if ~PMUcalcs
  strs=['In ' CSname ': Provided signals are phasor components - No PMU calculations'];
  VPhsr=[]; IPhsr=[];
  if ~isempty(LocVsigs)
    if length(LocVsigs)~=2
      disp('Bad value for LocVsigs - phasors must have two elements')
      disp(['LocVsigs = ' num2str(LocVsigs) ' -- good luck!'])
      return
    end
    VPhsr=PSMsigsX(:,LocVsigs);
  end
  if ~isempty(LocIsigs)
    if length(LocVsigs)~=2
      disp('Bad value for LocVsigs - phasors must have two elements')
      disp(['LocVsigs = ' num2str(LocVsigs) ' -- good luck!'])
      return
    end
    IPhsr=PSMsigsX(:,LocIsigs);
  end
else
  strs=['In ' CSname ': Provided signals are point-on-wave - Will do PMU calculations'];
end
disp(strs);
CaseCom=str2mat(CaseCom,strs);
%*************************************************************************

%Default parameters -- need interactive entry
i=sqrt(-1); r2deg=180/pi;   %Radians to degrees
KVfac=1; KAfac=1; MWfac=1;

%*************************************************************************
%Define phasor calculation logic
if PMUcalcs
strs=['In ' CSname ': Start of PMU calculations'];
disp(strs);
CaseCom=str2mat(CaseCom,strs);
str1='Rows of FilPars contain [FilType,HPfrq,LPfrq,FiltOrd,decfac]';
str2='Use FilType 1,2,3,4 for LP,BP,HP,BX filters';
str3='Zero value for FilType produces null filter (gain==1)';
str4='Decimation follows filtering';
strsA=str2mat(str1,str2,str3,str4);
disp(' ')
disp(strsA)
FilPars=[]; DXDsigsX=[];
%Expected sample rate=12 per cycle=720 sps
disp(' ')
disp(['Sample rate for input  signal = ' num2str(samplerate)])
disp('Menu for DXD filter parameters:')
FPS=       (    '[0  0    0 1  1; 0 0  0  0  1; 0 0  0  0  1]; %PMU_RawData  ');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 60  1  4; 0 0  0  1 24]; %PMU_Box1X30F ');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 60  1  4; 0 0  0  1 12]; %PMU_Box1X60F ');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 15  1  4; 0 0  0  1 24]; %PMU_Box4X30F ');
FPS=str2mat(FPS,'[0  0    0 1  4; 4 0 15  1  1; 0 0  0  1 24]; %PMU_Box4X30  ');
FPS=str2mat(FPS,'[0  0    0 1  4; 4 0 60  1  1; 4 0 15  1 24]; %PMU_Box1X4X30');
FPS=str2mat(FPS,'[0  0    0 1  4; 4 0 60  1  1; 4 0 15  1 12]; %PMU_Box1X4X60');
FPS=str2mat(FPS,'[0  0    0 1  4; 0 0 60  1  1; 0 0 15  1 24]; %PMU_Box0X30  ');
FPS=str2mat(FPS,'[0  0    0 1  4; 0 0 60  1  1; 0 0 15  1 12]; %PMU_Box0X60  ');
FPS=str2mat(FPS,'[0  0    0 1  4; 0 0 60  1  1; 0 0 15  1 01]; %PMU_Box0X720 ');
FPS=str2mat(FPS,'[0  0    0 1  4; 4 0 140 1  1; 0 0 15  1  2]; %PMU_Box140HzX360');
FPS=str2mat(FPS,'[0  0    0 1  4; 4 0 140 1  1; 0 0 15  1 24]; %PMU_Box140HzX30 ');
FPS=str2mat(FPS,'[6  0    0 1  4; 0 0  0  1  1; 0 0 15  1  2]; %PMU_Imp100HzX360');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 100 4  1; 0 0 15  1 12; 100 0 0 0 0]; %PMU_Box100HzX30_100');
FPS=str2mat(FPS,'[0  0    0 1  4; 4 0 60  1  1; 0 0  0  1  1]; %Olinda_720');
FPS=str2mat(FPS,'[0  0    0 1  4; 4 0 60  1  1; 1 0  0  1 24]; %Olinda_30 ');
FPS=str2mat(FPS,'[0  0    0 1  2; 4 0 60  1  4; 0 0  0  0  1]; %Olinda_5KPMU0');
FPS=str2mat(FPS,'[0  0    0 1  2; 4 0 60  1  4; 0 0  0  0 20]; %Olinda_5KPMU1');
FPS=str2mat(FPS,'[0  0    0 1  1; 1 0 10  4 32; 0 0  0  0  1]; %LADWP_2048A');
FPS=str2mat(FPS,'[0  0    0 1  4; 1 0  5  6  1; 0 0 12  6 24]; %PMU_Btr6X5X30');
FPS=str2mat(FPS,'[0  0    0 1  4; 1 0 10  6  1; 0 0 12  6 24]; %PMU_Btr6X10X30');
FPS=str2mat(FPS,'[0  0    0 1  4; 1 0 10  6  1; 0 0 12  6 12]; %PMU_Btr6X10X60');
FPS=str2mat(FPS,'[0  0    0 1  4; 1 0 15  6  1; 0 0 12  6 12]; %PMU_Btr6X15X60');
FPS=str2mat(FPS,'[0  0    0 1  4; 1 0 20  6  1; 0 0 12  6 12]; %PMU_Btr6X20X60');
FPS=str2mat(FPS,'[0  0    0 1  4; 4 0 60  1  1; 1 0 10  4 12]; %PMU_Box1XBtr4X10X60');
FPS=str2mat(FPS,'[0  0    0 1  4; 4 0 60  1  1; 1 0 15  4 12]; %PMU_Box1XBtr4X15X60');
FPS=str2mat(FPS,'[0  0    0 4  4; 5 0 20  6  1; 0 0 12  6 12]; %PMU_HsincX20X60');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 20  1  4; 1 0 18  4 36]; %SEL_Box20Btr4X18X20');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 60  1  4; 1 0 08  6 36]; %SEL_Box60Btr6X08X20');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 60  1  4; 1 0 12  6  1]; %SEL_Box60Btr6X12X720');
FPS=str2mat(FPS,'[2 45   85 4  1; 1 0 25  4  1; 1 0 25  4 24]; %Wide band30');
FPS=str2mat(FPS,'[2 40   80 4  1; 1 0 05  6  1; 1 0 02  6 24]; %Narrow band');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 15  1  1; 0 0  0  1 24]; %CRC_Box4X30');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 30  1  1; 0 0  0  1 12]; %CRC_Box2X60');
FPS=str2mat(FPS,'[0  0    0 1  1; 1 0 10  6  1; 0 0  0  1 12]; %CRC_Btr6X10X60');
FPS=str2mat(FPS,'[0  0    0 1  1; 0 0 30  1  1; 0 0  0  1  1]; %CRC_No filter/decimation');
FPS=str2mat(FPS,'[0  0    0 1  1; 0 0 30  1  1; 0 0  0  1 12]; %CRC_Decimation only');
FPS=str2mat(FPS,'[0  0    0 1  1; 0 0 30  1  1; 0 0  0  1 24]; %CRC_Decimation only');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 60  1  4; 1 0 12  6 24]; %SEL_Box60Btr6X12X30');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 60  1  1; 0 0  0  1 100];%PMU_Box1X60_2kspsX20');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 60  1  1; 0 0  0  1 40]; %PMU_Box1X60_2kspsX50');
FPS=str2mat(FPS,'[0  0    0 1  1; 4 0 60  1  1; 0 0  0  1 20]; %PMU_Box1X60_2kspsX100');
FPS=str2mat(FPS,'[0  0    0 1  1; 1 0 20  6  1; 0 0  0  1 10]; %PMU_Btr6X20_2kspsX200');
SigPars=[0;0;0];
FPStype=1; locbase=0; maxtrys=5;

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'DXDcalcs1_FPSTtypeok'), PSMMacro.DXDcalcs1_FPSTtypeok=NaN; end
if ~isfield(PSMMacro, 'DXDcalcs1_FPSstr'), PSMMacro.DXDcalcs1_FPSstr=NaN; end
if ~isfield(PSMMacro, 'DXDcalcs1_FPStype'), PSMMacro.DXDcalcs1_FPStype=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_FPSTtypeok))      % Not in Macro playing mode or selection not defined in a macro
    [FPStype,FPSstr,FPSTtypeok]=PickList1(FPS,FPStype,locbase,maxtrys);
else
    FPSTtypeok=PSMMacro.DXDcalcs1_FPSTtypeok;
    FPSstr=PSMMacro.DXDcalcs1_FPSstr;
    FPStype=PSMMacro.DXDcalcs1_FPStype;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.DXDcalcs1_FPSTtypeok=FPSTtypeok;
        PSMMacro.DXDcalcs1_FPSstr=FPSstr;
        PSMMacro.DXDcalcs1_FPStype=FPStype;
    else
        PSMMacro.DXDcalcs1_FPSTtypeok=NaN;
        PSMMacro.DXDcalcs1_FPSstr=NaN;
        PSMMacro.DXDcalcs1_FPStype=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% [FPStype,FPSstr,FPSTtypeok]=PickList1(FPS,FPStype,locbase,maxtrys);
% End: Macro selection ZN 10/18/06
%---------------------------------------------------



FPcommand=['FilPars=' FPSstr]; eval(FPcommand)
for FPN=1:3,FilPars(FPN,5)=max(FilPars(FPN,5),1); end
FilParsE=FilPars;
if size(FilPars,1)<4
  FilParsE=[FilPars;zeros(1,5)]; FilParsE(4,1)=60; %Reference freqs
end
PMUtrack=[0 0 0];

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'DXDcalcs1_trackok'), PSMMacro.DXDcalcs1_trackok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_trackok))      % Not in Macro playing mode or selection not defined in a macro
    trackok=promptyn(['In ' CSname ': Track Phasor calculations? '], 'n');
else
    trackok=PSMMacro.DXDcalcs1_trackok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.DXDcalcs1_trackok=trackok;
    else
        PSMMacro.DXDcalcs1_trackok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%trackok=promptyn(['In ' CSname ': Track Phasor calculations? '], 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if trackok, PMUtrack=[1 0 1]; 
else
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'DXDcalcs1_trackok02'), PSMMacro.DXDcalcs1_trackok02=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_trackok02))      % Not in Macro playing mode or selection not defined in a macro
        trackok=promptyn(['In ' CSname ': Track Filter calculations? '], 'n');
    else
        trackok=PSMMacro.DXDcalcs1_trackok02;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.DXDcalcs1_trackok02=trackok;
        else
            PSMMacro.DXDcalcs1_trackok02=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %trackok=promptyn(['In ' CSname ': Track Filter calculations? '], 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
    
    
    if trackok, PMUtrack=[1 0 0]; end 
end
if sum(PMUtrack)==0
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'DXDcalcs1_trackok03'), PSMMacro.DXDcalcs1_trackok03=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_trackok03))      % Not in Macro playing mode or selection not defined in a macro
       trackok=promptyn(['In ' CSname ': Track Filter step response? '], 'n');
    else
        trackok=PSMMacro.DXDcalcs1_trackok03;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.DXDcalcs1_trackok03=trackok;
        else
            PSMMacro.DXDcalcs1_trackok03=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %    trackok=promptyn(['In ' CSname ': Track Filter step response? '], 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
  
    if trackok, PMUtrack=[0 1 0]; end
end
str1='DXD Filter Parameters:'; 
str2=FPcommand;
str3=['PMUtrack=[' num2str(PMUtrack) ']']; 
disp(str1); disp(str2); disp(str3)
disp('FilParsE='); disp(FilParsE)
samplerate=round(1/tstep); Outrate=samplerate;
for FPN=1:3,Outrate=Outrate/FilPars(FPN,5); end
disp(['Sample rate for input  signal = ' num2str(samplerate)])
disp(['Sample rate for output signal = ' num2str(Outrate)])

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'DXDcalcs1_keybdok03'), PSMMacro.DXDcalcs1_keybdok03=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_keybdok03))      % Not in Macro playing mode or selection not defined in a macro
    keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
    if keybdok
      disp('  Invoking "keyboard" command - Enter "return" when you are finished')
      keyboard
    end
else
    keybdok=PSMMacro.DXDcalcs1_keybdok03;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.DXDcalcs1_keybdok03=keybdok;
    else
        PSMMacro.DXDcalcs1_keybdok03=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

FPstring=['FilPars=['];
for n=1:3
  str=num2str(FilPars(n,1:5)); str(findstr('  ',str))=''; 
  FPstring=[FPstring str];
  if n<3,FPstring=[FPstring ';']; end
end; FPstring=[FPstring,'];']; 
strs=str2mat('PMU Calculations:',FPstring);
str=['RefFrqs=[' num2str(FilParsE(4,:)) ']'];
strs=str2mat(strs,str);
CaseCom=str2mat(CaseCom,strs); disp(strs)
end  %Termination of PMU definition
%*************************************************************************

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'DXDcalcs1_CplotCase'), PSMMacro.DXDcalcs1_CplotCase=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_CplotCase))      % Not in Macro playing mode or selection not defined in a macro
    CplotCase=promptyn(['Is this a circle-plot case? '], 'n');
else
    CplotCase=PSMMacro.DXDcalcs1_CplotCase;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.DXDcalcs1_CplotCase=CplotCase;
    else
        PSMMacro.DXDcalcs1_CplotCase=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%CplotCase=promptyn(['Is this a circle-plot case? '], 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if CplotCase
  keyboard
  [CaseCom,RMSnames]=DXDcplots(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     SigPars,FilPars,PMUtrack,tstep,PSMfiles,PMUcalcs);
  CplotCase
  keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
  return
end

%*************************************************************************
%Calculate phasors from point-on-wave data
if PMUcalcs  %Start of PMU calculations
VPhsr=[];
if ~isempty(LocVsigs)  %Calculate voltage phasor
  Gtags=str2mat(caseID,casetime); 
  FiltTime=[]; %Filter settling time
  [VPhsr,tstepD,FiltTime]...
    =DXDmod1(PSMsigsX(:,LocVsigs),tstep,SigPars,FilPars,PMUtrack,Gtags);
  %VPhsr=VPhsr/sqrt(3); if length(LocVsigs)==3, VPhsr=VPhsr*3; end 
  PMUtrack=[0 0 0]; DXDpars=FilPars;
  maxpts=size(VPhsr,1);
  timeD=[0:maxpts-1]'*tstepD;
  %figure; plot(timeD,VPhsr(:,1))
  if isempty(FiltTime), FiltTime=0.5; end
  loc=min(ceil(FiltTime/tstepD),maxpts-1);
  if loc>0
    StartTime=timeD(loc+1);
    str1=['In ' CSname ': Suppressing DXD filter transient in voltage phasor'];
    str2=['  Filter settling time       = ' num2str(FiltTime) ' seconds'];
    str3=['  Phasor held constant until = ' num2str(StartTime) ' seconds'];
    strs=str2mat(str1,str2,str3); 
    CaseCom=str2mat(CaseCom,strs); disp(strs)
    for n=1:loc, VPhsr(n,:)=VPhsr(loc+1,:); end
  end
  VPhsr=VPhsr*KVfac; KVfac=1;
  DXDsigsX=timeD; DXDnames='time';
  DXDsigsX=[DXDsigsX VPhsr];  
  NameBase=namesX(LocVsigs(1),:); [NameBase]=BstringOut(NameBase,' ',2);
  NameBase=[NameBase ' Vphsr '];
  DXDnames=str2mat(DXDnames,[NameBase ' VcosCor'],[NameBase ' VsinCor']);
end  %Termination of voltage phasor calculation
IPhsr=[];
if ~isempty(LocIsigs)  %Calculate current phasor
  FiltTime=[]; %Filter settling time
  [IPhsr,tstepD,FiltTime]...
    =DXDmod1(PSMsigsX(:,LocIsigs),tstep,SigPars,FilPars,PMUtrack,Gtags);
  %IPhsr=IPhsr/sqrt(3); if length(LocIsigs)==3, IPhsr=IPhsr*3; end 
  PMUtrack=[0 0 0]; DXDpars=FilPars;
  maxpts=size(IPhsr,1);
  timeD=[0:maxpts-1]'*tstepD;
  %figure; plot(timeD,IPhsr(:,1))
  if isempty(FiltTime), FiltTime=0.2; end
  loc=min(ceil(FiltTime/tstepD),maxpts-1);
  if loc>0
    StartTime=timeD(loc+1)
    str1=['In ' CSname ': Supressing DXD filter transient in current phasor'];
    str2=['  Filter settling time       = ' num2str(FiltTime) ' seconds'];
    str3=['  Phasor held constant until = ' num2str(StartTime) ' seconds'];
    strs=str2mat(str1,str2,str3); 
    CaseCom=str2mat(CaseCom,strs); disp(strs)
    for n=1:loc, IPhsr(n,:)=IPhsr(loc+1,:); end
  end
  IPhsr=IPhsr*KAfac; KAfac=1;
  if isempty(VPhsr), DXDsigsX=timeD; DXDnames='time'; end
  DXDsigsX=[DXDsigsX IPhsr];  
  NameBase=namesX(LocIsigs(1),:); [NameBase]=BstringOut(NameBase,' ',2);
  NameBase=[NameBase ' Iphsr '];
  DXDnames=str2mat(DXDnames,[NameBase ' IcosCor'],[NameBase ' IsinCor']);
end  %Termination of current phasor calculation
end  %Termination of PMU calculations
%*************************************************************************

%*************************************************************************
%Calculate RMS quantities
%NEED DATA ENTRY FOR KVfac, KAfac
if ~isempty(VPhsr) %RMS calculations for Vphasor
  maxpts=size(VPhsr,1);
  timeD=[0:maxpts-1]'*tstepD;
  VPhsr=(VPhsr(:,1)-i*VPhsr(:,2))*KVfac; %NOTE MINUS SIGN
  Vmag=abs(VPhsr); Vang=PSMunwrap(angle(VPhsr)*r2deg);
  %figure, plot(timeD,Vmag); figure, plot(timeD,Vang)
  Vfrq=zeros(maxpts,1);
  Vfrq(2:maxpts)=Vang(2:maxpts)-Vang(1:maxpts-1); Vfrq(1)=Vfrq(2);
  Vfrq=Vfrq/(360*tstepD)+60;
  %figure, plot(timeD,Vfrq)
  if ~PMUcalcs, DXDsigsX=timeD; DXDnames='time'; end
  DXDsigsX=[DXDsigsX Vmag Vang];  
  NameBase=namesX(LocVsigs(1),:); [NameBase]=BstringOut(NameBase,' ',2);
  if PMUcalcs
    NameBase=[NameBase ' PSMtools Vphsr '];
  else
    NameBase=[NameBase ' Input Vphsr '];
  end
  DXDnames=str2mat(DXDnames,[NameBase ' VMag'],[NameBase ' VAngL']);
  VfrqName=[NameBase ' FreqL_BD'];
end
if ~isempty(IPhsr) %RMS calculations for Iphasor
  maxpts=size(VPhsr,1);
  timeD=[0:maxpts-1]'*tstepD;
  IPhsr=(IPhsr(:,1)-i*IPhsr(:,2))*KAfac;  %NOTE MINUS SIGN
  Imag=abs(IPhsr); Iang=PSMunwrap(angle(IPhsr)*r2deg);
  %figure, plot(timeD,Imag); figure, plot(timeD,Iang)
  if isempty(VPhsr)
    if ~PMUcalcs, DXDsigsX=timeD; DXDnames='time'; end
  end
  DXDsigsX=[DXDsigsX Imag Iang];  
  NameBase=namesX(LocIsigs(1),:); [NameBase]=BstringOut(NameBase,' ',2);
  if PMUcalcs
    NameBase=[NameBase ' PSMtools Iphsr '];
  else
    NameBase=[NameBase ' Input Iphsr '];
  end
  DXDnames=str2mat(DXDnames,[NameBase ' IMag'],[NameBase ' IAngL']);
  if ~isempty(VPhsr)
    DXDsigsX=[DXDsigsX real(VPhsr.*conj(IPhsr))*MWfac];
    DXDsigsX=[DXDsigsX imag(VPhsr.*conj(IPhsr))*MWfac];
    DXDnames=str2mat(DXDnames,[NameBase ' MW'],[NameBase ' Mvar']);
  end
end
if ~isempty(VPhsr)
  DXDsigsX=[DXDsigsX Vfrq];  
  DXDnames=str2mat(DXDnames,VfrqName);
end
%*************************************************************************

%*************************************************************************
%Organize return of phasor calculations
DXDnames=BstringOut(DXDnames,' ',2);  %Delete extra blanks
strs='Phasor calculations done: RMS Signals are:';
strs=str2mat(strs,names2chans(DXDnames));
disp(strs)
CaseCom=str2mat(CaseCom,strs); 
DXDsigsR=DXDsigsX;  %Temporary storage to enable diagnostics below
appendok=0;
aptest=tstepD==tstep;
if aptest
  appendok=promptyn('Append phasor calculation results at end of input signal array? ', 'n');
end
if appendok
  L=max(size(PSMsigsX,1),size(DXDsigsX,1)); %Test L?
  DXDnames=str2mat(namesX,DXDnames);
  DXDsigsR=[PSMsigsX(1:L,:) DXDsigsX(1:L,:)];
end
%*************************************************************************

%*************************************************************************
SrateD=1/tstepD; 
[maxptsD nsigsD]=size(DXDsigsR);
disp('Returning from DXDcalcs1:')
disp(sprintf('  Number of signals = %3.0i', nsigsD))
disp(sprintf('  Final tstep       = %3.8f', tstepD))
disp(sprintf('  Final samplerate  = %6.3f', SrateD))
disp(sprintf('  Final maxpoints   = %8.0i', maxptsD))
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'DXDcalcs1_keybdok04'), PSMMacro.DXDcalcs1_keybdok04=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_keybdok04))      % Not in Macro playing mode or selection not defined in a macro
    keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
    if keybdok
      disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
      if 0
        [maxpoints nsigs]=size(PSMsigsX);
        dispdec=round(tstep/tstepD);
        ModSig=PSMsigsX(1:dispdec:maxpoints,nsigs);
        DXDsigsR=[DXDsigsR PSMsigsX(:,nsigs)]; %Need dimension test here
        DXDnames=str2mat(DXDnames,namesX(nsigs,:));
      end
    end
else
    keybdok=PSMMacro.DXDcalcs1_keybdok04;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.DXDcalcs1_keybdok04=keybdok;
    else
        PSMMacro.DXDcalcs1_keybdok04=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

DXDsigsX=DXDsigsR;  %Final data to return
timeN=DXDsigsX(:,1);
%************************************************************************

%************************************************************************
%Optional plots of phasor results
for Npsets=1:20
    disp(' ')
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'DXDcalcs1_setok'), PSMMacro.DXDcalcs1_setok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_setok))      % Not in Macro playing mode or selection not defined in a macro
        setok=promptyn(['In ' CSname ': Batch plots of phasor results? '], '');
    else
        setok=PSMMacro.DXDcalcs1_setok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.DXDcalcs1_setok=setok;
        else
            PSMMacro.DXDcalcs1_setok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %   setok=promptyn(['In ' CSname ': Batch plots of phasor results? '], '');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
 
    
    if ~setok, break, end
    if ~isempty(get(0,'Children'))  %Test for open plots
        %----------------------------------------------------
        % Begin: Macro selection ZN 10/18/06
        if ~isfield(PSMMacro, 'DXDcalcs1_closeok'), PSMMacro.DXDcalcs1_closeok=NaN; end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_closeok))      % Not in Macro playing mode or selection not defined in a macro
            closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
        else
            closeok=PSMMacro.DXDcalcs1_closeok;
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.DXDcalcs1_closeok=closeok;
            else
                PSMMacro.DXDcalcs1_closeok=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        %closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
        % End: Macro selection ZN 10/18/06
        %----------------------------------------------------
        
        if closeok, close all; end    %Close all plots
    end
    maxptsDXD=size(DXDsigsX,1);   %Number of points in record
    nsigsDXD =size(DXDsigsX,2);   %Number of signals in record
    chansP=[2:nsigsDXD];          %Signals to plot
    decfac=1;                     %Decimation factor
    n1=1; n2=maxptsDXD;
    t1=DXDsigsX(n1,1);            %Initial processing time
    t2=DXDsigsX(n2,1);            %Final processing time
    TRange=[t1 t2];               %Processing range
    if Npsets>1    %Use value from prior plot cycle
      TRange=TRangeP;
    end
    Xchan=1;
    PlotPars=[];
    [CaseComP,SaveFileP,namesP,TRangeP,tstepP]...
      =PSMplot2(caseID,casetime,CaseCom,DXDnames,DXDsigsX(n1:n2,:),...
       chansP,TRange,tstepD,decfac,...
       Xchan,PlotPars);
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'DXDcalcs1_keybdok05'), PSMMacro.DXDcalcs1_keybdok05=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_keybdok05))      % Not in Macro playing mode or selection not defined in a macro
        keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
    else
        keybdok=PSMMacro.DXDcalcs1_keybdok05;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.DXDcalcs1_keybdok05=keybdok;
        else
            PSMMacro.DXDcalcs1_keybdok05=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
    
   
    if keybdok
      disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
      if 0 %Cut&paste stuff
        disp(names2chans(DXDnames))
        figure; plot(timeN,DXDsigsX(:,4)); set(gca,'xlim',[0 max(timeN)]) %Vmag
        figure; plot(timeN,DXDsigsX(:,5)); set(gca,'xlim',[0 max(timeN)]) %Vang
        figure; plot(timeN,cos(DXDsigsX(:,5)*pi/180)); set(gca,'xlim',[0 max(timeN)])
      end
      if 0 %Cut&paste stuff
        %DXDnames=namesX; DXDsigsX=PSMsigsX; tstepD=tstep; timeN=DXDsigsX(:,1);
        disp(names2chans(DXDnames)); Nsig1=4;
        dwell=01.0; Nstep=round(dwell/tstepD); Plag=0;
        disp('Check Plag,Nsig1:')
        figure; plot(DXDsigsX(:,Nsig1)); title(['Signal ' num2str(Nsig1) '=' DXDnames(Nsig1,:)])
        locsP=(round(0.9*Nstep):Nstep:size(DXDsigsX,1)-Plag)+Plag;
        PlotSig=DXDsigsX(locsP,Nsig1); PlotSig=PlotSig/max(PlotSig);
        figure; plot(PlotSig);
        xlabel('Time in Seconds');
        Ptitle{1}='Response for PMU_Box100HzX30_100';  title(Ptitle)
        figure; plot(timeN(locsP),db(PlotSig)); ylabel('Magnitude in dB')
        xlabel('Time in Seconds'); title(caseID)
        Ptitle{1}='Response for PMU_Box100HzX30_100';  title(Ptitle)
        set(gca,'ylim',[-60 20])
        if 0
          load PMU_Fscan20240A.mat SSfrqs Blockpts
          load PMU_Fscan000480A.mat SSfrqs Blockpts
          NN=min(length(locsP),length(SSfrqs));
          figure; plot(SSfrqs(1:NN),PlotSig(1:NN));
          xlabel('Frequency in Hertz');
          Ptitle{1}='Response for PMU_Box100HzX30_100';  title(Ptitle)
          set(gca,'xlim',[0 400])
        end
        locsP=locsP(2:length(locsP)); Nsig2=6; 
        FrqAxis=DXDsigsX(locsP,Nsig2);
        MaxFrq=max(FrqAxis); LM=find(FrqAxis==MaxFrq);
        Nfqs=length(FrqAxis); FrqAxis(LM+1:Nfqs)=FrqAxis(LM+1:Nfqs)+60;
        figure; plot(FrqAxis); 
        Ptitle{1}='Estimated Frequency Axis';  title(Ptitle)
        %locsP=locsP(1:LM);
        %figure; plot(DXDsigsX(locsP,6),DXDsigsX(locsP,4));
        figure; plot(FrqAxis,DXDsigsX(locsP,4));
        xlabel('Frequency in Hertz')
        %set(gca,'xlim',[30 90])
        %Trial designs for ABB compensating filter(s)
        WW=DXDsigsX(locsP,Nsig1); WW=WW./max(WW);
        Vlen=min(length(SSfrqs),length(WW));
        WW=WW(1:Vlen); SSfrqs=SSfrqs(1:Vlen); 
        figure; plot(SSfrqs,WW)
        Wboost=ones(size(WW));
        figure; plot(SSfrqs,Wboost)
        L1=find(SSfrqs==40); L2=find(SSfrqs==100);
        locsB=[L1:L2];
        %figure; plot([WW(locsB) Wboost(locsB) 1./WW(locsB)])
        Wboost(locsB)=1./WW(locsB); 
        %figure; plot(SSfrqs,Wboost); set(gca,'ylim',[0 2])
        rampstep=Wboost(L1)/L1; Wramp=[0:L1-1]*rampstep;
        Wboost(1:L1)=Wramp; 
        figure; plot(SSfrqs,Wboost); xlabel('Frequency in Hz'); title('Boost Filter 1'); set(gca,'ylim',[0 2])
        WWboost=WW.*Wboost; 
        figure; plot(SSfrqs,WWboost); xlabel('Frequency in Hz'); title('Total Filters 1'); set(gca,'ylim',[0 1.4])
        Wboost(1:L1)=Wboost(L1); 
        figure; plot(SSfrqs,Wboost); xlabel('Frequency in Hz'); title('Boost Filter 2'); set(gca,'ylim',[0 2])
        WWboost=WW.*Wboost; 
        figure; plot(SSfrqs,WWboost); xlabel('Frequency in Hz'); title('Total Filters 2'); set(gca,'ylim',[0 1.4])
      end       
    end
    
    if PSMMacro.RunMode>=1 
        break;
    end
end  %Terminate plot loop for filtered signals
%************************************************************************

%*************************************************************************
%Optional use of Ringdown GUI    %PSMT add-on
disp(' ')
prompt=['In ' CSname ': Launch ringdown tool? '];
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'DXDcalcs1_setok02'), PSMMacro.DXDcalcs1_setok02=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_setok02))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn(prompt,'');
else
    setok=PSMMacro.DXDcalcs1_setok02;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.DXDcalcs1_setok02=setok;
    else
        PSMMacro.DXDcalcs1_setok02=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%   setok=promptyn(prompt,'');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


for N=1:1
  AddOn=deblank(which('Ringdown'));  %Check presence of PSMT add-on
  if isempty(AddOn)
    disp(['In ' CSname ': Cannot find PSMT Add-On called Ringdown'])
    setok=0;  
  end  
  if ~setok, disp('Proceeding to next processing phase'), break, end
  if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
  end
  InSig=[]; FixedPoles=[];
  [maxpoints nsigs]=size(DXDsigsX);
  rgulocs=2:nsigs;  %All signals
  n1=1; timeN=DXDsigsX(:,1);
  %----------------------------------------------------
  % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'DXDcalcs1_keybdok06'), PSMMacro.DXDcalcs1_keybdok06=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.DXDcalcs1_keybdok06))      % Not in Macro playing mode or selection not defined in a macro
          keybdok=promptyn(['In ' CSname ': Do you want the keyboard first? '], 'n');
    else
        keybdok=PSMMacro.DXDcalcs1_keybdok06;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.DXDcalcs1_keybdok06=keybdok;
        else
            PSMMacro.DXDcalcs1_keybdok06=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
   %   keybdok=promptyn(['In ' CSname ': Do you want the keyboard first? '], 'n');
   % End: Macro selection ZN 10/18/06
   %----------------------------------------------------

  
  if keybdok
    disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
    %rgulocs=[2 78];  %Special selection
  end
  rguiopts.copyplotfcn='PSMlabl';
  rguiopts.copyplotargs={caseID casetime};
  ringdown([timeN DXDsigsX(n1:maxpoints,rgulocs)],DXDnames(rgulocs,:),InSig,FixedPoles,rguiopts);
  prompt=['In ' CSname ': Launch PRS utilities? '];
  for Ndisps=1:10
    setok=promptyn(prompt,'');
    if ~setok, break, end
    PRSdisp1(caseID,casetime,CaseCom,DXDnames(rgulocs,:),[timeN DXDsigsX(n1:maxpoints,rgulocs)],tstep);
  end
end   %Terminate local case loop
%************************************************************************

disp(' ')
return

%end of PSMT function DXDcalcs1

