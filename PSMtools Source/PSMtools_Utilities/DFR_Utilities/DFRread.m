function [y,comment,fname,names,reftime,tstep]=DFRread(fname,ctag,NoHead,NoSigs,dsep,nXfile);
%
% Reads a Binary/ASCII Comtrade file associated with a text comfiguration file.  
%
% [y,comment,fname,names,reftime,tstep]=DFRread(fname,ctag,NoHead,NoSigs,dsep,nXfile);
%
% STANDARD FORM:
%   Configuration file gives the information about how the data is stored in the data file.
%   Ref [1]: P37.111/D11 IEEE Standard Common Format for Transient Data Exchange (COMTRADE)
% for Power Systems, Prepared by the Working Group on Revision of C37.111 of the Power System Relaying Committee
%
% ASCII format data columns are separated by commas.
% Binary format data columns have fixed field lengths as defined in Ref [1].
%
% By Henry Huang  05FEB04
% Modified 02/19/04.  Henry
% Modified 02/24/04.  jfh.  Efficiencies, input control to reduce display

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%********************************************************************

persistent names0 CFname0
global PSMtype CFname

%Clear outputs
y=[]; comment=''; names=''; reftime=0; tstep=0;

%Set parameters
if ~exist('ctag'), ctag='';   end
if isempty(ctag),  ctag='C '; end
%Space=' '; Tab='   '; Comma=',';
%DsepNames=str2mat('(Space)','(Tab)','(Comma)');
%Establish data separator
%Dseps=str2mat(Space,Tab,Comma);
if ~exist('dsep'),   dsep='';   end
if isempty(dsep),    dsep=' ';  end
if ~exist('nXfile'), nXfile=[]; end
if isempty(nXfile),  nXfile=1;  end
%DsepNo=0;
%for L=1:size(Dseps)
%  if findstr(dsep,Dseps(L,:)), DsepNo=L; break, end
%end 
%str1=[ctag 'In Cread: Using initial data separator dsep = ' DsepNames(DsepNo,:)];
%comment=str2mat(comment,str1); disp(str1)
dsep=',';   % data separator

%Check input arguments
if nargin<1, fname='';  end
if nargin<2, ctag='C '; end
if nargin<3, NoHead=0;  end
if nargin<4, NoSigs=0;  end

% Open and read the configuration file
disp(' ')
disp(['In DFRread: Processing file number ' num2str(nXfile)])
if ~isempty(fname)
    [pathstr,Dname,ext,dummy]=fileparts(setstr(fname));
    cfgfname = fullfile(pathstr,[Dname '.CFG']);  
    fid=fopen(cfgfname,'r');
    if fid<0
        disp(['In DFRread: Configuration file ' cfgfname ' not found!'])
        disp(' ')
        return;
    end
else
    disp(['In DFRread: No file to read!!!'])
    return;
end

t0 = clock;     % start time

str1=[ctag 'In DFRread: Reading configuration information from file indicated below:'];
comment=str2mat(str1,[ctag '            ' fname]); 
disp(comment);
cs = fgetl(fid);    % read first line - "station_name,rec_dev_id,rev_year"
[stationName, stationID, ver] = strread(cs,'%s%s%d','delimiter',',');
if isempty(ver); ver = 1991; end        % default Comtrade version 
CFname=char(stationID);
str1=[ctag 'Substation= ' char(stationName)]; 
str2=[ctag 'CFname    = ' CFname]; 
str3=[ctag 'Comtrade version ' num2str(ver)];
comment=str2mat(str1,str2,str3);
cs = fgetl(fid);    % read second line - "TT,##A,##D"
[nSigs,nAs,nDs] = strread(cs,'%d%dA%dD','delimiter',',');
strl = [ctag '            Total ' num2str(nSigs) ' signals, including ' num2str(nAs) ' analog and ' num2str(nDs) ' digital signals.'];
comment=str2mat(comment,strl); 
disp(comment)
disp(' ')
if (nXfile==1)|isempty(CFname0)
  CFname0=CFname;
else
  CFchange=isempty(findstr(CFname,CFname0));
  if CFchange
    disp('In DFRread: FILE CONFIGURATION CHANGE')
    disp(['  Old CFname =' CFname0])
    disp(['  New CFname =' CFname])
    disp('In DFRread: Returning empty data matrix')
    y=[]; return
  end
end

chNames=[];chUnits=[];ch_a=[];ch_b=[];chSkew=[];chMin=[];chMax=[];chPri=[];chSec=[];chPS=[];
for i = 1:nAs       % read analog signal information
    cs = fgetl(fid);    % read analog singal line - "An,ch_id,ph,ccbm,uu,a,b,skew,min,max,primary,secondary,PS"
    [An,ch_id,ph,ccbm,uu,a,b,skew,dmin,dmax,primary,secondary,PS] = strread(cs,'%d%s%s%s%s%f%f%f%d%d%f%f%s','delimiter',',');
    if isempty(ch_id); ch_id = ['Signal #' num2str(i)]; end     % ch_id is non-critical as defined in the Comtrade standard
    if i==1 
        chNames = char(ch_id); 
        chUnits = char(uu);
    else
        chNames = char(chNames,char(ch_id)); 
        chUnits = char(chUnits,char(uu));
    end
    ch_a = [ch_a;a];
    ch_b = [ch_b;b];
    chSkew = [chSkew;skew];
    chMin = [chMin;dmin];        % protection for non-critical data ?????
    chMax = [chMax;dmax];
    chPri = [chPri;primary];
    if isempty(primary); chPri = [chPri; 1]; end
    chSec = [chSec;secondary];
    if isempty(secondary); chSec = [chSec; 1]; end
    if i==1
        if isempty(PS); PS = 'PS'; end
        chPS = char(PS);
    else
        if isempty(PS); PS = 'PS'; end
        chPS = str2mat(chPS,char(PS));    
    end
end

chNormStatus=[];
for i = 1:nDs       % read digital signal information
    cs = fgetl(fid);    % read analog singal line - "Dn,ch_id,ph,ccbm,y"
    [Dn,ch_id,ph,ccbm,y] = strread(cs,'%d%s%s%s%d','delimiter',',');
    if isempty(ch_id); ch_id = ['Signal #' num2str(nAs+i)]; end     % ch_id is non-critical as defined in the Comtrade standard
    if isempty(chNames) 
        chNames = char(ch_id); 
    else
        chNames = char(chNames,char(ch_id)); 
    end
    chNormStatus = [chNormStatus;y];
end

cs = fgetl(fid);    % read line frequency - "lf"
fNorm = strread(cs,'%d');
cs = fgetl(fid);    % read number of sampling rates - "nrates"
nRates = strread(cs,'%d');
rate=[];lastSample=[];
for i = 1:nRates
    cs = fgetl(fid);    % read sampling rate - "samp,endsamp"
    [samp,endsamp] = strread(cs,'%f%d','delimiter',',');
    rate = [rate;samp];
    lastSample = [lastSample;endsamp];
end
nSamples = endsamp;     % total number of samples is the last endsamp.

cs = fgetl(fid);    % read start time stamp - "dd/mm/yyyy,hh:mm:ss.ssssss"
startTime = strread(cs,'%s');
disp(['In DFRread: Reference time = ' char(startTime)])

cs = fgetl(fid);    % read trigger time stamp - "dd/mm/yyyy,hh:mm:ss.ssssss"
triggerTime = strread(cs,'%s');
cs = fgetl(fid);    % read data file type - "ft"
fileType = deblank(strread(cs,'%s'));
cs = fgetl(fid);    % read time multiplier - "timemult"
tMulti = 1;         % timestamp multiplier. defaulted to 1
if cs ~= -1
     try
         tMulti = strread(cs,'%f'); 
     catch
         tMulti = 1;
     end
%    if ~isempty(cs); tMulti = strread(cs,'%f'); else; tMulti = 1; end
end

fclose(fid);        % close configuration file

if ~strcmp(upper(fileType),'ASCII') & ~strcmp(upper(fileType),'BINARY')
    disp('In DFRread: file type not recognized!')
    disp(' ')
    return;
end

% Open and read ASCII data file
if strcmp(upper(fileType),'ASCII') 
    fid=fopen(setstr(fname),'r');
    if fid<0
        disp(['In DFRread: ASCII data file ' fname ' not found!'])
        disp(' ')
        return;
    end
    fclose(fid);
    y = dlmread(setstr(fname),',');
    y = y(:,2:nSigs+2);         % delete sample no
end

% Open and read Binary data file
if strcmp(upper(fileType),'BINARY') 
    fid=fopen(setstr(fname),'r');
    if fid<0
        disp(['In DFRread: Binary data file ' fname ' not found!'])
        disp(' ')
        return;
    end
    nBytesH = 4 + 4;                 % total bytes of analog signals in each sample
    nBytesA = nAs * 2;               % total bytes of analog signals in each sample
    nBytesD = ceil(nDs/16) * 2;      % total bytes of digital signals in each sample
    nBytes = nBytesH + nBytesA + nBytesD; % total bytes in each sample
    [y, count] = fread(fid,[nBytes/2 nSamples],'int16'); 
    fclose(fid);
    y(1,:) = (hex2dec([dec2hex(y(2,:)+(y(2,:)<0)*2^16,2) dec2hex(y(1,:)+(y(1,:)<0)*2^16,2)]))';    % sequence number    !! convert to positive number first then convert to hex
    y(2,:) = (hex2dec([dec2hex(y(4,:)+(y(4,:)<0)*2^16,2) dec2hex(y(3,:)+(y(3,:)<0)*2^16,2)]))';    % timestamp          !! and merge to 4-byte and then convert to new dec again
    % y(5:4+nAs,:);                   % analog signals
    dD = zeros(nBytesD*8,nSamples);
    for i = 1:nBytesD/2             % extract digital signals
        for j = 1:nSamples
            dD((i-1)*16+1:(i-1)*16+16,j) = (bitget(y(i+nBytesH/2+nAs,j), 1:1:16))';   
        end
    end
%    y = [y(1,:);y(2,:);y(5:4+nAs,:);dD(1:nDs,:)]';  % reconstruct data matrix
    y = [y(2,:);y(5:4+nAs,:);dD(1:nDs,:)]';  % reconstruct data matrix. delete sample no
end

%********************************************************************
% Convert data to engineering format
%y(:,2) = y(:,2) + chSkew;      % time shift ?????
for i = 1:nAs               % convert analog data. all data is converted to primary side
    y(:,1+i) = ch_a(i)*y(:,1+i) + ch_b(i);      % ax + b
    if strcmp(upper(chPS(i,:)),'S')
        y(:,1+i) = y(:,1+i) * chPri(i)/chSec(i);
    end
end
%********************************************************************

%********************************************************************
% Adjust time stamp
y(:,1)=y(:,1)*tMulti/1000000;     % convert from usec to sec
%********************************************************************

%********************************************************************
% Construct reference time
%NOTE: PSM absolute time is measured in seconds starting at 1-Jan-1900
%      Matlab absolute time is measured in days starting at 1-Jan-0000 

% !!!! guess different Comtrade versions have diff time format!!!!!
startTime = char(startTime);
dotPos = findstr(startTime,'.');
if size(dotPos,2)>1
    startTime = [startTime(1:dotPos(2)-1) startTime(dotPos(2)+1:length(startTime))];  % deal with one more dot output by WaveWin32
end
[MM,dd,yyyy,hh,mm,ss] = strread(char(startTime),'%d/%d/%d,%d:%d:%f');
if yyyy<20; yyyy = 2000+yyyy; elseif yyyy<100; yyyy = 1900+yyyy; end    % !!! ad hoc deal with 2-digit year
daysecs = 24*3600; %keyboard
reftime = (datenum(yyyy,MM,dd,hh,mm,ss)-datenum(1900,1,1,0,0,0))*daysecs; %Start of record
disp(['            Initial reference time = ' PSM2Date(reftime)]); %keyboard
%********************************************************************

%********************************************************************
if (nXfile==1)|isempty(names0)   % Construct signal names
%names = str2mat('Sample No', 'Time in us');
names = 'Time in seconds';
stName = strread(char(stationName), '%s');    % get short station name
for i = 1:nAs 
    names = str2mat(names, char([char(stName(1,:)) ' ' chNames(i,:) '    ' chUnits(i,:)])); 
end
for i = 1:nDs 
    names = str2mat(names, char([char(stName(1,:)) ' ' chNames(nAs+i,:)])); 
end
disp(' ')
%nSigs = nSigs + 2;      % include sample no and time
nSigs = nSigs + 1;      % include time
str1 = ['            Number of signal names = ' num2str(nSigs)];
chankey=['%' sprintf('%4.0i',1) '  ' names(1,:)];
for i = 2:nSigs
  linetxt=['%' sprintf('%4.0i',i) '  ' names(i,:)];
  chankey=str2mat(chankey,linetxt);
end
disp(str1)
maxlines=20;
if nSigs<=maxlines
  strs=chankey;
else
  strs=chankey(1:fix(maxlines/2),:);
  strs=str2mat(strs,'%   ');
  strs=str2mat(strs,chankey((nSigs-fix(maxlines/2)+1):nSigs,:));
end
disp(strs)
comment=str2mat(comment,str1,strs);
names0=names;
end
%********************************************************************

%********************************************************************
% Largest time step
tstep=1/min(rate);  % time step in seconds
%********************************************************************

%********************************************************************
str=['In DFRread: Data size = ' num2str(size(y))];
disp(str); comment=str2mat(comment,str);
if reftime>0
  str=['  Reference time = ' PSM2Date(reftime)];
  disp(str); comment=str2mat(comment,str);
end
str=[' Largest time step = ' num2str(tstep) ' seconds'];
disp(str); comment=str2mat(comment,str);

%Determine elapsed time for file read
readTime = etime(clock, t0);
str=['In DFRread: Data read time = ' num2str(readTime) ' seconds'];
disp(str); comment=str2mat(comment,str);


%end of PSMT function

