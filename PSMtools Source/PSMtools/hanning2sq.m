function w = hanning2sq(n)
%HANNING2SQ	Returns the N-point squared Hanning 
%     	window in a column vector.
%
%	w = hanning2sq(n)

%	$Id: hanning2sq.m,v 1.1.1.1 1994/06/02 14:53:27 d3f011 Exp $
w = .5*(1 - cos(2*pi*(0:n-1)'/n));
w = w.^2;

%end of PSM script

