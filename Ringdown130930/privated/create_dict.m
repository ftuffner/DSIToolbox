% This fucntion creates the dictionary for all the messages requird by the
% code to either print information like copyrights, or display error or
% warning messages.
function [mretr, wrnflg, copyrt, fatalerr, argerr, orderr] = create_dict(),

    global wrnflg mretr copyrt fatalerr argerr orderr
    
    mretr = MsgDict(); % initialize error messages
    wrnflg = MsgDict(); % initialize warning messages
    copyrt = MsgDict(); % initialize copyright messages
    fatalerr = MsgDict(); % intialize fatal error messages
    argerr = MsgDict(); % initialize the function argument error messages
    orderr = MsgDict(); % initialize error structure for the ordering algorithm
        
    % error messages
    mretr.add_elem('No Error', 0, 'No flags. Solution calculated.');
    mretr.add_elem('Error', 100, 'NNFIT < 3, i.e., too small.');
    mretr.add_elem('Error', 110, 'XSIG is a null signal.');
    mretr.add_elem('Error', 102, 'QCON < 1, i.e., too small.');
    mretr.add_elem('Error', 103, 'LPOCON < 1, i.e., too small.');
    mretr.add_elem('Error', 104, 'TSTEP too small.');
    mretr.add_elem('Error', 105, 'QCON too small.  Try increasing QCON or set QCON < KNWMOD');
    
    % warning error messages
    wrnflg.add_elem('Warning', 1, 'Numerical solution on the linear prediction SVD may be in error.');
    wrnflg.add_elem('Warning', 2, 'Numerical solution on the linear prediction QR may be in error.');
    wrnflg.add_elem('Warning', 3, 'Numerical solution on the linear prediction. Total Least Squares SVD may be in error.');
    wrnflg.add_elem('Warning', 4, 'Numerical solution on the root finder may be in error.');
    wrnflg.add_elem('Warning', 5, 'Possible errors in the residue solution due to large elements in the Vandermonde matrix.');
    wrnflg.add_elem('Warning', 6, 'Numerical solution on the Vandermonde problem may be in error.');
    
    % Battelle Copyright
    copyrt.add_elem('Copyright', 1, 'Copyright (c) 1995-2012 Battelle Memorial Institute.');
    copyrt.add_elem('Copyright', 2, 'The Government retains a paid-up nonexclusive,');
    copyrt.add_elem('Copyright', 3, 'irrevocable worldwide license to reproduce, prepare');
    copyrt.add_elem('Copyright', 4, 'derivative works, perform publicly and display');
    copyrt.add_elem('Copyright', 5, 'publicly by or for the Government, including the right');
    copyrt.add_elem('Copyright', 6, 'to distribute to other Government contractors.');
    
    % fatal error messages
    fatalerr.add_elem('Fatal error', 0, 'Errors in input data.');
    fatalerr.add_elem('Fatal error', 1, 'Not enough data points.');
    fatalerr.add_elem('Fatal error', 2, 'No modes identfied.');
    fatalerr.add_elem('Fatal error', 3, 'Sample period too small.');
    fatalerr.add_elem('Fatal error', 4, 'Linear prediction order too small.');
    fatalerr.add_elem('Fatal error', 5, 'Data sequence is a null signal.');
    fatalerr.add_elem('Fatal error', 6, 'Cannot reorder identified modes.');
    fatalerr.add_elem('Fatal error', 7, 'Norm of full-order model time domain signal is zero.');
    fatalerr.add_elem('Fatal error', 8, 'Unknown error occurred.');
    
    % errors related to input/output arguments of functions
    argerr.add_elem('Argument error', 1, 'Wrong number of input arguments.');
    argerr.add_elem('Argument error', 2, 'Wrong number of output arguments.');
    argerr.add_elem('Argument error', 3, 'All inputs must be real.');
    argerr.add_elem('Argument error', 4, 'All inputs must be of class double.');
    argerr.add_elem('Argument error', 5, 'Incorrect dimensions for the signal data matrix.');
    argerr.add_elem('Argument error', 6, 'Sample time should be given as a positive scalar.');
    argerr.add_elem('Argument error', 7, 'Incorrect dimensions for matrix holding number of points to skip in each column, and number of analysed points in each column.');
    argerr.add_elem('Argument error', 8, 'Incorrect dimensions for input pulse matrix.');
    argerr.add_elem('Argument error', 9, 'Incorrect dimensions for the known mode matrix.');
    argerr.add_elem('Argument error', 10, 'Incorrect dimensions for the control matrix.');
    argerr.add_elem('Argument error', 11, 'Bad data in matrix holding number of points to skip in each column, and number of analysed points in each column.');
    argerr.add_elem('Argument error', 12, 'Bad data in the control matrix.');    
    
    % errors during ordering
    orderr.add_elem('Order error', 0, 'No errors encountered during reordering.');
    orderr.add_elem('Order error', 11, 'Problem with ALPHA and/or BETA.');
    orderr.add_elem('Order error', 12, 'No terms within specified region.');
    orderr.add_elem('Order error', 101, 'Norm of calculated full-order time response is zero.');
    orderr.add_elem('Order error', 102, 'Norm of calculated full-order frequency response is zero.');
end