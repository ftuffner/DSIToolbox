function [CaseComR,PSMreftime,chankeyX,namesX,PSMsigsX,chansX,chansXok,tstep]=funReadSQL
% function [CaseComR,PSMreftime,chankeyX,namesX,PSMsigsX,chansX,chansXok,MenuName,tstep]=funReadSQL(CFname,MenuName)
% funReadSQL
%
% Function to read in SQL database information and return the items
% needed for integration into the DSI toolbox.
%
% Requires the SQL_Config.cfg file to be present in the DSI Toolbox parent folder
%
% Usage:
% [CaseComR,PSMreftime,chankeyX,namesX,PSMsigsX,chansX,chansXok,MenuName,tstep]=funReadSQL()
% where
% chansX is the channel selection vector - exported when done for future passes
% CFname is the case name
% nXfile is the number of the current file being read
% chansXok is a flag to indicate if channel selection has occurred
% MenuName is a signal selection variable
%
% CaseComR - normal case status information for DSI toolbox
% PSMreftime - Reference time for data (first sample)
% chankeyX - channel names with numbers
% namesX - channel names
% PSMsigsX - data matrix (column 1 = time)
% tstep - median timestep between samples
% 
% Functionalized March 3, 2014 by Frank Tuffner

%% Read in the configuration file for the SQL linkage            

%Find the configuration file
FileLocation = which('SQL_Config.cfg');

if (isempty(FileLocation))
    error('In funReadSQL: Failure to find SQL_Config.cfg file -- exiting');
end
    
%Read in configuration file - defaults to PSMfiles Source, one folder in
fHandle=fopen(FileLocation,'rt');

%Make sure it was found
if (fHandle==-1)
    error('In funReadSQL: Failure to find SQL_Config.cfg file -- exiting');
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

% %Find the JARFile entry
% %Removed, since needs to occur much earlier in process
% JARFile='';
% for sVals=1:NumEntriesRead
%     
%     if (strcmpi(ConfigData{sVals,1},'JARFile')~=0)
%         JARFile=ConfigData{sVals,2};
%         break;
%     end
% end
% 
% %Make sure it was found
% if isempty(JARFile)
%     error('In funReadSQL: JARFile entry in SQL_Config.cfg was either empty or missing');
% end

%Look for the driver entry
JARDriverName='';
for sVals=1:NumEntriesRead
    
    if (strcmpi(ConfigData{sVals,1},'JARDriverName')~=0)
        JARDriverName=strrep(ConfigData{sVals,2},'''','');
        break;
    end
end

%Make sure it was found
if isempty(JARDriverName)
    error('In funReadSQL: JARDriverName entry in SQL_Config.cfg was either empty or missing');
end

%Look for the connection string
JARConnectString='';
for sVals=1:NumEntriesRead
    
    if (strcmpi(ConfigData{sVals,1},'JARConnectString')~=0)
        JARConnectString=ConfigData{sVals,2};
        break;
    end
end

%Make sure it was found
if isempty(JARConnectString)
    error('In funReadSQL: JARConnectString entry in SQL_Config.cfg was either empty or missing');
end

%See how many bracket pairs there are to parse out
ParamIdx=(1:length(JARConnectString));
ParamStart=ParamIdx(JARConnectString=='{');
ParamEnd=ParamIdx(JARConnectString=='}');
NumParams=length(ParamStart);

if (NumParams~=0)
    %Get initial string
    FinalConnectString=JARConnectString(1:(ParamStart(1)-1));

    %Loop through and fix them
    for pVals=1:NumParams

        %Extract the name of the parameter
        paramName=JARConnectString((ParamStart(pVals)+1):(ParamEnd(pVals)-1));

        %Loop through the config and find this value, hopefully
        JARparamfound=0;

        for cVals=1:NumEntriesRead

            if (strcmp(ConfigData{cVals,1},['JAR' paramName])~=0)
                %Extract the value
                paramValue=strrep(ConfigData{cVals,2},'''','');
                JARparamfound=1;
                break;
            end
        end

        %Error check
        if JARparamfound==0
            error(['In funReadSQL: Unable to find parameter ' paramName ' in configuration file!']);
        end

        %Append this on, plus fill any gaps between parameters
        if (pVals<NumParams)
            FinalConnectString=[FinalConnectString paramValue JARConnectString((ParamEnd(pVals)+1):(ParamStart(pVals+1)-1))];
        else %Just do to the end
            FinalConnectString=[FinalConnectString paramValue JARConnectString((ParamEnd(pVals)+1):end)];
        end
    end
else %No parameters, just a straight pass
    FinalConnectString=JARConnectString;
end

%Clean it, for good measure
FinalConnectString=strrep(FinalConnectString,'''','');

%% Java commands

%Add JARFile to the Java path
% This is now done much earlier in the process, since adding to the java
% dynamic path apparently clears all global variables.
% javaclasspath(strrep(JARFile,'''',''));

%import the class
evalc(['import ' JARDriverName ';']);

%Create properties
tpropvals = java.util.Properties();

%Loop through parse enties and see if any are properties - if so, set them
for sVals=1:NumEntriesRead
    if (strfind(ConfigData{sVals,1},'JARPROP')~=0)
        %Get the property name
        PropertyName=ConfigData{sVals,1}(8:end);
        PropertyValue=ConfigData{sVals,2};
        
        %See if we're a username or password and empty -- if so, prompt us
        if ((strcmp(PropertyName,'user')~=0) && isempty(strrep(PropertyValue,'''','')))
            %Prompt for the username
            userDialogPrompt = inputdlg({'SQL Server Username?'},'SQL Username Requested');
            
            %Strip off the value
            PropertyValue = userDialogPrompt{1};

            %Write it as a property
            tpropvals.setProperty(strrep(PropertyName,'''',''),strrep(PropertyValue,'''',''));
            
            %Clear the intermediate value
            clear PropertyValue;
            
        elseif (strcmp(PropertyName,'password')~=0) %It's a password
            
            %See if it is empty
            if (isempty(strrep(PropertyValue,'''','')))
                %Check for the existence of external method
                if (exist('passwordEntryDialog','file')==2)    %File from MATLAB central that calls Java routine for passwords
                    PropertyValue = passwordEntryDialog('WindowName','SQL Access Password','CheckPasswordLength',0);
                else
                    %Prompt for the username
                    userDialogPrompt = inputdlg({'SQL Server password?'},'SQL Access Password');

                    %Strip off the value
                    PropertyValue = userDialogPrompt{1};
                end
            end
            %Default else - it's populated, but eliminate the working variable anyways (keeps it half hidden)

            %Write it as a property
            tpropvals.setProperty(strrep(PropertyName,'''',''),strrep(PropertyValue,'''',''));
            
            %Clear the intermediate value
            clear PropertyValue;
            
        else %Normal property
            %Write it as a property
            tpropvals.setProperty(strrep(PropertyName,'''',''),strrep(PropertyValue,'''',''));
        end
    end
end

%Create the connection
driverval = javaObjectEDT(JARDriverName);
connectVal = driverval.connect(FinalConnectString,tpropvals);

%Clear connection property, since it may have username/password in it
clear tpropvals;

%% Create teh query, now that the connection is established
JARQueryString='';
for sVals=1:NumEntriesRead
    
    if (strcmpi(ConfigData{sVals,1},'JARSQLQuery')~=0)
        JARQueryString=ConfigData{sVals,2};
        break;
    end
end

%Make sure it was found
if (isempty(JARQueryString) || (strcmp(JARQueryString,'''''')~=0))
    %Close the connection
    connectVal.close();
    driverval.unloadDriver();
    
    %Error out
    error('In funReadSQL: JARSQLQuery entry in SQL_Config.cfg was either empty or missing');
end

%See if there are any terms to prompt for
ParamIdx=(1:length(JARQueryString));
ParamStart=ParamIdx(JARQueryString=='{');
ParamEnd=ParamIdx(JARQueryString=='}');
NumParams=length(ParamStart);

%Get initial string
if (NumParams~=0)
    FinalQueryString=JARQueryString(1:(ParamStart(1)-1));

    %Loop through and fix them
    for pVals=1:NumParams

        %Extract the name of the parameter
        paramName=JARQueryString((ParamStart(pVals)+1):(ParamEnd(pVals)-1));

        %Create a prompt for it
        userDialogPrompt = inputdlg({[paramName ' field value?']},[paramName ' entry']);

        %Make sure it wasn't empty
        if (isempty(userDialogPrompt))
            disp(['In funReadSQL: No user value returned for {' paramName '}, assuming that was intentional and continuing']);
            paramValue='';
        else %Valid return
            %Strip off the value
            paramValue = userDialogPrompt{1};    
        end

        %Append this on, plus fill any gaps between parameters
        if (pVals<NumParams)
            FinalQueryString=[FinalQueryString paramValue JARQueryString((ParamEnd(pVals)+1):(ParamStart(pVals+1)-1))];
        else %Just do to the end
            FinalQueryString=[FinalQueryString paramValue JARQueryString((ParamEnd(pVals)+1):end)];
        end
    end
else %No parameters, just a straight string
    FinalQueryString=JARQueryString;
end

%Clean it, for good measure
FinalQueryString=strrep(FinalQueryString,'''','');

%Get count of results, so we can allocate later
newQuery=['SELECT COUNT(*) FROM (' FinalQueryString ') X'];
prepStatement = connectVal.prepareStatement(newQuery);

%Execute it, but capture it, just in case
try
    %run the query
    newData = prepStatement.executeQuery();
catch exception
    %Close the connection
    connectVal.close();
    driverval.unloadDriver();
    
    %Error out
    disp(exception.message);
    error('In funReadSQL: Error encountered with query count -- exiting');
end

%Query succeeded, get the information count
if (newData.next())
    FindRowCount=newData.getInt(1);
else
    FindRowCount=0;
end

%Prepare the final string as a query
prepStatement = connectVal.prepareStatement(FinalQueryString);

%Execute it - put a catch
try
    %Run the query
    data = prepStatement.executeQuery();
catch exception
    %Close the connection
    connectVal.close();
    driverval.unloadDriver();
    
    %Error out
    disp(exception.message);
    error('In funReadSQL: Error encountered with query -- exiting');
end

%% Read and store the data

%Loop through the entries
preAlloced=0;
DataRow=1;
while data.next()
    if (preAlloced==0)
        %Loop through until we break -- that's our size (not very elegant)
        
        %For giggles, make sure entry 1 is a timestamp
        try
            data.getTimestamp(1);
        catch exception
            %Close the connection
            connectVal.close();
            driverval.unloadDriver();

            %Error out
            disp(exception.message);
            error('In funReadSQL: Error encountered with query -- first column of result is not a timestamp! Exiting');
        end
        
        %set counter
        NumColumns=2;
        while 1
            try 
                %See if we can be read as a double
                data.getDouble(NumColumns);
                
                %Must have, increment and go forth
                NumColumns=NumColumns+1;
            catch
                %Nope, last one didn't work, decrement and exit
                NumColumns=NumColumns-1;
                
                break;
            end
        end
        
        %Pre-allocate the data matrix
        DataVals=zeros(FindRowCount,NumColumns);
        
        %Create the "reading statement" for the rest
            %Base CMD
            ReadCMD='DataVals(DataRow,(2:NumColumns))=[';
            
            %Loop through columns
            for cVals=2:NumColumns
                ReadCMD=[ReadCMD ' data.getDouble(' num2str(cVals) ')'];
            end
            
            %Finalize the command
            ReadCMD = [ReadCMD '];'];
        
        %Deflag us
        preAlloced=1;
    end
    
    %Read in try/catch -- just in case an error is encountered
    try
        %Store the values
        DataVals(DataRow,1)=datenum(char(data.getTimestamp(1)),'yyyy-mm-dd HH:MM:SS.FFF');

        %Execute reading statement
        evalc(ReadCMD);

        %Increment the counter
        DataRow=DataRow+1;
    catch exception
        %Close the connection
        connectVal.close();
        driverval.unloadDriver();

        %Error out
        disp(exception.message);
        error(['In funReadSQL: Error encountered with data read at entry ' num2str(DataRow) ' -- exiting']);
    end
end

%Close all of them
data.close()
connectVal.close();
driverval.unloadDriver();

% %%%%%%%%%%%%%%%%%%%%%%%%%%% DEBUG - DELETE
% DataVals=zeros(20,4);
% NumColumns = 4;
% FinalConnectString = 'test';
% FinalQueryString = 'tested';
% DataVals(:,1)=(datenum(now)+ (0:19)/24).';

%% Format the data into PSM signals format

%Create output data
PSMsigsX=zeros(size(DataVals));

%Populate column 1 as the time from reftime
PSMsigsX(:,1)=(DataVals(:,1)-DataVals(1,1))*24*3600;

%Populate the data array
PSMsigsX(:,2:NumColumns) = DataVals(:,2:NumColumns);

%Assign the first time to PSMreftime - convert to reference from 1900
DateMATLAB=datenum(1900,1,1,0,0,0);
PSMreftime=(DataVals(1,1)-DateMATLAB)*24*3600;  %Convert to seconds

%Compute tstep as the median timestep - no guarantee the SQL is in a uniform manner
tstep = median(diff(PSMsigsX(:,1)));

%Force chansX to be all channels -- not much of a choice here
chansX=1:NumColumns;

% Create some CaseComR entries 
CaseComR=char({['SQL Extracted data using connection info: ' FinalConnectString];
               [' and query string: ' FinalQueryString]});

%Create chansXok
chansXok = 1;

%Create a name and channel vector - unfortunately, they don't have a lot of options
namesXRaw=cell(NumColumns,1);
namesXRaw{1}='Time';

%Loop through for generic "other" names
for cVals=2:NumColumns
    namesXRaw{cVals} = ['SQL Read Channel ' num2str(cVals-1)];
end

%Extract it, now that the length is done
namesX=char(namesXRaw);

%Create the chankeyX variable
chankeyX=[repmat('% ',NumColumns,1) num2str((1:NumColumns).','%d') repmat('  ',NumColumns,1) namesX];