function [CaseComR,RMSkey,RMSnamesX,RMSsigsX,RMSnames,SigMask]...
      =PDCcalcA(caseID,RMSsigsX,SigMask,PMUsigs,PMUfreqs,PMUnames,PhsrNames,...
       tstep,nIphsrs,CaseComR,saveopt,CFname,trackX,nXfile)
	   
% PDCcalcA.m performs rms calculations on PDC phasor data.
%  [CaseComR,RMSkey,RMSnamesX,RMSsigsX,RMSnames,SigMask]...
%      =PDCcalcA(caseID,RMSsigsX,SigMask,PMUsigs,PMUfreqs,PMUnames,PhsrNames,...
%       tstep,nIphsrs,CaseComR,saveopt,trackX,nXfile);
%
% Output RMSsigsX is rms MW and Mvar, plus all phasors and all frequencies
% in polar form.
%
% Extended code for processing phasor measurements data through PSM_Tools.
% Logic is structured for future generalization to PMUs having variable 
% numbers of signals.
%
% Assumed data source is BPA Phasor Data Concentrator (PDC) Unit #2,
% as configured on 04/16/98 (seven PMUs including Sylmar).
%
% Last modified 05/22/01.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


global Kprompt ynprompt
global RMSnames RMSnamesX RMSkey
 
%Conversion Factors 
r2deg=180/pi;    %Radians to degrees

disp(' ')
S1=sprintf('In PDCcalcA: Performing rms calculations for nXfile = %2.0i',nXfile);
disp(S1)
CaseComR=str2mat(CaseComR,S1);

maxpoints=size(PMUsigs,1); Nphsrs=size(PMUsigs,2);
NPMUs=size(PMUfreqs,2);

%************************************************************************
B=' '; L='L'; R='R'; 
text=[PhsrNames(1,:) ' Mvar' B];
chars=size(text,2);
RMSnames='';
Sloc=1; Nloc=1;
for N=1:NPMUs
  RMSnames(Sloc,1:chars)  =[PhsrNames(Nloc,:) ' VMag' B];
  RMSnames(Sloc+1,1:chars)=[PhsrNames(Nloc,:) ' VAng' L];
  RMSnames(Sloc+2,1:chars)=[PhsrNames(Nloc,:) ' Freq' L];
  Sloc=Sloc+3; Nloc=Nloc+1; 
  for nI=1:nIphsrs(N)
	  RMSnames(Sloc,1:chars)  =[PhsrNames(Nloc,:) ' MW  ' B];
	  RMSnames(Sloc+1,1:chars)=[PhsrNames(Nloc,:) ' Mvar' B];
	  RMSnames(Sloc+2,1:chars)=[PhsrNames(Nloc,:) ' IMag' B];
	  RMSnames(Sloc+3,1:chars)=[PhsrNames(Nloc,:) ' IAng' L];
	  Sloc=Sloc+4; Nloc=Nloc+1;
  end
end
RMSnames=str2mat('Time',RMSnames);
%************************************************************************

%************************************************************************
%Define RMS key
%keyboard
text=['% ' sprintf('%3.0i',10) ' ' RMSnames(10,:)];
chars=size(text,2); lines=size(RMSnames,1);
RMSkey='';
for n=1:lines
  text=['% ' sprintf('%3.0i',n) ' ' RMSnames(n,:)];
  RMSkey(n,1:chars)=text;
end
%************************************************************************

%************************************************************************
%Determine signals to keep
if nXfile==1
  [MenuName,SigMask,chansXok]=SetExtPDC(SigMask,RMSnames,RMSkey,CFname);
  CaseComR=str2mat(CaseComR,MenuName);
  if ~chansXok, return, end
end
%************************************************************************

RMSnamesX=RMSnames(SigMask,:);
maxpoints=size(PMUsigs,1); maxsigs=size(RMSnamesX,1);

%************************************************************************
%RMS calculations
RMSsigsX=zeros(maxpoints,maxsigs);   %Initialize storage
KVfac=sqrt(3)*1.e-3; MWfac=1.e-6; KAfac=1.e-3;
i=sqrt(-1);
RMSsigsX(:,1)=[0:maxpoints-1]'*tstep;
Sloc=2; Iloc=1;  
for N=1:NPMUs
  Vloc=Iloc;
  SXloc=(Sloc+0==SigMask); SXX=(sum(SXloc)>0);
  if SXX, RMSsigsX(:,SXloc)=abs(PMUsigs(:,Vloc))*KVfac; end
  SXloc=(Sloc+1==SigMask); SXX=(sum(SXloc)>0);
  if SXX, RMSsigsX(:,SXloc)=PSMunwrap(angle(PMUsigs(:,Vloc))*r2deg); end
  SXloc=(Sloc+2==SigMask); SXX=(sum(SXloc)>0);
  if SXX, RMSsigsX(:,SXloc)=PMUfreqs(:,N); end
  Sloc=Sloc+3; Iloc=Iloc+1;  %Increment counters
  for nI=1:nIphsrs(N)
	SXloc=(Sloc+0==SigMask); SXX=(sum(SXloc)>0);
    if SXX, RMSsigsX(:,SXloc)= 3*real(PMUsigs(:,Vloc).*conj(PMUsigs(:,Iloc)))*MWfac; end
    SXloc=(Sloc+1==SigMask); SXX=(sum(SXloc)>0);
    if SXX, RMSsigsX(:,SXloc)=3*imag(PMUsigs(:,Vloc).*conj(PMUsigs(:,Iloc)))*MWfac; end
	  SXloc=(Sloc+2==SigMask); SXX=(sum(SXloc)>0);
    if SXX, RMSsigsX(:,SXloc)=abs(PMUsigs(:,Iloc))*KAfac; end
    SXloc=(Sloc+3==SigMask); SXX=(sum(SXloc)>0);
    if SXX, RMSsigsX(:,SXloc)=PSMunwrap(angle(PMUsigs(:,Iloc))*r2deg); end
    Sloc=Sloc+4; Iloc=Iloc+1;  %Increment counters
  end
end
%*************************************************************************

%*************************************************************************
if saveopt  %Invoke utility for saving results
  disp(' ')
  disp('In PDCcalcA: Invoking utility for saving RMS results')
  ListName=CFname;
  SaveList=['RMSsigsX tstep RMSnamesX RMSkey CaseComR'];
  PSMsave
end
%*************************************************************************

disp('Returning from PDCcalcA')
return

%end of PSMT utility

