%	Set decay rate standard
sigma=.1/30;
UnitMat=ones(1,9000);
% Scaling for PDC BPA1 in probing test 4/27/99
 
% Conversion Factors 
rd=180/pi;    % convert radians to degrees
dr=pi/180;    % convert degrees to radians

% Time array for x-axis values
Time = (0:1/30:(300-1/30));
% time=(0:rows-1)/samplerate-pretrigrows/samplerate;

% Subtract 120 degrees from Colstrip to handle transposition
pmu03phsr00=pmu03phsr00*exp(j*(-120)*dr);
pmu03phsr01=pmu03phsr01*exp(j*(-120)*dr);
pmu03phsr02=pmu03phsr02*exp(j*(-120)*dr);
pmu03phsr03=pmu03phsr03*exp(j*(-120)*dr);
pmu03phsr04=pmu03phsr04*exp(j*(-120)*dr);

% Convert Frequency values to Hertz
freq00=freq00/1000+60;
freq01=freq01/1000+60;
freq02=freq02/1000+60;
freq03=freq03/1000+60;
freq04=freq04/1000+60;
freq05=freq05/1000+60;
freq06=freq06/1000+60;
freq07=freq07/1000+60;
freq08=freq08/1000+60;


% Scale to Primary Values
pmu00phsr00=pmu00phsr00*27.25785;		% Grand Coulee Voltage--PMU0
pmu00phsr01=pmu00phsr01*0.161528;		% Grand Coulee 500-230 Bank Current
pmu00phsr02=pmu00phsr02*0.161528;		% Grand Coulee Hanford Current
pmu00phsr03=pmu00phsr03*0.242292;		% Grand Coulee Schultz #1 Current
pmu00phsr04=pmu00phsr04*0.161528;		% Grand Coulee Chief Joseph Current

pmu01phsr00=pmu01phsr00*27.053415;		% John Day Voltage--PMU1
pmu01phsr01=pmu01phsr01*0.096432;		% John Day Power House #1 Current
pmu01phsr02=pmu01phsr02*0.096432;		% John Day Power House #2 Current
pmu01phsr03=pmu01phsr03*0.096432;		% John Day Power House #3 Current
pmu01phsr04=pmu01phsr04*0.160720;		% John Day Power House #4 Current
pmu01phsr05=pmu01phsr05*0.160720;		% Big Eddy #1 & #2 Currents
pmu01phsr06=pmu01phsr06*0.160720;		% Grizzly #1 & #2 Currents
pmu01phsr07=pmu01phsr07*0.160720;		% Slatt #1 Current
pmu01phsr08=pmu01phsr08*0.160720;		% Marion #1 Current
pmu01phsr09=pmu01phsr09*0.160720;		% Hanford #1 Current

pmu02phsr00=pmu02phsr00*27.257850;		% Malin Voltage--PMU2
pmu02phsr01=pmu02phsr01*0.242292;		% Malin Round Mountain #1 Current
pmu02phsr02=pmu02phsr02*0.242292;		% Malin Round Mountain #2 Current
pmu02phsr03=pmu02phsr03*0.161528;		% Malin Grizzly #2 Current
pmu02phsr04=pmu02phsr04*0.161528;		% Malin Caption Jack #1 Current

pmu03phsr00=pmu03phsr00*27.257850;		% Colstrip Voltage--PMU3
pmu03phsr01=pmu03phsr01*0.161528;		% Colstrip Broadview #1 Current
pmu03phsr02=pmu03phsr02*0.161528;		% Colstrip Broadview #2 Current
pmu03phsr03=pmu03phsr03*0.088840;		% Colstrip Generator #3 Current
pmu03phsr04=pmu03phsr04*0.088840;		% Colstrip Generator #4 Current

pmu04phsr00=pmu04phsr00*12.114600;		% Big Eddy 230 voltage--PMU4
pmu04phsr01=pmu04phsr01*0.242292;		% Celilo #3 Current
pmu04phsr02=pmu04phsr02*0.242292;		% Celilo #4 Current
pmu04phsr03=pmu04phsr03*0.121146;		% Power House #3 Current
pmu04phsr04=pmu04phsr04*0.096917;		% Power House #4 Current
pmu04phsr05=pmu04phsr05*0.096917;		% Power House #5 Current
pmu04phsr06=pmu04phsr06*0.096917;		% Power House #6 Current
pmu04phsr07=pmu04phsr07*0.242292;		% Banks 2 & 5, 230:500 kV Current
pmu04phsr08=pmu04phsr08*0.121146;		% Midway #1 Current
pmu04phsr09=pmu04phsr09*0.096917;		% Troutdale #1 Current

pmu05phsr00=pmu05phsr00*27.257850;		% Big Eddy 500kV Voltage--PMU5
pmu05phsr01=pmu05phsr01*0.161528;		% Ostrander #1 Current
pmu05phsr02=pmu05phsr02*0.242292;		% Celilo #2 Current
pmu05phsr03=pmu05phsr03*0.242292;		% Celilo #1 Current
pmu05phsr04=pmu05phsr04*0.161528;		% John Day #1 & #2 Currents

pmu06phsr00=pmu06phsr00*7.268760;		% Sylmar Voltage--PMU6
pmu06phsr01=pmu06phsr01*0.201910;		% Rinaldi #1 Current
pmu06phsr02=pmu06phsr02*0.201910;		% Castaic #1 Current
pmu06phsr03=pmu06phsr03*0.201910;		% Bank E Current
pmu06phsr04=pmu06phsr04*0.323056;		% East Converter Current

pmu07phsr00=pmu07phsr00*12.114600;		% Maple Valley Voltage--PMU7
pmu07phsr01=pmu07phsr01*0.096917;		% SCL #1 Current
pmu07phsr02=pmu07phsr02*0.096917;		% SCL #3 Current
pmu07phsr03=pmu07phsr03*0.323056;		% Bank #2 Current
pmu07phsr04=pmu07phsr04*0.129222;		% Bank #1 Current

% did not scale Pmu08 from PhasorViewer
% Compute Complex Power Values
pmu00pow01=3*pmu00phsr00.*conj(pmu00phsr01);
pmu00pow02=3*pmu00phsr00.*conj(pmu00phsr02);
pmu00pow03=3*pmu00phsr00.*conj(pmu00phsr03);
pmu00pow04=3*pmu00phsr00.*conj(pmu00phsr04);

pmu01pow01=3*pmu01phsr00.*conj(pmu01phsr01);
pmu01pow02=3*pmu01phsr00.*conj(pmu01phsr02);
pmu01pow03=3*pmu01phsr00.*conj(pmu01phsr03);
pmu01pow04=3*pmu01phsr00.*conj(pmu01phsr04);
pmu01pow05=3*pmu01phsr00.*conj(pmu01phsr05);
pmu01pow06=3*pmu01phsr00.*conj(pmu01phsr06);
pmu01pow07=3*pmu01phsr00.*conj(pmu01phsr07);
pmu01pow08=3*pmu01phsr00.*conj(pmu01phsr08);
pmu01pow09=3*pmu01phsr00.*conj(pmu01phsr09);

pmu02pow01=3*pmu02phsr00.*conj(pmu02phsr01);
pmu02pow02=3*pmu02phsr00.*conj(pmu02phsr02);
pmu02pow03=3*pmu02phsr00.*conj(pmu02phsr03);
pmu02pow04=3*pmu02phsr00.*conj(pmu02phsr04);

pmu03pow01=3*pmu03phsr00.*conj(pmu03phsr01);
pmu03pow02=3*pmu03phsr00.*conj(pmu03phsr02);
pmu03pow03=3*pmu03phsr00.*conj(pmu03phsr03);
pmu03pow04=3*pmu03phsr00.*conj(pmu03phsr04);

pmu04pow01=3*pmu04phsr00.*conj(pmu04phsr01);
pmu04pow02=3*pmu04phsr00.*conj(pmu04phsr02);
pmu04pow03=3*pmu04phsr00.*conj(pmu04phsr03);
pmu04pow04=3*pmu04phsr00.*conj(pmu04phsr04);
pmu04pow05=3*pmu04phsr00.*conj(pmu04phsr05);
pmu04pow06=3*pmu04phsr00.*conj(pmu04phsr06);
pmu04pow07=3*pmu04phsr00.*conj(pmu04phsr07);
pmu04pow08=3*pmu04phsr00.*conj(pmu04phsr08);
pmu04pow09=3*pmu04phsr00.*conj(pmu04phsr09);

pmu05pow01=3*pmu05phsr00.*conj(pmu05phsr01);
pmu05pow02=3*pmu05phsr00.*conj(pmu05phsr02);
pmu05pow03=3*pmu05phsr00.*conj(pmu05phsr03);
pmu05pow04=3*pmu05phsr00.*conj(pmu05phsr04);

pmu06pow01=3*pmu06phsr00.*conj(pmu06phsr01);
pmu06pow02=3*pmu06phsr00.*conj(pmu06phsr02);
pmu06pow03=3*pmu06phsr00.*conj(pmu06phsr03);
pmu06pow04=3*pmu06phsr00.*conj(pmu06phsr04);  % East Converter Current


pmu07pow01=3*pmu07phsr00.*conj(pmu07phsr01);  % SCL #1 Current
pmu07pow02=3*pmu07phsr00.*conj(pmu07phsr02);
pmu07pow03=3*pmu07phsr00.*conj(pmu07phsr03);
pmu07pow04=3*pmu07phsr00.*conj(pmu07phsr04);

% Total Malin - Round Mt Power in MW
MALRM=(real(pmu02pow01)+real(pmu02pow02))/1000000;
% Celilo 3~4 AC Power in MW
Celilo34=(real(pmu04pow01)+real(pmu04pow02))/1000000;
% Celilo 1~2 AC Power in MW
Celilo12=(real(pmu05pow02)+real(pmu05pow03))/1000000;
% Total Celilo AC Power
CeliloAC=Celilo12+Celilo34;
% Compute mean values
CeliloMean=Mean(CeliloAC);
MALRMMean=Mean(MALRM);
Ijump=0;
%  Define vectors with mean removed
MALRMZ=MALRM-UnitMat*MALRMMean;
CeliloACZ=CeliloAC-UnitMat*CeliloMean;
