function w = hanning2(n)
%HANNING2 	Returns the N-point Hanning window in a column vector.
% 	It differs from HANNING(N) in that the definition in "Modern Spectrum
%      	Analysis II" is used...i.e., the correct one.
%
%	w = hanning2(n)

%	$Id: hanning2.m,v 1.1.1.1 1994/06/02 14:53:10 d3f011 Exp $
w = .5*(1 - cos(2*pi*(0:n-1)'/n));

%end of PSM script

