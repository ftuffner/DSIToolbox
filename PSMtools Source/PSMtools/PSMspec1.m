function [CaseComS,SaveFileS,namesS,TRangeS,tstepS,refchan,refname,...
     fftfrq,PxxSave,PyySave,TxySave,CxySave,chansAN]...
    =PSMspec1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansA,TRange,tstep,decfac,...
    refchan,SpecTrnd,WinType,nfft,lap,Frange,FFTpars);
 
% PSMspec1 produces FFT spectra and correlations (sliding window or ringdowns) 
%
% [CaseComS,SaveFileS,namesS,TRangeS,tstepS,refchan,refname,...
%    fftfrq,PxxSave,PyySave,TxySave,CxySave,chansAN]...
%   =PSMspec1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%    chansA,TRange,tstep,decfac,...
%    refchan,SpecTrnd,WinType,FFTtype,nfft,lap,Frange,FFTpars);
%
% INPUTS:  FFTpars=[];
%    caseID       name for present case
%    casetime     time when present case was initiated
%    CaseCom      case comments
%    namesX       signal names
%    PSMsigsX     signal data to be processed
%    tstep        time step for PSMsigsX
%    decfac		    decimation factor
%    DataPath     Path to PSM data file(s)
%    PSMfiles     Names of PSM data file(s)
%    chansA       indices for signals to analyze
%    refchan      index for reference signal
%    SpecTrnd     detrending control
%    WinType      window type for FFT analysis
%    nfft         number of points in each FFT (integer power of 2)
%    lap          per-unit overlap for successive FFT windows
%    Frange       frequency range for display of results
%    FFtpars      (spare array for future use)
%
% OUTPUTS:
%    CaseComS     case comments, showing PSMspec1 operations
%    namesS       names for signals analyzed
%    refname      name for reference signal
%    fftfrq       frequencies at which FFT data was calculated
%    PxxSave      autospectrum for reference signal
%    PyySave      autospectrum for response signals
%    TxySave      transfer functions (wrt reference signal)
%    CxySave      (squared) coherency functions (wrt reference signal)
%    tstepS       time step for PSMsigsX after decimation
%
% PSMT Functions called by PSMspec1:
%   PickList1, PickList2
%   PSMring1
%   DSAspec2
%   Detrend1
%   db
%   promptyn
%   PSMsave
%   PSMplot2
%   Ringdown
%   (others?)
%
% NOTES:
% a) Some PSM data has minimal filtering, to allow changes in sample rates.
% b) This version of PSMspect divides the FFT autospectra by nfft, for 
%    consistent results.
%
%  Modified 10/07/05  jfh   Replaced db by 0.5*db in autospectrum display
%                           for autoanalysis cases.  Do not know old this error
%                           might be!!!  
%  Modified 10/11/05  jfh   Removed 1/fft factor in cross analysis cases.  
%  Modified 11/03/05  jfh   Added coherency waterfalls
%                           revised waterfall control parameters  
%  Modified 10/18/2006 Ning Zhou to add macro function
 
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

persistent CxyLim chansA0  
%global CxyLim chansA0

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

 
if 0
    keyboard
    save Debug_08
elseif 0
    clear all 
    close all
    clc
    load Debug_08
    funLoadMacro()
    PSMMacro.RunMode=1;  %run macro
%    PSMMacro.RunMode=0;  %record macro
%    PSMMacro.RunMode=-1; %normal orperation
end


if isempty(CxyLim),  CxyLim=0; end

set(0,'DefaultTextInterpreter','none')

%Clear outputs
CaseComS=''; SaveFileS='';
namesS=namesX; TRangeS=TRange; tstepS=tstep;
refname=''; fftfrq=[];
PxxSave=[]; PyySave=[]; TxySave=[]; CxySave=[];

if isempty(PSMreftimes), PSMreftimes=0; end

disp(' ')
FNname='PSMspec1';
LcaseID=caseID;
disp(['In ' FNname ': Local caseID = ' LcaseID])

%Check inputs
if nargin~=16 % ???0
  disp(['In ' FNname ': Wrong number of inputs!!  Using old code?'])
  disp('Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end
FFTtype='';  %Future variable

disp(' ')
disp(['In ' FNname ': FFTtype = ' FFTtype])

%Determine channels to process
chansAstr=chansA;
if ~ischar(chansAstr)
  chansAstr=['chansA=[' num2str(chansAstr) '];'];
end
eval(chansAstr)
chankeyX=names2chans(namesX,1);
if isempty(chansA0), chansA0=chansA; end

%*************************************************************************
%Generate case identification, for stamping on plots and other outputs  
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMspec1_setok'), PSMMacro.PSMspec1_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn(['In ' FNname ': Generate new case tags? '], 'n');
else
    setok=PSMMacro.PSMspec1_setok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_setok=setok;
    else
        PSMMacro.PSMspec1_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%setok=promptyn(['In ' FNname ': Generate new case tags? '], 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if setok
  disp(['Generating new case tags for case ' LcaseID ':'])
  [LcaseID,casetime,CaseComS,Gtags]=CaseTags(LcaseID);
  CaseComS=str2mat(['New case tags in ' FNname ':'],CaseComS,CaseCom);
else
  CaseComS=CaseCom;
  Gtags=str2mat(LcaseID,casetime);
end
%*************************************************************************

%*************************************************************************
%Initialize plot headers
Ptitle{1}=' ';
Ptitle{2}=['LcaseID=' LcaseID '  casetime=' casetime];
%*************************************************************************

%*************************************************************************
%Test for presence of time channel
if isempty(findstr('time',lower(namesX(1,:))))
  disp('In PSMspec1: Time channel not found')
  disp('Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end
%*************************************************************************

%*************************************************************************
%Logic for local decimation
decfac=max(fix(decfac),1);
maxpoints=size(PSMsigsX,1);
tstepS=tstep;
deftag='n'; if decfac>1, deftag=''; end
if decfac>1
  rawdecimate=promptyn('   Decimate raw data?',deftag);
  if rawdecimate
    disp(sprintf('In PSMspec1: Local decimation factor =%4.0i',decfac))
    setok=promptyn('   Is this decimation factor ok? ', 'y');
    if ~setok
      decfac=promptnv('   Enter new decimation factor: ',decfac);
	    decfac=max(fix(decfac),1);
    end
    PSMsigsX=PSMsigsX(1:decfac:maxpoints,:);
    maxpoints=size(PSMsigsX,1);
	  tstepS=tstep*decfac; NyquistF=1/tstepS;
    strs=['In PSMspec1: Local decimation factor = ' num2str(decfac)];
    strs=str2mat(strs,['  Local maxpoints = ' num2str(maxpoints)]);
    strs=str2mat(strs,['  Local Nyquist   = ' num2str(NyquistF)]);
    disp(strs)
    CaseComF=str2mat(CaseComF,strs);
	decfac=1;
  end
end
simrate=1/tstepS;
Nyquist=0.5*simrate;
%*************************************************************************

%*************************************************************************
%Select Fourier window type
disp(' ')
disp('In PSMspec1: Select Fourier window type')
WinTypes=('Boxcar window');
WinTypes=str2mat(WinTypes,'Hanning window','Hanning squared');
WinTypes=str2mat(WinTypes,'Hamming window','Hamming squared');
locbase=0; maxtrys=5;
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'PSMspec1_WinTypeok'), PSMMacro.PSMspec1_WinTypeok=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_WinName'), PSMMacro.PSMspec1_WinName=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_WinType_1'), PSMMacro.PSMspec1_WinType_1=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_WinTypeok))      % Not in Macro playing mode or selection not defined in a macro
    [WinType,WinName,WinTypeok]=PickList1(WinTypes,WinType,locbase,maxtrys);
else
    WinTypeok=PSMMacro.PSMspec1_WinTypeok;
    WinName=PSMMacro.PSMspec1_WinName;
    WinType=PSMMacro.PSMspec1_WinType_1;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_WinTypeok=WinTypeok;
        PSMMacro.PSMspec1_WinName=WinName;
        PSMMacro.PSMspec1_WinType_1=WinType;
    else
        PSMMacro.PSMspec1_WinTypeok=NaN;
        PSMMacro.PSMspec1_WinName=NaN;
        PSMMacro.PSMspec1_WinType_1=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% [WinType,WinName,WinTypeok]=PickList1(WinTypes,WinType,locbase,maxtrys);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if ~WinTypeok
  disp('In PSMspec1: Window type not determined')
  disp('  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end
%*************************************************************************

%*************************************************************************
%Test for ringdown setup
yndef=[];
if ~isempty(findstr('ringdown',lower(FFTtype))), yndef='y'; end
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMspec1_setok02'), PSMMacro.PSMspec1_setok02=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_setok02))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn('In PSMspec1: Enter ringdown setup?', yndef);
else
    setok=PSMMacro.PSMspec1_setok02;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_setok02=setok;
    else
        PSMMacro.PSMspec1_setok02=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%setok=promptyn('In PSMspec1: Enter ringdown setup?', yndef);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if setok
  clear functions
  nsigsold=size(PSMsigsX,2);
  [CaseComS,chankeyX,namesX,PSMsigsR,tstepS,SpecTrnd,WinType,nfft,lap]...
    =PSMring1(LcaseID,casetime,CaseComS,chankeyX,namesX,PSMsigsX,...
     TRange,tstepS,SpecTrnd,WinType,nfft,lap);
  PSMsigsX=PSMsigsR; clear PSMsigsR;
  maxpoints=size(PSMsigsX,1);
  TRange(1)=PSMsigsX(1,1); TRange(2)=PSMsigsX(maxpoints,1);
  nsigsX=size(PSMsigsX,2);
  if nsigsX>nsigsold
    chansA=[nsigsX chansA];
  end
  FFTtype='Ringdown';
end
%*************************************************************************

%*************************************************************************
%Determine record time parameters
maxpoints=size(PSMsigsX,1);
nsigsX=size(PSMsigsX,2);
if ~isempty(findstr('time',lower(namesX(1,:))))
  startchan=2;
  time=PSMsigsX(:,1);
  RTmin=time(1); RTmax=time(maxpoints);
  tstart=max(RTmin,TRange(1)); tstop=min(RTmax,TRange(2));
else
  startchan=1;
  RTmax=(size(PSMsigsX,1)-1)*tstepS;
  time=(0:tstepS:RTmax);
  RTmin=time(1); RTmax=time(maxpoints);
  tstart=RTmin; tstop=RTmax;
end
disp(sprintf('  [maxpoints nsigsX] = %6.0i %4.0i', maxpoints, nsigsX))
disp(sprintf('  Record time span   = %6.2f %6.2f', RTmin,RTmax))
%*************************************************************************

%*************************************************************************
%Control for removing signal offsets
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMspec1_offtrend'), PSMMacro.PSMspec1_offtrend=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_offtrend))      % Not in Macro playing mode or selection not defined in a macro
    offtrend=promptyn('In PSMspec1: Remove signal offsets?', 'y');
else
    offtrend=PSMMacro.PSMspec1_offtrend;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_offtrend=offtrend;
    else
        PSMMacro.PSMspec1_offtrend=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% offtrend=promptyn('In PSMspec1: Remove signal offsets?', 'y');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if offtrend
  CaseComS=str2mat(CaseComS,'In PSMspec1: Signal offsets will be removed');
else
  SpecTrnd=0;
end
%*************************************************************************

%*************************************************************************
%Determine signals to analyze
disp(' ')
disp(['In ' FNname ':  Select signals for Fourier analysis']);
FAcom='Fourier analysis';

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'PSMspec1_chansAok'), PSMMacro.PSMspec1_chansAok=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_chansAN'), PSMMacro.PSMspec1_chansAN=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_MenuName'), PSMMacro.PSMspec1_MenuName=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_chansAok))      % Not in Macro playing mode or selection not defined in a macro
    [MenuName,chansAN,chansAok]=PickSigsN(chansA,namesX,chankeyX,'',FAcom);
else
    chansAok=PSMMacro.PSMspec1_chansAok;
    chansAN=PSMMacro.PSMspec1_chansAN;
    MenuName=PSMMacro.PSMspec1_MenuName;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_chansAok=chansAok;
        PSMMacro.PSMspec1_chansAN=chansAN;
        PSMMacro.PSMspec1_MenuName=MenuName;
    else
        PSMMacro.PSMspec1_chansAok=NaN;
        PSMMacro.PSMspec1_chansAN=NaN;
        PSMMacro.PSMspec1_MenuName=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% [MenuName,chansAN,chansAok]=PickSigsN(chansA,namesX,chankeyX,'',FAcom);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if ~chansAok
  disp(' No menu selections')
  disp(' Returning to invoking Matlab function')
  chansAN=[]; return
end
chansA=chansAN;
locsA=find(chansA>1); chansA=chansA(locsA);
nsigsA=length(chansA);
chansAN=[];
for N=1:nsigsA  %Avoid processing of secondary time axes
  Loc=chansA(N);
  if isempty(findstr('time',lower(namesX(Loc,:))))
    chansAN=[chansAN Loc];
  end
end
chansA=chansAN; chansA0=chansA;
namesA=namesX(chansA,:);
%*************************************************************************

%*************************************************************************
%Add to FFT processing log
nsigsA=length(chansA);
str1='ChansA='; disp(str1)
CaseComS=str2mat(CaseComS,str1);
for n1=1:15:nsigsA
  n2=min(n1+15-1,nsigsA);
  str1=[' ' num2str(chansA(n1:n2))]; 
  if n1==1, str1(1)='['; end
  if n2==nsigsA, str1=[str1 ']']; end
  disp(str1)
  CaseComS=str2mat(CaseComS,str1);
end
CaseComS=str2mat(CaseComS,'Signals for analysis:');
CaseComS=str2mat(CaseComS,namesA);
%*************************************************************************

%*************************************************************************
disp(' ')
disp('In PSMspec1: Set reference channel')
locbase=0; maxtrys=5;

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'PSMspec1_refok'), PSMMacro.PSMspec1_refok=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_refname'), PSMMacro.PSMspec1_refname=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_refchan'), PSMMacro.PSMspec1_refchan=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_refok))      % Not in Macro playing mode or selection not defined in a macro
    [refchan,refname,refok]=PickList1(str2mat('none',namesX),refchan,locbase,maxtrys);
else
    refok=PSMMacro.PSMspec1_refok;
    refname=PSMMacro.PSMspec1_refname;
    refchan=PSMMacro.PSMspec1_refchan;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_refok=refok;
        PSMMacro.PSMspec1_refname=refname;
        PSMMacro.PSMspec1_refchan=refchan;
    else
        PSMMacro.PSMspec1_refok=NaN;
        PSMMacro.PSMspec1_refname=NaN;
        PSMMacro.PSMspec1_refchan=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% [refchan,refname,refok]=PickList1(str2mat('none',namesX),refchan,locbase,maxtrys);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if ~refok
  refchan=0; refname='none';
end
str1=[sprintf('refchan = %5.2i   ', refchan) refname];
CaseComS=str2mat(CaseComS,str1);
%*************************************************************************

%*************************************************************************
disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMspec1_TRangeCk'), PSMMacro.PSMspec1_TRangeCk=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_TRangeCk))      % Not in Macro playing mode or selection not defined in a macro
    TRangeCk=promptyn('In PSMspec1: Verify time range?', 'n');
else
    TRangeCk=PSMMacro.PSMspec1_TRangeCk;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_TRangeCk=TRangeCk;
    else
        PSMMacro.PSMspec1_TRangeCk=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%TRangeCk=promptyn('In PSMspec1: Verify time range?', 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if TRangeCk
  DispSig=3; maxtrys=10;
  [TRangeS,nrange,TRangeSok]=ShowRange(PSMsigsX,namesX,DispSig,...
    [tstart tstop],tstep,maxtrys);
  if TRangeSok
    tstart=TRangeS(1); tstop=TRangeS(2);
  end
end
%*************************************************************************

%*************************************************************************
%Set FFT parameters for spectral analysis
fftok=0; maxtrys=5;
disp(' ')
disp('In PSMspec1: Window types are WinTypes=')
disp(names2chans(WinTypes))
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMspec1_fftok'), PSMMacro.PSMspec1_fftok=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_tstart'), PSMMacro.PSMspec1_tstart=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_tstop'), PSMMacro.PSMspec1_tstop=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_nfft'), PSMMacro.PSMspec1_nfft=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_lap'), PSMMacro.PSMspec1_lap=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_tstep'), PSMMacro.PSMspec1_tstep=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_Tbar'), PSMMacro.PSMspec1_Tbar=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_SpecTrnd'), PSMMacro.PSMspec1_SpecTrnd=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_WinType'), PSMMacro.PSMspec1_WinType=NaN; end
if ~isfield(PSMMacro, 'PSMspec1_Frange'), PSMMacro.PSMspec1_Frange=NaN; end

if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_fftok))      % Not in Macro playing mode or selection not defined in a macro
    for i=1:maxtrys
      if ~fftok
        disp(' ')
        nfft=2^round(log2(nfft)); 
        n1=fix((tstart-RTmin)/tstep+1); n2=fix(min((tstop-RTmin)/tstep+1,maxpoints));
        npoints=n2-n1+1; 
        maxfft=2^round(log2(npoints)); maxTbar=tstep*maxfft; 
        nfft=min(nfft,maxfft);
        Tbar=tstep*nfft; 
        if ~isempty(findstr('ringdown',lower(FFTtype)))
          tstop=tstart+Tbar+tstep;
        end
        disp('In PSMspec1: Parameters for FFT processing')
        disp(sprintf('  tstart = %8.2f   tstop = %6.2f', tstart,tstop))
        disp(sprintf('  nfft   = %8.0i   lap   = %7.4f', nfft,lap))
        disp(sprintf('  tstep  = %8.5f   Tbar  = %6.2f', tstep,tstep*nfft))
        disp(sprintf('  Signal Detrending:  SpecTrnd = %2.2i', SpecTrnd))
        disp(sprintf('  Window Type:        WinType  = %2.2i', WinType))
        disp(sprintf('  Frequency Range:    Frange   = [%6.2f  %6.2f]', Frange))
        fftok=promptyn('Is this ok?', '');
        if fftok
          if lap>1   %validity check #1
            disp('lap too large--must be less than unity')
            fftok=0;
          end
          if WinType<0|WinType>4   %validity check
            disp('WinType out of bounds--must be 0 through 4')
            fftok=0;
          end
        end
        if ~fftok
          disp('Use keyboard to set FFT data:')
          disp('Invoking "keyboard" command - Enter "return" when you are finished')
          keyboard
        end
      end
    end
else
    fftok=PSMMacro.PSMspec1_fftok;
    tstart=PSMMacro.PSMspec1_tstart;
    tstop=PSMMacro.PSMspec1_tstop;
    nfft=PSMMacro.PSMspec1_nfft;
    lap=PSMMacro.PSMspec1_lap;
    tstep=PSMMacro.PSMspec1_tstep;
    Tbar=PSMMacro.PSMspec1_Tbar;
    SpecTrnd=PSMMacro.PSMspec1_SpecTrnd;
    WinType=PSMMacro.PSMspec1_WinType;
    Frange=PSMMacro.PSMspec1_Frange;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_fftok=fftok;
        PSMMacro.PSMspec1_tstart=tstart;
        PSMMacro.PSMspec1_tstop=tstop;
        PSMMacro.PSMspec1_nfft=nfft;
        PSMMacro.PSMspec1_lap=lap;
        PSMMacro.PSMspec1_tstep=tstep;
        PSMMacro.PSMspec1_Tbar=Tbar;
        PSMMacro.PSMspec1_SpecTrnd=SpecTrnd;
        PSMMacro.PSMspec1_WinType=WinType;
        PSMMacro.PSMspec1_Frange=Frange;
    else
        PSMMacro.PSMspec1_fftok=NaN;
        PSMMacro.PSMspec1_tstart=NaN;
        PSMMacro.PSMspec1_tstop=NaN;
        PSMMacro.PSMspec1_nfft=NaN;
        PSMMacro.PSMspec1_lap=NaN;
        PSMMacro.PSMspec1_tstep=NaN;
        PSMMacro.PSMspec1_Tbar=NaN;
        PSMMacro.PSMspec1_SpecTrnd=NaN;
        PSMMacro.PSMspec1_WinType=NaN;
        PSMMacro.PSMspec1_Frange=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

if ~fftok
  str1=sprintf('Sorry -%5i chances is all you get!',maxtrys);
  disp([str1,' Returning to invoking Matlab function.'])
  return
end
str1=sprintf('tstart = %6.2f   tstop = %6.2f', tstart,tstop);
if decfac>1
  str1=[str1 sprintf('decfac= %6.2i',decfac)];
end
str2=sprintf('nfft = %6.2i   lap = %4.3f   Spectral Detrending = %2.2i', nfft,lap,SpecTrnd);
str3=sprintf('Window Type = %2.2i', WinType);
CaseComS=str2mat(CaseComS,str1,str2,str3);
%*************************************************************************

%*************************************************************************
%Set plot controls
SaveFileP='none';
ShowTRF  =0; TRFdb=0; ShowTsigs=0;
PrintPlot=0; SavePlot=0;
ShowWaterfalls=0;
DSAwtfac=1.0;  %Linear weighting for spectral average in DSAspec2
trackDSA=0;    %Diagnostics for developers only
WFpars=zeros(1,9);
disp(' ')

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMspec1_PlotOps'), PSMMacro.PSMspec1_PlotOps=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_PlotOps))      % Not in Macro playing mode or selection not defined in a macro
    PlotOps=promptyn('In PSMspec1: Plot hardcopy or other special operations?', 'y');
else
    PlotOps=PSMMacro.PSMspec1_PlotOps;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_PlotOps=PlotOps;
    else
        PSMMacro.PSMspec1_PlotOps=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
FFTforget=0;
% PlotOps=promptyn('In PSMspec1: Plot hardcopy or other special operations?', 'y');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if PlotOps
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMspec1_ShowTRF'), PSMMacro.PSMspec1_ShowTRF=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_ShowTRF))      % Not in Macro playing mode or selection not defined in a macro
        ShowTRF  =promptyn('In PSMspec1: Show transfer function?', 'n');
    else
        ShowTRF=PSMMacro.PSMspec1_ShowTRF;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMspec1_ShowTRF=ShowTRF;
        else
            PSMMacro.PSMspec1_ShowTRF=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %     ShowTRF  =promptyn('In PSMspec1: Show transfer function?', 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------

  
  if ShowTRF
    TRFdb=promptyn('  Show transfer function gain in dB?', 'n');
    disp(['  Minimum coherency for TF data = ' num2str(CxyLim)])
    CxyLimOK=promptyn('  Is this ok?','y');
    if ~CxyLimOK
      prompt='  Enter minimum coherency for TF data: Must lie between 0 and 1  ';
      CxyLim=promptnv(prompt,[0.2]);
      CxyLim=max(CxyLim,0); CxyLim=min(CxyLim,1);
    end
    disp(['In PSMspec1: Minimum coherency for TF data = ' num2str(CxyLim)])
  end
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMspec1_ShowTsigs'), PSMMacro.PSMspec1_ShowTsigs=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_ShowTsigs))      % Not in Macro playing mode or selection not defined in a macro
        ShowTsigs=promptyn('In PSMspec1: Show time signals?', 'n');
    else
        ShowTsigs=PSMMacro.PSMspec1_ShowTsigs;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMspec1_ShowTsigs=ShowTsigs;
        else
            PSMMacro.PSMspec1_ShowTsigs=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %     ShowTsigs=promptyn('In PSMspec1: Show time signals?', 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
 
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMspec1_PrintPlot'), PSMMacro.PSMspec1_PrintPlot=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_PrintPlot))      % Not in Macro playing mode or selection not defined in a macro
        PrintPlot=promptyn('In PSMspec1: Print generated plots?', '');
    else
        PrintPlot=PSMMacro.PSMspec1_PrintPlot;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMspec1_PrintPlot=PrintPlot;
        else
            PSMMacro.PSMspec1_PrintPlot=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %  PrintPlot=promptyn('In PSMspec1: Print generated plots?', '');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
  

    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMspec1_SavePlot'), PSMMacro.PSMspec1_SavePlot=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_SavePlot))      % Not in Macro playing mode or selection not defined in a macro
        SavePlot =promptyn('In PSMspec1: Save generated plots to file(s)?', 'n');
    else
        SavePlot=PSMMacro.PSMspec1_SavePlot;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMspec1_SavePlot=SavePlot;
        else
            PSMMacro.PSMspec1_SavePlot=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %   SavePlot =promptyn('In PSMspec1: Save generated plots to file(s)?', 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
 
    if SavePlot
        %SaveFileP=[casetime(10:11) casetime(13:14) casetime(16:17) 'S']	%long version
        SaveFileP=[casetime(13:14) casetime(16:17) 'S']	%short version
    end
   %
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMspec1_ShowSyyWF'), PSMMacro.PSMspec1_ShowSyyWF=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_ShowSyyWF))      % Not in Macro playing mode or selection not defined in a macro
        ShowSyyWF=promptyn('In PSMspec1: Show waterfall plots for autospectra?', 'n');
    else
        ShowSyyWF=PSMMacro.PSMspec1_ShowSyyWF;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMspec1_ShowSyyWF=ShowSyyWF;
        else
            PSMMacro.PSMspec1_ShowSyyWF=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %   ShowSyyWF=promptyn('In PSMspec1: Show waterfall plots for autospectra?', 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
  
  %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMspec1_ShowCxyWF'), PSMMacro.PSMspec1_ShowCxyWF=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_ShowCxyWF))      % Not in Macro playing mode or selection not defined in a macro
        ShowCxyWF=promptyn('In PSMspec1: Show waterfall plots for squared coherencies?', 'n');
    else
        ShowCxyWF=PSMMacro.PSMspec1_ShowCxyWF;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMspec1_ShowCxyWF=ShowCxyWF;
        else
            PSMMacro.PSMspec1_ShowCxyWF=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %ShowCxyWF=promptyn('In PSMspec1: Show waterfall plots for squared coherencies?', 'n');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
  
  ShowWaterfalls=ShowSyyWF|ShowCxyWF;
  WFmode=0; WFparsOk=0; FFTforget=0;
%  keyboard;
  if ShowWaterfalls
    WFmodes=str2mat('  none');
    WFmodes=str2mat(WFmodes,'  Trace superposition A','  Trace sequence A (not used)');
    WFmodes=str2mat(WFmodes,'  Waterfall display','  Mesh display');
    NWF=size(WFmodes,1);
    disp('In PSMspec1: Waterfall modes are')
    for N=1:NWF
      disp([num2str(N-1) WFmodes(N,:)])
    end
    FFTforget=0;   %linear averaging
    %FFTforget=60; %exponential averaging
    disp('FFT averaging options for waterfall calculations:')
    str1='  FFTforget= 0:  Linear averaging';
    str2='  FFTforget> 0:  Exponential averaging with 30% time constant specified by user';
    FFTavgOpts=str2mat(str1,str2); disp(FFTavgOpts)
    WFmode=4; 
    nWFavgs=20;
    nWFtraces=200; %Refine this later
    WFseq=1;
    disp('Trace sequence options for waterfall displays:')
    str1='  WFseq     = 1:  display newest traces at back';
    str2='  WFseq     = 2:  display newest traces at front';
    WFseqOpts=str2mat(str1,str2); disp(WFseqOpts)
    WFpause=0;
    SyyScale=1;
    disp('Scaling options for autospectra waterfalls:')
    str1='  SyyScale  = 1:  display sqrt(Syy)   [magnitude]';
    str2='  SyyScale  = 2:  display Syy         [squared magnitude]';
    str3='  SyyScale  = 3:  display 0.5*db(Syy) [magnitude in dB]';
    SyyScaleOpts=str2mat(str1,str2,str3); disp(SyyScaleOpts)
    WFaz=50; WFel=70; %In degrees
    
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMspec1_WFparsOk'), PSMMacro.PSMspec1_WFparsOk=NaN; end
    if ~isfield(PSMMacro, 'PSMspec1_WFpars'), PSMMacro.PSMspec1_WFpars=NaN; end

    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_WFparsOk))      % Not in Macro playing mode or selection not defined in a macro
        for i=1:6  %Allow 6 tries at parameter determination
          if ~WFparsOk
            disp(' ')
            disp('In PSMspec1: Parameters for waterfall displays:')
            FFTforget=max(FFTforget,0);
            WFspan=tstop-FFTforget;
            if WFmode==2, WFmode=1; end
            WFpause=0;
            SyyScale=max(SyyScale,1); SyyScale=min(SyyScale,3);
            str=['  FFT averaging :            FFTforget = ' num2str(FFTforget)];
            if FFTforget==0
              str=[str '  linear averaging']; disp(str);
            else
              str=[str '  30% time constant for exponential averaging']; disp(str);
            end
            disp(['  Waterfall mode:            WFmode    = ' num2str(WFmode)])
            disp(['  FFT points:                nfft      = ' num2str(nfft)])
            disp(['  FFT window overlap:        lap       = ' num2str(lap)])
            disp(['  Averages per trace:        nWFavgs   = ' num2str(nWFavgs)])
            disp(['  Waterfall span (seconds):  WFspan    = ' num2str(WFspan)])
            disp(['  WF trace sequence :      '  WFseqOpts(WFseq,:)])
            disp(['  Pause WF plot to view:     WFpause   = ' num2str(WFpause)])
            disp(['  Autospectra Scaling:     ' SyyScaleOpts(SyyScale,:)])
            disp(['  Waterfall azimuth:         WFaz      = ' num2str(WFaz)])
            disp(['  Waterfall elevation:       WFel      = ' num2str(WFel)])
            disp(['  Default view command:      view(' num2str(WFaz) ',' num2str(WFel) ')'])
            WFparsOk=promptyn('Is this ok?','y');
            if WFparsOk
              WFpars(1)=WFmode;
              WFpars(2)=nWFavgs;
              WFpars(3)=WFspan;
              WFpars(4)=WFseq;
              WFpars(5)=WFpause;
              WFpars(6)=SyyScale;
              WFpars(7)=WFaz;
              WFpars(8)=WFel;
              WFpars(9)=ShowSyyWF+2*ShowCxyWF;
            break
            else
              disp('Invoking "keyboard" command - Enter "return" when you are finished')
              keyboard
            end
          end
        end
    else
        WFparsOk=PSMMacro.PSMspec1_WFparsOk;
        WFpars=PSMMacro.PSMspec1_WFpars;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMspec1_WFparsOk=WFparsOk;
            PSMMacro.PSMspec1_WFpars=WFpars;
        else
            PSMMacro.PSMspec1_WFparsOk=NaN;
            PSMMacro.PSMspec1_WFpars=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------

       
  end
  ShowWaterfalls=WFparsOk&WFmode~=0;
end
%*************************************************************************

%*************************************************************************
chansWF=0;
if ShowWaterfalls
  if FFTforget==0
    DSAwtfac=1.0; %Linear weighting for spectral average in DSAspec2
  end
  if FFTforget>0
    DSAwtfac=nfft*tstep*(1-lap)/FFTforget; %Exponential  weighting
    DSAwtfac=DSAwtfac*log(1/0.3);
  end
  disp(' ')
  disp('In PSMspec1: Downselect channels for waterfall displays (future option)')
  locbase=1; maxtrys=10;
  namesA=namesX(chansA,:);
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    %keyboard;
    if ~isfield(PSMMacro, 'PSMspec1_chansWFok'), PSMMacro.PSMspec1_chansWFok=NaN; end
    if ~isfield(PSMMacro, 'PSMspec1_namesWF'), PSMMacro.PSMspec1_namesWF=NaN; end
    if ~isfield(PSMMacro, 'PSMspec1_chansWF_1'), PSMMacro.PSMspec1_chansWF_1=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_chansWFok))      % Not in Macro playing mode or selection not defined in a macro
        [chansWF,namesWF,chansWFok]=PickList2(namesA,chansA,locbase,maxtrys,chansA);
    else
        chansWFok=PSMMacro.PSMspec1_chansWFok;
        namesWF=PSMMacro.PSMspec1_namesWF;
        chansWF=PSMMacro.PSMspec1_chansWF_1;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMspec1_chansWFok=chansWFok;
            PSMMacro.PSMspec1_namesWF=namesWF;
            PSMMacro.PSMspec1_chansWF_1=chansWF;
        else
            PSMMacro.PSMspec1_chansWFok=NaN;
            PSMMacro.PSMspec1_namesWF=NaN;
            PSMMacro.PSMspec1_chansWF_1=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % [chansWF,namesWF,chansWFok]=PickList2(namesA,chansA,locbase,maxtrys,chansA);
    % End: Macro selection ZN 10/18/06
    %---------------------------------------------------
  
  
  if ~chansWFok
    chansWF=0; namesWF='none'; ShowWaterfalls=0;
    WFpars=zeros(1,9);
  end 
end
%*************************************************************************

%*************************************************************************
%Plot case documentation
CaseComPlot(CaseComS,Ptitle,PrintPlot,SavePlot,SaveFileP)
%*************************************************************************

%*************************************************************************
%Prepare signal analysis loop
simrate=1/tstepS;
Nyquist=0.5*simrate;
nfrq=nfft/2+1;
tbar=nfft*tstepS;
fstep=1/tbar;
Window=hanning2sq(nfft);  %Just in case!
if WinType==0, Window=ones(nfft,1);      end
if WinType==1, Window=hanning2(nfft);    end
if WinType==2, Window=hanning2(nfft).^2; end
if WinType==3, Window=hamming(nfft);     end
if WinType==4, Window=hamming(nfft).^2;  end
h=figure;  %Initiate new figure
plotno=sprintf('P%2.0i: ',h);
plot(Window);
Ptitle{1}=sprintf(['Type ' num2str(WinType) ' FFT Window']);
Ptitle{1}=[plotno Ptitle{1}];
title(Ptitle)
eps=tstep*1.e-6;
p1=fix((tstart-RTmin)*simrate+1); p1=max(p1,1);
pf=fix(min([(tstop-RTmin+1+eps)*simrate+1,maxpoints]));
if (pf-p1+1)<nfft
  disp(['In PSMspec1: Bad time controls - [p1 pf nfft]=' num2str([p1 pf nfft])])
  disp('Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end
if lap<=0, pf=p1+nfft-1; end
DSAtime=PSMsigsX(p1:pf,1);
%Determine plot range in samples
n1=fix(Frange(1)/fstep+1); n2=fix(min(Frange(2)/fstep+1,nfrq));
nsigsA=max(size(chansA));
PxxSave=zeros(nfrq,nsigsA);
sig1F=[];
if refchan>0
  sig1F=PSMsigsX(p1:pf,refchan);
  if offtrend
    sig1F=Detrend1(sig1F,SpecTrnd);
  end
  PyySave=zeros(nfrq,nsigsA);
  TxySave=zeros(nfrq,nsigsA);
  CxySave=zeros(nfrq,nsigsA);
end
%*************************************************************************

%*************************************************************************
%Execute signal analysis loop
disp(' ')

disp(['In PSMspec1: Processing ' num2str(nsigsA) ' Signals'])
namesS=[];
%Pspec = [Pyy Pxy Txy Cxy]
L=fix(min([size(namesX(1,:),2) 60]));  %trimmed signal name length
for N=1:nsigsA  %Main loop for analyzing signal pairs
  nsig=chansA(N);
  name2=namesX(nsig,:);
  namesS=str2mat(namesS,name2);
  DSAdisp=[trackDSA zeros(1,9)]; WFtitle{1}='none';
  if find(nsig==chansWF)
    DSAdisp=[trackDSA WFpars];
    if nsig==refchan, DSAdisp(10)=1; end  %Supress coherency waterfall
    WFtitle{1}=name2;
    WFtitle{2}=Ptitle{2};
  end
  sig2F=PSMsigsX(p1:pf,nsig);
  if offtrend
    sig2F=Detrend1(sig2F,SpecTrnd);
  end
  if ShowTsigs
    h=figure;
	plotno=sprintf('P%2.0i: ',h);
    if lap<=0
	  plot(DSAtime,[sig2F sig2F.*Window])
    else
	  plot(DSAtime,[sig2F])
	end
    TitleStr=[plotno name2]; 
    TitleStr=BstringOut(TitleStr,' ',2);
    Ptitle{1}=TitleStr;
	title(Ptitle)
	xlabel('Time in Seconds'); ylabel('Signal Segment #1')
    set(gca,'TickDir','out')
    if PrintPlot, print -f,     end
    if SavePlot
	  SaveP=[SaveFileP num2str(h)];
      eval(['print -deps ' SaveP]);
	end
  end 
  OldAvgs=0; Pspec=0;
  %----------------------------------------------------------------------
  if refchan>0    %Cross analysis case
	[Pspec,fftfrq,OldAvgs,DSAdisp]=DSAspec2(DSAtime,[sig1F sig2F],1,SpecTrnd,nfft,...
	         fix(lap*nfft),Window,simrate,Pspec,...
				  DSAwtfac,0,DSAdisp,Frange,WFtitle,FFTforget);
    %PxxSave(:,N)=Pspec(:,1,1)/nfft; PyySave(:,N)=Pspec(:,1,2)/nfft;
    PxxSave(:,N)=Pspec(:,1,1);  PyySave(:,N)=Pspec(:,1,2);
	TxySave(:,N)=Pspec(:,3,2);  CxySave(:,N)=Pspec(:,4,2);
    if N==1
	  h=figure;  %Initiate new figure
	  plotno=sprintf('P%2.0i: ',h);
	  plot(fftfrq(n1:n2),[10*log10(PxxSave(n1:n2,N))])
      TitleStr=[plotno 'Reference Signal =' refname]; 
      TitleStr=BstringOut(TitleStr,' ',2);
      Ptitle{1}=TitleStr;
	  title(Ptitle)
	  xlabel('Frequency in Hertz'); ylabel('Autospectrum in dB')
	  set (gca,'xlim',Frange); set(gca,'TickDir','out')
      if PrintPlot, print -f, end
	  if SavePlot
		SaveP=[SaveFileP num2str(h)];
        eval(['print -deps ' SaveP]);
      end
    end 
    if nsig~=refchan %Start cross-analysis display
    %Autospectra & Coherency
	h=figure;  %Initiate new figure
    set(h,'paperposition',[1.0 2.0 6 8])
	plotno=sprintf('P%2.0i: ',h);
    TitleStr=[plotno name2(1:L) '//' refname(1:L)];
    TitleStr=BstringOut(TitleStr,' ',2);
    Ptitle{1}=TitleStr;
	subplot(2,1,1) %Subplot 1 of 2
	  plot(fftfrq(n1:n2),[10*log10(PxxSave(n1:n2,N)) 10*log10(PyySave(n1:n2,N))])
	  xlabel('Frequency in Hertz'); ylabel('Autospectra in dB')
	  set (gca,'xlim',Frange); set(gca,'TickDir','out')
	  title(Ptitle)
    subplot(2,1,2) %Subplot 2 of 2
	  plot(fftfrq(n1:n2),[CxySave(n1:n2,N)])
	  xlabel('Frequency in Hertz'); ylabel('Coherency')
	  set (gca,'xlim',Frange); set(gca,'TickDir','out')
	  set (gca,'ylim',[0 1])
    if PrintPlot, print -f, end
    if SavePlot
	  SaveP=[SaveFileP num2str(h)];
      eval(['print -deps ' SaveP]);
    end
    %Transfer Function
	if ShowTRF&(nsig~=refchan)
      TxyMag=abs(TxySave(n1:n2,N)); TxyMin=min(TxyMag);
	  TxyAng=angle(TxySave(n1:n2,N))*180/pi.*(TxyMag>1000*eps);
	  [TxyAng]=PSMunwrap(TxyAng);  %Phase unwrap
      CxyN=CxySave(n1:n2,N); LocsCM=find(CxyN<CxyLim);
	  if ~isempty(LocsCM)
        TxyMag(LocsCM)=TxyMin;
        TxyAng(LocsCM)=0;
        CxyN(LocsCM)  =0;
      end
      h=figure;  %Initiate new figure
      set(h,'paperposition',[1.0 2.0 6 8])
	  plotno=sprintf('P%2.0i: ',h);
      TitleStr=[plotno name2(1:L) '//' refname(1:L)];
      TitleStr=BstringOut(TitleStr,' ',2);
      Ptitle{1}=TitleStr;
      subplot(3,1,1) %Subplot 1 of 3
      plot(fftfrq(n1:n2),[TxyMag])
      ytext='TF Gain (scalar)';
      if TRFdb
        epsval=1.e-6;
        if max(TxyMag)<epsval, TxyMag=ones(size(TxyMag))*epsval; end 
        plot(fftfrq(n1:n2),[20*log10(TxyMag)])
        ytext='TF Gain in dB';
      end
	  ylabel(ytext); %xlabel('Frequency in Hertz') 
	  set (gca,'xlim',Frange); set(gca,'TickDir','out')
      title(Ptitle)
      subplot(3,1,2) %Subplot 2 of 3
	    plot(fftfrq(n1:n2),[TxyAng])
	    ylabel('TF Phase in Degrees'); %xlabel('Frequency in Hertz') 
	    set (gca,'xlim',Frange); set(gca,'TickDir','out')
	    subplot(3,1,3) %Subplot 3 of 3
	    plot(fftfrq(n1:n2),[CxyN])
	    ylabel('Coherency'); xlabel('Frequency in Hertz') 
	    set (gca,'xlim',Frange); set(gca,'TickDir','out')
	    set (gca,'ylim',[0 1])
      if PrintPlot, print -f, end
	  if SavePlot
		SaveP=[SaveFileP num2str(h)];
        eval(['print -deps ' SaveP]);
      end
    end
	end  %Finish cross-analysis display
  end
  %----------------------------------------------------------------------
  if ~refchan>0    %Auto-analysis case
    %keyboard;  
    [Pspec,fftfrq,OldAvgs,DSAdisp]=DSAspec2(DSAtime,[sig2F],0,SpecTrnd,nfft,...
	           fix(lap*nfft),Window,simrate,Pspec,...
				    DSAwtfac,0,DSAdisp,Frange,WFtitle,FFTforget);
	PxxSave(:,N)=Pspec(:,1,1);
	%Autospectrum 
    h=figure; %Initiate new figure
	plotno=sprintf('P%2.0i: ',h);
	plot(fftfrq(n1:n2),[0.5*db(PxxSave(n1:n2,N))])
	TitleStr=[plotno name2];
    TitleStr=BstringOut(TitleStr,' ',2);
    Ptitle{1}=TitleStr;
	title(Ptitle)
	xlabel('Frequency in Hertz'); 
    Ystr='Autospectrum in dB';
    if DSAwtfac~=1,Ystr=[Ystr ' (sliding average)']; end
    ylabel(Ystr)
	set (gca,'xlim',Frange); set(gca,'TickDir','out')
    if PrintPlot, print -f, end
	  if SavePlot
	    SaveP=[SaveFileP num2str(h)];
        eval(['print -deps ' SaveP]);
      end
    end
    if trackDSA  %Test process tracking
    disp(' ')
    ClearTrack=promptyn('In PSMspec1: Cancel DSA tracking?', 'y');
    if ClearTrack, trackDSA=0; end
  end
  %----------------------------------------------------------------------
  if DSAdisp(6)  %Test WFpause
    disp(' ')
    ClearPause=promptyn('In PSMspec1: Cancel waterfall pause?', 'y');
    if ClearPause, WFpars(4)=0; end
  end
end    %Termination for signal analysis loop
namesS=namesS(2:nsigsA+1,:);
%*************************************************************************

%*************************************************************************
disp(' ')

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMspec1_setok03'), PSMMacro.PSMspec1_setok03=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_setok03))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn('In PSMspec1: Perform Inverse FFT operations?', yndef);
else
    setok=PSMMacro.PSMspec1_setok03;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_setok03=setok;
    else
        PSMMacro.PSMspec1_setok03=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%setok=promptyn('In PSMspec1: Perform Inverse FFT operations?', yndef);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if setok
  disp('IFFT operations in PSMspec1'); %keyboard
  fstep=fftfrq(2)-fftfrq(1);
  fmax=max(fftfrq); fmaxI=min(fmax,15);
  disp('In PSMspec1: Parameters for IFFT are')
  disp(['Max FFT freq = ' num2str(fmax)])
  disp(['Max IFFT freq: fmaxI = ' num2str(fmaxI)])
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMspec1_fmax'), PSMMacro.PSMspec1_fmax=NaN; end
    if ~isfield(PSMMacro, 'PSMspec1_fmaxI'), PSMMacro.PSMspec1_fmaxI=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_fmaxI))      % Not in Macro playing mode or selection not defined in a macro
        setok=promptyn('In PSMspec1: Change this value of fmaxI?', yndef);
        if setok
            disp('In PSMspec1: Invoking "keyboard" command - Enter "return" when you are finished')
            keyboard
         end
    else
        fmax=PSMMacro.PSMspec1_fmax;
        fmaxI=PSMMacro.PSMspec1_fmaxI;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMspec1_fmax=fmax;
            PSMMacro.PSMspec1_fmaxI=fmaxI;
        else
            PSMMacro.PSMspec1_fmax=NaN;
            PSMMacro.PSMspec1_fmaxI=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end

    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------

 
  
  fmaxI=min(fmaxI,fmax);
  disp(['Max IFFT freq: fmaxI = ' num2str(fmaxI)])
  n2F=round(fmaxI/fstep);
  fmaxI=fftfrq(n2F);
  tstepI=1/fmaxI;
  lagsT=[0:n2F-1]'*tstepI; 
  HalfPt=fix(length(lagsT)/2); lagsTH=lagsT(1:HalfPt);
  AutoRing=lagsTH; 
  namesCV='time';
  if refchan>=0
    for N=1:nsigsA
      nsig=chansA(N);
      if refchan==0
        SnameN=['PxxI: ' namesX(nsig,:)];
        IfftData=PxxSave(1:n2F,N);
      else
        SnameN=['PyyI: ' namesX(nsig,:)];
        IfftData=PyySave(1:n2F,N);
      end
      namesCV=str2mat(namesCV,SnameN);
      IfftSave=real(ifft(IfftData))/(2*fstep)*(3/8); %Generalize value
      if 0
        figure; plot(lagsT,real(IfftSave))
        figure; plot(lagsTH,real(IfftSave(1:HalfPt)))
        Ptitle{1}=[Sname1N];
        title(Ptitle); xlabel('Time in Seconds')
      end
      AutoRing=[AutoRing IfftSave(1:HalfPt)];
    end
    for Npsets=1:20 %Start of plot loop
      disp(' ')
        %----------------------------------------------------
        % Begin: Macro selection ZN 10/18/06
        if ~isfield(PSMMacro, 'PSMspec1_setok04'), PSMMacro.PSMspec1_setok04=NaN; end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_setok04))      % Not in Macro playing mode or selection not defined in a macro
            setok=promptyn(['In ' FNname ': Batch plots of Inverse FFT results? '], '');
        else
            setok=PSMMacro.PSMspec1_setok04;
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PSMspec1_setok04=setok;
            else
                PSMMacro.PSMspec1_setok04=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        %setok=promptyn(['In ' FNname ': Batch plots of Inverse FFT results? '], '');
        % End: Macro selection ZN 10/18/06
        %----------------------------------------------------
      
      
      if ~setok, break, end
      if ~isempty(get(0,'Children'))  %Test for open plots
        closeok=promptyn(['In ' FNname ': Close all plots? '], 'n');
        if closeok, close all; end    %Close all plots
      end
      chansP=[2:nsigsA+1]; TRange=[min(lagsTH) max(lagsTH)];
      decfac=1; Xchan=1; PlotPars=[];
      [CaseComP,SaveFileP,namesP,TRangeP,tstepP]...
        =PSMplot2(LcaseID,casetime,CaseComS,namesCV,AutoRing,...
         chansP,TRange,tstepI,decfac,...
         Xchan,PlotPars);
      keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '], 'n');
      if keybdok
        disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
        keyboard
      end
    end %Terminate plot loop
  end
  if refchan>0&0
    for N=1:nsigsA
      nsig=chansA(N);
      Sname2=['PyyI: ' namesX(nsig,:)];
      namesCV=str2mat(namesCV,Sname2);
      IfftData=PyySave(1:n2F,N);
      IfftSave=real(ifft(IfftData))/(2*fstep)*(3/8); %Generalize value
      %figure; plot(lagsT,real(IfftSave))
      figure; plot(lagsTH,real(IfftSave(1:HalfPt)))
      Ptitle{1}=[Sname2];
      title(Ptitle); xlabel('Time in Seconds')
      AutoRing=[AutoRing IfftSave(1:HalfPt)];
    end
    for N=1:nsigsA
      nsig=chansA(N);
      Sname12=['TxyI: ' namesX(nsig,:)];
      Sname12=[Sname12 '/' refname];
      namesCV=str2mat(namesCV,Sname12);
      IfftData=TxySave(1:n2F,N);
      IfftSave=real(ifft(IfftData)); 
      %figure; plot(lagsT,real(IfftSave))
      figure; plot(lagsTH,real(IfftSave(1:HalfPt)))
      Ptitle{1}=[Sname12];
      title(Ptitle); xlabel('Time in Seconds')
      AutoRing=[AutoRing IfftSave(1:HalfPt)];
    end
  end
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PSMspec1_Ringok'), PSMMacro.PSMspec1_Ringok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_Ringok))      % Not in Macro playing mode or selection not defined in a macro
       Ringok=promptyn('In PSMspec1: Launch ringdown tool for IFFTs? ', '');
    else
        Ringok=PSMMacro.PSMspec1_Ringok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMspec1_Ringok=Ringok;
        else
            PSMMacro.PSMspec1_Ringok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %  Ringok=promptyn('In PSMspec1: Launch ringdown tool for IFFTs? ', '');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------

  
  if Ringok
    if ~isempty(get(0,'Children'))  %Test for open plots
      closeok=promptyn(['In ' FNname ': Close all plots? '], 'n');
      if closeok, close all; end    %Close all plots
    end
    InSig=[]; FixedPoles=[];
    rguiopts.copyplotfcn='PSMlabl';
    rguiopts.copyplotargs={LcaseID casetime};
    ringdown(AutoRing,namesCV,InSig,FixedPoles,rguiopts);
  end
end
%*************************************************************************

%*************************************************************************
if (PSMMacro.RunMode<1)
    disp(' ')
    disp('In PSMspec1: Standard processing done')
    keybdok=promptyn('In PSMspec1: Do you want the keyboard? ', 'n');
    if keybdok
      disp('In PSMspec1: Invoking "keyboard" command - Enter "return" when you are finished')
      keyboard
      if 0
        locs=chansA; SnamesP=namesX(locs,:); 
        figure; plot(fftfrq(n1:n2),[0.5*db(PxxSave(n1:n2,:))])
        Ptitle{1}=['Autospectra in dB'];
        title(Ptitle);
        xlabel('Frequency in Hertz'); %ylabel('Autospectrum in dB')
        gtext(SnamesP)
      end
    end
end
%*************************************************************************

%*************************************************************************
disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMspec1_savesok'), PSMMacro.PSMspec1_savesok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMspec1_savesok))      % Not in Macro playing mode or selection not defined in a macro
    savesok=promptyn('In PSMspec1: Invoke utility to save spectral data? ', 'n');
else
    savesok=PSMMacro.PSMspec1_savesok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMspec1_savesok=savesok;
    else
        PSMMacro.PSMspec1_savesok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%savesok=promptyn('In PSMspec1: Invoke utility to save spectral data? ', 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if savesok
  disp('In PSMspec1: Loop for saving spectral data to files:')
  for tries=1:10
    disp(' ')
    SaveFile='';
    SaveList='refname fftfrq PxxSave PyySave TxySave CxySave tstepS namesS' ;
    SaveList=[SaveList ' chankeyX CaseComS PSMfiles'];
    PSMsave
    if isempty(SaveFile), break, end
  end
end
%*************************************************************************


disp('Return from PSMspec1')
return

%end of PSMT function
