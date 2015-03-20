%unwrapN
% Small utility for phase unwrapping
%
%
%  Last modified 12/11/01.  jfh

vang=PSMsigsX(:,N); vang2=PSMunwrap(vang);
figure; plot(vang2)
PSMsigsX(:,N)=vang2;
CaseCom=str2mat(CaseCom,'Voltage angle has been unwrapped')

return

%end of PSMT utility
