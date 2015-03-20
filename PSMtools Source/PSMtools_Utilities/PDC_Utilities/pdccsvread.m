function [errmsg, varnames] = pdccsvread(pdcfname_l, fmt_l, opts_l);

% pdccsvread:  Phasor Data Concentrator, for AEP PDC CSV format
%
% Reads data from PDC CSV data file and stores variables in calling
% function workspace or a .mat file.  Supports MATLAB I, II, and the
% experimental MATLAB III format; others may be added later.
%
% Usage:
%
%   [errmsg, varnames] = pdccsvread(pdcfname, fmt, opts);
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

% Author:  Henry Huang, Battelle Pacific Northwest National Laboratory
%                based on pdcread2.m by Jeff M. Johnson, Battelle Pacific Northwest National Laboratory
% Date:  July 22, 2005
%

% PSMT utilities called from pdccsvread:
%   Date2PSM
% 
% PSM time    = seconds starting at 1-Jan-1900
% Matlab time = days    starting at 1-Jan-0000
%
% Last modified 08/04/05.  Henry Huang. 

%
% Copyright (c) 1995-1999 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% Check number of input arguments
error(nargchk(2, 3, nargin));

if ~ischar(pdcfname_l)
  error('First argument must be a string');
end

if ~isequal(fmt_l, 1) & ~isequal(fmt_l, 2) & ~isequal(fmt_l, 3)
  error('Second argument must 1, 2, or 3');
end

% Default values for optional inputs
savefile = '';
incdgtls_l = 0;

if nargin > 2
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

errmsg = '';

%-----------------------------------------------
% PDC CSV read logic based on codes provided by Sanjoy K. Sarawgi (AEP)
%-----------------------------------------------

if exist(pdcfname_l,'file')
    rawData_l = csvread(pdcfname_l,1,2);
else
    errmsg = ['Error opening ' pdcfname_l ': file not exist!!!']
    disp(['In pdccsvread: ' errmsg])
end
disp(['In pdccsvread: PDC CSV data read from file <' pdcfname_l '>']);

[nRows_l,nCols_l]=size(rawData_l)     
StartTime = rawData_l(1,1)/60;
SampleRate = 1/((rawData_l(2,1) - rawData_l(1,1))*1/60)
SampleRate_vec_l = 1./((rawData_l(2:end,1) - rawData_l(1:end-1,1))*1/60);
StartSample = 0; 

%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% The following code segment adjusts the start time of PMU data recording
% from GMT to local time (EDT/EST). Needs the file 'isdst.m'.
% Note: If plot is zoomed in/out manually 'xlab' need to be changed
% accordingly. Added by Sanjoy K. Sarawgi

if 0        % disabled as suggested by Sanjoy (AEP). Henry Huang (PNNL), 2005-08-04

% get time stamps and calculate time vector
disp('In pdccsvread: Converting timestamps to local time (EDT or EST)...');
matlabDates_l = datenum('1-Jan-1900')+rawData_l(:,1)/(24*60*60*60);
[YY_l,MO_l,DD_l,HH_l,MM_l,SS_l] = datevec(matlabDates_l);
t0_l = HH_l(1)*3600 + MM_l(1)*60 + SS_l(1);          
t_l = HH_l*3600 + MM_l*60 + SS_l - t0_l;         % get time in seconds
index_l = find(t_l < 0);
if (~isempty(index_l))   %    disp('In pdccsvread: Correcting Negative Timestamps');
    t_l(index_l) = t_l(index_l) + 24*3600;
end
isdst_start_l = isdst(matlabDates_l(1),YY_l(1),MO_l(1),DD_l(1),HH_l(1));
isdst_end_l = isdst(matlabDates_l(end),YY_l(end),MO_l(end),DD_l(end),HH_l(end));

if (isdst_start_l && isdst_end_l)   %    disp('All EDT');
    HH_l = HH_l - 4;
elseif (isdst_start_l == 0 && isdst_end_l == 0)     %    disp('All EST');
    HH_l = HH_l - 5;
elseif (isdst_start_l == 0 && isdst_end_l == 1)     %    disp('From EST to EDT');
    DW_l = weekday(matlabDates_l) - 1;
    id_l = intersect(intersect(intersect(find(MO_l==4),find(DD_l<=7)),find(DW_l == 0)),find(HH_l >= 7));
    index_l = min(id_l);
    HH_l(1:index_l-1) = HH_l(1:index_l-1) - 5;
    HH_l(index_l:end) = HH_l(index_l:end) - 4;
elseif (isdst_start_l == 1 && isdst_end_l == 0)     %    disp('From EDT to EST');
    DW_l = weekday(matlabDates_l) - 1;
    id_l = intersect(intersect(intersect(find(MO_l==10),find(DD_l>=25)),find(DW_l == 0)),find(HH_l >= 6));
    index_l = min(id_l)
    HH_l(1:index_l-1) = HH(1:index_l-1) - 4;
    HH_l(index_l:end) = HH(index_l:end) - 5;
end

index_l = find(HH_l < 0);
HH_l(index_l)=24 + HH_l(index_l);
DD_l(index_l)=DD_l(index_l) - 1;

end     %if 0        % disabled as suggested by Sanjoy (AEP). Henry Huang (PNNL), 2005-08-04


%*******************************************
%*    ad hoc codes, need to be revised
%*******************************************

% get real and imaginary  values
R_l  = rawData_l(1:nRows_l,[3:2:11,18:2:26,33:2:41,48:2:56,63:2:73]);
I_l  = rawData_l(1:nRows_l,[4:2:12,19:2:27,34:2:42,49:2:57,64:2:74]);

% construct complex I/V vectors
AllPhsrs_l = R_l + sqrt(-1)*I_l;
AllFreqs_l = rawData_l(1:nRows_l,[16,31,46,61,78])/1e3+60;

PMUorder = ['ROCK'; 'KNRV'; 'JFRY'; 'MTFK'; 'ORNG'];

ROCKphsrs = AllPhsrs_l(:,[4 5 1:3]);
ROCKfreq = AllFreqs_l(:,1);

KNRVphsrs = AllPhsrs_l(:,[9 10 6:8]); 
KNRVfreq = AllFreqs_l(:,2);     

JFRYphsrs = AllPhsrs_l(:,[14 15 11:13]); 
JFRYfreq = AllFreqs_l(:,3);     

MTFKphsrs = AllPhsrs_l(:,[19 20 16:18]); 
MTFKfreq = AllFreqs_l(:,4);     

ORNGphsrs = AllPhsrs_l(:,21:26);  
ORNGfreq = AllFreqs_l(:,5);

% PMU status flags
ROCKchanflag = rawData_l(1:nRows_l,13);
KNRVchanflag = rawData_l(1:nRows_l,28);
JFRYchanflag = rawData_l(1:nRows_l,43);
MTFKchanflag = rawData_l(1:nRows_l,58);
ORNGchanflag = rawData_l(1:nRows_l,75);

%*******************************************
%*    end. ad hoc codes, need to be revised
%*******************************************


%********************* End of RowRead Logic *************************

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
  disp('In pdccsvread:  Translated data saved in file indicated below:')
  if exist(filenamesave) == 2
    eval(['which ' filenamesave]);
  elseif exist([filenamesave '.mat']) == 2
    eval(['which ' filenamesave '.mat']);
  end
  if nargout > 1; varnames = who; end
end

if nargout > 0; errmsg = ''; end

disp('  In pdccsvread: Processing done')
disp(' ')


%=============================================================================
function name_out = filenamesave(name_in);

% Stores the save file name for pdccsvread in a variable outside of the pdccsvread
% workspace to prevent this name from being saved in translated data files.

persistent name_save

if nargin>0; name_save = name_in; end
if nargout>0; name_out = name_save; end

%end of PSM script