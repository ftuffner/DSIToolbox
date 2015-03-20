function funMatlab2dst02(fname,PMU,Time)

% Use Stream Format
% Function to write *.dst file from Matlab using the Stream format.
% Sample rate of data is set in the *.ini file.
%
% Inputs:
%   fname = character string for *.dst file name.  Currently supported file name is
%       TEC1_YYMMDDHHMM.dst
%
%   PMU: Cell struture, which stores the PMU data
%   PMU{pmuIndex}.dstPMUName: an 4 character array
%   PMU{pmuIndex}.NumPhasor: The number of phasors in the PMU; 0 means no PMU
%   PMU{pmuIndex}.dstPhsrName(phIndex,:)     : The [phIndex] phasor's name
%   PMU{pmuIndex}.dstPhasor(timeSeq, phIndex): The [phIndex] phasor's value(complex)
%   PMU{pmuIndex}.dstFreq(timeSeq)           : frequency error samples in milliHz. 
%   PMU{pmuIndex}.dstDfDt(timeSeq)           : frequency error samples in milliHz.

%   Time = 1 by 6 time tag for data.  Format is provided by matlab's clock
%       command.  Time is rounded to the nearest minute.  We've been using
%       the same "time" as in fname.
%
% Modified by Ning Zhou on 06/01/2007  from
% [funMatlab2dst.m] written by P. Debnath and D. Trudnowski (Montana Tech).  2006
% to add multiple phasors

% 1.0 find Num of PMU  and length of data
NpmuChannel=size(PMU,1);
Npmu=0; Nrows=0;
for pmuIndex=1:NpmuChannel
    if PMU{pmuIndex}.NumPhasor>0
        Npmu=Npmu+1;
        
        if ~Nrows 
            Nrows=size(PMU{pmuIndex}.dstPhasor,1); 
        end
        % Error checks
        if size(PMU{pmuIndex}.dstFreq,1)~=Nrows; error('Dimension error in freq'); end
        if size(PMU{pmuIndex}.dstDfDt,1)~=Nrows; error('Dimension error in freq'); end
        if size(PMU{pmuIndex}.dstPMUName,2)~=4; error('Dimension error in freq'); end        
    end
end
%keyboard;
if size(Time,1)~=1; error('Dimension error in Time.'); end
if size(Time,2)~=6; error('Dimension error in Time.'); end

% Round time to nearest minute
Time = [round(Time(1,1:5)) 0];

%2.0 write the *.dst file
%Open file
[fid, message] = fopen([fname '.dst'],'w', 'b'); % Open the specified *.dst file
if fid==-1; error('Cannot open file.'); end
count=0;

% 2.1 Start of the File Header Section
count = count+ fwrite(fid,hex2dec('AACC0202'),'uint32'); %File header.  Time starts 1970.  Exclude DBUF
count = count+fwrite(fid,hex2dec('54454331'),'uint32'); %File Source ID ('TEC1')
%count = count+fwrite(fid,hex2dec('42504131'),'uint32'); %File Source ID ('BPA1'); use this for testing using bpa naming
count = count+fwrite(fid,(34+2*Npmu)*4,'uint32'); %Number of bytes (K*4) in header.
count = count+fwrite(fid,etime(Time,[1970 01 01 00 00 00]),'uint32'); % start time is the time in sec between current time 
                                                                % and '01-JAN-1970' at 00 hours 00 minutes and 00 seconds
count = count+fwrite(fid,0,'uint32'); %Start Sample.  It is the sample number of the first sample in the data file
count = count+fwrite(fid,hex2dec('0001001E'),'uint32'); % Sample rate - 30 samples/sec
RowLength=0;
for pmuIndex=1:NpmuChannel
    if PMU{pmuIndex}.NumPhasor
        RowLength=RowLength+PMU{pmuIndex}.NumPhasor+3;
    end
end
count = count+fwrite(fid,RowLength,'uint32'); % Row length - the number of long words in each row
count = count+fwrite(fid,Nrows,'uint32'); % Number of rows (assumes 30 samples/sec)
count = count+fwrite(fid,etime(Time,[1970 01 01 00 00 00]),'uint32'); % Trigger time-the same format as start time
count = count+fwrite(fid,0,'uint32'); %Trigger Sample.  If we assume no trigger is detected (same as start sample)
count = count+fwrite(fid,0,'uint32'); %Pre-Trigger Rows is Zero-since there is no trigger detected
count = count+fwrite(fid,0,'uint32'); %PMU# where trigger detected(higher 16 bit), PMU type of trigger(lower 16 bit)
                                % since we assume there is no trigger detected, so whole 32 bit is zero
for k=1:20
    count = count+fwrite(fid,0,'uint32'); %ASCII information-its an optional/ we set to zero
end
count = count+fwrite(fid,Npmu,'uint32');   % Number of PMUs with data in record
pmuOffset=0;
for k = 1:NpmuChannel
    if PMU{k}.NumPhasor
        PMUNames=PMU{k}.dstPMUName;
        x=[dec2hex(double(PMUNames(1))) dec2hex(double(PMUNames(2))) dec2hex(double(PMUNames(3))) dec2hex(double(PMUNames(4)))];
        count = count+fwrite(fid,hex2dec(x),'uint32'); % PMU k name
        count = count+fwrite(fid,pmuOffset,'uint32');  % Offset for PMU k
        pmuOffset=pmuOffset+3+PMU{k}.NumPhasor;
    end
end
clear x
count = count+fwrite(fid,hex2dec('AACCAACC'),'uint32'); %End of  header flag
% End of the File Header Section (2.1)

% 2.2 Start of the Data Section
for row=1:Nrows     % time loop
    for pmuIndex=1:NpmuChannel  % PMU loop
        if ~PMU{pmuIndex}.NumPhasor; continue; end;
     
        %Channel Flag. Byte 1 = "Flag bits" -- Macrodyne format.  Byte 2 =
        %Data Rate = 30 samples/sec.  Byte 3 = Number of digital words (no digital words used).
        %Byte 4 = Number of phasors = 2 (one voltage one current).
        count=fwrite(fid,hex2dec([dec2hex(2,2) dec2hex(30,2) dec2hex(0,2) dec2hex(PMU{pmuIndex}.NumPhasor,2)]),'uint32');

        %Sample/Status.  First 2 bytes = sample number = row-1.  2nd 2
        %bytes = 0 (pmu flags).
        count=fwrite(fid,hex2dec([dec2hex(row-1,4) dec2hex(0,4)]),'uint32');

        for cntphsr=1:PMU{pmuIndex}.NumPhasor   % phasor loop
            count=fwrite(fid,int16(real(PMU{pmuIndex}.dstPhasor(row,cntphsr))),'int16'); %voltage real part
            count=fwrite(fid,int16(imag(PMU{pmuIndex}.dstPhasor(row,cntphsr))),'int16'); %voltage imag part      
        end     % end -->     for cntphsr=1:NpmuChannel   % phasor loop

        %Frequency and df/dt
        count=fwrite(fid,int16(PMU{pmuIndex}.dstFreq(row)),'int16'); %freq
        count=fwrite(fid,int16(PMU{pmuIndex}.dstDfDt(row)),'int16'); %df/dt
        
    end         % end -->     for pmuIndex=1:NpmuChannel  % PMU loop
end             % end -->     for row=1:Nrows     % time 
fclose(fid);
