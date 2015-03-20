function [CaseComES,SaveFileES,namesES,TRangeES,ESAlarmLogReady, ESAlarmLevel]...
    =EventScan1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
    chansA,TRange,tstep,decfac, EScanpars);

% EventScan1 scans for fast distrubances 
%
%	 [CaseComES,SaveFileES,namesES,TRangeES,tstepES,...
%   ESAlarmLevel]...
%   =EventScan1(caseID,casetime,CaseCom,namesX,PSMsigsX(n1:n2,:),...
%    chansA,TRange,tstep,decfac,...
%    SigMeans,,EScanpars);

%
% INPUTS:
%    caseID       name for present case
%    casetime     time when present case was initiated
%    CaseCom      case comments
%    namesX       signal names
%    PSMsigsX     signal data to be processed
%    chansA       indices for signals to analyze
%    TRange       time range for analysis
%    tstep        time step for PSMsigsX
%    decfac		    decimation factor
%    
%    EScanpars     (spare object for later use)
%
% OUTPUTS:
%    CaseComES    case comments
%    SaveFileES   (not used)
%    namesES       names for signals analyzed
%    TRangeES      time range of actual analysis
%    tstepES       time step for PSMsigsX after decimation
%
% PSM Tools called from EventScan1:
%   CaseTags
%   ShowRange
%   CaseComPlot
%   promptyn, promptnv
%
% NOTES:
%
%  Last modified 02/19/01.   jfh
%  Last modified 05/11/06.   zn


%*********************************************************************
%% 0.0 Parameter initialization
if 0        % 1 for test purpose only
    keyboard
    global PhsrNames VIcon
    global Kprompt ynprompt nvprompt
    global PSMtype CFname PSMpaths PSMfiles PSMreftimes 
    save AllDataIn_EvenScan1
    return
elseif 0    % 1 for test purpose only
    clear 
    clc
    close all
    load AllDataIn_EvenScan1
end

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMpaths PSMfiles PSMreftimes
global PhsrNames VIcon
global PSMMacro

CSname='EventScan1';
disp(' ')
disp(['In ' CSname ': Start (Testing Code)'])

%Clear outputs
CaseComES=''; SaveFileES='';
namesES=namesX; TRangeES=TRange; ESAlarmLogReady=0; ESAlarmLevel=0;

chansAstr=chansA;
if ~ischar(chansAstr)
  chansAstr=['chansA=[' num2str(chansAstr) '];'];
end
eval(chansAstr);
chankeyX=names2chans(namesX,1);

%*************************************************************************
% 0.2 Generate case identification, for stamping on plots and other outputs  
%setok=promptyn('In EventScan1: Generate new case tags?', 'n');
setok=0;
%keyboard
if setok
  disp(['Generating new case tags for case ' caseID ':'])
  [caseID,casetime,CaseComES,Gtags]=CaseTags(caseID);
  CaseComES=str2mat('New case tags in EventScan1:',CaseComES,CaseCom);
else
  CaseComES=CaseCom;
  Gtags=str2mat(caseID,casetime);
end
%*************************************************************************

%*************************************************************************
% 0.4 Determine record time parameters
maxpoints=size(PSMsigsX,1);
nsigsX=size(PSMsigsX,2);
str=lower(namesX(1,:));
%keyboard%
if findstr(str,'time')
  startchan=2;
  timeSeq=PSMsigsX(:,1);
  RTmin=timeSeq(1);
  RTmax=timeSeq(maxpoints);
  tstart=max(RTmin,TRange(1)); tstop=min(RTmax,TRange(2));
else
  startchan=1;
  RTmax=(size(PSMsigsX,1)-1)*tstep;
  timeSeq=(0:tstep:RTmax);
  RTmin=timeSeq(1);
  RTmax=timeSeq(maxpoints);
  tstart=RTmin; tstop=RTmax;
end
disp(['In ', CSname, ':', sprintf('  [maxpoints nsigsX] = %6.0i %4.0i', maxpoints, nsigsX)]);
disp(['In ', CSname, ':', sprintf('  Record time span   = %6.2f %6.2f', RTmin,RTmax)]);
%*************************************************************************


%ESPara.Alarm_LevelN=4;                              % Number of Alarm levels                    
%ESPara.Alarm_Color=['k','g','b','y','r'];

if ~isfield(PSMMacro, 'EventScan1_LogFname'), PSMMacro.EventScan1_LogFname=''; end
if isempty(PSMMacro.EventScan1_LogFname)
    CurDateStr=datestr(now,'yyyymmddHHMM');
    PSMMacro.EventScan1_LogFname=['ESlog', CurDateStr,'.xls'];
end

if ~isfield(PSMMacro, 'EventScan1_PathName'), PSMMacro.EventScan1_PathName=''; end
if ~isdir(PSMMacro.EventScan1_PathName)
    if isempty(PSMpaths)
        [ScanFiles, PSMpaths, FileType]=PSMscanDirectory('', '', 'dst');
    end
    PSMMacro.EventScan1_PathName=PSMpaths(1,:);
end

logFileName=[PSMMacro.EventScan1_PathName,PSMMacro.EventScan1_LogFname];

if ~isfield(PSMMacro, 'EventScan1_PSMfilesIndex'), PSMMacro.EventScan1_PSMfilesIndex=1; end
if PSMMacro.EventScan1_PSMfilesIndex>1
   fidESLog=fopen(logFileName, 'a');        % open a file to add
else
    fidESLog=fopen(logFileName, 'w');       % open a new file to write
end

if fidESLog<0
    disp(' ');
    disp(['In ', CSname, ':',sprintf('Can not open [ %s ] for writing.',logFileName)]);
    disp('The result is going to be displayed on the screen.');
    disp('press any key to continue... ');pause;
    fidESLog=1;
    fprintf(fidESLog,'\t\t\t\t   Date\t    Time\t Duration\t Level\t Low\tHigh \tunit \t Source  ');
    fprintf(fidESLog,'\t Signal\tNotes');
    fprintf(fidESLog,'\n');
else
    ESAlarmLogReady=1;
    posESFreq = ftell(fidESLog);
    fprintf(fidESLog,'%s\n', PSMpaths(1,:));
    for fIndex=1:size(PSMfiles,1)
        fprintf(fidESLog,'\t%s\n', PSMfiles(fIndex,:));
    end

    if ~posESFreq       % write the head of the event scan file
        fprintf(fidESLog,'\t\t\t\t Alarm Date\t Alarm Time\t Alarm Duration (min) \t Alarm Level\tLevel Low \t Level High \t Level Unit\t Alarm Source  ');
        fprintf(fidESLog,'\t Triggering Signal  \t Notes');
        fprintf(fidESLog,'\n');
    end
end

EventScan1_config;    %load the event scan paramters.    
%*************************************************************************
%% 2.0 Start frequency boundary scan


if ~ESPara.FreqB_ES 
    disp(['In ' CSname ': Skip system frequency scan']);
else
    disp(' ')
    disp(' ')
    disp(['In ' CSname ': Start system freq scan']);
     % 2.4 Find the Frequency Channels Index
    chFreqSeq=funFindStr(namesX(:,end-6:end), 'freq');
    chFreqCount=length(chFreqSeq); 
    if chFreqCount<=0
       disp(['In ' CSname ': No Freq signal was found.']);
    else
        % 2.6 Check the Median of Freq
        %FreqAlarmN=size(ESPara.FreqB_Alarm,1);
        %FreqAlarmSeq=cell(chFreqCount, FreqAlarmN);
        %keyboard%
        tempN=min([3,chFreqCount]);
        for fcIndex=1:tempN
            if  chFreqCount>3
                switch fcIndex
                    case 1
                        FreqSigMed=median(PSMsigsX(:,chFreqSeq(:)),2);
                        MySignal='System Median Frequency';
                    case 2
                        FreqSigMed=max(PSMsigsX(:,chFreqSeq(:)),[],2);
                        MySignal='System Max Frequency';
                    case 3
                        FreqSigMed=min(PSMsigsX(:,chFreqSeq(:)),[],2);
                        MySignal='System Min Frequency';
                end
            else
                FreqSigMed=PSMsigsX(:,chFreqSeq(fcIndex));
                MySignal=namesX(chFreqSeq(fcIndex),:);
                %fcIndex=3;
            end
            
            % record the events to be scanned
            %if PSMMacro.EventScan1_PSMfilesIndex<=1
            %    fprintf(fidESLog,'\t\tFreq: %s\n',MySignal);
            %end
            
            MyXLabel='Time (sec)';
            MyYLabel='Freq (Hz)';
            MyTitle={['\fontsize{14}' MySignal], ['\fontsize{8}(Ref time: ', PSM2Date(PSMreftimes(1)), ')']};
            
            [ESReport.Freq_AlarmTopLevel,ESReport.Freq_AlarmPointsN,ESReport.Freq_AlarmSeq]=...
                funESFreqBoundary(FreqSigMed,ESPara.FreqB_Alarm,ESPara.Alarm_LevelN, [],ESPara.Alarm_Color,timeSeq,MyTitle,MyXLabel,MyYLabel,ESPara.Alarm_LevelPlot);
        
            if ESAlarmLevel<ESReport.Freq_AlarmTopLevel
                ESAlarmLevel=ESReport.Freq_AlarmTopLevel;
            end

            % 2.8 write the frequency Event Scan report.
            if ESReport.Freq_AlarmTopLevel
                aRefTime=PSM2Date(PSMreftimes(1));
                Alarm_Source='Freq Scan';
                Alarm_Triggering=MySignal;
                Alarm_Notes='N/A';
                ESAlarmLogReady=funESAlarmLog(fidESLog, ESReport.Freq_AlarmSeq, ESPara.FreqB_Alarm, ESPara.FreqB_MinEventTimeDist,...
                    aRefTime, tstep, timeSeq, Alarm_Source, Alarm_Triggering, Alarm_Notes, 'Hz');
            end
            if fcIndex>=3, break;end
        end
        disp(' ')
        disp(' ')
        disp(['In ' CSname ': End (Frequency Scanning)'])
    end
end
% 2.0 End frequency boundary scan 
%*************************************************************************



%*************************************************************************
%% 4.0 Start Voltage Magnitude (VM) boundary scan 
if ~ESPara.VM_ES
    disp(['In ' CSname ': Skip voltage magnitude scan']);
else
    disp(' ')
    disp(' ')
    disp(['In ' CSname ': Start system voltage magnitude scan']);
    % 4.2 find the Voltage magnitude channels
    chVMSeq=funFindStr(namesX(:,end-6:end), 'VMag');
    chVMCount=length(chVMSeq);
    
     %4.4 find the base voltage for Voltage magnitude
     [NumMaxPhasor,temp,NumPMU]=size(VIcon);
     rawPHRName=[];     % phasor names for voltage
     rawBaseVolt=[];
     for pmuIndex=1:NumPMU
         tempSeq=find(VIcon(:,1,pmuIndex)==1);      % find all the voltage phasor in current PMU
         rawBaseVolt=[rawBaseVolt;VIcon(tempSeq,6,pmuIndex)];
         rawPHRName= [rawPHRName;PhsrNames(tempSeq,:,pmuIndex)];
     end
     NumVPhasor=length(rawBaseVolt);
     fnlBaseVolt=NaN*ones(chVMCount,1);
     for chIndex=1:chVMCount
         tempName=deblank(namesX(chVMSeq(chIndex),1:end-7));
         for pIndex=1:NumVPhasor
             if strcmp(tempName, deblank(rawPHRName(pIndex,:)))
                 fnlBaseVolt(chIndex)=rawBaseVolt(pIndex);
                 break;
             end
         end
    end
    bBaseVoltUnavail=isnan(fnlBaseVolt);
    NumBaseVoltUnavail=sum(bBaseVoltUnavail);
    if NumBaseVoltUnavail>0
        SeqBaseVoltUnavail=find(bBaseVoltUnavail==1);
        disp(['In ', CSname, ':', 'The base voltages of the following channels are not available']);
        disp(namesX(chVMSeq(SeqBaseVoltUnavail),:));
        disp('500 KV is assumed as a default');
        disp('press any key to continue...'); pause;
        fnlBaseVolt(SeqBaseVoltUnavail)=500;
    end
    


    for chIndex=1:chVMCount
        %4.6 find the voltage over limits
        MySignal=namesX(chVMSeq(chIndex),:);
        MyXLabel='Time (sec)';
        MyYLabel='Voltage Magnitude (p.u.)';
        MyTitle={['\fontsize{14}' MySignal], ['\fontsize{8}(Ref time: ', PSM2Date(PSMreftimes(1)), ')']};
        % record the events to be scanned
        %if PSMMacro.EventScan1_PSMfilesIndex<=1
        %    fprintf(fidESLog,'\t\tVM: %s\n',MySignal);
        %end
        VMSig=PSMsigsX(:,chVMSeq(chIndex))/fnlBaseVolt(chIndex);    % convert the voltage into p.u.
        [ESReport.VMB_AlarmTopLevel,ESReport.VMB_AlarmPointsN,ESReport.VMB_AlarmSeq]=...
        funESFreqBoundary(VMSig,ESPara.VMB_Alarm,ESPara.Alarm_LevelN,[],ESPara.Alarm_Color,timeSeq,MyTitle,MyXLabel,MyYLabel,ESPara.Alarm_LevelPlot);
       
        if ESAlarmLevel<ESReport.VMB_AlarmTopLevel
            ESAlarmLevel=ESReport.VMB_AlarmTopLevel;
        end

        % 4.8 write the voltage magnitude Event Scan report.
        if ESReport.VMB_AlarmTopLevel
            aRefTime=PSM2Date(PSMreftimes(1));
            Alarm_Source='VM Scan';
            Alarm_Triggering=MySignal;
            Alarm_Notes='N/A';
            ESAlarmLogReady=funESAlarmLog(fidESLog, ESReport.VMB_AlarmSeq, ESPara.VMB_Alarm, ESPara.VMB_MinEventTimeDist,...
                    aRefTime, tstep, timeSeq, Alarm_Source, Alarm_Triggering, Alarm_Notes, 'p.u.');
        end
    end
    disp(['In ' CSname ': End system voltage magnitude scan']);
end

if ESAlarmLevel
    disp(['In ' CSname ': End system Event Scan [Alarmed Level: ', num2str(ESAlarmLevel),']'])
else
    disp(['In ' CSname ': End system Event Scan [Passed]'])
end

% 4.0 End voltage magnitude boundary scan 
%*************************************************************************

%keyboard
%-------------------------------------------------------------------------------------------------------------
if fidESLog>2
    fclose(fidESLog);       %close the log file
elseif fidESLog==1
    disp(' ');
    disp(['In ', CSname, ':',sprintf('Can not open [ %s ] for writing.',logFileName)]);
    disp('The event scanning results were displayed on the screen.');
    disp('press any key to continue... ');pause;
end

return



