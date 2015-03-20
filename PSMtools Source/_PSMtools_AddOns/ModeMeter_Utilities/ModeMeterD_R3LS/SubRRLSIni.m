%Copyright Battelle Memorial Institute.  All Rights Reserved.

    handles.reStart=2;                       % start re-sampling index 2???
    sigIndx = get(handles.hdlSigSelect,'Value') + 1;
    handles.NChannel=size(handles.Data,2)-1;            % number of channels in the data
    handles.NChannel=size(handles.Data,2)-1;            % number of channels in the data
    bAllChannels = get(handles.hdlAllChannelsCheck,'Value');    
    
    if bAllChannels
        if handles.bInputChannels
            handles.lModel=handles.NChannel-handles.Nu;      % number of output channels
        else
            handles.lModel=handles.NChannel;      % number of output channels
        end
    else
        handles.lModel=1;
    end
    
   % if bAllChannels
   %       handles.lModel=handles.NChannel;
   % else
   %       handles.lModel=1;
   % end
   
    handles.Nu=1;
    handles.OutlierCount02=zeros(handles.lModel,1);
    handles.RegularizationCount02=0;% zeros(handles.lModel,1);
    
    handles.epsilon2=zeros(handles.lModel,1);
    handles.pErr2=ones(handles.aOrder2+handles.bOrder2+handles.cOrder2+10,handles.lModel)*inf;           % prediction errors from stage 2
    handles.phi0s2=NaN(handles.aOrder2+handles.bOrder2+handles.cOrder2+1,handles.lModel);               % wait the buffer populated before starting (stage 2)
    
    if isempty(handles.IniModelPoles)
        handles.P2=1e6*eye(handles.aOrder2+(handles.bOrder2+handles.cOrder2)*handles.lModel);                % variance matrix for stage 2
        handles.P2(handles.aOrder2+1:end,handles.aOrder2+1:end)=1e6*eye((handles.bOrder2+handles.cOrder2)*handles.lModel);                % variance matrix for stage 2
        handles.th2 = zeros(handles.aOrder2+(handles.bOrder2+handles.cOrder2)*handles.lModel,1);              % see the rarx.m() for definition (parameters for stage #2)
    else
        %-----------------------------------------------
        % start: prepare for the mode regulation term (known initial mode)
        z=exp(handles.IniModelPoles*handles.TsID);        % estimated discrete poles
        vv=handles.IniModeWeight;         % weighting parameter should be proportional to mean(pErr2)^2 and windows size;
        tSteps=2;                    % equivalent steps of ringdown signal
        SigStd=NaN;                     %std(std(PSMsigsX(1:6000,2)));  % standard deviation of the ambient data
        if isnan(SigStd)
            SigStd=24;
        end
        [handles.th2, handles.P2]=funR3LSModesIni(z, vv, SigStd, tSteps, [handles.aOrder2, handles.cOrder2,handles.bOrder2], handles.lModel);
        % end: prepare for the mode regulation term
        %-----------------------------------------------      
    end
    
    
    handles.zSamplePast=NaN*zeros(2,handles.lModel);
    handles.vSamplePast=NaN*zeros(2,handles.Nu);
    
    %---------------------------------
    % start: parameters for limited time window
    %bL=round(3*60*FsID)                %window length in steps
    %bL=0;                               %unlimited window
    bL=handles.WindowSize;
    handles.PhiLextY=NaN(bL,handles.lModel);    % data output
    handles.PhiLextU=NaN(bL,handles.lModel);    % data input
    handles.PhiLextE=NaN(bL,handles.lModel);    % data prediction errors
    handles.PhiPrimeHist=NaN(bL,handles.lModel);    % historical data for 2nd derivative of the robust function.
    handles.LamLHist=ones(bL,1);
    %temp=1;
    % the above parameters are to be used to construct the
    % phiL( for limited window size data)
    % end: parameters for limited time window
    %---------------------------------

    % detrending
    % keyboard;
    
    [xTrend,handles.meBufFix,handles.mePntFixBuf,handles.mePreLength,handles.thetaX,handles.Rx,handles.oTime,handles.FFDetrend]=...
        funRMedianDetrendNaN([],[handles.meBufSize,handles.lModel]);
   
    [uTrend,handles.meBufFixU,handles.mePntFixBufU,handles.mePreLengthU,handles.thetaXU,handles.RxU,handles.oTimeU,handles.FFDetrendU]=...
        funRMedianDetrendNaN([],[handles.meBufSize,handles.Nu]);

    handles.FFDetrend=0.9998*ones(size(handles.FFDetrend));                      % forgeting factor for the recursive detrend
    

    % anti-alias filter
    [handles.yHat,handles.meBufFixD,handles.mePntFixBufD,handles.mePreLengthD]=...
        funRMedianFilter([],[handles.meBufSizeD,handles.lModel]);
    [handles.uHat,handles.meBufFixDU,handles.mePntFixBufDU,handles.mePreLengthDU]=...
        funRMedianFilter([],[handles.meBufSizeD,handles.Nu]);
