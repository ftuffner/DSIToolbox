
%*******************************************************************************
% testEventScan??.m
%
% testEventScan is a DSI toolbox utility for scanning the *.dst files to 
%   find the abnomal events. Some major codes are from (c)DSItoolbox
% 
%    
%
% By Ning Zhou, Pacific Northwest National Laboratory.
%
% 05/10/2006.     
%
%
%
% To use the code:
%  1) copy all the codes, including the subdirectory, into a local disk.
%  2) start a matlab.
%  3) In the matlab environment, select 'File', then 'Set path', then 'Add
%     with subfolders'.
%  4) After choosing the folder where the codes are, click 'save'
%  5) run 'testEventScan??.m'


clear all       % clear all variables
close all
clc
%******************************************************
% 0.0 Start Variables From PSMBrowser for compatibles
global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMpaths PSMreftimes
PSMtype='';      %Clear PSM type 
DataPath='';
CSname='Batch_Event_Scan';  %Internal name of this case script

% 0.0 End Variables From PSMBrowser for compatibles
%******************************************************************************
global PSMMacro;         % Macro Structure for automatic running
if isempty(PSMMacro)
    funLoadMacro(); 
end
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
%************************************************
%1.0 define file path and directory selection 
%path(path,'CodeFromDSI');
if isfield(PSMMacro, 'EventScan1_PathName')
    if isdir(PSMMacro.EventScan1_PathName)
        cd(PSMMacro.EventScan1_PathName);
    end
end
%keyboard;
Batch_Event_Scan_config;
subCheckValid;
if NFiles<=0
    return;
end
save(PSMMacro.MacroName,'PSMMacro');
%************************************************
%2.0 check the definition of the default selections

PSMMacro.RunMode=2;     % Super running a model in a macro play mode
PSMMacro.AddCom_lineok=0;
PSMMacro.CaseTags_setok=1;

PSMMacro.EndChecks_keybdok=0;
PSMMacro.EndChecks_fillok=0;

PSMMacro.PSMload_PSMntype=1;
PSMMacro.PSMload_PSMtype='PDC';
PSMMacro.PSMload_PSMtypeok=1;
PSMMacro.PSMload_GetRange=0;
PSMMacro.PSMload_savesok=0;

PSMMacro.PSMload_PSMfiles=NaN;
PSMMacro.PSMload_PSMpaths=NaN;
PSMMacro.PSMload_dstFileChosen=1;
PSMMacro.PSMload_filesok=1;

PSMMacro.PDCloadN_AliasOK=0;

PSMMacro.PDCload4_MatFmt=2;
PSMMacro.PDCload4_initext=[];
PSMMacro.PDCload4_fname=PSMMacro.EventScan1_CFname;
PSMMacro.PDCload4_CFname=PSMMacro.EventScan1_CFname;
PSMMacro.PDCload4_setok=0;

PSMMacro.PDCload4_PatchMode=1;
%PSMMacro.PDCload4_PatchMode=NaN;

PSMMacro.PDCload4_logpatch=0;
PSMMacro.PDCload4_setok2=1;
PSMMacro.PDCload4_BnkLevelPU=NaN;
PSMMacro.PDCload4_BnkFactor=NaN;
PSMMacro.PDCload4_PlotPatch=0;
PSMMacro.PDCload4_LogPatch=NaN; 

if isempty(PSMMacro.EventScan1_ChannelSeq)                                  % [] means all channels are to be selected
    PSMMacro.SetExtPDC_chansXok=1;
    PSMMacro.SetExtPDC_chansX=PSMMacro.EventScan1_ChannelSeq;               % []=All channels are chosen
    PSMMacro.SetExtPDC_MenuName='Event Scan Choice';
elseif isnan(PSMMacro.EventScan1_ChannelSeq)                                % menu selected channels
    PSMMacro.SetExtPDC_chansXok=0;
    PSMMacro.SetExtPDC_chansX=PSMMacro.EventScan1_ChannelSeq;               % NaN channel selection are postponed for menu selection
    PSMMacro.SetExtPDC_MenuName='';
else
    PSMMacro.SetExtPDC_chansXok=1;
    PSMMacro.SetExtPDC_chansX=PSMMacro.EventScan1_ChannelSeq;               % [1:10 20]=specified channel number
    PSMMacro.SetExtPDC_MenuName='Event Scan Choice';
end


titleProc='Batch Event Scan';
disp(' ')
disp(['In ' CSname ': Define new case tags']);
[caseID,casetime,CaseCom]=CaseTags(CSname);

if ~isempty(get(0,'Children'))  %Test for open plots
    closeok=promptyn(['In ' CSname ': Close all plots? '], 'y');
    if closeok, close all; end    %Close all plots
end

%************************************************
% 3.0 convert all the *.dst files into txt files
startTime=clock;        % count the time duration for data format conversion
filename=dstFileNames(1).name;
msgProc=sprintf(' Performing bacth event Scanning for the \n %d files under the directory of\n [ %s ] \n edit [configBatchEventScan.m] to change directory setting. \n\n Please wait ......',...
            NFiles,PSMMacro.EventScan1_PathName);
hESMSG=msgbox(msgProc,titleProc,'replace');
fileCount=0;        % count the number of files converted
%dstFileNames(1).Convertedname=SaveFile;
switch 3
    case 1          % all the files are grouped together.
    PSMMacro.PSMload_PSMfiles=dstFileNames(1).name;
    for fIndex=2:NFiles
         PSMMacro.PSMload_PSMfiles=str2mat(PSMMacro.PSMload_PSMfiles,dstFileNames(fIndex).name);
    end
    PSMMacro.EventScan1_PSMfilesIndex=1;
    PSMMacro.PSMload_PSMpaths=PSMMacro.EventScan1_PathName;
    PSMfiles=PSMMacro.PSMload_PSMfiles;
    PSMpaths=PSMMacro.PSMload_PSMpaths; 
    cd(PSMpaths(1,:));
    %************************************************************
    % the major function to load the data
    PSMload;    % the major function to do converstion
    % the major function to load the data
    %************************************************************
    
    [maxpoints,nsigs]=size(PSMsigsX); 
    chansA=[2:5];                 %Signals to analyze
    decfac=1;                     %Decimation factor
    n1=1; n2=maxpoints;
    t1=PSMsigsX(n1,1);            %Initial processing time
    t2=PSMsigsX(n2,1);            %Final processing time
    TRange=[t1 t2];               %Processing range
    EScanpars=[];
    [CaseComES,SaveFileES,namesES,TRangeES,ESAlarmLogReady, ESAlarmLevel]...
                =EventScan1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
                     chansA,TRange,tstep,decfac,...
                     EScanpars);

    case 2              % each file is processed independantly.
        ESAlarmLevel=0;        
        for fIndex=1:NFiles
            clc;
            PSMMacro.PSMload_PSMfiles=dstFileNames(fIndex).name;
            PSMMacro.PSMload_PSMpaths=PSMMacro.EventScan1_PathName;
            PSMMacro.EventScan1_PSMfilesIndex=fIndex;
            
            PSMfiles=PSMMacro.PSMload_PSMfiles;
            PSMpaths=PSMMacro.PSMload_PSMpaths; 
            



            %************************************************************
            % the major function to load the data
            cd(PSMpaths(1,:));
            PSMload;    % the major function to do converstion
            % the major function to load the data
            %************************************************************
            %dstFileNames(fIndex).Convertedname=SaveFile;
            fileCount=fileCount+1;
            tDuration=etime(clock, startTime);  % in sec
            fileCountDisp=max([fileCount,1]);
            if ishandle(hESMSG)
                msgProc=sprintf(' Scanned %d files, %d files are left. \n Expected execution time = %5.1f minutes \n ( speed= %5.1f sec/file ). \n  (The %s was just finished.) \n\n Please wait ......',...
                    fileCount,NFiles-fIndex,1/60*(NFiles-fIndex)*tDuration/fileCountDisp,tDuration/fileCountDisp,dstFileNames(fIndex).name);
                hESMSG=msgbox(msgProc,titleProc,'replace');
            end

            [maxpoints,nsigs]=size(PSMsigsX); 
            chansA=[2:5];                 %Signals to analyze
            decfac=1;                     %Decimation factor
            n1=1; n2=maxpoints;
            t1=PSMsigsX(n1,1);            %Initial processing time
            t2=PSMsigsX(n2,1);            %Final processing time
            TRange=[t1 t2];               %Processing range
            EScanpars=[];
             
            [CaseComES,SaveFileES,namesES,TRangeES,ESAlarmLogReady, ESAlarmLevelFile]...
                =EventScan1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
                     chansA,TRange,tstep,decfac,...
                     EScanpars);
            if ESAlarmLevel<ESAlarmLevelFile
                ESAlarmLevel=ESAlarmLevelFile;
            end
        end
        
    case 3          % Files are grouped to the maximum allowed number
        ESAlarmLevel=0;
        PSMMacro.PSMload_PSMfiles=[];
        countPSMFiles=0;
        countPSMGroup=0;
        
        for fIndex=1:NFiles
            if isempty(PSMMacro.PSMload_PSMfiles)
                PSMMacro.PSMload_PSMfiles=dstFileNames(fIndex).name;
            else
                PSMMacro.PSMload_PSMfiles=str2mat(PSMMacro.PSMload_PSMfiles,dstFileNames(fIndex).name);
            end
            
            countPSMFiles=countPSMFiles+1;
            if countPSMFiles>=MaxFiles || fIndex==NFiles
                 countPSMGroup=countPSMGroup+1;
                 countPSMFiles=0;
                 PSMMacro.EventScan1_PSMfilesIndex=countPSMGroup;
                 PSMMacro.PSMload_PSMpaths=PSMMacro.EventScan1_PathName;
                 PSMfiles=PSMMacro.PSMload_PSMfiles;
                 PSMpaths=PSMMacro.PSMload_PSMpaths; 
                 
                %************************************************************
                % the major function to load the data
                cd(PSMpaths(1,:));
                PSMload;    % the major function to do converstion
                % the major function to load the data
                %************************************************************
                fileCount=fileCount+MaxFiles;
                tDuration=etime(clock, startTime);  % in sec
                fileCountDisp=max([fileCount,1]);
                if ishandle(hESMSG)
                    msgProc=sprintf(' Scanned %d files, %d files are left. \n Expected execution time = %5.1f minutes \n ( speed= %5.1f sec/file ). \n  \n Please wait ......',...
                     fileCount,NFiles-fileCount,1/60*(NFiles-fileCount)*tDuration/fileCountDisp,tDuration/fileCountDisp);
                    hESMSG=msgbox(msgProc,titleProc,'replace');
                end
            
                [maxpoints,nsigs]=size(PSMsigsX); 
                chansA=[2:5];                 %Signals to analyze
                decfac=1;                     %Decimation factor
                n1=1; n2=maxpoints;
                t1=PSMsigsX(n1,1);            %Initial processing time
                t2=PSMsigsX(n2,1);            %Final processing time
                TRange=[t1 t2];               %Processing range
                EScanpars=[];
                [CaseComES,SaveFileES,namesES,TRangeES,ESAlarmLogReady, ESAlarmLevelFile]...
                    =EventScan1(caseID,casetime,CaseCom,namesX,PSMsigsX,...
                         chansA,TRange,tstep,decfac,...
                         EScanpars);
                PSMMacro.PSMload_PSMfiles=[];     % reset the file names
                 if ESAlarmLevel<ESAlarmLevelFile
                    ESAlarmLevel=ESAlarmLevelFile;
                 end
             end
        end
        
    otherwise
        disp('Not a valid switch');
end

if ishandle(hESMSG)
    close(hESMSG);
else
    edit configBatchEventScan.m;
end

tDuration=etime(clock, startTime);
disp(' ');


if ESAlarmLevel 
    disp(' ');
    disp('-------------------------------------------------------------------------- ');
    disp(['In ' CSname ': Event Scan has been finished for the directory at ']);
    disp([ '      [ ' PSMMacro.EventScan1_PathName ' ]'])
    disp([ '      Scanned [', num2str(NFiles),']  files ( within ', num2str(tDuration/60,'%4.1f'),'minutes )']);
     disp(['      Highest detected alaram level = ', num2str(ESAlarmLevel)]);
     if ESAlarmLogReady
         disp('      The summary is stored in the file ')
         disp(['      [',  PSMMacro.EventScan1_PathName, PSMMacro.EventScan1_LogFname, ' ]']);
         disp('--------------------------------------------------------------------------- ');
         ESInspectOk=promptyn(['In ' CSname ': Do you want to inspect it? '], 'y');
         if ESInspectOk
              winopen([PSMMacro.EventScan1_PathName, PSMMacro.EventScan1_LogFname]);
              disp(' press any key to continue ... ');  pause;
         end
     else
        disp('      The summary is printed on the screen because the log file cannot be openned!! ') 
        disp('--------------------------------------------------------------------------- ');
        disp(' press any key to continue ... ');  pause;
     end
else
    disp(' ');
    disp('-------------------------------------------------------------------------- ');
    disp(['In ' CSname ': No special events were detected for the files in the directory at ']);
    disp([ '[ ' PSMMacro.EventScan1_PathName ' ]'])
    disp([ '      Scanned [', num2str(NFiles),']  files ( within ', num2str(tDuration/60,'%4.1f'),'minutes )']);
    disp('--------------------------------------------------------------------------- ');
    disp(' press any key to continue ... ');  pause;
end
PSMMacro.RunMode=-1;     % stop a macro from running



