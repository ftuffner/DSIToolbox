

function EventTime=funEventTimeSummary(kAlarmSeq,MinEventTimeDist,timeSeq)
%
%   Input Parameters:
%               kAlarmSeq:      A 'ascendly' sorted vector (steps)
%               MinEventTimeDist:   The miminum distance between two neigbor events (seconds)
%               timeSeq:        The time sequency
%   Output Parameters:
%               EventTime:      EventTime(:,1) is the start time of the events (seconds)
%                               EventTime(:,2) is the duration of the events (in seconds)
%
%                        
%   Create by Ning Zhou, 05/15/2006
%
if nargin<2, MinEventTimeDist=30*60; end
if nargin<3, timeSeq=1:kAlarmSeq(end); end

EventTime=[];
startRelTime=timeSeq(kAlarmSeq(1));
lastRelTime=timeSeq(kAlarmSeq(1));
for kIndex=1:length(kAlarmSeq)
    curRelTime=timeSeq(kAlarmSeq(kIndex));
    if curRelTime-lastRelTime < MinEventTimeDist              % in events minimum distance (steps) or event resolution
        lastRelTime=curRelTime;
    else
        endRelTime=lastRelTime;
        %save the events
        EventTime=[EventTime; startRelTime endRelTime-startRelTime];
        startRelTime=curRelTime;
        lastRelTime=curRelTime;
    end
end
endRelTime=curRelTime;
% save the events
EventTime=[EventTime; startRelTime endRelTime-startRelTime];
return
