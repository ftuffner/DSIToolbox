function [y,comment,fname,names,reftime,tstep]=cread(fname,ctag,NoHead,NoSigs,dsep);
%
% Reads a text file with data preceeded by a header.  
% Header lines are usually identified by CTAG='C ' as the first two
% characters.   Alternate values of CTAG can be used.
%
% [y,comment,fname,names,reftime,tstep]=Cread(fname,ctag,NoHead,NoSigs,dsep);
%
% STANDARD FORM:
%   Header is followed by a numeric entry Ncols indicating the number 
%     of data columns to follow.
%   Keyword 'NAMES=', in the row following Ncols, commands loading of the
%      next rows as a column of signal names.  Other keyword options
%      are under development.
%
% OPTIONAL FORM #1:
%   No header, no data for Ncols.  Value of Ncols is determind by column count.
%
% OPTIONAL FORM #2:
%   Header is followed by a row of signal names
%   Value of Ncols is determind by column count, but can be provided in next row.
%
% OTHER OPTIONAL FORMS ARE UNDER DEVELOPMENT
%
% Columns are separated by the data separator symbol dsep, usually a tab.
% Special logic is provided to deal with Excel text files
%
% By J. M. Johnson  13MAY94
% Modified 01/24/06.  jfh  Extensions to HMS format 2
% Modified 10/18/06.  Ning Zhou to add macro function

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%********************************************************************

%Clear outputs
%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

y=[]; comment=''; names=''; reftime=0; tstep=0;

%Set parameters
if ~exist('ctag'), ctag='';   end
if isempty(ctag),  ctag='C '; end
Tab='	'; Comma=','; Space=' ';
DsepNames=str2mat('(Tab)','(Comma)','(Space)');
%Establish data separator
%CAUTION: deblank function seems to remove trailing tabs!
Dseps=str2mat(Tab,Comma,Space);
if ~exist('dsep'), dsep=Tab; end
if isempty(dsep),  dsep=Tab; end
DsepNo=0;
for L=1:size(Dseps,1)
  if findstr(dsep,Dseps(L,:)), DsepNo=L; break, end
end 
str1=[ctag 'In Cread: Using initial data separator dsep = ' DsepNames(DsepNo,:)];
comment=str2mat(comment,str1); disp(str1)

%Check input arguments
if nargin<1, fname='';  end
if nargin<2, ctag='C '; end
if nargin<3, NoHead=0;  end
if nargin<4, NoSigs=0;  end

%Open ascii file
if ~isempty(fname)
  fid=fopen(setstr(fname),'r');
else
  fid=-1;
end
if fid<0
  disp(['In Cread: Launching dialog box:'])
  [name,path]=uigetfile('*.*','Select C-Header file:');
  if name==0; return; end;
  fname=[path name];
  [fid,message]=fopen(fname,'r');
  if fid<0; error(message); end;
end
Ctype=computer;
D='\';  %Default delimiter
if strcmp(Ctype,'MAC2'), D=':'; end
TFname=fname; Ds=findstr(D,fname); 
if ~isempty(Ds)
  last=Ds(size(Ds,2));
  TFname=fname(last+1:size(fname,2));
end
%********************************************************************

%********************************************************************
%Process header comments
str1=[ctag 'In Cread: Loading from file indicated below:'];
comment=str2mat(str1,[ctag fname]); 
disp(comment)
disp(' ')
if NoHead, disp('In Cread: No header expected' ); end
if NoSigs, disp('In Cread: No signals expected'); end
Clines=0;
if ~NoHead 
  str1=[ctag 'In Cread: Scanning signal data with ctag = ' '''' ctag ''''];
  comment=str2mat(comment,str1); disp(str1)
  taglen=size(ctag,2);
  for N=1:999
    cs=fgetl(fid);
    if isempty(cs), cs=fgetl(fid); end  %try next file line
    if cs==-1, return, end
    if ~isempty(cs)
      len=min(taglen+1,size(cs,2));
      cfound=~isempty(findstr(ctag,cs(1:len)))|isempty(ctag);
      if ~cfound, break, end      %First non-comment line
      Cline=deblank(cs);
      Ltabs=findstr(Cline,Tab);
      if ~isempty(Ltabs), Cline(Ltabs)=' '; end
      comment=str2mat(comment,Cline);
      Clines=Clines+1;
    end
  end
end
disp(['In Cread: Number of comment lines = ' num2str(Clines)] ) 
%********************************************************************

if NoSigs, disp('In Cread: No signals expected'); return, end

HMSstr=''; HMStime=0; 
Ncols=0;   NcolsOld=0;
%Recognized HMS Formats
%HMStime==1: 
%HMStime==2: 6/19/2005 11:57:30 PM

if NoHead
  cs=fgetl(fid);  %Read first fileline
end
if isempty(cs), cs=fgetl(fid); end  %try next file line
str1=[ctag 'In Cread: Scanning data with initial data separator dsep = ' DsepNames(DsepNo,:)];
comment=str2mat(comment,str1); disp(str1)
disp('In Cread: First line after header is'); disp(cs)
%keyboard

%********************************************************************
%Test for reference date/time information
reftime=0; reftime0=0; reftimeStr='';
%NOTE: PSM absolute time is measured in seconds starting at 1-Jan-1900
%      Matlab absolute time is measured in days starting at 1-Jan-0000 
daysecs=24*3600; %keyboard
refdateline=~isempty(findstr('reference time=',lower(cs)));
if refdateline
  disp('Seeking reference time in format 10-Aug-1996 15:48:46.133')
  cs=fgetl(fid);                      %get next fileline
  if isempty(cs), cs=fgetl(fid); end  %try next file line
  refdateStr=deblank(cs)
  if ~isempty(refdateStr)
    disp(['Reference Time string  = ' refdateStr]);
    reftime0=(datenum(refdateStr)-datenum(1900,1,1,0,0,0))*daysecs; %Start of record
    disp(['Initial reference time = ' PSM2Date(reftime0)])
  end
  cs=fgetl(fid); %get next fileline
end
if isempty(cs), cs=fgetl(fid); end  %try next file line
reftime=reftime0;
%********************************************************************

%********************************************************************
%Test for time step value
tstep=0;
tstepline=~isempty(findstr('time step=',lower(cs)));
if tstepline
  disp('Seeking numerical entry for time step value')
  cs=fgetl(fid); %get next fileline
  if isempty(cs), cs=fgetl(fid); end  %try next file line
  tstep=sscanf(cs,'%f');
  str1=['  tstepline indicates tstep= ' num2str(tstep) '  seconds'];
  disp(str1)
  cs=fgetl(fid); %get next fileline
  if isempty(cs), cs=fgetl(fid); end  %try next file line
end
%********************************************************************

%********************************************************************
%Test #1 for number of data columns
Ncolsline=~isempty(findstr('columns=',lower(cs)));
if Ncolsline
  disp('Seeking numerical entry for number of columns')
  cs=fgetl(fid);
  if isempty(cs), cs=fgetl(fid); end  %try next file line
  Ncols=round(sscanf(cs,'%f'));
  str1=['  Ncolsline indicates Ncols= ' num2str(Ncols) '  data columns'];
  disp(str1)
  cs=fgetl(fid);  %get next fileline
  if isempty(cs), cs=fgetl(fid); end  %try next file line
end
%********************************************************************

%********************************************************************
%Test #2 for number of data columns
Dfmt=['%f' dsep];
if ~Ncolsline
  disp(' ')
  disp('In Cread: Test #2 for number of data columns - Possible data line starts as'); 
  L=min(length(cs),80); disp(cs(1:L))
  HMStime=~isempty(findstr(':',cs));
  if HMStime
    disp('In Cread: HMS time entry recognized')
    nvals=0;
  end
  for L=1:size(Dseps,1)
    dtagL=Dseps(L,:); %dtagL=deblank(Dseps(L,:));
    if isempty(dtagL), dtagL=' '; end
    if findstr(dtagL,cs)
      disp(['In Cread: Data separator ' DsepNames(L,:) ' found in data line'])
      setok=promptyn('In Cread: Use this data separator? ','');
      if setok, dsep=dtagL; DsepNo=L; end
    end
  end 
  Dfmt=['%f' dsep];
  DDlocs=findstr(cs,dsep);
  if HMStime
    nvals=length(DDlocs);
    if max(DDlocs)<length(cs), nvals=nvals+1; end
  else
    [Dline,nvals]=sscanf(cs,Dfmt);
  end
  Ncols=nvals;
  disp(['Number of numeric entries in parsed data line = ' num2str(Ncols)])
  Ncolsline=(nvals==1);
  if Ncolsline
    Ncols=Dline;
    str1=['Possible entry indicates Ncols= ' num2str(Ncols) '  data columns'];
    disp(str1)
  end
  if Ncols<2,
    disp('Data line may indicate too few data columns-- cs shown below'); disp(cs)
    disp(['In Cread: Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  else
    if Ncolsline
      cs=fgetl(fid); %get next fileline
      if isempty(cs), cs=fgetl(fid); end  %try next file line
    end
  end
end
%********************************************************************

%********************************************************************
%Test #1 for signal names
NamesLine=0; NamesCol=0; NamesRow=0;
NamesCol=~isempty(findstr('names=',lower(cs)));
NamesCol=NamesCol|~isempty(findstr('namesv=',lower(cs)));
NamesCol=NamesCol|~isempty(findstr('namescol=',lower(cs)));
if ~NamesCol
  NamesRow=~isempty(findstr('namesh=',lower(cs)));
  NamesRow=NamesCol|~isempty(findstr('namescrow=',lower(cs)));
  if NamesRow
    disp('This option for Row Names not supported yet'); disp(cs)
    keyboard
    y=[];
  end
end
NamesLine=NamesCol|NamesRow;
if NamesCol
  for N=1:Ncols
    cs=fgetl(fid);
    if isempty(cs), cs=fgetl(fid); end  %try next file line
    line=deblank(cs);     %Remove trailing blanks
    line=CharTrim(line);  %Remove trailing tabs
    line=deblank(line);   %Remove trailing blanks
    if N==1
      names=line;
    else
      names=str2mat(names,line);
    end
  end
  y=[];
  cs=fgetl(fid); 
  if isempty(cs), cs=fgetl(fid); end  %try next file line
end
%********************************************************************

%********************************************************************
%Test #2 for signal names (seek names row)
if ~NamesLine
  cst=CharTrim(cs,dsep);  %Remove trailing separators
  locT=findstr(cst,dsep); %Find separator locations
  if ~isempty(locT)
    nameN=cst(1:locT(1)-1);
    NamesLine=~isempty(findstr('time',lower(nameN)));
    NamesLine=NamesLine|~isempty(findstr('freq',lower(nameN)));
    NamesLine=NamesLine|~isempty(findstr('sample',lower(nameN)));
    if NamesLine
      disp(['Test #2 for signal names: first name= ' nameN])
      names=nameN;
      locT=[locT length(cst)+1];
      nvalsA=length(locT);  %number of ascii fields
      for n=2:nvalsA
        nameN='(none)';
    	span=locT(n)-locT(n-1)-1;
	    if span>1, nameN=cs(locT(n-1)+1:locT(n)-1); end
        names=str2mat(names,nameN);
      end
      Ncols=nvalsA; NcolsOld=Ncols;
      disp(['Number of recognized signal names= ' num2str(Ncols)])
      cs=fgetl(fid);
    end
  end
end
%********************************************************************

%********************************************************************
%Assumed start of data -- Examine data characteristics 
disp(' ')
if (Ncols==1), dsep=' '; DsepNo=3; end
disp('In Cread: Assumed start of signal data.  First line starts as'); 
L=min(length(cs),80); disp(cs(1:L))
for L=1:size(Dseps,1)
  dtagL=Dseps(L,:); %dtagL=deblank(Dseps(L,:));
  if isempty(dtagL), dtagL=' '; end

  if findstr(dtagL,cs)
    disp(['In Cread: Data separator ' DsepNames(L,:) ' found in data line'])
    

    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'Cread_setok'), PSMMacro.Cread_setok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.Cread_setok))      % Not in Macro playing mode or selection not defined in a macro
        setok=promptyn('In Cread: Use this data separator? ','');
    else
        setok=PSMMacro.Cread_setok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.Cread_setok=setok;
        else
            PSMMacro.Cread_setok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % setok=promptyn('In Cread: Use this data separator? ','');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------
    if setok, dsep=dtagL; DsepNo=L; end
  end
  
end 
DDlocs=findstr(cs,dsep);
if (Ncols>1)&isempty(DDlocs)
  disp(['In Cread: Cannot find indicated data separator ' DsepNames(DsepNo,:)])
  disp(['In Cread: Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end
str1=[ctag 'In Cread: Scanning data with validated data separator dsep = ' DsepNames(DsepNo,:)];
comment=str2mat(comment,str1); disp(str1)
dsep=Dseps(DsepNo);
Dfmt=['%f' dsep];
HMSstr='';
HMStime=~isempty(findstr(':',cs));
if HMStime
  disp('  Colon found: Assuming HMS time data')
  HMSstr=cs(1:DDlocs(1)-1); HMSfields=1;
  disp(['  HMS time data starts at ' HMSstr])
  HMStime2=~isempty(findstr('/',HMSstr));
  if HMStime2
    HMStime=2; HMSfields=3;
    disp('This is HMS time version 2')
  end
else 
  [Dline,nvals]=sscanf(cs,Dfmt);
  HMSstr=num2str(Dline(1));
  disp(['  Time data starts at time = ' HMSstr ' units'])
end

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'Cread_keybdok'), PSMMacro.Cread_keybdok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.Cread_keybdok))      % Not in Macro playing mode or selection not defined in a macro
    keybdok=promptyn('In Cread: Do you want the keyboard? ','n');
else
    keybdok=PSMMacro.Cread_keybdok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.Cread_keybdok=keybdok;
    else
        PSMMacro.Cread_keybdok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% keybdok=promptyn('In Cread: Do you want the keyboard? ','n');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if keybdok
  disp(['In Cread: Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end
if HMStime
  csd=cs((DDlocs(1)+1):length(cs));
  [Dline,nvals]=sscanf(csd,Dfmt); 
  Dline=[0 Dline']'; nvals=nvals+1;
else
  [Dline,nvals]=sscanf(cs,Dfmt);
end
dataline=nvals>1;  %Assume start of numerical data
if dataline
  Ncols=nvals; 
  str1=['Data line indicates Ncols= ' num2str(Ncols) '  data columns'];
  disp(str1)
else
  disp(cs);
  disp('THIS SHOULD BE A DATA LINE -- user keyboard to check')
  keyboard
end
%********************************************************************

%********************************************************************
%Construct default names if needed
if isempty(names)
  str1='No signal names found: Constructing generic signal names'; disp(str1)
  names='Time';
  for N=2:Ncols
    linetxt=['Signal ' sprintf('%4.0i',N)];
    names=str2mat(names,linetxt);
  end
  comment=str2mat(comment,str1);
end
%Display signal names
disp(' ')
Nsigs=size(names,1);
str1=['Number of signal names = ' num2str(Nsigs)];
chankey=['%' sprintf('%4.0i',1) '  ' names(1,:)];
for N=2:Nsigs
  linetxt=['%' sprintf('%4.0i',N) '  ' names(N,:)];
  chankey=str2mat(chankey,linetxt);
end
disp(str1)
maxlines=20;
if Nsigs<=maxlines
  strs=chankey;
else
  strs=chankey(1:fix(maxlines/2),:);
  strs=str2mat(strs,'%   ');
  strs=str2mat(strs,chankey((Nsigs-fix(maxlines/2)+1):Nsigs,:));
end
disp(strs)
comment=str2mat(comment,str1,strs);
%********************************************************************

%********************************************************************
if 0 %start of supressed logic
if dataline
  Ncols=nvals; 
  if NcolsOld>0&Ncols~=NcolsOld
    str1=['Discrepancy in number of signals: '];
    str1=[str1 'Ncols= ' num2str(Ncols) '  NcolsOld= ' num2str(NcolsOld)];
    disp(str1)
    keyboard
  end 
  %y=Dline';
end
end %end of supressed logic
str1=['In Cread: Looking for ' num2str(Ncols) ' data columns'];
disp(str1); comment=str2mat(comment,str1);
%********************************************************************

%********************************************************************
%Read in time & signal data
disp(' ')
disp('In Cread: Reading signal data'); %keyboard
Readt0=clock;
str=['In Cread: Starting data read at ' datestr(now)];
disp(str); disp(' ')
line=1; badline=0;
while ~isempty(cs)
  if strcmp(cs(1),'&'), break, end %EOF for LADWP data type #1
  if HMStime==1  %keyboard
    HMSstr=cs(1:DDlocs(1)); HMSlocs=findstr(':',HMSstr);
    HMSstr(HMSlocs)=Tab; hms=sscanf(HMSstr,'%f');
    timeval=hms(1)*3600+hms(2)*60+hms(3);
    if line==1
      daysecs=24*3600;
      reftime0=fix(reftime0/daysecs)*daysecs; %Start of day
      str=['Amended reference time = ' PSM2Date(reftime0)];
      disp(str); %comment=str2mat(comment,str);
      reftime=reftime0+timeval;
      offset=timeval;
    end
    timeval=timeval-offset;
    %psmtime=reftime+timeval; disp(PSM2Date(psmtime))
    csd=(cs(DDlocs(1)+1):length(cs));
    [Dline,nvals]=sscanf(csd,Dfmt);
    Dline=[timeval Dline']'; nvals=nvals+1;
  end
  if HMStime==2  %keyboard
    if line==1, disp('Need additional code for HMStime==2'); end
    csd=cs((DDlocs(1)+1):length(cs));
    [Dline,nvals]=sscanf(csd,Dfmt);
    timeval=line; %Temporary placeholder
    Dline=[timeval Dline']'; nvals=nvals+1;
  end
  if ~HMStime
    [Dline,nvals]=sscanf(cs,Dfmt);
  end
  if nvals~=Ncols
    badline=badline+1;
    if badline<=5
      disp(['In Cread -- End of File or bad data at line ' num2str(line) ': (shown below)'])
      disp(cs); %keyboard
    end
  else
    if isempty(y), y=Dline'; 
    else y=[y; Dline']; end
  end
  for NN=1:10  %Possible empty lines
    cs=fgetl(fid);
    if ~isempty(cs), break, end  
  end
  if isempty(cs), cs=-1; end
  if cs==-1, break, end
  line=line+1;
end
%********************************************************************

%********************************************************************
str=['In Cread: Data size = ' num2str(size(y))];
disp(str); comment=str2mat(comment,str);
if reftime>0
  str=['Reference time = ' PSM2Date(reftime)];
  disp(str); comment=str2mat(comment,str);
end
NoTime=isempty(findstr('time',lower(names(1,:))));
if NoTime
  str=['In Cread: Constructing time axis with tstep= ' num2str(tstep)];
  disp(str); comment=str2mat(comment,str);
  npts=size(y,1); time=[0:npts-1]'*tstep; y=[time y];
  names=str2mat('Time',names);
end
time=y(:,1); npts=length(time);
if tstepline
  str=['Indicated tstep = ' num2str(tstep)];
  disp(str); comment=str2mat(comment,str);
  if HMStime==2
    time=(y(:,1)-1)*tstep; y(:,1)=time;
  end
else
  tsteps=time(2:npts)-time(1:npts-1);
  tstep=max(tsteps);
  if HMStime
    tstepA=sum(tsteps)/(npts-1);
    srate=max(1,round(1/tstepA)); tstep=1/srate;
    time=time(1)+[0:(npts-1)]'*tstep; y(:,1)=time;
  end
  str=['Estimated tstep = ' num2str(tstep)];
  disp(str); comment=str2mat(comment,str);
end
%********************************************************************

%Determine elapsed time for file read
Readtime=etime(clock,Readt0);
str=['In Cread: Data read time = ' num2str(Readtime) ' seconds'];
disp(str); comment=str2mat(comment,str);

%Close file
fclose(fid);

%end of PSMT function

