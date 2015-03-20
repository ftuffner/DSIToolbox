function [num,den]=ezbutter(order,normfreq1,normfreq2,filtype)
%
%  [num,den]=ezbutter(order,normfreq1,normfreq2,filtype)
%
% EZBUTTER is a basic stand-alone function for design 
% of digital Butterworth filters.  It is not intended for
% use in situations with poor numerical conditioning.
%
% Input Variables:
%   ORDER is the filter order.
%   NORMFREQ1,NORMFREQ2 are the normalized frequencies (must be
%     between 0 and 1).  For a lowpass or highpass filter,
%     NORMFREQ1 and NORMFREQ2 should be identical entries.
%   FILTYPE can be 'low','high','pass', or 'stop'
%
% Output Variables:
%   NUM is the polynomial coefficient matrix of the numerator
%   DEN is the polynomial coefficient matrix of the denominator
%
% Author:  Barbara J. Hickman (8/1/97)
%
%***************************************************************

spc=2;  %samples per cycle (Nyquist)
tempfreq=2*spc*tan(pi*[normfreq1,normfreq2]/spc);  %Prewarp and scale frequency
%
%Calculate center/corner frequency and bandwidth:
if strcmp(filtype,'low')|strcmp(filtype,'high')
   bandwidth=[];
   critfreq=tempfreq(1);
end
if strcmp(filtype,'pass')|strcmp(filtype,'stop')
   bandwidth=tempfreq(2)-tempfreq(1);
   critfreq=sqrt(tempfreq(1)*tempfreq(2));
end
%
% Calculate low pass analog parameters, convert to state-space 
buttzeros=[];
buttpoles=exp(i*(pi*(1:2:2*order-1)/(2*order) + pi/2));
buttgain=real(prod(-buttpoles));
[a0,b0,c0,d0]=zp2ss(buttzeros,buttpoles,buttgain);
%
%Transform lowpass analog parameters for desired filter type
if strcmp(filtype,'low')
   a1=critfreq*a0; b1=critfreq*b0;
   c1=c0; d1=d0;
end
if strcmp(filtype,'high')
   a1=critfreq*inv(a0); b1=-critfreq*(a0\b0);
   c1=c0/a0; d1=d0-c0/a0*b0;
end
if strcmp(filtype,'pass')
   temp=critfreq/bandwidth;
   [brow,bcol]=size(b0); [crow,ccol]=size(c0);
   a1=critfreq*[a0/temp eye(brow); -eye(brow) zeros(brow)];
   b1=critfreq*[b0/temp; zeros(brow,bcol)];
   c1=[c0 zeros(crow,ccol)]; d1=d0;
end
if strcmp(filtype,'stop')
   temp=critfreq/bandwidth;
   [brow,bcol]=size(b0); [crow,ccol]=size(c0);
   a1=[critfreq/temp*inv(a0) critfreq*eye(brow);...
         -critfreq*eye(brow) zeros(brow)];
   b1=-[critfreq/temp*(a0\b0); zeros(brow,bcol)];
   c1=[c0/a0 zeros(crow,brow)]; d1=d0-c0/a0*b0;
end
%
%Apply bilinear transform to transform
t=1/spc;
tplus=eye(size(a1))+a1*(t/2);
tminus=eye(size(a1))-a1*(t/2);
a2=tminus\tplus;
b2=t/sqrt(t)*(tminus\b1);
c2=sqrt(t)*c1/tminus;
d2=(c1/tminus)*b1*t/2+d1;
den=poly(a2);
num=poly(a2-b2*c2)+(d2-1)*den;

% End bjh m-file

