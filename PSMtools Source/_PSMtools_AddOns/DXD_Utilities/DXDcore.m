function [corWsum] = DXDcore(Wsig,tstep,delays,reffrq,Pscale,Gtags,trackDXD)
% Forms sine/cosine projections for 1-phase or 3-phase digital transducers
%
% This is a prototype production version 
%
% NOTE: NEXT VERSION SHOULD REDUCE WORKING STORAGE
% 
% PSMT functions called from DXDcore:
%	  Sigplot
%   Ringdown
%   promptyn
%
% Last modified 11/24/03.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


disp(' ')
disp('In DXDcore:') 
samplerate=1/tstep;
disp(['  reffrq=' num2str(reffrq) '  samplerate= ' num2str(samplerate)])

%Determine number of phase signals
[maxpoints nsigs]=size(Wsig);
disp(['  nsigs =' num2str(nsigs)])

if 0
  time=[0:(maxpoints-1)]'*tstep;
  SigNames=str2mat('POWsigA','POWsigB','POWsigC');
  SigNames=str2mat(SigNames(1:nsigs,:));
  ringdown([time Wsig],SigNames,[],[],'');
  PRSdisp1('DXDcore point-on-wave signals:','','',SigNames,[time Wsig],tstep);
end

%Construct sinusoidal reference signals
Rangstep=tstep*reffrq*2*pi;
xsig=[0:(maxpoints-1)]'*Rangstep;

%Assumes no inter-channel skew
refrot=[0 -2*pi/3 2*pi/3];
refcos=ones(maxpoints,nsigs);
refsin=ones(maxpoints,nsigs);
if nsigs==1
  refcos=cos(xsig);
  refsin=sin(xsig);
else
  for j=1:nsigs
	refcos(:,j)=cos(xsig+ones(maxpoints,1)*refrot(j));
	refsin(:,j)=sin(xsig+ones(maxpoints,1)*refrot(j));
  end
end

%Display reference signals
if trackDXD
  disp('Starting diagnostic plots in DXDcore:')
  disp('Some displays will pause -- press any key to continue')
  pause
  Ptitle=str2mat('In DXDcore: cosine reference  ','In DXDcore: sine reference');
  time=[0:(maxpoints-1)]'*tstep;
  Sigplot(time,[refcos refsin],Ptitle,Pscale,Gtags);
  if 0
    SigNames=str2mat('cosrefA','cosrefB','cosrefC','sinrefA','sinrefB','sinrefC');
    SigNames=str2mat(SigNames(1:nsigs,:),SigNames(4:3+nsigs,:));
    ringdown([time refcos refsin],SigNames,[],[],'');
    PRSdisp1('DXDcore phasor reference signals:','','',SigNames,[time refcos refsin],tstep);
  end
end

%Form correlation products
coscorW=Wsig.*refcos;
sincorW=Wsig.*refsin;
disp(['Correlation products done: ' sprintf('samplerate= %5.3f', samplerate)])

%Display correlation products
if trackDXD
  time=[0:(maxpoints-1)]'*tstep; samplerate=1/tstep;
  disp('In DXDcore: Displaying correlation products')	
  Ptitle=str2mat('In DXDcore: coscorW','In DXDcore: sincorW');
  Sigplot(time,[coscorW sincorW],Ptitle,Pscale,Gtags);
  ASname=str2mat('Autospectrum of VA cosine correlation product');
  XrangeF=[0 1000; 0 200; 0 10]; YrangeF=[];
  [sigfft,nfft]=ASpecF1(coscorW(:,1),ASname,XrangeF,YrangeF,samplerate,Gtags);
  ASname=str2mat('Autospectrum of VA sine correlation product');
  [sigfft,nfft]=ASpecF1(sincorW(:,1),ASname,XrangeF,YrangeF,samplerate,Gtags);
  %ASname=str2mat('Autospectrum of VA correlation product');
  keybdok=promptyn('In DXDcore: Do you want the keyboard? ','n');
  if keybdok
    disp('In DXDcore: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
    if 0
      SigNames=str2mat('coscorA','coscorB','coscorC','sincorA','sincorB','sincorC');
      SigNames=str2mat(SigNames(1:nsigs,:),SigNames(4:3+nsigs,:));
      ringdown([time coscorW sincorW],SigNames,[],[],'');
      PRSdisp1('DXDcore correlation products:','','',SigNames,[time coscorW sincorW],tstep);
    end
  end
end

%Combine correlation signals
corWsum=[coscorW sincorW];
if nsigs>1
  corWsum=[sum(coscorW')' sum(sincorW')'];
end

%Display rectangular correlation sums
if trackDXD&(nsigs>1)
  disp('In DXDcore: Displaying rectangular correlation sums')
  Ptitle=str2mat('In DXDcore: coscorWsum','In DXDcore: sincorWsum');
  Sigplot(time,[corWsum(:,1) corWsum(:,2)],Ptitle,Pscale,Gtags);
end

if trackDXD
  keybdok=promptyn('in DXDcore: Do you want the keyboard? ', 'n');
  if keybdok
    disp('In DXDcore: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
    if 0
      SigNames=str2mat('coscorA','coscorB','coscorC','sincorA','sincorB','sincorC');
      SigNames=str2mat(SigNames(1:nsigs,:),SigNames(4:3+nsigs,:));
      SigNames=str2mat(SigNames,'coscorWsum','sincorWsum');
      ringdown([time coscorW sincorW corWsum],SigNames,[],[],'');
      PRSdisp1('DXDcore correlations & correlation sums:','','',SigNames,[time coscorW sincorW corWsum],tstep);
      %else use
      SigNames=str2mat('coscorWsum','sincorWsum');
      ringdown([time corWsum],SigNames,[],[],'');
      PRSdisp1('Correlation sums:','','',SigNames,[time corWsum],tstep);
    end
  end
end

disp('Return from PSMT utility DXDcore')
return

%end of PSMT function



