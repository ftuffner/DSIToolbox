function [errmsg, varnames] = pdcread2(pdcfname_l, fmt_l, opts_l, VIcon_l, PMUtagsImp_l);

% PDCREAD2:  Phasor Data Concentrator, PDC, PMU
%
% Reads data from PDC binary file and stores variables in calling
% function workspace or a .mat file.  Supports MATLAB I, II, and the
% experimental MATLAB III format; others may be added later.
%
% Usage:
%
%   [errmsg, varnames] = pdcread2(pdcfname, fmt, opts);
%
% where
%
%   pdcfname = Name of binary PDC data file to read.
%
%   fmt      = Format in which to store data in workspace.
%              Set equal to 1 for MATLAB I format.
%              Set equal to 2 for MATLAB II format.
%              Set equal to 3 for MATLAB III format.
%
%   opts     = (Optional) Structure containing additional options.
%              Currently recognized fields are:
%
%              savefile = Name of file in which to store data.  If not
%                         present, data is saved to calling function
%                         workspace.
%
%              incdgtls = Include PMU/PDC digital data?
%                         incdgtls == 0 ==> No
%                         incdgtls ~= 0 ==> Yes
%
%   errmsg   = String containing text describing any errors
%              that occurred.
%
%   varnames = Cell array containing names of variables created
%              in workspace or file.

% Author:  Jeff M. Johnson, Battelle Pacific Northwest National Laboratory
% Date:  August 27, 1999
%

% PSMT utilities called from PDCread2:
%   Date2PSM
% 
% PSM time    = seconds starting at 1-Jan-1900
% Matlab time = days    starting at 1-Jan-0000
%
% Modified 12/09/05.  jfh  Partial fix for PMU names starting with numeric
% Modified 05/04/2006. zn. Skip the PMU readings according to the rms channel selection in VIcon(:, 7, :);

%
% Copyright (c) 1995-1999 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% Check number of input arguments

%---------------------------------------------------------------------
% Start: Modified by Ning Zhou on 05/04/2006 for skip PMU reading
%error(nargchk(2, 3, nargin));
error(nargchk(2, 5, nargin));
% End:  Modified by Ning Zhou on 05/04/2006 for skip PMU reading
%---------------------------------------------------------------------
if ~ischar(pdcfname_l)
  error('First argument must be a string');
end

if ~isequal(fmt_l, 1) & ~isequal(fmt_l, 2) & ~isequal(fmt_l, 3)
  error('Second argument must 1, 2, or 3');
end

% Default values for optional inputs
savefile = '';
incdgtls_l = 0;
%---------------------------------------------------------------------
% Start: Added by Ning Zhou on 05/04/2006 for skip PMU reading
if nargin <3, opts_l=[];end
if nargin <4, VIcon_l=[]; end
if nargin <5, PMUtagsImp_l=[]; end

%if nargin > 2
if ~isempty(opts_l)
% End:  Added by Ning Zhou on 05/04/2006 for skip PMU reading
%---------------------------------------------------------------------
  if isstruct(opts_l)
    if isfield(opts_l, 'savefile'); savefile = opts_l.savefile; end
    if isfield(opts_l, 'incdgtls'); incdgtls_l = opts_l.incdgtls; end
  else
    error('Third argument must be a structure');
  end
end

if ~ischar(savefile)
  error('Savefile field of ''opts'' input must be a string');
end

if ~isa(incdgtls_l, 'double')
  error('Incdgtls field of ''opts'' input must be a double');
else
  incdgtls_l = incdgtls_l(1);
end

% Allocate second output argument
if nargout > 1; varnames=cell(0); end

% Open the file
[fid_l, msg_l] = fopen(pdcfname_l, 'r', 'b');
if fid_l < 0
  errmsg = ['Error opening ' pdcfname_l ...
            ': Error message from MATLAB is "' msg_l '".'];
  return;
end

% Read first 12 bytes of header.
h_l = fread(fid_l, 12, 'uint8');

% Check first two bytes.
% First byte should be 0xAA = 170
% Second should be 0xCC = 204
if h_l(1) ~= 170 | h_l(2) ~= 204
  errmsg = ['Error reading ' pdcfname_l ': Incorrect start characters in header'];
  disp(['In PDCread2: ' errmsg])
  disp('First 12 bytes of file header are'); disp(h_l)
  fclose(fid_l); return;
end

% Check third byte.  This indicates file type
% Third byte == 01 ==> PDC phasor data recording #1
% Third byte == 02 ==> PDC phasor data recording #2
% Third byte == 04 ==> PPSM sample data recording

%disp('In PDCread2: Keyboard'); keyboard
PMUorder='';

FheadType=h_l(3);
%if ~(FheadType==1|FheadType==2)
if ~(FheadType==1|FheadType==2|FheadType==3)
  errmsg = ['Error reading ' pdcfname_l ': Incorrect file type in header'];
  disp(['In PDCread2: ' errmsg])
  disp('First 12 bytes of file header are'); disp(h_l)
  fclose(fid_l); return;
end

% Check fourth byte.  This indicates file version
% version == 1 ==> PDC phasor data recording, including Dbuf flag
% version == 2 ==> PDC phasor data recording, excluding Dbuf flag
version_l = h_l(4);
if ~(version_l==1|version_l==2)
  errmsg = ['Error reading ' pdcfname_l ': Incorrect version stamp in header'];
  disp(['In PDCread2: ' errmsg])
  disp('First 12 bytes of file header are'); disp(h_l)
  fclose(fid_l); return;
end

% Read mnemonic representing recording unit (currently not used).
% ... = char(h(5:8));

% Read start time and start sample
h_l = fread(fid_l, 2, 'uint32');
starttime_l = h_l(1);
startsample_l = h_l(2);
if FheadType==2
  starttime_l=starttime_l+Date2PSM('01-Jan-1970 00:00:00.000'); 
end

% Calculate sample rate
h_l=fread(fid_l, 2, 'uint16');
SampleRate = h_l(2)/h_l(1);

% Read next 5 long words.
h_l = fread(fid_l, 5, 'uint32');
nnbytesrow_l = 4 * h_l(1); % Number of bytes per row
nnrows_l = h_l(2);         % Number of rows in data section
trigtime_l = h_l(3);       % NTP time of disturbance trigger
trigsample_l = h_l(4);     % Sample number within time of det. trigger
PreTrigRows = h_l(5);      % Number of rows before trigger

% Read PMU/PDC where trigger detected and trigger type
h_l = fread(fid_l, 2, 'uint16');
TrigPMU = h_l(1);
trigtype_l = h_l(2);

% Read 80-byte ASCII information.  Currently this is ignored
h_l = fread(fid_l, 80, 'uint8');

% Read number of PMU and PDC cells per row
nncellsperrow_l = fread(fid_l, 1, 'uint32');

% Read the section containing PMU ID's and data offsets.
% Convert offsets to bytes
h_l = fread(fid_l, [4 2 * nncellsperrow_l], 'uint8');
pmupdcnames_l = char(h_l(:, 1:2:end)');
offsets_l = 4 * bitor(bitshift(h_l(3, 2:2:end), 8), h_l(4, 2:2:end));

% Read and check end of header flag.
% First byte should be 0xAA = 170
% Second should be 0xCC = 204
h_l = fread(fid_l, 4, 'uint8');

if h_l(1) ~= 170 | h_l(2) ~= 204 | h_l(3) ~= 170 | h_l(4) ~= 204
  errmsg = ['Error reading ' pdcfname_l ', incorrect end of header flag.'];
  fclose(fid_l); return;
end

% Format dependent variable names
if fmt_l == 1
  TrigTime = trigtime_l;
  TrigSample = trigsample_l;
  TrigType = trigtype_l;
  NumPMUs = nncellsperrow_l;
  Rows = nnrows_l;
elseif fmt_l == 2 | fmt_l == 3
  PMUNames = pmupdcnames_l;
  NumRows = nnrows_l;
  StartTime = starttime_l;
  StartSample = startsample_l;
  TriggerType = trigtype_l;
  Time = (0:nnrows_l - 1)' / SampleRate;
end

% Store the current file pointer position
datapos_l = ftell(fid_l);

%---------------------------------------------------------------------
% Start: Added by Ning Zhou on 05/04/2006 for skip PMU reading
NPMUs_l=size(VIcon_l,3);
% End:  Added by Ning Zhou on 05/04/2006 for skip PMU reading
%---------------------------------------------------------------------
    
%********************* Start of RowRead Logic *************************
% Read data from each cell

for ii_l = 1:nncellsperrow_l
    %---------------------------------------------------------------------
    % Start: Added by Ning Zhou on 05/04/2006 for skip PMU reading
%    if ~isempty(VIcon_l)
%         if sum(VIcon_l(:,7,ii_l))==0      
%            continue;
%        end
%    end
    
    if ~isempty(VIcon_l)
        sigsnameG_dst_l=deblank(pmupdcnames_l(ii_l, :));
        tagtest_l=0;        % whether this PMU needs to be extracted.
        for K_l=1:NPMUs_l
            if sum(VIcon_l(:,7,K_l))==0      
                continue;
            end
            sigsnameG_ini_l=deblank(PMUtagsImp_l(K_l,:));
            tagtest_l=strcmp(sigsnameG_ini_l, sigsnameG_dst_l);
            if tagtest_l
                break;
            end
        end

        if ~tagtest_l
            continue;
        end
    end
    % End:  Added by Ning Zhou on 05/04/2006 for skip PMU reading
    %---------------------------------------------------------------------
    
  % Set file pointer to first sample for this cell
  fpos_l = datapos_l + offsets_l(ii_l);
  fseek(fid_l, fpos_l, 'bof');

  % Read DBUF and channel flags
  if version_l == 1
    h_l = fread(fid_l, [2 nnrows_l], '2*uint32', nnbytesrow_l - 8);
    dbuf_l = [bitshift(h_l(1, :), -16); bitand(h_l(1, :), 65535)];
    chanflg_l = h_l(2, :);
    fpos_l = fpos_l + 4;
  else
    h_l = fread(fid_l, [1 nnrows_l], 'uint32', nnbytesrow_l - 4);
    chanflg_l = h_l(1, :);
  end

  % Determine if cell contains PMU or PDC format data
  pdcfmt_l = bitget(chanflg_l(1), 27);

  % Variables to save or assign in caller's workspace
  if fmt_l == 1
    % PMU/PDC number for variable names
    npmupdcstr_l = sprintf('%02d', ii_l - 1);
    % Data valid vectors
    eval(['DV' npmupdcstr_l ' = bitget(chanflg_l, 32) == 0;']);
  else
    % Four character name for this PMU/PDC
    pmupdcname_l = deblank(pmupdcnames_l(ii_l, :));
    CkTag=pmupdcname_l(1);
    if ~isempty(findstr(CkTag,'1234567890'))
      NewTag='P'; %may have to extend this for multiple hits
      str1=['In pdcread2: Naming problem for PMU ' pmupdcname_l];  
      str2=['Name starts with ' CkTag ];
      str3=['Changing name to ' NewTag pmupdcname_l];
      disp(str2mat(str1,str2,str3))
      pmupdcname_l=[NewTag pmupdcname_l];
    end
    if ~pdcfmt_l
      disp(['  In pdcread2: Processing ' pmupdcname_l])
      
     %if ii_l==1,       
     if isempty(PMUorder)       % changed by ZN (05/05/2006)
        PMUorder=pmupdcname_l;
      else 
        PMUorder=str2mat(PMUorder,pmupdcname_l);
      end
    end
    % Interactive diagnostic
    CkPMU=''; %CkPMU='AULT';
    if ~isempty(CkPMU)
      if findstr(CkPMU,pmupdcname_l)
        disp(['  In pdcread2: Keyboard for interactive diagnosis of PMU with name ' CkPMU])
        keyboard
     end
    end

    % DBUF and channel flag vectors [debug]
    if fmt_l==2
      if version_l == 1, eval([pmupdcname_l 'DBUF = dbuf_l' ';']); end
      eval([pmupdcname_l 'chanflag = chanflg_l' ';']);
    elseif fmt_l==3
      if pdcfmt_l; pdcst_l.name = pmupdcname_l; else; pdcst_l.name = ''; end
      if version_l==1; pdcst_l.dbuf=dbuf_l'; end
      pdcst_l.chanflag = chanflg_l';
    end
  end

  if pdcfmt_l
    % Read number of PMU data blocks
    nnpmus_l=bitand(chanflg_l(1),255);
    % Number of words to read per cell (minus DBUF and channel flag)
    nnreadcell_l=8*nnpmus_l;
  else
    % Read number of phasors and number of digitals
    nnphasors_l =bitand(chanflg_l(1),255);
    nndigitals_l=bitand(bitshift(chanflg_l(1),-8),255);
    nnpmus_l=1;
    % Number of words to read per cell (minus DBUF and channel flag)
    nnreadcell_l=2*nnphasors_l+2*(nndigitals_l>0)+4;
  end

  % Position the file pointer past the channel flag in the first row
  fseek(fid_l,fpos_l+4,'bof');

  % Read remaining cell quantities from all rows
  try
    h_l=fread(fid_l,[nnreadcell_l nnrows_l], ...
          sprintf('%d*int16',nnreadcell_l), ...
          nnbytesrow_l-2*nnreadcell_l);
  catch
    disp(['  In pdcread2: BREAK--bad data for PMU with name ' pmupdcname_l])
    break
    %disp('Here is the keyboard -- enter RETURN when you are done')
    %keyboard
  end

  % Allocate cell arrays to contruct structure array for format III
  if fmt_l == 3
    pmunamecell_l =cell(nnpmus_l, 1);
    chanflgcell_l =pmunamecell_l;
    samplecell_l  =pmunamecell_l;
    statuscell_l  =pmunamecell_l;
    phasorscell_l =pmunamecell_l;
    freqcell_l    =pmunamecell_l;
    dfdtcell_l    =pmunamecell_l;
    digitalscell_l=pmunamecell_l;
  end

  % Extract variables to save or assign in caller's workspace
  if pdcfmt_l  % PDC data cell

    % Row offset to data from first PMU in matrix read above
    ind1_l = 0;

    % Phasor counter for format I
    kk_l = 0;

    for jj_l = 1:nnpmus_l
      % Variable or field name for current PMU
      if fmt_l == 1
        npmustr_l = sprintf('%02d', jj_l - 1);
      else
        pmuname_l = sprintf('pmu%d', jj_l - 1);
      end

      % PMU channel flags, status words, and digitals.
      % Convert to unsigned integers
      h2_l = h_l(ind1_l + [1 2 8], :);
      ind2_l = logical(h2_l < 0);
      h2_l(ind2_l) = h2_l(ind2_l) + 65536;
      if fmt_l == 1
        eval(['pmu' npmupdcstr_l 'DV' npmustr_l ' = bitget(h2_l(1, :), 16) == 0;']);
        eval(['pmu' npmupdcstr_l 'stat' npmustr_l ' = h2_l(2, :);']);
        if incdgtls_l; eval(['pmu' npmupdcstr_l 'dig' npmustr_l ' = h2_l(3, :);']); end
      elseif fmt_l == 2
        disp(['  In pdcread2: Processing ' pmupdcname_l pmuname_l])
        PMUorder=str2mat(PMUorder,[pmupdcname_l pmuname_l]);
        eval([pmupdcname_l pmuname_l 'chanflag = h2_l(1, :)'';']);
        eval([pmupdcname_l pmuname_l 'status = h2_l(2, :)'';']);
        if incdgtls_l; eval([pmupdcname_l pmuname_l 'dgtls = h2_l(3, :)'';']); end
      elseif fmt_l == 3
        pmunamecell_l{jj_l} = pmuname_l;
        chanflgcell_l{jj_l} = h2_l(1, :)';
        samplecell_l{jj_l} = [];
        statuscell_l{jj_l} = h2_l(2, :)';
        if incdgtls_l; digitalscell_l{jj_l} = h2_l(3, :)'; end
      end

      % Phasors and frequency
      h2_l = h_l(ind1_l + [3 5], :) + sqrt(-1) * h_l(ind1_l + [4 6], :);
      if fmt_l == 1
        eval(['pmu' npmupdcstr_l 'phsr' sprintf('%02d', kk_l) ' = h2_l(1, :);']);
        kk_l = kk_l + 1;
        eval(['pmu' npmupdcstr_l 'phsr' sprintf('%02d', kk_l) ' = h2_l(2, :);']);
        kk_l = kk_l + 1;
        eval(['pmu' npmupdcstr_l 'freq' npmustr_l ' = h_l(ind1_l + 7, :);']);
      elseif fmt_l == 2
        eval([pmupdcname_l pmuname_l 'phsrs = h2_l.'';']);
        eval([pmupdcname_l pmuname_l 'freq = h_l(ind1_l + 7, :)'';']);
      elseif fmt_l == 3
        phasorscell_l{jj_l} = h2_l.';
        freqcell_l{jj_l} = h_l(ind1_l + 7, :)';
        dfdtcell_l{jj_l} = [];
      end
      % Offset to data for next PMU
      ind1_l = ind1_l + 8;
    end

  else  % PMU data cell

    % PMU sample numbers and status words
    % Convert to unsigned integers
    h2_l = h_l([1 2], :);
    ind2_l = logical(h2_l < 0);
    h2_l(ind2_l) = h2_l(ind2_l) + 65536;

    if fmt_l == 1
      eval(['smp' npmupdcstr_l ' = h2_l(1, :);']);
      eval(['stat' npmupdcstr_l ' = h2_l(2, :);']);
    elseif fmt_l == 2
      eval([pmupdcname_l 'sample = h2_l(1, :)'';']);
      eval([pmupdcname_l 'status = h2_l(2, :)'';']);
    elseif fmt_l == 3
      pmunamecell_l{1} = pmupdcname_l;
      samplecell_l{1} = h2_l(1, :)';
      statuscell_l{1} = h2_l(2, :)';
    end

    % Phasors
    ind1_l = 2 * (0:nnphasors_l - 1);
    h2_l = h_l(ind1_l + 3, :) + sqrt(-1) * h_l(ind1_l + 4, :);
    if fmt_l == 1
      for jj_l = 1:nnphasors_l
        eval(['pmu' npmupdcstr_l 'phsr' sprintf('%02d', jj_l - 1) ...
          ' = h2_l(jj_l, :);']);
      end
    elseif fmt_l == 2
      eval([pmupdcname_l 'phsrs = h2_l.'';']);
    elseif fmt_l == 3
      phasorscell_l{1} = h2_l.';
    end

    % Frequency and df/dt
    ind1_l = 2 * nnphasors_l + 3;
    if fmt_l == 1
      eval(['freq' npmupdcstr_l ' = h_l(ind1_l, :);']);
      eval(['dfdt' npmupdcstr_l ' = h_l(ind1_l + 1, :);']);
    elseif fmt_l == 2
      eval([pmupdcname_l 'freq = h_l(ind1_l, :)'';']);
      eval([pmupdcname_l 'dfdt = h_l(ind1_l + 1, :)'';']);
    elseif fmt_l == 3
      freqcell_l{1} = h_l(ind1_l, :)';
      dfdtcell_l{1} = h_l(ind1_l + 1, :)';
    end

    % Digitals
    if incdgtls_l & (nndigitals_l > 0)
      % Offset to digitals
      ind1_l = ind1_l + 2 + (0:nndigitals_l - 1);
      % Convert to unsigned integers
      h2_l = h_l(ind1_l, :);
      ind2_l = logical(h2_l < 0);
      h2_l(ind2_l) = h2_l(ind2_l) + 65536;
      if fmt_l == 1
        for jj_l = 1:nndigitals_l
          eval(['pmu' npmupdcstr_l 'dig' sprintf('%02d', jj_l - 1) ...
            ' = h2_l(:, jj_l)'';'])
        end
      elseif fmt_l == 2
        eval([pmupdcname_l 'dgtls = h2_l'';']);
      elseif fmt_l == 3
        digitalscell_l = h2_l';
      end
    end
  end

  % Complete PDC structure for format III
  if fmt_l == 3
    pdcst_l.pmus = struct('pmuname', pmunamecell_l, 'chanflag', chanflgcell_l, ...
      'sample', samplecell_l, 'status', statuscell_l, 'phsrs', phasorscell_l, ...
      'freq', freqcell_l, 'dfdt', dfdtcell_l, 'dgtls', digitalscell_l);
    eval([pmupdcname_l '_pmupdc = pdcst_l;']);
  end

end
%********************* End of RowRead Logic *************************

% Close the file
fclose(fid_l);

% Clear all variables not to be saved
MatFmt=fmt_l;
clear ans varnames *_l

% Save to a file or assign in caller's workspace
if isempty(savefile)
  clear savefile
  varnames_l = who;
  for ii_l = 1:length(varnames_l)
    assignin('caller', varnames_l{ii_l}, eval(varnames_l{ii_l}));
  end
  if nargout > 1; varnames = varnames_l; end
else
  % Prevent savefile variable from being saved in translated data file
  filenamesave(savefile);
  clear savefile
  eval(['save ' filenamesave]);
  % Write path to translated file to stdout
  disp('In PDCread2:  Translated data saved in file indicated below:')
  if exist(filenamesave) == 2
    eval(['which ' filenamesave]);
  elseif exist([filenamesave '.mat']) == 2
    eval(['which ' filenamesave '.mat']);
  end
  if nargout > 1; varnames = who; end
end

if nargout > 0; errmsg = ''; end

disp('  In pdcread2: Processing done')
disp(' ')


%=============================================================================
function name_out = filenamesave(name_in);

% Stores the save file name for pdcread2 in a variable outside of the pdcread2
% workspace to prevent this name from being saved in translated data files.

persistent name_save

if nargin>0; name_save = name_in; end
if nargout>0; name_out = name_save; end

%end of PSM script