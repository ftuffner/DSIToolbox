%***************************************
% Alarm definition
ESPara.Alarm_LevelN=4;                              % Number of Alarm levels                    
ESPara.Alarm_Color=['k','g','b','m','r'];
ESPara.Alarm_LevelPlot=2;                       % the alarm level above which a plot is going to be drawn.


% 2.2 Freq Alarm detection parameter definition
ESPara.FreqB_ES=1;           % 1, do the event scan for Freq boudary, 0, skip the event scan
Freq_Norm=60;                                       % in Hz  ES(EventScan)
ESPara.FreqB_Alarm=   [
                       4, Freq_Norm-20,    Freq_Norm-0.5;
                       3, Freq_Norm-0.5,    Freq_Norm-0.2;         % alarm level (1~4), lower limit(Hz), upper limit(Hz)
                       2, Freq_Norm-0.2,   Freq_Norm-0.05; 
                       1, Freq_Norm+0.05, Freq_Norm+0.2;
                       3, Freq_Norm+0.2,  Freq_Norm+0.5 
                       4, Freq_Norm+0.5,  Freq_Norm+20];        % frequency to triger the alarm
ESPara.FreqB_MinEventTimeDist=60;               % minimum time distance between two events (second). Two events which are close to each other is considered as on events.
                   
% 2.2 Voltage magnitude alarm detection parameter definition
ESPara.VM_ES=1;           % 1, do the event scan for Voltage Magnitude
VM_Norm=1.0;                                       % in pu  ES(EventScan)
ESPara.VMB_Alarm=    [
                      4, VM_Norm-0.99,    VM_Norm-0.5;
                      3, VM_Norm-0.5,  VM_Norm-0.3;
                      2, VM_Norm-0.3,  VM_Norm-0.15;         % alarm level (1~4), lower limit(p.u.), upper limit(p.u.)
                      1, VM_Norm-0.15, VM_Norm-0.08; 
                      1, VM_Norm+0.10, VM_Norm+0.2;
                      2, VM_Norm+0.20, VM_Norm+0.50;
                      4, VM_Norm+0.5,  VM_Norm+1
                      3, VM_Norm+1 ,  VM_Norm+10
                      ];        % VM to triger the alarm
ESPara.VMB_MinEventTimeDist=60;                  % minimum time distance between two events (second). Two events which are close to each other is considered as on events.