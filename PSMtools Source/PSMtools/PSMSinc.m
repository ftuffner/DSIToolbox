function [CaseComF,PSMsigsF,SincDat1,Filtered]...
   =PSMSinc(caseID,casetime,CaseComF,PSMsigsX,tstep,startchan,FilPars)
% Constructs Sinc filters, filters signals if so instructed
%
% [CaseComF,PSMsigsF,SincDat1,Filtered]...
%   =PSMSinc(caseID,casetime,CaseComF,PSMsigsX,tstep,startchan,FilPars)
%
% PSMT functions called from PSMsinc:
%	  PickList1
%   TrfCalcZ
%   db
%   promptyn
%
% Last modified 03/18/02.   jfh
% Last modified 10/20/2006  Ning Zhou to add macro function

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

Filtered=0;

%Initialize plot header
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '    casetime=' casetime];

[maxpoints nsigsX]=size(PSMsigsX);

%*************************************************************************
%Construct Sinc filter
disp(' ');
str1='In PSMSinc: Constructing Sinc filter Sinc1'; disp(str1)
CaseComF=str2mat(CaseComF,str1);
samplerate=1/tstep;
Nyquist=0.5*samplerate;
strs='NOTES:';
strs=str2mat(strs,' a) Filter Sinc0 is a basic Sinc filter of "Sincpts" points');
strs=str2mat(strs,' b) Filter Sinc1 is filter Sinc0 plus a Hamming window');
strs=str2mat(strs,' c) [Sinc0 Sinc1] will have -6 dB corners in the general range');
strs=str2mat(strs,'    of [1 2]*LPcorner.  Just where depends upon SincFac.');
strs=str2mat(strs,' d) Use SincFac=[2 1 0.5] for a [low medium high] order filter');
disp(strs)

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMSinc_SincFac'), PSMMacro.PSMSinc_SincFac=NaN; end
if ~isfield(PSMMacro, 'PSMSinc_LPcorner'), PSMMacro.PSMSinc_LPcorner=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMSinc_SincFac))      % Not in Macro playing mode or selection not defined in a macro
    LPcorner=FilPars(2);   %lowpass corner frequency in Hertz
    SincFac=0.5;	         %high order filter
    disp('Filter settings:')
    disp(sprintf('  LPcorner=%3.3f',LPcorner))
    disp(sprintf('  SincFac= %3.3f',SincFac))
    SincFac=promptyn('In PSMSinc: Is this ok?', 'y');
    if ~SincFac
      strs='In PSMSinc: Invoking "keyboard command for modification of filter values.';
      disp(str2mat(strs,'  Type "return" when you are finished.'))
      keyboard
    end
else
    SincFac=PSMMacro.PSMSinc_SincFac;
    LPcorner=PSMMacro.PSMSinc_LPcorner;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMSinc_SincFac=SincFac;
        PSMMacro.PSMSinc_LPcorner=LPcorner;
    else
        PSMMacro.PSMSinc_SincFac=NaN;
        PSMMacro.PSMSinc_LPcorner=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end

disp(sprintf('  LPcorner=%3.3f',LPcorner))
disp(sprintf('  SincFac= %3.3f',SincFac))
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

 

Nyquist=0.5*samplerate;
ncorner=LPcorner/Nyquist; 
Sincpts=fix(0.5*samplerate/SincFac)*2;	%Force an even number
SincRange=ncorner*(-Sincpts:Sincpts);
I=find(SincRange);
SincWts=ones(size(SincRange));
SincWts(I)=sin(pi*SincRange(I))./(pi*SincRange(I));
HamWts=0.54-0.46*cos(2*pi*(0:2*Sincpts)/(2*Sincpts));
BSinc0=ncorner*SincWts;
BSinc1=BSinc0.*HamWts;
BSinc0=BSinc0/sum(BSinc0);
BSinc1=BSinc1/sum(BSinc1);
SincDat1=sprintf('LPcorner=%5.3f, SincFac= %5.3f',LPcorner,SincFac);
strs=['Sinc1 Parameters: ' SincDat1];
SincDat2=sprintf('ncorner=%5.3f, Sincpts=%5.3i',ncorner, Sincpts);
strs=str2mat(strs,SincDat2);
disp(strs)
CaseComF=str2mat(CaseComF,strs);
%*************************************************************************

%*************************************************************************
%Optional plotting of filter characteristics

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMSinc_plotok'), PSMMacro.PSMSinc_plotok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMSinc_plotok))      % Not in Macro playing mode or selection not defined in a macro
    plotok=promptyn('In PSMSinc: Plot filter characteristics?', 'n');
else
    plotok=PSMMacro.PSMSinc_plotok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMSinc_plotok=plotok;
    else
        PSMMacro.PSMSinc_plotok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if plotok
  figure;
  plot([BSinc0' BSinc1'])
  Ptitle{1}=['weights for Sinc0,Sinc1: ' SincDat1];
  title(Ptitle)
  set(gca,'TickDir','out')
  figure;
  [resp0,f]=TrfCalcZ(BSinc0,1,4096,samplerate);
  [resp1,f]=TrfCalcZ(BSinc1,1,4096,samplerate);
  plot(f,[db(abs(resp0)) db(abs(resp1))]);
  %plot(f,[db(abs(resp1))]); %set(gca,'ylim',[-3 0.1])
  %plot(f,[(abs(resp1))]);   %set(gca,'ylim',[0.95 1.01])   
  Ptitle{1}=['dB gain for Sinc0, Sinc1: ' SincDat1];
  title(Ptitle)
  set(gca,'TickDir','out')
  figure;
  plot(f,[db(abs(resp0)) db(abs(resp1))]);
  title(Ptitle)
  set(gca,'TickDir','out')
  set (gca,'ylim',[-6 6])
  disp('Processing paused - press any key to continue')
  pause
end
%*************************************************************************

%*************************************************************************
%Test for signal filtering
if isempty(PSMsigsX)
  disp('No signals to filter - returning')
  PSMsigsF=PSMsigsX; 
  CaseComF=str2mat(CaseComF,'No signals to filter - returning');
  return
end

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMSinc_setok'), PSMMacro.PSMSinc_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMSinc_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn('In PSMSinc: Filter all signals with filter Sinc1?', 'y');
else
    setok=PSMMacro.PSMSinc_setok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMSinc_setok=setok;
    else
        PSMMacro.PSMSinc_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if ~setok
  disp('No filtering')
  PSMsigsF=PSMsigsX; 
  CaseComF=str2mat(CaseComF,'Signals not filtered');
  return
end
%*************************************************************************

%*************************************************************************
%Filter all signals with filter Sinc1
Filtered=1;
PSMsigsF=ones(maxpoints,nsigsX);
extlen=max(size(BSinc1));
trim=extlen+fix(extlen/2);
for j=startchan:nsigsX
  extsig=[PSMsigsX(extlen:-1:2,j); %start of 3-line statement!
  PSMsigsX(:,j);
  PSMsigsX(maxpoints:-1:maxpoints-extlen,j)];
  temp=conv(BSinc1,extsig);
  temp=temp(trim:length(temp));
  PSMsigsF(:,j)=temp(1:maxpoints);
  %plot([PSMsigsX(:,j) PSMsigsF(:,j)])
end
CaseComF=str2mat(CaseComF,'Signals have been filtered');
%*************************************************************************

return

%end of PSMT utility
