function [StrN,TrimChar]=CharTrim(Str,TrimChar,StrEnd)
% Trim off leading or trailing characters of type TrimChar
% 
% Last modified 03/04/03.  jfh

tab='	'; TrimChar=tab;
StrN='';
if ~exist('Str'), Str=''; end
if isempty(Str), return, end

if nargin<1, disp('In CharTrim: No data - return'), return, end
if nargin<2, TrimChar=tab; end
if isempty(TrimChar), TrimChar=tab; end
if nargin<3, StrEnd='trailing'; end
if isempty(StrEnd), StrEnd='trailing'; end

%Trimming off trailing characters of type TrimChar
StrN=Str; chars=length(Str);
keep=find(Str~=TrimChar);
if isempty(keep), return, end
if ~isempty(findstr('trailing',lower(StrEnd)))
  StrN=Str(:,1:max(keep));
  return
end
if ~isempty(findstr('leading',lower(StrEnd)))
  StrN=Str(:,min(keep):chars);
  return
end

return

%end of PSMT utility