function [CaseCom,chankeyX,namesX,PSMsigsR,tstep,SpecTrnd,WinType,nfft,lap]...
  =PSMring1(caseID,casetime,CaseCom,chankeyX,namesX,PSMsigsX,...
     TRange,tstep,SpecTrnd,WinType,nfft,lap);
% PSMring1 performs special setups for FFT ringdown analysis 
%
%  [CaseCom,chankeyX,namesX,PSMsigsR,tstep,SpecTrnd,WinType,nfft,lap]...
%     =PSMring1(caseID,casetime,CaseCom,chankeyX,namesX,PSMsigsX,...
%        TRange,tstep,SpecTrnd,WinType,nfft,lap);
%
% INPUTS:
%    CaseCom      case comments
%    chankeyX     table relating signal numbers to channel numbers
%    namesX       signal names
%    PPSMsigsX    signal data to be processed
%    tstep        time step for PPSMsigsX
%    SpecTrnd     detrending control
%    WinType      window type for FFT analysis
%    nfft         number of points in each FFT (integer power of 2)
%    lap          per-unit overlap for successive FFT windows
%
% OUTPUTS:
%
% PSMT Functions called by PSMring1:
%   names2chans
%   promptyn
%
%  Last modified 05/15/01.   jfh

if nargin~=12
	disp('In PSMring1: Wrong number of inputs!!  Using old code?')
	disp('Invoking "keyboard" command - Enter "return" when you are finished')
	keyboard
end

%*************************************************************************
disp('In PSMring1: ')
%*************************************************************************

%*************************************************************************
%Initialize plot headers
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '  casetime=' casetime];
%*************************************************************************

%*************************************************************************
%Determine time parameters
maxpoints=size(PSMsigsX,1);
nsigsX=size(PSMsigsX,2);
if ~isempty(findstr('time',lower(namesX(1,:))))
  startchan=2;
  time=PSMsigsX(:,1);
else
  startchan=1;
  RTmax=(size(PSMsigsX,1)-1)*tstep;
  time=(0:tstep:RTmax);
end
RTmin=time(1); RTmax=time(maxpoints);
%*************************************************************************

%*************************************************************************
%Set time span for ringdown analysis, value for nfft
tstart=RTmin; tstop=RTmax;
tstart=TRange(1); tstop=TRange(2);
DispSig=startchan;
maxtrys=20; fftok=0;
for i=1:maxtrys
  if ~fftok
    disp('In PSMring1: Set time span and nfft for ringdown analysis')
    disp(sprintf('  Plotting data for  DispSig = %4.2i  tstart = %6.2f   tstop = %6.2f', DispSig,tstart,tstop))
    nfft=2^round(log2(nfft)); 
    n1=fix((tstart-RTmin)/tstep+1); n2=fix(min((tstop-RTmin)/tstep+1,maxpoints));
    npoints=n2-n1+1; 
    maxfft=2^round(log2(npoints))*2; maxTbar=tstep*maxfft; 
    nfft=min(nfft,maxfft);
    Tbar=tstep*nfft; tstop=tstart+Tbar/2;
    disp(['  Unpadded record length = ' num2str(npoints)])
	  disp(['  Max nfft with padding  = ' num2str(maxfft)])
	  disp(['  Max Tbar with padding  = ' num2str(maxTbar)])
	  disp(['  Assigned value of nfft = ' num2str(nfft)])
    if i==1, h=figure; end   %Initiate new figure
	  plot(time(n1:n2),PSMsigsX(n1:n2,DispSig));
    set (gca,'xlim',[tstart tstop])
    Ptitle{1}=namesX(DispSig,:); title(Ptitle)
    set(gca,'TickDir','out')
    xlabel('Time in Seconds')
    fftok=promptyn('Are this start time and nfft ok? ', 'y');
    if ~fftok
      disp('Use keyboard to modify data:')
      str=['Display signal is DispSig=' num2str(DispSig) ': '];
      disp([str namesX(DispSig,:)]) 
	    disp('Invoking "keyboard" command - Enter "return" when you are finished')
      keyboard
    end
    tstart=max(tstart,RTmin); tstop=min(tstop,RTmax); 
  end
end
%*************************************************************************

%*************************************************************************
%Set other FFT parameters
%Fill to left, trim off unused signal data
lap=0; nffth=nfft/2;
WinType=1;  %Hanning window 
PSMsigsR=zeros(nfft,nsigsX);
level=PSMsigsX(n1,:);    %Need extended zfill controls here!!
for n=1:nsigsX
  PSMsigsR(1:nffth,n)=level(n);
end
n2=n1+nffth-1;
PSMsigsR(nffth+1:nfft,1:nsigsX)=PSMsigsX(n1:n2,1:nsigsX);
timeR=zeros(nfft,1);
timeR(1:nffth)=[-nffth:-1]*tstep+time(n1);
timeR(nffth+1:nfft)=time(n1:n2);
if ~isempty(findstr('time',lower(namesX(1,:))))
  PSMsigsR(:,1)=timeR;
end
disp(['Size PSMsigsR = [' num2str(size(PSMsigsR)) ']'])
%*************************************************************************

%*************************************************************************
%Construct test pulse signal
testsigok=promptyn('In PSMring1:  Construct test pulse signal? ', 'n');
if ~testsigok
   PSMsigsR=PSMsigsR(:,1:nsigsX);
   disp('Return from PSMring1')
   return
end
%Default parameters for pulse signal
PulseName='Unit Pulse';
PulseHt=1.0;
PulseOn=tstart+2*tstep;
PulseOff=PulseOn+0.5;
%Test for repeated time points
swlocs=find(time(1:maxpoints-3)==time(2:maxpoints-2));
if ~isempty(swlocs)
  strs=['In PSMring1: Time axis indicates ' num2str(length(swlocs)) ' switching times'];
  strs=str2mat(strs,'WARNING -- NO LOGIC YET TO MERGE REPEATED TIME POINTS FOR SWITCHING EVENTS');
  swtimes=time(swlocs);
  for nsw=1:length(swlocs)
    strs=str2mat(strs,['  Switch time ' num2str(nsw) ' = ' num2str(swtimes(nsw))]);
    if nsw==1, PulseOn =swtimes(1); end
    if nsw==2, PulseOff=swtimes(2); end
    if nsw>2,  strs=str2mat(strs,'  More than 2 Switch times'); end
  end
  disp(strs)
end
maxtrys=20; fftok=0;
h=figure;  %Initiate new figure
for i=1:maxtrys
   if ~fftok
     disp('In PSMring1: Constructing test pulse signal [experimental code]')
     index=find((timeR>=PulseOn)&(timeR<=PulseOff));
     index=index(2:length(index)-1);
     testsig=zeros(size(PSMsigsR,1),1); testsig(index)=PulseHt;
	  %plot(timeR,testsig); pause
     str1='Plotting constructed pulse signal:';
     strs=str2mat(str1,['  PulseName = ' PulseName]);
     strs=str2mat(strs,['  PulseHt   = ' num2str(PulseHt)]);
     strs=str2mat(strs,['  [PulseOn PulseOff] = [' num2str([PulseOn PulseOff]) ']']);
     disp(strs)
     sig1=PSMsigsR(:,DispSig)-PSMsigsR(1,DispSig);
     sig2=testsig-testsig(1);
     Fac1=max(abs(sig1)); if Fac1~=0, Fac1=1/Fac1; end 
     Fac2=max(abs(sig2)); if Fac2~=0, Fac2=1/Fac2; end 
     plot(timeR,[sig1*Fac1 sig2*Fac2])
     Ptitle{1}='Timing comparison (signals normalized)';
     title(Ptitle)
     xlabel('Time in Seconds')
     pulseok=promptyn('In PSMspec1: Is this pulse signal ok?', 'y');
     if pulseok, break, end
       disp('Use keyboard to set pulse data:')
       disp('Invoking "keyboard" command - Enter "return" when you are finished')
       keyboard
    end
end
PSMsigsR=[PSMsigsR testsig];
namesX=str2mat(namesX,PulseName);
chankeyX=names2chans(namesX);
%*************************************************************************

disp('Return from PSMring1')
return

%end of PSMT function

