function [pathname,filename]=PSMparse(fullpathname);

%  function [pathname,filename]=PSMparse(fullpathname);
%
%  Parses a full file path into the individual path and filename
%  components.
%

% Copyright (c) 1996 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% RCS Identification
  rcsid='$Id$';

% Platform specific path separator.
c=computer;
if strcmp(c,'MAC2')
  pathsep=':';
elseif (strcmp(c,'PCWIN') || strcmp(c,'PCWIN64'))
  pathsep='\';
elseif isunix
  pathsep='/';
else
  error(['Computer platform ' c ' not recognized.'])
end

pathseploc=find(fullpathname==pathsep);

if isempty(pathseploc)
  filename=fullpathname;
  pathname='';
else
  filenameloc=pathseploc(length(pathseploc));
  filename=fullpathname(filenameloc+1:length(fullpathname));
  pathname=fullpathname(1:filenameloc);
end

