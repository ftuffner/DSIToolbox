function [y,names,units,filename,headerdat]=PSAMread(filename);

% PSAMREAD:  psam
% Reads data from a PSAM header file.
%
% Usage:
%
%          [y,names,units,filename,headerdat]=PSAMread(filename);
%
% where
%
%   filename  = Name of PSAM file.  If this is empty or invalid, user is prompted
%               to select a file.
%
%   y         = Data matrix.  First column is time.
%
%   names     = Titles for data columns.
%
%   units     = Units for data columns.
%
%   headerdat = Structure containing data read from file header (and footer).
%               Fields are:
%               f_type  = String describing file type.  Currently, this is
%                         always 'BPA_PSAM'
%               datenum = Date/time expressed as serial date number.  See help
%                         for DATENUM function.
%               datestr = Date/time expressed as string.

% By Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date:  September 8, 1999
%
% Last modified 09/09/99.  jfh
%
% Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% Print RCSID stamp and copyright
if nargin==1 & isstr(filename) & strcmp(filename,'rcsid')
  fprintf(1,['\n$Id$\n\n' ...
    'Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government\n' ...
    'retains a paid-up nonexclusive, irrevocable worldwide license to\n' ...
    'reproduce, prepare derivative works, perform publicly and display\n' ...
    'publicly by or for the Government, including the right to distribute\n' ...
    'to other Government contractors.\n\n' ...
    'Date of last source code modification:  09/08/1999 (JMJ)\n\n']);
  return
end

if nargin<1; filename=''; end

if isempty(filename)
  [n,p]=uigetfile('*.*','Select a PSAM file');
  if n==0; return; end
  filename=[p n];
end

% Try to open the file
[psamfid,message]=fopen(filename,'rt');
if psamfid<0
  error(sprintf('Error opening %s,\nError message from MATLAB is %s',filename,message));
end

% Format string for error messages
errfstr=sprintf('Error reading %s,\n',filename);

% Insert file type in headerdat output
headerdat.f_type='BPA_PSAM';

% Read the entire file
[psamstr,count]=fread(psamfid,inf,'uchar'); fclose(psamfid);
if count==0; error(errfstr); end; psamstr=char(psamstr');

% Read the date and time stamps
ind1=findstr('DATE ',psamstr);
if isempty(ind1)
  ddat=[];
else
  ind1=ind1(1)+5;
  ind2=ind1; while psamstr(ind2)~=10 & psamstr(ind2)~=13; ind2=ind2+1; end
  ddat=sscanf(psamstr(ind1:ind2),'%d-%d-%d',3);
  if length(ddat)<3; ddat=[]; end
end
if isempty(ddat); error([errfstr 'Unable to read date from file']); end
if ddat(3)<70; ddat(3)=ddat(3)+2000; else; ddat(3)=ddat(3)+1900; end

ind1=findstr('TIME ',psamstr);
if isempty(ind1)
  tdat=[];
else
  ind1=ind1(1)+5;
  ind2=ind1; while psamstr(ind2)~=10 & psamstr(ind2)~=13; ind2=ind2+1; end
  tstr=fliplr(deblank(fliplr(deblank(psamstr(ind1:ind2)))));
  tdat=sscanf(tstr,'%d:%d:%f',3);
  if length(tdat)<3; tdat=[]; end
end
if isempty(tdat); error([errfstr 'Unable to read time from file']); end

% Create date/time fields in headerdat output structure
day2sec=24*60*60;
fraction=tdat(3)-fix(tdat(3)); tdat(3)=fix(tdat(3));
headerdat.datenum=datenum(ddat(3),ddat(1),ddat(2),tdat(1),tdat(2),tdat(3))+fraction/day2sec;
headerdat.datestr=[datestr(headerdat.datenum,1) ' ' tstr];
  
% Read the sample period
ind1=findstr('INTERVAL ',psamstr);
if isempty(ind1)
  tstep=[];
else
  ind1=ind1+9;
  ind2=ind1; while psamstr(ind2)~=13 & psamstr(ind2)~=10; ind2=ind2+1; end
  tstep=sscanf(psamstr(ind1:ind2),'%f',1);
end
if isempty(tstep); error([errfstr 'Unable to read sample period']); end

% Read the number of channels
ind1=findstr('NUM_SERIES ',psamstr);
if isempty(ind1)
  nnchannels=[];
else
  ind1=ind1+11;
  ind2=ind1; while psamstr(ind2)~=13 & psamstr(ind2)~=10; ind2=ind2+1; end
  nnchannels=sscanf(psamstr(ind1:ind2),'%d',1);
end
if isempty(nnchannels); error([errfstr 'Unable to read number of channels']); end

% Read the number of samples per channel
ind1=findstr('NUM_SAMPS ',psamstr);
if isempty(ind1)
  nnsamples=[];
else
  ind1=ind1+10;
  ind2=ind1; while psamstr(ind2)~=13 & psamstr(ind2)~=10; ind2=ind2+1; end
  nnsamples=sscanf(psamstr(ind1:ind2),'%d',1);
end
if isempty(nnsamples); error([errfstr 'Unable to read number of samples']); end

% Read the signal names and units.
ind1=findstr('COMMENT #',psamstr);
if length(ind1)<nnchannels
  error([errfstr 'Unable to read titles for all channels']);
end

namescell=cell(nnchannels+1,1); namescell{1}='Time';
unitscell=cell(nnchannels+1,1); unitscell{1}='sec'; ind1=ind1+9;

% There may be more elegant ways to code this section, but . . .
for ii=1:nnchannels
  ind2=ind1(ii); while psamstr(ind2)~=13 & psamstr(ind2)~=10; ind2=ind2+1; end
  ind3=ind1(ii); while ~isletter(psamstr(ind3)) & ind3<ind2; ind3=ind3+1; end
  ind4=ind3; while isletter(psamstr(ind4)) & ind4<ind2; ind4=ind4+1; end
  unitscell{ii+1}=psamstr(ind3:ind4-1);
  while ~isletter(psamstr(ind4)) & ind4<ind2; ind4=ind4+1; end
  namescell{ii+1}=deblank(psamstr(ind4:ind2-1));
end

names=char(namescell); units=char(unitscell);

% Read the data.
ind1=findstr('DATA',psamstr);
if isempty(ind1); error([errfstr 'Unable to find data section']); end

ind1=ind1(end)+4; ind2=find(psamstr(ind1:end)==13);
if isempty(ind2); ind2=find(psamstr(ind1:end)==10); end
if length(ind2)<nnsamples
  error([errfstr 'Unable to read data section']);
end
ind2=ind1+ind2;
if psamstr(end)~=10 & psamstr(end)~=13; ind2=[ind2; length(psamstr)]; end

% Preallocate the data matrix.  Insert the time column.
y=[tstep*(0:nnsamples-1)' zeros(nnsamples,nnchannels)];

% We are using a for loop here.  It was found that using a single call to
% sscanf to read the entire data section results in very slow execution.
for ii=1:nnsamples
  [h,count]=sscanf(psamstr(ind2(ii)+1:ind2(ii+1)-1),'%f');
  if count~=nnchannels
    error([errfstr sprintf('Data row %d should contain %d samples, read %d', ...
      ii,nnchannels,count)]);
  end
  y(ii,2:end)=h';
end
