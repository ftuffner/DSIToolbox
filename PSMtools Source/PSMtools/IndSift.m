function [IndexC,IndexD]=IndSift(IndexA,IndexB)
% IndexC = all integers in IndexA that are not in IndexB
% IndexD = all integers in IndexA that are in IndexB
%
%  Last modified 12/31/01.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

lenA=length(IndexA);
IndexC=[]; IndexD=[];
for N=1:lenA
  test=find(IndexA(N)==IndexB);
  if isempty(test)
    IndexC=[IndexC IndexA(N)];
  else
    IndexD=[IndexD IndexA(N)]; 
  end
end

return

%end of PSMT function