function [CaseComF,PSMsigsF,FilData,Filtered]...
   =PSMButr4(caseID,casetime,CaseComF,PSMsigsX,tstep,startchan,FilType,FilPars)
%Constructs 4th-order Butterworth filter, filters signals if so instructed
%
%  [CaseComF,PSMsigsF,FilData]...
%    =PSMButr4(caseID,casetime,CaseComF,PSMsigsX,tstep,startchan,FilPars)
%
% PSMT functions called from PSMButr4:
%	  PickList1
%   EZbutter (else BUTTER)
%   TrfCalcZ
%   db
%   promptyn
%
% Last modified 01/20/03.   jfh
% Last modified 04/05/04. Henry Huang
% Last modified 07/12/05 by Henry Huang.  Changed some defaults & prompts
% Last modified 10/18/2006 by Ning Zhou.  Add the Macro function

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
%keyboard
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

Filtered=0;

disp(' ')
strs='In PSMButr4: Constructing Butterworth filter:'; disp(strs)
CaseComF=str2mat(CaseComF,strs);

%*************************************************************************
%Initialize plot header
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '    casetime=' casetime];
[maxpoints nsigsX]=size(PSMsigsX);
%*************************************************************************

%*************************************************************************
%Construct Butterworth Filter
samplerate=1/tstep;
Nyquist=0.5*samplerate;
FilTypes=['LP';'BP';'HP'];
disp('  ')
locbase=1; maxtrys=5;

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMbutr4_FilTypeok'), PSMMacro.PSMbutr4_FilTypeok=NaN; end
if ~isfield(PSMMacro, 'PSMbutr4_FilName'), PSMMacro.PSMbutr4_FilName=NaN; end
if ~isfield(PSMMacro, 'PSMbutr4_FilType_2'), PSMMacro.PSMbutr4_FilType_2=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbutr4_FilTypeok))      % Not in Macro playing mode or selection not defined in a macro
    [FilType(2),FilName,FilTypeok]=PickList1(FilTypes,FilType(2),locbase,maxtrys);
else
    FilTypeok=PSMMacro.PSMbutr4_FilTypeok;
    FilName=PSMMacro.PSMbutr4_FilName;
    FilType(2)=PSMMacro.PSMbutr4_FilType_2;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbutr4_FilTypeok=FilTypeok;
        PSMMacro.PSMbutr4_FilName=FilName;
        PSMMacro.PSMbutr4_FilType_2=FilType(2);
    else
        PSMMacro.PSMbutr4_FilTypeok=NaN;
        PSMMacro.PSMbutr4_FilName=NaN;
        PSMMacro.PSMbutr4_FilType_2=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%[FilType(2),FilName,FilTypeok]=PickList1(FilTypes,FilType(2),locbase,maxtrys);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if ~FilTypeok
  disp('In PSMButr4: Filter type not determined')
  disp('  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end
disp(['  FilType=' FilName])
FilOrd=4;
HPcorner=FilPars(1); LPcorner=FilPars(2);
filparsok=0;
maxtrys=5;

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMbutr4_HPnorm'), PSMMacro.PSMbutr4_HPnorm=NaN; end
if ~isfield(PSMMacro, 'PSMbutr4_LPnorm'), PSMMacro.PSMbutr4_LPnorm=NaN; end
if ~isfield(PSMMacro, 'PSMbutr4_FilOrd'), PSMMacro.PSMbutr4_FilOrd=NaN; end
if ~isfield(PSMMacro, 'PSMbutr4_CheckFil'), PSMMacro.PSMbutr4_CheckFil=NaN; end
%keyboard
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbutr4_HPnorm) || isnan(PSMMacro.PSMbutr4_LPnorm))      % Not in Macro playing mode or selection not defined in a macro
    for N=1:maxtrys
      HPnorm=HPcorner/Nyquist; LPnorm=LPcorner/Nyquist;
      CheckFil=min(HPnorm,LPnorm)<0.005;
      CheckFil=CheckFil&FilOrd>2;
      if CheckFil
        disp(' ')
        strW='WARNING: ';
        strW=str2mat(strW,'  One or more corner frequencies are small fractions of Nyquist frequency');
        strW=str2mat(strW,'  -- Watch for evidence of numerical instabilities.');
        strW=str2mat(strW,'  Fix is to terminate this processing step, then rerun it using');
        strW=str2mat(strW,'  data decimation, lower filter order, or corner frequency revisions.');   
        strW=str2mat(strW,'  OBSERVE VALUES BELOW PLUS LATER PLOT OF FILTER RESPONSE');
        disp(strW); disp(' ')
      end
      disp('Filter Settings:')
      if FilType(2) ~=1
        disp(sprintf('  HPcorner=%6.2f Hz (%2.4f Nyquist)',[HPcorner HPnorm]))
      end
      if FilType(2) ~=3
        disp(sprintf('  LPcorner=%6.2f Hz (%2.4f Nyquist)',[LPcorner LPnorm]))
        end
      disp(sprintf('  FilOrd  =%6.0i',FilOrd))
      filparsok=promptyn('In PSMButr4: Is this ok? ', 'y');

      if ~filparsok
        disp('  Invoking "keyboard" command - Enter "return" when you are finished')
        keyboard
      else
        HPnorm=HPcorner/Nyquist; LPnorm=LPcorner/Nyquist;
        break
      end
    end
else
    HPnorm=PSMMacro.PSMbutr4_HPnorm;
    LPnorm=PSMMacro.PSMbutr4_LPnorm;
    FilOrd=PSMMacro.PSMbutr4_FilOrd;
    CheckFil=PSMMacro.PSMbutr4_CheckFil;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbutr4_HPnorm=HPnorm;
        PSMMacro.PSMbutr4_LPnorm=LPnorm;
        PSMMacro.PSMbutr4_FilOrd=FilOrd;
        PSMMacro.PSMbutr4_CheckFil=CheckFil;
    else
        PSMMacro.PSMbutr4_HPnorm=NaN;
        PSMMacro.PSMbutr4_LPnorm=NaN;
        PSMMacro.PSMbutr4_FilOrd=NaN;
        PSMMacro.PSMbutr4_CheckFil=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% 
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if ~filparsok
  disp('In PSMbutr4: Filter parameters not established -- using initial values')
  FilOrd=4;
  HPcorner=FilPars(1); LPcorner=FilPars(2);
end
HPnorm=HPcorner/Nyquist; LPnorm=LPcorner/Nyquist;
strs=['  Filter type is [' num2str(FilType) ']'];
AddOn=deblank(which('butter'));  %Check presence of signal processing add-on
AddOn=~isempty(AddOn);
if AddOn
  str1='Using filter synthesis function BUTTER';  disp(str1)
  strs=str2mat(strs,str1);
  if FilType(2)==1
    FilData=sprintf('LPcorner = %6.2f  Hz', LPcorner);
    [Bbutter,Abutter]=butter(FilOrd,[LPnorm]);
  end
  if FilType(2)==2
    FilData=sprintf('HPcorner = %6.2f LPcorner = %6.2f  Hz', HPcorner, LPcorner);
    [Bbutter,Abutter]=butter(FilOrd,[HPnorm LPnorm]);
  end
  if FilType(2)==3
    FilData=sprintf('HPcorner = %6.2f  Hz', HPcorner);
    [Bbutter,Abutter]=butter(FilOrd,HPnorm,'high');
  end
end
if ~AddOn
  str1='Using filter synthesis function EZBUTTER';  disp(str1)
  strs=str2mat(strs,str1);
  if FilType(2)==1
    FilData=sprintf('LPcorner = %6.2f  Hz', LPcorner);
    [Bbutter,Abutter]=ezbutter(FilOrd,LPnorm,LPnorm,'low');
  end
  if FilType(2)==2
    FilData=sprintf('HPcorner = %6.2f LPcorner = %6.2f  Hz', HPcorner, LPcorner);
    [Bbutter,Abutter]=ezbutter(FilOrd,HPnorm,LPnorm,'pass');
  end
  if FilType(2)==3
    FilData=sprintf('HPcorner = %6.2f  Hz', HPcorner);
    [Bbutter,Abutter]=ezbutter(FilOrd,HPnorm,HPnorm,'high');
  end
end
FilSize=sprintf('length(B,A)=[%4.0i %4.0i]', size(Bbutter,2),size(Abutter,2));
strs=str2mat(strs,FilData,FilSize);
CaseComF=str2mat(CaseComF,strs);
if CheckFil
  str='WARNING: Filter might not be stable';
    disp(str); CaseComF=str2mat(CaseComF,str); 
end
%*************************************************************************

%*************************************************************************
%Optional plotting of filter characteristics
deftag='n'; if CheckFil, deftag='y'; end
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMbutr4_plotok'), PSMMacro.PSMbutr4_plotok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbutr4_plotok))      % Not in Macro playing mode or selection not defined in a macro
    plotok=promptyn('In PSMButr4: Plot filter characteristics? ', deftag);
else
    plotok=PSMMacro.PSMbutr4_plotok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbutr4_plotok=plotok;
    else
        PSMMacro.PSMbutr4_plotok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% plotok=promptyn('In PSMButr4: Plot filter characteristics? ', deftag);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


FilName=['Butter' num2str(FilOrd)];
if plotok
  %Plot gain response
  figure;   %Start new figure
  [Fresp,f]=TrfCalcZ(Bbutter,Abutter,1024,samplerate);
  Gain=abs(Fresp); Phase=PSMunwrap(angle(Fresp)*360/(2*pi));
  plot(f,db(Gain));
  Ptitle{1}=['dB gain for ' FilName ' filter: ' FilData];
  title(Ptitle)
  xlabel('Frequency in Hertz'); Ylabel('Gain in dB');
  set (gca,'ylim',[-60 10])
  set(gca,'TickDir','out')     %jfh preference
  %Plot phase response
  figure;   %Start new figure
  plot(f,Phase);
  Ptitle{1}=['Phase response for ' FilName ' filter: ' FilData];
  title(Ptitle)
  xlabel('Frequency in Hertz'); Ylabel('Phase in Degrees');
  %set (gca,'xlim',[0 2])
  set(gca,'TickDir','out')     %jfh preference
  %Plot step response
  figure;   %Start new figure
  if FilType(2)==1, steppts=fix(5/(LPcorner*tstep)); end
  if FilType(2)==2, steppts=fix(5/(HPcorner*tstep)); end
  if FilType(2)==3, steppts=500; end
  steptime=0:(steppts-1);
  steptime=(steptime-9)*tstep;
  stepsig=ones(steppts,1);
  stepsig(1:10)=zeros(10,1);
  stepresp=[stepsig filter(Bbutter,Abutter,stepsig)];
  plot(steptime,stepresp);
  Ptitle{1}=['Step response for ' FilName ' filter: ' FilData];
  title(Ptitle)
  xlabel('Time in Seconds'); Ylabel('Filter Output');
  set(gca,'TickDir','out')     %jfh preference
  
  if PSMMacro.RunMode<1
      keybdok=promptyn(['In PSMButr4: Do you want the keyboard? '], 'n');
      if keybdok
        disp('In PSMButr4: Invoking "keyboard" command - Enter "return" when you are finished')
        keyboard
      end
  end
  
end
%*************************************************************************

%*************************************************************************
%Test for signal filtering

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PSMbutr4_setok'), PSMMacro.PSMbutr4_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMbutr4_setok))      % Not in Macro playing mode or selection not defined in a macro
    deftag='y'; % if CheckFil, deftag=''; end       % use 'y' as default. Henry 07/12/05 
    setok=promptyn('In PSMButr4: Filter all signals? ', deftag);
else
    setok=PSMMacro.PSMbutr4_setok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMbutr4_setok=setok;
    else
        PSMMacro.PSMbutr4_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% deftag='y'; % if CheckFil, deftag=''; end       % use 'y' as default. Henry 07/12/05 
% setok=promptyn('In PSMButr4: Filter all signals? ', deftag);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if ~setok
  if CheckFil, disp('WARNING: Filter might not be stable'); end
  disp('No filtering')
  PSMsigsF=PSMsigsX; 
  CaseComF=str2mat(CaseComF,'Signals not filtered');
  return
end
%*************************************************************************

%*************************************************************************
%Filter all signals
disp('Filtering signals:')
Filtered=1;
extlen=fix(min(maxpoints/2,500));
trim=extlen;
PSMsigsF=ones(maxpoints,nsigsX);
for j=startchan:nsigsX
  extsig=[PSMsigsX(extlen:-1:2,j);	%extend for filter transients
  PSMsigsX(:,j);
  PSMsigsX(maxpoints:-1:maxpoints-extlen,j)];
  temp=filter(Bbutter,Abutter,extsig);
  PSMsigsF(:,j)=temp(trim:maxpoints+trim-1);
end
NF=nsigsX-startchan+1;
str=['In PSMButr4: ' num2str(NF) ' Signals have been filtered'];
disp(str);
CaseComF=str2mat(CaseComF,str);
%*************************************************************************

return

%end of PSMT utility
