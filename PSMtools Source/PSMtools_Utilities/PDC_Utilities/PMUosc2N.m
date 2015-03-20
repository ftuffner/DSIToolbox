function [CaseCom,namesX,PSMsigsX,ModPars,FreqE]...
   =PMUosc2(caseID,casetime,CaseCom,namesX,PSMsigsX,...
    tstep,decfac,ModType,ModPars,trackX,FullSigName,...
    Tlabel,FreqE);
% Emphirical correction for oscillation in VMag (only)
%
% Special functions used:
%   Butr4
%	  promptyn,promptnv
%   (others?)
%
% Last modified 02/12/03.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

global Kprompt ynprompt nvprompt
 
disp(' ')
FNname='PMUosc2';
disp(['In ' FNname ': Experimental logic for removing parasitic oscillations']);

if ~exist('trackX'), trackX=[]; end
if isempty(trackX),  trackX=2;  end
if ~exist('FullSigName'), FullSigName=''; end
if ~exist('Tlabel'), Tlabel=''; end
if isempty(Tlabel),  Tlabel='Time in Seconds';  end
if ~exist('FreqE'),  FreqE=[]; end

if ~isempty(FullSigName)
  disp(['Phasor signal is ' FullSigName]) 
end

%Conversion Factors & parameters 
r2deg=180/pi;    %Radians to degrees
[maxpoints,nsigs]=size(PSMsigsX);
time=PSMsigsX(:,1);
chankeyX=names2chans(namesX);

%************************************************************************
%Verify/edit processing controls
LEM=2; LEA=3; %For AEP data
Vmag =PSMsigsX(:,LEM);
VangD=PSMsigsX(:,LEA);
 AngFac=2; MagFac=0.0023;
%AngFac=1; MagFac=0.0032;
AngShift=180;  %Likely best value
Efac=MagFac*Vmag(1);
if trackX>=2
  disp('Available signals are')
  disp(chankeyX)
  disp('Signals selected to process are')
  disp(chankeyX(LEM,:));
  disp(chankeyX(LEA,:));
  disp(['In ' FNname ': Signal pointers are'])
  strM=[' LEM= ' sprintf('%2.2i',LEM) ' for voltage magnitude']; 
  strA=[' LEA= ' sprintf('%2.2i',LEA) ' for voltage angle in degrees']; 
  disp(str2mat(strM,strA))
  disp(['In ' FNname ': Parameters for oscillation model are'])
  str1=['[AngFac MagFac Efac AngShift]=[']; 
  str1=[str1 sprintf('%2.2i %6.4f %6.4f %6.2f',[AngFac,MagFac,Efac,AngShift])];
  str1=[str1 ']'];
  disp(str1)
  valsOK=promptyn(['In ' FNname ': Are these values ok? '], 'y');
  if ~valsOK
    disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end
strM=[' LEM= ' sprintf('%2.2i',LEM) ' for voltage magnitude']; 
strA=[' LEA= ' sprintf('%2.2i',LEA) ' for voltage angle in degrees']; 
Vmag =PSMsigsX(:,LEM);
VangD=PSMsigsX(:,LEA);
if trackX>=2
  disp(str2mat(strM,strA))
  figure; plot(Vmag) ; title(['In ' FNname ': Vmag  signal'])
  figure; plot(VangD); title(['In ' FNname ': VangD signal'])
end
%************************************************************************

Efac=MagFac*Vmag(1);
nameE=namesX(LEM,:);
if ~isempty(deblank(FullSigName))
  nameE=deblank(FullSigName);
end
Ptitle{1}=nameE;
Ptitle{2}='';

%************************************************************************
disp(' ')
if trackX>=2
  AscanOK=promptyn(['In ' FNname ': Scan angle shift? '], 'n');
  if AscanOK
    disp(['In ' FNname ': Scanning for best angle shift'])
    for N=1:5  %Scan near 180 degrees
      AngShift=(N-1)*10+160;
      VangE1=(AngFac*VangD+AngShift)/r2deg;
      OscSigE1=Efac*cos(VangE1);
      figure; plot(time,[Vmag OscSigE1+0.99*Vmag(1)]); 
      xlabel(Tlabel)
      str1=['[AngFac MagFac Efac AngShift]=[']; 
      str1=[str1 sprintf('%2.2i %6.4f %6.4f %6.2f',[AngFac,MagFac,Efac,AngShift])];
      str1=[str1 ']'];
      Ptitle{2}=str1; title(Ptitle)
    end
  end
end
%************************************************************************

%************************************************************************
%Summary displays for oscillation model
AngShift=180;  %Likely best value
VangE1=(AngFac*VangD+AngShift)/r2deg;
OscSigE1=Efac*cos(VangE1);
nameE=[nameE ' DeOsc'];
VmagDeOsc=Vmag-OscSigE1;
if trackX>=1
  disp(' ')
  disp(['In ' FNname ': Displays for best angle shift'])
  figure; plot(time,Vmag,'b',time,OscSigE1+0.99*Vmag(1),'r')
  xlabel(Tlabel)
  str1=['[AngFac MagFac Efac AngShift]=[']; 
  str1=[str1 sprintf('%2.2i %6.4f %6.4f %6.2f',[AngFac,MagFac,Efac,AngShift])];
  str1=[str1 ']'];
  Ptitle{2}=str1; title(Ptitle)
  figure; plot(time,Vmag,'b',time,VmagDeOsc,'r') 
  xlabel(Tlabel)
  Ptitle{1}=nameE;
  str1=['[AngFac MagFac Efac AngShift]=[']; 
  str1=[str1 sprintf('%2.2i %6.4f %6.4f %6.2f',[AngFac,MagFac,Efac,AngShift])];
  str1=[str1 ']'];
  Ptitle{2}=str1; title(Ptitle)
end
%************************************************************************

%************************************************************************
%Check details of oscillation model fit
if trackX>=1
  str=['In ' FNname ': Oscillation model fit'];
  if ~isempty(deblank(FullSigName))
    str=[str ' for ' FullSigName];
  end
  disp(str)
  disp('Signals will be bandpass filtered to facilitate comparison')
  ynprompt=0; nvprompt=0; %Suspend prompt controls
  decfac=round(decfac);
  timeD=PSMsigsX(:,1); tstepD=tstep;
  FilSigs=[(PSMsigsX(:,2)-PSMsigsX(1,2)) (OscSigE1-OscSigE1(1))]; 
  if decfac>1
    timeD=timeD(1:decfac:maxpoints);
    tstepD=tstep*decfac;
    FilSigs=FilSigs(1:decfac:maxpoints,:);
  end
  %Determine filter range
  if isempty(FreqE)
    FreqE=PSMsigsX(2:maxpoints,3)-PSMsigsX(1:(maxpoints-1),3);
    FreqE=[FreqE(1) FreqE']'/(tstep*360);
  end 
  figure; plot(time,FreqE)
  xlabel(Tlabel)
  title(['Frequency estimate for ' FullSigName])
  HPC=min(abs(FreqE))/2; LPC=max(abs(FreqE))*2;
  LPC=max(LPC,0.1); LPC=min(LPC,1); 
  HPC=max(HPC,LPC/10); 
  %Filter signals to facilitate comparison
  [CaseComF,FilSigsF,FilData,Filtered]...
    =PSMButr4(caseID,casetime,CaseCom,FilSigs,tstepD,1,[2 2],[HPC LPC]);
  %figure; plot(timeD,FilSigs(:,1),'b',timeD,FilSigs(:,2), 'r')
  %figure; plot(timeD,FilSigs(:,1),'b',timeD,FilSigsF(:,1),'r')
  figure; plot(timeD,FilSigsF(:,1),'b',timeD,FilSigsF(:,2),'r')
  xlabel(Tlabel)
  Ptitle{1}=[FullSigName ': FilData=' FilData];
  title(Ptitle)
end
%************************************************************************
%************************************************************************
%Entry point for interactive diagnostics
if 0&(trackX>=1) %Turned on & off with editor
  keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '], '');
  if keybdok
    disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end
%************************************************************************

%************************************************************************
%Append repaired VMag signal to signal array
PSMsigsX=[PSMsigsX OscSigE1 VmagDeOsc];
MnameE=['Osc Model: [AngShift MagFac]=[' num2str(AngShift) ' ' num2str(MagFac) ']'];
namesX=str2mat(namesX,MnameE,nameE);
chankeyX=names2chans(namesX);
%************************************************************************

%*************************************************************************

Kprompt=0; ynprompt=1; nvprompt=1; %Restore prompt controls

disp('Returning from PMUosc2')
return

%end of PSMT utility