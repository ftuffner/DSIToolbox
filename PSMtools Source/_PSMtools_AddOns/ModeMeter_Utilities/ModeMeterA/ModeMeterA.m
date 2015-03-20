function [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
     spoles,zpoles]...
    =ModeMeterA(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansMM,TRange,tstep,decfac,...
     refchan,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars);
% Subset of John Pierre ModeMeter, as provided on 09/04/00
%
%  [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
%    spoles,zpoles]...
%   =ModeMeterA(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%    chansMM,TRange,tstep,decfac,...
%    refchan,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars);
%
% Functions called by ModeMeterA:
%    CaseTags
%    PickList1
%    PSMfilt
%    ARMAovr
%    MMscanA
%    Sortpole1
%    MMscanPlots2
%    promptyn, promptnv
%    (others?)  
%
% Core code developed by J. W. Pierre at U. Wyoming
% Integration into PSM_Tools by J. F. Hauer, 
% Pacific Northwest National Laboratory.
%
% Modified 05/27/04.  jfh   (internal documentation)
% Modified 02/12/07.  jfh   (internal documentation)

%----------------------------------------------------
% Begin: Macro definition ZN 02/12/07
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 02/12/07
%----------------------------------------------------
 
global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

FNname='ModeMeterA';  %name for this function

disp(' ')
disp(['In ' FNname ': EXPERIMENTAL CODE'])

chankeyX=names2chans(namesX); 

%Clear outputs
CaseComMM=''; SaveFileMM='';
namesMM=namesX;,TRangeMM=TRange; tstepMM=tstep;
spoles=[]; zpoles=[];

simrate=1/tstepMM;
Nyquist=0.5*simrate;
time=PSMsigsX(:,1);
[maxpoints,nsigs]=size(PSMsigsX);

%*************************************************************************
%Generate case/time stamp for plots
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '  casetime=' casetime];
%*************************************************************************


%*************************************************************************
%Select processing window type
%[not used as yet]
%*************************************************************************

MMsig=PSMsigsX(:,chansMM(1));   %Signal to process

%*************************************************************************
%Preprocess signal
MMsig=MMsig-mean(MMsig);
rateMM=1/tstepMM;
decfacF=fix(rateMM/decfrq);
disp(' ')
MMsigF=MMsig; timeF=time;



%----------------------------------------------------
% Begin: Macro selection ZN 02/12/2007
if ~isfield(PSMMacro, 'ModeMeterA_setok'), PSMMacro.ModeMeterA_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterA_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn(['In ' FNname ': Filter/Decimate data? '],'n');
    setok=0;                                                     % the yes answer is not ready to be used.
else
    setok=PSMMacro.ModeMeterA_setok;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterA_setok=setok;
    else
        PSMMacro.ModeMeterA_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% setok=promptyn(['In ' FNname ': Filter/Decimate data? '],'y');
% End: Macro selection ZN 02/12/2007
%----------------------------------------------------
%keyboard

if setok
  FilType=1; FilPars=[];
  [CaseComF,SaveFileF,namesF,TRangeF,tstepF,...
    MMsigF,FilPars]...
     =PSMfilt(caseID,casetime,CaseCom,namesMM,MMsig,...
      [2],TRangeMM,tstepMM,decfacF,FilType,FilPars);
elseif decfacF>1
  str1=['In ' FNname ': Unfiltered decimation by decfacF=' num2str(decfacF)];
  disp(str1)
  MMsigF=MMsig(1:decfacF:maxpoints,:);
  timeF=time(1:decfacF:maxpoints);
  tstepF=tstepMM*decfacF;
  maxpointsF=size(MMsigF,1);
  str2=['In ' FNname ': New signal length is maxpointsF=' num2str(maxpointsF)];
  disp(str2)
  CaseComMM=str2mat(CaseComMM,str1,str2);
end
%*************************************************************************

%*************************************************************************
%Redefine time vectors
Tfirst=TRangeMM(1);
maxpoints=size(MMsig,1);          %Length of decimated signal
time=(0:maxpoints-1)*tstepMM;     %Time vector for decimated data
maxpointsF=size(MMsigF,1);        %Length of decimated signal
timeF=(0:maxpointsF-1)*tstepF;    %Time vector for decimated data
TRangeF=[timeF(1) timeF(maxpointsF)];
tspanF=TRangeF(2)-TRangeF(1);  
srateF=1/tstepF;
%Add Tfirst to allign with external displays??
%*************************************************************************

%*************************************************************************
disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 02/12/2007
if ~isfield(PSMMacro, 'ModeMeterA_viewok'), PSMMacro.ModeMeterA_viewok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterA_viewok))      % Not in Macro playing mode or selection not defined in a macro
    viewok=promptyn(['In ' FNname ': View preprocessed signals? '],'');
else
    viewok=PSMMacro.ModeMeterA_viewok;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterA_viewok=viewok;
    else
        PSMMacro.ModeMeterA_viewok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 02/12/2007
%----------------------------------------------------

if viewok
  h=figure;  %Initiate new figure
  subplot(2,1,1)
  plot(time(1:decfac:maxpoints),MMsig(1:decfac:maxpoints))
  Ptitle{1}=[namesMM(1,:) ' (with mean removed)'];
  title(Ptitle)
  xlabel('Time in Seconds')
  ylabel('Signal Amplitude')
  subplot(2,1,2)
  plot(timeF,MMsigF)
  title([namesMM(1,:) ' (preprecessed)'])
  xlabel('Time in Seconds')
  ylabel('Signal Amplitude')
  TbarFFT=min(72,tspanF);
  nfft=TbarFFT*srateF; nfft=2^fix(log2(nfft));
  [Py,F] = psd(MMsigF,nfft,srateF,hamming(nfft),fix(0.9*nfft));
  h=figure;  %Initiate new figure
  plot(F,10*log10(Py))
  if ~isempty(Frange), set(gca,'xlim',Frange); end
  Ptitle{1}=['Periodogram for ' namesMM(1,:)];
  title(Ptitle)
  xlabel('Frequency in Hz')
  ylabel('Autospectra in dB')
  if ~isempty(Frange), set(gca,'xlim',Frange); end
  TbarC=min(72,tspanF/3); NbarC=fix(TbarC*srateF);
  Rhat0=RHATFUNC(MMsigF,NbarC,0);
  h=figure;  %Initiate new figure
  plot(timeF(1:length(Rhat0)),Rhat0)
  Ptitle{1}=['Autocorrelation for ' namesMM(1,:)];
  title(Ptitle)
  xlabel('Shift in seconds')
  ylabel('Autocorrelation')
  keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '],'n');
  if keybdok
    disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end
%*************************************************************************

%*************************************************************************
%Set parameters for ModeMeter analysis
%Tbar=Tbar  %Diagnostics here
Nbar=fix(Tbar/tstepF);%Length of processing window in samples
TbarF=Nbar*tstepF;    %Length of processing window in seconds
nlap=fix(Nbar*lap);	  %Overlap of successive processing windows in samples
Nshift=Nbar-nlap;     %Advance of processing window in samples
Nest=24;              %Initial denominator order for estimator
Kcor=48;              %Length of correlation matrix
Mest=16;              %Numerator order for estimator
w=0;                  %w is window for correlation est., currently disabled.
Parsok=0; maxtrys=5;
disp(' ')
disp(['In ' FNname ': Parameters for ModeMeter processing'])

%Select modes to track with special displays
TrackModes='PACI Intertie';
TrackModes=str2mat(TrackModes,'Alberta');
TrackFrqs(1)=0.27;  
TrackFrqs(2)=0.40; 
autoaxis=1;      %autoscale axis for plots of damping and freq vs. time
                 %1 for autoscale, else range is fixed
%*************************************************************************

%keyboard
%PSMMacro.RunMode=0;
%*************************************************************************
disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 02/12/2007
if ~isfield(PSMMacro, 'ModeMeterA_Fullok'), PSMMacro.ModeMeterA_Fullok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterA_Fullok))      % Not in Macro playing mode or selection not defined in a macro
    Fullok=promptyn(['In ' FNname ': Estimate modes from entire record? '],'y');
else
    Fullok=PSMMacro.ModeMeterA_Fullok;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterA_Fullok=Fullok;
    else
        PSMMacro.ModeMeterA_Fullok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 02/12/2007
%----------------------------------------------------

if Fullok
  %Estimate correlation function
  Rhat=RHATFUNC(MMsigF,Kcor+Mest,w);  %Rhat needs to be a column vector
  %Estimate the modes using overdetermined ARMA-based mode meter
  [a,spoles,zpoles,cnd]=ARMAovr(Rhat,Nest,Kcor,Mest,srateF);
  %Sort estimated modes by energy, then place tracked modes at top of mode table
  [ur,cr,sr,Y]=Sortpole1(zpoles,Rhat,spoles,TrackFrqs); 
  %Display mode table with relative energies
  disp('Mode estimation using entire record')
  disp('Full Mode Table:')
  disp('      Freq. in Hz      Damping Ratio     Relative Energy')
  disp([imag(sr)/(2*pi) -real(sr)./abs(sr) Y/max(Y)])
  %Display parameters for special modes
  for M=1:length(TrackFrqs)
    str1=['Special mode ' num2str(M) ': ' TrackModes(M,:)];
    str2=['  Frequency     = ' num2str(imag(sr(M))/(2*pi)) '  Hz'];
    str3=['  Damping ratio = ' num2str(-real(sr(M))/abs(sr(M)))];
    disp(str2mat(' ',str1,str2,str3))
  end
  
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/12/2007
    if ~isfield(PSMMacro, 'ModeMeterA_keybdok02'), PSMMacro.ModeMeterA_keybdok02=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterA_keybdok02))      % Not in Macro playing mode or selection not defined in a macro
        keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '],'n');
    else
        keybdok=PSMMacro.ModeMeterA_keybdok02;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.ModeMeterA_keybdok02=keybdok;
        else
            PSMMacro.ModeMeterA_keybdok02=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 02/12/2007
    %----------------------------------------------------
  if PSMMacro.RunMode==1 && ~keybdok
      disp('Press any key to continue....')
      pause;
      disp('Continued');
  end
  
  if keybdok
    disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
  
end
%*************************************************************************

%*************************************************************************
%Modemeter Scan
disp(' ')
disp(['In ' FNname ':']);
RecLen=length(MMsigF)*tstepF;            %Record length in seconds
Dblocks=fix((maxpointsF-Nbar)/Nshift)+1;  %Number of data blocks
disp(['  Record length = ' num2str(RecLen) ' seconds']);
disp(['  Block length  = ' num2str(TbarF)  ' seconds']);
disp(['  Block overlap = ' num2str(lap)]);
disp(['  Data blocks   = ' num2str(Dblocks)]);
if Dblocks<10
  disp('Not enough data blocks for ModeMeter scan of this record')
  scanok=0;
else
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/12/2007
    if ~isfield(PSMMacro, 'ModeMeterA_scanok'), PSMMacro.ModeMeterA_scanok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterA_scanok))      % Not in Macro playing mode or selection not defined in a macro
        scanok=promptyn('Proceed with ModeMeter scan of this record?', '');
    else
        scanok=PSMMacro.ModeMeterA_scanok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.ModeMeterA_scanok=scanok;
        else
            PSMMacro.ModeMeterA_scanok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 02/12/2007
    %----------------------------------------------------
end

if scanok  %analyze data with mode meter
  [S1,C1,Rhat1,U1,YY1,Cnd]=MMscanA(MMsigF,Nest,Kcor,Mest,Nbar,lap,srateF,TrackFrqs);
  ExCom=' ';
  ExCom=str2mat(ExCom,'WARNING: In plots of frequency or damping ratio as a function of time,');
  ExCom=str2mat(ExCom,'  outliers may be caused by the Mode Meter choosing the wrong entry ');
  ExCom=str2mat(ExCom,'  from the mode table.  Future logic will deal with this.');
  ExCom=str2mat(ExCom,' ');
  disp(ExCom)
  %plot the results of the mode meter
  %pltstrt2
  MMscanPlots2(caseID,casetime,namesMM,timeF,MMsigF,S1,C1,Nbar,Nshift,Dblocks,srateF,...
    TrackModes,TrackFrqs,autoaxis);
  [RHpoints RHblocks]=size(Rhat1);
  h=figure;  %Initiate new figure
  plot(timeF(1:RHpoints),Rhat1)
  Ptitle{1}=[namesMM(1,:) ' Autocorrelations for Processed Blocks'];
  title(Ptitle)
  xlabel('Shift in seconds')
  ylabel('Autocorrelation')
  h=figure;  %Initiate new figure
  plot(Rhat1(1,:))
  Ptitle{1}=[namesMM(1,:) ' Autocorrelation Energies for Processed Blocks'];
  title(Ptitle)
  xlabel('Block Number')
  ylabel('Autocorrelation Energy')
  h=figure;  %Initiate new figure
  XX=zeros(RHpoints,RHblocks); 
  YY=zeros(RHpoints,RHblocks);
  ZZ=zeros(RHpoints,RHblocks);
  [Rmax loc]=max(Rhat1(1,:)); Rscale=1/Rmax;
  for k=1:RHblocks
    XX(:,k)=timeF(1:RHpoints)';
    YY(:,k)=ones(RHpoints,1)*k;
    ZZ(:,k)=Rhat1(:,k)*Rscale;
  end
  waterfall(XX',YY',ZZ')
  view(8,20)
  xlabel('Shift in seconds')
  %ylabel('Block No.'); 
  zlabel('Autocorrelation')
  Ptitle{1}=[namesMM(1,:) ' Normalized Autocorrelations for Processed Blocks'];
  title(Ptitle)
end
%*************************************************************************

disp(' ')
disp(['In ' FNname ': PROCESSING COMPLETE'])

%----------------------------------------------------
% Begin: Macro selection ZN 02/12/2007
if ~isfield(PSMMacro, 'ModeMeterA_keybdok'), PSMMacro.ModeMeterA_keybdok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterA_keybdok))      % Not in Macro playing mode or selection not defined in a macro
    keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '],'n');
else
    keybdok=PSMMacro.ModeMeterA_keybdok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterA_keybdok=keybdok;
    else
        PSMMacro.ModeMeterA_keybdok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 02/12/2007
%----------------------------------------------------

if keybdok
  disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end

disp(['Return from ' FNname]); disp(' ')

%end of ModeMeter function