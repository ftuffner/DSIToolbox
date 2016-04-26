function [mag,phs]=tranfrq0(dampf,frqrps,resr,resi,thru,frq,dftr,dfti)
%$Id$
%
%TRANFRQ0.C:  Calculates the frequency response of a system that is expressed
%             in parallel form.  Returns magnitudes in dB and unwrapped phase
%             angles in degrees.
%
%This function is to be compiled as a MATLAB 5.2 MEX file.
%
%MATLAB Call:
%
%  [mag,phs]=tranfrq0(dampf,frqrps,resr,resi,thru,frq,dftr,dfti);
%
%By Jeff M. Johnson, Pacific Northwest National Laboratory.
%Date : January 1997
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
%  dampf    : Vector of mode damping factors.
%
%  frqrps   : Vector of mode frequencies in rad/sec.
%
%  resr     : Vector of real parts of mode residues.
%
%  resi     : Vector of imaginary parts of mode residues.
%
%  thru     : Feed-Forward term.
%
%  frq      : Vector of sample frequencies in Hz.
%
%  mag      : Magnitude of response in dB.
%
%  phs      : Unwrapped phase of response in degrees.
%
%The following input arguments are optional.  If they are included,
%the first n columns of mag and phs will be the magnitude and phase
%of this data, where n is the column dimension of each argument.
%Both arguments must be present in the function call if either one
%is used.
%
%  dftr     : Real part of additional frequency response data.
%
%  dfti     : Imaginary part of additional frequency response data.
%
%*************************************************************************
%

if ((nargin ~= 6) && (nargin ~= 8))
    error('Wrong number of input arguments');
end

if (nargout ~= 2)
    error('Wrong number of output arguments');
end

%Check first input
[m,n]=size(dampf);
if ((m > 1) && (n > 1))
    error('Incorrect dimensions on first input');
end
if (m>=n)
    qcon = m;
else
    qcon = n;
end

%Check second input
[m,n]=size(frqrps);
if (((m > 1) && (n > 1)) || ((m ~= qcon) && (n~=qcon)))
    error('Incorrect dimensions on the second input');
end

%Check the third input
[m,n]=size(resr);
if (((m > 1) && (n > 1)) || ((m ~= qcon) && (n~=qcon)))
    error('Incorrect dimensions on the third input');
end

%Check the fourth input
[m,n]=size(resi);
if (((m > 1) && (n > 1)) || ((m ~= qcon) && (n~=qcon)))
    error('Incorrect dimensions on the fourth input');
end

%Check the fifth input
[m,n]=size(thru);
if ((m > 1) && (n > 1))
    error('Incorrect dimensions on the fifth input');
end
if (m > 1)
    thru = frq(1);
else
    thru = 0;
end

if ((qcon~=0) || (m~=0))
    nncalc = 1;
else
    nncalc = 0;
end

%Check the 6th input
[m,n]=size(frq);
if ((m > 1) && (n > 1))
    error('Incorrect dimensions on the sixth input');
end
if (m >= n)
    nnfrq = m;
else
    nnfrq = n;
end

%CHeck other inputs
if (nargin==8)
    
    %Check 7th input
    [m,nnsigs]=size(dftr);
    if (m  ~= nnfrq)
        error('Incorrect dimensions on the seventh input');
    end
    
    %Check 8th input
    [m,n]=size(dfti);
    if ((m ~= nnfrq) && (n ~= nnsigs))
        error('Incorrect dimensions on the eighth input');
    end
else
    nnsigs = 0;
end

n = nncalc + nnsigs;
m = nnsigs*nnfrq;

%Preallocate outputs
mag = zeros(nnfrq,n);
phs = zeros(nnfrq,n);

%Put in magnitude and phase of "extra" components
for k=0:(m-1)
    xr = dftr(k+1);
    xi = dfti(k+1);
    mag(k+1) = xr*xr + xi*xi;
    if (mag(k+1) == 0)
        phs(k+1) = NaN;
    else
        phs(k+1) = atan2(xi,xr)/pi*180;
    end
end

%Calculate frequency response of model
if (nncalc)
    
    %Next set
    for k=m:(m+nnfrq-1)
        mag(k+1) = thru;
        phs(k+1) = 0.0;
    end
    
    %Large loop - check for empty
    if (~isempty(frqrps))
        for ival = 0:(qcon-1)
            if (abs(frqrps(ival+1)) < 1e-8)
                xr = resr(ival+1)/pi;
                yr = -dampf(ival+1)/(2*pi);
                y1 = yr*yr;
                zr = -xr*yr;

                for kval=0:(nnfrq-1)
                    fr = frq(kval+1);
                    zi = -xr*fr;
                    zdn = y1 + fr*fr;

                    if (zdn == 0.0)
                        mag(m+k+1) = mag(m+kval+1) + zr*1e35;
                        phs(m+k+1) = phs(m+kval+1) + zi*1e35;
                    else
                        mag(m+kval+1) = mag(m+kval+1) + zr/zdn;
                        phs(m+kval+1) = phs(m+kval+1) + zi/zdn;
                    end
                end
            else
                xr = (dampf(ival+1)*resr(ival+1) - frqrps(ival+1)*resi(ival+1))/(2*pi*pi);
                x1 = resr(ival+1)/pi;
                y1 = (dampf(ival+1)*dampf(ival+1) + frqrps(ival+1)*frqrps(ival+1))/(4*pi*pi);
                y2 = -dampf(ival+1)/pi;

                for kval=0:(nnfrq-1)
                    fr = frq(kval+1);
                    xi = x1*fr;
                    yr = y1 - fr*fr;
                    yi = y2*fr;
                    zr = xr*yr - xi*yi;
                    zi = yr*xi + xr*yi;
                    zdn = yr*yr + yi*yi;

                    if (zdn == 0.0)
                        mag(m+kval+1) = mag(m+kval+1) + zr*1e35;
                        phs(m+kval+1) = phs(m+kval+1) + zi*1e35;
                    else
                        mag(m+kval+1) = mag(m+kval+1) + zr/zdn;
                        phs(m+kval+1) = phs(m+kval+1) + zi/zdn;
                    end
                end
            end
        end
    end
        
    for kval=m:(m+nnfrq-1)
        xr = mag(kval+1);
        xi = phs(kval+1);
        mag(kval+1) = xr*xr + xi*xi;
        if (mag(kval+1) == 0.0)
            phs(kval+1) = NaN;
        else
            phs(kval+1) = atan2(xi,xr)/pi*180;
        end
    end
end

%Unwrap phase angles and convert to dB
for ivals=0:(n-1)
    %Offset index to get around C code
    ivaloffset = ivals*nnfrq;
    
    y1 = 0.0;
    for kvals=ivaloffset:(ivaloffset+nnfrq-1)
        if (mag(kvals+1) > 0.0)
            x1 = phs(kvals+1);
            break;
        end
    end
    
    for kvals=ivaloffset:(ivaloffset+nnfrq-1)
        if (mag(kvals+1) > 0.0)
            mag(kvals+1) = 10.0*log10(mag(kvals+1));
            y2 = phs(kvals+1) - x1;
            if (abs(y2) > 180.0)
                if (y2 < 0)
                    y1 = y1 + 360.0;
                else
                    y1 = y1 - 360.0;
                end
            end
            x1 = phs(kvals+1);
            phs(kvals+1) = phs(kvals+1) + y1;
        else
            mag(kvals+1) = inf;
        end
    end
end
        
                