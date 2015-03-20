function [Pspec,fftfrq,NewAvgs,DSAdisp]=DSAspec1(sigs,refchan,Mtrend,nfft,nlap,...
	           window,samprate,Pspec0,WtFac,OldAvgs,DSAdisp,FRange,WFtitle);
%  DSAspec1 performs FFT-based pediodogram analysis.
%  Optional waterfall plots for autospectra only.
%
%   [Pspec,fftfrq,NewAvgs]=DSAspec1(sigs,refchan,Mtrend,nfft,nlap,...
%	      window,samprate,Pspec0,WtFac,OldAvgs,DSAdisp,WFtitle);
% Inputs:
%
%  Mtrend = Mode for removing signal trends.  Primary options are
%	    0		No trend removal
%	    1		Remove initial value
%	    2		Remove average value			
%	    3		Remove least-squares fitted ramp
%	    4		Remove final value
%    (Most cases use external detrending.)
%
% Outputs:
%   Pspec	 = [Syy,Sxy,Txy,Cxy]
%
% Special functions called by DSAspec1:
%   fft
%   promptyn, promptnv
%   (others?)
%
% Last change 06/20/03.  jfh

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

persistent WaterFigN DispSave DispCount

str='In DSAspec1:';
str=[str ' nsigs = ' num2str(size(sigs,2))];
str=[str ' refchan = ' num2str(refchan)];
disp(str)

if ~exist('OldAvgs'), OldAvgs=[]; end
if isempty('OldAvgs'), OldAvgs=0; end
if OldAvgs==0    %Clear waterfall display
  WaterFigN=[]; DispCount=0; 
end

%Check display controls
if ~exist('DSAdisp'), DSAdisp=[]; end
if isempty(DSAdisp), DSAdisp=zeros(6,1); end
N=length(DSAdisp);
if N<6, DSAdisp(N+1:6)=0; end
trackDSA=DSAdisp(1);         %Display diagnostics
nsigs=size(sigs,2); WFsig=0;
WaterFalls=DSAdisp(2)>0;     %Display waterfall plots
%Consistency checks
if WaterFalls
  WFsig=1;
  if nsigs>1  %if nsigs>2
    WFsig=0;
  else
    %WFsig=1+(refchan>0);
  end
  if WFsig==0
    disp(' ')
    disp('In DSAspec1: Temporary  restriction')
    disp('  Waterfall display limited to autoanalysis of individual signals')
    disp(' ')
    DSAdisp(2)=0; WaterFalls=0;
  end
end
WaterFalls=(WFsig>0);
if WaterFalls
  WFmode   =DSAdisp(2);
  nWFavgs  =DSAdisp(3);
  nWFtraces=DSAdisp(4);
  WFseq    =DSAdisp(5);
  WFpause  =DSAdisp(6);
  WFdB     =DSAdisp(7);
  WFaz     =DSAdisp(8);
  WFel     =DSAdisp(9);
end
if ~exist('FRange') , FRange=[]; end
if ~exist('WFtitle'),WFtitle=''; end

%Assure nfft is a power of 2
nfft0=nfft;
nfft=2^fix(log2(nfft));
if nfft~=nfft0
  disp(sprintf('In DSAspec1: Forcing nfft to a power of 2'))
  disp(sprintf('In DSAspec1: [nfft0 nfft] = %6.0i %6.0i',nfft0, nfft))
end
nfrqpts=nfft/2+1;

%Generate frequency axis
fftfrq=[0:nfrqpts-1]'*samprate/nfft;
if isempty(FRange), FRange=[0 max(fftfrq)]; end
WFfrqsN=find(fftfrq>=FRange(1)&fftfrq<=FRange(2));
WFfrqs=fftfrq(WFfrqsN);
nWFpoints=length(WFfrqs);

%Determine scale factor for FFT window
WinFac=sum(window.^2)/nfft;

%*************************************************************************
%Determine mode and weights for FFT averaging
if WtFac>0&WtFac<1
  ExpAvg=1;
  WTold=1-WtFac; WTnew=WtFac/WinFac;
else
  ExpAvg=0;
  WtFac=1.0;  
end
LinAvg=~ExpAvg;
if OldAvgs>0
  disp(sprintf(  'In DSAspec1: [OldAvgs LinAvg]      = %6.0i %4.0i',OldAvgs,LinAvg))
  if ExpAvg
    disp(sprintf('In DSAspec1: [WtFac   ExpAvg]      = %6.4f %4.0i',WtFac,ExpAvg))
    disp(sprintf('In DSAspec1: [WTold WTnew WinFac]  = %6.4f %6.4f %6.4f',WTold,WTnew,WinFac))
  end
end
%*************************************************************************

%*************************************************************************
%Set basic controls
[nsigpts nsigs]=size(sigs);
nwinpts=length(window);
nfuncts=1; if refchan, nfuncts=4; end;
%*************************************************************************

%*************************************************************************
%Initialize storage
if OldAvgs
  Pspec=Pspec0;
else
  Pspec=zeros(nfrqpts,nfuncts,nsigs);
end
Fxx=zeros(nfft,1);
if refchan
  Sxx=Pspec(:,1,refchan);
  Fyy=zeros(nfft,1);    Syy=zeros(nfrqpts,1);
  Fxy=zeros(nfft,1);    Sxy=zeros(nfrqpts,1);
  Txy=zeros(nfrqpts,1); Cxy=zeros(nfrqpts,1);
end
%*************************************************************************

%*************************************************************************
%Set sliding-window controls
nshift=nfft-nlap;
Nwinds=fix((nsigpts-nwinpts)/nshift)+1;
pt1=1; pt2=nfft;
%*************************************************************************

%*************************************************************************
%Main loop for sliding window
DispNow=0;   %Initialize control for waterfall display
for Nwind=1:Nwinds	  %Top of sliding window loop
  if LinAvg
    WTold=OldAvgs/(OldAvgs+1);
    WTnew=(1-WTold)/(WinFac*nfft);
  end
  OldAvgs=OldAvgs+1;
  if trackDSA
    disp(sprintf('In DSAspec1: [Nwind WTold WTnew]   = %6.0i %8.7f %8.7f',Nwind,WTold,WTnew))
    test0=Pspec(1:4,1,1)'
  end
  if ~refchan  %Start auto-analysis
	for Nsig=1:nsigs
	  if Mtrend
	    Fxx=fft(window.*Detrend1(sigs(pt1:pt2,Nsig),Mtrend));
	  else
	    Fxx=fft(window.*sigs(pt1:pt2,Nsig));
	  end
	  Pspec(:,1,Nsig)=WTold*Pspec(:,1,Nsig)+WTnew*abs(Fxx(1:nfrqpts)).^2;
	  if trackDSA&(Nsig==1)
	    WTold,WTnew
		size(Pspec)
		test1=Pspec(1:4,1,Nsig)'
		test2=abs(Fxx(1:4)).^2'
	  end
	end
	pt1=pt1+nshift; pt2=pt2+nshift;
  end          %Terminate auto-analysis
  if refchan   %Start cross-analysi
    if Mtrend
	  Fxx=fft(window.*Detrend1(sigs(pt1:pt2,refchan),Mtrend));
    else
	  Fxx=fft(window.*sigs(pt1:pt2,refchan));
    end
    Sxx=WTold*Sxx+WTnew*abs(Fxx(1:nfrqpts)).^2;
    for Nsig=1:nsigs
      if Mtrend
        Fyy=fft(window.*Detrend1(sigs(pt1:pt2,Nsig),Mtrend));
      else
        Fyy=fft(window.*sigs(pt1:pt2,Nsig));
      end
      Syy=abs(Fyy(1:nfrqpts)).^2;
      Fxy=Fyy.*conj(Fxx);
      Sxy=Fxy(1:nfrqpts);
      Pspec(:,1,Nsig)=WTold*Pspec(:,1,Nsig)+WTnew*Syy;
      Pspec(:,2,Nsig)=WTold*Pspec(:,2,Nsig)+WTnew*Sxy;
      if trackDSA&(Nsig==1)
        WTold,WTnew
        size(Pspec)
        test1=Pspec(1:4,1,Nsig)'
        test2=Syy(1:4)'
      end
    end
    pt1=pt1+nshift; pt2=pt2+nshift;
  end          %Terminate cross-analysis
  if WaterFalls
    DispNow=fix(OldAvgs/nWFavgs)>0&mod(OldAvgs,nWFavgs)==0;
  end
  if DispNow   %Waterfall display
    if DispCount==0   %Initialize display
	  [m n p]=size(Pspec);
      DispSave=zeros(m,n,p,nWFtraces);
    end
    DispSave(:,:,:,2:nWFtraces)= DispSave(:,:,:,1:nWFtraces-1); %temp logic
	DispSave(:,:,:,1)=Pspec;
	DispCount=min(DispCount+1,nWFtraces);
    XX=zeros(nWFpoints,DispCount); 
    YY=zeros(nWFpoints,DispCount);    ZZ=zeros(nWFpoints,DispCount);
    for k=1:DispCount
      nWFpoints=length(WFfrqsN);
      XX(1:nWFpoints,k)=fftfrq(WFfrqsN);
      if WFseq  %New trace at back
        YY(1:nWFpoints,k)=ones(nWFpoints,1)*(DispCount-k+1);
      else      %New trace at front
        YY(1:nWFpoints,k)=ones(nWFpoints,1)*k;
      end
      if WFdB, ZZ(1:nWFpoints,k)=db(DispSave(WFfrqsN,1,1,k));
      else     ZZ(1:nWFpoints,k)=  (DispSave(WFfrqsN,1,1,k)); 
      end
    end
    if DispCount>=2   %Need at least two traces for waterfall!
      if isempty(WaterFigN), WaterFigN=figure; end
      WaterFigN=WaterFigN; figure(WaterFigN)
      if WFmode==1 %Trace superposition A
        plot(fftfrq(WFfrqsN),ZZ)
        if WFdB, ylabel('Autospectrum in dB: WFmode 1'); 
        else ylabel('Scalar Autospectrum: WFmode 1');
        end
      end
      if WFmode==2 %Trace sequence A
        if WFdB
           plot(fftfrq(WFfrqsN),db(DispSave(WFfrqsN,1,1,1)))
           ylabel('Autospectrum in dB: WFmode 2')
        else
           plot(fftfrq(WFfrqsN),(DispSave(WFfrqsN,1,1,1)))
           ylabel('Scalar Autospectrum: WFmode 2')
        end
      end
      if WFmode>=3
        %surf(XX',YY',ZZ')
        %mesh(XX',YY',ZZ')
        %waterfall(XX',YY',ZZ')
        tstp=1/samprate;
        WFTscale=(nshift*nWFavgs)*tstp;
        TT=(nfft-1)*tstp+YY*WFTscale;
        if WFmode==4
          mesh(XX',TT',ZZ')
        else
          waterfall(XX',TT',ZZ')
        end 
        if 0
          disp('At DSAspec1 waterfall:'); keyboard
          %pt2,Nwind, Nwinds, size(DispSave)
          tstp=1/samprate;
          WFtime1=(pt2-1)*tstp
          WFtime2=(nfft-1+(DispCount*nshift*nWFavgs))*tstp
          WFTscale=(nshift*nWFavgs)*tstp;
          TT=(nfft-1)*tstp+YY*WFTscale;
          figure; waterfall(XX',TT',ZZ'); view(60,10)
        end
        %view(08,20)
        %view(60,10)
        WFview=['view(' num2str(WFaz) ',' num2str(WFel) ')'];
        eval(WFview)
        set(gca,'xlim',FRange)
        if WFdB, zlabel('Autospectrum in dB: WFmode 3'); 
        else zlabel('Scalar Autospectrum: WFmode 3');
        end
        clear Ytext;
        Ytext{1}='Time in Seconds'; 
        if PSMreftimes(1)>0
          RefString=PSM2Date(PSMreftimes(1));
          Ytext{2}=[' since ' RefString];   
        end
        ylabel(Ytext)
      end
      xlabel('Frequency in Hertz')
      title(WFtitle)
      if WFpause
        disp('Processing paused - to continue, press any key'); pause
      end
    end
  end
end		%Terminate sliding window loop
%*************************************************************************

%*************************************************************************
%Finish final results
if refchan
	for Nsig=1:nsigs
	  Syy=Pspec(:,1,Nsig);
	  Sxy=Pspec(:,2,Nsig);
	  Txy=Sxy./Sxx;
	  Cxy=(abs(Sxy).^2)./(Sxx.*Syy);
	  Pspec(:,3,Nsig)=Txy;
    Pspec(:,4,Nsig)=Cxy;
	end
end
NewAvgs=OldAvgs;
disp(sprintf('In DSAspec1: [OldAvgs NewAvgs]     = %6.0i %6.0i',OldAvgs,NewAvgs))
%*************************************************************************

return

%end of PSMT function
				   
   

