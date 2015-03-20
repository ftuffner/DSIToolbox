function [ClinesN]=BstringOut(Clines0,OutChar,MinOuts)
% Deletes long strings of undesirable characters that are 
% common to the rows of Clines.
%
%  [ClinesN]=BstringOut(Clines,OutChar,MinOuts);
% 
% Last modified 12/17/02.  jfh

tabchar='	';
StringN='';
if nargin<1, disp('In BstringOut: No data - return'), return, end
if nargin<2, OutChar=' '; end
if nargin<3, MinOuts=2; end
if isempty(OutChar), OutChar=' '; end
MinOuts=max(MinOuts,2);
%disp('In BstringOut:')

Clines=Clines0;
Clines=Char2Blank(Clines0); %Substitute blanks for tabs
Clines=deblank(Clines);
for Ntries=1:10

ClinesN=Clines;
[nlines nchars]=size(Clines);
Bind=zeros(nlines,nchars);
Bloc1=1; Bloc2=2;
Bstr=''; for n=1:MinOuts, Bstr=[Bstr OutChar]; end  
for L=1:nchars
  for N=1:nlines
    Bind(N,:)=zeros(1,nchars);
    Lbstr=findstr(Bstr,ClinesN(N,:)); 
    Bind(N,Lbstr)=1;
  end
  LBsum=sum(Bind,1);
  if max(LBsum)<nlines, break, end
  Bloc1=min(find(LBsum==nlines))+1; 
  Bloc2=Bloc1+length(Bstr)-1;
  Bstr=[Bstr OutChar];
end
if Bloc2>Bloc1+1
  ClinesN=ClinesN(:,[1:Bloc1 Bloc2:nchars]);
  Clines =ClinesN;
  %disp(['Removing surplus characters of type ' ''' ''' ' from character array'])
  %disp([Bloc1 Bloc2])
  %disp( 'Revised character array is')
  %disp(ClinesN)
end

end %Termination of Ntries loop

return

%end of PSMT function