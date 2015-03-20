%
% Copyright Battelle Memorial Institute.  All Rights Reserved."
%
% PDCDataReaderDemo Configuration File
% Created on 17-Feb-2006 16:15:23
%  keyboard;
% PDC .INI file and UDP port
% PDCConfigFile      = 'C:\d3p045\DSTini\BPA2_060508.ini';
% PDCMatFile      = 'C:\d3p045\DSTini\BPA2_060508.ini';
% PDCUDPPort         = 3050;
% PDCConfigFile      = 'C:\d3p045\TVA_PDC.INI';
% PDCUDPPort         = 3077;
%
% Time series plot parameters
%
PlotWindowSec      = 15;
% Fourier analysis parameters
DFTWindowLength    = 1024;
DFTWindowOverlap   = 768;
xNote=[];
sNote=[];
DRBorder=[0, 5, 10, 20];
TopSpeed=10;

ModelType          =1;          % 0 for AR model
                                % 1 for ARMA model

SaveModeFileName='SavedMode.txt';
SaveMode=1;

% AR Model parameters
%aOrder=45;
%ForgTimeConst=120;                              % memory time constant (sec) see page 378 eq(11.65a)
WindowLength=5*60;                               % Limited window size in (sec) =0 means infinite window length
%ForgTimeConst=10*60;                           % memory time constant (sec) see page 378 eq(11.65a)

% ARMA Model parameters
aOrder2=30;                    %30    order of AR
bOrder2=25;                    %25     order of X
cOrder2=5;                     %5      order of MA
kOrder2=1;
NumMajorPoles=5;
if NumMajorPoles>(aOrder2/2)
    NumMajorPoles=floor(aOrder2/2);
end

%lModel=1;                       % number of data channels
delta2=4;

%------------------------------------
% start: Parameter for mode initialization
IniModeFreq=[0.26; 0.455];
IniModeDR=[5.; 10];
IniModeWeight=[0; 0];

%handles.IniModeWeight
% temp=IniModeFreq*2*pi;
% Poles=temp.*cot(acos(-IniModeDR/100))+j*temp;
% funPole2mode(Poles);
% end: Parameter for mode initialization
%--------------------------------------

%keyboard;
ForgTimeConst02=2*60;       % Limited window size in (sec) =0 means infinite window length
PDCMatPath=[pwd, '\'];     
PDCMatFile='Current.mat';
sigIndxInput=0;     % Input channel index  0 means no injection
sigIndx=2;          % output channel index
        
