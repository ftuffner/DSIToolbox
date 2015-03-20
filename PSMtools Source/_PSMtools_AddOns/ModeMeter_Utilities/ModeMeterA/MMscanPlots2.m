function [FlagDat]=MMscanPlots2(caseID,casetime,namesMM,time,MMsig,S1,C1,Nbar,Nshift,Dblocks,srateF,...
   TrackModes,TrackFrqs,autoaxis);
% Accessory plots for ModeMeter scans
%
% Developed by Dr. J. W. Pierre, U. Wyoming
%
% Last modified 10/23/00.  jfh
%
% Integration into PSM_Tools by J. F. Hauer, 
%   Pacific Northwest National Laboratory.

disp('In MMscanPlots2:')

FlagDat=[];

%*************************************************************************
%Generate case/time stamp for plots
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '  casetime=' casetime];
%*************************************************************************

%Temporary
Fintertie=TrackFrqs(1);
Falberta=TrackFrqs(2);

T=Nbar;
Tu=Nshift;

%Display all the modes in the s-plane for all the trials
h=figure;
plot(real(S1),imag(S1)/(2*pi),'x')
title('s-plane')
xlabel('real part of pole')
ylabel('imag part of pole / (2pi)')
axis([-0.5 0 0 1])

%display intertie mode
mode=1;
strt=T/2;
t1=(strt:Tu:(strt+(Dblocks-1)*Tu));
h=figure;
subplot(3,1,1)
plot(time,MMsig,'-')
ylabel('Signal Amplitude')
Ptitle{1}=['Intertie Mode from Signal ' namesMM(:,1)];
title(Ptitle)
subplot(3,1,2)
plot(t1/60,abs(imag(S1(mode,:)))/(2*pi),'+')  %plot freq vs t
ylabel('Frequency in Hertz')
%axis([t(1)/60 t(length(t))/60 0.25 0.35]);
%axis([t(1)/60 t(length(t))/60 0.24 0.32]);
if autoaxis~=1  %if autoaxis not equal to one
   axis([t(1)/60 t(length(t))/60 0.2 0.35]);
end
subplot(3,1,3)
plot(t1/60,-real(S1(mode,:))./abs(S1(mode,:)),'+') %plot damp rat vs t
ylabel('Damping Ratio')
if autoaxis~=1  %if autoaxis not equal to one
  axis([t(1)/60 t(length(t))/60 0.0 0.15]);
end
xlabel('Time in Minutes')

%Alberta 0.4 Hz mode
mode=2;
h=figure;
subplot(3,1,1)
plot(time,MMsig,'-')
ylabel('Signal Amplitude')
Ptitle{1}=['Alberta Mode from Signal ' namesMM(:,1)];
subplot(3,1,2)
plot(t1/60,abs(imag(S1(mode,:)))/(2*pi),'+')  %plot freq vs t
ylabel('Frequency in Hertz')
if autoaxis~=1  %if autoaxis not equal to one
   axis([t(1)/60 t(length(t))/60 0.3 0.45]);
end
subplot(3,1,3)
plot(t1/60,-real(S1(mode,:))./abs(S1(mode,:)),'+') %plot damp rat vs t
ylabel('Damping Ratio')
if autoaxis~=1  %if autoaxis not equal to one
  axis([t(1)/60 t(length(t))/60 0.0 0.15]);
end
xlabel('Time in Minutes')


%end of ModeMeter function