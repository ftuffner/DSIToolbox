function [sPoles,Energy,rAuto,rAutohat] = funModeMeterAmbient(y,Ts,n,m,MAR,MRes,DampMax,Frange,EnergyMin,Method,Nfft);
% [sPoles,Energy] = funModeMeterAmbient(y,Ts,n,m,MAR,MRes,DampMax,Frange,EnergyMin,Method,Nfft)
% Estimates the modes in a set of ambient signals.  The system model
% is a MIMO ARMA model driven by white noise.
% 
% INPUT:
%   y = matrix of measured outputs.  kth column is kth output.
%   Ts = sample period (seconds)
%   n = AR order.
%   m = max. MA order.
%   MAR = number of data points to be included from the autocorrlation when
%      solving for the AR coef. (only used if Method = 1 or 2).
%   MRes = number of data points to be included from the autocorrlation when
%      solving for the Energy terms.
%   DampMax = Modes with a damping raio greater than DampMax are not 
%       returned. 
%   Frange = 2x1 vector.  First element is the min. frequency of the modes
%       of interest; second element is the max. freqquency of the modes of 
%       interest in Hz.  That is, modes with a frequency in the Frange are
%       estimated.
%   EnergyMin = Modes with a relative energy less than EnergyMin are not
%       returned.
%   Method = if = 1, use Modified Extended Yule Walker method;
%            if = 2, use Modified Extended Yule Walker with spectral
%            analysis to estimate the autocorrelation function;
%            if = 3, use the N4SID algorithm.
%   Nfft = size of fft window for estimating PSD if Method = 2.  If Method
%       equal to 2, not used.
%
% OUTPUT:
%   sPoles = Vector of estimated modes (poles).  Only the upper s-plane  bound
%       by Frange and DampMax is included.
%   Energy = Vector of relative pseudo energy of each mode in sPoles.  Note that
%       Energy is normalized to unity (i.e., max(Energy) = 1).  Also, 
%       {sPoles, Energy} are sorted according to Energy with the highest
%       Energy term first.
%   rAuto = Matrix of auto-correlation functions.  The kth column is the 
%       estimated autocorrelation vector for the kth y.
%   rAutohat = Matrix of auto-correlation functions estimated by the ARMA 
%       model.

% copyright 2006, Contributors:  Montana Tech, University of Wyoming, Pacific Northest
% National Laboratory.

[Nd,Nout] = size(y);
Method = round(Method);
if Method<1 | Method>3; error('Method must be 1, 2, or 3.'); end

%Estimate mode and energy matrix
if Method == 1;
    [zPoles,EnergyMatrix,rAuto,rAutohat] = funMEYWambient(y,n,m,MAR,MRes); %Modified EYW
elseif Method==2;
    [zPoles,EnergyMatrix,rAuto,rAutohat] = funMEYWSpectralAmbient(y,n,m,MAR,MRes,Nfft); %Modified EYW with spectral analysis
else
    [zPoles,EnergyMatrix,rAuto,rAutohat] = funN4SIDambient(y,n,m,MRes); %N4SID algorithm
end

%Subset select modes and calculate relative energy
if size(EnergyMatrix,2)>1;
    Energy = sum(EnergyMatrix')'; %Add total relative energy for each mode
else
    Energy = EnergyMatrix';
end
sPoles = (1/Ts)*log(zPoles);    %Convert the discrete poles into continuous poles
Energy = Energy(imag(sPoles)>0); 
sPoles = sPoles(imag(sPoles)>0); %Keep upper s-plane
Energy = Energy(imag(sPoles)>2*pi*Frange(1));
sPoles = sPoles(imag(sPoles)>2*pi*Frange(1)); %Get rid of low frequency terms
Energy = Energy(imag(sPoles)<2*pi*Frange(2));
sPoles = sPoles(imag(sPoles)<2*pi*Frange(2)); %Get rid of high frequency terms
Energy = Energy(-real(sPoles)./abs(sPoles) < DampMax);
sPoles = sPoles(-real(sPoles)./abs(sPoles) < DampMax);
Energy = Energy./max(Energy); %Normalize
sPoles = sPoles(Energy>EnergyMin);
Energy = Energy(Energy>EnergyMin); %Get rid of low energy terms

%Sort sPoles and Energy in decsending order
[x,k] = sort(Energy,'descend');
Energy = Energy(k);
sPoles = sPoles(k);