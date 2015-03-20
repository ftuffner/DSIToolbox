function [CaseCom]=SWXdisp(caseID,casetime,CaseCom,namesX,PSMsigsX);
% Displays/prints powerflow data
%
% Functions provided:
%   
%
% PSMT utilities called from PSMload:
%
% Last modified 09/06/01.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

disp(['In SWXdisp:'])
keyboard

strs=['Powerflow display for ' caseID];
strs=str2mat(strs,CaseCom(1:2,:))

[maxpoints nsigs]=size(PSMsigsX);
for N=1:nsigs
  dline=['  ' num2str(PSMsigsX(1,N))];
  strs=str2mat(strs,namesX(N,:),dline);
end
disp(strs)

%end of PSMT utility
