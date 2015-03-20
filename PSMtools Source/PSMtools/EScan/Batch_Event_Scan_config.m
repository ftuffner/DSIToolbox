MaxFiles=4;      %Maximum number of PSM files to load together
% configuration files for the 'Batch_Event_Scan'
PSMMacro.EventScan1_PathName='';   % use the menu to choose the path for the *.dst files
PSMMacro.EventScan1_CFname='';     % use the menu to choose the *.ini files
%PSMMacro.EventScan1_PathName='C:\ZhouNingDataHugeSize\EventScanData';             % path for the *.dst files
%PSMMacro.EventScan1_CFname='C:\ZhouNingDataHugeSize\EventScanData\BPA2_050215.ini';   % *.ini files with path; the default path is same as the *.dst files
PSMMacro.EventScan1_PSMfilesIndex=0;    % the Index the current *.dst file
PSMMacro.EventScan1_ChannelSeq=[];     % The channel selections [] means all the channels
%PSMMacro.EventScan1_ChannelSeq=NaN;     % NaN means user selection of channel                                           
%PSMMacro.EventScan1_ChannelSeq=[1,10:90];      
CurDateStr=datestr(now,'yyyymmddHHMM');
PSMMacro.EventScan1_LogFname=['BatchESLog', CurDateStr,'.xls'];

