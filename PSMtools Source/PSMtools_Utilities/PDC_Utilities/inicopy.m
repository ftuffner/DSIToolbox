function [initext,fname,CFname]=inicopy(fname,ctag);
%
% Copies PDC configuration data from a PDC ini file.
%
%  [initext,fname,CFname]=inicopy(fname,ctag);
%
% Last modified 01/23/03.   jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


if  nargin<1, fname=''; ctag=';'; end;
if ~exist('ctag'), ctag='';  end
if  isempty(ctag), ctag=';'; end

initext=''; CFname='';

%********************************************************************
% Open configuration file
if ~isempty(fname)
  fname=deblank(fname);
  fid=fopen(setstr(fname),'r');
else
  fid=-1;
end
if fid<0
  disp(['In inicopy: Launching dialog box for PDC configuration file'])
  [n,p]=uigetfile('*.*','Select PDC configuration file:');
  if n==0; return; end;
  fname=[p n];
  [fid,message]=fopen(fname,'r');
  if fid<0; error(message); end;
end
Ctype=computer;
D='\';  %Default delimiter
if strcmp(Ctype,'MAC2'), D=':'; end
Ds=findstr(D,fname); 
if isempty(Ds)
  CFname=fname;
else
  last=Ds(size(Ds,2));
  CFname=fname(last+1:size(fname,2));
end
%********************************************************************

if max(size(fname))<60
  disp(['In inicopy: configuration file = ' fname])
else
  disp(['In inicopy: configuration file is '])
  disp(['  ' fname])
end

%********************************************************************
% Read file as lines of text
initext='';
for N=1:999
  cs=fgetl(fid);
  if ~isstr(cs), break, end
  if N==1, initext=cs;
  else initext=str2mat(initext,cs); end
end
%********************************************************************

fclose(fid);

%end of PSMT m-file

