function [YY,comment,fname,names,reftime,tstep]=PTIprntRead(fname,ctag,NoHead,NoSigs);
%
% Reads a text file with data preceeded by a header.  
% Header lines are usually identified by CTAG='C ' as the first two
% characters.   Alternate values of CTAG can be used.
% This version is specialized to PTI PRNT files, which use no CTAG
%
% [y,comment,fname,names,reftime,tstep]=PTIprntRead(fname,ctag,NoHead,NoSigs);
%
%
% Columns are separated by the delimiter symbol DEL, usually a tab.
% Special logic is provided to deal with Excel text files
%
% By J. M. Johnson  13MAY94
% Last modification 04/11/02.  jfh

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%********************************************************************

%Set parameters
tab='	';

%Clear outputs
YY=[]; comment=''; names=''; reftime=0; 
tstep=0; tstepline=0;

%Check input arguments
if nargin<1, fname='';  end
if nargin<2, ctag='C '; end
if nargin<3, NoHead=0;  end
if nargin<4, NoSigs=0;  end

%Special for PTI PRNT files:
ctag='C ';
Ntag=lower('CHANNEL #'); %Special for PTI data
NoHead=0; NoSigs=0;      %Special for PTI data

%*************************************************************************
%Open ascii file
if ~isempty(fname)
  fid=fopen(setstr(fname),'r');
else
  fid=-1;
end
if fid<0
  disp(['In PTIprntRead: Launching dialog box for navigation to data file'])
  [name,path]=uigetfile('*.*','Select PTI PRNT file:');
  if name(1)==0|path(1)==0 
    disp('In PTIprntRead: No file indicated -- returning'),
    return
  end;
	eval(['cd ' '''' path '''']) 
  fname=[path name];
  [fid,message]=fopen(fname,'r');
  if fid<0; error(message); end;
end
%*************************************************************************

%********************************************************************
%Process PTI header comments
str1=['In PTIprntRead: Loading from file indicated below:'];
comment=str2mat(str1,fname); disp(comment)
disp(' ') 
if NoHead, disp('In PTIprntRead: No header expected' ); end
if NoSigs, disp('In PTIprntRead: No signals expected'); end
if ~NoHead 
  str1=['In PTIprntRead: Scanning header with Ntag = ' '''' Ntag ''''];
  comment=str2mat(comment,str1); disp(str1)
  cs=fgetl(fid);
  for N=1:999
    FileEnd=(cs==-1); 
    if FileEnd, return, end
    if ~isempty(cs)
      Nfound=~isempty(findstr(Ntag,lower(cs)));  %Need to extend this test!
      if Nfound, break, end      %First channel name
    end
    line=[ctag deblank(cs)];
    Ltabs=findstr(line,tab);
    if ~isempty(Ltabs), line(Ltabs)=' '; end
    comment=str2mat(comment,line);
    cs=fgetl(fid);
  end
end
disp('In PTIprntRead: First line after header is'); 
disp(cs)
%********************************************************************

%********************************************************************
%Load PTI data
FileEnd=0; LoadStart=now;
names='Time';  %Initialize names array
for DBK=1:99
  %Read signal names for this data block
  [nameN]=deblank(CharTrim(cs,' ','leading'));
  names=str2mat(names,nameN);
  for N=1:999
    cs=fgetl(fid);
    FileEnd=(cs==-1); 
    if FileEnd, break, end
    if ~isempty(cs)
      Nfound=~isempty(findstr(Ntag,lower(cs)));  %Need to extend this test!
      if Nfound
        [nameN]=deblank(CharTrim(cs,' ','leading'));
        names=str2mat(names,nameN);
      else  %Read names line
        NamesLine=findstr('time',lower(cs));
        %strs=['Start of data block ' num2str(DBK)];
        %disp(strs)
        break
      end
    end
  end
  if FileEnd, break, end
  %Assumed start of block data 
  cs=fgetl(fid);
  [Dline,nvals]=sscanf(cs,'%f'); Ncols=nvals;
  if DBK==1 %Examine data characteristics
    disp('In PTIprntRead: Assumed start of data.  First line starts as'); 
    disp(cs)
    disp(['Number of data columns = ' num2str(Ncols)])
    disp('Key to signal names:')
    disp(names2chans(names))
    keybdok=0;
    %keybdok=promptyn('In PTIprntRead: Do you want the keyboard? ', 'n');
    if keybdok
      disp(['In PTIprntRead: Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
    end
  end
  %Read in time & signal data
  disp(['In PTIprntRead: Reading numerical data for block ' num2str(DBK)]);
  y=[]; line=1; badline=0;
  while ~isempty(cs)
    [Dline,nvals]=sscanf(cs,'%f');
    if nvals~=Ncols
      badline=badline+1;
      if badline<=5
        disp('  In PTIprntRead -- Bad data line or end of data block')
        disp('  Data line shown below:')
        disp(cs); break
      end
    else
      if isempty(y), y=Dline'; 
      else y=[y; Dline']; end
    end
    cs=fgetl(fid);
    FileEnd=(cs==-1); 
    if FileEnd, break, end
    line=line+1;
  end
  strs=['  Data block ' num2str(DBK) ': Data size = ' num2str(size(y))];
  disp(strs)
  comment=str2mat(comment,strs);
  [maxpts Ncols]=size(y);
  if DBK==1 %Determine data characteristics
    maxpts1=maxpts;
    YY=y;
  else  %Need additional tests
    YY=[YY y(:,2:Ncols)];    
  end
  if FileEnd, break, end
  %Scan to top of next block
  for N=1:999
    FileEnd=(cs==-1); 
    if FileEnd, break, end
    if ~isempty(cs)
      Nfound=~isempty(findstr(Ntag,lower(cs)));  %Need to extend this test!
      if Nfound, break, end      %First channel name
    end
    cs=fgetl(fid);
  end
  if ~Nfound, break, end
end
LoadEnd=now;
%********************************************************************

%********************************************************************
%Summarize loaded data
chankey=names2chans(names);
comment=str2mat(comment,chankey);
Etime=LoadEnd-LoadStart; EtimeStr=datestr(Etime,13);
[maxpoints nsigs]=size(YY);
strs=' ';
strs=str2mat(strs,['In PTIprntRead: Data size = ' num2str(size(YY))]);
strs=str2mat(strs,['Elapsed working time = ' EtimeStr ' HMS']); 
disp(strs); comment=str2mat(comment,strs);
if reftime>0
  str=['Reference time = ' PSM2Date(reftime)];
  disp(str); comment=str2mat(comment,str);
end
time=YY(:,1); npts=length(time);
tsteps=time(2:npts)-time(1:npts-1);
swlocs=find(time(1:maxpoints-1)==time(2:maxpoints));
if ~isempty(swlocs)
  disp('Switching times found in data:')
  disp(time(swlocs))
  figure;
  plot(tsteps)
  Ptitle{1}='Checking SWX time steps';
  title(Ptitle)
  xlabel('Time in Samples')
  ylabel('Time Steps')
end
if tstepline
  str=['Indicated tstep = ' num2str(tstep)];
  disp(str); comment=str2mat(comment,str);
else
  TSloc1=max([0 swlocs'])+2;
  tstepMax=max(tsteps); 
  tstepMean=mean(tsteps(TSloc1:maxpoints-2));
  tstepE=(time(maxpoints-1)-time(TSloc1))/(maxpoints-1-TSloc1);
  tstep=tstepE; %best guess for now
  str=['Estimated tstep = ' num2str(tstep)];
  disp(str); comment=str2mat(comment,str);
end
%********************************************************************

%Close data file
fclose(fid);

%end of PSMT function PTIprntRead

