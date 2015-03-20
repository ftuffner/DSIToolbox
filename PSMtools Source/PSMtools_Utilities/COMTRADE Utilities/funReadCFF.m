function [CaseComR,PSMreftime,chankeyX,namesXRaw,PSMsigsX,chansX,chansXok,MenuName,tstep]=funReadCFF(DataPath,chansX,CFname,nXfile,chansXok,MenuName)
% funReadCFF
%
% Function to read in a CFF file and return the items needed for
% integration into the DSI toolbox.
%
% Usage:
% [CaseComR,PSMreftime,chankeyX,namesX,PSMsigsX,tstep]=funReadCFF(DataPath)
% where
% DataPath is the file name to read (.CFF file)
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
% Relies on SigSelect to be found in path
% 
% Functionalized December 9, 2013 by Frank Tuffner

%Null out the outputs
CaseComR=[];
chankeyX=[];
namesXRaw=[];
PSMsigsX=[];
tstep=-1;

%Define signal types - extracted from PDCload routines, so same???
SigTypes=char({'Time','Freq','VMag','VAng','IMag','IAng','MW  ','Mvar',...
                'FreqL','VAngL','FreqR','VAngR','FreqA','VAngA','VAngX',...
                'spcl','end '});

%% Open file header
fHeader=fopen(DataPath,'rt');

%Ensure it worked
if (fHeader<1)
    disp('CFFRead - Unable to open file');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%Get the name of the source file -- first line
SourceFileName=sscanf(fgetl(fHeader),'<RECORD:%[^>]s');

%Make sure it isn't empty
if isempty(SourceFileName)
    disp('CFFRead - Source file invalid');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%% Look for and parse config block

%Parse next line, make sure it is <CONFIG>
if (strcmp(fgetl(fHeader),'<CONFIG>')==0)
    disp('CFFRead - CONFIG designator not found - invalid format');
    
    % Close the file header
    fclose(fHeader);
    return;
end

% Next line is station name, identification, and revision year
RawScanData=textscan(fgetl(fHeader),'%s %s %d','delimiter',',');
rev_year=RawScanData{3};
station_id=RawScanData{2}{1};
station_name=RawScanData{1}{1};

%Error checks on initial data
if (isempty(rev_year))
    rev_year=1991;  %Default assumption
elseif (rev_year<1991)
    disp(['CFFRead - COMTRADE Revision year of ' num2str(rev_year) ' not valid -- check file']);
    
    % Close the file header
    fclose(fHeader);
    return;
end

%Get number of channel types
RawScanData=textscan(fgetl(fHeader),'%d %dA %dD','delimiter',',');
NumTotalChans=RawScanData{1};
NumAnalogChans=RawScanData{2};
NumDigitalChans=RawScanData{3};

%Error check
if ((NumAnalogChans+NumDigitalChans)~=NumTotalChans)
    disp('CFFRead - mismatched channel count');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%Preallocate storage arrays
if (NumAnalogChans~=0)
    AnalogInformation(NumAnalogChans)=struct('Index',0,'Channel_ID','','Phase','','Component','','Units','','Mult',1.0,'Offset',0.0,'skew',0,'min',-3.4028235e38,'max',3.4028235e38,'primary','','secondary','','PS','');
end

if (NumDigitalChans~=0)
    DigitalInformation(NumDigitalChans)=struct('Index',0,'Channel_ID','','Phase','','Component','','Normal',1);
end

%Parse the info
for lVals=1:NumAnalogChans
    
    %Read line
    RawData=textscan(fgetl(fHeader),'%d %s %s %s %s %f %f %f %f %f %f %f %c','delimiter',',');
    
    %Extract the values if not empty
    if (isempty(RawData))
        disp(['CFFRead - Error reading analog channel specifier:' num2str(lVals)]);
    else
        AnalogInformation(lVals).Index=RawData{1};
        AnalogInformation(lVals).Channel_ID=RawData{2}{1};
        AnalogInformation(lVals).Phase=RawData{3}{1};
        AnalogInformation(lVals).Component=RawData{4}{1};
        AnalogInformation(lVals).Units=RawData{5}{1};
        AnalogInformation(lVals).Mult=RawData{6};
        AnalogInformation(lVals).Offset=RawData{7};
        AnalogInformation(lVals).skew=RawData{8};
        AnalogInformation(lVals).min=RawData{9};
        AnalogInformation(lVals).max=RawData{10};
        AnalogInformation(lVals).primary=RawData{11};
        AnalogInformation(lVals).secondary=RawData{12};
        AnalogInformation(lVals).PS=RawData{13};
    end %Structure parse
end %End analog channel data parsers

%Parse the digital channels
for lVals=1:NumDigitalChans
    
    %Read line
    RawData=textscan(fgetl(fHeader),'%d %s %s %s %d','delimiter',',');
    
    %Extract the values if not empty
    if (isempty(RawData))
        disp(['CFFRead - Error reading digital channel specifier:' num2str(lVals)]);
    else
        DigitalInformation(lVals).Index=RawData{1};
        DigitalInformation(lVals).Channel_ID=RawData{2}{1};
        DigitalInformation(lVals).Phase=RawData{3}{1};
        DigitalInformation(lVals).Component=RawData{4}{1};
        DigitalInformation(lVals).Normal=RawData{5};
    end %Structure parse
end

%Read the frequency information
Line_Frequency=sscanf(fgetl(fHeader),'%f');

%Get number of sample rates
NumSampleRates=sscanf(fgetl(fHeader),'%d');

%See how many rates there are
if (NumSampleRates>1)   %If 1 or zero, there's only 1 or none
    %Allocate
    SampleRate=zeros(NumSampleRates,1);
    EndSample=zeros(NumSampleRates,1);
    
    %Loop and collect
    for sVals=1:NumSampleRates
        %Read the first value anyways
        RawData=sscanf(fgetl(fHeader),'%f,%f');
        SampleRate(sVals)=RawData(1);
        EndSample(sVals)=RawData(2);
    end
else
    %Read the first value anyways
    RawData=sscanf(fgetl(fHeader),'%f,%f');
    SampleRate=RawData(1);
    EndSample=RawData(2);
end

%Get total sample count - for preallocation purposes later
TotalSamples=max(EndSample);

%Parse timestamp information
RawFirstTimeText=textscan(fgetl(fHeader),'%s %s','delimiter',',');
RawSecondTimeText=textscan(fgetl(fHeader),'%s %s','delimiter',',');

%Convert them into MATLAB times
FirstTimeDate=datenum(str2double(RawFirstTimeText{1}{1}(7:10)),...
                      str2double(RawFirstTimeText{1}{1}(4:5)),...
                      str2double(RawFirstTimeText{1}{1}(1:2)),...
                      str2double(RawFirstTimeText{2}{1}(1:2)),...
                      str2double(RawFirstTimeText{2}{1}(4:5)),...
                      str2double(RawFirstTimeText{2}{1}(7:end)));
%Trigger time unused
% TriggerTimeDate=datenum(str2double(RawSecondTimeText{1}{1}(7:10)),...
%                         str2double(RawSecondTimeText{1}{1}(4:5)),...
%                         str2double(RawSecondTimeText{1}{1}(1:2)),...
%                         str2double(RawSecondTimeText{2}{1}(1:2)),...
%                         str2double(RawSecondTimeText{2}{1}(4:5)),...
%                         str2double(RawSecondTimeText{2}{1}(7:end)));

%Read the data type
DataTypeText=fgetl(fHeader);

%Figure out which type and set the flag
%0 = ASCII, 1 = binary, 2 = binary32, 3 = float32
if (strcmpi(DataTypeText,'ASCII')~=0)
    DataType=0;
elseif (strcmpi(DataTypeText,'binary32')~=0)
    DataType=2;
elseif (strcmpi(DataTypeText,'binary')~=0)
    DataType=1;
elseif (strcmpi(DataTypeText,'float32')~=0)
    DataType=3;
else %Unknown, fail
    disp('CFFRead - Unknown data encoding type in file');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%Get TimeStamp multiplication factor
TimeStampMultiplier=sscanf(fgetl(fHeader),'%f');

%Get timezone information -- continue here
RawData=textscan(fgetl(fHeader),'%s %s','delimiter',',');

%Parse out the two time codes
TimeCode=RawData{1}{1};
LocalCode=RawData{2}{1};

%Parse out the time code for offsetting to UTC
[HoursOffsetRead,OffsetReadCount]=sscanf(TimeCode,'%dh%d');

if (OffsetReadCount==1)
    HoursOffset=HoursOffsetRead;
else %More than one
    HoursOffset = sign(HoursOffsetRead(1))*(abs(HoursOffsetRead(1))+HoursOffsetRead(2)/60);
end

%Get time quality and leap-seconds code
RawData=textscan(fgetl(fHeader),'%s %d','delimiter',',');

%Extract time flag and leap-seconds flag
TimingFlag=sscanf(['0x' RawData{1}{1}],'%i');
LeapSeconds=RawData{2};

%Time flag interpretations - use somehow??
% BIN  HEX VALUE (worst case accuracy)
% 1111  F  Fault--clock failure, time not reliable
% 1011  B  Clock unlocked, time within 10 s
% 1010  A  Clock unlocked, time within 1 s
% 1001  9  Clock unlocked, time within 10-1 s
% 1000  8  Clock unlocked, time within 10-2 s
% 0111  7  Clock unlocked, time within 10-3 s
% 0110  6  Clock unlocked, time within 10-4 s
% 0101  5  Clock unlocked, time within 10-5 s
% 0100  4  Clock unlocked, time within 10-6 s
% 0011  3  Clock unlocked, time within 10-7 s
% 0010  2  Clock unlocked, time within 10-8 s
% 0001  1  Clock unlocked, time within 10-9 s
% 0000  0  Normal operation, clock locked

%Make sure the next line is the end of the config
if (strcmp(fgetl(fHeader),'</CONFIG>')==0)
    disp('CFFRead - End of CONFIG block expected, but not found!');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%% Create some CaseComR entries with what we extracted reading
CaseComR=char({['Station ID: ' station_id];
               ['Station name: ' station_name];
               ['COMTRADE Rev Year: ' num2str(rev_year)];
               ['Analog Chans = ' num2str(NumAnalogChans)];
               ['Digital Chans = ' num2str(NumDigitalChans)];
               ['Frequency = ' num2str(Line_Frequency)];
               });

%Assign the first time to PSMreftime - convert to reference from 1900
DateMATLAB=datenum(1900,1,1,0,0,0);
PSMreftime=(FirstTimeDate-DateMATLAB)*24*3600-3600*HoursOffset;  %Convert to seconds

%% Read in information section, if it exists

%Make sure it starts
if (strcmp(fgetl(fHeader),'<INFORMATION>')==0)
    disp('CFFRead - INFORMATION block header expected, but not found');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%Record our position, just in case
InfoStartPos=ftell(fHeader);

%Read data
RawData=fgetl(fHeader);
InfoEndPos=ftell(fHeader);

%Loop through until end is found
while (strcmp(RawData,'</INFORMATION>')~=0)
    InfoEndPos=ftell(fHeader);
    RawData=fgetl(fHeader);
end

%Rewind to the start of the information
fseek(fHeader,InfoStartPos,'bof');

%Read the information section - pulls off CRLF
InformationSection=(fread(fHeader,(InfoEndPos-InfoStartPos-2),'*char')).';

%Offset by one character to put us on the new line
fseek(fHeader,2,'cof');

%Read the next line again - should be end of information, but make sure
if (strcmp(fgetl(fHeader),'</INFORMATION>')==0)
    disp('CFFRead - End of INFORMATION block not found on second parse!');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%% Read in header section, if it exists

%Make sure it starts
if (strcmp(fgetl(fHeader),'<HEADER>')==0)
    disp('CFFRead - HEADER block header expected, but not found');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%Record our position, just in case
HeaderStartPos=ftell(fHeader);

%Read data
RawData=fgetl(fHeader);
HeaderEndPos=ftell(fHeader);

%Loop through until end is found
while (strcmp(RawData,'</HEADER>')~=0)
    HeaderEndPos=ftell(fHeader);
    RawData=fgetl(fHeader);
end

%Rewind to the start of the information
fseek(fHeader,HeaderStartPos,'bof');

%Read the information section - pulls off CRLF
HeaderSection=(fread(fHeader,(HeaderEndPos-HeaderStartPos-2),'*char')).';

%Offset by one character to put us on the new line
fseek(fHeader,2,'cof');

%Read the next line again - should be end of information, but make sure
if (strcmp(fgetl(fHeader),'</HEADER>')==0)
    disp('CFFRead - End of HEADER block not found on second parse!');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%% Form up the "secondary" variables - used for channel extraction later
namesXPre=cell((NumTotalChans+1),1);
namesXUnits=cell((NumTotalChans+1),1);
namesXPre{1}='Time';
namesXUnits{1}=' ';

ChanVal=2;
%Loop through and extract
for lVals=1:NumAnalogChans
    %Store
    namesXPre{ChanVal}=[AnalogInformation(lVals).Channel_ID '_' AnalogInformation(lVals).Phase];
    namesXUnits{ChanVal}=AnalogInformation(lVals).Units;
    
    %Increment
    ChanVal=ChanVal+1;
end

%Do the same for the digital channels
for lVals=1:NumDigitalChans
    %Store
    namesXPre{ChanVal}=[DigitalInformation(lVals).Channel_ID '_' AnalogInformation(lVals).Phase];
    namesXUnits{ChanVal}='bool';
    
    %Increment
    ChanVal=ChanVal+1;
end

%Combine them
namesXRaw=[char(namesXPre) repmat('  ',(NumTotalChans+1),1) char(namesXUnits)];

%Now create chankeyX
% namesX=[repmat('% ',(NumTotalChans+1),1) namesXRaw];
chankeyXpre=[repmat('% ',(NumTotalChans+1),1) num2str((1:(NumTotalChans+1)).','%d') repmat('  ',(NumTotalChans+1),1) namesXRaw];

%% Select the channels to keep, if not already done
if nXfile==1 && chansXok==0    %Call the signal selection routine
    [MenuName,chansX,chansXok]=SigSelect([],namesXRaw,chankeyXpre,CFname,SigTypes,'','','');
end

%Get total channels to output
TotalChannelOutputSize=length(chansX);

%Adjust the text-based outputs now
% namesX=[repmat('% ',TotalChannelOutputSize,1) namesXRaw(chansX,:)];
chankeyX=[repmat('% ',TotalChannelOutputSize,1) num2str((1:TotalChannelOutputSize).','%d') repmat('  ',TotalChannelOutputSize,1) namesXRaw(chansX,:)];

%% Parse data

%Read in the initial line
RawData=textscan(fgetl(fHeader),'<DATA %s %d>','delimiter',{'=',':',' ','>'},'MultipleDelimsAsOne',1);

%Make sure the first part is DATA
if (isempty(RawData{1}))
    disp('CFFRead - DATA section start expected and not found!');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%See if it matches the earlier data base type - error out if not match, since binary interpretations will be off
if (strcmp(RawData{1}{1},'ASCII'))  %We are ASCII
    if (DataType~=0)
        disp('CFFRead - DATA specified as ASCII, but binary earlier - mismatch');
    
        % Close the file header
        fclose(fHeader);
        return;
    end
    
    %Create the text parsing field
    FileParseField=['%f %f' repmat(' %f',1,NumAnalogChans) repmat(' %f',1,NumDigitalChans)];
    
    %Read the data
    RawData=textscan(fHeader,FileParseField,TotalSamples,'delimiter',',','CollectOutput',1);
    
    %Check the time fields to determine how to process the data
    %Per COMTRADE spec, if an explicit sample rate was specified, use it
    if (NumSampleRates==0)  %No sample rate specified, use timestamps
        
        %Extract and convert the timestamp column - put it in seconds
        TimeValues=RawData{1}(:,2)*TimeStampMultiplier/1e6;
        
        %Sort the time values, just in case
        [~,SortIdx]=sort(TimeValues);
        
        %Put the data into a PSMsigsX format
        PSMsigsXpre=[TimeValues(SortIdx) RawData{1}(SortIdx,3:(NumTotalChans+2))];
        
    else %One was specified, use sample number and explicit sample rate for timestamps
        if (NumSampleRates==1)
            
            %Create the timestamp from the sample number and sampling rate
            TimeValues=RawData{1}(:,1)/SampleRate;
            
        else %More than one
            %Create an empty time vector
            TimeValues=zeros(size(RawData{1}(:,1),1),1);
            
            %Set up index track
            PrevStart=1;
            TOffsetVal=-1/SampleRate(1);
            
            %Loop through rates
            for rVals=1:NumSampleRates
                %Store the time vector
                TimeValues(PrevStart:EndSample(rVals))=(RawData{1}(PrevStart:EndSample(rVals),1)-PrevStart+1)/SampleRate(rVals)+TOffsetVal;
                
                %Update trackers
                TOffsetVal=TimeValues(EndSample(rVals));
                PrevStart=EndSample(rVals)+1;
            end
        end
        
        %Put into PSMsigsX format
        PSMsigsXpre=[TimeValues RawData{1}(:,3:(NumTotalChans+2))];
    end

    %Parse one more "line", since textscan leaves one behind when you give it a set line count
    JunkData=fgetl(fHeader);
    
else %Must be binary
    if (DataType==0)
        disp('CFFRead - DATA specified as binary, but ASCII earlier - mismatch');
   
        % Close the file header
        fclose(fHeader);
        return;
    end
    
    %Figure out how many bytes the data section is
    NumberBinBytes=RawData{2};
    
    %See how big any digital channels should be - they are compressed
    if (NumDigitalChans~=0)
        NumDigitalBinChannels=ceil(double(NumDigitalChans)/16);
    else
        NumDigitalBinChannels=0;
    end

    %Preallocate a storage matrix
    BinaryStorageData=zeros(TotalSamples,(2+NumAnalogChans+NumDigitalChans));
    
    %Determine data type and read it in
    %0 = ASCII, 1 = binary, 2 = binary32, 3 = float32
    if (DataType==1)    %binary
        %Figure out expected size per line
        ExpectedSizePerEnty = (NumAnalogChans*2) + (2*NumDigitalBinChannels) + 8;
        
        %See how far we need to loop
        NumEntries=NumberBinBytes/ExpectedSizePerEnty;
        
        %Check it for consistency
        if (NumEntries ~= TotalSamples)
            disp('CFFRead - Binary sample data doesn''t match expected file length!');
            
            %Close the file header
            fclose(fHeader);
            return;
        end
        
        %Begin the loop
        for pVals=1:NumEntries
            
            %Read in the sample number and timestamp - both supposed to be 4 byte entries
            SampTimeStamp = fread(fHeader,2,'uint32',0,'l');
            
            %Store these values
            BinaryStorageData(pVals,(1:2)) = [SampTimeStamp(1) SampTimeStamp(2)];
            
            %Analog data
            if (NumAnalogChans~=0)
                %Read the data
                AnalogData = fread(fHeader,NumAnalogChans,'int16',0,'l');
                
                %Store the data
                BinaryStorageData(pVals,(3:(2+NumAnalogChans)))=AnalogData(:).';
            end
            
            %Digital data
            if (NumDigitalChans~=0)
                %Read the data
                DigitalData = fread(fHeader,NumDigitalBinChannels,'uint16',0,'l');
                
                %Convert this out to status bits array
                ArrayOfBits=dec2bin(DigitalData,16);
                
                %Now manipulate it - flipping and converting to a number
                ProperBin=double(fliplr(reshape(ArrayOfBits.',1,(NumDigitalBinChannels*16))))-48;
                
                %Store the data
                BinaryStorageData(pVals,((NumAnalogChans+3):(NumAnalogChans+NumDigitalChans+2)))=ProperBin(1:NumDigitalChans);
            end
        end
    elseif (DataType==2)    %binary32
        %Warning, for now
        disp('CFFRead - Warning, this mode is untested at present');
                
        %Figure out expected size per line
        ExpectedSizePerEnty = (NumAnalogChans*4) + (2*NumDigitalBinChannels) + 8;

        %See how far we need to loop
        NumEntries=NumberBinBytes/ExpectedSizePerEnty;
        
        %Check it for consistency
        if (NumEntries ~= TotalSamples)
            disp('CFFRead - Binary sample data doesn''t match expected file length!');
            
            %Close the file header
            fclose(fHeader);
            return;
        end
        
        %Begin the loop
        for pVals=1:NumEntries
            
            %Read in the sample number and timestamp - both supposed to be 4 byte entries
            SampTimeStamp = fread(fHeader,2,'uint32',0,'l');
            
            %Store these values
            BinaryStorageData(pVals,(1:2)) = [SampTimeStamp(1) SampTimeStamp(2)];
            
            %Analog data
            if (NumAnalogChans~=0)
                %Read the data
                AnalogData = fread(fHeader,NumAnalogChans,'int32',0,'l');
                
                %Store the data
                BinaryStorageData(pVals,(3:(2+NumAnalogChans)))=AnalogData(:).';
            end
            
            %Digital data
            if (NumDigitalChans~=0)
                %Read the data
                DigitalData = fread(fHeader,NumDigitalBinChannels,'uint16',0,'l');
                
                %Convert this out to status bits array
                ArrayOfBits=dec2bin(DigitalData,16);
                
                %Now manipulate it - flipping and converting to a number
                ProperBin=double(fliplr(reshape(ArrayOfBits.',1,(NumDigitalBinChannels*16))))-48;
                
                %Store the data
                BinaryStorageData(pVals,((NumAnalogChans+3):(NumAnalogChans+NumDigitalChans+2)))=ProperBin(1:NumDigitalChans);
            end
        end
    elseif (DataType==3)    %float32
        %Warning, for now
        disp('CFFRead - Warning, this mode is untested at present');
        
        %Figure out expected size per line
        ExpectedSizePerEnty = (NumAnalogChans*4) + (2*NumDigitalBinChannels) + 8;
        
        %See how far we need to loop
        NumEntries=NumberBinBytes/ExpectedSizePerEnty;
        
        %Check it for consistency
        if (NumEntries ~= TotalSamples)
            disp('CFFRead - Binary sample data doesn''t match expected file length!');
            
            %Close the file header
            fclose(fHeader);
            return;
        end
        
        %Begin the loop
        for pVals=1:NumEntries
            
            %Read in the sample number and timestamp - both supposed to be 4 byte entries
            SampTimeStamp = fread(fHeader,2,'uint32',0,'l');
            
            %Store these values
            BinaryStorageData(pVals,(1:2)) = [SampTimeStamp(1) SampTimeStamp(2)];
            
            %Analog data
            if (NumAnalogChans~=0)
                %Read the data
                AnalogData = fread(fHeader,NumAnalogChans,'float32',0,'l');
                
                %Store the data
                BinaryStorageData(pVals,(3:(2+NumAnalogChans)))=AnalogData(:).';
            end
            
            %Digital data
            if (NumDigitalChans~=0)
                %Read the data
                DigitalData = fread(fHeader,NumDigitalBinChannels,'uint16',0,'l');
                
                %Convert this out to status bits array
                ArrayOfBits=dec2bin(DigitalData,16);
                
                %Now manipulate it - flipping and converting to a number
                ProperBin=double(fliplr(reshape(ArrayOfBits.',1,(NumDigitalBinChannels*16))))-48;
                
                %Store the data
                BinaryStorageData(pVals,((NumAnalogChans+3):(NumAnalogChans+NumDigitalChans+2)))=ProperBin(1:NumDigitalChans);
            end
        end
    else
        disp('CFFRead - Unknown data type detected - exiting');
        
        %Close the file header
        fclose(fHeader);
        return;
    end
    
    %Check the time fields to determine how to process the data
    %Per COMTRADE spec, if an explicit sample rate was specified, use it
    if (NumSampleRates==0)  %No sample rate specified, use timestamps
        
        %Extract and convert the timestamp column - put it in seconds
        TimeValues=BinaryStorageData(:,2)*TimeStampMultiplier/1e6;
        
        %Sort the time values, just in case
        [~,SortIdx]=sort(TimeValues);
        
        %Put the data into a PSMsigsX format
        PSMsigsXpre=[TimeValues(SortIdx) BinaryStorageData(SortIdx,3:(NumTotalChans+2))];
        
    else %One was specified, use sample number and explicit sample rate for timestamps
        if (NumSampleRates==1)
            
            %Create the timestamp from the sample number and sampling rate
            TimeValues=BinaryStorageData(:,1)/SampleRate;
            
        else %More than one
            %Create an empty time vector
            TimeValues=zeros(size(BinaryStorageData(:,1),1),1);
            
            %Set up index track
            PrevStart=1;
            TOffsetVal=-1/SampleRate(1);
            
            %Loop through rates
            for rVals=1:NumSampleRates
                %Store the time vector
                TimeValues(PrevStart:EndSample(rVals))=(BinaryStorageData(PrevStart:EndSample(rVals),1)-PrevStart+1)/SampleRate(rVals)+TOffsetVal;
                
                %Update trackers
                TOffsetVal=TimeValues(EndSample(rVals));
                PrevStart=EndSample(rVals)+1;
            end
        end
        
        %Put into PSMsigsX format
        PSMsigsXpre=[TimeValues BinaryStorageData(:,3:(NumTotalChans+2))];
    end
end

%Calculate tstep - take as the median value
tstep = median(diff(PSMsigsXpre(:,1)));

%Next line should be the end of the data
if (strcmp(fgetl(fHeader),'</DATA>')==0)
    disp('CFFRead - End of DATA section expected, but not found');
    
    % Close the file header
    fclose(fHeader);
    return;
end

%% End checks and finalizing

%Last line should be record close
if (strcmp(fgetl(fHeader),'</RECORD>')==0)
    disp('CFFRead - End of RECORD expected, but not found');
    
    % Close the file header
    fclose(fHeader);
    return;
end

% Close the file header
fclose(fHeader);

%Parse out the final file set - easier to just let it read everything and strip later
PSMsigsX=PSMsigsXpre(:,chansX);
