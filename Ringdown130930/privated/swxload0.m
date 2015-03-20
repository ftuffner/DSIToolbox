function [y,names]=swxload0(h);

% Reads and "fixes" SWX file data for the Ringdown Analysis Tool.  Fixing the data
% includes:
%
% 1.  Read data from a file.  Uses an embedded version of swxread0.m
% 2.  Examine sample times.  Remove duplicate times at the end of data matrix.
% 3.  Locate remaining repeated sample times.  Delete all data from beginning of
%     file to last repeated sample time.
% 4.  Examine remaining points for non-uniform sample spacing.  Remove non-uniformly
%     spaced from beginning and end of record.

% By J. M. Johnson, Pacific Northwest National Laboratory
% Date:  February 22, 2001
%
% Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% Initialize output arguments
y=[]; names='';

% Print RCSID stamp and copyright
if nargin==1 & ischar(h) & strcmp(h,'rcsid')
  fprintf(1,['\n$Id$\n\n' ...
    'Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government\n' ...
    'retains a paid-up nonexclusive, irrevocable worldwide license to\n' ...
    'reproduce, prepare derivative works, perform publicly and display\n' ...
    'publicly by or for the Government, including the right to distribute\n' ...
    'to other Government contractors.\n\n' ...
    'Date of last source code modification:  05/30/2001 (JMJ)\n\n']);
  return
end

% Read data file
[output0,errmsg,wrnmsg]=swxread0;
if ~isempty(wrnmsg); uiwait(warndlg(wrnmsg,'Warning(s)','modal')); end
if ~isempty(errmsg); uiwait(errordlg(errmsg,'Error(s)','modal')); return; end

y=output0.data; names=output0.names;
if isempty(y); return; end

% Remove repeated sample times at end of record
n=size(y,1);
while n>1 & y(n-1,1)==y(n,1); n=n-1; end
if n~=size(y,1); y=y(1:n,:); end

% Locate remaining repeated sample times.
% Retain record from last repeated point forward
rep_indx=find(diff(y(:,1))<eps);
if ~isempty(rep_indx); y=y(rep_indx(end)+1:end,:); end

% Trim initial and final half steps
tsteps=diff(y(:,1)); tstep=max(tsteps);
keep_indx=find(tsteps>=0.9*tstep & tsteps<=1.1*tstep);
keep_indx=[keep_indx; keep_indx(end)+1];

if any(diff(keep_indx)~=1)
  errordlg('Error:  File contains unevenly spaced time samples.','Error','modal');
  y=[]; return;
end

y=y(keep_indx,:);

%=================================================================================
function [output0,errmsg,wrnmsg]=swxread0(filename,opts)

% SWXREAD0:  SWX, Swing Export
%
% Reads data from Swing Export (SWX) format files.
%
% Usage
%
%              [output0,errmsg,wrnmsg]=swxread0(filename,opts);
%
% where
%
%   filename = Name of data file to read.  If empty, user is prompted to
%              select a file.
%
%   opts     = Structure containing additional read options.  Currently
%              recognized fields include:
%
%              ctags   = Cell array of strings containing comment line
%                        delimiters for which to search.
%
%              sigindx = Vector of signal column numbers to read.
%                        Set to 'all' to read all columns.
%                        Set to [] to just read header information.
%
%   output0  = Structure containing read results.  Contains the following fields:
%
%              filename = Path and name of file read.
%
%              comments = Comment lines at top of file (with delimiters).
%
%              names    = Signal names read from file.
%
%              data     = Data matrix read from file.
%
%   errmsg   = Error message if runtime error occurs.  If this argument is not
%              present in the function call, a MATLAB error results.
%
%   wrnmsg   = Matrix of warning errors produced during file read.

% By Jeff M. Johnson, Battelle Pacific Northwest National Laboratory.
% Date:  February 26, 2001
%
% Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% Initialize output arguments
output0=struct('filename','','comments','','names','','data',[]);
errmsg=''; wrnmsg='';

% Print RCSID stamp and copyright
if nargin==1 & ischar(filename) & strcmp(filename,'rcsid')
  fprintf(1,['\n$Id$\n\n' ...
    'Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government\n' ...
    'retains a paid-up nonexclusive, irrevocable worldwide license to\n' ...
    'reproduce, prepare derivative works, perform publicly and display\n' ...
    'publicly by or for the Government, including the right to distribute\n' ...
    'to other Government contractors.\n\n' ...
    'Date of last source code modification:  05/22/2001 (JMJ)\n\n']);
  return
end

% Check input arguments
if nargin<1; filename=''; end
if nargin<2; opts=struct('junk',[]); end

% Check and parse the 'opts' input
if ~isstruct(opts); error('Opts input must be a structure.'); end

if isfield(opts,'ctags')

  ctags=opts.ctags;
  if ischar(ctags); ctags={ctags(1,:)}; end

  if ~iscell(ctags)
    error('''ctag'' field in ''opts'' argument must be a cell array.')
  elseif any(~cellfun('isclass',ctags,'char'))
    error('All ctags must be of class ''char''.')
  end

else

  ctags={'C ', 'c ', '! '};

end

% If no filename entered, prompt user to select
if isempty(filename)
  [n,p]=uigetfile('*.*','Select a SWX file to read');
  if n==0; return; end
  filename=[p n];
end

output0.filename=filename;

% Open the file
[fid,message]=fopen(filename,'rt');
if fid<0
  errmsg=sprintf('Error opening %s\nError message from MATLAB is %s',filename,message);
  if nargout<2; error(errmsg); else; return; end
end

% Read file header
eof=0;
ctag='';
comments='';
names='';
nncolshead=[];

while 1

  % Read line, remove leading blanks, and check for EOF
  try; lin=fgetl(fid); catch; fclose(fid); return; end
  if isequal(lin,-1); eof=1; break; end
  lin=strjust(lin,'left');

  % Determine comment delimiter, if not already defined
  if isempty(ctag)

    for ii=1:length(ctags)
      ctag0=ctags{ii}; lctag=length(ctag0);
      if strncmp(lin,ctag0,lctag)
        ctag=ctag0; comments=strjust(deblank(lin(lctag+1:end)),'left');
      end
    end

  % Check for comment line
  elseif strncmp(lin,ctag,lctag)

    comments=str2mat(comments,strjust(deblank(lin(lctag+1:end)),'left'));
    if ~isempty(names); names=''; end

  % Check for non-numerical characters in string
  elseif any(isletter(lin))

    if ~strncmp(lin,'names=',6); names=strvcat(names,deblank(lin)); end

  % Check for number of columns or first data row
  else

    data=sscanf(lin,'%f')'; nncols=length(data);

    if nncols>0
      if nncols==1 & abs(data-floor(data))<eps; nncolshead=data; else; break; end
    end
  
  end

end

% Fill output arguments
output0.comments=comments;
output0.names=names;

% Return if EOF
if eof; fclose(fid); return; end

errmsg='';

% Read signals to extract
if isfield(opts,'sigindx')

  if ischar(sigindx) & strcmp(sigindx,'all'); sigindx=1:nncols; end

  if any(~isnumeric(sigindx))
    errmsg='''sigindx'' field in ''opts'' must be ''all'' or a numeric array.';
  end

  if isempty(errmsg) & any(sigindx<1 | sigindx>nncols)
    errmsg='''sigindx'' field in ''opts'' input specifies columns not in file.';
  end

else

  sigindx=1:nncols;

end

if ~isempty(errmsg); fclose(fid); error(errmsg); end

data=data(sigindx); nnrows=1; mdata=1;

% Read file data
while 1

  % Read line and check for EOF
  try; lin=fgets(fid); catch; fclose(fid); return; end
  if isequal(lin,-1); break; end

  data0=sscanf(lin,'%f')';

  if ~isempty(data0)

    if length(data0)==nncols
      nnrows=nnrows+1;
      if nnrows>mdata; data=[data; zeros(100,nncols)]; mdata=size(data,1); end
      data(nnrows,:)=data0(sigindx);
    else
      errmsg=sprintf('Wrong number of samples in data row %d.',nnrows+1);
      break;
    end

  end

end

% Close file
fclose(fid);

% Fill output arguments
output0.data=data(1:nnrows,:);

% Check for correct number of signal names
if ~isempty(names)

  if size(names,1)==nncols-1; names=str2mat('Time',names); end

  if size(names,1)~=nncols
    errmsg0='Number of signal names and columns unequal.';
    if isempty(errmsg); errmsg=errmsg0; else; errmsg=[errmsg sprintf('\n') errmsg0]; end
  end
end

% Check for inconsistency between actual and number of columns indicated in header
if ~isempty(nncolshead)
  if nncolshead==nncols-1; nncolshead=nncols; end
  if nncolshead~=nncols; wrnmsg='Incorrect number of data columns indicated in file header.'; end
end

% Check for errors
if ~isempty(errmsg)
  [p,n]=fileparts(filename); errmsg=[sprintf('Error reading %s,\n',n) errmsg];
  if nargout<2; error(errmsg); else; return; end
end

% Check for warnings
if ~isempty(wrnmsg)
  [p,n]=fileparts(filename);
  wrnmsg=[sprintf('Warnings generated while reading %s:\n',n) wrnmsg];
  if nargout<3; disp(wrnmsg); end
end
