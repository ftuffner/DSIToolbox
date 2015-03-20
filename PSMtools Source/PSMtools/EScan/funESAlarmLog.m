function logReady=funESAlarmLog(logFileName, Freq_AlarmSeq, FreqBoundary, MinEventTimeDist,aRefTime, tstep, timeSeq,...
    Alarm_Source, Alarm_Triggering, Alarm_Notes, Level_Unit)   
% Input Parameters:
%               logFileName:    File name to store the alarm log Or a opened file handle
%               Freq_AlarmSeq:  A cell vector of number of row as "FreqBoundary". The
%                               indexes of sequence points which cause the
%                               alarm.
%               FreqBoundary:   A matrix define the boundary for alarm
%                               FreqBoundary(:,1) the level of alarm (a positive integer <=AlarmLevelN)
%                               FreqBoundary(:,2) the lower alarm boundary.
%                               FreqBoundary(:,3) the higher alarm
%                               boundary.
%           MinEventTimeDist:   Minimum time distance between two events (second).
%                 aRefTime:     Reference time in matlab format
%                 tstep:        sampling interval (second)
%               timeSeq:        The time sequence of the original signals(see the Freq_AlarmSeq )
%               Alarm_Source:   The source of alarm (e.g. 'Freq Event Scan')
%           Alarm_Triggering:   (e.g. 'Malin VM')
%           Alarm_Note:         (e.g. notation);
%
%   Written by Ning Zhou, 05/10/2006

if nargin<8, Alarm_Source='Event Scan'; end
if nargin<9, Alarm_Triggering='N/A'; end
if nargin<10, Alarm_Notes='N/A';end
if nargin<11, Level_Unit='Unknown';end

%MinEventDist=fix(MinEventTimeDist/tstep);

CSname='funESAlarmLog';
%keyboard
aRefTimeV=datevec(aRefTime);
if isstr(logFileName)
    fidESFreq = fopen(logFileName, 'a');        % if the file name is inputed
else
    fidESFreq =logFileName;                     % if the file handle is inputed
end

if fidESFreq<0
    disp(' ');
    disp(['In ', CSname, ':',sprintf('Can not open [ %s ] for writing.',logFileName)]);
    disp(' ');
%   disp('Press any key to continue...');  pause;
    fidESFreq=1;
    fprintf(fidESFreq,'\t\t\t\t   Date\t    Time\t Duration\t Level\t Low\t High \t unit \tSource')
    fprintf(fidESFreq,'\t Signal \tNotes')
    fprintf(fidESFreq,'\n')
else
    posESFreq = ftell(fidESFreq);
    if ~posESFreq       % write the head of the event scan file
        fprintf(fidESFreq,'\t\t\t\t Alarm Date\t Alarm Time\t Alarm Duration (min) \t Alarm Level \tLevel Low \t Level High \t Level Unit \t Alarm Source  ')
        fprintf(fidESFreq,'\t Triggering Signal  \t Notes')
        fprintf(fidESFreq,'\n')
    end
end
    
for aIndex=1:size(FreqBoundary,1)
    if isempty(Freq_AlarmSeq{aIndex})
       continue;
    end
    
   
    kAlarmSeq=Freq_AlarmSeq{aIndex};
            
   % EventStep=funEventSummary(kAlarmSeq,MinEventDist);    % convert step to seconds
   % EventTime=tstep*double(EventStep);
    %keyboard%
    EventTime=funEventTimeSummary(kAlarmSeq,MinEventTimeDist,timeSeq);    % convert step to seconds
    
    Alarm_Level=FreqBoundary(aIndex,1);
    Alarm_RangleLow=FreqBoundary(aIndex,2);
    Alarm_RangleHigh=FreqBoundary(aIndex,3);


    
    for etIndex=1:size(EventTime,1)
        startSecV=EventTime(etIndex,1)+aRefTimeV(6);
        Alarm_StartTime=datenum([aRefTimeV(1:5),startSecV]);
        Alarm_Duration=EventTime(etIndex,2)/60;
             
        startDateStr=datestr(Alarm_StartTime, 'yyyy/mm/dd');
        startTimeStr=datestr(Alarm_StartTime, 'HH:MM:SS');
                
        fprintf(fidESFreq,'\t\t\t\t%s',startDateStr);
        fprintf(fidESFreq,'\t%s',startTimeStr);
        fprintf(fidESFreq,'\t%3.1f',Alarm_Duration);
        fprintf(fidESFreq,'\t%d',Alarm_Level);
        fprintf(fidESFreq,'\t%04.3f',Alarm_RangleLow);
        fprintf(fidESFreq,'\t%04.3f',Alarm_RangleHigh);
        fprintf(fidESFreq,'\t%s', Level_Unit);
        fprintf(fidESFreq,'\t%s',Alarm_Source);
        fprintf(fidESFreq,'\t%s',Alarm_Triggering);
        fprintf(fidESFreq,'\t%s',Alarm_Notes);
        fprintf(fidESFreq,'\n');
    end
end

        
if fidESFreq>2
    if isstr(logFileName)
        fclose(fidESFreq);
    end
    logReady=1;
else
    logReady=0;
end