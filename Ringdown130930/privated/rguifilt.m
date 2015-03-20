function [yf,bsinc]=rguifilt(y,tstep,fc)
%$Id: rguifilt.c,v 1.1 1997/12/27 00:36:57 d3h902 Exp $
%
%RGUIFILT:  Data filter function for BPA/PNNL Ringdown Analysis Tool.
%
%This function is to be compiled as a MATLAB 5.1 MEX file.
%
%MATLAB Call:
%
%  [yf,bsinc]=rguifilt(y,tstep,fc);
%
%By Jeff M. Johnson, Pacific Northwest National Laboratory.
%Date : July 1996
%
%Adapted from a MATLAB m-file written by John F. Hauer.
%
%Adapted back to MATLAB from C by Frank Tuffner
%
%Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
%retains a paid-up nonexclusive, irrevocable worldwide license to
%reproduce, prepare derivative works, perform publicly and display
%publicly by or for the Government, including the right to distribute
%to other Government contractors.
%
%*************************************************************************
%
%User provided variables
%These are the variables listed in the MATLAB function call above.  They
%are not passed directly to this function.
%
%  y     : Matrix containing data to be filtered.  Each column contains
%          a different signal.
%
%  tstep : Sample period for y.
%
%  fc    : Filter cutoff frequency (Hz).
%
%  yf    : Matrix containing filtered data.  Dimensions are same as
%          those of y.
%
%  bsinc : FIR filter coefficients.
%
%*************************************************************************
%
if (nargin ~=3)
    error('Wrong number of input arguments');
end

%Determine outputs
incfilt = (nargout == 2);

%Check outputs
if ((nargout ~= 1) && (incfilt == false))
    error('Wrong number of output arguments');
end

%Check composition
if (any(~isreal(y)))
    error('All inputs must be purely real.');
end

%Get size
[nnsamp,nnsigs]=size(y);

%Check
if (nnsamp*nnsigs == 0)
    nnsamp = 0;
    nnsigs = 0;
end

%Make sure we can filter
if (nnsamp == 0)
    return; %Empty, why filter?
end

%Check second input
[m,n]=size(tstep);
if ((m ~= 1) || (n ~= 1))
    error('Incorrect dimensions on second input');
end
if ((tstep <= 0.0) || (tstep > 1))
    error('Sample period must be > 0 and <= 1');
end

%Check third input
[m,n]=size(fc);
if ((m ~= 1) || (n ~= 1))
    error('Incorrect dimensions on third input');
end
if (fc <= 0)
    error('Cutoff frequency must be > 0.');
end

%Calculate filter length
simrate = 1.0/tstep;
nyquist_r = simrate/2.0;
sincfac = 0.5;
pncornr = pi*fc/nyquist_r;
sincpts = 2*floor(nyquist_r/sincfac);
lfilt = 2*sincpts+1;
sincpt2 = 2.0*sincpts;

%Preallocate output
yf = zeros(nnsamp,nnsigs);
bsinc = zeros(lfilt,1);

%Filter point
bsinc(sincpts+1) = 1.0;

%Create the filter
lvar = 1;
jvar = sincpts-1;
for ivar=(sincpts+1):(lfilt-1)
    %Simple sinc-shaped (rectangular frequency)
    x1 = pncornr*lvar;
    sincwt = sin(x1)/x1;
    hammwt = 0.54-0.46*cos(2.0*pi*ivar/sincpt2);
    bsinc(ivar+1)=sincwt*hammwt;
    bsinc(jvar+1)=bsinc(ivar+1);
    
    %Update indices
    lvar = lvar + 1;
    jvar = jvar - 1;
end

%Normalize it
x1 = 0.0;
for ivar=0:(lfilt-1)
    x1 = x1 + bsinc(ivar+1);
end
bsinc = bsinc/x1;

%Figure out working array size
lval = nnsamp + 2*sincpts;

%Allocate it
yaug = zeros(lval,nnsigs);

%Put the values in
yaug((sincpts+1):(sincpts+nnsamp),:)=y;

%Filter the columns
for sigcon=1:nnsigs
    mvar = lval-sincpts-1;
    jvar = sincpts + 1;
    x1 = 2.0*yaug((sincpts+1),sigcon);
    
    %Reflect sincpts data points around the beginning of signal
    for ivar=(sincpts-1):-1:0
        yaug((ivar+1),sigcon)=x1-yaug((jvar+1),sigcon);
        jvar = jvar + 1;
        if (jvar > mvar)
            jvar = ivar + 1;
            x1 = 2.0 * yaug((ivar+1),sigcon);
        end
    end
    
    %Reflect sincpots data points around end of signal
    x1 = 2.0*yaug((mvar+1),sigcon);
    jvar = mvar - 1;
    for ivar = (lval-sincpts):(lval-1)
        yaug((ivar+1),sigcon) = x1 - yaug((jvar+1),sigcon);
        jvar = jvar - 1;
    end
    
    %Filter
    jvar=(lfilt-1);
    for ivar=0:(nnsamp-1)
        for mvar=0:(lfilt-1)
            yf((ivar+1),sigcon) = yf((ivar+1),sigcon) + bsinc(mvar+1)*yaug((jvar-mvar+1),sigcon);
        end
        jvar = jvar + 1;
    end
end