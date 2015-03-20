function [D,blp,bhp,ahp]=preprocdsn(Finitial,Fs)
%******************************
%preprocessing design:  i.e. lowpass filter and decimate,
%usage [D,blp,bhp,ahp]=preprocdsn(Finitial,Fs)
%designed and tested for Finitial=30 and Fs=5;
%input
%   Finitial=initial sampling rate
%   Fs=new sampling rate after decimation
%  Note: the ratio of Finitial to Fs should be an integer
%outputs
%   D=decimation factor
%   blp=coef. for low-pass FIR filter
%   bhp=numerator coef. for high pass filter
%   ahp=denominator coef. for high pass filter
%note: 
%   length of lowpass filter is 91 samples
%   Low pass cutt-off frequency is 2 Hz
%   Low pass stop frequency is 3 Hz
%   high pass filter is first order with a zero at z=0
%      and a pole at z=0.95
%********************************
%First, lowpass filter for decimation
Finitial=30;  	%initial sampling rate
Fs=5;				%decimated sampling rate
D=Finitial/Fs;	%decimation factor
F=[0 2 3 Finitial/2];	%specs for filter frequencies
f=F/Finitial;  %normalized digital frequency filter specs
m=90;  %order of lowpass FIR filter, approx. 3 seconds of data
blp=remez(m,2*f,[1 1 0 0]); %lowpass digital antialias filter used before dec.
%[Hlp,w]=freqz(blp,1,512);  
%%figure(1)
%%plot(w*Finitial/(2*pi),20*log10(abs(Hlp)))
%second, highpass filter to remove very low frequency trends, high freq. gain=1
%to be applied after lowpass filtering and decimating
bhp=(1.95/2)*[1 -1];  %numerator with z-plane zero at z=1
ahp=[1 -0.95]; %denominator with z-plane pole at z=0.95
%[Hhp,w]=freqz(bhp,ahp,512);
%%figure(2)
%plot(w*Fs/(2*pi),20*log10(abs(Hhp)));
%%plot(w*Fs/(2*pi),abs(Hhp));
