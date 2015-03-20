%Window Checks #3
%
% Last modified 09/02/99.  jfh

AngStep=1;  %Angle step in degrees
Asteps=fix(180/AngStep);
angles=[0:Asteps]';
Win1=sin(angles*2*pi/360);
Window=[Win1 Win1.^2 Win1.^4];
%set(gca,'xlim',[0 180])
h=figure;
plot(angles,Window)
title('Window Response Amplitude')
xlabel('Angle in Degrees'); Ylabel('Window Response Amplitude')
h=figure;
plot(angles,db(Window))
title('Window Response in dB')
xlabel('Angle in Degrees'); Ylabel('Window Response in dB')
set(gca,'ylim',[-100 20])
h=figure;
plot(angles,db(Window))
title('-3 dB Bandwidths')
xlabel('Angle in Degrees'); Ylabel('Window Response in dB')
set(gca,'ylim',[-3 2])

%end of jfh m-file

