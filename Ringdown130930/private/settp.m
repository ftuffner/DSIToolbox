% Function that sets the Toeplitz matrix, to form least squares Toeplitz
% system for denominator coefficients. Related to the step when
% forward/backward linear prediction is done.
% **************************************************************************
%
% The following represents the MATLAB translation of the original FORTRAN
% code for the SETTP function
% Author of the MATLAB code: Laurentiu Dan Marinovici
% Date: August - September 2013
%
% **************************************************************************
function [mat, c, n1] = settp(x, sigcon, n, p, fb, flag),
    
    global ntaille nsize nwork nsigs nflgs inpmax mincon
    
    % the total number of equations (rows in mat matrix) is n1
    n1 = 0;
    
    % begin loop to process all the signals in x given by column; total
    % number is sigcon
    for sig = 1 : sigcon,
        l = n(sig) - 1 + p; m = 0;
        if flag == 2 | flag == 3,
            l = n(sig) - 1;
            m = p;
        end
        k = 0; q = n(sig) - 1 + p;
        if flag >= 3
            k = p;
            q = n(sig) - 1;
        end
        % case where FORWARD equations are used
        if fb <= 2,
            if l - k + 1 >= 1,
                for i_ind = 1 : l - k + 1,
                    index = k + i_ind - 1;
                    if i_ind + n1 >= 1,
                        if index < 0 | index >= n(sig),
                            c(i_ind + n1, 1) = 0;
                        else,
                            c(i_ind + n1, 1) = - x(index + 1, sig);
                        end
                        for j_ind = 1 : p,
                            index = k - j_ind + i_ind - 1;
                            if index < 0 | index >= n(sig),
                                mat(i_ind + n1, j_ind) = 0;
                            else,
                                mat(i_ind + n1, j_ind) = x(index + 1, sig);
                            end
                        end
                    end
                end
            end
        end
        
        % case where BACKWARD equations are used
        if fb >= 2,
            n2 = q - m + 1;
            n3 = 1;
            if fb == 2,
                n3 = n2 + 1;
            end
            if n3 >= 1 & n3 + n2 >= 1,
                for i_ind = n3 : n3 + n2,
                    index = m - p + i_ind - n3;
                    if i_ind + n1 >= 1,
                        if index < 0 | index >= n(sig),
                            c(i_ind + n1, 1) = 0;
                        else,
                            c(i_ind + n1, 1) = - x(index + 1, sig);
                        end
                        for j_ind = 1 : p,
                            index = i_ind + j_ind - p - n3 + m;
                            if index < 0 | index >= n(sig),
                                mat(i_ind + n1, j_ind) = 0;
                            else,
                                mat(i_ind + n1, j_ind) = x(index + 1, sig);
                            end
                        end
                    end
                end
            end
        end
        n1 = n1 + l - k + 1;
        if fb == 2,
            n1 = n1 + n2;
        end
    end
end