function [Pspec,fftfrq,NewAvgs,DSAdisp]=DSAspec2(time,sigs,refchan,Mtrend,nfft,nlap,...
	           window,samprate,Pspec0,WtFac,OldAvgs,DSAdisp,FRange,WFtitle,FFTforget);
%  DSAspec2 replaces DSAspec1 for FFT-based pediodogram analysis.
%  Optional waterfall plots for autospectra and coherency.
%
%   [Pspec,fftfrq,NewAvgs]=DSAspec2(time,sigs,refchan,Mtrend,nfft,nlap,...
%	      window,samprate,Pspec0,WtFac,OldAvgs,DSAdisp,WFtitle,FFTforget);
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
% NOTE: Waterfall logic assumes just two signals
%
% Special functions called by DSAspec2:
%   fft
%   surf, fmesh, waterfall
%   promptyn, promptnv
%   (others?)
%
% Modified 10/13/05. jfh  Changed db to 0.5*db in spectral waterfalls
% Modified 10/26/05  jfh  Added coherency waterfalls, renamed function to DSAspec2
% Modified 11/03/05  jfh  Refinements to waterfall logic
 
global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

persistent WaterFigSyy WaterFigCxy DispSaveSyy DispSaveCxy DispCount

str='In DSAspec2:';
str=[str ' nsigs = ' num2str(size(sigs,2))];
str=[str ' refchan = ' num2str(refchan)];
disp(str)

if ~exist ('OldAvgs'), OldAvgs=[]; end
if isempty('OldAvgs'), OldAvgs=0;  end
if OldAvgs==0    %Clear waterfall displays
  WaterFigSyy=[]; WaterFigCxy=[]; DispCount=0; 
end

%Check display controls
if ~exist('DSAdisp'), DSAdisp=[]; end
if isempty(DSAdisp),  DSAdisp=zeros(10,1); end
N=length(DSAdisp);
if N<10, DSAdisp(N+1:10)=0; end
trackDSA=DSAdisp(1);         %Display diagnostics
WFpars=DSAdisp(2:N);         %Waterfall parameters
nsigs=size(sigs,2); WFsig=0;
WaterFalls=DSAdisp(10)>0;     %Display waterfall plots
%Consistency checks here??
if WaterFalls
  WFmode   =WFpars(1);
  nWFavgs  =WFpars(2);
  WFspan   =WFpars(3);
  WFseq    =WFpars(4);
  WFpause  =WFpars(5);
  SyyScale =WFpars(6);
  WFaz     =WFpars(7);
  WFel     =WFpars(8);
  ShowSyyWF=(WFpars(9)==1)|(WFpars(9)==3);
  ShowCxyWF=(WFpars(9)==2)|(WFpars(9)==3);
else
  ShowSyyWF=0; ShowCxyWF=0;
end
if nsigs<2|refchan==0, ShowCxyWF=0; end
if ~exist('FRange') ,  FRange=[];   end
if ~exist('WFtitle'),  WFtitle='';  end

%Assure nfft is a power of 2
nfft0=nfft;
nfft=2^fix(log2(nfft));
if nfft~=nfft0
  disp(sprintf('In DSAspec2: Forcing nfft to a power of 2'))
  disp(sprintf('In DSAspec2: [nfft0 nfft] = %6.0i %6.0i',nfft0,nfft))
end
tstep=1/samprate; Tbar=nfft*tstep;
nfrqpts=nfft/2+1;

%Generate frequency axis
fftfrq=[0:nfrqpts-1]'*samprate/nfft;
if isempty(FRange), FRange=[0 max(fftfrq)]; end
WFfrqsN=find(fftfrq>=FRange(1)&fftfrq<=FRange(2));
WFfrqs=fftfrq(WFfrqsN);
nWFfrqs=length(WFfrqs);

%Determine scale factor for FFT window
WinFac=sum(window.^2)/nfft;
FFTfac=1/(WinFac*nfft);

%*************************************************************************
%Determine mode and weights for FFT averaging
if WtFac>0&WtFac<1
  ExpAvg=1;
  WTold=1-WtFac; WTnew=WtFac;
else
  ExpAvg=0;
  WtFac=1.0;  
end
LinAvg=~ExpAvg;
if OldAvgs>0
  disp(sprintf(  'In DSAspec2: [OldAvgs LinAvg]      = %6.0i %4.0i',OldAvgs,LinAvg))
  if ExpAvg
    disp(sprintf('In DSAspec2: [WtFac   ExpAvg]      = %6.4f %4.0i',WtFac,ExpAvg))
    disp(sprintf('In DSAspec2: [WTold WTnew WinFac]  = %6.4f %6.4f %6.4f',WTold,WTnew,WinFac))
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
XX=[]; YY=[]; ZZ=[];
ZZlabel{1}= ' ';
ZZlabel{2}=['FFTforget=' num2str(FFTforget)]; 
%*************************************************************************

%*************************************************************************
%Set sliding-window controls
nshift=nfft-nlap;
Nwinds=fix((nsigpts-nwinpts)/nshift)+1;
NWFtraces=0; %May need to refine this if OldAvgs>0
pt1=1; pt2=nfft;
%*************************************************************************

%*************************************************************************
%Main loop for sliding window
DispNow=0;   %Initialize control for waterfall display
for Nwind=1:Nwinds	  %Top of sliding window loop
  FFTtime=time(pt2);
  if LinAvg
    WTold=OldAvgs/(OldAvgs+1);
    WTnew=(1-WTold);
  end
  OldAvgs=OldAvgs+1;
  if trackDSA
    disp(sprintf('In DSAspec2: [Nwind WTold WTnew]   = %6.0i %8.7f %8.7f',Nwind,WTold,WTnew))
    test0=Pspec(1:4,1,1)'
  end
%----------------------------------------------------------------------
  if ~refchan  %Start auto-analysis
	for Nsig=1:nsigs
	  if Mtrend
	    Fxx=FFTfac*fft(window.*Detrend1(sigs(pt1:pt2,Nsig),Mtrend));
	  else
	    Fxx=FFTfac*fft(window.*sigs(pt1:pt2,Nsig));
	  end
	  Pspec(:,1,Nsig)=WTold*Pspec(:,1,Nsig)+WTnew*abs(Fxx(1:nfrqpts)).^2;
	  if trackDSA&(Nsig==1)  %Diagnostic output
	    WTold,WTnew,FFTtime
		size(Pspec)
		test1=Pspec(1:4,1,Nsig)'
		test2=abs(Fxx(1:4)).^2'
	  end
	end
	pt1=pt1+nshift; pt2=pt2+nshift;
  end          %Terminate auto-analysis
%----------------------------------------------------------------------
  if refchan   %Start cross-analysis
    if Mtrend
	  Fxx=FFTfac*fft(window.*Detrend1(sigs(pt1:pt2,refchan),Mtrend));
    else
	  Fxx=FFTfac*fft(window.*sigs(pt1:pt2,refchan));
    end
    Sxx=WTold*Sxx+WTnew*abs(Fxx(1:nfrqpts)).^2;
    for Nsig=1:nsigs
      if Mtrend
        Fyy=FFTfac*fft(window.*Detrend1(sigs(pt1:pt2,Nsig),Mtrend));
      else
        Fyy=FFTfac*fft(window.*sigs(pt1:pt2,Nsig));
      end
      Syy=abs(Fyy(1:nfrqpts)).^2;
      Fxy=Fyy.*conj(Fxx);
      Sxy=Fxy(1:nfrqpts);
      Pspec(:,1,Nsig)=WTold*Pspec(:,1,Nsig)+WTnew*Syy;
      Pspec(:,2,Nsig)=WTold*Pspec(:,2,Nsig)+WTnew*Sxy;
      %Cxy=(abs(Pspec(:,2,Nsig)).^2)./(Sxx.*Pspec(:,1,Nsig));
      if trackDSA&(Nsig==1)
        WTold,WTnew
        size(Pspec)
        test1=Pspec(1:4,1,Nsig)'
        test2=Syy(1:4)'
      end
    end
    pt1=pt1+nshift; pt2=pt2+nshift;
  end            %Terminate cross-analysis
%----------------------------------------------------------------------
  if WaterFalls  %Start waterfall logic
   NWFtraces=ceil((WFspan-Tbar)/(nshift*tstep*nWFavgs));
   if DispCount==0   %Initialize displays
      WFtime=zeros(NWFtraces,1);
      %Pspec=zeros(nfrqpts,nfuncts,nsigs);  %Dimensioning info
      if ShowSyyWF 
        if isempty(WaterFigSyy), WaterFigSyy=figure; end
        DispSaveSyy=zeros(nfrqpts,NWFtraces);
      end
      if ShowCxyWF 
        if isempty(WaterFigCxy), WaterFigCxy=figure; end
        DispSaveCxy=zeros(nfrqpts,NWFtraces);
      end
      WFfunctions=str2mat('SyyWF','CxyWF'); 
      if ~ShowCxyWF, WFfunctions=str2mat('SyyWF'); end
      if ~ShowSyyWF, WFfunctions=str2mat('CxyWF'); end
      %size(WFfunctions)
      WFwindows=ShowSyyWF+ShowCxyWF;
    end
    DispNow=fix(OldAvgs/nWFavgs)>0&mod(OldAvgs,nWFavgs)==0;
  end
  if DispNow     %Waterfall display
  %DispNow=DispNow, keyboard
  for WFplot=1:WFwindows
    %Store new data at front of arrays
    %Future code will use pointers instead of direct storage changes
    if WFplot==1
      WFtime(2:NWFtraces)=WFtime(1:NWFtraces-1);
      WFtime(1)=FFTtime;
      DispCount=min(DispCount+1,NWFtraces);
    end
    SyyWF=~isempty(findstr('SyyWF',WFfunctions(WFplot,:)));
    CxyWF=~isempty(findstr('CxyWF',WFfunctions(WFplot,:)));
    if SyyWF
      %Future code will use pointers instead of direct storage changes
      DispSaveSyy(:,2:NWFtraces)= DispSaveSyy(:,1:NWFtraces-1);
      DispSaveSyy(:,1)=Pspec(:,1,1+refchan);
    end
    if CxyWF
      %Future code will use pointers instead of direct storage changes
      DispSaveCxy(:,2:NWFtraces)= DispSaveCxy(:,1:NWFtraces-1);
      DispSaveCxy(:,1)=(abs(Pspec(:,2,2)).^2)./(Sxx.*Pspec(:,1,2));
    end
    XX=zeros(nWFfrqs,DispCount); 
    YY=zeros(nWFfrqs,DispCount);    ZZ=zeros(nWFfrqs,DispCount);
    if SyyWF
      WaterFig=WaterFigSyy;
      ZZscale=SyyScale;
      if SyyScale==1, Ztext1='Autospectrum magnitude'; end 
      if SyyScale==2, Ztext1='Autospectrum squared';   end
      if SyyScale==3, Ztext1='Autospectrum in dB';     end 
    end
    if CxyWF
      WaterFig=WaterFigCxy;
      ZZscale=1.0;
      Ztext1='Coherency Function (squared)';      
    end
    %disp(Ztext1); keyboard  %Interactive diagnostic
    for k=1:DispCount
      XX(1:nWFfrqs,k)=fftfrq(WFfrqsN);
      if WFseq==1,TraceLoc=DispCount-k+1; %Newest in back
      else TraceLoc=k;                    %Newest in front
      end
      YY(1:nWFfrqs,k)=ones(nWFfrqs,1)*WFtime(TraceLoc);
      if SyyWF
        if ZZscale==1, ZZ(1:nWFfrqs,k)=  sqrt(DispSaveSyy(WFfrqsN,TraceLoc)); end
        if ZZscale==2, ZZ(1:nWFfrqs,k)=      (DispSaveSyy(WFfrqsN,TraceLoc)); end
        if ZZscale==3, ZZ(1:nWFfrqs,k)=0.5*db(DispSaveSyy(WFfrqsN,TraceLoc)); end
      end
      if CxyWF
        ZZ(1:nWFfrqs,k)=DispSaveCxy(WFfrqsN,TraceLoc); 
      end
    end
    %Need at least two traces for waterfall!
    if DispCount>=2  %Proceed with display
      figure(WaterFig)
      ZZlabel{1}=[Ztext1 ': WFmode ' num2str(WFmode)];
      if WFmode==1 %Trace superposition A
        plot(fftfrq(WFfrqsN),ZZ)
        ylabel(ZZlabel); 
        if CxyWF, set(gca,'ylim',[0 1]); end
      end
      if WFmode==2  %Trace sequence A
        ylabel(ZZlabel); 
        if CxyWF, set(gca,'ylim',[0 1]); end
      end
      if WFmode>=3  %Waterfall or mesh display
        %surf(XX',YY',ZZ')
        %mesh(XX',YY',ZZ')
        %waterfall(XX',YY',ZZ')
        if WFmode==4
          mesh(XX',YY',ZZ')
        else
          waterfall(XX',YY',ZZ')
        end 
        if 0  %Interactive diagnostic
          disp('At DSAspec2 waterfall:'); keyboard
          %pt2,Nwind, Nwinds, size(DispSaveSyy)
          WFtime1=(pt2-1)*tstep
          WFtime2=(nfft-1+(DispCount*nshift*nWFavgs))*tstep
          %view(08,20)
        end
        if CxyWF, set(gca,'zlim',[0 1]); end
        WFview=['view(' num2str(WFaz) ',' num2str(WFel) ')'];
        eval(WFview)
        set(gca,'xlim',FRange)
        zlabel(ZZlabel) 
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
    end  %Terminate display operation
  end    %Terminate waterfall logic
  %----------------------------------------------------------------------
end		 %Terminate sliding window loop
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
str='In DSAspec2: [OldAvgs NewAvgs NWFtraces] = [';
str=[str num2str([OldAvgs NewAvgs NWFtraces]) ']'];
disp(str); %keyboard
if 0  %Interactive diagnostic
  disp(['In DSAspec2: Nwind = ' num2str(Nwind)])
  figure; plot(time);   title('DSAtime')
  figure; plot(WFtime); title('WFtime')
  figure; plot(YY(1,:)); title('plot(YY(1,:)')
  disp(['  WtFac       =' num2str(WtFac)])
  disp(['  WTold       =' num2str(WTold)])
  disp(['  WTnew       =' num2str(WTnew)])
  disp(['  WTold+WTnew =' num2str(WTold+WTnew)])
  disp(['size DispSaveSyy =' num2str(size(DispSaveSyy))])
  disp(['  size WFtime =' num2str(size(WFtime))])
  disp(['  size Pspec  =' num2str(size(Pspec))])
  disp(['  size XX     =' num2str(size(XX))])
  disp(['  size YY     =' num2str(size(YY))])
  disp(['  size ZZ     =' num2str(size(ZZ))])
  figure; plot(0.5*db(Pspec(1:100,1,1))); title('Final Pyy(1:100,1) in dB')
  figure; plot(Pspec(1:100,4,2)); title('Final Cxy(1:100,2)')
  if ~isempty(ZZ)
    figure; plot(ZZ(1:100,50:55));          title('ZZ sections 50:55')
    %view(0,0)
  end
end
%*************************************************************************

return

%end of PSMT function