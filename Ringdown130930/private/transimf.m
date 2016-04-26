function [yhat,thru]=transimf(dampf,frqrps,resr,resi,inpulses,tstep,nncalc,y,incthru)
% $Id: transimf.c,v 1.1 1997/12/27 00:46:28 d3h902 Exp $
%
% TRANSIMF.C:  Simulates the time-domain response of a system that is expressed
%              in parallel form.  A feed-forward term is then calculated from
%              measurement data and it's response is (optionally) added to the
%              calculated response.
%
% This function is to be compiled as a MATLAB 5.1 MEX file.
%
% MATLAB Call:
%
%   [yhat,thru]=transimf(dampf,frqrps,resr,resi,inpulses,tstep,nncalc,y,incthru);
%
% By Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date : August 1996
%
% Adapted back to MATLAB from C by Frank Tuffner
%
% Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
%**************************************************************************
%
% User provided variables
% These are the variables listed in the MATLAB function call above.  They
% are not passed directly to this function.
%
%   dampf    : Vector of mode damping factors.
%
%   frqrps   : Vector of mode frequencies in rad/sec.
%
%   resr     : Vector of real parts of mode residues.
%
%   resi     : Vector of imaginary parts of mode residues.
%
%   inpulses : Input pulse data.
%              If inpulses is empty, system input is a delta function.
%              If inpulses is not empty, it must contain two columns.
%              First column is switch times.  Second is pulse amplitudes.
%
%   tstep    : Sample period.
%
%   nncalc   : Number of time-domain samples to calculate.
%
%   y        : Vector with system response data for calculating
%              feed-forward term
%
%   incthru  : Include feed-forward term in simulated model response?
%              0 ==> No
%              1 ==> Yes
%
%   yhat     : Vector with simulated model response data.
%
%   thru     : Calculated feed-forward term.
%              Thru is set to zero is inpulses is empty.
%
%**************************************************************************

%Check i/o
if (nargin~=9)
    error('Wrong number of input arguments.');
end

if (nargout~=2)
    error('Wrong number of output arguments.');
end

%Check composition
if (any(~isreal(dampf) | ~isreal(frqrps) | ~isreal(resr) | ~isreal(resi) | ~isreal(inpulses) | ~isreal(tstep) | ~isreal(nncalc) | ~isreal(y) | ~isreal(incthru)))
    error('All inputs must be purely real.');
end

%Check dimensions of inputs
%First input
[m,n]=size(dampf);
if ((m==0) || (n==0))
    m = 0;
    n = 0;
end
if ((m>1) && (n>1))
    error('Incorrect dimensions on first input');
end
if (m>=n)
    qcon = m;
else
    qcon = n;
end

%Second input
[m,n]=size(frqrps);
if ((m==0) || (n==0))
    m = 0;
    n = 0;
end
if ((m>1) && (n>1) || ((m ~= qcon) && (n ~= qcon)))
    error('Incorrect dimensions on second input');
end

%Third input
[m,n]=size(resr);
if ((m==0) || (n==0))
    m = 0;
    n = 0;
end
if ((m>1) && (n>1) || ((m ~= qcon) && (n ~= qcon)))
    error('Incorrect dimensions on third input');
end

%Fourth input
[m,n]=size(resi);
if ((m==0) || (n==0))
    m = 0;
    n = 0;
end
if ((m>1) && (n>1) || ((m ~= qcon) && (n ~= qcon)))
    error('Incorrect dimensions on fourth input');
end

%Fifth input
[ninputs,n]=size(inpulses);
if ((ninputs ~= 0) && (n~=2))
    error('Incorrect dimensions on fifth input');
end
delay=inpulses;
if (n~=2)
    inamp=[];
else
	inamp=inpulses(:,2);
end

%Sixth input
[m,n]=size(tstep);
if ((m~=1) || (n~=1))
    error('Incorrect dimensions on the sixth input');
end

%Seventh input
[m,n]=size(nncalc);
if ((m==0) || (n==0))
    m = 0;
    n = 0;
end
if ((m>1) || (n>1))
    error('Incorrect dimensions on the seventh input');
end
if (m ==0)
    nncalc = -1;
end

%Eighth input
[m,n]=size(y);
if ((m==0) || (n==0))
    m = 0;
    n = 0;
end
if ((m~=1) && (n~=1))
    error('Incorrect dimensions on eighth input');
end
if (m >= n)
    nnthru = m;
else
    nnthru = n;
end

%Ninth input
[m,n]=size(incthru);
if ((m~=1) || (n~=1))
    error('Incorrect dimensions on ninth input');
end

%other check
if (nncalc < 0)
    nncalc = nnthru;
end
if (nnthru > nncalc)
    n = nnthru;
else
    n = nncalc;
end

%If inputs pulses are present, make sure the final input pulse is nonzero
while (ninputs>0)
    if (abs(inamp(ninputs)) < 1.0e-8)
        ninputs = ninputs - 1;
    else
        break;
    end
end

%Determine if the input is a step
ival = 0;
while ((ninputs>0) && (delay(ninputs) > nnthru*tstep))
    ninputs = ninputs - 1;
    ival = 1;
end
ninputs = ninputs + ival;

%Create output matrices
if (n > nncalc)
    yhat = zeros(n,1);
else
    yhat = zeros(nncalc,1);
end
thru = 0.0;

%Small fraction of a step to subtract from switch times for >= comparison
ftstep = tstep/1000.0;

%Calculate system output without feed-foward term
if (ninputs==0)
    for ival=0:(qcon-1)
        t = 0.0;
        if (abs(frqrps(ival+1)) < 1e-8)
            for kval=0:(n-1)
                yhat(kval+1) = yhat(kval+1) + 2*resr(ival+1)*exp(-dampf(ival+1)*t);
                t = t + tstep;
            end
        else
            for kval=0:(n-1)
                [vr,vi]=cexpz_m(-dampf(ival+1)*t,frqrps(ival+1)*t);
                yhat(kval+1) = yhat(kval+1) + 2*(resr(ival+1)*vr-resi(ival+1)*vi);
                t = t + tstep;
            end
        end
    end
else
    %Find the term at zero in the z-plane
    m = -1;
    x = 1e12;
    for ival=0:(qcon-1)
        if ((abs(frqrps(ival+1) < 1e-8)) && (abs(dampf(ival+1)) < x))
            x = abs(dampf(ival+1));
            m = ival;
        end
    end
    if (x < 1e-8)
        ires0 = m;
        res0 = 2.0*resr(ires0+1);
    else
        ires0 = -1;
        res0 = 0.0;
    end
    
    %Response of term at zero
    if (ires0 >= 0)
        t = 0.0;
        jval = 0;
        qvlk = res0*inamp(jval+1);
        term2 = 0.0;
        for kval=0:(n-1)
            if (jval < ninputs)
                if (t >= delay(jval+1)-ftstep)
                    if (jval < (ninputs-1))
                        qvlk = res0*inamp(jval+1);
                        term2 = term2 + res0*delay(jval+1)*(inamp(jval+2)-inamp(jval+1));
                    else
                        qvlk = 0.0;
                        term2 = term2 - res0*delay(jval+1)*inamp(jval+1);
                    end
                    jval = jval + 1;
                end
                yhat(kval+1) = yhat(kval+1) + qvlk*t;
            end
            yhat(kval+1) = yhat(kval+1) - term2;
            t = t + tstep;
        end
    end
    
    %Response of remaining modes
    for ival=0:(qcon-1)
        if (ival == res0)
            continue;
        end
        t = 0.0;
        jval = 0;
        
        if (abs(frqrps(ival+1))<1e-8)
            qr = -2.0*resr(ival+1)/dampf(ival+1);
            qvlk = qr * inamp(jval+1);
            qvikr = qvlk;
            for kval=0:(n-1)
                if (jval < ninputs)
                    if (t >= (delay(jval+1)-ftstep))
                        vr = exp(dampf(ival+1)*delay(jval+1));
                        if (jval < (ninputs-1))
                            qvlk = qr*inamp(jval+2);
                            qvikr = qvikr + qr*vr*(inamp(jval+2)-inamp(jval+1));
                        else
                            qvlk = 0.0;
                            qvikr = qvikr - qr*vr*inamp(jval+1);
                        end
                        jval = jval+1;
                    end
                end
                yhat(kval+1) = yhat(kval+1) + qvikr*exp(-dampf(ival+1)*t)-qvlk;
                t = t + tstep;
            end
        else
            [qr,qi]=cdivz_m(resr(ival+1),resi(ival+1),-dampf(ival+1),frqrps(ival+1));
            qr = qr * 2.0;
            qi = qi * 2.0;
            qvlk = qr * inamp(jval+1);
            qvikr = qvlk;
            qviki = qi * inamp(jval+1);
            for kval=0:(n-1)
                if (jval < ninputs)
                    if (t >= (delay(jval+1)-ftstep))
                        [vr,vi] = cexpz_m((dampf(ival+1)*delay(jval+1)),(-frqrps(ival+1)*delay(jval+1)));
                        if (jval < (ninputs-1))
                            qvlk = qr*inamp(jval+2);
                            qvikr = qvikr + (qr*vr-qi*vi)*(inamp(jval+2)-inamp(jval+1));
                            qviki = qviki + (qr*vi+qi*vr)*(inamp(jval+2)-inamp(jval+1));
                        else
                            qvlk = 0.0;
                            qvikr = qvikr - (qr*vr-qi*vi)*inamp(jval+1);
                            qviki = qviki - (qr*vi+qi*vr)*inamp(jval+1);
                        end
                        jval = jval+1;
                    end
                end
                [vr,vi] = cexpz_m((-dampf(ival+1)*t),(frqrps(ival+1)*t));
                yhat(kval+1) = yhat(kval+1) + vr*qvikr - vi*qviki - qvlk;
                t = t + tstep;
            end
        end
    end
    
    %Calculate the feed-forward term and add its response
    t = 0.0;
    jval = 0;
    vlk = inamp(jval+1);
    thruk = 0.0;
    svlksq = 0.0;
    for kval=0:(nnthru-1)
        if (jval < ninputs)
            if (t >= (delay(jval+1)-ftstep))
                if (jval < (ninputs-1))
                    vlk = inamp(jval+2);
                else
                    vlk = 0.0;
                end
                jval = jval+1;
            end
            thruk = thruk + vlk*(y(kval+1)-yhat(kval+1));
            svlksq = svlksq + vlk*vlk;
            t = t + tstep;
        else
            break;
        end
    end
    
    thru = thruk/svlksq;
    
    if (incthru~=0)
        t = 0.0;
        jval = 0.0;
        tvlk = thru*inamp(jval+1);
        for kval=0:(n-1)
            if (jval < ninputs)
                if (t >= (delay(jval+1)-ftstep))
                    if (jval < (ninputs-1))
                        tvlk = thru*inamp(jval+2);
                    else
                        tvlk = 0.0;
                    end
                    jval = jval+1;
                end
                yhat(kval+1) = yhat(kval+1) + tvlk;
                t = t + tstep;
            else
                break;
            end
        end
    end
end

%Trim the output
if (n > nncalc)
    yhat = yhat(1:nncalc);
end

end %End function

%Other functions
%Complex exponential, done in the same fashion as old C code
function [zr,zi]=cexpz_m(xr,xi)
% Computes the complex exponetial of a complex number
% [zr,zi] = cexpz_m(xr,xi)
% where
% zr+j*zi = exp(xr+j*xi)
if ((nargin~=2) || (nargout~=2))
    error('cexpz_m: Please specify all input and output arguments');
end
w = exp(xr);
zr = w*cos(xi);
zi = w*sin(xi);
end

%Complex division, done in the same fashion as old C code
function [zr,zi]=cdivz_m(xr,xi,yr,yi)
% Computes the division of two complex numbers explicitly
% [zr,zi]=cdivz_m(xr,xi,yr,yi)
% where
% zr+j*zi = (xr+j*xi)/(yr+j*yi)
if ((nargin~=4) || (nargout~=2))
    error('cdivz_m: Please specify all input and output arguments');
end

w = yr*yr+yi*yi;
zr = (xr*yr+xi*yi)/w;
zi = (xi*yr-xr*yi)/w;
end

