function [chankey]=names2chans(names,locbase,Index)
%Construct channel key from channel names%
%
%  [chankey]=names2chans(names,locbase,Index)
%
%  Last modified =1/10/01.  jfh

ncols=size(names,1);
if ~exist('locbase'), locbase=1; end
if isempty(locbase),  locbase=1; end
locbase=max(0,locbase); locbase=min(1,locbase);
if ~exist('Index'), Index=[]; end
if length(Index)~=ncols, Index=[locbase:ncols+locbase-1]; end


linetxt=  ['%' sprintf('%4.0i',Index(1)) '  ' names(1,:)];
if Index(1)==0
  linetxt=['%'                   '   0'  '  ' names(1,:)];
end
chankey=str2mat(linetxt);
for N=2:ncols
  linetxt=['%' sprintf('%4.0i',Index(N)) '  ' names(N,:)];
  chankey=str2mat(chankey,linetxt);
end

%end of PSMT utility