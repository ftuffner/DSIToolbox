 function [PSMtime]=Date2PSM(DateString);
% Convert Date to PSM time
%
%   [PSMtime]=PSM2Date(DateString);
%
%  Date string should be in format 10-Aug-1996 15:48:46.133
%  PSM time    = seconds starting at 1-Jan-1900
%  Matlab time = days    starting at 1-Jan-0000
%
% See also PSM2Date 
% 
% See also Matlab built-in functions NOW, DATESTR, DATENUM, DATEVEC 
% 
% Last modified 03/28/03.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

daysecs=24*3600;

%Date string should be in format 10-Aug-1996 15:48:46.133
DateString=deblank(DateString);
PSMtime=(datenum(DateString)-datenum(1900,1,1,0,0,0))*daysecs;
%disp(['Checking date: ' PSM2Date(PSMtime)])

return

%end PSMT utility 
