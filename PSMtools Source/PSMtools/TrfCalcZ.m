function [Trf,frq] = TrfCalcZ(BB,AA,nfrq,samprate)
%
%  function [Trf,frq] = TrfCalcZ(BB,AA,nfrq,samprate)
%
%  Evaluates digital transfer function BB/AA,
%   under standard Matlab notation for filters.
%
%  nfrq = number of eqi-spaced samples for evaluation on unit circle
%  samprate = sample rate (per second)
%  Trf = complex values of transfer function BB/AA
%  frq = frequency points (in Hertz) for Trf evaluation
%
% last modified 07/30/97.  jfh

Nyquist=0.5*samprate; imag=sqrt(-1);
frq=(0:nfrq-1)'*Nyquist/nfrq;
fac=imag*pi/Nyquist;
Trf=polyval(BB,exp(frq*fac))./polyval(AA,exp(frq*fac));

%end of jfh m-file

