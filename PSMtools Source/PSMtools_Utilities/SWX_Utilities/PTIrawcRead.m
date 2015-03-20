function [YY,comment,fname,names,reftime,tstep]=PTIrawcRead(fname,ctag,NoHead,NoSigs);
%
% Reads a text file with data preceeded by a header.  
% Header lines are usually identified by CTAG='C ' as the first two
% characters.   Alternate values of CTAG can be used.
% This version is specialized to PTI RAWC files, which use no CTAG
%
% [y,comment,fname,names,reftime,tstep]=PTIrawcRead(fname,ctag,NoHead,NoSigs);
%
%
% Columns are separated by the delimiter symbol DEL, usually a tab.
% Special logic is provided to deal with Excel text files
%
% By J. M. Johnson  13MAY94
% Last modification 06/16/03.  jfh

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
  disp(['In PTIrawcRead: Launching dialog box for navigation to data file'])
  [name,path]=uigetfile('*.*','Select PTI PRNT file:');
  if name(1)==0|path(1)==0 
    disp('In PTIrawcRead: No file indicated -- returning'),
    return
  end;
	eval(['cd ' '''' path '''']) 
  fname=[path name];
  %fclose(fid);
  [fid,message]=fopen(fname,'r');
  if fid<0; error(message); end;
end
%*************************************************************************

%********************************************************************
%Process PTI header
%fclose(fid); [fid,message]=fopen(fname,'r');
str1=[ctag 'In PTIrawcRead: Loading from file indicated below:'];
comment=str2mat(str1,[ctag fname]); disp(comment)
disp(' '); %keyboard 
if NoHead, disp('In PTIrawcRead: No header expected' ); end
if NoSigs, disp('In PTIrawcRead: No signals expected'); end
if ~NoHead 
  str1=['In PTIrawcRead: Scanning fixed-format name header'];
  comment=str2mat(comment,[ctag str1]); disp(str1)
  cs=fgetl(fid); PTIhead=cs;
  [Dline,nvals]=sscanf(cs,'%f');
  Nsigs=Dline(1); PTIformat=Dline(2);
  disp(['PTI format=' num2str(PTIformat)])
  Nlines=1;
  if PTIformat==1
    disp('In PTIrawcRead: Name parsing not complete for PTI format 1--Use format 2 if possible')
    disp('Processing paused == press any key to continue'); pause
    NameLen=30;
    Nlines=ceil(Nsigs/(280/NameLen));   
  end
  if PTIformat==2
    NameLen=32;
    Nlines=ceil(Nsigs/(128/NameLen)); 
  end
  for N=1:Nlines+2
    cs=fgetl(fid); PTIhead=str2mat(PTIhead,cs);
    line=[ctag deblank(cs)];
    Ltabs=findstr(line,tab);
    if ~isempty(Ltabs), line(Ltabs)=' '; end
    comment=str2mat(comment,line);
  end
end
disp('PTI header:'); disp(PTIhead)
[Hlines Hcols]=size(PTIhead);
NameStr=PTIhead(2,:);
for N=3:Hlines, NameStr=[NameStr PTIhead(N,:)]; end
if PTIformat==1  %Parsing incomplete
  NameLen1=32; NameLen2=32;
  locs=([0:Nsigs-1]*NameLen1);
end
if (PTIformat==2)|(PTIformat==1) %Temporary for format 1
  NameLen=32;
  locs=([0:Nsigs-1]*NameLen);
  names='Time';  %Initialize names array
  for N=1:Nsigs
    names=str2mat(names,NameStr([1:NameLen]+locs(N)));
  end
end
disp('PTI names:'); disp(names); %keyboard
%********************************************************************

%********************************************************************
%Load PTI data
FileEnd=0; LoadStart=now; DataStart=0;
for DBK=1:9999 %Read all data blocks
  if FileEnd, break, end
  cs=fgetl(fid);
  FileEnd=(cs==-1);
  if FileEnd, break, end
  if ~isempty(cs)
    [Dline,nvals]=sscanf(cs,'%f'); 
    if nvals==2
      if Dline(1)<=0
        FileEnd=1; break
      end 
      Ncols=Dline(1); timeK=Dline(2);
      if DataStart==0 %Examine data characteristics
        DataStart=1;
        disp('In PTIrawcRead: Assumed start of data.  First line starts as'); 
        disp(cs)
        disp(['Indicated number of data columns = ' num2str(Ncols)])
        disp(['Initial time for stored data     = ' num2str(timeK)])
        time=[]; YY=[]; 
        keybdok=0;
        %keybdok=promptyn('In PTIrawcRead: Do you want the keyboard? ', 'n');
        if keybdok
          disp(['In PTIrawcRead: Invoking "keyboard" command - Enter "return" when you are finished'])
          keyboard
        end
      end
      time=[time timeK]; 
      y=timeK; NewPts=0;
      while NewPts<Nsigs
        cs=fgetl(fid);
        [Dline,nvals]=sscanf(cs,'%f');
        y=[y Dline'];
        NewPts=NewPts+nvals;
      end
      YY=[YY y'];
    end  %End block for nvals==2
  end
end
YY=YY';
LoadEnd=now;
%********************************************************************

%********************************************************************
%Summarize loaded data
chankey=names2chans(names);
comment=str2mat(comment,chankey);
Etime=LoadEnd-LoadStart; EtimeStr=datestr(Etime,13);
[maxpoints nsigs]=size(YY);
strs=' ';
strs=str2mat(strs,['In PTIrawcRead: Data size = ' num2str(size(YY))]);
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

%end of PSMT function PTIrawcRead

