function [Trf,frq] = TrfCalcS(BB,AA,arg3,arg4)
%
%  Evaluates s-domain transfer function BB/AA,
%   under standard Matlab notation for filters.
%
%  All frequency parameters are in Hertz.
%
% FORM A:
%  function [Trf,frq] = TrfCalcS(BB,AA,nfrq,frqstep)
%
% FORM B:
%  function [Trf,frq] = TrfCalcS(BB,AA,frq)
%
% INPUTS (form A):
%     nfrq = number of eqi-spaced frequency samples for Trf evaluation
%     frqstep = spacing for frequency samples
%
% INPUTS (form B):
%     frq = frequency samples for Trf evaluation
%
% OUTPUTS:
%      Trf = complex values of transfer function BB/AA
%      frq = frequency points (in Hertz) for Trf evaluation
%
% Last modified 05/20/98.  jfh

if max(size(arg3)) == 1
  nfrq=arg3; frqstep=arg4;
  frq=(0:nfrq-1)'*frqstep;
else
  frq=arg3;
end

imag=sqrt(-1);
fac=imag*2*pi;
Trf=polyval(BB,frq*fac)./polyval(AA,frq*fac);

%end of jfh m-file

