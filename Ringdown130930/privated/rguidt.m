function [yd,tr]=rguidt(y,startind,endind,dtmode)

%$Id: rguidt.c,v 1.1 1997/12/27 00:32:40 d3h902 Exp $
%
%RGUIDT:  Trend removal function for BPA/PNNL Ringdown Analysis Tool.
%
%This function is to be compiled as a MATLAB 5.1 MEX file.
%
%MATLAB Call:
%
%  [yd,trends]=rguidt(y,startind,endind,dtmode);
%
%By Jeff M. Johnson, Pacific Northwest National Laboratory.
%Date : August 1997
% Ported from C to MATLAB on April 26, 2013 by Frank Tuffner
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
%  y        : Matrix with data from which to remove trends.
%
%  startind : Initial point indices for trend calculations.
%
%  endind   : Final point indices for trend calculations.
%
%  dtmode   : Trend removal modes.
%             dtmode(ii) == 0 ==> Do not remove trend from column ii.
%             dtmode(ii) == 1 ==> Remove initial point from column ii.
%             dtmode(ii) == 2 ==> Remove mean from column ii.
%             dtmode(ii) == 3 ==> Remove final point from column ii.
%             dtmode(ii) == 4 ==> Remove linear trend from column ii.
%
%  yd       : Data with trends removed.
%
%  trends   : Matrix with removed trends.
%
%*************************************************************************
%

%Check inputs and outputs
if (nargin ~= 4)
    error('Wrong number of input arguments');
end

inctrnd = (nargout == 2);

if ((nargout ~=1) && (inctrnd == false))
    error('Wrong number of output arguments');
end

%Check inputs for validity
if (any(~isreal(y)))
    error('All inputs must be purely real');
end

%Get input size
[nnsamp,nnsigs]=size(y);

%Check individual inputs - second input
[m,n]=size(startind);
if (m*n == 0)
    m = 0;
    n = 0;
end
if (((m>1) && (n>1)) || ((m ~=nnsigs) && (n ~= nnsigs)))
    error('Incorrect dimensions on second input');
end
for j=1:nnsigs
    st = startind(j);
    if ((st < 1) || (st > nnsamp))
        error('Out of range values on second input');
    end
end

%Check individual inputs - third input
[m,n]=size(endind);
if (m*n == 0)
    m = 0;
    n = 0;
end
if (((m>1) && (n>1)) || ((m ~=nnsigs) && (n ~= nnsigs)))
    error('Incorrect dimensions on third input');
end
for j=1:nnsigs
    st = startind(j);
    ed = endind(j);
    if ((st > ed) || (ed > nnsamp))
        error('Out of range values on third input');
    end
end

%Check individual inputs - fourth input
[m,n]=size(dtmode);
if (m*n == 0)
    m = 0;
    n = 0;
end
if (((m>1) && (n>1)) || ((m ~=nnsigs) && (n ~= nnsigs)))
    error('Incorrect dimensions on fourth input');
end
for j=1:nnsigs
    if ((dtmode(j) < 0) || (dtmode(j) > 4))
        error('Out of range values on fourth input');
    end
end

%Preallocate the output
yd = zeros(nnsamp,nnsigs);

%Create trend matrix, if wanted
if (inctrnd)
    tr = zeros(nnsamp,nnsigs);
end

%Remove teh trends
for j=1:nnsigs
    %Extract indices
    st = startind(j);
    ed = endind(j);
    dt = dtmode(j);
    
    %Perform detrending
    if (dt < 4) %Not 4 (single value subtractive)
        if (dt == 0)
            b = 0.0;
        elseif (dt == 1)
            b = y(st,j);
        elseif (dt == 2)
            b = mean(y((st:ed),j));
        else %must be 3
            b = y(ed,j);
        end
        
        %Remove
        yd(:,j) = y(:,j)-b;
        
        %If trend matrix desired, add
        if (inctrnd)
            tr(:,j) = b;
        end
    else %Must be 4 - linear
        %Initial conditions
        xs = 0;
        ys = 0;
        xs2 = 0;
        xys = 0;
        nn = (ed-st+1);
        
        %Loop through and figure out parameters
        for k = st:ed
            xx = k;
            yy = y(k,j);
            xs = xs + xx;
            ys = ys + yy;
            xs2 = xs2 + xx*xx;
            xys = xys + xx*yy;
        end
        
        %Calculate the slope
        a = (nn*xys-xs*ys)/(nn*xs2 - xs*xs);
        b = (ys-a*xs)/nn;
        
        %Make the removal
        tr_remove = a*((1:nnsamp)-1).' + b;
        
        %Remove it
        yd(:,j) = y(:,j) - tr_remove;
        
        %Store it, if wanted
        if (inctrnd)
            tr(:,j) = tr_remove;
        end
    end
end