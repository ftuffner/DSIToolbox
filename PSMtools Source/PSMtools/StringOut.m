function [ClinesN]=StringOut(Clines,OutChar)
% Deletes long strings of OutChar characters that are common
% to the rows of Clines
%
%  [ClinesN]=StringOut(Clines,OutChar);
% 
% Last modified 01/25/02.  jfh

tabchar='	';
StringN='';
if nargin<1, disp('In StringOut: No data - return'), return, end
if nargin<2, OutChar=' '; end
if isempty(OutChar), OutChar=' '; end

ClinesN=Clines;
[nlines nchars]=size(Clines,1);
Bind=zeros(nlines,nchars);
MinBks=5; Bloc1=1; Bloc2=2;
Bstr=''; for n=1:MinBks, Bstr=[Bstr OutChar]; end  
for L=1:chars
  for N=1:nlines
    Bind(N,:)=zeros(1,nchars);
    Lbstr=findstr(Bstr,ClinesN(1,:)); 
    Bind(N,Lbstr)=1;
  end
  LBsum=sum(Bind,1);
  if max(LBsum)<nlines, break, end
  Bloc1=min(find(LBsum==nlines))+1; 
  Bloc2=Bloc1+length(Bstr)-3;
  Bstr=[Bstr OutChar];
end
if Bloc2>Bloc1+1
  disp(['Removing surplus characters of type ' ''' ''' ' from character array'])
  disp( 'Revised character array is')
  ClinesN=ClinesN(:,[1:Bloc1 Bloc2:nchars]);
  disp(ClinesN)
end

return

%end of PSMT function