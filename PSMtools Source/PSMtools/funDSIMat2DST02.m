%******************************************************
% The main code for converting standard DSI format data (*.mat)
% into *.dst and *.ini files
%   Multi-phasors in one PMU
%
%                       by Ning Zhou 2007/06/01
%
function funDSIMat2DST02(PSMsigsX,PSMreftimes,namesX,tstep)

%
% Input Parameters:(standarad format defined by DSI toolbox
%
% PSMsigsX(TimeSeq, chanSeq), store the signals
% PSMreftimes,		     reference time.
% namesX(chanSeq, :),	     store the names of the signal. 
%			    First 4 letters stand for PMU name
%               Note in western data there are: [SCE1pmu0][SCE1pmu1]
%
% tstep,		     sampling period
%
%
%
% Output Files:
%
% TEC1_[yymmddhhmm].ini file
% TEC1_[yymmddhhmm].dst file
%

dstRefDateStr=PSM2Date(PSMreftimes);
dstRefTime=datevec(dstRefDateStr); %PSM2Date(PSMreftimes);

FileNameTarget=['TEC1_', datestr(dstRefDateStr(1,:),'yymmddHHMM')];
bUseDynamicRange=1;                                % 0: use the default values
                                                   % 1: use the dynamic range
ChannelSeq=[];                                     % the sequence of the channels                                                   

% 1.2 constants used in generating *.dst file
KVfact=sqrt(3)*1.e-3;   KAfact=1.e-3;
r2deg=180/pi;
dstFreqScale=1.e-3;     dstFreqOffset=60;

% 1.3 default config for the Voltage phasor

PhasorV_default=[4500.0,0.0060573,0,0,500];     % voltage phasor defaults (see *.ini for details) Ratio, Cal Factor, Offset, Shunt, VoltageRef/Class, Label
%PhasorI_default=[400 ,0.0000401397,0,0.1,1];
PhasorI_default=[600.00,0.000040382,0,1,1.0];   % current phasor defaults
PhasorF_default=[1000,60,1000,0,0];
NumberPhasors=2;

%--------------------------------------
% 2.0 prepare the original data 
%


% 2.2 select a subset of the channels
if ~isempty(ChannelSeq)
    PSMsigsX=PSMsigsX(:,ChannelSeq);
    namesX=namesX(ChannelSeq,:);
    chankeyX=chankeyX(ChannelSeq,:);
end

%dstRefDateStr=PSM2Date(PSMreftimes);
%dstRefTime=datevec(dstRefDateStr); %PSM2Date(PSMreftimes);
      

[dstPMUNames, mTemp, PhasorSeq]=unique(namesX(:,1:4),'rows');       % first 4 rows must contains the PMU names
timeIndex=strmatch('time',lower(dstPMUNames));


dstNumPMUChannel=size(dstPMUNames,1);
dstNumPMU=dstNumPMUChannel-length(timeIndex);

dstNumData=size(PSMsigsX,1);

%----------------------------------------
% 2.4 locate the phasor data

% 2.4.1 find the position of feature word 'VMag' 
%       other feature word include 'VAng', 'IMag', 'IAng'
for chIndex=1:dstNumPMUChannel
  sigTypeNamePos=strfind(lower(namesX(chIndex,:)),'vmag');     % assume that all the channel names are aligned
  if ~isempty(sigTypeNamePos), break; end
end


dstPMU=cell(dstNumPMUChannel,1);

for pmuIndex=1:dstNumPMUChannel
    dstPMU{pmuIndex}.dstPMUName=dstPMUNames(pmuIndex,:);    % PMU's name
    if pmuIndex==timeIndex
        dstPMU{pmuIndex}.SeqPhasor=[];
        dstPMU{pmuIndex}.NumPhasor=0;        % indicate that there are no phasor available for this channel
        continue;
    else
        % find the phasor position
        PhasorSeqChannel=find(PhasorSeq==pmuIndex);
        localImagSeq=strmatch('imag',lower(namesX(PhasorSeqChannel,sigTypeNamePos:sigTypeNamePos+3)));
        localIangSeq=strmatch('iang',lower(namesX(PhasorSeqChannel,sigTypeNamePos:sigTypeNamePos+3)));

        localVmagSeq=strmatch('vmag',lower(namesX(PhasorSeqChannel,sigTypeNamePos:sigTypeNamePos+3)));
        localVangSeq=strmatch('vang',lower(namesX(PhasorSeqChannel,sigTypeNamePos:sigTypeNamePos+3)));

        localFreqSeq=strmatch('freq',lower(namesX(PhasorSeqChannel,sigTypeNamePos:sigTypeNamePos+3)));
        localDfDtSeq=strmatch('dfdt',lower(namesX(PhasorSeqChannel,sigTypeNamePos:sigTypeNamePos+3)));

        
        
        dstPMU{pmuIndex}.VmagSeq=PhasorSeqChannel(localVmagSeq);
        dstPMU{pmuIndex}.VangSeq=PhasorSeqChannel(localVangSeq);
        dstPMU{pmuIndex}.dstVPhasorScale=ones(length(dstPMU{pmuIndex}.VmagSeq),1);         % save the phasor's scaling factor

        dstPMU{pmuIndex}.ImagSeq=PhasorSeqChannel(localImagSeq);
        dstPMU{pmuIndex}.IangSeq=PhasorSeqChannel(localIangSeq);
        dstPMU{pmuIndex}.dstIPhasorScale=ones(length(dstPMU{pmuIndex}.ImagSeq),1);         % save the phasor's scaling factor
        
        
        dstPMU{pmuIndex}.FreqSeq=PhasorSeqChannel(localFreqSeq);
        dstPMU{pmuIndex}.DfDtSeq=PhasorSeqChannel(localDfDtSeq);
        

       

        
        % find the phasor number
        dstPMU{pmuIndex}.NumPhasor=length(dstPMU{pmuIndex}.VmagSeq)+length(dstPMU{pmuIndex}.ImagSeq);      % number of phasors in (pmuIndex) PMU
        
        % allocate memory for the phasor's name
        dstPhsrNameSeq=5:sigTypeNamePos-1;
        dstPhsrNameLength=length(dstPhsrNameSeq);
        if dstPhsrNameLength
            dstPMU{pmuIndex}.dstPhsrName=char(32*ones(dstPMU{pmuIndex}.NumPhasor,dstPhsrNameLength,'int8'));
        else
            dstPMU{pmuIndex}.dstPhsrName=char(86*ones(dstPMU{pmuIndex}.dstNumPMU,15,'int8'));
        end
    end
    
    dstPMU{pmuIndex}.dstPhasor=ones(dstNumData, dstPMU{pmuIndex}.NumPhasor);    % save the phasor's value
    
    dstPMU{pmuIndex}.dstPhasorFilled=ones(dstPMU{pmuIndex}.NumPhasor,1);        % 1 mag filled,  10 ang filled; 11 both are filled
    dstPMU{pmuIndex}.dstFreq=zeros(dstNumData, 1);           
    dstPMU{pmuIndex}.dstDfDt=zeros(dstNumData, 1);
end




%----------------------------------------
% 2.6 prepare the phasor data for writing in *.dst format
if isempty(sigTypeNamePos)
  disp('Can not find the Phasor Signal');
else
  for pmuIndex=1:dstNumPMUChannel
      if dstPMU{pmuIndex}.NumPhasor<=0
          continue;
      end
      
      phasorIndex=0;
      phasorVIndex=0;

      %2.6.1 Voltage phasors
      for VphsrIndex=1:length(dstPMU{pmuIndex}.VmagSeq)
          phasorIndex=phasorIndex+1;
          phasorVIndex=phasorVIndex+1;
          % phasor's name
          dstPMU{pmuIndex}.dstPhsrName(phasorIndex,:)=namesX(dstPMU{pmuIndex}.VmagSeq(VphsrIndex), dstPhsrNameSeq);
                    
          % voltage magnitudes  
          dstPMU{pmuIndex}.dstPhasor(:, phasorIndex)=...
              dstPMU{pmuIndex}.dstPhasor(:, phasorIndex).*PSMsigsX(:,dstPMU{pmuIndex}.VmagSeq(VphsrIndex))/(KVfact*PhasorV_default(1)*PhasorV_default(2));   % file the mag value
          
          % voltage angles  --> assume that the Vang are in the same sequence as Vmag
          if VphsrIndex<=length(dstPMU{pmuIndex}.VangSeq)
              dstPMU{pmuIndex}.dstPhasor(:, phasorIndex)=...
                  dstPMU{pmuIndex}.dstPhasor(:, phasorIndex).*exp(j*PSMsigsX(:,dstPMU{pmuIndex}.VangSeq(VphsrIndex))/r2deg);;   % file the Voltage angles
              % check phasor's name
              if ~strcmp(namesX(dstPMU{pmuIndex}.VmagSeq(VphsrIndex), dstPhsrNameSeq),...
                        namesX(dstPMU{pmuIndex}.VangSeq(VphsrIndex), dstPhsrNameSeq)) 
                    disp('Warning: Miss match found in phasor name in magnitudes and angles');
                    disp(['In mag:', namesX(dstPMU{pmuIndex}.VmagSeq(VphsrIndex), dstPhsrNameSeq)]);
                    disp(['In ang:', namesX(dstPMU{pmuIndex}.VangSeq(VphsrIndex), dstPhsrNameSeq)]);
              end
          else
              disp('Warning: Not enough angle data');
          end
              

          % dynamic ranges  
          if bUseDynamicRange
              tempData=abs([real(dstPMU{pmuIndex}.dstPhasor(:, phasorIndex)); imag(dstPMU{pmuIndex}.dstPhasor(:, phasorIndex))]);
              tempMax=max(tempData); 
              if tempMax>0.1
                  dstPMU{pmuIndex}.dstVPhasorScale(phasorVIndex)=32000/tempMax;  % max int 16;
              end
              dstPMU{pmuIndex}.dstPhasor(:, phasorIndex)=...
                  dstPMU{pmuIndex}.dstPhasor(:, phasorIndex)*dstPMU{pmuIndex}.dstVPhasorScale(phasorVIndex);
          end    
          
      end  % end [Voltages phasors]---> for VphsrIndex=1:length(dstPMU{pmuIndex}.VmagSeq) 
      
      
      %2.6.2 Current phasors
      phasorAIndex=0;
      for IphsrIndex=1:length(dstPMU{pmuIndex}.ImagSeq)
          phasorIndex=phasorIndex+1;
          phasorAIndex=phasorAIndex+1;
          % phasor's name
          dstPMU{pmuIndex}.dstPhsrName(phasorIndex,:)=namesX(dstPMU{pmuIndex}.ImagSeq(IphsrIndex), dstPhsrNameSeq);
                    
          % current magnitudes  
          dstPMU{pmuIndex}.dstPhasor(:, phasorIndex)=...
              dstPMU{pmuIndex}.dstPhasor(:, phasorIndex).*PSMsigsX(:,dstPMU{pmuIndex}.ImagSeq(IphsrIndex))/(KAfact*PhasorI_default(1)*PhasorI_default(2)/PhasorI_default(4));   % file the mag value
          
          % current angles  --> assume that the Iang are in the same sequence as Imag
          if IphsrIndex<=length(dstPMU{pmuIndex}.IangSeq)
              dstPMU{pmuIndex}.dstPhasor(:, phasorIndex)=...
                  dstPMU{pmuIndex}.dstPhasor(:, phasorIndex).*exp(j*PSMsigsX(:,dstPMU{pmuIndex}.IangSeq(IphsrIndex))/r2deg);;   % file the Current angles
              % check phasor's name
              if ~strcmp(namesX(dstPMU{pmuIndex}.ImagSeq(IphsrIndex), dstPhsrNameSeq),...
                        namesX(dstPMU{pmuIndex}.IangSeq(IphsrIndex), dstPhsrNameSeq)) 
                    disp('Warning: Miss match found in phasor name in magnitudes and angles');
                    disp(['In mag:', namesX(dstPMU{pmuIndex}.ImagSeq(IphsrIndex), dstPhsrNameSeq)]);
                    disp(['In ang:', namesX(dstPMU{pmuIndex}.IangSeq(IphsrIndex), dstPhsrNameSeq)]);
              end
          else
              disp('Warning: Not enough angle data');
          end
              

          % dynamic ranges  
          if bUseDynamicRange
              tempData=abs([real(dstPMU{pmuIndex}.dstPhasor(:, phasorIndex)); imag(dstPMU{pmuIndex}.dstPhasor(:, phasorIndex))]);
              tempMax=max(tempData); 
              if tempMax>0.1
                  dstPMU{pmuIndex}.dstIPhasorScale(phasorAIndex)=32000/tempMax;  % max int 16;
              end
              dstPMU{pmuIndex}.dstPhasor(:, phasorIndex)=...
                  dstPMU{pmuIndex}.dstPhasor(:, phasorIndex)*dstPMU{pmuIndex}.dstIPhasorScale(phasorAIndex);
          end    
          
      end  % end [Current phasors]---> for IphsrIndex=1:length(dstPMU{pmuIndex}.ImagSeq) 

          
      %2.6.3 Frequency
      if ~isempty(dstPMU{pmuIndex}.FreqSeq)
          dstPMU{pmuIndex}.dstFreq=(PSMsigsX(:,dstPMU{pmuIndex}.FreqSeq(1))-dstFreqOffset)/dstFreqScale;
      end
      
      %2.6.4 Frequency changing rate       % may not be available from the standard DSI format
      if ~isempty(dstPMU{pmuIndex}.DfDtSeq)
          dstPMU{pmuIndex}.dstDfDt=(PSMsigsX(:,dstPMU{pmuIndex}.DfDtSeq(1)))/dstFreqScale;
      end
  end       % end "for pmuIndex=1:dstNumPMUChannel"
end         % end "if isempty(sigTypeNamePos)"
disp(' ');
disp('------------------------------')
disp(['start writing *.dst file: [', FileNameTarget, ']']);
%keyboard;
funMatlab2dst02(FileNameTarget,dstPMU,dstRefTime(1,:));
disp('End writing dst files');
disp(' ')
%----------------------------------------
% 2.8 prepare writing *.ini files

FileNameIni=[FileNameTarget, '.ini'];
FileNameDST=[FileNameTarget, '.dst'];
disp(['start writing *.ini file: [', FileNameIni, ']']);

fidIni = fopen(FileNameIni, 'wt');
if fidIni<0
    disp('Can not open the ini file for writing. Mission failed !!');
    fclose(fidIni); return;
end

fprintf(fidIni, '; File: %s \n', FileNameIni);
fprintf(fidIni, '; This is an auto-generated *.ini. It should be used with ''%s'' only. \n\n', FileNameDST);

fprintf(fidIni, '[DEFAULT]\n');
fprintf(fidIni, 'PhasorV=V, %5.1f, %12.11f, %d, %d, %d, Default 500kV   ;\n', ...
    PhasorV_default(1), PhasorV_default(2), PhasorV_default(3),PhasorV_default(4),PhasorV_default(5));
fprintf(fidIni, 'PhasorI=I, %5.1f, %12.11f, %d, %d, %d, Default Current   ;\n', ...
    PhasorI_default(1), PhasorI_default(2), PhasorI_default(3),PhasorI_default(4),PhasorI_default(5));
fprintf(fidIni, 'Frequency=F, %5.1f, %8.2f, %d, %d, %d, Default Freq   ;\n', ...
    PhasorF_default(1), PhasorF_default(2), PhasorF_default(3),PhasorF_default(4),PhasorF_default(5));

fprintf(fidIni, '\n[CONFIG]\n');
fprintf(fidIni, 'SampleRate=%4.2f   ; Number of samples per second \n', 1/tstep);  
fprintf(fidIni, 'NumberOfPMUs=%d       ; Number of PMUs individually \n\n', dstNumPMU);

pmuCount=0;
for pmuIndex=1:dstNumPMUChannel
    if ~dstPMU{pmuIndex}.NumPhasor; continue; end
    fprintf(fidIni, '\n[%s]\n', dstPMU{pmuIndex}.dstPMUName);
    fprintf(fidIni, 'Name=PMU%d %s \n', pmuCount, dstPMU{pmuIndex}.dstPMUName);
    fprintf(fidIni, 'PMU=%d \n', pmuCount);
    pmuCount=pmuCount+1;
    fprintf(fidIni, 'NumberPhasors=%d \n', dstPMU{pmuIndex}.NumPhasor);
    
    %Voltage phasors
    phsrIndex=0;
    for VphsrIndex=1:length(dstPMU{pmuIndex}.VmagSeq)
        phsrIndex=phsrIndex+1;
        fprintf(fidIni, 'PhasorV=V, %5.1f, %12.11f, %d, %d, %d, %s;\n', ...
            PhasorV_default(1), PhasorV_default(2)/dstPMU{pmuIndex}.dstVPhasorScale(VphsrIndex), PhasorV_default(3),PhasorV_default(4),PhasorV_default(5), ...
                deblank(dstPMU{pmuIndex}.dstPhsrName(phsrIndex, :)));
    end
    
    %Current phasors
    for IphsrIndex=1:length(dstPMU{pmuIndex}.ImagSeq)
        phsrIndex=phsrIndex+1;
        fprintf(fidIni, 'PhasorI=I, %5.1f, %12.11f, %d, %d, %d, %s;\n', ...
            PhasorI_default(1), PhasorI_default(2)/dstPMU{pmuIndex}.dstIPhasorScale(IphsrIndex), PhasorI_default(3),PhasorI_default(4),PhasorI_default(5), ...
                deblank(dstPMU{pmuIndex}.dstPhsrName(phsrIndex, :)));
    end
    
    %fprintf(fidIni, 'PhasorI=I, %5.1f, %12.11f, %d, %d, %d, %s;\n', ...
    %    PhasorI_default(1), PhasorI_default(2)/dstIPhasorScale(pmuIndex), PhasorI_default(3),PhasorI_default(4),PhasorI_default(5), deblank(dstPhsrIName(pmuIndex, :)));
    fprintf(fidIni, 'Frequency=F, %5.1f, %8.2f, %d, %d, %d, Default Freq   ;\n', ...
        PhasorF_default(1), PhasorF_default(2), PhasorF_default(3),PhasorF_default(4),PhasorF_default(5));
end
fclose(fidIni);
disp('Finished *.ini file....');
disp('------------------------------');
