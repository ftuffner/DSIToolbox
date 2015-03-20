% Function that generates combinations of 1's and 0's
% **************************************************************************
%
% The following represents the MATLAB translation of the original FORTRAN
% code for the COMBIN function
% Author of the MATLAB code: Laurentiu Dan Marinovici
% Date: August - September 2013
%
% **************************************************************************
function new_ic = combin(n, m, ic)
    global ntaille nsize nwork nsigs nflgs inpmax mincon
    new_ic = ic;
    if m >= n | m == 0,
        % This message is for testing only
        % fprintf('Nothing to do in COMBIN function.\n');
    else,
        %n1 = n -1;
        j_ind = 1;
        nj = n - j_ind;
        while ic(n) == ic(nj) & j_ind < n,
            j_ind = j_ind + 1;
            nj = n - j_ind;
        end
        if mod(m, 2) == 0, % if m is even
            if ic(n) ~= 1,
                k1 = n - j_ind;
                k2 = k1 + 1;
            elseif ic(n) == 1,
                if mod(j_ind, 2) == 0, % j_ind is even
                    k1 = n - j_ind;
                    k2 = min(k1 + 2, n);
                elseif mod(j_ind, 2) == 1, % j_ind is odd
                    % scan form right to left
                    jp = (n - j_ind) - 1;
                    i_ind = 1;
                    i1 = jp + 2 - i_ind;
                    while ic(i1) == 0 & i_ind < jp,
                        i_ind = i_ind + 1;
                        i1 = jp + 2 - i_ind;
                    end
                    if ic(i1 - 1) == 1,
                        k1 = i1 - 1;
                        k2 = n - j_ind;
                    else,
                        k1 = i1 - 1;
                        k2 = (n + 1) - j_ind;
                    end
                end
            end
        elseif mod(m, 2) == 1, % if m is odd
            if ic(n) == 1,
                if mod(j_ind, 2) == 1,
                    k1 = n - j_ind;
                    k2 = min(k1 + 2, n);
                else,
                    % scan form right to left
                    jp = (n - j_ind) - 1;
                    i_ind = 1;
                    i1 = jp + 2 - i_ind;
                    while ic(i1) == 0 & i_ind < jp,
                        i_ind = i_ind + 1;
                        i1 = jp + 2 - i_ind;
                    end
                    if ic(i1 - 1) == 1,
                        k1 = i1 - 1;
                        k2 = n - j_ind;
                    else,
                        k1 = i1 - 1;
                        k2 = (n + 1) - j_ind;
                    end
                end
            else,
                k2 = (n - j_ind) - 1;
                if  k2 == 0,
                   k1 = 1;
                   k2 = (n + 1) - m; 
                else,
                    if ic(k2 + 1) == 1 & ic(k2) == 1,
                        k1 = n;
                    else,
                        k1 = k2 + 1;
                    end
                end
            end
        end
        new_ic(k1) = 1 - ic(k1);
        new_ic(k2) = 1 - ic(k2);
    end
end