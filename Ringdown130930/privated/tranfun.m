% **********************************************************************
% *
% * $Id$
% * SUBROUTINE TRANFUN
% *
% *  by:  Dan Trudnowski, Pacific NW Labs, April 1992.
% *
% *  References:  D. Trudnowski, "Pronyid and Sigpakz notebook" PNL
% *               Engineering Notebook, FY92.
% *
% *               D. Trudnowski, "BPA FY92 Task Ordering Agreement Notebook,"
% *               PNL Engineering Notebook, FY92.
% *
% *               D. Trudnowski, et.al.,"Identification of Oscillatory System
% *               Models using Prony Analysis, a Comparison with ARMA
% *               ARMA modelling,"  To be submitted for pub., 1992.
% *
% *               D. Pierre, et.al., "Identifying Reduced-Order Models for
% *               Large Nonlinear Systems with Arbitrary Initial Conditions
% *               and Multiple Outputs using Prony Signal Analysis," Proceedings
% *               of the 1990 American Control Conference, Vol. 1, pp. 149-154.
% *
% *               D. Trudnowski, "Decentralized Adaptive Control and System
% *               Identification with Applications to Power Systems," Ph.D.
% *               Thesis, Montana State University, 1991.
% *
% *  Consider the following Laplace transform system:
% *
% *
% *                ----------
% *    U(s)  ----->|  G(s)  |--Y(s)-->sampled at TSTEP----->
% *                ---------- 
% *
% *  A system model (G(s)) is identified by this routine where
% *
% *                   QCON     RES(i)       Conjugate(RES(i))
% *     G(s) = THRU + sum  [----------- + --------------------- ]
% *                   i=1   s-lambda(i)   s-Conjugat(lambda(i))
% *
% *
% *  where the eigenvalues (lambda(i)'s) are assumed distinct and may be
% *  real and/or zero.  This program identifies the RES(i) terms.  U(s) 
% *  is a known input of the form
% *
% *             NINPUTS          exp(-s*DELAY(j-1)) - exp(-s*DELAY(j))
% *     U(s) =   sum    INAMP(j) --------------------------------------
% *              j=1                                  s
% *
% *  A model of the output is assumed known after the input is turned off
% *  or on the last pulse of the input.  The output model is a sum of
% *  exponentials with eigenvalues EIG.  The output model starts at sample
% *  SHIFT:
% *         QCON
% *   y(t) = sum AMPOPT(j)*exp(-DAMP(j)*T)*cos(FRQRPS(j)*T+PHASE(j))
% *          j=1
% *
% *  For t=0, TSTEP, ..., (NNFIT-1)*TSTEP
% *
% *  System eigenvalues (lambda(i)'s) are:
% *      Real(lambda(i))=-DAMP(i)
% *      Imag(lambda(i))=FRQRPS(i)
% *
% *
% **************************************************************************
% *
% *  INPUT:
% *       NINPUTS = Number of input pulses.
% *       DELAY   = Input switching times (sec.)
% *                 (1...NINPUTS).  DELAY(0) assumed 0.
% *       INAMP   = Input pulse amplitudes. (1...NINPUTS).
% *       TSTEP   = Sample period.
% *       QCON    = Number of output conjugate pair terms.
% *       DAMP    = Damping of output eigenvalues (1...QCON) in rad/sec. 
% *       FRQRPS  = Frequency of output eigenvalues (rad/sec). (1...QCON).
% *       AMPOPT  = Amplitude of output terms.  (1...QCON)
% *       PHASE   = Phase of output amplitude terms in radians (1...QCON).
% *       SHIFT   = See Above.
% *
% *  OUTPUT:
% *       RESR    = Real part of trans. func. residues.  (1...QCON).
% *       RESI    = Imag. part of trans. func. residues.  (1...QCON).
% *       DCTERM  = DC Term due to input.  Calculated if input is step.
% *
% ********************************************************************
% **************************************************************************
%
% The following represents the MATLAB translation of the original FORTRAN
% code for the TRANFUN function
% Author of the MATLAB code: Laurentiu Dan Marinovici
% Date: August - September 2013
%
% **************************************************************************
function [resr, resi, dcterm] = tranfun(ninputs, delay, inamp, tstep, qcon, damp,...
    frqrps, ampopt, phase, shift),
    
    global ntaille nsize nwork nsigs nflgs inpmax mincon
    
    % ================== IMPORTANT !!!!!!!!!!!!!!!! ==================
    % It seems that setting delay(1) = 0 is only done such that hey can
    % compute de delay differences later on. Technically, the actual delays
    % are introduced even in FORTRAN from index 1 to ninputs, which
    % practically will make the length of delay vector to be ninputs+1.
    % I will try to get around this while having inamp and delay vectors
    % having the same ninputs length
    %
    % delay(1) = 0;
    %
    % ================================================================
    
    % Initialize internal function variables
    bresr = zeros(size(ampopt));
    bresi = zeros(size(ampopt));
    resr = zeros(size(ampopt));
    resi = zeros(size(ampopt));
    l = 0;
    x = 1E+12;
    
    % Calculate output residue and find term at zero in the s-plane
    if any(frqrps == 0),
        x = min(abs(damp(frqrps == 0)));
        l = find(abs(damp) == min(abs(damp(frqrps == 0))));
    end
    
    % ires0 is an index, and it is going to become non-zero, only if there
    % exists a term at zero in the s-plane
    ires0 = 0;
    bres0 = 0;
    if x < 1e-4,
        ires0 = l;
        bres0 = ampopt(ires0) * cos(phase(ires0));
    end
    
    % vector operations, MATLAB style
    bresr([1:length(bresr)] ~= ires0) = ampopt([1:length(ampopt)] ~= ires0) .* cos(phase([1:length(phase)] ~= ires0)) / 2;
    bresi([1:length(bresi)] ~= ires0) = ampopt([1:length(ampopt)] ~= ires0) .* sin(phase([1:length(phase)] ~= ires0)) / 2;
    
    % Shift output residues
    instep = 0;
    intot = ninputs;
    t = shift * tstep - delay(intot);
    if t < -1e-8,
        instep = 1;
        intot = ninputs - 1;
        if intot == 0,
            t = shift * tstep;
        else,
            t = shift * tstep - delay(intot);
        end
    end
    if t > 0,
        % vector calculation, MATLAB style
        xr = t * damp([1:length(damp)] ~= ires0);
        xi = -t * frqrps([1:length(frqrps)] ~= ires0);
        yr = real(exp(complex(xr, xi)));
        yi = imag(exp(complex(xr, xi)));
        xr = real(complex(bresr([1:length(bresr)] ~= ires0), bresi([1:length(bresi)] ~= ires0)) .* complex(yr, yi));
        xi = imag(complex(bresr([1:length(bresr)] ~= ires0), bresi([1:length(bresi)] ~= ires0)) .* complex(yr, yi));
        bresr([1:length(bresr)] ~= ires0) = xr;
        bresi([1:length(bresi)] ~= ires0) = xi;
    end
    
    % Calculate residue for zero eigenvalue if input is not step
    if instep == 0,
        dcterm = 0;
        lastamp = 0;
        x = inamp(1:intot)' * [delay(1); diff(delay(1:intot))];
        res0 = 0;
        if abs(x) > 1e-12,
            res0 = bres0 / x;
        end
    else,
        dcterm = bres0;
        res0 = 0;
        lastamp = inamp(ninputs);
        
        % If a STEP function, calculate residues
        if intot == 0,
            eigr = - damp([1:length(damp)] ~= ires0);
            eigi = frqrps([1:length(frqrps)] ~= ires0);
            resr([1:length(resr)] ~= ires0) = real(complex(eigr, eigi) .*...
                complex(bresr([1:length(bresr)] ~= ires0), bresi([1:length(bresi)] ~= ires0)));
            resi([1:length(resi)] ~= ires0) = imag(complex(eigr, eigi) .*...
                complex(bresr([1:length(bresr)] ~= ires0), bresi([1:length(bresi)] ~= ires0)));
            resr([1:length(resr)] ~= ires0) = resr([1:length(resr)] ~= ires0) / inamp(1);
            resi([1:length(resi)] ~= ires0) = resi([1:length(resi)] ~= ires0) / inamp(1);
            
            % Add residue at zero to list
            if ires0 > 0,
                resr(ires0) = res0 / 2;
                resi(ires0) = 0;
            end
            
            % Now we return to the main script
            return
        end
    end
    
    % Calculate residues
    % This part is going to be run either instep = 0, or (instep = 1, & intot ~= 0)
    for ind = 1:qcon,
        if ind ~= ires0,
            eigr = -damp(ind);
            eigi = frqrps(ind);
            yr = eigr * [delay(intot); delay(intot) - delay(1:(intot - 1))];
            yi = eigi * [delay(intot); delay(intot) - delay(1:(intot - 1))];
            yr2 = eigr * (delay(intot) - delay(1:intot));
            yi2 = eigi * (delay(intot) - delay(1:intot));
            zr = real(exp(complex(yr, yi)));
            zi = imag(exp(complex(yr, yi)));
            zr2 = real(exp(complex(yr2, yi2)));
            zi2 = imag(exp(complex(yr2, yi2)));
            xr = lastamp + inamp(1:intot)' * (zr - zr2); % technically, inamp and delay (thus, zr) should be row vectors and doing scalar product
                                                 % should give the sum of the elements
            xi = inamp(1:intot)' * (zi - zi2);
            xr2 = real(complex(eigr, eigi) * complex(bresr(ind), bresi(ind)));
            xi2 = imag(complex(eigr, eigi) * complex(bresr(ind), bresi(ind)));
            resr(ind) = real(complex(xr2, xi2) / complex(xr, xi));
            resi(ind) = imag(complex(xr2, xi2) / complex(xr, xi));
        end
    end
    
    if ires0 > 0,
        resr(ires0) = res0 / 2;
        resi(ires0) = 0;
    end
end