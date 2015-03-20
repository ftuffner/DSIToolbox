function [vecmat,vfill]=vec2mat(vecmat,vec,vfill);
% [timevecs]=vec2mat(timevecs,timefill);
%	
% Assemble column vectors of varying lengths into a matrix
% Fill unused locations with value vfill
% vecmat may be empty for first call
%
% Last modified 12/13/01.   jfh

if ~exist('vfill'), vfill=0;   end
if isempty(vfill),  vfill=-77; end

if min(size(vec))>1
  disp('In vec2mat: entry should be a vector, not an array')
  disp(['  Entry size = ' num2str(size(vec)) ' -- returning'])
  return
end

if size(vec,2)>size(vec,1)
  vec=vec';
end
%disp('In vec2mat:'); keyboard

if isempty(vecmat)
  vecmat=vec; return
end

nvec=length(vec);
[nrows ncols]=size(vecmat);

fillvec=ones(max(nrows,nvec),1)*vfill;
fillmat=ones(max(nrows,nvec),ncols)*vfill;
fillvec(1:nvec)=vec;
fillmat(1:nrows,1:ncols)=vecmat;
vecmat=[fillmat fillvec];

return

%end of PSMT utility

