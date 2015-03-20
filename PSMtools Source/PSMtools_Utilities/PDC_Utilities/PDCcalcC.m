function [CaseComR,RMSkey,RMSnamesX,RMSsigsX,RMSnames,chansX, chansXok]...
      =PDCcalcC(caseID,RMSsigsX,chansX,PMUsigs,PMUfreqs,PMUnames,PhsrNames,...
       tstep,VIcon,CaseComR,CFname,trackX,nXfile,GPSlost,chansXok )
	   
% PDCcalcC.m performs rms calculations on PDC phasor data.
%  [CaseComR,RMSkey,RMSnamesX,RMSsigsX,RMSnames,chansX]...
%      =PDCcalcC(caseID,RMSsigsX,chansX,PMUsigs,PMUfreqs,PMUnames,PhsrNames,...
%       tstep,VIcon,CaseComR,CFname,saveopt,trackX,nXfile,GPSlost);
%
% Output RMSsigsX is rms MW and Mvar, plus all phasors and all frequencies
% in polar form.
%
% Extended code for processing phasor measurements data through PSM_Tools.
% NOMENCLATURE WARNINGS:
%   - PSMsigsX  is an array extracted from any PSM (power system monitor)
%   - PDC RMS signals are numbered [1:N]
%   - Signals to extract are numbered [1:N+1], with time axis at column 1
%
% This version uses .ini files that specify PDC configuration.
%
% Special functions used:
%   SetExtPDC
%	promptyn,promptnv
%   PSMsave
%
% Modified 07/06/04.  jfh  Comments
% Modified 04/05/06.  zn   selection of channels before patching data 


% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

global Kprompt ynprompt nvprompt
global RMSnames RMSnamesX RMSkey


%********************************************************************
% add by ZN on 04/05/2006 for channel selection before repairing
% 1.0 Check the arguments
if (nargin < 15);chansXok=[];end
if (isempty(chansXok));  chansXok=0; end;        % default is default key
% add by ZN on 04/05/2006 for channel selection before repairing
%********************************************************************

%Conversion Factors 
r2deg=180/pi;    %Radians to degrees

disp(' ')
S1=sprintf('In PDCcalcC: Performing rms calculations for nXfile = %2.0i',nXfile);
disp(S1)
CaseComR=str2mat(CaseComR,S1);

maxpoints=size(PMUsigs,1); Nphsrs=size(PMUsigs,2);
NPMUs=size(PMUfreqs,2);

%************************************************************************
text=[PhsrNames(1,:,1) ' VAng' '  '];
chars=size(text,2);
RMSnames='';
Sloc=1;
PMUbase=zeros(NPMUs+1,1);
for K=1:NPMUs
  AngTag='L '; if GPSlost(K), AngTag='LX'; end 
  nphsrsK=sum(VIcon(:,1,K)==1|VIcon(:,1,K)==2);
    for N=1:nphsrsK
	  loc=PMUbase(K)+N;
	  phsrtype=VIcon(N,1,K);
	  if phsrtype==1
      RMSnames(Sloc+0,1:chars)=[PhsrNames(N,:,K) ' VMag' '  '  ];
      RMSnames(Sloc+1,1:chars)=[PhsrNames(N,:,K) ' VAng' AngTag];
	    Sloc=Sloc+2;
      if N==1
        RMSnames(Sloc,1:chars)=[PhsrNames(N,:,K) ' Freq' AngTag];
		Sloc=Sloc+1;
	  end
    end
	  if phsrtype==2
        RMSnames(Sloc+0,1:chars)=[PhsrNames(N,:,K) ' MW  ' '  '  ];
	    RMSnames(Sloc+1,1:chars)=[PhsrNames(N,:,K) ' Mvar' '  '  ];
	    RMSnames(Sloc+2,1:chars)=[PhsrNames(N,:,K) ' IMag' '  '  ];
	    RMSnames(Sloc+3,1:chars)=[PhsrNames(N,:,K) ' IAng' AngTag];
      Sloc=Sloc+4;
    end
    if phsrtype~=1&phsrtype~=2
	  disp(['In PDCcalcC: Unrecognized phasor type = ',sprintf('%4.0i',phsrtype)])
	  pause
	end
  end
  PMUbase(K+1)=PMUbase(K)+nphsrsK;
end
RMSnames=str2mat('Time',RMSnames);
%************************************************************************

%************************************************************************
%Define RMS key
RMSkey=names2chans(RMSnames);
%************************************************************************

%************************************************************************
%Determine rms signals to extract
%disp('In PDCcalcC:'), keyboard
if nXfile==1 && chansXok==0
  [MenuName,chansX,chansXok]=SetExtPDC(chansX,RMSnames,RMSkey,CFname);
  if ~chansXok, disp('No menu selected - return'), return, end
  str1=['Starting menu = ' MenuName];
  CaseComR=str2mat(CaseComR,str1);
  nsigs=max(size(chansX));
  str1='chansX='; disp(str1)
  CaseComR=str2mat(CaseComR,str1);
  for n1=1:15:nsigs
    n2=min(n1+15-1,nsigs);
    str1=[' ' num2str(chansX(n1:n2))]; 
    if n1==1, str1(1)='['; end
    if n2==nsigs, str1=[str1 ']']; end
    disp(str1)
    CaseComR=str2mat(CaseComR,str1);
  end
end
%************************************************************************

RMSnamesX=RMSnames(chansX,:);
maxpoints=size(PMUsigs,1); maxsigs=size(RMSnamesX,1);

%************************************************************************
%RMS calculations
RMSsigsX=zeros(maxpoints,maxsigs);    %Initialize storage
KVfac=sqrt(3)*1.e-3; MWfac=1.e-6; KAfac=1.e-3;
i=sqrt(-1);
RMSsigsX(:,1)=[0:maxpoints-1]'*tstep; %Time axis
Sloc=2; Phloc=1;
PMUbase=zeros(NPMUs+1,1);
for K=1:NPMUs
  nphsrsK=sum(VIcon(:,1,K)==1|VIcon(:,1,K)==2);
  for N=1:nphsrsK
	loc=PMUbase(K)+N;
	phsrtype=VIcon(N,1,K);
	if phsrtype==1
	  Vloc=Phloc;
	  SXloc=find(Sloc+0==chansX); SXX=size(SXloc,2); %Voltage magnitude
    for n=1:SXX, RMSsigsX(:,SXloc(n))=abs(PMUsigs(:,Vloc))*KVfac; end
    SXloc=find(Sloc+1==chansX); SXX=size(SXloc,2);  %Voltage angle
    for n=1:SXX, RMSsigsX(:,SXloc(n))=PSMunwrap(angle(PMUsigs(:,Vloc))*r2deg); end
	  Sloc=Sloc+2;    %Increment signal counter 
	  if N==1
        SXloc=find(Sloc+0==chansX); SXX=size(SXloc,2); %Frequency
		for n=1:SXX, RMSsigsX(:,SXloc(n))=PMUfreqs(:,K); end
	    Sloc=Sloc+1;    %Increment signal counter 
	  end
      Phloc=Phloc+1;  %Increment phasor counter
    end
    if phsrtype==2
	  Vref=VIcon(N,6,K);
	  if Vref>0, Vloc=PMUbase(K)+Vref; end
	  SXloc=find(Sloc+0==chansX); SXX=size(SXloc,2);    %Real power
      for n=1:SXX, RMSsigsX(:,SXloc(n))=3*real(PMUsigs(:,Vloc).*conj(PMUsigs(:,Phloc)))*MWfac; end
      SXloc=find(Sloc+1==chansX); SXX=size(SXloc,2);    %Reactive power
      for n=1:SXX, RMSsigsX(:,SXloc(n))=3*imag(PMUsigs(:,Vloc).*conj(PMUsigs(:,Phloc)))*MWfac; end
	    SXloc=find(Sloc+2==chansX); SXX=size(SXloc,2);   %Current magnitude
      for n=1:SXX, RMSsigsX(:,SXloc(n))=abs(PMUsigs(:,Phloc))*KAfac; end
      SXloc=find(Sloc+3==chansX); SXX=size(SXloc,2);     %Current angle
      for n=1:SXX, RMSsigsX(:,SXloc(n))=PSMunwrap(angle(PMUsigs(:,Phloc))*r2deg); end
      Sloc=Sloc+4; Phloc=Phloc+1;  %Increment counters
    end
    if phsrtype~=1&phsrtype~=2
	  disp(['In PDCcalcC: Unrecognized phasor type = ',sprintf('%4.0i',phsrtype)])
	  pause
	end
  end
  PMUbase(K+1)=PMUbase(K)+nphsrsK;
end
%*************************************************************************

disp('Returning from PDCcalcC')
disp(' ')
return

%end of PSMT function