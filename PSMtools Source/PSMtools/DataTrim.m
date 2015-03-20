function y = DataTrim(data,range)
%
% function y = DataTrim(data,range)
%				   
% All DATA values are trimmed to lie within RANGE values.
%
% It is useful to examine the details of Matlab plots
% through commands such as
%
%    set (gca,'xlim',xrng)
%
% However, clipboard copies of such plots may exhibit 
% trace "runovers" when pasted into other applications. 
% DataTrim is a simple workaround to this problem.

y=max(data,range(1));
y=min(y,range(2));

%end of PSM script
