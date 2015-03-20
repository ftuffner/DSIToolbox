function [Freq, DR]=funFindModes(sPoles);
% JPierre utility for mode display
% function [Freq, DR]=funFindModes(sPoles);
%
% Modified 05/18/04.  jfh  Longer fields for numerical display

[Y,I]=sort(imag(sPoles));
sPoles=sPoles(I);
Freq=imag(sPoles)./(2*pi);
DR=-100*real(sPoles)./abs(sPoles);

%***********************************************************************************
if nargout == 0,   % do plots
    Np=length(sPoles);
    disp('     ')
    disp('Major Modes:');
    disp('Frequency(Hz)    Damping Ratio(%)');
    disp('----------------------------------');
    for nIndex=1:Np
      disp(sprintf('freq=%14.8f      DR=%14.8f ', Freq(nIndex),DR(nIndex)));
    end
    disp('----------------------------------');
end
%***********************************************************************************

