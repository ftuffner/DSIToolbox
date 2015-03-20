function [PickNo,PickName,pickOK,sequential]=PickList1(OptList,InPick,locbase,maxtrys,Index)
% Pick one choice from displayed options list
%
%
%  [Pick,PickName,pickOK,sequential]=PickList	1(OptList,InPick,locbase,maxtrys,Index);
%
% Index indicates special numbering of options.  Generally used when displayed
% options are a special subset of some external list.
%
% See also PickList2, names2chans
%
% Last modified 10/15/03.   jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

Noptions=size(OptList,1);
if ~exist('locbase'), locbase=[]; end
if isempty(locbase),  locbase=1; end
locbase=min(1,max(0,locbase));
if ~exist('maxtrys'), maxtrys=[]; end
if isempty(maxtrys),  maxtrys=5; end
maxtrys=max(maxtrys,1);
if ~exist('Index'), Index=[]; end
if length(Index)~=Noptions, Index=[]; end
if isempty(Index), Index=[locbase:Noptions+locbase-1]; end
IndSteps=Index(2:Noptions)-Index(1:Noptions-1);
sequential=isempty(find(IndSteps~=1));
if ~exist('InPick'), InPick=[]; end
PickNo=[];
if ~isempty(InPick)
  PickNo=find(Index==InPick);
  if ~isempty(PickNo), PickNo=InPick; end
end

OptListN=names2chans(OptList,locbase,Index);

%*************************************************************************
%Select option from provided list
default='n';
if ~isempty(PickNo), default='y'; end
if  isempty(InPick), default='';  end
pickOK=0;
for M=0:maxtrys
  if ~pickOK
    disp('Select desired option from list below: ')
    disp(OptListN)
    if sequential
      prompt=['   Enter ' num2str(Index(1)) ' to ' num2str(Index(Noptions))];
    else
      prompt=['   Enter value from index set [' num2str(Index) ']:'];
    end
    PickNo=promptnv(prompt,PickNo);
    if isempty(PickNo), PickNo=1; end
    PickNo=max(PickNo,min(Index)); PickNo=min(PickNo,max(Index)); 
    PickNoD=find(Index==PickNo);
    PickName=OptList(PickNoD,:);
 	  disp(['PickNo = ' num2str(PickNo) ': ' PickName])
    pickOK=promptyn('Is this ok?', default);
    default='y'; 
  else
    break
  end
end
if ~pickOK
  str1=sprintf('Sorry -%5i chances is all you get!',maxtrys);
  disp([str1,' Returning to invoking Matlab function.'])
  PickNo=[]; PickName=''; return
end
%*************************************************************************

%end of PSMT utility