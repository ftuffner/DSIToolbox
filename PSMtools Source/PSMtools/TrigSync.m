function[BSincH]=TrigSync(CaseCom,fcorner0,SincFac,tstep,track)
% Constructs Hanned Sinc filter for Trig3.m
%
% [BSincH]=TrigSync(CaseCom,fcorner0,SincFac,tstep);
%
% Last modified 09/05/01.   jfh

%General initialization
global Kprompt ynprompt nvprompt

%Check input parameters
if isempty(CaseCom), CaseCom='In TrigSync:'; end
if isempty(fcorner0),fcorner0=1; end
if isempty(SincFac), SincFac=1;  end
if isempty(tstep),   tstep=0.05; end
if tstep<=0,         tstep=0.05; end
if isempty(track),   track=0; end

%*************************************************************************
%Construct signal filter
strs='In TrigSync: Constructing Sinc filter SincH';
disp(strs)
CaseCom=str2mat(CaseCom,strs);
simrate=1/tstep;
Nyquist=0.5*simrate;
strs='NOTES:';
strs=str2mat(strs,' a) Filter Sinc0 is a basic Sinc filter of "Sincpts" points');
strs=str2mat(strs,' b) Filter SincH is filter Sinc0 plus a Hamming window');
strs=str2mat(strs,' c) [Sinc0 SincH] will have -6 dB corners in the general range');
strs=str2mat(strs,'    of [1 2]*fcorner0.  Just where depends upon SincFac.');
strs=str2mat(strs,' d) Use SincFac=[2 1 0.5] for a [low medium high] order filter');
if track, disp(strs); end
if fcorner0<=0, fcorner0=1; end		%lowpass corner frequency in Hertz
if SincFac<=0, SincFac=1.0; end		%medium order filter
disp('DEFAULT SETTINGS:')
disp(sprintf('fcorner0=%3.3f',fcorner0))
disp(sprintf('SincFac= %3.3f',SincFac))
setok=promptyn('In PSMSinc: Is this ok?', 'y');
if ~setok
  strs='In TrigSync: Invoking "keyboard command for modification of filter values.';
  disp(str2mat(strs,'  Type "return" when you are finished.'))
  keyboard
end
ncorner=fcorner0/Nyquist; 
Sincpts=fix(0.5*simrate/SincFac)*2;	%force an even number
SincRange=ncorner*(-Sincpts:Sincpts);
I=find(SincRange);
SincWts=ones(size(SincRange));
SincWts(I)=sin(pi*SincRange(I))./(pi*SincRange(I));
HamWts=0.54-0.46*cos(2*pi*(0:2*Sincpts)/(2*Sincpts));
BSinc0=ncorner*SincWts;
BSincH=BSinc0.*HamWts;
BSinc0=BSinc0/sum(BSinc0);
BSincH=BSincH/sum(BSincH);
SincDat1=sprintf('fcorner0=%5.3f, SincFac= %5.3f',fcorner0,SincFac);
strs=['Sinc1 Parameters: ' SincDat1];
SincDat2=sprintf('ncorner=%5.3f, Sincpts=%5.3i',ncorner, Sincpts);
strs=str2mat(strs,SincDat2);
disp(strs)
CaseCom=str2mat(CaseCom,strs);
%*************************************************************************

%*************************************************************************
%Optional plotting of filter characteristics
plotok=promptyn('In TrigSync: Plot filter characteristics?', 'n');
if plotok
  h1=figure;
  plot([BSinc0' BSincH'])
  Ptitle{1}=['weights for Sinc0,Sinc1: ' SincDat1];
  title(Ptitle)
  set(gca,'TickDir','out')
  h=figure;
  [resp0,f]=TrfCalcZ(BSinc0,1,4096,simrate);
  [resp1,f]=TrfCalcZ(BSincH,1,4096,simrate);
  plot(f,[db(abs(resp0)) db(abs(resp1))]);
  Ptitle{1}=['dB gain for Sinc0, Sinc1: ' SincDat1];
  title(Ptitle)
  set(gca,'TickDir','out')
  h=figure;
  plot(f,[db(abs(resp0)) db(abs(resp1))]);
  title(Ptitle)
  set(gca,'TickDir','out')
  set (gca,'ylim',[-6 6])
  disp('Processing paused - press any key to continue')
  pause
end
%*************************************************************************

return

%end of jfh m-file

