

function EventTime=funEventSummary(kAlarmSeq,MinEventDist)
%
%   Input Parameters:
%               kAlarmSeq:      A 'ascendly' sorted vector
%               MinEventDist:   The miminum distance between two neigbor events
%
%   Output Parameters:
%               EventTime:      EventTime(:,1) is the start index of the events
%                               EventTime(:,2) is the duration of the events (in steps)
%
%                        
%   Create by Ning Zhou, 05/11/2006
%
if nargin<2
    MinEventDist=30*60;
end
EventTime=[];
startRelTime=kAlarmSeq(1);
lastRelTime=kAlarmSeq(1);
for kIndex=1:length(kAlarmSeq)
    curRelTime=kAlarmSeq(kIndex);
    if curRelTime-lastRelTime < MinEventDist              % in events minimum distance (steps) or event resolution
        lastRelTime=curRelTime;
    else
        endRelTime=lastRelTime;
        %save the events
        EventTime=[EventTime; startRelTime endRelTime-startRelTime+0.5];
        startRelTime=curRelTime;
        lastRelTime=curRelTime;
    end
end
endRelTime=curRelTime;
% save the events
EventTime=[EventTime; startRelTime endRelTime-startRelTime+0.5];
return
