function [pmutags,pmunames,VIcon,phsrnames,comment,samplerate,pmutagsA]=inipars2(initext,ctag,trackX);
%
% Reads and parses PDC configuration data from a text array.
%
%  [pmutags,pmunames,VIcon,phsrnames,comment]=inipars2(initext,ctag,trackX);
%
% Modified 11/21/05  jfh  Changed read command for samplerate.
% Modified 04/06/06  zn   select channels first before repairing.
% Modified 04/03/07  zn   Adapted to TVA configuration file
% Modified 05/30/13  ft   Adapting to more generic configuration files
%
% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%keyboard;
pmutagsA='';

if nargin<1, fname=''; ctag=';'; trackX=1; end;
if isempty(ctag), ctag=';'; end
if ~exist('trackX'), trackX=1; end
if isempty(trackX),  trackX=1; end
trackX=max(trackX,0);

%********************************************************************
%Process header comments
comment=''; taglen=size(ctag,2);
for NN=1:999
  cs=initext(NN,:);
  if (isempty(cs) || (cs(1)=='[')), break, end  %FT - Added bracket search, in case first blank not there
  cfound=findstr(ctag,cs(1:taglen));
  if isempty(cfound), break, end
  if NN==1, comment=cs;
  else comment=str2mat(comment,cs); end
end
%********************************************************************

%disp(comment); disp(' '); pause

%********************************************************************
% Start: Edited by Ning Zhou on 04/03/2007 for eastern compatibility
for ntry=1:100
    cslen=size(cs,2);
    cs=initext(NN,:);   %new data line
    if ~isempty(findstr(cs,'['))
        break;
    else
        NN=NN+1; 
    end
end
    
% cslen=size(cs,2);
% NN=NN+1; cs=initext(NN,:);   %new data line

% End: Edited by Ning Zhou on 04/03/2007 for eastern compatibility
%********************************************************************

%********************************************************************
%Extract generic data
for K=1:2
    loc1=findstr(cs,'['); loc2=findstr(cs,']');
    nameQ=cs(loc1+1:loc2-1);     %Quantity name
    if strcmp(nameQ,'DEFAULT')   %Default data
      if trackX, disp(['In inipars2: keyword = ' nameQ]); end
      VIdef=zeros(3,6); N=0;
      NN=NN+1; cs=initext(NN,:);   %new data line
      for MMM=1:999
        N=N+1;
        locE=findstr(cs,'='); locC=findstr(cs,ctag);
        if isempty(locC), locC=size(cs,2)+1; end
        phsrtype=cs(locE+1); ind=findstr(phsrtype,'VIF');
          if ~isempty(ind), VIdef(N,1)=ind; end
        loc=findstr(cs(1:locC-1),',');
        NF=min(size(loc,2)-1,5);  %number of numeric fields
        for n=1:NF
            span=loc(n+1)-loc(n)-1;
            if span>1, VIdev(N,n+1)=sscanf(cs(loc(n)+1:loc(n+1)-1),'%f'); end
        end
        name=cs(loc(NF+1)+1:locC-1);
          if N==1, defnames=name; else defnames=str2mat(defnames,name); end
          NN=NN+1; cs=initext(NN,:);   %new data line
        if size(findstr(' ',cs),2)==cslen, break, end
      end
      NN=NN+1; cs=initext(NN,:);   %new data line
    end
    if strcmp(nameQ,'CONFIG')   %sample rate, etc.
      if trackX, disp(['In inipars2: keyword = ' nameQ]); end
      %Get sample rate
      NN=NN+1; cs=initext(NN,:);   %new data line
      locE=findstr(cs,'='); locC=findstr(cs,ctag);
      if isempty(locC), locC=size(cs,2)+1; end
      field=cs(locE+1:locC-1);
      samplerate=sscanf(field,'%f');
      %Get number of PMUs
      NN=NN+1; cs=initext(NN,:);   %new data line
      locE=findstr(cs,'='); locC=findstr(cs,ctag);
      if isempty(locC), locC=size(cs,2)+1; end
      field=cs(locE+1:locC-1);
      npmus=sscanf(field,'%d');
      for MMM=1:5    %Scan to next blank line
        NN=NN+1; cs=initext(NN,:);   %new data line
        if size(findstr(' ',cs),2)==cslen, break, end
      end
    end
end
%********************************************************************

if trackX, disp(' '); end
%Reserve working storage
maxsigs=20; NFmax=5; VInums=NFmax+1; maxchars=80;
%------------------------------------------
% start: changed by ZN on 04/05/2006 
% VIcon=zeros(maxsigs,VInums,npmus);

VIcon=zeros(maxsigs,VInums+1,npmus);
% end: changed by ZN on 04/05/2006
%------------------------------------------

phsrnames=char(ones(maxsigs,maxchars,npmus)*' ');
nsigsM=0; ncharsM=0;    %Initialize counters

%********************************************************************
%Extract configuration details for each PMU or remote PDC
for K=1:npmus
  nameS='';
  for ntry=1:100
    NN=NN+1; cs=initext(NN,:);   %new data line - may be blank
    loc1=findstr(cs,'['); loc2=findstr(cs,']');
    nameS=cs(loc1+1:loc2-1);     %PMU station name (short WSCC acronym)
    if ~isempty(nameS), break, end
  end
  if trackX, disp(['In inipars2: PMU tag = ' nameS]); end
  if K==1, pmutags=nameS; else pmutags=str2mat(pmutags,nameS); end
  NN=NN+1; cs=initext(NN,:);   %new data line - PMU station name
  locE=findstr(cs,'='); locC=findstr(cs,ctag);
  if isempty(locC), locC=size(cs,2)+1; end
  nameL=cs(locE(1)+1:locC-1);     %PMU station name (long)
  if trackX, disp(['             station name = ' nameL]); end
  if K==1, pmunames=nameL; else pmunames=str2mat(pmunames,nameL); end
  NN=NN+1; cs=initext(NN,:);   %new data line - PMU number
  locE=findstr(cs,'='); locC=findstr(cs,ctag);
  if isempty(locC), locC=size(cs,2)+1; end
  field=cs(locE(1)+1:locC-1);
  pmuno=sscanf(field,'%d');
  NN=NN+1; cs=initext(NN,:);   %new data line - Alias name or number of phasors
  locE=findstr(cs,'='); locC=findstr(cs,ctag);
  if isempty(locC), locC=size(cs,2)+1; end
  field=cs(locE(1)+1:locC-1);
  if findstr('aliasid=',lower(cs))
    tagA=deblank(field);  %Alias tag
    if K==1, pmutagsA=tagA; else pmutagsA=str2mat(pmutagsA,tagA); end
    NN=NN+1; cs=initext(NN,:);  %new data line - Number of phasors
    locE=findstr(cs,'='); locC=findstr(cs,ctag);
    if isempty(locC), locC=size(cs,2)+1; end
    field=cs(locE(1)+1:locC-1);
  end
  nphsrs=sscanf(field,'%d');
  if trackX
    disp(sprintf('             PMU number   =%2.1i Phasors = %2.1i',[pmuno nphsrs]))
  end
  VIconK=zeros(nphsrs+1,VInums);
  
  %FT - see if the next line is a digital count, and skip if necessary
  tempcs=initext((NN+1),:);
  if (strfind(tempcs,'NumberDigitals'))
      %Go forward one
      NN = NN + 1;
  elseif (~strfind(tempcs,'Phasor'))
      error(['Unexpected data in ini file at line ' num2str(NN+1)]);
  end
  %Default else - it is a 'Phasor' line
    
  for N=1:nphsrs+1
	  NN=NN+1; cs=initext(NN,:);   %new data line
	  if trackX&(size(findstr(' ',cs),2)==cslen)
      disp(['   Premature data end for   ' nameL]), break
    end
	  nsigs=N;
	  locE=findstr(cs,'='); locC=findstr(cs,ctag);
    if isempty(locC), locC=size(cs,2)+1; end
    phsrtype=cs(locE(1)+1); ind=findstr(phsrtype,'VIFNS');  %phasor type 
	  if ~isempty(ind), VIconK(N,1)=ind; end
	  loc=findstr(cs(1:locC-1),',');
    NF=min(size(loc,2)-1,NFmax);  %number of numeric fields
    for n=1:NF
  	  span=loc(n+1)-loc(n)-1;
	    if span>0, VIconK(N,n+1)=sscanf(cs(loc(n)+1:loc(n+1)-1),'%f'); end
    end
	  name=cs(loc(NF+1)+1:locC-1);
	  %prefix=sprintf('%2.0i%2.0i',[pmuno N-1]);index=prefix==['    '];prefix(index)='0';
	  prefix=pmutags(K,1:4);
	  name=[prefix ' ' deblank(name) ' '];
	  nchars=min(size(name,2),maxchars);  ncharsM=max(nchars,ncharsM);
	  phsrnames(N,1:nchars,K)=name(1:nchars);
  end
  for ntry=1:5    %Scan to next blank line
    if NN == size(initext,1), break, end
    NN=NN+1; cs=initext(NN,:);   %new data line
    if size(findstr(' ',cs),2)==cslen, break, end
  end
%------------------------------------------
% start: changed by ZN on 04/05/2006 
%  VIcon(1:nsigs,:,K)=VIconK(1:nsigs,:);
  VIcon(1:nsigs,1:end-1,K)=VIconK(1:nsigs,:);
% start: changed by ZN on 04/05/2006 
%------------------------------------------  
  nsigsM=max(nsigs,nsigsM);
end

%Trim output arrays to minimum size

VIcon=VIcon(1:nsigsM,:,:);
phsrnames=phsrnames(1:nsigsM,1:ncharsM,:);

%Substitute blanks for tabs
tabs=char(ones(size(pmunames))*'	');
index=pmunames==tabs;
pmunames(index)=' ';
tabs=char(ones(size(phsrnames))*'	');
index=phsrnames==tabs;
phsrnames(index)=' ';
tabs=char(ones(size(comment))*'	');
index=comment==tabs;
comment(index)=' ';

%end of PSMT utility

