function [StrMat]=cparse(String,del)
% Parsing tab-delimited text string into text array
% 
% Last modified 03/29/00.  jfh

StrMat=0;
tab='	';
if nargin<1, disp('In Cparse: No data-return'), return, end
if nargin<2, del=tab; end
if isempty(del), del=tab; end


String=[String del];
len=size(String,2);
loc=[0 findstr(String,del)];
NF=size(loc,2)-1;   %number of text fields
for n=1:NF
  span=loc(n+1)-loc(n)-1;
  text='';
  if span>0, text=String(loc(n)+1:loc(n+1)-1); end
  if n==1, StrMat=text;
    else StrMat=str2mat(StrMat,text); 
  end
end

%end of PSM script