function  [CaseComF,PSMsigsF,FilData,Filtered]...
    =SincHP(caseID,casetime,CaseCom,PSMsigsX,tstep,startchan,FilType,FilPars);
%Bandpass filter based upon Hanned-Sinc filter
%Code extends TRIG2 FORTRAN original, with graphics code added.
%Uses Hanned Sync function as basis for filter construction
%
% [CaseComF,PSMsigsF,FilData,Filtered]...
%   =SincHP(caseID,casetime,CaseCom,PSMsigsX,tstep,startchan,FilType,FilPars);
%
% Special functions used:
%   TrigSync
%   TrfCalcZ
%   db
%   promptyn
%   
% Last modified 12/03/04.   jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
% Last modified 10/20/2006  Ning Zhou to add macro function

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------


Filtered=0;

disp(' ')
strs='In SincHP: Constructing Bandpass filter based upon Hanned-Sinc filter'; 
disp(strs)
CaseComF=str2mat(CaseCom,strs);

if isempty(tstep), tstep=0;    end
if tstep<=0,       tstep=0.05; end

%Initialize plot header
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '    casetime=' casetime];

[maxpoints nsigs]=size(PSMsigsX);
FilData='';

track=0;
samplerate=1/tstep;


%*************************************************************************
%Construct basic filters
CaseComF='##Tuning Trigger Filters';
disp('In SincHP: Constructing basic filters')
str='LowPass 1'; disp(' '); disp(str)
%keyboard;

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'SincHP_BSincH1'), PSMMacro.SincHP_BSincH1=[]; end
if (PSMMacro.RunMode<1 || isempty(PSMMacro.SincHP_BSincH1))      % Not in Macro playing mode or selection not defined in a macro
    [BSincH1]=TrigSync(str,1.5,1.0,tstep,track);
else
    BSincH1=PSMMacro.SincHP_BSincH1;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SincHP_BSincH1=BSincH1;
    else
        PSMMacro.SincHP_BSincH1=[];
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


MHIST1=max(size(BSincH1));
str='LowPass 2'; disp(' '); disp(str)
%[BSincH2]=TrigSync(str,0.16,0.125,tstep,track);

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'SincHP_BSincH2'), PSMMacro.SincHP_BSincH2=[]; end
if (PSMMacro.RunMode<1 || isempty(PSMMacro.SincHP_BSincH2))      % Not in Macro playing mode or selection not defined in a macro
    [BSincH2]=TrigSync(str,0.10,0.125,tstep,track);
else
    BSincH2=PSMMacro.SincHP_BSincH2;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SincHP_BSincH2=BSincH2;
    else
        PSMMacro.SincHP_BSincH2=[];
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



MHIST2=max(size(BSincH2));
str='LowPass 3'; disp(' '); disp(str)

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'SincHP_BSincH3'), PSMMacro.SincHP_BSincH3=[]; end
if (PSMMacro.RunMode<1 || isempty(PSMMacro.SincHP_BSincH3))      % Not in Macro playing mode or selection not defined in a macro
    [BSincH3]=TrigSync(str,0.25,0.25,tstep,track);
else
    BSincH3=PSMMacro.SincHP_BSincH3;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SincHP_BSincH3=BSincH3;
    else
        PSMMacro.SincHP_BSincH3=[];
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



MHIST3=max(size(BSincH3));
HPSDEL=fix(MHIST2/2);
MHIST=[MHIST1 MHIST2 MHIST3];
MaxHist=max(MHIST);
HMT=zeros(MaxHist,3);
HMT(1:MHIST1,1)=BSincH1';
HMT(1:MHIST2,2)=BSincH2';
HMT(1:MHIST3,3)=BSincH3';
BHP0=[zeros(max(HPSDEL,MHIST2),1)];
BHP0(1:MHIST2)=HMT(1:MHIST2,2); %VERIFY ALL THIS LATER
BHP1=-BHP0; BHP1(HPSDEL)=-BHP0(HPSDEL)+1;
HP1dat=sprintf('HPSDEL=%5.3i',HPSDEL);
%keyboard
%*************************************************************************

%*************************************************************************
%Optional plotting of basic filter characteristics
disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'SincHP_plotok'), PSMMacro.SincHP_plotok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.SincHP_plotok))      % Not in Macro playing mode or selection not defined in a macro
    plotok=promptyn('In PSMSinc: Plot basic filter characteristics?', 'n');
else
    plotok=PSMMacro.SincHP_plotok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SincHP_plotok=plotok;
    else
        PSMMacro.SincHP_plotok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% plotok=promptyn('In PSMSinc: Plot basic filter characteristics?', 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if plotok
disp(' ')
disp('In SincHP: Displays for basic filter responses')
h=figure; plot(HMT)
Ptitle{1}=['Filter Weights'  ];
title(Ptitle)
set(gca,'TickDir','out')
[resp1,f]=freqz(HMT(1:MHIST1,1),1,4096,samplerate);
h=figure;
plot(f,[db(abs(resp1))]);
LP1dat=sprintf('MHIST1=%5.3i',MHIST1);
title(['dB gain for Filter LP1: ' LP1dat])
xlabel('Frequency in Hertz'); set(gca,'TickDir','out')
%set (gca,'ylim',[-6 6])
%LP2 frequency response
[resp1,f]=freqz(HMT(1:MHIST2,2),1,4096,samplerate);
h=figure;
plot(f,[db(abs(resp1))]);
LP2dat=sprintf('MHIST2=%5.3i',MHIST2);
title(['dB gain for Filter LP2: ' LP2dat])
xlabel('Frequency in Hertz'); set(gca,'TickDir','out')
%set (gca,'ylim',[-6 6])
%LP3 frequency response
[resp1,f]=freqz(HMT(1:MHIST3,3),1,4096,samplerate);
h=figure;
plot(f,[db(abs(resp1))]);
LP3dat=sprintf('MHIST3=%5.3i',MHIST3);
title(['dB gain for Filter LP3: ' LP3dat])
xlabel('Frequency in Hertz'); set(gca,'TickDir','out')
%set (gca,'ylim',[-6 6])
end  %Terminate display
%*************************************************************************

%*************************************************************************
%Optional plotting of HP filter characteristics
disp(' ')

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'SincHP_plotok02'), PSMMacro.SincHP_plotok02=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.SincHP_plotok02))      % Not in Macro playing mode or selection not defined in a macro
    plotok=promptyn('In PSMSinc: Plot HP filter characteristics?', 'n');
else
    plotok=PSMMacro.SincHP_plotok02;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SincHP_plotok02=plotok;
    else
        PSMMacro.SincHP_plotok02=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% plotok=promptyn('In PSMSinc: Plot basic filter characteristics?', 'n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if plotok
%HP1 weights
disp(' ')
disp('In SincHP: Displays for HP filter response')
h=figure;
plot([BHP0])
title(['Weights BHP0: ' HP1dat])
xlabel('Time in Samples')
h=figure;
plot([BHP0 BHP1])
title(['Weights BHP0,BHP1: ' HP1dat])
xlabel('Time in Samples')
%HP1 frequency response
[resp1,f]=freqz(BHP1,1,4096,samplerate);
h=figure;
plot(f,[db(abs(resp1))]);
title(['dB gain for Filter BHP1: ' HP1dat])
xlabel('Frequency in Hertz')
set(gca,'TickDir','out')
h=figure;
plot(f,[db(abs(resp1))]);
title(['dB gain detail for Filter BHP1: ' HP1dat])
xlabel('Frequency in Hertz')
set(gca,'TickDir','out')
set (gca,'ylim',[-60 6]); set (gca,'xlim',[0 1])
end  %Terminate display
%*************************************************************************

%*************************************************************************
%Test for signal filtering
disp(' ')

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'SincHP_setok'), PSMMacro.SincHP_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.SincHP_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn('In SincHP: Filter all signals with filter SincHP?', 'y');
else
    setok=PSMMacro.SincHP_setok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.SincHP_setok=setok;
    else
        PSMMacro.SincHP_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% setok=promptyn('In SincHP: Filter all signals with filter SincHP?', 'y');
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
disp('Filtering signals:')
Filtered=1;
extlen=max(size(BHP1));
trim=extlen+fix(extlen/2)-1; 
PSMsigsF=ones(maxpoints,nsigs);
for j=startchan:nsigs
  extsig=[PSMsigsX(extlen:-1:2,j); %start of 3-line statement!
  PSMsigsX(:,j);
  PSMsigsX(maxpoints:-1:maxpoints-extlen,j)];
  temp=conv(BHP1,extsig);
  temp=temp(trim:length(temp));
  PSMsigsF(:,j)=temp(1:maxpoints);
  %plot([PSMsigsX(:,j) PSMsigsF(:,j)])
end
CaseComF=str2mat(CaseComF,'Signals have been filtered');
%*************************************************************************

return

%*************************************************************************
%Start of supressed code
str='Filtering all signals with recursive logic'; disp(str)
extlen=max(size(BHP1));
trim=extlen+fix(MHIST1/2)+HPSDEL;
PSMsigsF=ones(maxpoints,nsigs);
for j=startchan:nsigs
  Sigin=[PSMsigsX(extlen:-1:2,j); %start of 3-line statement!
  PSMsigsX(:,j);
  PSMsigsX(maxpoints:-1:maxpoints-extlen,j)];
  SigLP1=conv(Sigin,HMT(:,1));
  SigLP2=conv(SigLP1,HMT(:,2));
  histlen=max(size(SigLP1));
  SigLP1lag=zeros(histlen,1);
  SigLP1lag(HPSDEL+1:histlen)=SigLP1(1:histlen-HPSDEL);
  SigHP1=SigLP1lag-SigLP2(1:histlen);
  temp=SigHP1;
  temp=temp(trim:length(temp));
  PSMsigsFN(:,j)=temp(1:maxpoints);
  %plot([PSMsigsX(:,j) PSMsigsF(:,j)])
end
CaseComF=str2mat(CaseComF,'Signals have been filtered');
%*************************************************************************

return

%[Old code for filter & activity calculations]
disp(' ')
disp('In SincHP: Filter & activity calculations')
SigLP1=conv(Sigin,HMT(:,1));
SigLP2=conv(SigLP1,HMT(:,2));
histlen=max(size(SigLP1));
SigLP1lag=zeros(histlen,1);
SigLP1lag(HPSDEL+1:histlen)=SigLP1(1:histlen-HPSDEL);
SigHP1=SigLP1lag-SigLP2(1:histlen);
RAWACT=abs(SigHP1);
OUTACT=conv(RAWACT,HMT(:,3));

return

%end of PSMT utility

