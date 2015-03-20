function [sigfft,nfft] = ASpecF1(fftsigs,Snames,Xrange,Yrange,samplerate,Gtags)
%
%	[sigfft,nfft] = ASpecF1(fftsigs,Snames,Xrange,Yrange,samplerate,Gtags)
%
%	Displays voltage & current autospectra for input "fftsigs".
%
%	THIS FUNCTION HAS A LOT OF OPTIONS--READ THE CODE!!
%
% Last modified 03/13/02.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%disp('In ASpecF1:')

%Genesamplerate case/time stamp for plots
Ptitle{1}=' ';
Ptitle{2}=['caseID=' Gtags(1,:) '    casetime=' Gtags(2,:)];

npoints=size(fftsigs,1);
nfft=2^fix(log2(npoints));
tstep=1/samplerate;
tbar=tstep*nfft;
frqstep=1/tbar;
fftfrq=[0:nfft/2-1]'*frqstep;
start=max(1,npoints-nfft+1);	%Allowance for filter startup
sigfft=fft(fftsigs(start:npoints,:),nfft)/nfft;
sigfft=sigfft(1:nfft,:);
Nnames=size(Snames,1);
Nplots=size(Xrange,1);
for j=1:Nnames
  for n=1:Nplots
	  h=figure;
	  plotno=sprintf('P%2.0i: ',h);
    n1=1; n2=nfft/2;
    if ~isempty(Xrange)
      n1=fix(Xrange(n,1)/frqstep+1); n2=min(fix(Xrange(n,2)/frqstep),nfft/2);
	  end
    plot(fftfrq(n1:n2),[db(sigfft(n1:n2,j))])
	  Ptitle{1}=[plotno ' ' Snames(j,:)];
    title(Ptitle)
    if ~isempty(Xrange), set(gca,'xlim',Xrange(n,:)); end
	  if ~isempty(Yrange), set(gca,'Ylim',Yrange); end
	  xlabel('Frequency in Hertz');
	  Ylabel('Autospectrum in dB');
	  set(gca,'TickDir','out')
  end
end

%end PSMT utility

