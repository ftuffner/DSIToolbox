function [FAlias]=Alias1(F,Srate);
%Determine aliased frequency for a sine wave of frequency F,
%when sampled at Srate samples per second
%  [FAlias]=Alias1(F,Srate);
%
% Last modified 01/09/04.   jfh

%Srate=50; F=[-1.08;118.92;57.84;177.84;116.76;236.76];
FN=Srate/2; %Nyquist frequency
FAlias=F*0;
for I=1:length(F)
  FA=mod(F(I),Srate); 
  if FA>FN, FA=FA-Srate; end; 
  FAlias(I)=FA;
end

if min(FAlias)<0
  disp('In Alias1: Negative frequencies in output')
end

%end of PSMT function

