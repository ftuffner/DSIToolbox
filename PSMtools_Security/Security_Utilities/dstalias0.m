function [newdstfiles,errmsg]=dstalias0(dstpath,dstfiles,inifile,newdstpath,opts)

% DSTALIAS0:  PDC, PMU, DST
%
% Copies a series of phasor data files (produced by a Bonneville Power
% Administration phasor data concentrator (PDC)) to a new directory.  Scans
% the new files and replaces data in certain header fields with new values.
%
% Currently, the fields processed are the file source ID, ASCII info,
% and PMU ID's.  The INI file must specify new values for source and PMU
% ID's.  ASCII info will be replaced with a series of spaces (20h).
%
% This function was written as a first attempt to conceal recording unit
% and PMU ID information in PDC-generated phasor data files.  If further
% data security is required, it is recommend that file encryption
% techniques be studied and deployed.
%
% Usage
%
%   [newdstfiles,errmsg]=dstalias0(dstpath,dstfiles,inifile,newdstpath,opts)
%
% where
%
%   dstpath     = Directory containing files to process.
%
%   dstfiles    = Character array containing names of files to process.
%                 Set dstfiles=[] to process all files in dstpath.
%
%   inifile     = Path to INI file for use with dstfiles.  INI file must
%                 contain new source and PMU ID names.
%
%   newdstpath  = Directory in which to store processed files.
%
%   opts        = Structure containng additional options.  Currently
%                 recognized fields are
%
%                 verbose = Flag to print/surpress diagnostic information.
%                           Set verbose=1 to print information.
%
%   newdstfiles = Character array containing of new processed files.
%
%   errmsg      = Character array containing error message.  If empty,
%                 function executed successfully.

% By Jeff M. Johnson, Pacific Northwest National Laboratory
% Date:  June 3, 2003
%
% Date of last source code modification:  06/23/2003 (JFH)

% Initialize outputs
newdstfiles=''; errmsg='';

try

% Check input arguments
  error(nargchk(4,5,nargin));

  if nargin<5; opts=struct([]); end
  if isfield(opts,'verbose'); verbose=opts.verbose; else; verbose=0; end

  fs=filesep;

  if ~isempty(dstpath) & ~isequal(dstpath(end),fs)
    dstpath=[dstpath fs];
  end

  if isempty(dstfiles)
    d=dir([dstpath '*.dst']); dstfiles=char(d(~[d.isdir]).name);
    if isempty(dstfiles); return; end
  end

  if exist(inifile,'file')~=2; inifile=[dstpath inifile]; end

  if isempty(newdstpath) % Add ability to create newdstpath later
    error('Input ''newdstpath'' specifies a nonexistent directory');
  elseif ~isequal(newdstpath(end),fs)
    newdstpath=[newdstpath fs];
  end

% Read source and PMU ID info from INI file
  if verbose; fprintf(1,'Reading INI file ''%s''\n',inifile); end
  [sourceIDini,pmuIDini]=getIDinfoINI(inifile);
  nnPMUmx=size(pmuIDini.old,1);

% Loop to process files
  if verbose; fprintf(1,'In DSTalias0: Processing DST files in ''%s''\n',dstpath); end

  for ii=1:size(dstfiles,1)

    if verbose; fprintf(1,'In DSTalias0: Processing DST file ''%s'' ',dstfiles(ii,:)); end

  % Full path to dstfile
    dstfile=[dstpath deblank0(dstfiles(ii,:))];

  % Read source and PMU ID info from DST file
    [sourceIDdst,pmuIDdst]=getIDinfoDST(dstfile,nnPMUmx);
    if verbose
      locs=[1:3]+~isempty(findstr('_',sourceIDini.old(1)));
      sourceIDiniS=sourceIDini.old(locs);
      %Compare first 3 characters, ignore leading underbar
      if ~strcmp(sourceIDdst(1:3),sourceIDiniS)
        disp(sprintf(['\nIn DSTalias0: WARNING - \n' ...
          'Source ID in DST differs from that of INI file.\n' ...
          'In DST file     , SourceID = %s\nIn INI file name, SourceID = %s'] ...
          ,sourceIDdst,sourceIDini.old));
      end
      fprintf(1,'.');
    end
    sourceIDdst=sourceIDini.new;

  % Replace PMU ID's with alias ID's
    for ii=1:size(pmuIDdst,1)
      ind=strmatch(pmuIDdst(ii,:),pmuIDini.old);
      if isempty(ind)
        error(sprintf('Missing alias ID for PMU ''%s''',pmuIDdst(ii,:)));
      end
      pmuIDdst(ii,:)=pmuIDini.new(ind(1),:);
    end
    if verbose; fprintf(1,'.'); end

  % Full path to new DST file
    [p,n,e]=fileparts(dstfile);
    if length(n)<4
      error('Unable to replace source ID in DST file name');
    end
    n(1:4)=sourceIDini.new; newfile=[n e]; newdstfile=[newdstpath newfile];

  % Copy DST file to new directory
    [s,msg]=copyfile(dstfile,newdstfile);
    if ~s
      error(sprintf('Error copying DST file to path ''%s''',newdstpath));
    end
    if verbose; fprintf(1,'.'); end

  % Set source and PMU ID info in new DST file
    setIDinfoDST(newdstfile,sourceIDdst,pmuIDdst);
    if verbose; fprintf(1,'.\n'); end

  % Update 'newdstfiles' output
    if nargout>0; newdstfiles=strvcat(newdstfiles,newfile); end

  end

catch

  if exist('newdstfile','var')==1
    if exist(newdstfile,'file')==2; delete(newdstfile); end
  end

  if nargout>1; errmsg=lasterr; else; error(lasterr); end

end

%=========================================================================
function [sourceID,pmuID]=getIDinfoINI(inifile)

% Reads source and PMU ID info from a specified INI file.
% Helper function for dstalias0.m.

% Initialize outputs
  [p,n]=fileparts(inifile);
  if length(n)<4; error('Bad INI file name, no station name found'); end
  sourceID.old=n(1:4); sourceID.new=''; pmuID.old=''; pmuID.new='';

  try

  % Open the file for reading
    [fid,msg]=fopen(inifile,'rt');
    if fid<0; error(sprintf('Error opening INI file:  %s',msg)); end

  % Search for AliasSource ID key in [CONFIG] section
    found=0; keyword='[CONFIG]'; lkeyword=length(keyword);
    while 1
      lin=fgets(fid); if ischar(lin); lin=deblank0(lin); else; break; end
      if strncmp(lin,keyword,lkeyword); found=1; break; end
    end
    if ~found; error('Error locating [CONFIG] section in INI file'); end

    found=0; key='AliasSourceID'; lkey=length(key);
    while 1
      lin=fgets(fid); if ischar(lin); lin=deblank0(lin); else; break; end
      if strncmp(lin,'[',1); break; end
      if strncmp(lin,key,lkey)
        val=readkeyval(lin);
        if length(val)==4; sourceID.new=val; found=1; end
        break;
      end
    end
    if ~found; error('Error reading ''%s'' key from INI file',key); end

  % Re-position file pointer to beginning of file
    if fseek(fid,0,-1)<0; error('Error accessing INI file'); end

  % Search for AliasID keys in PMU info sections
    key0='AliasID'; lkey0=length(key0);
    key1='PMU'; lkey1=length(key1);
    key2='PDC'; lkey2=length(key2);
    found=0; pmuIDold=''; pmuIDnew='';
    while 1
      lin=fgets(fid); if ischar(lin); lin=deblank0(lin); else; break; end
      if strncmp(lin,'[',1)
        if length(lin)==6 & strcmp(lin(6),']')
          pmuIDold=lin(2:5);
        elseif length(lin)==10 & strcmp(lin(6:8),'pmu') & strcmp(lin(10),']')
          pmuIDold=lin(2:5);
        else
          found=0; pmuIDold=''; pmuIDnew='';
        end
      elseif strncmp(lin,key0,lkey0)
        pmuIDnew=readkeyval(lin);
        if length(pmuIDnew)==8; pmuIDnew=pmuIDnew(1:4); end
        if length(pmuIDnew)~=4; found=0; pmuIDold=''; pmuIDnew=''; end
      elseif strncmp(lin,key1,lkey1) | strncmp(lin,key2,lkey2)
        found=1;
      end
      if found & ~isempty(pmuIDold) & ~isempty(pmuIDnew)
        pmuID.old=char(pmuID.old,pmuIDold);
        pmuID.new=char(pmuID.new,pmuIDnew);
        found=0; pmuIDold=''; pmuIDnew='';
      end
    end

    fclose(fid);

  catch

    if exist('fid','var')==1
      if ~isempty(fopen(fid)); fclose(fid); end
    end
    error(lasterr);

  end

%=========================================================================
function [sourceID,pmuID]=getIDinfoDST(dstfile,nnPMUmx)

% Reads source and PMU ID info from a specified DST file.
% Helper function for dstalias0.m.

% Initialize outputs
  sourceID=''; pmuID='';

  try

  % Open the file for reading
    [fid,msg]=fopen(dstfile,'r','b');
    if fid<0; error(sprintf('Error opening DST file:  %s',msg)); end

  % Check first two header bytes (Note:  AACCh = 43724d)
    [hdr,count]=fread(fid,2,'uint16');
    if count~=2; error('Error reading DST file header'); end
    if hdr(1)~=43724; error('Bad data at beginning of file header'); end

  % Read file sourceID
    [srcID,count]=fread(fid,4,'uint8');
    if count~=4; error('Error reading Source ID from file header'); end
    sourceID=char(srcID');

  % Read number of PMUs
    if fseek(fid,128,-1)<0; error('Error accessing DST file'); end
    [nnPMU,count]=fread(fid,1,'uint32');
    if count~=1; error('Error reading NumPMUs from file header'); end
    if nnPMU>nnPMUmx
      error('DST file header indicates more PMU/PDC''s than in INI file.');
    end

  % Read pmuIDs
    nnread=4*nnPMU; [pmID,count]=fread(fid,nnread,'4*uint8',4);
    if count~=nnread; error('Error reading PMU IDs from file header'); end
    pmuID=zeros(4,nnPMU); pmuID(:)=pmID; pmuID=char(pmuID');

  % Check end of header bytes
    [hdr,count]=fread(fid,2,'uint16');
    if count~=2; error('Error reading DST file header'); end
    if any(hdr~=43724); error('Bad data at end of file header'); end

    fclose(fid);

  catch

    if exist('fid','var')==1
      if ~isempty(fopen(fid)); fclose(fid); end
    end
    error(lasterr);

  end

%=========================================================================
function setIDinfoDST(dstfile,sourceIDdst,pmuIDdst)

% Writes new source and PMU ID info to a specified DST file.
% Also replaces ASCII information field with blanks.
% Helper function for dstalias0.m.

  try

  % Open the file for reading
    [fid,msg]=fopen(dstfile,'r+','b');
    if fid<0; error(sprintf('Error opening new DST file:  %s',msg)); end

  % Write the new file source ID
    if fseek(fid,4,-1)<0; error('Error accessing new DST file (1)'); end
    count=fwrite(fid,sourceIDdst(1:4),'uint8');
    if count~=4; error('Error writing new source ID'); end

  % Replace the ASCII information field with blanks
    if fseek(fid,48,-1)<0; error('Error accessing new DST file (2)'); end
    nnwrite=80; count=fwrite(fid,blanks(nnwrite),'uint8');
    if count~=nnwrite; error('Error writing new ASCII field'); end

  % Write the new PMU ID's
    if fseek(fid,128,-1)<0; error('Error accessing new DST file (3)'); end
    count=fwrite(fid,pmuIDdst','4*uint8',4);
    if count~=prod(size(pmuIDdst)); error('Error writing new PMU IDs'); end
    fclose(fid);

  catch

    if exist('fid','var')==1
      if ~isempty(fopen(fid)); fclose(fid); end
    end
    error(lasterr);

  end

%=========================================================================
function val=readkeyval(lin)

% Reads value from a line of the form 'keyname = value ; Comments'
  loc0=findstr(lin,'='); if isempty(loc0); val=''; return; end
  loc1=findstr(lin,';'); if isempty(loc1); loc1=length(lin)+1; end
  val=deblank0(lin(loc0+1:loc1-1));

%=========================================================================
function s1=deblank0(s)

% Removes leading and trailing blanks from lines in a character array.
% A blank is removed only if it is present in all lines of text.
% Adapted from MATLAB's 'deblank' m-file.

  [r,c]=find(sum((s~=0) & ~isspace(s),1));
  if isempty(c)
    s1=char(ones(size(s,1),0));
  else
    s1=s(:,min(c):max(c));
  end
