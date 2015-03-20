function [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
     spoles,zpoles]...
    =ModeMeterC(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansAout,TRange,tstepMM,decfac,...
     chansAin,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars,Method, namesXAll);
 
%keyboard;
%load temp

%
%  [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
%    spoles,zpoles]...
%   =ModeMeterC(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%    chansAout,TRange,tstep,decfac,...
%    chansAin,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars, Method);
%   Method= 1: YW, 2:YW/Spectral, 3: N4SID
%
% Functions called by ModeMeterB:
%    funL1Subspace
%    promptyn, promptnv
%    (others?)  
%
% Core code developed by D. Trudnowski with Montana Tech
% Integration into PSM_Tools by N. Zhou, 
% Pacific Northwest National Laboratory.
%
% Modified 10/17/2006.  nz

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMpaths PSMfiles PSMreftimes
%global PSMtype CFname PSMpaths PSMfiles PSMreftimes

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------
if 0     
  save Debug_04  
  keyboard
elseif  0
 clear all
 close all
 clc
 load Debug_04
 Method=2;
end


FNname='ModeMeterC';

disp(' ')
disp(['In ' FNname ': EXPERIMENTAL CODE'])

chankeyX=names2chans(namesX); 

%Clear outputs
CaseComMM=''; SaveFileMM='';
namesMM=namesX; TRangeMM=TRange;
spoles=[]; zpoles=[];

%*************************************************************************
%Set parameters for ModeMeter analysis [old code]


%[put display here]
%*************************************************************************

%--------------------------------------
% default parameters required by Dan's Code

%YW algorithm parameters
YW.strIDName='Yule Walker Method';
YW.Ts = 1/decfrq; %Sample period (seconds)
YW.n= 25; %AR order
YW.m = 10; %MA order
YW.MAR = round(10/YW.Ts); %number of data points to be included from the autocorrlation when solving for the AR coef.
YW.MRes = YW.MAR; %number of data points to be included from the autocorrlation when solving for the Energy terms.
YW.Nfft= 0; %Size of fft window for estimating PSD if Method = 2.

%YW with Spectrum analysis algorithm parameters
YWS.strIDName='YW Spectrum Method';
YWS.Ts = 1/decfrq; %Sample period (seconds)
YWS.n = 25; %AR order
YWS.m = 10; %MA order
YWS.MAR= round(10/YWS.Ts); %number of data points to be included from the autocorrlation when solving for the AR coef.
YWS.MRes = YWS.MAR; %number of data points to be included from the autocorrlation when solving for the Energy terms.
YWS.Nfft= round(Tbar/YWS.Ts); %Size of fft window for estimating PSD if Method = 2.

%N4SID algorithm parameters
N4SID.strIDName='N4SID Method';
N4SID.Ts = 1/decfrq; %Sample period (seconds)
N4SID.n = 20; %AR order
N4SID.m = 5; %MA order
N4SID.MAR = round(10/N4SID.Ts); %number of data points to be included from the autocorrlation when solving for the AR coef.
N4SID.MRes = N4SID.MAR; %number of data points to be included from the autocorrlation when solving for the Energy terms.
N4SID.Nfft= 0; %Size of fft window for estimating PSD if Method = 2.


DampMax = 0.2; %Modes with a damping raio greater than DampMax are not returned.
%Frange = [0.2;0.5]; %First element is the min. frequency of the modes
%Frange = [0.1; 0.9]; %First element is the min. frequency of the modes
EnergyMin = 0.01; %Modes with a relative energy less than EnergyMin are not returned.


%Nfft_YW = round(2*60/Ts_YW); %Size of fft window for estimating PSD if Method = 2.

%*************************************************************************
%Setup using D. Trudnowski template

switch(Method)
    case 1      % YW
        Chosen=YW;                                 % targeted sampling rate in seconds

    case 2      % YWS
        Chosen=YWS;                                 % targeted sampling rate in seconds
      
    case 3      % N4SID
        Chosen=N4SID;                                 % targeted sampling rate in seconds
        
    otherwise
        disp(['In ' FNname ': Invalid Identification method. Press anykey to continue ...']);
        pause
        return;
end

%******************************
% add the chance to change the parameter selection

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard
if ~isfield(PSMMacro, 'ModeMeterC_Chosen'), PSMMacro.ModeMeterC_Chosen=NaN; end
if (PSMMacro.RunMode<1 || ~isstruct(PSMMacro.ModeMeterC_Chosen))      % Not in Macro playing mode or selection not defined in a macro
    while(1)
        disp(' ')
        disp(' ')
        disp(['In ' FNname ': Identification Parameter Selection: ' ]);
        disp(Chosen);
        IDParaOK=promptyn('Use these parameters? ', 'y');
        if ~IDParaOK
          disp('Invoking "keyboard" command ');
          disp('Type "return" when you are done')
          disp('- You may modify the field in "Chosen" to change ID parameters.')
          keyboard
        else 
            break;
        end
    end
else
    Chosen=PSMMacro.ModeMeterC_Chosen;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterC_Chosen=Chosen;
    else
        PSMMacro.ModeMeterC_Chosen=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

%detrend
if SpecTrnd
    yOrg=detrend(PSMsigsX(:,chansAout));          % Experiment 1, output
else
    yOrg=PSMsigsX(:,chansAout);          % Experiment 1, output
end

%Decimation
yDeci = [];         %Decimated ambient data for N4SID alorithms
Nout=length(chansAout);
for k = 1:Nout
    
    tempVar=var(yOrg(:,k));
    if tempVar>0.0000001
        x = yOrg(:,k)./sqrt(tempVar); %Subset select and normalize ambient signal
        yDeci(:,k) = resample(x,round(1/Chosen.Ts),round(1/tstepMM)); %Resample with period Ts_N4SID
    end
end
% parameters required by Dan's Code
%--------------------------------------

%keyboard;
[spoles,Energy,rAuto,rAutohat] = funModeMeterAmbient(yDeci, Chosen.Ts,Chosen.n, Chosen.m,Chosen.MAR, Chosen.MRes,DampMax,Frange,EnergyMin,Method,Chosen.Nfft);

%------------------------------------21-----------------
% Start: display the identification results

[Freq, DR]=funFindModes(spoles);
Np=length(Freq);
disp('     ')
disp(['In ' FNname ':']);
disp(['Major Modes identified using:  ' Chosen.strIDName] );
disp('Index     Relative Energy(%)         Frequency(Hz)    Damping Ratio(%)');
disp('-------------------------------------------------------------------------------------------------------');
for nIndex=1:Np
    disp(sprintf('%d)            Energy=%4.1f%%          freq=%5.4f(Hz)           DR=%4.2f%% ', nIndex, Energy(nIndex)*100, Freq(nIndex),DR(nIndex)));
end
disp('-------------------------------------------------------------------------------------------------------');
% 
% start: save mode meter results in xls files
%       by ZN 2007/07/25

if ~isfield(PSMMacro, 'ModeMeterC_saveok'), PSMMacro.ModeMeterC_saveok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterC_saveok))      % Not in Macro playing mode or selection not defined in a macro
    saveok=promptyn(['In ' FNname ': Do you want to save the mode meter results? '],'y');
else
    saveok=PSMMacro.ModeMeterC_saveok;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterC_saveok=saveok;
    else
        PSMMacro.ModeMeterC_saveok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end

if saveok
    CurrentDate=datestr(now);
    MMLogFileName=sprintf('ModeMeterResults%s.xls',date);
    MMLogFileNameAppdx=sprintf('ModeMeterResults%sAppdx.xls',date);
    %--------------------------------------------------------------   
    % 1.0 write the mode meter results
    fidMMLog=fopen([PSMpaths MMLogFileName], 'a');        % open a file to add
    if fidMMLog<0
       disp('Can not open the log file to store the mode meter analysis results.');
       fidMMLog=1;
    end

    posMMFreq = ftell(fidMMLog);
    if ~posMMFreq       % write the head of the event scan file
        fprintf(fidMMLog,'\tCalculation start time \t Data start date\t Data start time\t Duration (min)'); 
        fprintf(fidMMLog,'\tMode Index \tRelative Energy(%%) \tFrequency(Hz) \tDamping Ratio(%%)');
        fprintf(fidMMLog,'\tNumber Outputs \tNumber Inputs \tPath \tAuxiliary File \tNumber of data files \tIdentification Data channels');
    end
    
    for nIndex=1:Np
 
        fprintf(fidMMLog,'\n');

        % analysis results
        [DateString,MatlabTime]=PSM2Date(PSMreftimes(1));
        fprintf(fidMMLog, '\t%s \t%s \t%s',CurrentDate, datestr(MatlabTime,'mm/dd/yyyy'), datestr(MatlabTime,'HH:MM:SS'));
        fprintf(fidMMLog, '\t%3.2f',(TRange(2)-TRange(1))/60.0);
        fprintf(fidMMLog, '\t%d \t%4.1f \t%5.4f \t%4.2f ', ...
            nIndex, Energy(nIndex)*100, Freq(nIndex),DR(nIndex));
                
        % data summary
        fprintf(fidMMLog, '\t%d',length(chansAout));    % number of output channels
        fprintf(fidMMLog, '\t%d',length(chansAin));     % number of input channels
        fprintf(fidMMLog, '\t%s', PSMpaths);            % path
        fprintf(fidMMLog, '\t%s', MMLogFileNameAppdx);  % name of auxiliary files (contains the load information)        
        NumFiles=size(PSMfiles,1);                      
        fprintf(fidMMLog,'\t%d', NumFiles);             % number of data files

        
        % channel(output) data
        for chIndex=1:length(chansAout)
            chNum=chansAout(chIndex);
            fprintf(fidMMLog, '\tOutput: %s',namesX(chIndex,:));     % channels name
            tempMedian=median(PSMsigsX(:,chNum));
            %fprintf(fidMMLog, '\t%10.2f',tempMedian);    % median
            %fprintf(fidMMLog, '\t%10.2f',median(abs(PSMsigsX(:,chNum)-tempMedian))/0.6745);    % median
        end
        
        % channel (input) data
        for chIndex=1:length(chansAin)
            chNum=chansAin(chIndex);
            fprintf(fidMMLog, '\tInput: %s',namesX(chIndex+length(chansAout),:));     % channels name
            tempMedian=median(PSMsigsX(:,chNum));
            %fprintf(fidMMLog, '\t%10.2f',tempMedian);    % median
            %fprintf(fidMMLog, '\t%10.2f',median(abs(PSMsigsX(:,chNum)-tempMedian))/0.6745);    % median
        end
       
        

        % file data
        for fIndex=1:NumFiles
            fprintf(fidMMLog,'\t%s', PSMfiles(fIndex,:));
        end
    end

    if fidMMLog>2
        fclose(fidMMLog);       %close the log file
    end
    
    %--------------------------------------------------------------
    % 2.0 write an appendix file to record the environmental data (e.g. MW)
    
    fidMMLogAppdx=fopen([PSMpaths MMLogFileNameAppdx], 'a');        % open a file to add
    
    if fidMMLogAppdx<0
       disp('Can not open the log file to store the power system states.');
       fidMMLogAppdx=1;
    end

    posMMFreq = ftell(fidMMLogAppdx);
    if ~posMMFreq       % write the head of the file
        fprintf(fidMMLogAppdx,'\tCalculation start time \t Data start date\t Data start time\t Duration (min)'); 
        fprintf(fidMMLogAppdx,'\tAvailable Channel Names \tMedian \tStd (Median)');
    end

    % channel(output) data
    for chIndex=2:size(namesXAll,1)
        fprintf(fidMMLogAppdx,'\n');
        fprintf(fidMMLogAppdx, '\t%s \t%s \t%s',CurrentDate, datestr(MatlabTime,'mm/dd/yyyy'), datestr(MatlabTime,'HH:MM:SS'));
        fprintf(fidMMLogAppdx, '\t%3.2f',(TRange(2)-TRange(1))/60.0);
        fprintf(fidMMLogAppdx, '\t%s',namesXAll(chIndex,:));     % channels name
        tempMedian=median(PSMsigsX(:,chIndex));
        fprintf(fidMMLogAppdx, '\t%10.2f',tempMedian);    % median
        fprintf(fidMMLogAppdx, '\t%10.2f',median(abs(PSMsigsX(:,chIndex)-tempMedian))/0.6745);    % median
    end
    
    if fidMMLogAppdx>2
        fclose(fidMMLogAppdx);       %close the log file
    end

    disp(' ');
    disp(sprintf('Results from mode meter analysis are saved in [%s%s]',PSMpaths, MMLogFileName));
    disp(sprintf('Power system states are saved in [%s%s]',PSMpaths, MMLogFileNameAppdx));
    disp(' ');
    %
    % End: save mode meter results in xls files
    %       by ZN 2007/07/25
end

% End:   display the identification results
%-----------------------------------------------------



disp(' ')
disp(['In ' FNname ': PROCESSING COMPLETE'])
if ~ynprompt
    if PSMMacro.RunMode<1
        disp('Press Any Key to continue.....');
        pause
    end
end
%keyboard;
if (PSMMacro.RunMode<1)
    keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '],'n');
    if keybdok
      disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
    end
else
    pause(2);
end
disp(['Return from ' FNname]); disp(' ')

%end of ModeMeter function