function [y]=db(x);
%Calculate the db gain of x:
%   [y]=db(x);
%Calculation equivalent to
% 	y=20*log10(abs(x));
%but with protection against log of zero
%
% Last modified 01/19/01.   jfh

%	$Id: db.m,v 1.1.1.1 1994/06/02 14:50:56 d3f011 Exp $
MinLevel=1e-40;
loc=find(abs(x)<MinLevel);
x(loc)=MinLevel;
y=20*log10(abs(x));

%end of PSMT function

