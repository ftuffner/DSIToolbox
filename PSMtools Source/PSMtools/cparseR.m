function [ValMat,count]=cparseR(String,del)
% Parsing delimited text string into numerical value array
% 
% Last modified 05/22/00.  jfh

ValMat=0;
tab='	';
if nargin<1, disp('In CparseR: No data-return'), return, end
if nargin<2, del=tab; end
if isempty(del), del=tab; end

%String=[String del];
[ValMat,count]=sscanf(String,'%f');

return

%end of PSM script