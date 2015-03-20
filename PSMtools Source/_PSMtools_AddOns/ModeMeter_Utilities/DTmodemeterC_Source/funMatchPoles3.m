function [MajorPoles,MajorEnergy]=funMatchPoles3(TruePoles,EstPoles,Energy,Dmax,DEmphasis)
% find the estimation error square for estimation poles
% 
% TruePoles:        True poles (column vector).  Assume in upper-half of s-plane
% EstPoles:         Estimated poles (column vector).  Assume in upper-half of s-plane
% Energy:           Energy of each mode (column vector same size as EstPoles)
% Dmax:             Max. damping factor allowed (%).
% DEmphasis:        Scaling factor to emphasize damping.
%
% MajorPoles:       Major poles close to TruePoles; ([] if none)
% MajorEnergy:      Energy for MajorPoles.

if size(TruePoles,2)>1; error('Dimension error on TruePoles.'); end
if size(EstPoles,2)>1; error('Dimension error on EstPoles.'); end
if min(size(Energy)~=size(EstPoles)); error('Energy must be same size as EstPoles.'); end

%Get rid of poles with more than Dmax % damping
x = abs(real(EstPoles))./abs(EstPoles); 
Energy = Energy(x<Dmax/100);
EstPoles = EstPoles(x<Dmax/100);
if max(size(EstPoles)) == 0; 
    MajorPoles = [];
    MajorEnergy = [];
end

for k=1:length(TruePoles)
    x = abs((real(EstPoles) - real(TruePoles(k)))*DEmphasis + j*imag(EstPoles - TruePoles(k))); %Scaled error between poles
    [x,m] = sort(x,1,'ascend'); %Sort according to error
    MajorPoles(k) = EstPoles(m(1));
    MajorEnergy(k) = Energy(m(1));
end
MajorPoles = MajorPoles(:);
MajorEnergy = MajorEnergy(:);