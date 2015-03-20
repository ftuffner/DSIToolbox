function funApplySQLJAR
% function funApplySQLJAR
%
% Function to read in SQL database information and load the .jar file to run it.
% Has to be done early because altering the Java dynamic path clears global variables,
% which messes up most other DSI toolbox functions.
%
% Requires the SQL_Config.cfg file to be present in the DSI Toolbox parent folder
%
% Functionalized March 3, 2014 by Frank Tuffner

%% Read in the configuration file for the SQL linkage            

%Find the configuration file
FileLocation = which('SQL_Config.cfg');

if (isempty(FileLocation))
    disp('In funApplySQLJAR: Failure to find SQL_Config.cfg file -- exiting');
    return
end
    
%Read in configuration file - defaults to PSMfiles Source, one folder in
fHandle=fopen(FileLocation,'rt');

%Make sure it was found
if (fHandle==-1)
    disp('In funApplySQLJAR: Failure to find SQL_Config.cfg file -- exiting');
    return;
end

%Read in the data
ConfigDataRaw=textscan(fHandle,'%s %s','Delimiter',{':='},'CommentStyle','#','CollectOutput',1);

%close file handle
fclose(fHandle);

%Extract it out one layer so double cells are being used
ConfigData=ConfigDataRaw{1};

%% Configure connection string

%Get the number of entries read
NumEntriesRead=size(ConfigData,1);

%Find the JARFile entry
JARFile='';
for sVals=1:NumEntriesRead
    
    if (strcmpi(ConfigData{sVals,1},'JARFile')~=0)
        JARFile=ConfigData{sVals,2};
        break;
    end
end

%Make sure it was found
if isempty(JARFile)
    disp('In funApplySQLJAR: JARFile entry in SQL_Config.cfg was either empty or missing');
    return;
end

%% Java commands

%Output message
disp('Adding JAR file for SQL support -- if this gives a warning and you wish to use');
disp('the SQL functionality, please insure your SQL_Config.cfg file is set properly');
disp(' ');

%Add JARFile to the Java path
javaclasspath(strrep(JARFile,'''',''));
