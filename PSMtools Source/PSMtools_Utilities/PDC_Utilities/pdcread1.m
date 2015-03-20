function [errmsg, varnames] = pdcread1(pdcfname_l, fmt_l, SaveFile);

% Reads data from PDC binary file and stores variables in
% calling function workspace or a .mat file.  Supports
% MATLAB I and MATLAB II formats; others may be added later.
%
% Usage:
%
%   [errmsg, varnames] = pdcread1(pdcfname, fmt, SaveFile);
%
% where
%
%   pdcfname = Name of binary PDC data file to read.
%
%   fmt      = Format in which to store data in workspace.
%              Set equal to 1 for MATLAB I format.
%              Set equal to 2 for MATLAB II format.
%              (other formats may be added later)
%
%   SaveFile = Name of file in which to store data.  If
%              this argument is not present, no save operation
%  			      is performed.
%
%   errmsg   = String containing text describing any errors
%              that occurred.
%
%   varnames = Cell array containing names of variables created
%              in workspace or file.

% Author:  Jeff M. Johnson, Battelle Pacific Northwest National Laboratory
% Date:  February 5, 1999
%
% Copyright (c) 1995-1999 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% Last change 02/12/99.  jfh
%
% $Id$

% Check number of input arguments
error(nargchk(2, 3, nargin));

if ~ischar(pdcfname_l)
  error('First argument must be a string');
end

if fmt_l ~= 1 & fmt_l ~= 2
  error('Second argument must 1 or 2');
end

if nargin > 2
  if ~ischar(SaveFile)
    error('Third argument must be a string');
  end
else
  SaveFile = '';
end

% Open the file
[fid_l, msg_l] = fopen(pdcfname_l, 'r', 'b');
if fid_l < 0
  errmsg = ['Error opening ' pdcfname_l ...
            '.  Error message from MATLAB is "' msg_l '".'];
end

% Read first 12 bytes of header.
h_l = fread(fid_l, 12, 'uint8');

% Check first two bytes.
% First byte should be 0xAA = 170
% Second should be 0xCC = 204
if h_l(1) ~= 170 | h_l(2) ~= 204
  errmsg = ['Error reading ' pdcfname_l ', incorrect start characters'];
  fclose(fid_l); return;
end

% Check third byte.  This indicates file type
% Third byte == 01 ==> PDC phasor data recording
% Third byte == 04 ==> PPSM sample data recording
if h_l(3) ~= 1
  errmsg = ['Error reading ' pdcfname_l ', incorrect file type in header'];
  fclose(fid_l); return;
end

% Check fourth byte.  This indicates file version
% version == 1 ==> PDC phasor data recording, including Dbuf flag
% version == 2 ==> PDC phasor data recording, excluding Dbuf flag
version_l = h_l(4);
if version_l ~= 1 & version_l ~= 2
  errmsg = ['Error reading ' pdcfname_l ', incorrect version stamp in header'];
  fclose(fid_l); return;
end

% Read mnemonic representing recording unit (currently not used).
% ... = char(h(5:8));

% Read start time and start sample
h_l = fread(fid_l, 2, 'uint32');
StartTime = h_l(1); StartSample = h_l(2);

% Calculate sample rate
h_l=fread(fid_l, 2, 'uint16');
SampleRate = h_l(2)/h_l(1);

% Read next 5 long words.
h_l = fread(fid_l, 5, 'uint32');
nnbytesrow_l = 4 * h_l(1); % Number of bytes per row
nnrows_l = h_l(2);         % Number of rows in data section
trigtime_l = h_l(3);       % NTP time of disturbance trigger
trigsample_l = h_l(4);     % Sample number within time of det. trigger
pretrigrows_l = h_l(5);    % Number of rows before trigger

% Read PMU where trigger detected and trigger type
h_l = fread(fid_l, 2, 'uint16');
trigpmu_l = h_l(1); trigtype_l = h_l(2);

% Read 80-byte ASCII information.  Currently this is ignored
h_l = fread(fid_l, 80, 'uint8');

% Read number of PMUs
nnpmus_l = fread(fid_l, 1, 'uint32');

% Read the section containing PMU ID's and data offsets.
% Convert offsets to bytes
h_l = fread(fid_l, [4 2 * nnpmus_l], 'uint8');
pmunames_l = char(h_l(:, 1:2:end)');
offsets_l = 4 * bitor(bitshift(h_l(3, 2:2:end), 8), h_l(4, 2:2:end));

% Read and check end of header flag.
% First byte should be 0xAA = 170
% Second should be 0xCC = 204
h_l = fread(fid_l, 4, 'uint8');

if h_l(1) ~= 170 | h_l(2) ~= 204 | h_l(3) ~= 170 | h_l(4) ~= 204
  errmsg = ['Error reading ' pdcfname_l ', incorrect end of header'];
  fclose(fid_l); return;
end

% Format dependent variable names
if fmt_l == 1
  trigtime = trigtime_l;
  trigsample = trigsample_l;
  pretrigrows = pretrigrows_l;
  trigpmu = trigpmu_l;
  trigtype = trigtype_l;
  numpmus = nnpmus_l;
  rows = nnrows_l;
else
  PreTrigRows = pretrigrows_l;
  TrigPMU = trigpmu_l;
  TriggerType = trigtype_l;
  PMUnames = pmunames_l;
  NumRows = nnrows_l;
  Time = (0:nnrows_l - 1)' / SampleRate;
end

% Store the current file pointer position
datapos_l = ftell(fid_l);

% Read data from each PMU
for ii_l = 1:nnpmus_l

  % Set file pointer to first channel flag for this PMU
  fpos_l = datapos_l + offsets_l(ii_l);
  if version_l == 1; fpos_l = fpos_l + 4; end
  fseek(fid_l, fpos_l, 'bof');

  % Read channel flags, sample numbers, and status words
  h_l = fread(fid_l, [4 nnrows_l], '4*uint16', nnbytesrow_l - 8);

  % Determine number of phasors and number of digitals
  nnphasors_l  = bitand(h_l(2, 1), 255);
  nndigitals_l = bitshift(h_l(2, 1), -8);

  % Variables to save or assign in caller's workspace
  if fmt_l == 1

    % PMU number for variable names
    npmustr_l = sprintf('%02d', ii_l - 1);

    % Data valid flags
    eval(['DV' npmustr_l ' = bitshift(h_l(1, :), -15);']);

    % Sample numbers and status words
    eval(['smp' npmustr_l ' = h_l(3, :);']);
    eval(['stat' npmustr_l ' = h_l(4, :);']);

  else

    % Four character name for this PMU
    pmuname_l = pmunames_l(ii_l, :);

    % Data valid flags.
    eval([pmuname_l '_DV = bitshift(h_l(1, :), -15)'';']);

    % Sample numbers and status words
    eval([pmuname_l 'smp = h_l(3, :)'';']);
    eval([pmuname_l 'stat = h_l(4, :)'';']);

  end

  % Set file pointer to phasor and freq data for this PMU
  fseek(fid_l, fpos_l + 8, 'bof');

  % Read phasor and frequency data
  nnread_l = 2 * nnphasors_l + 2;
  h_l = fread(fid_l, [nnread_l nnrows_l], ...
       sprintf('%d*int16', nnread_l), ...
       nnbytesrow_l - 2 * nnread_l);

  % Form complex phasors
  if fmt_l == 1

    for jj_l = 0:nnphasors_l - 1
      ind_l = 2 * jj_l;
      eval(['pmu' npmustr_l 'phsr' sprintf('%02d', jj_l) ...
        ' = h_l(ind_l + 1, :) + sqrt(-1) * h_l(ind_l + 2, :);']);
    end

    % Read frequency and dfdt
    eval(['Freq' npmustr_l ' = h_l(nnread_l - 1, :);']);
    eval(['dfdt' npmustr_l ' = h_l(nnread_l, :);']);

  else

    ind_l = 1:2:(2 * nnphasors_l);

    eval([pmuname_l 'phsrs = ' ...
      'h_l(ind_l, :)'' + sqrt(-1) * h_l(ind_l + 1, :)'';']);

    % Read frequency and dfdt
    eval([pmuname_l 'freq = h_l(nnread_l - 1, :)'';']);
    eval([pmuname_l 'dfdt = h_l(nnread_l, :)'';']);

  end

  % Read PMU digitals
  if nndigitals_l > 0

    % Set file pointer to digital data for this PMU
    fseek(fid_l, fpos_l + 4 * nnphasors_l + 12, 'bof');

    % Read digitals
    h_l = fread(fid_l, [2 nnrows_l], sprintf('2*uint16', nnread_l), ...
      nnbytesrow_l - 4);

    if fmt_l == 1

      for jj_l = 0:nndigitals_l - 1
        eval(['pmu' npmustr_l 'dig' sprintf('%02d', jj_l) ...
          ' = h_l(jj_l + 1, :);']);
      end

    else

      eval([pmuname_l 'dgtls = h_l(nndigitals_l, :)'';']);

    end

  end

end

% Close the file
fclose(fid_l);

% Clear all variables not to be saved
MatFmt=fmt_l;
clear ans *_l

% Save to a file or assign in caller's workspace
if isempty(SaveFile)

  clear SaveFile
  varnames_l = who;

  for ii_l = 1:length(varnames_l)
    assignin('caller', varnames_l{ii_l}, eval(varnames_l{ii_l}));
  end

  if nargout > 1; varnames = varnames_l; end

else

  eval(['save ' SaveFile]);
  disp('In PDCread1: Translated data saved in file indicated below:')
  eval(['which ' SaveFile]);

  if nargout > 1; varnames = who; end

end

if nargout > 0; errmsg = ''; end

%end of PSM script
