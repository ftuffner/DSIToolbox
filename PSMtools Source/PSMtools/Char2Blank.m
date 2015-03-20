function [ClinesN]=Char2Blank(Clines,BlankChar)
% Substitute blanks for characters of type BlankChar
%
%  [ClinesN]=Char2Blank(Clines,BlankChar);
% 
% Last modified 07/22/03.  jfh

tabchar='	';
StringN='';
if nargin<1, disp('In Char2Blank: No data - return'), return, end
if nargin<2, BlankChar=tabchar; end
if ~exist('Clines'), Clines=''; end
if isempty(BlankChar), BlankChar=tabchar; end

ClinesN='(No Comment Lines)';
if isempty(Clines), disp('In Char2Blank: No data - return'), return, end
nlines=size(Clines,1);
for N=1:nlines  %Replace entries of type BlankChar by blanks
  %line=deblank(ClinesN(N,:));
   line=Clines(N,:);
  LBchar=findstr(line,BlankChar);
  if ~isempty(LBchar), line(LBchar)=' '; end
  if N==1
    ClinesN=line;
  else
    ClinesN=str2mat(ClinesN,line);
  end
end

return

%end of PSMT function