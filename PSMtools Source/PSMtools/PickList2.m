function [PickVec,PickNames,pickOK]=PickList2(OptList,InPick,locbase,maxtrys,Index)
% Pick multiple choices from displayed options list
%
%  [Pick,PickNames,pickOK]=PickList2(OptList,InPick,locbase,maxtrys,Index);
%
% See also PickList1, names2chans
%
% Last modified 06/27/03.   jfh

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
if isempty(maxtrys),  maxtrys=10; end
maxtrys=max(maxtrys,1);
if ~exist('Index'), Index=[]; end
if length(Index)~=Noptions, Index=[]; end
if isempty(Index), Index=[locbase:Noptions+locbase-1]; end
IndSteps=Index(2:Noptions)-Index(1:Noptions-1);
sequential=isempty(find(IndSteps~=1));
if ~exist('InPick'), InPick=[]; end
if isempty(InPick), PickVec=Index(1);
else
  PickVec=[];
  for n=1:length(InPick)
    if find(InPick(n)==Index), PickVec=[PickVec InPick(n)]; end 
  end
end

disp('Select desired options from list below: ')
OptListN=names2chans(OptList,locbase,Index);
disp(OptListN)

%*************************************************************************
%Select option from provided list
default='n';
if ~isempty(InPick), default='y'; end
for M=0:maxtrys
  PickVecD=[];
  for n=1:length(PickVec)
    PickVecD=[PickVecD find(PickVec(n)==Index)]; 
  end
  if isempty(PickVecD) PickVecD=1; end
  disp(' ')
  disp('Present selections shown below:')
  disp(OptListN(PickVecD,:))
  pickOK=promptyn('Is this ok?', default);
  default='y'; 
  if M==maxtrys, break, end
  if ~pickOK
    disp(' ')
    disp('Update selection vector shown below: ')
	  PickVecS=['val=[' num2str(PickVec) ']'];
    disp(PickVecS)
	  disp('Invoking "keyboard" command - Enter "return" when you are finished')
    val=1; %Assure nonempty value
    keyboard
    PickVec=val;
  else
    PickNames=OptList(PickVecD,:); break
  end
end
if ~pickOK
  str1=sprintf('Sorry -%5i chances is all you get!',maxtrys);
  disp([str1,' Returning to invoking Matlab function.'])
  PickVec=[]; PickNames=''; return
end
%*************************************************************************

%end of PSMT function