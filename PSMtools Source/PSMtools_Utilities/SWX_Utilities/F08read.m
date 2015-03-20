function [y,comment,fname,names]=F08read(fname,ctag,NoHead,NoSigs);
%
% Reads SYSFIT text files with data preceeded by a header.  
% Header lines are usually identified by CTAG='C ' as the first two
% characters.   Alternate values of CTAG can be used.
%
% STANDARD FORM:
%   Main header, followed by a subheader plus numeric data for each signal.
%   Format F08 as defined for BPA programs SYSFIT,SYSCHECK,SIGPAK,SIGPAKZ
%   Data columns are formatted 12 characters wide, USUALLY have delimiting spaces.
%
%     [y,comment,fname,names]=F08read(fname,ctag,NoHead,NoSigs);
%
% By J. M. Johnson  13MAY94
% Last modification 06/22/01.  jfh

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%********************************************************************

%Set parameters
tab='	';

%Clear outputs
y=[]; comment=''; names='';

%Check input arguments
if nargin<1, fname= '';  end
if nargin<2, ctag='C '; end
if nargin<3, NoHead=0; end
if nargin<4, NoSigs=0; end

%Open ascii file
if ~isempty(fname)
  fid=fopen(setstr(fname),'r');
else
  fid=-1;
end
if fid<0
  disp(['In F08read: Launching dialog box:'])
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
str1=['In F08read: Loading from file indicated below:'];
comment=str2mat(str1,fname); disp(comment)
disp(' ') 
if NoHead, disp('In F08read: No header expected' ); end
if NoSigs, disp('In F08read: No signals expected'); end
if ~NoHead 
  str1=['In F08read: Scanning header with ctag = ' '''' ctag ''''];
  comment=str2mat(comment,str1); disp(str1)
  taglen=size(ctag,2);
  for N=1:999
    cs=fgetl(fid);
    if cs==-1, return, end
    if ~isempty(cs)
      len=min(taglen+1,size(cs,2));
      cfound=~isempty(findstr(ctag,cs(1:len)))|isempty(ctag);
      if ~cfound, break, end      %First non-comment line
      line=deblank(cs);
      Ltabs=findstr(line,tab);
      if ~isempty(Ltabs), line(Ltabs)=' '; end
      comment=str2mat(comment,line);
    end
  end
end
disp('In F08read: First line after comments is'); disp(cs)
%********************************************************************

%********************************************************************
%Special operations
if NoSigs, return, end
Ncols=0; NcolsOld=0;
if NoHead
  cs=fgetl(fid);  %Read first line of file
  disp('In F08read: First line is'); disp(cs)
end
%********************************************************************

%********************************************************************
%Read series of signal records
y=''; names='';
for RecNo=1:99
  if RecNo>1
    cs=fgetl(fid);  %Read first line of subheader
  end
  if cs==-1, break, end  %Test for end of file
  [Dline,nvals]=sscanf(cs,'%f'); %Test for numerical data
  if nvals>0,
    disp('THIS SHOULD NOT BE A DATA LINE -- use keyboard to check')
    keyboard
  else
    disp(['Start of Subheader for record number ' num2str(RecNo)])
    strs=deblank(cs);
    NameIn=deblank(cs(1:24)); NameOut=deblank(cs(25:48));
    cs=fgetl(fid);  %Read line 2 of subheader
    strs=str2mat(strs,deblank(cs));
    SigName=deblank(cs);
    cs=fgetl(fid);  %Read line 3 of subheader (blank)
    strs=str2mat(strs,deblank(cs));
    cs=fgetl(fid);  %Read line 1 of data parameters
    strs=str2mat(strs,deblank(cs));
    [Dline,nvals]=sscanf(cs,'%f');
    %[Kplt Mdat IsigSum NoWin NoPrtd]=Dline';
    Kplt=Dline(1);  %Number of data points
    Mdat=Dline(2);  %Data Mode
    cs=fgetl(fid);  %Read line 2 of data parameters
    strs=str2mat(strs,deblank(cs));
    comment=str2mat(comment,strs);
    %disp(strs); 
    [Dline,nvals]=sscanf(cs,'%f');
    %[Tfirst Tlast Scale WinTypeX Rzero]=Dline';
    Tfirst=Dline(1); Tlast=Dline(2); Scale=Dline(3);
    if Scale==0, Scale=1; end
    str1=['In F08read: ' num2str(Kplt) ' data entries'];
    comment=str2mat(comment,strs,str1);
    %disp(str1); 
    if Kplt>0
      RecTime=zeros(Kplt,1); InSig=zeros(Kplt,1); OutSig=zeros(Kplt,1);
      for K=1:Kplt
        cs=fgetl(fid);  %Read data line
        [Dline,nvals]=sscanf(cs,'%f');
        RecTime(K)=Dline(1); InSig(K)=Dline(2); OutSig(K)=Dline(3);    
      end
      if Scale~=1, OutSig=OutSig*Scale; end
      if RecNo==1
        time=RecTime;
        y(:,1)=time;
        TimeLocs=1; names='time ';
      end
      [SigPts Nsigs]=size(y);
      RecPts=length(RecTime);
      fill=SigPts~=RecPts;
      if fill
        if SigPts<RecPts
          filldat=zeros(RecPts-SigPts,Nsigs);
          y=[y' filldat']';
          time=y(:,max(TimeLocs));
        end
        if SigPts>RecPts
          filldat=zeros(SigPts-RecPts,1);
          RecTime=[RecTime filldat];
          InSig  =[InSig   filldat];
          OutSig =[OutSig  filldat];
        end
      end
      timetest=fill;
      if ~fill
        timetest=RecTime==time;
        timetest=~isempty(find(timetest==0));
      end
      if timetest
        time=RecTime;
        y=[y time];
        TimeLocs=[TimeLocs size(y,2)];
        names=str2mat(names,['time ' num2str(length(TimeLocs))]);
        str1=['  New time axis at column ' num2str(max(TimeLocs))];
        comment=str2mat(comment,str1);
        disp(str1)
      end
      if Mdat==2
        y=[y InSig];
        names=str2mat(names,NameIn);
      end
      y=[y OutSig];
      names=str2mat(names,SigName);
    end
  end
end
%********************************************************************

%********************************************************************
%Determine size of data array
str1=['In F08read: Data size = ' num2str(size(y))];
disp(str1); comment=str2mat(comment,str1);
%********************************************************************

%Close file
fclose(fid);

return

%end of PSMT function

