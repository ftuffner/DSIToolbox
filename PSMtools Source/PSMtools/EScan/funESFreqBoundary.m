function [Freq_AlarmTopLevel,Freq_AlarmPointsN,Freq_AlarmSeq]=...
    funESFreqBoundary(FreqSig,FreqBoundary,AlarmLevelN,figIndex,Alarm_Color,timeSeq,MyTitle,MyXLabel,MyYLabel,AlarmPlotLevel)
%
%   Input Parameters:
%               FreqSig:        One dimensional vector, which contains the signal to be examined
%               FreqBoundary:   A matrix define the boundary for alarm
%                               FreqBoundary(:,1) the level of alarm (a positive integer <=AlarmLevelN)
%                               FreqBoundary(:,2) the lower alarm boundary.
%                               FreqBoundary(:,3) the higher alarm boundary.
%               AlarmLevelN:   The number of alaram levels
%
%               [figIndex]:     Figure number to plot the figure
%               [Alarm_color]:  Color Code for alarm plots
%               [timeSeq]:      time sequence for plot out the alarm
%
%   Output Parameters:
%               Freq_AlarmTopLevel: The highest level of alaram. 0: no alarm
%               Freq_AlarmPointsN:  A array vector of length "AlarmLevelN". the
%                                   number of alarm points at each level;
%               [Freq_AlarmSeq]:    A cell vector of number of row as "FreqBoundary". The
%                                   index of sequence the points which cause the alarm
%
%   Note: [ ] means optional parameters
%                        
%   Written by Ning Zhou, 05/10/2006
%
%keyboard%
CSname='funESFreqBoundary';
%-------------------------------------
% 0.0 input check
if nargin<4
    FigurePlot=0;
else
    FigurePlot=1;
    if nargin<5, Alarm_Color=['k','g','b','y','r'];end
    if nargin<6, timeSeq=[1:length(FreqSig)]; end
    if nargin<7, MyTitle='';end
    if nargin<8, MyXLabel='Time';end
    if nargin<9, MyYLabel='Freq (Hz)';end
    if nargin<10, AlarmPlotLevel=2; end
end

ErrAlarmSeq=find(FreqBoundary(:,1)>AlarmLevelN);
if ~isempty(ErrAlarmSeq)
    disp(['In ' CSname ': Warning. Alarm level exceed the defined limitation. (Problem Corrected)']);
    FreqBoundary(ErrAlarmSeq,1)=AlarmLevelN;
end

Freq_TotalsN=length(FreqSig);
FreqAlarmN=size(FreqBoundary,1);

Freq_AlarmPointsN=zeros(AlarmLevelN,1,'double');
Freq_AlarmTopLevel=0;

if nargout>=3 || FigurePlot
    Freq_AlarmSeq=cell(FreqAlarmN,1);
end

%-------------------------------------
% 2.0 check for the out-of-boundary behaviors
for faIndex=1:FreqAlarmN                    % Freq alarm band loop
    tempFreqAlarm=uint32(find(FreqSig>=FreqBoundary(faIndex,2)...
                            & FreqSig<FreqBoundary(faIndex,3)));
    if ~isempty(tempFreqAlarm)    
        AlarmLevel=FreqBoundary(faIndex,1);
        if nargout>=3 || FigurePlot
            Freq_AlarmSeq{faIndex}=tempFreqAlarm;
        end
        
        Freq_AlarmPointsN(AlarmLevel)=Freq_AlarmPointsN(AlarmLevel)+length(tempFreqAlarm);
        
        if Freq_AlarmTopLevel<AlarmLevel
            Freq_AlarmTopLevel=AlarmLevel;
        end
   end
end
%keyboard%
if FigurePlot && Freq_AlarmTopLevel>=AlarmPlotLevel
    if isempty(figIndex)
        figIndex=figure;
    else
        figure(figIndex);
    end
    clf
    hold on
    plot(timeSeq,FreqSig, Alarm_Color(1));
    tempFreqLegend='Data';
    
    for aIndex=1:Freq_AlarmTopLevel
        if Freq_AlarmPointsN(aIndex)>0
            faSeq=find(FreqBoundary(:,1)==aIndex);
            tempFreqAlarm=[];
            for faIndex=1:length(faSeq)
                tempFreqAlarm=[tempFreqAlarm; Freq_AlarmSeq{faSeq(faIndex)}];
            end
           
            tempFreqLegend=str2mat(tempFreqLegend,['Alarm Level ', num2str(aIndex), ':  ',...
                num2str(Freq_AlarmPointsN(aIndex)/Freq_TotalsN*100,'%03.1f'), ' %'] );
            plot(timeSeq(tempFreqAlarm),FreqSig(tempFreqAlarm), [Alarm_Color(aIndex+1),'*']);
        end
    end
    legend(tempFreqLegend, 'Location', 'Best');
    xlabel(MyXLabel);
    ylabel(MyYLabel);
    title(MyTitle,'Interpreter','tex');
end


