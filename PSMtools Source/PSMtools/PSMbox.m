function [CaseComF,PSMsigsF,FilData,Filtered,ABox,BBox]...
   =PSMbox(caseID,casetime,CaseComF,PSMsigsX,tstep,startchan,FilType,FilPars)
% Constructs boxcar filters, filters signals if so instructed
%
% [CaseComF,PSMsigsF,FilData,Filtered,BBox,ABox]...
%   =PSMbox(caseID,casetime,CaseComF,PSMsigsX,tstep,startchan,FilType,FilPars)
% PSMT functions called from PSMbox:
%	  PickList1
%   TrfCalcZ?
%   db
%   PSMunwrap
%   promptyn
%
% Last modified 09/25/02.   jfh
% Last modified 10/20/2006  Ning Zhou to add macro function

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

Filtered=0; PSMsigsF=PSMsigsX;

disp(' ');
strs='In PSMbox: Constructing Boxcar filter'; disp(strs)
CaseComF=str2mat(CaseComF,strs);

%Initialize plot header
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '    casetime=' casetime];

[maxpoints nsigsX]=size(PSMsigsX);

%*************************************************************************
%Construct Boxcar filter
samplerate=1/tstep;
Nyquist=0.5*samplerate;
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMbox_LPcorner'), PSMMacro.PSMbox_LPcorner=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbox_LPcorner))      % Not in Macro playing mode or selection not defined in a macro
    LPcorner=FilPars(2);   %lowpass corner frequency in Hertz
    disp('Filter settings:')
    disp(sprintf('  LPcorner=%3.3f',LPcorner))
    setok=promptyn('In PSMbox: Is this ok?', 'y');
    if ~setok
      strs='In PSMbox: Invoking "keyboard command for modification of filter values.';
      disp(str2mat(strs,'  Type "return" when you are finished.'))
      keyboard
    end
else
    LPcorner=PSMMacro.PSMbox_LPcorner;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbox_LPcorner=LPcorner;
    else
        PSMMacro.PSMbox_LPcorner=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end

% End: Macro selection ZN 10/18/06
%----------------------------------------------------

tbar=1/LPcorner;
Boxpts=round(tbar*samplerate);     
BB=ones(1,Boxpts); %Set boxcar weights
if length(BB)==0
  str=['In BuildBox: ' FilType ' filter  not recognised'];
	str=str2mat(str,'In PSMbox: Invoking "keyboard" command:');
  disp(str2mat(str,'  Enter "return" when you are finished.'))
  keyboard
end
ABox=1; BBox=BB/sum(BB);
Nyquist=0.5*samplerate;
FilData=sprintf('LPcorner=%5.3f, Boxpts=%5.3i',LPcorner,Boxpts);
strs=str2mat(strs,FilData);
%*************************************************************************

%*************************************************************************
%Optional plotting of filter characteristics

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMbox_plotok'), PSMMacro.PSMbox_plotok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbox_plotok))      % Not in Macro playing mode or selection not defined in a macro
    plotok=promptyn('In PSMBox: Plot filter characteristics?', 'n');
else
    plotok=PSMMacro.PSMbox_plotok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbox_plotok=plotok;
    else
        PSMMacro.PSMbox_plotok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if plotok
  figure; plot([BBox])
  Ptitle{1}=['weights for Boxcar: ' FilData];
  title(Ptitle)
  set(gca,'TickDir','out')     %jfh preference
  [Fresp,f]=TrfCalcZ(BBox,ABox,4096,samplerate);
  Gain=abs(Fresp); Phase=PSMunwrap(angle(Fresp)*360/(2*pi));
  figure;   %Start new figure
  plot(f,db(Gain));
  Ptitle{1}=['dB gain for Boxcar filter: ' FilData];
  title(Ptitle)
  xlabel('Frequency in Hertz'); Ylabel('Gain in dB');
  set (gca,'ylim',[-60 10])
  set(gca,'TickDir','out')     %jfh preference
  figure;   %Start new figure
  plot(f,db(Gain));
  Ptitle{1}=['dB gain for Boxcar filter: ' FilData];
  title(Ptitle)
  xlabel('Frequency in Hertz'); Ylabel('Gain in dB');
  set (gca,'ylim',[-6 6])
  set(gca,'TickDir','out')     %jfh preference
  if 0 %Plot phase response
    [Fresp,f]=TrfCalcZ(BBox,ABox,4096,samplerate); %VERIFY
    [Fresp,f]=freqz(BBox,ABox,4096,samplerate);
    Phase=angle(Fresp)*360/(2*pi);
    figure; plot(f,Phase);
    Ptitle{1}=['Phase response for Boxcar filter: ' FilData];
    title(Ptitle)
    xlabel('Frequency in Hertz'); Ylabel('Phase in Degrees');
    %set(gca,'xlim',[0 2*LPcorner])
    set(gca,'TickDir','out')     %jfh preference
  end
  %Plot step response
  figure;   %Start new figure
  steppts=3*length(BBox);
  steptime=0:(steppts-1);
  steptime=(steptime-9)*tstep;
  stepsig=ones(steppts,1);
  stepsig(1:10)=zeros(10,1);
  stepresp=[stepsig filter(BBox,ABox,stepsig)];
  plot(steptime,stepresp);
  Ptitle{1}=['Step response for Boxcar filter: ' FilData];
  title(Ptitle)
  xlabel('Time in Seconds'); Ylabel('Filter Output');
  set (gca,'ylim',[0 1.2])
  set(gca,'TickDir','out')     %jfh preference
  keybdok=promptyn('In PSMBox: Do you want the keyboard? ', 'n');
  if keybdok
    disp('In PSMBox: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
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
if ~isfield(PSMMacro, 'PSMbox_setok'), PSMMacro.PSMbox_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbox_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn('In PSMbox: Filter all signals with filter Box?', 'y');
else
    setok=PSMMacro.PSMbox_setok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbox_setok=setok;
    else
        PSMMacro.PSMbox_setok=NaN;
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
%Filter all signals with filter Box
disp('Filtering signals:')
Filtered=1;
extlen=max(size(BBox));
trim=extlen+fix(extlen/2);
PSMsigsF=ones(maxpoints,nsigsX);
for j=startchan:nsigsX
  extsig=[PSMsigsX(extlen:-1:2,j); %start of 3-line statement!
  PSMsigsX(:,j);
  PSMsigsX(maxpoints:-1:maxpoints-extlen,j)];
  temp=conv(BBox,extsig);
  temp=temp(trim:length(temp));
  PSMsigsF(:,j)=temp(1:maxpoints);
  %plot([PSMsigsX(:,j) PSMsigsF(:,j)])
end
CaseComF=str2mat(CaseComF,'Signals have been filtered');
%*************************************************************************

return

%end of PSMT utility
