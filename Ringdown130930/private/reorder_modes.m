% ***********************************************************************
%  ORDER:  Reorder system modes according to a selected criteria.
%
%  Contributors:  D. Trudnowski, Montana Tech
%                 J. M. Johnson, Pacifi% Northwest National Laboratory
%
%  Date:  December 1992, April 1993, March 1995
%  Updated:  September 1996
%
%  This subroutine reorders the paramters of
%
%            QCON
%    yhat(t)=sum AMP(i)*exp(t*DAMP(i))*cos(t*FRQ(i)+PHASE(i))
%            i=1
%
%             QCON AMP(i)/2 angle PHASE(i)    AMP(i)/2 angle -PHASE(i)
%    YHAT(jw)=sum  ------------------------ + ------------------------
%             i=1   jw + DAMP(i)-j*FRQ(i)      jw + DAMP(i)+j*FRQ(i)
%
%  according to the Akaike Final Prediction Error (FPE) or according to
%  decreasing mode energy.
%
% ***********************************************************************
%
%  Input Variables:
%    TIME    : Vector of sample times (0,...,NNFIT-1).
%    TSIG    : Vector of time response samples (0,...,NNFIT-1).
%              Used only if ACTUAL == 1.
%    NNFIT   : Number of sample times.
%    OMEGA   : Vector of sample frequencies (0,...,NFNFIT-1).
%    FRSIGR  : Vector of real parts of frequency response samples.
%              Used only if ACTUAL == 1.
%    FRSIGI  : Vector of imaginary parts of frequency response samples.
%              Used only if ACTUAL == 1.
%    NFNFIT  : Number of sample frequencies.
%    QCON    : Number of modes.
%    AMP     : Mode amplitudes (1,...,QCON).
%    DAMP    : Mode damping factors (1,...,QCON) nepers.
%    FRQ     : Mode frequencies (1,...,QCON) rad/sec.
%    PHASE   : Mode phases (1,...,QCON) radians.
%    DAMMAX  : Terms with ABS(DAMP(I)) > DAMMAX are ignored.
%              Set DAMMAX <= 0 to disable.
%    FRQMAX  : Terms with ABS(FRQ(I)) > FRQMAX are ignored.
%              Set FRQMAX <= 0 to disable.
%    STABLE  : Ignore terms with DAMP(I) < STABLE.
%    ALPHA   : Weight on time response in FPE.
%    BETA    : Weight on frequency response in FPE.
%    ACTUAL  : If ACTUAL == 1, use the data in TSIG, FRSIGR, FRSIGI as
%              the full order model response.
%    ORDCON  : Reording method.
%              If ORDCON == 1, reorder according to FPE.
%              If ORDCON == 2, reorder according to mode energy.
%
%  Output Variables:
%    AMP     : Mode amplitudes reordered.
%    DAMP    : Mode damping factors reordered.
%    FRQ     : Mode frequencies reordered.
%    PHASE   : Mode phases reordered.
%    AIC     : Vector of Akaike FPE.
%    RELENG  : Relative mode energies.
%              Currently these are relative to that of the strongest mode.
%    MRETR   : Integer flag for fatal error.
%              MRETR ==   0 ==> No errors encountered during reordering.
%              MRETR ==  11 ==> Problem with ALPHA and/or BETA.
%              MRETR ==  12 ==> No terms within specified region.
%              MRETR == 101 ==> Norm of calculated full-order time response
%                               is zero.
%              MRETR == 102 ==> Norm of calculated full-order frequency
%                               response is zero.
%
% ***********************************************************************
% **************************************************************************
%
% The following represents the MATLAB translation of the original FORTRAN
% code for the ORDER function. It has been renamed to reorder_modes
% Author of the MATLAB code: Laurentiu Dan Marinovici
% Date: August - September 2013
%
% **************************************************************************
function [amp, damp, frq, phase, aic, releng, mretr] = reorder_modes(time, nnfit,...
    qcon, amp, damp, frq, phase, dammax, frqmax, stable, alpha, beta, ordcon),
    
    global ntaille nsize nwork nsigs nflgs inpmax mincon
    
    % initialize flags
    global wrnflg mretr copyrt fatalerr argerr orderr
    mretr = 0;

    % initialize other returned variables;
    aic = zeros(size(amp, 1), 1);
    releng = zeros(qcon, 1);

    % check input arguments
    if ordcon ~= 1 & ordcon ~= 2,
        ordcon = 2;
    end
    if alpha < 0 & beta < 0,
        mretr = 11;
        return
    end
    
    % Determine which terms are to be included in the reordering; place the
    % modes that are not used at the bottom of the list
    % qconsub = qcon;
    % indexes of the modes that are not going to be used
    not_used_ind = damp < stable | (dammax > 0 & abs(damp) > dammax) | (frqmax > 0 & abs(frq) > frqmax);
    % It looks like for this first stage of selection, the order is not
    % important, so I am not going to bother with getting the same order as
    % in the original FORTRAN code.
    amp = [amp(~not_used_ind); amp(not_used_ind)];
    damp = [damp(~not_used_ind); damp(not_used_ind)];
    frq = [frq(~not_used_ind); frq(not_used_ind)];
    phase = [phase(~not_used_ind); phase(not_used_ind)];
    aic(end:-1:(end + 1 - size(amp(not_used_ind), 1))) = 99999;
    
    % Number of terms included in reordering
    qconsub = sum(~not_used_ind); % just sum the logical indexes of those which are in use; should be the same as length(amp(~not_used_ind))
    if qconsub == 0,
        mretr = 12;
        return
    end
    
    % Calculate individual mode energies.
    % Calculate output and total output energy for full order model.
    mtnorm = zeros(qconsub, 1);
    mfnorm = zeros(qconsub, 1);
    tsig = zeros(nnfit, 1);
    for time_k = 1:nnfit,
        z = amp(1:qconsub, 1).*exp(-time(time_k)*damp(1:qconsub, 1)).*cos(time(time_k)*frq(1:qconsub, :) + phase(1:qconsub, :));
        mtnorm = mtnorm + z.^2; % individual mode energies
        tsig(time_k) = sum(z);
    end
    tnorm = sum(tsig.^2);
    
    if alpha > 0 & tnorm == 0,
        mretr = 101;
        return
    end
    ntnorm = nnfit*tnorm;
    
    % Jumping over a part of the FORTRAN code for the order function
    % because it relates to the sample frequencies, and in the function
    % call the number nfnfit = 0, which will make the FOR loop to be
    % omitted. Nevertheless, MFNORM = 0, so we can still keep it for the
    % rest of the code, just in case we decide to revise this function.
    
    % Caluculate the relative strength of each mode over the time and
    % frequency intervals specified
    releng(1:qconsub, 1) = mtnorm + mfnorm;
    x = max(0, max(releng(1:qconsub, 1)));
    releng(1:qconsub, 1) = releng(1:qconsub, 1)/x;
    
    % Sort modes according to criteria specified by ordcon
    if alpha > 0,
        td = tsig;
    end
    
    if ordcon == 1,
        for ind_i = 1:qconsub,
            fpemin = 1e+35;
            isv = 1;
            
            if alpha > 0,
                z = zeros(qconsub - ind_i + 1, nnfit);
                tdnorm_elem = zeros(qconsub - ind_i + 1, nnfit);
                for time_k = 1:nnfit,
                    z(1:(qconsub - ind_i + 1), time_k) = amp(ind_i:qconsub).*exp(-time(time_k)*damp(ind_i:qconsub)).*...
                        cos(time(time_k)*frq(ind_i:qconsub) + phase(ind_i:qconsub));
                    tdnorm_elem(1:(qconsub - ind_i + 1), time_k) = repmat(td(time_k), qconsub - ind_i + 1, 1) - z(1:(qconsub - ind_i + 1), time_k);
                end
                tdnorm = sum(tdnorm_elem.^2, 2);
                
                % Calculate FPE
                x = zeros(size(tdnorm));
                fpe = zeros(size(x));
                zdn = nnfit - 4*ind_i;
                if zdn ~= 0,
                    z = (nnfit + 4*ind_i)/zdn;
                else,
                    z = 1e+35;
                end
                x = alpha * tdnorm * z / ntnorm;
                fpe(x == 0) = -1e-35;
                fpe(~(x == 0)) = log(x(~(x == 0)));
                if min(fpe) < fpemin,
                    fpemin = min(fpe);
                    isv = find(fpe == min(fpe)) + ind_i - 1; % this changed from the original code because I do not do indexing over J, I go "vectorially"
                end
            end
            
            % Place the mode that causes the minimum FPE at point ind_i
            % in the list
            % ==========================
            amptmp = amp(isv);
            damptmp = damp(isv);
            frqtmp = frq(isv);
            phtmp = phase(isv);
            reltmp = releng(isv);
            % ==========================
            amp(isv) = amp(ind_i);
            damp(isv) = damp(ind_i);
            frq(isv) = frq(ind_i);
            phase(isv) = phase(ind_i);
            releng(isv) = releng(ind_i);
            % ==========================
            amp(ind_i) = amptmp;
            damp(ind_i) = damptmp;
            frq(ind_i) = frqtmp;
            phase(ind_i) = phtmp;
            releng(ind_i) = reltmp;
            % ==========================
            aic(ind_i) = fpemin;
            % Update the TD
            if alpha > 0,
                z = amptmp*exp(-time * damptmp).*cos(time * frqtmp + phtmp);
                td = td - z;
            end
        end
    else, % that is ordcon == 2
        for ind_i = 1:qconsub,
            relmax = 0;
            if max(releng(ind_i:qconsub)) > relmax,
                relmax = max(releng(ind_i:qconsub));
                find(releng == max(releng(ind_i:qconsub)));
                isv = find(releng(ind_i:qconsub) == max(releng(ind_i:qconsub))) + ind_i - 1;
            end
            % ==========================
            amptmp = amp(isv);
            damptmp = damp(isv);
            frqtmp = frq(isv);
            phtmp = phase(isv);
            reltmp = releng(isv);
            % ==========================
            amp(isv) = amp(ind_i);
            damp(isv) = damp(ind_i);
            frq(isv) = frq(ind_i);
            phase(isv) = phase(ind_i);
            releng(isv) = releng(ind_i);
            % ==========================
            amp(ind_i) = amptmp;
            damp(ind_i) = damptmp;
            frq(ind_i) = frqtmp;
            phase(ind_i) = phtmp;
            releng(ind_i) = reltmp;
            % ==========================
            % Calculate the FPE
            if alpha > 0,
                z = amptmp*exp(-time * damptmp).*cos(time * frqtmp + phtmp);
                td = td - z;
                tdnorm = sum(td.^2);
                
                x = zeros(size(tdnorm));
                zdn = nnfit - 4*ind_i;
                if zdn ~= 0,
                    z = (nnfit + 4*ind_i)/zdn;
                else,
                    z = 1e+35;
                end
                x = alpha * tdnorm * z / ntnorm;
                if x == 0,
                    aic(ind_i) = -1e-35;
                else,
                    aic(ind_i) = log(x);
                end
            end
        end
    end
end