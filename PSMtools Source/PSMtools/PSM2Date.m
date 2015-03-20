 function [DateString,MatlabTime]=PSM2Date(PSMtime);
% Convert PSM time to Matlab time, then to date string
%
%  [DateString,MatlabTime]=PSM2Date(PSMtime);
%
%  PSM time    = seconds starting at 1-Jan-1900
%  Matlab time = days    starting at 1-Jan-0000
%  Date string will be in format 10-Aug-1996 15:48:46.133
% 
% See also date2PSM
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

DateString='';
lines=max(size(PSMtime));
daysecs=24*3600;
%keyboard

MatlabTime=zeros(lines,1);
for N=1:lines
  secfrac=PSMtime(N)-fix(PSMtime(N));
  secfrac=round(secfrac*1000)/1000;   
  PSMtime(N)=floor(PSMtime(N))+secfrac;
  secfrac=PSMtime(N)-fix(PSMtime(N));
  MatlabTime(N)=datenum(1900,1,1,0,0,0)+floor(PSMtime(N))/daysecs;
  DateStr=datestr(MatlabTime(N),0);
  Tag=sprintf('%3.0i',round(secfrac*1000));
  if secfrac==0, Tag='000'; end
  locs=findstr(' ',Tag); Tag(locs)='0';
  DateStr=[DateStr '.' Tag];
  if N==1, DateString=DateStr;
  else DateString=str2mat(DateString,DateStr);
  end
end

return

%end PSM file 
