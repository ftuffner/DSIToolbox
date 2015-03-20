function errmsg = SWXwrite(savefile,swxdata)

% SWXwrite :
%
% Writes time series data from one or more signals to a file of SWX format.
%
% Usage:
%
%                   errmsg = SWXwrite(savefile,swxdata);
%
% where
%
%   savefile = String matrix containing full path of file to create.  If empty
%             user is prompted to select a file.
%
%   swxdata = Structure containing signal data and title information.  Fields
%             include:
%             title    = String matrix with title to appear in file header.
%             comments = String matrix with comments to appear in file header.
%             names    = String matrix with names of signals in sigdat.
%             timdat   = Matrix with time sample information.  Can be entered
%                        as a 1 x 2 matrix or as a N x 1 matrix.  If entered as
%                        a 1 x 2 matrix
%                        timdat(1) = Time of initial sample.
%                        timdat(2) = Spacing between adjacent samples.
%                        If entered as a M x 1 matrix, M is the number of rows
%                        in sigdat and points represent times at which samples
%                        in sigdat were acquired.
%             sigdat   = Matrix with signal data information.  Dimensions are
%                        M x N where M is the number of samples and N is the
%                        number of signals.
%
%   errmsg  = String describing any errors that occur.  If not present in function
%             call, errors are handled with the MATLAB error() function.

% Author:  Jeff M. Johnson, Battelle Pacific Northwest National Laboratory.
% Date:  June 5, 2000
%
% Last modified 06/04/02   jfh

% Copyright (c) 1995-2000 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

if ~exist('savefile'), savefile='';, end
if isempty(savefile)
  disp(['In SWXwrite: Savefile not defined yet'])
else
  disp(['In SWXwrite: Save to file ' savefile])
end

%*************************************************************************
%Check input arguments
error(nargchk(2,2,nargin))

if ~ischar(savefile) | size(savefile, 1) > 1
  error('Input ''savefile'' must be a string matrix with one row.')
end

if ~isstruct(swxdata)
  error('Input ''swxdata'' must be a 1 x 1 structure array.')
end

if isfield(swxdata, 'title')
  if ~ischar(swxdata.title)
    error('Field ''title'' in input ''swxdata'' must be a string matrix.')
  end
  title0 = swxdata.title;
else
  title0 = '';
end

if isfield(swxdata, 'comments')
  if ~ischar(swxdata.comments)
    error('Field ''comments'' in input ''swxdata'' must be a string matrix.')
  end
  comments0 = str2mat('', swxdata.comments);
else
  comments0 = '';
end

if isfield(swxdata, 'sigdat')
  if ~isa(swxdata.sigdat, 'double')
    error('Field ''sigdat'' in input ''swxdata'' must be of class ''double''.');
  end
  sigdat = swxdata.sigdat; nnsigs = size(sigdat, 2);
else
  error('Input ''swxdata'' must contain a field titled ''sigdat''.')
end

if isfield(swxdata, 'names')
  if ~ischar(swxdata.names)
    error('Field ''names'' in input ''swxdata'' must be a string matrix.')
  end
  if size(swxdata.names, 1) ~= nnsigs+1
    error(['Number of rows in swxdata.names must equal number of total columns ' ...
      'in swxdata'])
  end
  names0 = swxdata.names;
else
  names0 = '';
end

if isfield(swxdata, 'timdat')
  if ~isa(swxdata.timdat, 'double')
    error('Field ''timdat'' in input ''swxdata'' must be of class ''double''.');
  end
  if size(swxdata.timdat) == [1 2]
    timdat=swxdata.timdat(1) + swxdata.timdat(2) * (0:size(sigdat, 1) - 1)';
  else
    if size(swxdata.timdat) ~= [size(sigdat, 1) 1]
      error('Field ''timdat'' in input ''swxdata'' is of incorrect dimension''.');
    end
    timdat = swxdata.timdat;
  end
else
  error('Input ''swxdata'' must contain a field titled ''timdat''.')
end
%*************************************************************************

%Put additional error checking here
disp('In SWXwrite: Primary error tests complete')

%*************************************************************************
%Comment delimiter and digits of precision.
cstr = 'C ';
prec = 4;
%*************************************************************************

%*************************************************************************
%If no SWX file name entered, prompt user to select a file
if isempty(savefile)
  [n, p] = uiputfile('*.*', 'Select file to create.');
  if ~ischar(n)
    errmsg = 'File select operation cancelled by user.'
    if ~nargout; disp(errmsg); end; return
  end
  savefile = [p, n];
end
%*************************************************************************

%*************************************************************************
%Create the SWX file
disp(['In SWXwrite: Save to file ' savefile])
fid = fopen(savefile, 'wt');
if fid < 0
  errmsg = ['Error opening file:  ' savefile];
  if ~nargout; error(errmsg); end; return;
end
%*************************************************************************

%*************************************************************************
%Write the title information
fstr = [cstr '** %s\n'];

for ii = 1:size(title0, 1)
  str = sprintf(fstr, deblank(title0(ii, :))); cnt = fprintf(fid, str);
  if cnt ~= length(str)
    errmsg = ['Error writing title information to ''', savefile, ''''];
    fclose(fid); if ~nargout; error(errmsg); end; return;
  end
end

%Write the comments
fstr = [cstr '%s\n'];
for ii = 1:size(comments0, 1)
  str = [comments0(ii, :) '    ']; 
  if strcmp(lower(str(1:2)),'c ')
    str = str(3:length(str));
  end
  LX  = findstr(str,'%'); str(LX)=' ';
  str = deblank(str);
  str = sprintf(fstr, str); cnt = fprintf(fid, str);
  if cnt ~= length(str)
    %errmsg = ['Error writing comment information to ''', savefile, '''']
    %disp(str), disp(cnt)
    %fclose(fid); if ~nargout; error(errmsg); end; return;
  end
end
str = sprintf(fstr, '  ');  %safety cushion
cnt = fprintf(fid, str);

%disp('In SWXwrite:'); keyboard
fstr = '%s\n';
%Write the file reference time as a DateString
str='reference time='; 
str=sprintf(fstr, str); cnt = fprintf(fid, str);
str=swxdata.DateString;
str=sprintf(fstr, str); cnt = fprintf(fid, str);
%Write the time step
str='time step='; 
str=sprintf(fstr, str); cnt = fprintf(fid, str);
tstep=swxdata.timestep;
str = sprintf('%d\n', tstep); cnt = fprintf(fid, str);
%Write the number of signal columns (including time column)
str='columns='; 
str=sprintf(fstr, str); cnt = fprintf(fid, str);
str = sprintf('%d\n', nnsigs+1); cnt = fprintf(fid, str);
if cnt ~= length(str)
  warning = ['Error writing number of signals to ''', savefile, ''''];
  disp(warning)
  keybdok=promptyn(['In SWXwrite: Do you want the keyboard? '], 'n');
  if keybdok
    disp(['In SWXwrite: Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end

%Write the signal names (including time)
fstr = '%s\n';
%str='names=';
str=sprintf(fstr, 'names='); cnt = fprintf(fid, str);
for ii = 1:size(names0, 1)
  str = sprintf(fstr, deblank(names0(ii, :))); cnt = fprintf(fid, str);
  if cnt ~= length(str)
    warning = sprintf('  Possible error writing signal name %3.0i', ii);
    warning = [warning ' to ''', savefile, ''''];
    disp(warning)
    keybdok=promptyn(['In SWXwrite: Do you want the keyboard? '], 'n');
    if keybdok
      disp(['In SWXwrite: Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
    end
  end
end

%Write the time and signal data
fstr = sprintf('%%0.%df\\t', prec * ones(1, nnsigs + 1)); fstr(end) = 'n';

str = sprintf(fstr, [timdat'; sigdat']); cnt = fprintf(fid, str);
if cnt ~= length(str)
  errmsg = ['Error writing signal data to ''', savefile, ''''];
  fclose(fid); if ~nargout, error(errmsg); end; return;
end
%*************************************************************************

%*************************************************************************
%Display path & name for SWX file
NameCk1=fopen(fid); NameCk2=cd;
disp('In SWXwrite: Data saved in file indicated below:')
NameCk=[NameCk2 '\' NameCk1]; disp(NameCk)
%*************************************************************************

%Close the file
fclose(fid);

%end of PSMT function
