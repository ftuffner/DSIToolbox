function funMatlab2dst(fname,PMUNames,Vphasor,Iphasor,freq,dfdt,Time)

% Use Stream Format
% Function to write *.dst file from Matlab using the Stream format.
% Sample rate of data is set in the *.ini file.
%
% Inputs:
%   fname = character string for *.dst file name.  Currently supported file name is
%       TEC1_YYMMDDHHMM.dst
%   PMUNames = npmu by 4 character array.  Row k is the 4 charater name
%       for pmu k (note: npmu = number of pmu's).
%   Vphasor = nrow by npmu of complex phasor samples.  row k is the kth sample
%      (note:  nrow is the number of samples; each pmu has one phasor sample).
%   Iphasor = nrow by npmu of complex phasor samples.  row k is the kth sample
%   freq = nrow by npmu of frequency error samples in milliHz.  row k
%       is the kth sample.
%   dfdt = nrow by npmu of frequency error samples in milliHz.  row k
%       is the kth sample.
%   Time = 1 by 6 time tag for data.  Format is provided by matlab's clock
%       command.  Time is rounded to the nearest minute.  We've been using
%       the same "time" as in fname.

% Written by P. Debnath and D. Trudnowski (Montana Tech).  2006

% Error checks
[Nrows,Npmu] = size(Vphasor);
if size(freq,1)~=Nrows; error('Dimension error in freq'); end
if size(freq,2)~=Npmu; error('Dimension error in freq'); end
if size(dfdt,1)~=Nrows; error('Dimension error in dfdt'); end
if size(dfdt,2)~=Npmu; error('Dimension error in dfdt'); end
if size(PMUNames,1)~=Npmu; error('Dimension error in PMUNames'); end
if size(PMUNames,2)~=4; error('Dimension error in PMUNames'); end
if size(Time,1)~=1; error('Dimension error in Time.'); end
if size(Time,2)~=6; error('Dimension error in Time.'); end

% Round time to nearest minute
Time = [round(Time(1,1:5)) 0];

%Open file
[fid, message] = fopen([fname '.dst'],'w', 'b'); % Open the specified *.dst file
if fid==-1; error('Cannot open file.'); end

% Start of the File Header Section
count = fwrite(fid,hex2dec('AACC0202'),'uint32'); %File header.  Time starts 1970.  Exclude DBUF
count = fwrite(fid,hex2dec('54454331'),'uint32'); %File Source ID ('TEC1')
%count = fwrite(fid,hex2dec('42504131'),'uint32'); %File Source ID ('BPA1'); use this for testing using bpa naming
count = fwrite(fid,(34+2*Npmu)*4,'uint32'); %Number of bytes (K*4) in header.
count = fwrite(fid,etime(Time,[1970 01 01 00 00 00]),'uint32'); % start time is the time in sec between current time 
                                                                % and '01-JAN-1970' at 00 hours 00 minutes and 00 seconds
count = fwrite(fid,0,'uint32'); %Start Sample.  It is the sample number of the first sample in the data file
count = fwrite(fid,hex2dec('0001001E'),'uint32'); % Sample rate - 30 samples/sec
count = fwrite(fid,5*Npmu,'uint32'); % Row length - the number of long words in each row
count = fwrite(fid,Nrows,'uint32'); % Number of rows (assumes 30 samples/sec)
count = fwrite(fid,etime(Time,[1970 01 01 00 00 00]),'uint32'); % Trigger time-the same format as start time
count = fwrite(fid,0,'uint32'); %Trigger Sample.  If we assume no trigger is detected (same as start sample)
count = fwrite(fid,0,'uint32'); %Pre-Trigger Rows is Zero-since there is no trigger detected
count = fwrite(fid,0,'uint32'); %PMU# where trigger detected(higher 16 bit), PMU type of trigger(lower 16 bit)
                                % since we assume there is no trigger detected, so whole 32 bit is zero
for k=1:20
    count = fwrite(fid,0,'uint32'); %ASCII information-its an optional/ we set to zero
end
count = fwrite(fid,Npmu,'uint32');   % Number of PMUs with data in record
for k = 1:Npmu
    x=[dec2hex(double(PMUNames(k,1))) dec2hex(double(PMUNames(k,2))) dec2hex(double(PMUNames(k,3))) dec2hex(double(PMUNames(k,4)))];
    count = fwrite(fid,hex2dec(x),'uint32'); % PMU k name
    count = fwrite(fid,(k-1)*5,'uint32');  % Offset for PMU k
end
clear x
count = fwrite(fid,hex2dec('AACCAACC'),'uint32'); %End of  header flag
% End of the File Header Section

% Start of the Data Section
for row=1:Nrows
    for cntphsr=1:Npmu        
        %Channel Flag. Byte 1 = "Flag bits" -- Macrodyne format.  Byte 2 =
        %Data Rate = 30 samples/sec.  Byte 3 = Number of digital words (no digital words used).
        %Byte 4 = Number of phasors = 2 (one voltage one current).
        count=fwrite(fid,hex2dec([dec2hex(2,2) dec2hex(30,2) dec2hex(0,2) dec2hex(2,2)]),'uint32');

        %Sample/Status.  First 2 bytes = sample number = row-1.  2nd 2
        %bytes = 0 (pmu flags).
        count=fwrite(fid,hex2dec([dec2hex(row-1,4) dec2hex(0,4)]),'uint32');
    
        %Phasor data
        %keyboard;
        if 0 %Orignal code from Dan
            count=fwrite(fid,int16(imag(Vphasor(row,cntphsr))),'int16'); %voltage imag part      
            count=fwrite(fid,int16(real(Vphasor(row,cntphsr))),'int16'); %voltage real part
            count=fwrite(fid,int16(imag(Iphasor(row,cntphsr))),'int16'); %current real part
            count=fwrite(fid,int16(real(Iphasor(row,cntphsr))),'int16'); %current imag part
        else    % modified code added by Ning Zhou 05/15/2007
            count=fwrite(fid,int16(real(Vphasor(row,cntphsr))),'int16'); %voltage real part
            count=fwrite(fid,int16(imag(Vphasor(row,cntphsr))),'int16'); %voltage imag part      
            count=fwrite(fid,int16(real(Iphasor(row,cntphsr))),'int16'); %current real part
            count=fwrite(fid,int16(imag(Iphasor(row,cntphsr))),'int16'); %current imag part
        end
       
        
        %Frequency and df/dt
        count=fwrite(fid,int16(freq(row,cntphsr)),'int16'); %freq
        count=fwrite(fid,int16(dfdt(row,cntphsr)),'int16'); %df/dt
    end   
end
fclose(fid);
