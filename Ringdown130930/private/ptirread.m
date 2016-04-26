function [y,names,ptirname]=ptirread(ptirname);

% PTIRREAD:  pti, randypak 
% Reads data from a PTI file converted for RandyPak.
%
% Usage:
%
% [y,names,ptirname]=ptirread(ptirname);
%
% where
%
% ptirname = Name of PTIR file.  If this is empty or invalid, user is prompted to
%            select a file.
%
% y        = Data matrix.  First column is time.
%
% names    = Titles for data columns.

% By Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date:  January 2, 1996
%
% Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% Initialize output arguments
if nargout; y=[]; names=''; end

% Print RCSID stamp and copyright
if nargin==1 & ischar(ptirname) & strcmp(ptirname,'rcsid')
  fprintf(1,['\n$Id$\n\n' ...
    'Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government\n' ...
    'retains a paid-up nonexclusive, irrevocable worldwide license to\n' ...
    'reproduce, prepare derivative works, perform publicly and display\n' ...
    'publicly by or for the Government, including the right to distribute\n' ...
    'to other Government contractors.\n\n' ...
    'Date of last source code modification:  03/24/1999 (JMJ)\n\n']);
  return
end

if nargin<1; ptirname=[]; end

% Try to open the file.
if ~isempty(ptirname)
  ptirfid=fopen(setstr(ptirname),'rt');
else
  ptirfid=-1;
end

if ptirfid<0
  [n,p]=uigetfile('*','Select a PTIR file');
  if n==0; return; end
  ptirname=[p n];
  [ptirfid,message]=fopen(ptirname,'rt');
  if ptirfid<0; error(['Error opening file:  ' message]); end
end

% Read the entire file.
[ptirstr,count]=fread(ptirfid,inf,'uchar');
ptirstr=setstr(ptirstr');

% Close the file
fclose(ptirfid);

if count==0; error('Error reading file.'); end

% End of line character
c=computer;
if strcmp(c(1:2),'MA')
  newline=13;
else
  newline=10;
end

% Find the signal titles.
qtloc=find(ptirstr==34);
nncols=length(qtloc)/2;
names='';

if nncols-floor(nncols)>0; error('File does not have correct format.'); end

for ii=1:nncols
  name=ptirstr(qtloc(2*(ii-1)+1)+1:qtloc(2*(ii-1)+2)-1);
  eolloc=name>=9 & name<=13;
  name(eolloc)=[];                       % Strip out end of line characters in name string.
  names=str2mat(names,name);
end
names=str2mat('Time',names);

% Read the data
dataloc=qtloc(length(qtloc))+1;

y1=sscanf(ptirstr(dataloc:length(ptirstr)),'%f',[nncols+1,inf]);

y=y1';
