% Copyright Battelle Memorial Institute.  All Rights Reserved."
%
% Mode Meter Demo (for power system)
%
% Warning: the mode meter codes are for the demo purpose only
%
%    To start the mode meter demo, 
%       1) change the current directory of Matlab to ‘\ModeMeterDemo?R\’.
%       2) type in ‘ModeMeterOfflineDemo’ in the command window of matlab.
%    Note that the codes are tested under matlab 7.1.
%
%
% Author (Algorithms):  Ning Zhou, Battelle - Pacific Northwest National Laboratory
%           [funRarxRobustExtP05MIMOoffline]
% Author (Data Link):  Jeff Johnson, Battelle - Pacific Northwest National Laboratory
%
% Questions and suggestions can be sent to
%           ning.zhou@pnl.gov; jeffrey.johnson@pnl.gov
%
% Date:    Sept 12, 2006
%
% Last Modified by Ning Zhou on 03/02/2007      % for MIMO ARMA model 
% Last Modified by Ning Zhou on 05/07/2007      % for regularization ARMAX model 
% Last Modified by Ning Zhou on 08/22/2008      % for GUI improvement and DSItoolbox integration 

function varargout = ModeMeterOfflineDemo(varargin)
% MODEMETEROFFLINEDEMO:  PDCDataReader Demonstration Program
% M-file for ModeMeterOfflineDemo.fig
% Begin initialization code - DO NOT EDIT

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ModeMeterOfflineDemo_OpeningFcn, ...
                   'gui_OutputFcn',  @ModeMeterOfflineDemo_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT





% --- Executes just before ModeMeterOfflineDemo is made visible.
function ModeMeterOfflineDemo_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ModeMeterOfflineDemo (see VARARGIN)

% Choose default command line output for ModeMeterOfflineDemo
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ModeMeterOfflineDemo wait for user response (see UIRESUME)
% uiwait(handles.hdlFigureMain);

% -- JMJ Begin --

% Start progress annunciate
fprintf(1,'\nInitializing %s ',mfilename);

% Create default configuration file if none found
cfgFile = [mfilename 'Config.m'];

if exist(cfgFile) ~= 2
  try
    util_DefaultConfigFile(cfgFile);
  catch
    error(sprintf('Error creating configuration file:  %s',lasterr));
  end
    msg = ['Configuration file ''%s'' not found ... Created.\n\n' ...
           'At the Matlab command prompt (>>), type\n\n' ...
           'edit %s\n\n' ...
           'Change ''PDCConfigFile'' and enter a valid PDC configuration file path.\n' ...
           'Change ''PDCUDPPort'' and enter a port on which to receive PDC data packets.\n' ...
           'Save and enter %s to restart demo.\n'];
    error(sprintf(msg,cfgFile,cfgFile,mfilename));
end

% Load configuration parameters
run(cfgFile(1:end-2));
handles.udPlotWindowSec    = PlotWindowSec;
handles.udDFTWindowLength  = DFTWindowLength;
handles.udDFTWindowOverlap = DFTWindowOverlap;
handles.ModelType=ModelType;
%clc
%fprintf(1,'.');

% initialize logo
axes(handles.Logo);
iLogo=imread('logo.tif');
image(iLogo);
axis off;


% Additional variables
handles.udDisplayCount    = -1;
handles.udPlotBuffer.time = [];
handles.udPlotBuffer.data = [];
handles.tagTimer          = [mfilename 'Timer'];

% Default label for frequency domain plot
vis = get(0,'ShowHiddenHandles'); set(0,'ShowHiddenHandles','on');
axes(handles.hdlFreqAxes); %text(0.5,0.5,'Future Waterfall Plot','HorizontalAlignment','center');
set(handles.hdlFreqAxes,'XLim',[0,1]);
%set(handles.hdlFreqAxes,'XLim',[0 1],'YLim',[0 1],'XTick',[],'YTick',[]);
set(0,'ShowHiddenHandles',vis);

% Set initial Run Status indicator value
set(handles.hdlRunStatus,'String','Waiting for Descriptor');

handles.PDCMatPath=PDCMatPath;
handles.PDCMatFile=PDCMatFile;
if exist('sigIndxInput')
    handles.sigIndxInput=sigIndxInput-1;
    handles.sigIndx=sigIndx-1;
else
    handles.sigIndxInput=1;
    handles.sigIndx=1;
end
handles.udPlotBuffer.tf = -Inf;

%-------------------------------------------------------
% load new data set
SubLoadNewData;

% running speed control
handles.TopSpeed=TopSpeed;                          % highest speed
handles.NormalPeriod=1/handles.TopSpeed;     % the period corresponding to the highest speed

set(handles.hdlSpeedSlider,'Min',0)
set(handles.hdlSpeedSlider,'Max',handles.TopSpeed);
set(handles.hdlSpeedSlider,'Value',handles.TopSpeed);
set(handles.hdlSpeedSlider,'SliderStep',[1/handles.TopSpeed, 1/handles.TopSpeed]);
handles.Speed=get(handles.hdlSpeedSlider,'Value');
handles.SpeedPeriod=round(handles.TopSpeed/handles.Speed);
handles.SpeedCount=0;
set(handles.hdlSpeedEdit,'String',...
    num2str(handles.Speed));
handles.bInputChannels = get(handles.hdlInputChannelsCheck,'Value');

%*********************************************************************
% 1.0 Added by Ning Zhou to initiate some variables for the mode meter

% 1.1 parameters for resampling

%handles.reStart=2;                       % start re-sampling index

% 1.2 start: added by Ning Zhou on 08/15/2006
handles.AmpIndex=1;                      
handles.xPlotLimit=[-1, 0.1];
handles.yPlotLimit=[0,    1];
handles.DRBorder=DRBorder;              % damping ratio border
handles.DRBorderAngle=acos(-handles.DRBorder/100);
handles.DRBorderRadius= sqrt((handles.xPlotLimit(1)-handles.xPlotLimit(2)).^2+...
                             ((handles.yPlotLimit(1)-handles.yPlotLimit(2))*2*pi).^2);      % 2*pi for the the coversion of Hz -> angular freq
handles.DRBorderX=handles.DRBorderRadius*cos(handles.DRBorderAngle);
handles.DRBorderY=(handles.DRBorderRadius*sin(handles.DRBorderAngle))/(2*pi);               % convert to the freq (Hz)
handles.DRBorderColor=['r';'m';'g';'b' ];
handles.DRFillColor=[1, 0.9, 0.9;
                     0.95, 0.95, 0.8;
                     0.9, 1, 0.9;
                     0.9, 0.9, 0.9;];
% 1.2 end: added by Ning Zhou on 08/15/2006


% 1.3 parameters for the recursive identification method algorithm

handles.NumMajorPoles=NumMajorPoles;                                   % number of modes to be displayed

%ARMA model parameters
handles.aOrder2=aOrder2;                     %AR
handles.bOrder2=bOrder2;                     %X
handles.cOrder2=cOrder2;                     %MA
handles.kOrder2=kOrder2;
handles.delta2=delta2;

if isfield(handles,'SaveModeFID')
    if handles.SaveModeFID>0
        handles.SaveModeFID=fclose(handles.SaveModeFID);
    end
else
    handles.SaveModeFID=0;
end
handles.SaveModeFileName=SaveModeFileName;
handles.SaveMode=SaveMode;


handles.WindowSize=round(WindowLength*handles.FsID);    %  number of steps
   
if exist('IniModeFreq');
    handles.IniModeFreqHalf  =IniModeFreq;
    handles.IniModeDRHalf    =IniModeDR;
    handles.IniModeWeightHalf=IniModeWeight;
        
    temp=handles.IniModeFreqHalf*2*pi;
    tempsPoles=temp.*cot(acos(-handles.IniModeDRHalf /100))+j*temp;
    if size(tempsPoles,1)==1
        tempsPoles=tempsPoles.';
    end
    handles.IniModelPoles=[tempsPoles;conj(tempsPoles)];
    
    if size(IniModeWeight,1)==1
        IniModeWeight=IniModeWeight.';
    end
    handles.IniModeWeight=[IniModeWeight;IniModeWeight];
else
    handles.IniModelPoles=[];
    handles.IniModeFreqHalf  =[];
    handles.IniModeDRHalf    =[];
    handles.IniModeWeightHalf=[];
end
%end

% 1.5 parameters for the recursive detrend algorithm
meBufSize=fix(2/handles.FsID*Fs);      % buffer size of the median filter for detrend
%meBufSize=11;                 % buffer size of the median filter (an odd number is required)
if ~mod(meBufSize,2)
    meBufSize=meBufSize+1;
end
handles.meBufSize=meBufSize;     % buffer size of the median filter for detrend

% 1.7 parameters for the data extraction median filter

meBufSizeD=7;                 % buffer size of the median filter (an odd number is required)
if ~mod(meBufSizeD,2)
    meBufSizeD=meBufSizeD+1;
end
handles.meBufSizeD=meBufSizeD;
handles.meBufSizeU=handles.meBufSizeD;                  % buffer size of the median filter (an odd number is required)

handles.ForgFactor02=1-1/(ForgTimeConst02*FsTarget);     % forgeting factor for rarx.m()    
handles.ForgTimeConst02=ForgTimeConst02;     % forgeting factor for rarx.m()    

strFigTitle=sprintf('RRLS ARMAX{%d,%d,%d}, ForgetFactorTime=%4.1f min, Window=%4.1f min',handles.aOrder2,handles.cOrder2, handles.bOrder2,handles.ForgTimeConst02/60, handles.WindowSize/(handles.FsID*60));
set(handles.hdlModelPara,'String',strFigTitle);

if handles.PDCMatLoaded 
    %------------------------------------------------------
    % initialize the parameters for the RRLS algorithms
    SubRRLSIni;
end

% 1.9 parameters for the mode plot
handles.hdlPlotMode=NaN;
handles.hdlPlotModeBoundary=NaN;
handles.hdlPlotModeUnstable=NaN;
handles.hdlFreq=NaN; 
handles.hdlPeakSpectrum=NaN;

handles.DataTimer=clock;
handles.PackCount=0;


handles.bodyLength =10;

handles.hdlPlotBody=nan(2*handles.NumMajorPoles,1);                 % modified by Ning Zhou on 11/17/2006
handles.ModeBufferX=nan(2*handles.NumMajorPoles,handles.bodyLength);
handles.ModeBufferY=nan(2*handles.NumMajorPoles,handles.bodyLength);;

figNumber=gcf;
set(figNumber,'Backingstore','off');
axes(handles.hdlModeAxes);
cla;

%------------------------------------------------------------------------
% Start: added by Ning Zhou on 08/15/2006 for damping ratio border
hold on
for bIndex=1:length(handles.DRBorder)
    plot([0,handles.DRBorderX(bIndex)],[0, handles.DRBorderY(bIndex)],[handles.DRBorderColor(bIndex),'--'],'LineWidth',2)
end

 xTemp=zeros(4,1);
 yTemp=zeros(4,1);
    
 for bIndex=1:length(handles.DRBorder)-1
     xTemp(2)=handles.DRBorderX(bIndex);
     yTemp(2)=handles.DRBorderY(bIndex);
     xTemp(3)=handles.DRBorderX(bIndex+1);
     yTemp(3)=handles.DRBorderY(bIndex+1);
     patch(xTemp,yTemp,handles.DRFillColor(bIndex,:),'EdgeColor','y'); %handles.DRBorderColor(bIndex,:))
 end
    
 bIndex=bIndex+1;
 xTemp(2)=-2;
 yTemp(2)=0;
 patch(xTemp,yTemp,handles.DRFillColor(bIndex,:),'EdgeColor','y'); %handles.DRBorderColor(bIndex,:))
    

for bIndex=1:length(handles.DRBorder)
    plot([0,handles.DRBorderX(bIndex)],[0, handles.DRBorderY(bIndex)],[handles.DRBorderColor(bIndex),'--'],'LineWidth',2)
end

legend(num2str(handles.DRBorder',' Damping Ratio = %2.1f %%'),'Location','Southwest');
wMode=get(handles.hdlModeAxes,'position');
wFreq=get(handles.hdlFreqAxes,'position');
wFreq(2:end)=wMode(2:end);
set(handles.hdlFreqAxes,'position',wFreq);

%disp(wMode)
% End:   added by Ning Zhou on 08/15/2006 for damping ratio border
%------------------------------------------------------------------------

box(handles.hdlModeAxes,'on');
set(handles.hdlModeAxes,'XLim',handles.xPlotLimit,'YLim',handles.yPlotLimit, ...
            'Drawmode','fast', 'Visible','on','NextPlot','add');
        

        
     
ylabel('Freq (Hz)');
xlabel('\sigma');

% 1.0 End addition by Ning Zhou to initiate some variables for the mode meter
%*********************************************************************


% Delete any remaining timer objects
hdlTimer = timerfind('Tag', handles.tagTimer);
for ii = 1:length(hdlTimer)
  if ~isvalid(hdlTimer(ii)); continue; end
  stop(hdlTimer(ii)); delete(hdlTimer(ii));
end

% Create a timer to check for new descriptor, data, or error.
% Note:  Would like to use PDCDataReader ActiveX events here,
% but need a way to obtain the control's parent figure handle.
hdlTimer = timer('Tag', handles.tagTimer, 'BusyMode', 'drop', ...
  'ExecutionMode','fixedRate', 'Period',handles.NormalPeriod, ...
  'ErrorFcn',{@timer_ErrorFcn, handles}, ...
  'TimerFcn',{@timer_TimerFcn, handles});

fprintf(1,'.');

handles.hdlTimer=hdlTimer;

% Update handles structure
handles.TimerIn =0;
guidata(hObject, handles);

% Finish progress annunciate
set(handles.hdlStop,'Enable','off');
% start(hdlTimer);
% if isvalid(handles.hdlTimer)
%     stop(handles.hdlTimer);
% end

fprintf(1,' done\n');
% -- JMJ End --

% end:  function ModeMeterOfflineDemo_OpeningFcn(hObject, eventdata, handles, varargin)
%########################################################################





% --- Outputs from this function are returned to the command line.
function varargout = ModeMeterOfflineDemo_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function hdlSigSelect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hdlSigSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in hdlSigSelect.
function hdlSigSelect_Callback(hObject, eventdata, handles)
% hObject    handle to hdlSigSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns hdlSigSelect contents as cell array
%        contents{get(hObject,'Value')} returns selected item from hdlSigSelect

% -- JMJ Begin --

% Reset plot data buffer
% set(handles.hdlAllChannelsCheck,'Enable','inactive');

if isvalid(handles.hdlTimer)
    stop(handles.hdlTimer);
end

if handles.TimerIn 
   handles.TimerIn=0; 
   guidata(hObject, handles);
   msgbox('The data stream has been stopped. Please try again!','modal');
   return;
end

handles.udPlotBuffer.time = [];


%*************************************************************************
% 1.0 Added by Ning Zhou to Re-initialize the data for RLS function

% Trigger a plot data buffer reset
handles.udPlotBuffer.tf = -Inf;
handles.blockCount=0;

%??????????????????????????????????????
% Trigger a plot data buffer reset
handles.udPlotBuffer.tf = -Inf;
handles.blockCount=0;
% 1.3 parameters for the recursive identification method algorithm
if 1
    SubRRLSIni;
end
% 1.8 Added by Ning Zhou on 08/15/2006 to correct the displaying unit to MW
% and MVAR
val = get(hObject,'Value');
string_list = get(hObject,'String');
MyString = string_list(val,:); 
MVARok=strfind(MyString, 'MVAR');
MWok=strfind(MyString, 'MW');
if ~isempty(MVARok) || ~isempty(MWok)
    handles.AmpIndex=3*10^-6;
else 
    handles.AmpIndex=1;
end
% 1.8 End Added by Ning Zhou on 08/15/2006 to correct the displaying unit to MW


% 1.9 parameters for the mode plot
hdlModeAxes = findobj(handles.hdlModeAxes,'Type','line');

axes(handles.hdlFreqAxes); drawnow; cla;

axes(handles.hdlModeAxes); drawnow; cla;

% start: added by Ning Zhou 08/15/2006
hold on
for bIndex=1:length(handles.DRBorder)
    plot([0,handles.DRBorderX(bIndex)],[0, handles.DRBorderY(bIndex)],[handles.DRBorderColor(bIndex),'--'],'LineWidth',2)
end

xTemp=zeros(4,1);
yTemp=zeros(4,1);
    
 for bIndex=1:length(handles.DRBorder)-1
     xTemp(2)=handles.DRBorderX(bIndex);
     yTemp(2)=handles.DRBorderY(bIndex);
     xTemp(3)=handles.DRBorderX(bIndex+1);
     yTemp(3)=handles.DRBorderY(bIndex+1);
     patch(xTemp,yTemp,handles.DRFillColor(bIndex,:),'EdgeColor','y'); %handles.DRBorderColor(bIndex,:))
 end
    
 bIndex=bIndex+1;
 xTemp(2)=-2;
 yTemp(2)=0;
 patch(xTemp,yTemp,handles.DRFillColor(bIndex,:),'EdgeColor','y'); %handles.DRBorderColor(bIndex,:))
 
 for bIndex=1:length(handles.DRBorder)
    plot([0,handles.DRBorderX(bIndex)],[0, handles.DRBorderY(bIndex)],[handles.DRBorderColor(bIndex),'--'],'LineWidth',2)
 end


box(handles.hdlModeAxes,'on');
set(handles.hdlModeAxes,'XLim',handles.xPlotLimit,'YLim',handles.yPlotLimit, ...
            'Drawmode','fast', 'Visible','on','NextPlot','add');
% end: added by Ning Zhou 08/15/2006

handles.hdlPlotMode=NaN;
handles.hdlPlotModeBoundary=NaN;
handles.hdlPlotModeUnstable=NaN;
handles.hdlFreq=NaN; 
handles.hdlPeakSpectrum=NaN;

handles.DataTimer=clock;
handles.hdlPlotBody=handles.hdlPlotBody*NaN;
handles.ModeBufferX=handles.ModeBufferX*NaN;
handles.ModeBufferY=handles.ModeBufferY*NaN;

%1.11 parameters for the spectral plot
axes(handles.hdlFreqAxes)
cla
% 1.0 end addition by Ning Zhou to Re-initialize the data for RLS function
%*************************************************************************

%?????????????????????????????????????

% 1.8 Added by Ning Zhou on 08/15/2006 to correct the displaying unit to MW
% and MVAR
val = get(hObject,'Value');
string_list = get(hObject,'String');
MyString = string_list(val,:); 
MVARok=strfind(MyString, 'MVAR');
MWok=strfind(MyString, 'MW');

% START: plot the general time plots, Ning Zhou 10/02/2006
  sigIndx = get(handles.hdlSigSelect,'Value') + 1;
  
  MyData=handles.Data(:,sigIndx);       % signal selected
  MyTime=handles.Data(:,1);             % time duration
  axes(handles.hdlWholeTimeAxes);
  cla;
  line(MyTime, MyData,'color','c');
  handles.hdlAniWhole=NaN;
  MedTemp=median(MyData);
  STDTemp=std(MyData);
  set(handles.hdlWholeTimeAxes,'yLim',[MedTemp-4*STDTemp,MedTemp+4*STDTemp], 'xLim', [MyTime(1),MyTime(end)]);
% End: plot the general time plots, Ning Zhou 10/02/2006


% START: plot the general time plots of the input, Ning Zhou 05/07/2007
  handles.bInputChannels = get(handles.hdlInputChannelsCheck,'Value');    
  if handles.bInputChannels 
      sigIndxInput = get(handles.hdlSigSelectInput,'Value') + 1;

      MyDataInput=handles.Data(:,sigIndxInput);       % signal selected
      MyTime=handles.Data(:,1);             % time duration
      axes(handles.hdlWholeTimeAxesInput);
      cla;
      line(MyTime, MyDataInput,'color','c');
      handles.hdlAniWholeInput=NaN;
      MedTemp=median(MyDataInput);
      STDTemp=std(MyDataInput);
      set(handles.hdlWholeTimeAxesInput,'yLim',[MedTemp-4*STDTemp,MedTemp+4*STDTemp], 'xLim', [MyTime(1),MyTime(end)]);
    % End: plot the general time plots of the input, Ning Zhou 05/07/2007
  else
      axes(handles.hdlWholeTimeAxesInput);
      cla;
  end


% Update handles structure
guidata(hObject, handles);

%if isvalid(handles.hdlTimer)
%    start(handles.hdlTimer);
%end


% -- JMJ End --

% --- Executes on button press in hdlClose.
function hdlClose_Callback(hObject, eventdata, handles)
% hObject    handle to hdlClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% -- JMJ Begin --

%aOrder=handles.aOrder;
%phi0=handles.phi0;
%P=handles.P;
%th=handles.th;
%pErr=handles.pErr;

% save PreviousModel aOrder phi0 P th pErr;
% Execute Figure CloseRequestFcn
hdlFigureMain_CloseRequestFcn(handles.hdlFigureMain, eventdata, handles);

% -- JMJ End --

% --- Executes when user attempts to close hdlFigureMain.
function hdlFigureMain_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to hdlFigureMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% -- JMJ Begin --

% Delete any remaining timer objects
%keyboard
hdlTimer = timerfind('Tag',handles.tagTimer);
for ii = 1:length(hdlTimer)
  if ~isvalid(hdlTimer(ii)); continue; end
  stop(hdlTimer(ii)); delete(hdlTimer(ii));
end

% Delete instance of PDCDataReader
if isfield(handles,'hdlPDCDataReader')
  if ishandle(handles.hdlPDCDataReader); delete(handles.hdlPDCDataReader); end
end

% -- JMJ End --

% Hint: delete(hObject) closes the figure
delete(hObject);

% -------------------------- JMJ Added Functions --------------------------
% Executes when timer object fires
function timer_TimerFcn(hdlTimer, eventdata, handles)
% hdlTimer           Handle to timer object
% eventdata          Event data (supplied by timer object)
% handles            structure with handles and user data (see GUIDATA)

% Update handles structure
handles = guidata(handles.hdlFigureMain);
handles.TimerIn=1;
guidata(handles.hdlFigureMain, handles);

set(handles.hdlAllChannelsCheck,'Enable','inactive');
set(handles.hdlInputChannelsCheck,'Enable','inactive');
set(handles.hdlPlay,'Enable','off');
set(handles.hdlLoad,'Enable','off');
set(handles.hdlSigSelect,'Enable','off');
set(handles.hdlSigSelectInput,'Enable','off');
set(handles.hdlClose,'Enable','off');
%set(handles.pushbuttonConfig,'Enable','off');
set(handles.hdlStop,'Enable','on');

%hdlCtrl      = handles.hdlPDCDataReader;
hdlRunStatus = handles.hdlRunStatus;

redraw = 0;

% Toggle run status indicator visibility
if 0    % ~handles.PDCMatLoaded
    vis = get(hdlRunStatus,'Visible');
    if strcmp(vis,'on'); vis = 'off'; else; vis = 'on'; end
    set(hdlRunStatus,'Visible',vis);
end

% Process all newDescriptor and newData notifications
%while 1
if 1
  % New Data has come
  if handles.PDCMatLoaded  % util_PDCDataReaderRead(hdlCtrl,'NewData')
    handles.SpeedCount=handles.SpeedCount+1;  
    if handles.SpeedCount>=handles.SpeedPeriod
        handles.SpeedCount=0;
    else
        guidata(handles.hdlFigureMain, handles);
        return
    end
    
     valTemp= round(str2double(get(handles.hdlSpeedEdit,'String')));
     if handles.Speed~=valTemp
         handles.Speed=valTemp;
         set(handles.hdlSpeedEdit,'String',...
            num2str(handles.Speed));
         handles.SpeedPeriod=round(handles.TopSpeed/handles.Speed);
         handles.SpeedCount=0;
     end

%    handles.SpeedTurbo=get(handles.hdlSpeedCheckbox, 'Value');
%    if handles.SpeedTurbo
%        handles.Speed=8;
%        handles.SpeedPeriod=round(handles.TopSpeed/handles.Speed);
%        handles.SpeedCount=0;
%    else
%        handles.Speed=2;
%        handles.SpeedPeriod=round(handles.TopSpeed/handles.Speed);
%        handles.SpeedCount=0;
%    end
    
    % Read signal select index
    sigIndx = get(handles.hdlSigSelect,'Value') + 1;
    sigIndxInput = get(handles.hdlSigSelectInput,'Value') + 1;

%    keyboard;
    % Read sample rate, sample number and signal data
    fs   = double(1/handles.Ts);
    blockSize=floor(1*fs);
    handles.blockCount=handles.blockCount+blockSize;
    [NData, NChan]=size(handles.Data);
    bAllChannels = get(handles.hdlAllChannelsCheck,'Value'); 
%    keyboard;
    sigSeq=2:handles.NChannel+1;
    if handles.bInputChannels
        sigSeq=setdiff(sigSeq, sigIndxInput);
    end
       
    
    
    if NData>handles.blockCount
       data = double(handles.Data(handles.blockCount-blockSize+1:handles.blockCount,:));
    else
        set(handles.hdlAllChannelsCheck,'Enable','on');
        set(handles.hdlInputChannelsCheck,'Enable','on');
        set(handles.hdlPlay,'Enable','on');
        set(handles.hdlLoad,'Enable','on');
        set(handles.hdlClose,'Enable','on');
        set(handles.hdlSigSelect,'Enable','on');
        set(handles.hdlSigSelectInput,'Enable','on');
        set(handles.hdlStop,'Enable','off');
        set(handles.pushbuttonConfig,'Enable','on');
        if isvalid(handles.hdlTimer)
            stop(handles.hdlTimer);
        end
        %handles.PDCMatLoaded=0;
        handles.TimerIn=0;
        if handles.SaveModeFID>1
            handles.SaveModeFID=fclose(handles.SaveModeFID);
        end
        % Update handles structure
        guidata(handles.hdlFigureMain, handles);
        msgbox('End of Data. Please use the ''load'' button to load new data set.','help','modal');
        return
    end
        


    % Check for empty data matrix
    %  if isempty(data); continue; end

    % Time between first new sample and last sample in buffer
    t1 = data(1,1) - handles.udPlotBuffer.tf;

    % Allocate a new plot data buffer, if necessary
    if t1 > handles.udPlotWindowSec
      n = ceil(handles.udPlotWindowSec*fs); t1 = 1/fs;
      handles.udPlotBuffer.tf   = data(1,1) - t1;
      handles.udPlotBuffer.time = -(n:-1:1)'/fs;
      handles.udPlotBuffer.data = NaN*ones(n,1);
    end

    time0 = handles.udPlotBuffer.time;
    data0 = handles.udPlotBuffer.data;

    % Check for buffer length problem
    if size(data,1) > length(time0)
      error('User parameter ''PlotWindowSec'' to small.');
    end

    
    % Insert NaNs for missing samples
    if t1 > 1.1/fs
      n = fix(1.1*t1*fs) - 1;
      time0 = [time0(n+1:end); time0(end) + (1:n)'/fs];
      data0 = [data0(n+1:end); NaN*ones(n,1)];
      %*************************************************************
      % 3.0 added by Ning Zhou for mode meter
      if bAllChannels       % all channels are chosen
          rlsData=[NaN*ones(n,NChan-1); data(:,sigSeq)];    % missing data
      else                  % single channel of data
          rlsData=[NaN*ones(n,1); data(:,sigIndx)];    % missing data
      end
      rlsDataInput=[NaN*ones(n,NChan-1); data(:,sigIndxInput)];    % missing data
      % 3.0 end addtion by Ning Zhou for mode meter
     %*************************************************************
    else
        %*************************************************************
        % 3.0 added by Ning Zhou for mode meter
        if bAllChannels       % all channels are chosen
            rlsData=data(:,sigSeq);    % missing data
        else                  % single channel of data
            rlsData=data(:,sigIndx);                    % no missing data
        end
        rlsDataInput= data(:,sigIndxInput);    % missing data
        % 3.0 end addtion by Ning Zhou for mode meter
        %*************************************************************
    end

    % Insert new data into buffer
    n = size(data,1);
    handles.udPlotBuffer.tf   = data(end,1);
    handles.udPlotBuffer.time = [time0(n+1:end); time0(end) + (1:n)'/fs];
%    handles.udPlotBuffer.data = [data0(n+1:end); data(:,sigIndx)];  % by Ning Zhou on 08/15/2006
    handles.udPlotBuffer.data = [data0(n+1:end); handles.AmpIndex*data(:,sigIndx)];
    redraw = 1;
    
     %********************************************************************
     % 5.0 Added By Ning Zhou for mode meter
     
     % 5.1 Input the data from "data" and "zTimeTag"
     %keyboard;
     yBlockOrg=rlsData;
     if handles.bInputChannels
         uBlockOrg=rlsDataInput;
     else
         uBlockOrg=zeros(size(yBlockOrg,1),1);
     end
     
     %yBlockOrg(~(zTimeTag>0))=NaN;     % for missing data
     if handles.Fs~=fs;
         error(sprintf('Please set Fs= %f to replace (Fs=%f) !!!!!!!!!!!!!', fs, handles.Fs))
     end

     %disp('line 433')
     % 2.2.3 remove the trend;
     [Ndata,NumCh]=size(yBlockOrg);
     xTrend=zeros(Ndata,NumCh);
     for chIndex=1:NumCh
         [xTrend(:,chIndex),handles.meBufFix(:,chIndex),handles.mePntFixBuf(chIndex),handles.mePreLength(chIndex),handles.thetaX(:,chIndex),handles.Rx(:,:,chIndex),handles.oTime(chIndex)]=...
               funRMedianDetrendNaN(yBlockOrg(:,chIndex),handles.meBufFix(:,chIndex),handles.mePntFixBuf(chIndex),handles.mePreLength(chIndex),handles.thetaX(:,chIndex),handles.Rx(:,:,chIndex),handles.oTime(chIndex),handles.FFDetrend(chIndex) );
     end
     
     uTrend=zeros(Ndata,handles.Nu);
     if handles.bInputChannels
         [uTrend,handles.meBufFixU,handles.mePntFixBufU,handles.mePreLengthU,handles.thetaXU,handles.RxU,handles.oTimeU]=...
              funRMedianDetrendNaN(uBlockOrg, handles.meBufFixU,handles.mePntFixBufU,handles.mePreLengthU,handles.thetaXU,handles.RxU,handles.oTimeU,handles.FFDetrend(1));
     end
     
     yBlockDetr=yBlockOrg-xTrend;
     uBlockDetr=uBlockOrg-uTrend;
     
     %disp('line 439')
     % 2.2.4 apply the median filter on the detrended data (low pass
      % anti-alias filter
    [yHat,handles.meBufFixD,handles.mePntFixBufD,handles.mePreLengthD]=...
                    funRMedianFilter(yBlockDetr,handles.meBufFixD,handles.mePntFixBufD,handles.mePreLengthD);
    if handles.bInputChannels            
        [uHat,handles.meBufFixDU,handles.mePntFixBufDU,handles.mePreLengthDU]=...
                    funRMedianFilter(uBlockDetr,handles.meBufFixDU,handles.mePntFixBufDU,handles.mePreLengthDU); 
    else
        uHat=zeros(size(yHat,1),1);
    end
                
    yHat(any(isinf(yHat),2))=[];
     %disp('line 445')
    % 2.2.5 data decimation
    nB=length(yHat);                    % actual block sizes
    reSeq=handles.reStart:handles.DeciFactor:nB;        % resampling sequence       
    yResample=yHat(reSeq,:);              % simple resampling
    uResample=uHat(reSeq,:);              % simple resampling input
    
    nResample= size(yResample,1);        % length of resample signal
    handles.reStart=reSeq(end)+handles.DeciFactor-nB;   % get the start index for the next resampling
    %disp('line 452')
    dispMode=0;
     % 2.2.5 buffer the data to reach the starting condition (i.e. phi0 is filled with good data)
   for tIndex=1:nResample
       zResample=yResample(tIndex,:);     % extract the data step by step 
       vResample=uResample(tIndex,:);     % extract the input data step by step 
       zReady=~isnan(zResample);          % if the data is available; NaN stands for situation when the data is missing 
       
       
       %???
       for chIndex=1:handles.lModel             % channel loop start          % added on 12/27/2006 for multi-channel data
           if isnan(handles.epsilon2(chIndex))
               handles.epsilon2(chIndex)=0;
           end
           preErr01=handles.epsilon2(chIndex);
           handles.zSamplePast(:,chIndex)=[zResample(chIndex); handles.zSamplePast(1,chIndex);];
           handles.vSamplePast=[vResample; handles.vSamplePast(1)];

           [thm2,handles.zHat2,handles.P2,handles.phi2,handles.pErr2(:,chIndex),handles.epsilon2(chIndex), handles.OutlierCount02(chIndex),epsi,...
                 handles.PhiLextY(:,chIndex),handles.PhiLextU(:,chIndex), handles.PhiLextE(:,chIndex), handles.PhiPrimeHist(:,chIndex), handles.LamLHist] = ...
                       funRarxRobustExtP05MIMOoffline([handles.zSamplePast(2,chIndex), preErr01, handles.vSamplePast(1)], [handles.aOrder2, handles.cOrder2, handles.bOrder2, handles.kOrder2, handles.kOrder2], 'ff',handles.ForgFactor02,...
                            handles.th2,handles.P2,handles.phi0s2(:,chIndex),handles.pErr2(:,chIndex),handles.delta2,[],handles.lModel, chIndex, handles.OutlierCount02(chIndex), handles.RegularizationCount02,...
                            handles.PhiLextY(:,chIndex),handles.PhiLextU(:,chIndex),handles.PhiLextE(:,chIndex),handles.PhiPrimeHist(:,chIndex), handles.LamLHist );
                   
%            [thm2,handles.zHat2,handles.P2,handles.phi2,handles.pErr2(:,chIndex),handles.epsilon2(chIndex), handles.OutlierCount02(chIndex)] = ...
%                        funRarxRobustExtP03MIMO([handles.zSamplePast(2,chIndex), preErr01, handles.vSamplePast(1)], [handles.aOrder2, handles.cOrder2, handles.bOrder2, handles.kOrder2, handles.kOrder2], 'ff',handles.ForgFactor02,...
%                        handles.th2,handles.P2,handles.phi0s2(:,chIndex),handles.pErr2(:,chIndex),handles.delta2,[],handles.lModel, chIndex, handles.OutlierCount02(chIndex), handles.RegularizationCount02);

           handles.RegularizationCount02=mod(handles.RegularizationCount02+1, 2^30);
                   
           
           
           handles.th2=thm2(end,:).'; 
           handles.phi0s2(:,chIndex)=handles.phi2;
           %zEstPoles=roots([1; azIdent]);
           %sEstPoles=log(zEstPoles)/TsID;
       end
       testAzIdent=handles.th2(1:handles.aOrder2).';       % identified a(z)
       if sum(testAzIdent~=0)
           dispMode=1;
       else
           dispMode=0;
       end
   end

%   tTemp=etime(clock,handles.DataTimer);
   tTemp=data(end,1);
   tSec=floor(mod(tTemp,60));
   tMin=floor(mod(floor(tTemp/60),60));
   tHour=floor(tTemp/3600);
   

   aRefTimeV=datevec(handles.StartTime);
   if  0    %GMT
       startHourV=aRefTimeV(4);
       startSecV=aRefTimeV(6)+ data(end,1);
       EndTime=datenum([aRefTimeV(1:3),startHourV,aRefTimeV(5), startSecV]);
       UpdateTime=[datestr(EndTime), ' GMT'];
   else     % PDT
       startHourV=aRefTimeV(4)-7;
       startSecV=aRefTimeV(6)+ data(end,1);
       EndTime=datenum([aRefTimeV(1:3),startHourV,aRefTimeV(5), startSecV]);
       UpdateTime=[datestr(EndTime), ' PDT'];
   end
   
   set(handles.hdlDataTimer,'string',num2str([tHour, tMin,tSec], 'Time Since the Beginning of Estimation: %4d:%4d''%4d'''''));
   set(handles.hdlDataUpdate,'string',['Updating Time: ', UpdateTime]);
   
   handles.PackCount=handles.PackCount+1;
   if handles.PackCount>7200        % pack the variable every 2 hours (7200 seconds)
       handles.PackCount=0;
       cwd = pwd;
       cd(tempdir);
       pack
       cd(cwd)
   end

   if dispMode  
       %   2.2.5.2 display the mode estimation results
       %   2.2.5.2.1 display the mode estimation results
       if 1     % with the dominant pole calc
           switch(handles.ModelType)
               case 0
                   azIdent=handles.th(end,:);       % identified a(z)
                   czIdent=1;
               case 1
                   chIndex=handles.lModel;
                   azIdent=handles.th2(1:handles.aOrder2).';       % identified a(z) (AR part)
                   czIdent=[1 (handles.th2(handles.aOrder2+1+(chIndex-1)*(handles.cOrder2+handles.bOrder2):...
                                           handles.aOrder2+  (chIndex-1)*(handles.cOrder2+handles.bOrder2)+handles.cOrder2)).'];       % identified c(z) MA parts
                   bzIdent=[(handles.th2(handles.aOrder2+1+(chIndex-1)*(handles.cOrder2+handles.bOrder2)+handles.cOrder2:...
                                           handles.aOrder2+   chIndex   *(handles.cOrder2+handles.bOrder2))).'];       % identified c(z) MA parts

                   %czIdent=1;
           end
            EnergyWindow=5*60;
            [modeEnergy, sEstPolesAll]=funDominantMode(czIdent, [1 azIdent],handles.TsID, EnergyWindow);
            NumDisp=handles.NumMajorPoles;             % the number of poles displayed; note: the complex poles come in pair.
            FreqH=1.0;
            FreqL=0.05;
            sEstPolesAll(isinf(sEstPolesAll))=-1e12;
            [sEstPoles, tDisp, sEstPolesTrivial, tDispTrivial]=funModeDispSelection(sEstPolesAll,modeEnergy,NumDisp,FreqH,FreqL,20);
            %funFindModes(sEstPoles);
            %[Freq, DR]=funFindModes(sEstPoles);
       else     % without the dominant pole calc
            azIdent=handles.th(end,:);       % identified a(z)
            zEstPoles=roots([1, azIdent]);
            sEstPoles=log(zEstPoles)/handles.TsID;
            [Freq, DR]=funFindModes(sEstPoles);
            tDisp=DR;       % display damping ratio
       end

       %disp('line 539')

       
       x=real(sEstPoles);
       %funFindModes(sEstPoles);
       SeqOutboundary=find(x>=handles.xPlotLimit(2));
       if ~isempty(SeqOutboundary)
            x(SeqOutboundary)=handles.xPlotLimit(2);
       end 
       SeqUnstable=find(x>=0);
       y=imag(sEstPoles)/(2*pi);
       
       xTrivial=real(sEstPolesTrivial);
       SeqOutboundaryTrivial=find(xTrivial>=handles.xPlotLimit(2));
       if ~isempty(SeqOutboundaryTrivial)
            xTrivial(SeqOutboundaryTrivial)=handles.xPlotLimit(2);
       end 
       %SeqUnstable=find(xTrivial>=0);
       yTrivial=imag(sEstPolesTrivial)/(2*pi);
       
       if isfield(handles,'PeakFreq')
          tempY=y-handles.PeakFreq;
           tempDistance=0.2*(x-0.1).^2+tempY.^2;
           [tempV,tempI]=min(tempDistance);
           if isempty(SeqOutboundary)
               SeqOutboundary=tempI;
           end 
       end
 
%       hold on
       if isnan(handles.hdlPlotMode) || isnan(handles.hdlPlotModeUnstable) || isnan(handles.hdlPlotModeBoundary)
          h = get(0,'ShowHiddenHandles'); set(0,'ShowHiddenHandles','on');
          axes(handles.hdlModeAxes);
          legend(num2str(handles.DRBorder',' Damping Ratio = %2.1f %%'),'Location','Southwest');
          %disp('line 551')

           handles.hdlPlotMode = plot(handles.xPlotLimit(2)+10,handles.yPlotLimit(1),'.', 'color','b','markersize',25, 'EraseMode','xor');
           handles.hdlPlotModeTrivial = plot(handles.xPlotLimit(2)+10,handles.yPlotLimit(1),'o', 'color',[0.8, 0.8, 1.0],'markersize',6, 'EraseMode','xor');
           handles.hdlPlotModeBoundary = plot(handles.xPlotLimit(2)+10,handles.yPlotLimit(1),'o', 'color','m','markersize',25, 'EraseMode','xor');
           handles.hdlPlotModeUnstable = plot(handles.xPlotLimit(2)+10,handles.yPlotLimit(1),'.', 'color','r','markersize',35, 'EraseMode','xor');
           %disp('line 560')
           for kIndex=1:handles.bodyLength
                handles.hdlPlotBody(kIndex) = plot(handles.ModeBufferX(:,kIndex),handles.ModeBufferY(:,kIndex),...
                    '.','color',[0.2, 0.2, 0.8],'markersize',10, 'EraseMode','xor');  
   %             handles.hdlPlotBody(kIndex) = plot(handles.ModeBufferX(:,kIndex),handles.ModeBufferY(:,kIndex),...
   %                 '.','color','k','markersize',10, 'EraseMode','xor');  
           end
           set(0,'ShowHiddenHandles',h);
        %   handles.hdlPlotBody = plot(x,y,'.','color','b','markersize',10, 'EraseMode','xor');
           drawnow
          %disp('line 557')
       else
           %handles.X
           set(handles.hdlPlotMode,'xdata',x,'ydata',y);
           set(handles.hdlPlotModeTrivial,'xdata',xTrivial,'ydata',yTrivial);
           set(handles.hdlPlotModeBoundary,'xdata',x(SeqOutboundary),'ydata',y(SeqOutboundary));
           if handles.SaveModeFID>0
               fprintf(handles.SaveModeFID,'%s\t', UpdateTime);
               for pIndex=1:length(sEstPoles)
                   fprintf(handles.SaveModeFID,'%5.3f+i*%5.4f\t',real(sEstPoles(pIndex)),imag(sEstPoles(pIndex)));
               end
               fprintf(handles.SaveModeFID,'\n');
           end
%            [Freq, DR]=funPole2Mode(sEstPoles(SeqOutboundary));
%            tempDisp=sprintf('Freq= %4.2f Hz   DR= %3.1f %% ',Freq(1), DR(1));
%            set(handles.textMode1,'string', tempDisp);
           
            [Freq, DR]=funPole2Mode(sEstPoles);
            tempDisp1=sprintf('Freq= %4.2f Hz   DR= %3.1f %% ',abs(Freq(1)), DR(1));
            set(handles.textMode1,'string', tempDisp1);
            tempDisp2=sprintf('Freq= %4.2f Hz   DR= %3.1f %% ',abs(Freq(3)), DR(3));
            set(handles.textMode2,'string', tempDisp2);

           set(handles.hdlPlotModeUnstable,'xdata',x(SeqUnstable),'ydata',y(SeqUnstable));
           
           
           for kIndex=1:handles.bodyLength
                 set(handles.hdlPlotBody(kIndex),'xdata', handles.ModeBufferX(:,kIndex),'ydata',handles.ModeBufferY(:,kIndex));
           end
        %   set(handles.hdlPlotBody,'xdata', handles.X,'ydata',handles.Y);
           %disp('line 562')
           drawnow
           
       end 
       handles.ModeBufferX=[x,handles.ModeBufferX(:,1:end-1)];
       handles.ModeBufferY=[y,handles.ModeBufferY(:,1:end-1)];
       
       
       
       %   2.2.5.2.2 display the spectral estimation results
       [azH,azFreq]=funFreqz(czIdent,[1, azIdent],256,1/handles.TsID);
       
       [abzH,abzFreq]=funFreqz(bzIdent,[1, azIdent],256,1/handles.TsID);
       
       SigmaE=median(handles.pErr2(~isinf(handles.pErr2(:,chIndex)),chIndex))/0.6745;
       azHdB=20*log10(abs(azH)*SigmaE/handles.FsID);
       
       tempBias=10;
       [tempMax, tempI]=max(azHdB(tempBias+1:end-1));
       tempI=tempI+tempBias;
       
       handles.PeakFreq=azFreq(tempI);
       hdlFreq = findobj(handles.hdlFreqAxes,'Type','line');
%       if isempty(hdlFreq)
       if isnan(handles.hdlFreq) || isnan(handles.hdlPeakSpectrum)
           h = get(0,'ShowHiddenHandles'); set(0,'ShowHiddenHandles','on');
           axes(handles.hdlFreqAxes); 
           handles.hdlFreq=line(azFreq,azHdB); 
%          handles.hdlPeakSpectrum=line(azFreq(tempI-1:tempI+1),azHdB(tempI-1:tempI+1),'LineWidth',5,'Color',[1 .2 .2]);
           handles.hdlPeakSpectrum=text(azFreq(tempI),azHdB(tempI),'O','Color','r','HorizontalAlignment','Center');
%           axis auto
           xlabel('Freq (Hz)'); ylabel('Magnitude (db)')
           
           
           set(0,'ShowHiddenHandles',h);
           drawnow
       else
           %set(handles.hdlFreqAxes,'YLimMode','auto');
           %set(hdlFreq,'XData',20*log10(abs(azH)),'YData',azFreq);
           MaxTempY=max(azHdB(azFreq<1 & azFreq>0.05))+1;
           MinTempY=min(azHdB(azFreq<1 & azFreq>0.05))-1;
           axes(handles.hdlFreqAxes); 
           if MaxTempY-MinTempY < 10
               TempAxis=axis;
               if MinTempY < TempAxis(3) || MaxTempY > TempAxis(4)
                   tempCenter=(MaxTempY+MinTempY)/2;
                   set(handles.hdlFreqAxes,'yLim',[tempCenter-5,tempCenter+5], 'xLim', [0 1]);
               end
               axis manual;
           else
               axis 'auto y';
           end
           set(handles.hdlFreq,'XData',azFreq,'YData',azHdB);
           set(handles.hdlPeakSpectrum, 'Position',[azFreq(tempI),azHdB(tempI)]);
%          set(handles.hdlPeakSpectrum, 'XData',azFreq(tempI-1:tempI+1),'YData',azHdB(tempI-1:tempI+1));
           %set(handles.hdlFreqAxes,'XLim','auto');

           %xLim = get(handles.hdlFreqAxes,'XLim');
           %set(handles.hdlFreqAxes,'XLim',[xLim(2) - handles.udPlotWindowSec xLim(2)]);
           drawnow;
       end
           
   end

    %disp('line 540');
    % 2.0 End addition By Ning Zhou for mode meter
    %********************************************************************

    

  else      % no data are available
        set(handles.hdlAllChannelsCheck,'Enable','on');
        set(handles.hdlInputChannelsCheck,'Enable','on');
        set(handles.hdlPlay,'Enable','on');
        set(handles.hdlLoad,'Enable','on');
        set(handles.hdlClose,'Enable','on');
        set(handles.hdlSigSelect,'Enable','on');
        set(handles.hdlSigSelectInput,'Enable','on');
        set(handles.hdlStop,'Enable','off');
        if isvalid(handles.hdlTimer)
            stop(handles.hdlTimer);
        end
        %handles.PDCMatLoaded=0;
        handles.TimerIn=0;

            % Update handles structure
         guidata(handles.hdlFigureMain, handles);
         msgbox('Data are NOT available. Please use the ''load'' button to load a new data set.','help','modal');
  end

end


if redraw
    % START: plot the general time plots, Ning Zhou 10/02/2006
    if isnan(handles.hdlAniWhole)       % first plots
          h = get(0,'ShowHiddenHandles'); set(0,'ShowHiddenHandles','on');
          axes(handles.hdlWholeTimeAxes);
          handles.hdlAniWhole=line(handles.Data(1:handles.blockCount,1),handles.Data(1:handles.blockCount,sigIndx),'color','b');
    else                                % follow up plots
        set(handles.hdlAniWhole,'xdata',handles.Data(1:handles.blockCount,1),'ydata',handles.Data(1:handles.blockCount,sigIndx));
    end

    if handles.bInputChannels
        if isnan(handles.hdlAniWholeInput)       % first plots
           h = get(0,'ShowHiddenHandles'); set(0,'ShowHiddenHandles','on');
           axes(handles.hdlWholeTimeAxesInput);
           handles.hdlAniWholeInput=line(handles.Data(1:handles.blockCount,1),handles.Data(1:handles.blockCount,sigIndxInput),'color','b');
        else
            set(handles.hdlAniWholeInput,'xdata',handles.Data(1:handles.blockCount,1),'ydata',handles.Data(1:handles.blockCount,sigIndxInput));
        end
    end
    
    
    
    % End: plot the general time plots, Ning Zhou 10/02/2006
end

% Update plots
if redraw

  % Time series
  %hdlLine = findobj(handles.hdlTimeAxes,'Type','line');
  time0   = handles.udPlotBuffer.time;
  data0   = handles.udPlotBuffer.data;

%   if isempty(hdlLine)
%     h = get(0,'ShowHiddenHandles'); set(0,'ShowHiddenHandles','on');
%     axes(handles.hdlTimeAxes); line(time0,data0); xlabel('Time (sec)');
%     set(0,'ShowHiddenHandles',h);
%   else
%     %*** DPC idenfity only non-zero values
%     id1 = find(data0~=0);
%     id2 = find(isnan(data0)==0);        % added by Ning Zhou 08/15/2006
%     id0 = intersect(id1,id2);
%     set(handles.hdlTimeAxes,'XLimMode','auto');
%     %*** DPC show only non-zero values
%     if ( length(id0)>0)
%         set(hdlLine,'XData',time0(id0),'YData',data0(id0));
%     else
%         set(hdlLine,'XData',time0,'YData',data0);
%     end
%     xLim = get(handles.hdlTimeAxes,'XLim');
%     set(handles.hdlTimeAxes,'XLim',[xLim(2) - handles.udPlotWindowSec xLim(2)]);
%     %*** DPC: control yLim to prevent erroneous zero from disrupting scale
%     if (length(id0)>0)
%         mu = mean(data0(id0));
%         s3 = 3*std(data0(id0));
%         if ( ~(isnan(mu) || isnan(s3)))
%             set(handles.hdlTimeAxes,'YLim',[mu-s3 mu+s3]);
%         end
%     end
%   end

end

% Put additional processing here
% if redraw
%
%  % Check for plot data buffer reset
%   if isnan(handles.udPlotBuffer.data(1)
%
%  end
% end

% Set Run Status Indicator
if handles.udDisplayCount > 0
  handles.udDisplayCount = handles.udDisplayCount - 1;
elseif handles.udDisplayCount == 0
  set(hdlRunStatus,'String','Running');
  handles.udDisplayCount = -1;
end

% Update handles structure
handles.TimerIn=0;
guidata(handles.hdlFigureMain, handles);

% -------------------------------------------------------------------------
% Executes when timer object encounters unhandled error
function timer_ErrorFcn(hdlTimer, eventdata, handles)
% hdlTimer           Handle to timer object
% eventdata          Event data (supplied by timer object)
% handles            structure with handles and user data (see GUIDATA)

% Execute Figure CloseRequestFcn
hdlFigureMain_CloseRequestFcn(handles.hdlFigureMain, eventdata, handles);

% -------------------------------------------------------------------------
% Read PDCDataReader properties with proper error handling
function val = util_PDCDataReaderRead(hdlCtrl,prop)

% Expand this function as need arises

try
  val = get(hdlCtrl,prop);
catch
  filtstr = 'Maximum number of lost samples exceeded.';
  val = []; if isempty(findstr(lasterr,filtstr)); error(lasterr); end
end

% -------------------------------------------------------------------------
% Generate a default configuration parameter file
function util_DefaultConfigFile(cfgFile);

% Open file
fid = fopen(cfgFile,'wt+');

% Write header
fprintf(fid,'%% %s Configuration File\n',mfilename);
fprintf(fid,'%% Created on %s\n',datestr(clock));

% PDC Configuration File and UDP Port
PDCConfigFile = [fileparts(mfilename('fullpath')) filesep 'BPA1_030320.ini'];
fprintf(fid,'\n%% PDC .INI file and UDP port\n');
fprintf(fid,'PDCConfigFile      = ''%s'';\n', PDCConfigFile);
fprintf(fid,'PDCUDPPort         = %d;\n', 3050);

% Time series plot parameters
fprintf(fid,'\n%% Time series plot parameters\n');
fprintf(fid,'PlotWindowSec      = %d;\n', 30);

% Fourier parameters
fprintf(fid,'\n%% Fourier analysis parameters\n');
fprintf(fid,'DFTWindowLength    = %d;\n', 1024);
fprintf(fid,'DFTWindowOverlap   = %d;\n', 768);

% Close file
fclose(fid);


% --- Executes during object creation, after setting all properties.
function hdlFigureMain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hdlFigureMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called









% --- Executes on button press in hdlLoad.
function hdlLoad_Callback(hObject, eventdata, handles)
% hObject    handle to hdlLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%------------------------------------------------
%  LOAD THE NEW FILES
%handles.udPlotBuffer.tf = -Inf;
set(handles.hdlAllChannelsCheck,'Enable','on');
set(handles.hdlInputChannelsCheck,'Enable','on');
if isvalid(handles.hdlTimer)
    stop(handles.hdlTimer);
end

if ~isfield(handles, 'TimerIn')
    handles.TimerIn=0;
end

if handles.TimerIn 
   handles.TimerIn=0;
   guidata(hObject, handles);
   msgbox('The data stream has been stopped. Please try again!','modal');
   return;
end

xNote=[];
sNote=[];

if 1
%   handles.bInputChannels = get(handles.hdlInputChannelsCheck,'Value');
    SubLoadNewData;
    
        %------------------------------------------------
    %  RESET PARAMETERS
    % Reset plot data buffer
    handles.udPlotBuffer.time = [];
    axes(handles.hdlFreqAxes); drawnow; cla;
    axes(handles.hdlModeAxes); drawnow; cla;

    % start: added by Ning Zhou 08/15/2006
    hold on
    for bIndex=1:length(handles.DRBorder)
        plot([0,handles.DRBorderX(bIndex)],[0, handles.DRBorderY(bIndex)],[handles.DRBorderColor(bIndex),'--'],'LineWidth',2)
    end

    xTemp=zeros(4,1);
    yTemp=zeros(4,1);

     for bIndex=1:length(handles.DRBorder)-1
         xTemp(2)=handles.DRBorderX(bIndex);
         yTemp(2)=handles.DRBorderY(bIndex);
         xTemp(3)=handles.DRBorderX(bIndex+1);
         yTemp(3)=handles.DRBorderY(bIndex+1);
         patch(xTemp,yTemp,handles.DRFillColor(bIndex,:),'EdgeColor','y'); %handles.DRBorderColor(bIndex,:))
     end

     bIndex=bIndex+1;
     xTemp(2)=-2;
     yTemp(2)=0;
     patch(xTemp,yTemp,handles.DRFillColor(bIndex,:),'EdgeColor','y'); %handles.DRBorderColor(bIndex,:))

     for bIndex=1:length(handles.DRBorder)
        plot([0,handles.DRBorderX(bIndex)],[0, handles.DRBorderY(bIndex)],[handles.DRBorderColor(bIndex),'--'],'LineWidth',2)
     end


    box(handles.hdlModeAxes,'on');
    set(handles.hdlModeAxes,'XLim',handles.xPlotLimit,'YLim',handles.yPlotLimit, ...
                'Drawmode','fast', 'Visible','on','NextPlot','add');
    % end: added by Ning Zhou 08/15/2006

    handles.hdlPlotMode=NaN;
    handles.hdlPlotModeBoundary=NaN;
    handles.hdlPlotModeUnstable=NaN;
    handles.hdlFreq=NaN; 
    handles.hdlPeakSpectrum=NaN;

    handles.DataTimer=clock;
    handles.hdlPlotBody=handles.hdlPlotBody*NaN;
    handles.ModeBufferX=handles.ModeBufferX*NaN;
    handles.ModeBufferY=handles.ModeBufferY*NaN;

    %1.11 parameters for the spectral plot
    axes(handles.hdlFreqAxes)
    cla
    set(handles.hdlPlay,'Enable','on');
    % 1.0 end addition by Ning Zhou to Re-initialize the data for RLS function
    %*************************************************************************
else
    tempNewLoad=0;
    try
        if isdir(handles.PDCMatPath)
            cd(handles.PDCMatPath);
        end

        [PDCMatFile,PDCMatPath]=uigetfile('*.mat','Default.pathname is NOT valid. Please choose your dst file:');

        if PDCMatFile
            handles.PDCMatPath=PDCMatPath; % July 24, 2006
            handles.PDCMatFile = PDCMatFile;
            load([handles.PDCMatPath handles.PDCMatFile]);
            tempNewLoad=1;
            handles.PDCMatLoaded=1;    
            set(handles.hdlRunStatus,'String',['[' handles.PDCMatFile '] is being loaded']);
        else
            tempNewLoad=0;
     %       handles.PDCMatLoaded=0;    
     %       set(handles.hdlRunStatus,'String','No file is loaded');
        end
    catch
        tempNewLoad=0
    %    handles.PDCMatLoaded=0;    
    %    set(handles.hdlRunStatus,'String','No file is loaded');
    end


    if tempNewLoad %handles.PDCMatLoaded         % store the data

      handles.blockCount=0;
      handles.Ts=tstep;
      handles.Fs=1/handles.Ts;
      handles.Data=PSMsigsX;
      handles.NChannel=size(handles.Data,2)-1;            % number of channels in the data
      handles.StartTime=PSM2Date(PSMreftimes(1));       % Greenwich Mean Time(GMT);    PDT=GMT - 7hour
      set(handles.hdlSigSelect,'String',chankeyX(2:end, 3:end),'Value',1);
      keyboard;
      set(handles.hdlSigSelectInput,'String',chankeyX(2:end, 3:end),'Value',1);
    % set(handles.hdlSigSelect,'String',chankeyX(2:end, 3:end),'Value',80);
      handles.xNote=xNote;
      handles.sNote=sNote;
    %  handles.yNote=yNote;

    %   MyData=handles.Data(:,sigIndx);       % signal selected
    %   MyTime=handles.Data(:,1);             % time duration
    %   axes(handles.hdlWholeTimeAxes);
    %   line(MyTime, MyData,'color','c');
      % End: plot the general time plots, Ning Zhou 10/02/2006

    end

    axes(handles.hdlWholeTimeAxes);
    cla

    if handles.PDCMatLoaded
        % START: plot the general time plots, Ning Zhou 10/02/2006
        sigIndx = get(handles.hdlSigSelect,'Value') + 1;
        sigIndxInput = get(handles.hdlSigSelectInput,'Value') + 1;
        MyData=handles.Data(:,sigIndx);       % signal selected
        MyTime=handles.Data(:,1);             % time duration
        axes(handles.hdlWholeTimeAxes);
        line(MyTime, MyData,'color','c');

          handles.hdlAniWhole=NaN;
          MedTemp=median(MyData);
          STDTemp=std(MyData);
          set(handles.hdlWholeTimeAxes,'yLim',[MedTemp-4*STDTemp,MedTemp+4*STDTemp], 'xLim', [MyTime(1),MyTime(end)]);


          for kIndex=1:length(handles.xNote)
              yNote=MedTemp+4*STDTemp-STDTemp;
              text(handles.xNote(kIndex), yNote, [handles.sNote{kIndex},' \downarrow '], ...
                      'HorizontalAlignment','right','BackgroundColor',[.7 .9 .7],'EdgeColor','red', 'FontSize',10);
          end

    else
      handles.Ts=1/30;          % default as 30 samples/sec 
    end

    Fs=1/handles.Ts;
    FsTarget=5;                             % Target sampling freq for the identification
    handles.Fs=Fs;
    handles.DeciFactor=round(Fs/FsTarget);                 
    handles.FsID=Fs/handles.DeciFactor;              % Sampling rate for identification (sample/sec)
    handles.TsID=1/handles.FsID;                     % sampling period (sec)


    %------------------------------------------------
    %  RESET PARAMETERS
    % Reset plot data buffer
    handles.udPlotBuffer.time = [];
    axes(handles.hdlFreqAxes); drawnow; cla;
    axes(handles.hdlModeAxes); drawnow; cla;

    % start: added by Ning Zhou 08/15/2006
    hold on
    for bIndex=1:length(handles.DRBorder)
        plot([0,handles.DRBorderX(bIndex)],[0, handles.DRBorderY(bIndex)],[handles.DRBorderColor(bIndex),'--'],'LineWidth',2)
    end

    xTemp=zeros(4,1);
    yTemp=zeros(4,1);

     for bIndex=1:length(handles.DRBorder)-1
         xTemp(2)=handles.DRBorderX(bIndex);
         yTemp(2)=handles.DRBorderY(bIndex);
         xTemp(3)=handles.DRBorderX(bIndex+1);
         yTemp(3)=handles.DRBorderY(bIndex+1);
         patch(xTemp,yTemp,handles.DRFillColor(bIndex,:),'EdgeColor','y'); %handles.DRBorderColor(bIndex,:))
     end

     bIndex=bIndex+1;
     xTemp(2)=-2;
     yTemp(2)=0;
     patch(xTemp,yTemp,handles.DRFillColor(bIndex,:),'EdgeColor','y'); %handles.DRBorderColor(bIndex,:))

     for bIndex=1:length(handles.DRBorder)
        plot([0,handles.DRBorderX(bIndex)],[0, handles.DRBorderY(bIndex)],[handles.DRBorderColor(bIndex),'--'],'LineWidth',2)
     end

    
    box(handles.hdlModeAxes,'on');
    set(handles.hdlModeAxes,'XLim',handles.xPlotLimit,'YLim',handles.yPlotLimit, ...
                'Drawmode','fast', 'Visible','on','NextPlot','add');
    % end: added by Ning Zhou 08/15/2006

    handles.hdlPlotMode=NaN;
    handles.hdlPlotModeBoundary=NaN;
    handles.hdlPlotModeUnstable=NaN;
    handles.hdlFreq=NaN; 
    handles.hdlPeakSpectrum=NaN;

    handles.DataTimer=clock;
    handles.hdlPlotBody=handles.hdlPlotBody*NaN;
    handles.ModeBufferX=handles.ModeBufferX*NaN;
    handles.ModeBufferY=handles.ModeBufferY*NaN;

    %1.11 parameters for the spectral plot
    axes(handles.hdlFreqAxes)
    cla
    set(handles.hdlPlay,'Enable','on');
    % 1.0 end addition by Ning Zhou to Re-initialize the data for RLS function
    %*************************************************************************
end

% Update handles structure
guidata(hObject, handles);

%set(handles.hdlAllChannelsCheck,'Enable','inactive');

%if isvalid(handles.hdlTimer)
%    start(handles.hdlTimer);
%end

% end: hdlLoad_Callback
%##########################################################################





% --- Executes on slider movement.
function hdlSpeedSlider_Callback(hObject, eventdata, handles)
% hObject    handle to hdlSpeedSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles.Speed=round(get(handles.hdlSpeedSlider,'Value'));
set(handles.hdlSpeedEdit,'String',...
    num2str(handles.Speed));
handles.SpeedPeriod=round(handles.TopSpeed/handles.Speed);
handles.SpeedCount=0;
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function hdlSpeedSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hdlSpeedSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end





function hdlSpeedEdit_Callback(hObject, eventdata, handles)
% hObject    handle to hdlSpeedEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of hdlSpeedEdit as text
%        str2double(get(hObject,'String')) returns contents of hdlSpeedEdit as a double

val = str2double(get(handles.hdlSpeedEdit,'String'));
% Determine whether val is a number between 0 and 1
if isnumeric(val) & length(val)==1 & ...
    val >= get(handles.hdlSpeedSlider,'Min') & ...
    val <= get(handles.hdlSpeedSlider,'Max')
    set(handles.hdlSpeedSlider,'Value',val);
else
% Increment the error count, and display it
%    guidata(hObject,handles); % store the changes
    set(handles.hdlSpeedEdit,'String',...
    num2str(handles.Speed));
end

handles.Speed=round(get(handles.hdlSpeedSlider,'Value'));
set(handles.hdlSpeedEdit,'String',...
    num2str(handles.Speed));
handles.SpeedPeriod=round(handles.TopSpeed/handles.Speed);
handles.SpeedCount=0;
% Update handles structure
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function hdlSpeedEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hdlSpeedEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over hdlLoad.





% --- Executes on button press in hdlAllChannelsCheck.
function hdlAllChannelsCheck_Callback(hObject, eventdata, handles)
% hObject    handle to hdlAllChannelsCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bAllChannels = get(handles.hdlAllChannelsCheck,'Value');    
if bAllChannels
    set(handles.hdlAllChannelsCheck,'ForegroundColor', [0.1,0.1,0.4]);    
    set(handles.hdlAllChannelsCheck,'FontSize', 11);    
    set(handles.hdlAllChannelsCheck,'FontWeight', 'bold');    
else
    set(handles.hdlAllChannelsCheck,'ForegroundColor', [0.5,0.5,0.5]);    
    set(handles.hdlAllChannelsCheck,'FontSize', 10);    
    set(handles.hdlAllChannelsCheck,'FontWeight', 'normal');    
end
% Hint: get(hObject,'Value') returns toggle state of hdlAllChannelsCheck




% --- Executes on button press in hdlStop.
function hdlStop_Callback(hObject, eventdata, handles)
% hObject    handle to hdlStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.hdlAllChannelsCheck,'Enable','on');
set(handles.hdlInputChannelsCheck,'Enable','on');
set(handles.hdlPlay,'Enable','on');
set(handles.hdlLoad,'Enable','on');
set(handles.hdlClose,'Enable','on');
set(handles.hdlSigSelect,'Enable','on');
set(handles.hdlSigSelectInput,'Enable','on');
set(handles.hdlStop,'Enable','off');
set(handles.pushbuttonConfig,'Enable','on');
if isvalid(handles.hdlTimer)
    stop(handles.hdlTimer);
end
axes(handles.hdlModeAxes);
legend(num2str(handles.DRBorder',' Damping Ratio = %2.1f %%'),'Location','Southwest');
if handles.TimerIn 
   handles.TimerIn=0;
   if handles.SaveModeFID>1
       handles.SaveModeFID=fclose(handles.SaveModeFID);
   end
   guidata(hObject, handles);
   msgbox('The data stream has been stopped!','modal');
   return;
end



% --- Executes on button press in hdlPlay.
function hdlPlay_Callback(hObject, eventdata, handles)
% hObject    handle to hdlPlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~handles.PDCMatLoaded
    msgbox('Please load data first!!!','modal');
    return
end
%clc
%*************************************************************************
% 1.0 Added by Ning Zhou to Re-initialize the data for RLS function
% Trigger a plot data buffer reset
axes(handles.hdlModeAxes);
legend(num2str(handles.DRBorder',' Damping Ratio = %2.1f %%'),'Location','Southwest');
bAllChannels = get(handles.hdlAllChannelsCheck,'Value');    
handles.Nu=1;                           % number of input channels

handles.udPlotBuffer.tf = -Inf;
handles.blockCount=0;
% 1.3 parameters for the recursive identification method algorithm
SubRRLSIni;

% 1.8 Added by Ning Zhou on 08/15/2006 to correct the displaying unit to MW
% and MVAR
val = get(hObject,'Value');
string_list = get(hObject,'String');
MyString = string_list(val,:); 
MVARok=strfind(MyString, 'MVAR');
MWok=strfind(MyString, 'MW');
if ~isempty(MVARok) || ~isempty(MWok)
    handles.AmpIndex=3*10^-6;
else 
    handles.AmpIndex=1;
end
% 1.8 End Added by Ning Zhou on 08/15/2006 to correct the displaying unit to MW


% 1.9 parameters for the mode plot
hdlModeAxes = findobj(handles.hdlModeAxes,'Type','line');

% 1.10 set the speed >0
handles.Speed=round(get(handles.hdlSpeedSlider,'Value'));
if handles.Speed<=0
    handles.Speed=handles.TopSpeed;
    set(handles.hdlSpeedSlider,'Value',handles.Speed);
end
set(handles.hdlSpeedEdit,'String',...
    num2str(handles.Speed));
handles.SpeedPeriod=round(handles.TopSpeed/handles.Speed);
handles.SpeedCount=0;
set(handles.pushbuttonConfig,'Enable','off');
% Update handles structure
if handles.SaveMode
    handles.SaveModeFID=fopen(handles.SaveModeFileName,'w');
    if handles.SaveModeFID<0
        handles.SaveModeFID=1;
    end
end
guidata(hObject, handles);

if isvalid(handles.hdlTimer)
    start(handles.hdlTimer);
end



% --- Executes on selection change in hdlSigSelectInput.
function hdlSigSelectInput_Callback(hObject, eventdata, handles)
% hObject    handle to hdlSigSelectInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.bInputChannels = get(handles.hdlInputChannelsCheck,'Value');    
if handles.bInputChannels 
    sigIndxInput = get(handles.hdlSigSelectInput,'Value') + 1;
    MyData=handles.Data(:,sigIndxInput);       % signal selected
    MyTime=handles.Data(:,1);             % time duration
    axes(handles.hdlWholeTimeAxesInput);
    cla
    line(MyTime, MyData,'color','c');

    handles.hdlAniWholeInput=NaN;
    MedTemp=median(MyData);
    STDTemp=std(MyData);
    set(handles.hdlWholeTimeAxesInput,'yLim',[MedTemp-4*STDTemp,MedTemp+4*STDTemp], 'xLim', [MyTime(1),MyTime(end)]);
else
    axes(handles.hdlWholeTimeAxesInput);
    cla
end
guidata(hObject, handles);
% Hints: contents = get(hObject,'String') returns hdlSigSelectInput contents as cell array
%        contents{get(hObject,'Value')} returns selected item from hdlSigSelectInput


% --- Executes during object creation, after setting all properties.
function hdlSigSelectInput_CreateFcn(hObject, eventdata, handles)
% hObject    handle to hdlSigSelectInput (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

%if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%    set(hObject,'BackgroundColor','white');
%end


% --- Executes on button press in hdlInputChannelsCheck.
function hdlInputChannelsCheck_Callback(hObject, eventdata, handles)
% hObject    handle to hdlInputChannelsCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.bInputChannels = get(handles.hdlInputChannelsCheck,'Value');    
if handles.bInputChannels
    set(handles.hdlInputChannelsCheck,'ForegroundColor', [0.1,0.1,0.4]);    
    set(handles.hdlInputChannelsCheck,'FontSize', 11);    
    set(handles.hdlInputChannelsCheck,'FontWeight', 'bold');
    
     sigIndxInput = get(handles.hdlSigSelectInput,'Value') + 1;
    MyData=handles.Data(:,sigIndxInput);       % signal selected
    MyTime=handles.Data(:,1);             % time duration
    axes(handles.hdlWholeTimeAxesInput);
    cla
    line(MyTime, MyData,'color','c');

    handles.hdlAniWholeInput=NaN;
    MedTemp=median(MyData);
    STDTemp=std(MyData);
    set(handles.hdlWholeTimeAxesInput,'yLim',[MedTemp-4*STDTemp,MedTemp+4*STDTemp], 'xLim', [MyTime(1),MyTime(end)]);
else
    set(handles.hdlInputChannelsCheck,'ForegroundColor', [0.5,0.5,0.5]);    
    set(handles.hdlInputChannelsCheck,'FontSize', 10);    
    set(handles.hdlInputChannelsCheck,'FontWeight', 'normal');    

    axes(handles.hdlWholeTimeAxesInput);
    cla
end

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of hdlInputChannelsCheck




% --- Executes on button press in ConfigPushbutton.
function ConfigPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ConfigPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttonConfig.
function pushbuttonConfig_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% handles.aOrder2=aOrder2;                     %AR
% handles.bOrder2=bOrder2;                     %X
% handles.cOrder2=cOrder2;                     %MA

WindowLength=handles.WindowSize/handles.FsID; % in seconds

retConfig=funConfigParameters([handles.aOrder2, handles.bOrder2, handles.cOrder2], [WindowLength, handles.ForgTimeConst02],...
    [handles.IniModeFreqHalf,handles.IniModeDRHalf, handles.IniModeWeightHalf], handles.SaveMode );

if ~isempty(retConfig)
    ModelOrder=retConfig{1};
    if ~any(isnan(ModelOrder))
        handles.aOrder2=abs(ceil(ModelOrder(1)));      % AR
        if handles.aOrder2<10
            handles.aOrder2=10;
        end
        handles.bOrder2=abs(ceil(ModelOrder(2)));      % X
        handles.cOrder2=abs(ceil(ModelOrder(3)));      % MA
    end
    
    CalWindow=retConfig{2};
    if ~any(isnan(CalWindow))    
        handles.WindowLength=abs(CalWindow(1));      % windows length
        handles.ForgTimeConst02=abs(CalWindow(2));   % equivalent window length of forgetting facotr
    end

    IniMode=retConfig{3};
    
    if (sum(IniMode(:,3))>0)
        
        tempInvalidModeSeq=find((IniMode(:,3))<=0);
        IniMode(tempInvalidModeSeq,:)=[];
        
        handles.IniModeFreqHalf=IniMode(:,1);
        handles.IniModeDRHalf    =IniMode(:,2);
        handles.IniModeWeightHalf=IniMode(:,3);


        temp=handles.IniModeFreqHalf*2*pi;
        tempsPoles=temp.*cot(acos(-handles.IniModeDRHalf /100))+j*temp;
        if size(tempsPoles,1)==1
            tempsPoles=tempsPoles.';
        end
        handles.IniModelPoles=[tempsPoles;conj(tempsPoles)];

        if size(handles.IniModeWeightHalf,1)==1
            handles.IniModeWeightHalf=handles.IniModeWeightHalf.';
        end
        handles.IniModeWeight=[handles.IniModeWeightHalf;handles.IniModeWeightHalf];
    else
        handles.IniModelPoles    =[];
        handles.IniModeFreqHalf  =[];
        handles.IniModeDRHalf    =[];
        handles.IniModeWeightHalf=[];
    end
    handles.SaveMode=retConfig{4};              % save the mode file
    
    
    handles.WindowSize=round(handles.WindowLength*handles.FsID);    %  number of steps
    handles.ForgFactor02=1-1/(handles.ForgTimeConst02*handles.FsID);     % forgeting factor for rarx.m()    
    if handles.SaveMode
        strFigTitle=sprintf('RRLS ARMAX{%d,%d,%d}, ForgetFactorTime=%4.1f min, Window=%4.1f min   [%s]',handles.aOrder2,handles.cOrder2, handles.bOrder2,handles.ForgTimeConst02/60, handles.WindowSize/(handles.FsID*60), handles.SaveModeFileName);
    else
        strFigTitle=sprintf('RRLS ARMAX{%d,%d,%d}, ForgetFactorTime=%4.1f min, Window=%4.1f min',handles.aOrder2,handles.cOrder2, handles.bOrder2,handles.ForgTimeConst02/60, handles.WindowSize/(handles.FsID*60));
    end
    set(handles.hdlModelPara,'String',strFigTitle);
    set(handles.hdlModelPara,'ForegroundColor',[0 0.5 0.2]);
    set(handles.hdlModelPara,'BackgroundColor',[1   1  1]);
    pause(1.0)    
    set(handles.hdlModelPara,'ForegroundColor',[0   0  0]);
    set(handles.hdlModelPara,'BackgroundColor',[0.9  0.9  0.9]);

    %------------------------------------------------------
    % initialize the parameters for the RRLS algorithms
    if handles.PDCMatLoaded 
        SubRRLSIni;
    end

end

guidata(hObject, handles);
