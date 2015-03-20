function [Poles,Energy,rAuto,rAutohat] = funMEYWambient(y,n,m,MAR,MRes);
% [Poles,Energy,rAuto,rAutohat] = funMEYWambient(y,n,m,MAR,MRes)
% Estimates the poles and the relative energy of each pole of an MIMO
% ARMA system where the ith output is defined by
%
%   A(z)y-sub-i = sum[B-sub-ij(z)e-sub-j]
%                  j
% where e-sub-j is unobserved white noise and y-sub-i is the ith signal.
% The Poles are estimated using the modified Extend Yule Walker equations
% where the autocorrelation is directly estimated from the time samples.
%
% The relative energy of each pole is estimated by solving the Vandermonde
% problem applied to the autocorrelation function of each output.
% The relative energy is calculated from the residue and pole.
%
% The relative energy of each pole is estimated by solving the Vandermonde
% problem applied to the autocorrelation function of each output.
% The relative energy is calculated from the residue and pole.
%
% INPUT:
%   y = matrix of measured outputs.  ith column is ith output.
%   n = AR order.
%   m = max MA order (each B-sub-ij(z) is assumed to have order m or less).
%   MAR = number of data points to be included from the autocorrlation when
%      solving for the AR coef.
%   MRes = number of data points to be included from the autocorrlation when
%      solving for the Energy terms.
%
% OUTPUT:
%   Poles = Vector of discrete-time poles.  I.e., the roots of
%       the characteristic equation is given by
%       1 + a(1)z^(-1) + ... + a(n)z^(-n)
%   Energy = Matrix of relative energy.  Energy(i,k) estimates the 
%       energy in the ith signal due to the Poles(k).  Each column of Energy
%       is normalized so the max term is unity.
%   rAuto = Matrix of auto-correlation functions.  The kth column is the 
%       estimated autocorrelation vector for the kth y.
%   rAutohat = Matrix of auto-correlation functions estimated by the ARMA 
%       model.

% copyright 2006, Contributors:  Montana Tech, University of Wyoming, Pacific Northest
% National Laboratory.

[Nd,Nout] = size(y);
if Nd<=MAR+m; error('Not enough data'); end
if (MRes-1)<n; error('MRes too small.'); end

%Build autocorrelation matrix
RMatrix = [];
rVector = [];
rAuto = [];
for k = 1:Nout
    %Autocorrelation estimate for y(:,k) using a biased estimate
    c = [];
    for kk = 1:m+MAR+1
        c(kk) = (1/Nd)*sum(y(kk:Nd,k).*y(1:Nd-kk+1,k));
    end
    c = [c(m+MAR+1:-1:1) c(2:m+MAR+1)]';
    x = [];
    for kk=1:n
        index = 2*m+MAR+1-kk+1;
        x = [x c(index:index+MAR-1)]; %Build auto matrix for kth output
    end
    RMatrix = [RMatrix;x]; %Cancatenate matrices
    rVector = [rVector;-c(2*m+MAR+2:2*m+2*MAR+1)]; %Cancatenate vectors
    rAuto(:,k)=c(2*m+MAR+2:2*m+2*MAR+1);
end

%Solve for AR coef. and poles
acoef = RMatrix\rVector; % Solve for AR coef.
Poles = roots([1; acoef]); % Z-domain poles
clear c x index kk RMatrix acoef rVector

%Solve for Residues
Np = size(rAuto,1);
if MRes>Np; error('MRes too large.'); end
Np = MRes;
ZMatrix = zeros(Np,n);
for k=1:Np
    ZMatrix(k,:) = (Poles.').^(k-1);
end
B = [];
for k=1:Nout
    B(:,k) = ZMatrix\rAuto(1:Np,k);
end

%Solve for relative pseudo mode energy
PoleEnergy = zeros(n,1);
for kk=1:n
    for k=1:Np
        PoleEnergy(kk) = PoleEnergy(kk) + (Poles(kk)^k) * (conj(Poles(kk))^k);
    end
end
Energy = [];
for k=1:Nout
    Energy(:,k) = (B(:,k).*conj(B(:,k))) .* PoleEnergy;
    Energy(:,k) = Energy(:,k)./max(Energy(:,k));
end
clear PoleEnergy

%Simulate;
rAutohat = zeros(size(rAuto));
for k=1:Nout
    for kk=1:Np;
        for kkk=1:n;
            rAutohat(kk,k) = rAutohat(kk,k) + B(kkk,k)*(Poles(kkk)^(kk-1));
        end
    end;
end;
rAutohat = real(rAutohat);
