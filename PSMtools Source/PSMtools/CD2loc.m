function [CDpath]=CD2loc(CDfile)
% CD2.m changes the present Matlab directory to that of CDfile
%
%  [CDpath]=CD2loc(CDfile)
%
% 
% Last modified 04/26/01.  jfh

CDpath='';

Nup=0;
if ~isempty(CDfile)
  command=['CDloc=which(' '''' CDfile '''' ');'];
  eval(command)
  if isempty(CDloc)
    disp(['File ' CDloc ' not found on Matlab path:'])
    disp('Directory not changed')
  return
  end
  ind=find(CDloc=='\'); 
  last=ind(max(size(ind))-Nup); 
  CDpath=CDloc(1:last);
end
disp(['Setting path to working directory: CD file = ' CDfile])
disp('User may want to customize this later')
command=['cd(' '''' CDpath '''' ');'];
eval(command);
str=cd; disp(['In CD2loc: Starting directory = ' str])

%End of PSMT utility