function [Wphsr,tstep,FiltTime]=...
            DXDmod1(Wsig,tstep,SigPars,FilPars,PMUtrack,GtagsC);
% Applies digital transducer (DXD) processing to point-on-wave signals.
% Context assumes DXD filter is a phasor measurment unit (PMU).
% Fourier filter has been renamed Correlation filter, to reduce 
%   possible conflicts with relay terminology.
%
% [Wphsr,tstep,FiltTime]=...
%    DXDmod1(Wsig,tstep,SigPars,FilPars,PMUtrack,GtagsC)
%
% Rows of FilPars contain [FilType,HPfrq,LPfrq,FiltOrd,decfac]
% Use FilType 1,2,3 for 'LP', 'BP', and 'HP' filters
% Zero value for FilType produces null filter (gain==1)
% Decimation follows filtering
%
% Special functions called:
%   DXDcore
%   BuildBF
%   BuildBox
%   BuildSinc
%   TrfCalcZ
%   ASpecF1
%   Ringdown
%   promptyn
%
% Last modified 12/22/03.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

FNname='DXDmod1';

disp(' ')
disp(['Initiating ' FNname ':'])
samplerate=1/tstep;		%samples per second (SPS)
[maxpoints nsigs]=size(Wsig);
time=[0:maxpoints-1]*tstep;
disp(sprintf('  Number of phases   = %2.0i', nsigs))
disp(sprintf('  Initial tstep      = %2.8f', tstep))
disp(sprintf('  Initial samplerate = %5.3f', samplerate))
disp(sprintf('  Initial maxpoints  = %8.3f', maxpoints))

reffrq=60;
if size(FilPars,1)==4
  reffrq=FilPars(4,1);
end
if reffrq<=0, reffrq=60; end  

FiltTime =[]; %Greatest filter settling time
FiltTimes=[]; %Filter settling times
trackfilts=PMUtrack(1);
trackstepR=PMUtrack(2);
trackDXD  =PMUtrack(3);

i=sqrt(-1); r2deg=180/pi;  %Radians to degrees
SigNames=str2mat('Aphase','Bphase','Cphase');
SigNames=SigNames(1:nsigs,:);

%Display for raw signals
if trackDXD
  disp(' ')
  disp('In DXDmod1: Display for point-on-wave signals')
  Ptitle{1}='In DXDmod1: Point-on-wave signal 1 (normalized)';
  Ptitle{2}=['caseID=' GtagsC(1,:) '    casetime=' GtagsC(2,:)];
  maxW=max(Wsig);
  %Wsig=Wsig/maxW;
  sigmax=max(Wsig);
  ymin=0.95*sigmax(1); ymax=1.01*sigmax(1);
  figure; plot(max(Wsig(:,1),ymin))
  set(gca,'ylim',[ymin ymax])
  title(Ptitle)
  xlabel('Time in Samples')
  set(gca,'TickDir','out')
end

%Display for raw autospectra
if trackDXD
  disp(' ')
  disp('In DXDmod1: Display for point-on-wave autospectra')
  ASname=str2mat('Autospectrum for POW signal 1');
  Xrange=[0 1000; 0 500; 50 70];
  Yrange=[];
  [sigfft,nfft]=ASpecF1(Wsig(:,1),ASname,Xrange,Yrange,samplerate,GtagsC);
end
%Check for special operations
if sum(PMUtrack)
  keybdok=promptyn('POW signals display: Do you want the keyboard? ', 'n');
  if keybdok
    disp('In DXDmod1: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
    if 0
      ringdown([time' Wsig],SigNames,[],[],'');
      PRSdisp1('DXDmod point-on-wave signals:','','',SigNames,[time' Wsig],tstep);
    end
  end
end

%Recognized filter types
types=str2mat('NULL','LP','BP','HP','BX','HSinc','Import');
ntypes=size(types,1);
steppts=100;

%*************************************************************************
%Construct filter #1 (guard filter)
Bguard=[]; Aguard=[];
typeNo=FilPars(1,1); if typeNo>ntypes, typeNo=0; end
type=deblank(types(typeNo+1,:)); 
decfac=FilPars(1,5);
str=['In DXDmod1: Guard filter = ' type];
str=[str '  Decimation = ' num2str(decfac)];
disp(str)
if typeNo>=1&typeNo<=3 %Butterworth filter
  HPfrq=FilPars(1,2); LPfrq=FilPars(1,3);
  FiltOrd=ceil(FilPars(1,4)/2)*2; FiltOrd=max(FiltOrd,2);
  FilName=[type ' Butterworth guard filter: ' sprintf('HPfrq = %6.2f LPfrq = %6.2f  Hz', [HPfrq LPfrq])];
  PtagsF=['Filter Order = ' num2str(FiltOrd) ' Samplerate = ' num2str(samplerate)];
  if typeNo==1, steppts=fix(10/(LPfrq*tstep)); end
  if typeNo==2, steppts=fix(10/(HPfrq*tstep)); end
  if typeNo==3, steppts=200; end
  FiltTimes=[FiltTimes steppts*tstep];
  XrangeF=[0 1000]; if LPfrq>0, XrangeF=[0 4*LPfrq]; end
  YrangeF=[-60 10]; 
  if ~trackfilts, steppts=0; XrangeF=[0 0]; end
  [Aguard,Bguard,BrespD1,stepresp]=BuildBF(type,HPfrq,LPfrq,FiltOrd,FilName,...
		  XrangeF,YrangeF,samplerate,steppts,1,PtagsF);
end
if typeNo==4 %Boxcar filter
  HPfrq=0; LPfrq=FilPars(1,3);
  FiltOrd=1;
  FilName=[type ' Boxcar guard filter: ' sprintf('LPfrq = %6.2f  Hz', [LPfrq])];
  PtagsF=['Filter Order = ' num2str(FiltOrd) ' Samplerate = ' num2str(samplerate)];
  steppts=fix(5/(LPfrq*tstep));
  FiltTimes=[FiltTimes steppts*tstep];
  XrangeF=[0 1000]; if LPfrq>0, XrangeF=[0 4*LPfrq]; end
  YrangeF=[-60 10]; 
  if ~trackfilts, steppts=0; XrangeF=[0 0]; end
  [Aguard,Bguard,BrespD1,stepresp]=BuildBox(type,HPfrq,LPfrq,FiltOrd,FilName,...
		  XrangeF,YrangeF,samplerate,steppts,1,PtagsF);
end
if typeNo==5 %HSinc filter
  HPfrq=0; LPfrq=FilPars(1,3);
  SincFac=FilPars(1,4)/10;
  FilName=[type ' HSinc guard filter: ' sprintf('LPfrq = %6.2f  Hz', [LPfrq])];
  PtagsF=['SincFac = ' num2str(SincFac) ' Samplerate = ' num2str(samplerate)];
  steppts=fix(5/(LPfrq*tstep));
  FiltTimes=[FiltTimes steppts*tstep];
  XrangeF=[0 1000]; if LPfrq>0, XrangeF=[0 4*LPfrq]; end
  YrangeF=[-80 10]; 
  if ~trackfilts, steppts=0; XrangeF=[0 0]; end
  [Aguard,Bguard,BrespD1,stepresp]=BuildSinc(type,HPfrq,LPfrq,SincFac,FilName,...
		  XrangeF,YrangeF,samplerate,steppts,1,PtagsF);
end
if typeNo==6 %Import filter parameters
  FilName=type;
  disp( 'In DXDmod1: Enter B,A parameters for guard filter')
  disp(['  Present tstep=' num2str(tstep)])
  disp( '  EXAMPLE:  B=[1 2 3 4 5 4 3 2 1]; A=[1]; return')
  disp( '  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
  %edit CLSBP1
  %edit REMEZBP1
  Bguard=B; Aguard=A;
  if 0 %Cut&paste stuff
    [resp2,W]=freqz(Bguard,Aguard,256,round(1/tstep));
    figure; plot(W,abs(resp2)); 
    xlabel('Frequency in Hertz'); title('Imported guard filter')
  end
end
%Filter stage #1 (guard filter)
if typeNo>0
  offset=ones(size(Wsig,1),1)*Wsig(1,:);
  Wsig=filter(Bguard,Aguard,(Wsig-offset))+offset;
end
%Decimation stage #1
decfac1=FilPars(1,5);
tstep=decfac1*tstep;
samplerate=1/tstep;
nptsD0=size(Wsig,1);
Wsig=Wsig(1:decfac1:nptsD0,:);
maxpoints=size(Wsig,1);
disp(['Guard filter done: ' sprintf('samplerate= %5.3f', samplerate)])

%Display for Autospectra after filter #1 (decimated)
if trackDXD
  disp(' ')
  disp('In DXDmod1: Autospectra after filter #1 (decimated)')
  ASname=str2mat('Autospectrum 1 after guard filter (decimated)');
  XrangeF=[0 1000; 0 500; 50 70];
  YrangeF=[];
  [sigfft,nfft]=ASpecF1(Wsig(:,1),ASname,XrangeF,YrangeF,samplerate,GtagsC);
end
%Check for special operations
if sum(PMUtrack)
  keybdok=promptyn('Guard filter done: Do you want the keyboard? ','n');
  if keybdok
    disp('In DXDmod1: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
    if 0
      timeN=[0:maxpoints-1]*tstep;
      ringdown([timeN' Wsig],SigNames,[],[],'');
      PRSdisp1('DXDmod signals after Guard filter:','','',SigNames,[timeN' Wsig],tstep);
    end
  end
end
%*************************************************************************

%*************************************************************************
%Correlation against reference signals (DXDcore)
if ~trackstepR
  ASname=str2mat(sprintf('Sine Correlation: [samplerate]=[%3.0i]', samplerate));
  Xrange=[0 1];
  Yrange=[];
  delays=SigPars(:,1);
  [Wphsr]=DXDcore(Wsig,tstep,delays,reffrq,Xrange,GtagsC,trackDXD);
else
  disp(' ')
  disp('In DXDmod1: filter test - no correlation products') 
  Wphsr=[Wsig(:,1) zeros(maxpoints,1)];
end

%Display for raw phasor correlation sums
if trackDXD
  disp(' ')
  disp('In DXDmod1: Display for raw phasor')
  Ptitle{1}='In DXDmod1: Raw phasor (rectangular components)';
  Ptitle{2}=['caseID=' GtagsC(1,:) '    casetime=' GtagsC(2,:)];
  time=[0:size(Wphsr,1)-1]*tstep;
  figure; plot(time,Wphsr)
  title(Ptitle)
  xlabel('Time in Seconds')
  set(gca,'TickDir','out')
  Ptitle{1}='In DXDmod1: Raw phasor (magnitude)';
  figure, plot(time,abs((Wphsr(:,1)+i*Wphsr(:,2))))
  title(Ptitle)
  xlabel('Time in Seconds')
  set(gca,'TickDir','out')
  %set(gca,'xlim',[0.1 0.4])
end

%Display for autospectra of correlation sums
if trackDXD
  disp(' ')
  disp('In DXDmod1: Display autospectrum of correlation sums')
  XrangeF=[0 1000; 0 200; 0 10];
  YrangeF=[];
  ASname=str2mat('Autospectrum of coscor (raw)');
  [sigfft,nfft]=ASpecF1(Wphsr(:,1),ASname,XrangeF,YrangeF,samplerate,GtagsC);
  ASname=str2mat('Autospectrum of sincor (raw)');
  [sigfft,nfft]=ASpecF1(Wphsr(:,2),ASname,XrangeF,YrangeF,samplerate,GtagsC);
  %ASname=str2mat('Autospectrum of correlation sum magnitude');
  %[sigfft,nfft]=ASpecF1(abs(Wphsr(n,1)+i*Wphsr(n,2)),ASname,XrangeF,YrangeF,samplerate,GtagsC);
end
%Check for special operations
if sum(PMUtrack)
  keybdok=promptyn('Correlations done: Do you want the keyboard? ', 'n');
  if keybdok
    disp('In DXDmod1: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
    if 0
      timeN=[0:maxpoints-1]*tstep;
      SigNames=str2mat('Phasor coscor (raw)','Phasor sincor (raw)');
      ringdown([timeN' Wphsr],SigNames,[],[],'');
      PRSdisp1('DXDmod Raw correlation sums:','','',SigNames,[timeN' Wphsr],tstep);
    end
  end
end
%*************************************************************************

%*************************************************************************
%Construct filter #2 (Correlation filter)
BFour=[]; AFour=[];
typeNo=FilPars(2,1); if typeNo>ntypes, typeNo=0; end
type=deblank(types(typeNo+1,:));
decfac=FilPars(2,5);
str=['In DXDmod1: Correlation filter = ' type];
str=[str '  Decimation = ' num2str(decfac)];
disp(str)
if typeNo>=1&typeNo<=3 %Butterworth filter
  HPfrq=FilPars(2,2); LPfrq=FilPars(2,3);
  FiltOrd=ceil(FilPars(2,4)/2)*2; FiltOrd=max(FiltOrd,2);
  FilName=[type ' Butterworth Correlation filter: ' sprintf('HPfrq = %6.2f LPfrq = %6.2f  Hz', [HPfrq LPfrq])];
  PtagsF=['Filter Order = ' num2str(FiltOrd) ' Samplerate = ' num2str(samplerate)];
  if typeNo==1, steppts=fix(5/(LPfrq*tstep)); end
  if typeNo==2, steppts=fix(10/(LPfrq*tstep)); end
  if typeNo==3, steppts=200; end
  FiltTimes=[FiltTimes steppts*tstep];
  XrangeF=[0 1000]; if LPfrq>0, XrangeF=[0 4*LPfrq]; end
  YrangeF=[-60 10]; 
  if ~trackfilts, steppts=0; XrangeF=[0 0]; end
  [AFour,BFour,BrespD1,stepresp]=BuildBF(type,HPfrq,LPfrq,FiltOrd,FilName,...
		  XrangeF,YrangeF,samplerate,steppts,1,PtagsF);
end
if typeNo==4 %Boxcar filter
  HPfrq=0; LPfrq=FilPars(2,3);
  FiltOrd=1;
  FilName=[type ' Boxcar Correlation filter: ' sprintf('LPfrq = %6.2f  Hz', [LPfrq])];
  PtagsF=['Filter Order = ' num2str(FiltOrd) ' Samplerate = ' num2str(samplerate)];
  steppts=fix(5/(LPfrq*tstep));
  FiltTimes=[FiltTimes steppts*tstep];
  XrangeF=[0 1000]; if LPfrq>0, XrangeF=[0 4*LPfrq]; end
  YrangeF=[-60 10]; 
  if ~trackfilts, steppts=0; XrangeF=[0 0]; end
  [AFour,BFour,BrespD1,stepresp]=BuildBox(type,HPfrq,LPfrq,FiltOrd,FilName,...
		  XrangeF,YrangeF,samplerate,steppts,1,PtagsF);
end
if typeNo==5 %HSinc filter
  HPfrq=0; LPfrq=FilPars(2,3);
  SincFac=FilPars(2,4)/10;
  FilName=[type ' HSinc Correlation filter: ' sprintf('LPfrq = %6.2f  Hz', [LPfrq])];
  PtagsF=['SincFac = ' num2str(SincFac) ' Samplerate = ' num2str(samplerate)];
  steppts=fix(5/(LPfrq*tstep));
  FiltTimes=[FiltTimes steppts*tstep];
  XrangeF=[0 1000]; if LPfrq>0, XrangeF=[0 4*LPfrq]; end
  YrangeF=[-80 10]; 
  if ~trackfilts, steppts=0; XrangeF=[0 0]; end
  [AFour,BFour,BrespD1,stepresp]=BuildSinc(type,HPfrq,LPfrq,SincFac,FilName,...
		  XrangeF,YrangeF,samplerate,steppts,1,PtagsF);
end
if typeNo==6 %Import filter parameters
  FilName=type;
  disp( 'In DXDmod1: Enter B,A parameters for Correlation filter')
  disp(['  Present tstep=' num2str(tstep)])
  disp( '  EXAMPLE:  B=[1 2 3 4 5 4 3 2 1]; A=[1]; return')
  disp( '  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
  %edit CLSBP1
  %edit REMEZBP1
   BFour=B; AFour=A;
  if 0 %Cut&paste stuff
    [resp2,W]=freqz(BFour,AFour,256,round(1/tstep));
    figure; plot(W,abs(resp2)); 
    xlabel('Frequency in Hertz'); title('Imported Correlation filter')
  end
end
%Filter stage #2 (Correlation filter)
if typeNo>0
  offset=ones(size(Wphsr,1),1)*Wphsr(1,:);
  Wphsr=filter(BFour,AFour,(Wphsr-offset))+offset;
end
%Decimation stage #2
decfac2=FilPars(2,5);
tstep=decfac2*tstep;
samplerate=1/tstep;
nptsD1=size(Wphsr,1);
Wphsr=Wphsr(1:decfac2:nptsD1,:);
maxpoints=size(Wphsr,1);
disp(['Correlation filter done: ' sprintf('samplerate= %5.3f', samplerate)])

%Display for autospectra after Correlation filter (decimated)
if trackDXD
  disp(' ')
  disp('In DXDmod1: Autospectra for phasor components')
  XrangeF=[0 1000; 0 200; 0 10; 0 1];
  YrangeF=[];
  ASname=str2mat('Autospectrum for phasor coscor (filtered)');
  [sigfft,nfft]=ASpecF1(Wphsr(:,1),ASname,XrangeF,YrangeF,samplerate,GtagsC);
  ASname=str2mat('Autospectrum for phasor sincor (filtered)');
  [sigfft,nfft]=ASpecF1(Wphsr(:,2),ASname,XrangeF,YrangeF,samplerate,GtagsC);
end
%Check for special operations
if sum(PMUtrack)
  keybdok=promptyn('Correlation filter done: Do you want the keyboard? ', 'n');
  if keybdok
    disp('In DXDmod1: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
    if 0 %Cut&paste stuff
      Ptitle{1}='In DXDmod1: Response of Correlation Filter';
      Ptitle{2}=['caseID=' GtagsC(1,:) '    casetime=' GtagsC(2,:)];
      [Bresp,frq]=TrfCalcZ(BFour,AFour,1024,samplerate);
      figure; plot(frq,abs(Bresp));
      xlabel('Frequency in Hertz'); ylabel('Scalar Gain'); 
      title(Ptitle); pause
      set(gca,'xlim',[0 400])
      figure; plot(frq,db(Bresp));
      xlabel('Frequency in Hertz'); ylabel('Gain in dB'); 
      title(Ptitle);
      set(gca,'xlim',[0 400])
    end
    if 0 %Cut&paste stuff
      timeN=[0:maxpoints-1]*tstep;
      SigNames=str2mat('Phasor coscor (filtered)','Phasor sincor (filtered)');
      %rguiopts.copyplotfcn='PSMlabl';
      %rguiopts.copyplotargs={FNname};
      rguiopts='';
      ringdown([timeN' Wphsr],SigNames,[],[],rguiopts);
      PRSdisp1('DXDmod phasor after Correlation filter:','','',SigNames,[timeN' Wphsr],tstep);
    end
  end
end
%*************************************************************************

%*************************************************************************
%Construct filter #3 (final output filter)
Bout=[]; Aout=[];
typeNo=FilPars(3,1); if typeNo>ntypes, typeNo=0; end
type=deblank(types(typeNo+1,:));
decfac=FilPars(3,5);
str=['In DXDmod1: Final output filter = ' type];
str=[str '  Decimation = ' num2str(decfac)];
disp(str)
if typeNo>=1&typeNo<=3 %Butterworth filter
  HPfrq=FilPars(3,2); LPfrq=FilPars(3,3);
  FiltOrd=ceil(FilPars(3,4)/2)*2; FiltOrd=max(FiltOrd,2);
  FilName=[type ' Butterworth output filter: ' sprintf('HPfrq = %6.2f LPfrq = %6.2f  Hz', [HPfrq LPfrq])];
  PtagsF=['Filter Order = ' num2str(FiltOrd) ' Samplerate = ' num2str(samplerate)];
  if typeNo==1, steppts=fix(5/(LPfrq*tstep)); end
  if typeNo==2, steppts=fix(10/(LPfrq*tstep)); end
  if typeNo==3, steppts=200; end
  FiltTimes=[FiltTimes steppts*tstep];
  XrangeF=[0 1000]; if LPfrq>0, XrangeF=[0 4*LPfrq]; end
  YrangeF=[-60 10]; 
  if ~trackfilts, steppts=0; XrangeF=[0 0]; end
  [Aout,Bout,BrespD1,stepresp]=BuildBF(type,HPfrq,LPfrq,FiltOrd,FilName,...
		  XrangeF,YrangeF,samplerate,steppts,1,PtagsF);
end
if typeNo==4 %Boxcar filter
  HPfrq=0; LPfrq=FilPars(3,3);
  FiltOrd=1;
  FilName=[type ' Boxcar output filter: ' sprintf('LPfrq = %6.2f  Hz', [LPfrq])];
  PtagsF=['Filter Order = ' num2str(FiltOrd) ' Samplerate = ' num2str(samplerate)];
  steppts=fix(5/(LPfrq*tstep));
  FiltTimes=[FiltTimes steppts*tstep];
  XrangeF=[0 1000]; if LPfrq>0, XrangeF=[0 4*LPfrq]; end
  YrangeF=[-60 10]; 
  if ~trackfilts, steppts=0; XrangeF=[0 0]; end
  [Aout,Bout,BrespD1,stepresp]=BuildBox(type,HPfrq,LPfrq,FiltOrd,FilName,...
		  XrangeF,YrangeF,samplerate,steppts,1,PtagsF);
end
if typeNo==5 %HSinc filter
  HPfrq=0; LPfrq=FilPars(3,3);
  SincFac=FilPars(3,4)/10;
  FilName=[type ' HSinc output filter: ' sprintf('LPfrq = %6.2f  Hz', [LPfrq])];
  PtagsF=['SincFac = ' num2str(SincFac) ' Samplerate = ' num2str(samplerate)];
  steppts=fix(5/(LPfrq*tstep));
  FiltTimes=[FiltTimes steppts*tstep];
  XrangeF=[0 1000]; if LPfrq>0, XrangeF=[0 4*LPfrq]; end
  YrangeF=[-80 10]; 
  if ~trackfilts, steppts=0; XrangeF=[0 0]; end
  [Aout,Bout,BrespD1,stepresp]=BuildSinc(type,HPfrq,LPfrq,SincFac,FilName,...
		  XrangeF,YrangeF,samplerate,steppts,1,PtagsF);
end
if typeNo==6 %Import filter parameters
  FilName=type;
  disp( 'In DXDmod1: Enter B,A parameters for final output filter')
  disp(['  Present tstep=' num2str(tstep)])
  disp( '  EXAMPLE:  B=[1 2 3 4 5 4 3 2 1]; A=[1]; return')
  disp( '  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
  %edit CLSBP1
  %edit REMEZBP1
  Bout=B; Aout=A;
  if 0 %Cut&paste stuff
    [resp2,W]=freqz(Bout,Aout,256,round(1/tstep));
    figure; plot(W,abs(resp2)); 
    xlabel('Frequency in Hertz'); title('Imported guard filter')
  end
end
%Filter stage #3 (final output filter)
if typeNo>0
  offset=ones(size(Wphsr,1),1)*Wphsr(1,:);
  Wphsr=filter(Bout,Aout,(Wphsr-offset))+offset;
end
%Decimation stage #3
decfac3=FilPars(3,5);
tstep=decfac3*tstep;
samplerate=1/tstep;
nptsD2=size(Wphsr,1);
Wphsr=Wphsr(1:decfac3:nptsD2,:);
maxpoints=size(Wphsr,1);
FiltTime=sum(FiltTimes);
FiltTime=max(FiltTimes);
disp(['Output filter done: ' sprintf('samplerate= %5.3f', samplerate)])

if trackDXD
  disp(' ')
  disp('In DXDmod1: Display for final phasor')
  Ptitle{1}='In DXDmod1: Final phasor';
  Ptitle{2}=['caseID=' GtagsC(1,:) '    casetime=' GtagsC(2,:)];
  h=figure;
  time=[0:size(Wphsr,1)-1]*tstep;
  plot(time,Wphsr)
  title(Ptitle)
  xlabel('Time in Seconds')
  set(gca,'TickDir','out')
  %set(gca,'xlim',[0.1 0.4])
end

%Display for autospectra after filter #3 (decimated)
if trackDXD
  disp(' ')
  disp('In DXDmod1: Autospectra for final phasor')
  XrangeF=[0 1000; 0 200; 0 10; 0 1];
  YrangeF=[];
  ASname=str2mat('Autospectrum for phasor coscor');
  [sigfft,nfft]=ASpecF1(Wphsr(:,1),ASname,XrangeF,YrangeF,samplerate,GtagsC);
  ASname=str2mat('Autospectrum for phasor sincor');
  [sigfft,nfft]=ASpecF1(Wphsr(:,2),ASname,XrangeF,YrangeF,samplerate,GtagsC);
  ASname=str2mat('Autospectrum for phasor magnitude');
  [sigfft,nfft]=ASpecF1(abs(Wphsr(:,1)-i*Wphsr(:,2)),ASname,XrangeF,YrangeF,samplerate,GtagsC);
end
%Check for special operations
if sum(PMUtrack)
  keybdok=promptyn('Output filter done: Do you want the keyboard? ', 'n');
  if keybdok
    disp('In DXDmod1: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
    if 0
      timeN=[0:size(Wphsr,1)-1]'*tstep;
      SigNames=str2mat('Phasor coscor','Phasor sincor');
      ringdown([timeN Wphsr],SigNames,[],[],'');
      PRSdisp1('DXDmod phasor after final output filter:','','',SigNames,[timeN Wphsr],tstep);
    end
  end
end
%*************************************************************************

disp('Return from DXDmod1:')
disp(sprintf('  Final tstep      = %2.8f', tstep))
disp(sprintf('  Final samplerate = %5.3f', samplerate))
disp(sprintf('  Final maxpoints  = %8.3f', maxpoints))
disp(sprintf('  Filtering time   = %8.3f', FiltTime))
disp(' ')
return

%End of PSMT utility


