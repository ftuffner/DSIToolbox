%start3v2.m
%Bill's "start.m" program modified for modemeter.
%Note:  very crude code but something fast to have code in Bill's hands

%Part 1 - Initialize modemeter parameters
clear all
close all
p=10; %number of 5 minute dst files to load
Finitial=30;  %Original sampling rate
Fs=5;   %new sampling rate after decimation
t=(0:(p*5*60*Finitial-1))/Finitial;  %time vector for concatenated data
thresh=300;  %magnitude for finding missing data in datacrct.m program
%initialize parameters for modemeter
T=6*60; 	% time in second for each segment
Tu=1*60;	% time in seconds between updates
L=T*Fs;     %data points per segment
P=Tu*Fs;    %data points between updates
N=24;  %initial order (denominator)
K=48;  %length of correlation matrix to use
M=16;   %Numerator order
w=0;  %w is window for correlation est., currently disabled.
Fintertie=0.27;  %approximate intertie mode frequency used in sorting
Falberta=0.4;  %approximate alberta mode frequency used in sorting
autoaxis=1;  %autoscale axis for plots of damping and freq vs. time
             %1 for autoscale, else (0 or any other value) range is fixed

%*******************
%Part 2 - load data (the brute force approach, one five minute segment at a time)
%Initialize vectors to contain the concatenated 5 minute segments
MALRMt=[];  %concatenated Malin
CeliloACt=[]; %concatenated Celilo
%load first data set
load BPAP_0008041925
startaux     %modification of Bill's start program
MALRMt=[MALRMt MALRM];
CeliloACt=[CeliloACt CeliloAC];
%load another data set and concatenate with other sets
load BPAP_0008041930
startaux
MALRMt=[MALRMt MALRM];
CeliloACt=[CeliloACt CeliloAC];
%load another data set and concatenate with others
load BPAP_0008041935
startaux
MALRMt=[MALRMt MALRM];
CeliloACt=[CeliloACt CeliloAC];
%load another data set and concatenate with others
load BPAP_0008041940
startaux
MALRMt=[MALRMt MALRM];
CeliloACt=[CeliloACt CeliloAC];
%load another data set and concatenate with others
load BPAP_0008041945
startaux
MALRMt=[MALRMt MALRM];
CeliloACt=[CeliloACt CeliloAC];
%load another data set and concatenate with others
load BPAP_0008041950
startaux
MALRMt=[MALRMt MALRM];
CeliloACt=[CeliloACt CeliloAC];
%%load another data set and concatenate with others
load BPAP_0008041955
startaux
MALRMt=[MALRMt MALRM];
CeliloACt=[CeliloACt CeliloAC];
%load another data set and concatenate with others
load BPAP_0008042000
startaux
MALRMt=[MALRMt MALRM];
CeliloACt=[CeliloACt CeliloAC];
%load another data set and concatenate with others
load BPAP_0008042005
startaux
MALRMt=[MALRMt MALRM];
CeliloACt=[CeliloACt CeliloAC];
%load another data set and concatenate with others
load BPAP_0008042010
startaux
MALRMt=[MALRMt MALRM];
CeliloACt=[CeliloACt CeliloAC];
%*******************

%*******************
%signal for mode meter to analyze
x=MALRMt-mean(MALRMt);
x=datacrct(x,thresh);
%*******************

%*******************
%Part 3 - data preprocessing
%design the preprocessing
[I,blp,bhp,ahp]=preprocdsn(Finitial,Fs);  
%preprocess the data(i.e. lowpass filter, decimate, highpass filter)
y=preproc(x,I,blp,bhp,ahp);
%%y=preproc(x,D,blp,1,1);  % this will bypass the highpass filter
LL=length(y);  %total data length
D=fix((LL-L)/P)+1;  %number of data blocks
%*******************

%*******************
%Part 4 - mode estimation using all of the concatenated data
%i.e. one estimate of of the modes based on all the data
%estimate correlation function
rhat=RHATFUNC(y(101:length(y)),K+M,w);  %rhat needs to be a column vector
%note, above the first 100 points of y are not used because of transient response of filter
%estimate the modes using overdetermined ARMA based mode meter
[a,spoles,zpoles,cnd]=ARMAovr(rhat,N,K,M,Fs);  %mode meter segment
%sort the modes
[ur,cr,sr,Y]=SORTPOLE(zpoles,rhat,spoles,Fintertie,Falberta);  %sorts the modes by energy, then places the
    %and then places the intertie mode first in the list and the alberta mode second
%display the Intertie mode and the Alberta mode
disp('mode estimation results using all the data in a single estimate')
disp('Intertie mode:  frequency')
disp(imag(sr(1))/(2*pi))
disp('Intertie mode:  damping ratio')
disp(-real(sr(1))/(abs(sr(1))))
disp('Alberta mode:  frequency')
disp(imag(sr(2))/(2*pi))
disp('Alberta mode:  damping ratio')
disp(-real(sr(2))/(abs(sr(2))))
%extra info - display all the estimated modes and their relative energies
disp('All the estimated modes')
disp('   Freq.   Damp Ratio  Relative Ener')
disp([imag(sr)/(2*pi) -real(sr)./abs(sr) Y/max(Y)])
%*******************

%*******************
%plots
%display data before preprocessing (every 6th sample)
figure(1)
subplot(2,1,1)
plot(t(1:6:length(t))/60,x(1:6:length(x)))
title('data with mean removed - before preprocessing,every 6th sample')
xlabel('time (min)')
ylabel('Amplitude (MW)')
%display data after preprocessing
figure(1)
subplot(2,1,2)
plot(t(1:6:length(t))/60,y)
title('data - after preprocessing')
xlabel('time (min)')
ylabel('Amplitude (MW)')
%display periodogram
[Py,F] = psd(y(101:length(y)),1024,5,hamming(256),192);
figure(2)
plot(F,10*log10(Py))
title('Periodogram of Signal')
xlabel('Frequency (Hz)')
ylabel('Autospectra (dB)')
%display poles in s-plane
figure(3)
plot(real(sr),imag(sr)/(2*pi),'x')
title('s-plane')
xlabel('real part of pole')
ylabel('imag part of pole / (2pi)')
axis([-0.5 0 0 1])
%*******************

%*******************
%Part 5 - modemeter
%if you have 15 minutes or more of data, then track mode as a function of time
if p>=3,
  %analyze data with mode meter
  [S1,C1,Rhat1,U1,YY1,Cnd]=block(y,N,K,M,T,Tu,Fs,Fintertie,Falberta);
  disp('In plots of frequency or damping ratio')
  disp('as a function of time, outliers may be')
  disp('caused by the Mode Meter choosing the')
  disp('wrong mode from the estimated list of modes.')
  %plot the results of the mode meter
  pltstrt2
  %%imag(S1(1:6,:)')/(2*pi)
  %%-real(S1(1:6,:)')./abs(S1(1:6,:)')
  %%[imag(S1(1:3,:)')/(2*pi) YY1(1:3,:)'/1e6]
  %%[imag(S1(1:3,:)')/(2*pi) -real(S1(1:3,:)')./abs(S1(1:3,:)')]
end
%**********************

