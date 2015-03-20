%PSMT Utility PSDSnamesFix

tab='	';

[y,comment,fname,names]=cread('');
nsigs=size(names,1);
namesN=names; 
line=''; MaxLen=0;
for N=2:nsigs  %Replace tabs by blanks
  line=deblank(namesN(N,:));
  Ltabs=findstr(line,tab);
  if ~isempty(Ltabs), line(Ltabs)=' '; end
  LineLen=length(line);
  namesN(N,1:LineLen)=line;
  MaxLen=max(MaxLen,LineLen);
end
namesN=namesN(:,1:MaxLen);
