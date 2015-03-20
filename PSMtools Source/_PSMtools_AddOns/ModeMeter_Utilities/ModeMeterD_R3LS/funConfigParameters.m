function varargout = funConfigParameters(varargin)
% FUNCONFIGPARAMETERS M-file for funConfigParameters.fig
%      FUNCONFIGPARAMETERS by itself, creates a new FUNCONFIGPARAMETERS or raises the
%      existing singleton*.
%
%      H = FUNCONFIGPARAMETERS returns the handle to a new FUNCONFIGPARAMETERS or the handle to
%      the existing singleton*.
%
%      FUNCONFIGPARAMETERS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FUNCONFIGPARAMETERS.M with the given input arguments.
%
%      FUNCONFIGPARAMETERS('Property','Value',...) creates a new FUNCONFIGPARAMETERS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before funConfigParameters_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to funConfigParameters_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help funConfigParameters

% Last Modified by GUIDE v2.5 21-Aug-2008 11:46:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @funConfigParameters_OpeningFcn, ...
                   'gui_OutputFcn',  @funConfigParameters_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before funConfigParameters is made visible.
function funConfigParameters_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to funConfigParameters (see VARARGIN)

% Choose default command line output for funConfigParameters


% Update handles structure
guidata(hObject, handles);

% Insert custom Title and Text if specified by the user
% Hint: when choosing keywords, be sure they are not easily confused 
% with existing figure properties.  See the output of set(figure) for
% a list of figure properties.

%____________________________________________________
% Start 01: by Ning Zhou 08/20/2008
%keyboard;

if (nargin > 1)
    ModelOrder=varargin{1};
    handles.aOrder2=ModelOrder(1);      % AR
    handles.bOrder2=ModelOrder(2);      % X
    handles.cOrder2=ModelOrder(3);      % MA
else
    handles.aOrder2=10;      % AR
    handles.bOrder2=9;      % X
    handles.cOrder2=9;      % MA
end

if (nargin > 2)
    CalWindow=varargin{2};
    handles.WindowLength=CalWindow(1);      % windows length
    handles.ForgTimeConst02=CalWindow(2);   % equivalent window length of forgetting facotr
else
    handles.WindowLength=5*60;      
    handles.ForgTimeConst02=2*60;   
end

handles.IniModeFreqHalf  =nan(2,1);
handles.IniModeDRHalf    =nan(2,1);
handles.IniModeWeightHalf=zeros(2,1);

if (nargin > 3)
     IniMode=varargin{3};
     for rIndex=1:min([2 size(IniMode,1)])
         handles.IniModeFreqHalf(rIndex)=IniMode(rIndex,1);
         handles.IniModeDRHalf(rIndex)    =IniMode(rIndex,2);
         handles.IniModeWeightHalf(rIndex)=IniMode(rIndex,3);
     end
end
if (nargin > 4)
    handles.SaveMode=varargin{4};
else
    handles.SaveMode=0;
end
set(handles.checkboxSaveMode,'Value',handles.SaveMode);

handles.output = {[handles.aOrder2, handles.bOrder2, handles.cOrder2], [handles.WindowLength, handles.ForgTimeConst02]} ;

guidata(hObject, handles);  

set(handles.editaOrder2, 'String', num2str(handles.aOrder2));
set(handles.editbOrder2, 'String', num2str(handles.bOrder2));
set(handles.editcOrder2, 'String', num2str(handles.cOrder2));

set(handles.editWindowLength, 'String', num2str(handles.WindowLength));
set(handles.editForgTimeConst02, 'String', num2str(handles.ForgTimeConst02));
set(handles.editFreq1, 'String', num2str(handles.IniModeFreqHalf(1)));
set(handles.editFreq2, 'String', num2str(handles.IniModeFreqHalf(2)));
set(handles.editDR1, 'String', num2str(handles.IniModeDRHalf(1)));
set(handles.editDR2, 'String', num2str(handles.IniModeDRHalf(2)));
set(handles.editWeight1, 'String', num2str(handles.IniModeWeightHalf(1)));
set(handles.editWeight2, 'String', num2str(handles.IniModeWeightHalf(2)));

% End 01: by Ning Zhou 08/20/2008
%----------------------------------------------------


% Determine the position of the dialog - centered on the callback figure
% if available, else, centered on the screen
FigPos=get(0,'DefaultFigurePosition');
OldUnits = get(hObject, 'Units');
set(hObject, 'Units', 'pixels');
OldPos = get(hObject,'Position');
FigWidth = OldPos(3);
FigHeight = OldPos(4);
if isempty(gcbf)
    ScreenUnits=get(0,'Units');
    set(0,'Units','pixels');
    ScreenSize=get(0,'ScreenSize');
    set(0,'Units',ScreenUnits);

    FigPos(1)=1/2*(ScreenSize(3)-FigWidth);
    FigPos(2)=2/3*(ScreenSize(4)-FigHeight);
else
    GCBFOldUnits = get(gcbf,'Units');
    set(gcbf,'Units','pixels');
    GCBFPos = get(gcbf,'Position');
    set(gcbf,'Units',GCBFOldUnits);
    FigPos(1:2) = [(GCBFPos(1) + GCBFPos(3) / 2) - FigWidth / 2, ...
                   (GCBFPos(2) + GCBFPos(4) / 2) - FigHeight / 2];
end
FigPos(3:4)=[FigWidth FigHeight];
set(hObject, 'Position', FigPos);
set(hObject, 'Units', OldUnits);

% Show a question icon from dialogicons.mat - variables questIconData
% and questIconMap
load dialogicons.mat

IconData=questIconData;
questIconMap(256,:) = get(handles.figure1, 'Color');
IconCMap=questIconMap;

%Img=image(IconData, 'Parent', handles.axes1);
%set(handles.figure1, 'Colormap', IconCMap);

% set(handles.axes1, ...
%     'Visible', 'off', ...
%     'YDir'   , 'reverse'       , ...
%     'XLim'   , get(Img,'XData'), ...
%     'YLim'   , get(Img,'YData')  ...
%     );

%

% Make the GUI modal
set(handles.figure1,'WindowStyle','modal')

% UIWAIT makes funConfigParameters wait for user response (see UIRESUME)
uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = funConfigParameters_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% The figure can be deleted now
delete(handles.figure1);

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


handles.aOrder2 = str2double(get(handles.editaOrder2,'String'));
handles.bOrder2 = str2double(get(handles.editbOrder2,'String'));
handles.cOrder2 = str2double(get(handles.editcOrder2,'String'));

handles.WindowLength= str2double(get(handles.editWindowLength,'String'));
handles.ForgTimeConst02 = str2double(get(handles.editForgTimeConst02,'String'));


handles.IniModeFreqHalf(1)=str2double(get(handles.editFreq1, 'String'));
handles.IniModeFreqHalf(2)=str2double(get(handles.editFreq2, 'String'));
handles.IniModeDRHalf(1)  =str2double(get(handles.editDR1, 'String'));
handles.IniModeDRHalf(2)  =str2double(get(handles.editDR2, 'String'));
handles.IniModeWeightHalf(1)=str2double(get(handles.editWeight1, 'String' ));
handles.IniModeWeightHalf(2)=str2double(get(handles.editWeight2, 'String' ));

handles.SaveMode=get(handles.checkboxSaveMode,'Value');

handles.output = {[handles.aOrder2, handles.bOrder2, handles.cOrder2], [handles.WindowLength, handles.ForgTimeConst02], ...
    [handles.IniModeFreqHalf,handles.IniModeDRHalf, handles.IniModeWeightHalf],handles.SaveMode} ;

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%handles.output = get(hObject,'String');

handles.output=[];

% Update handles structure
guidata(hObject, handles);

% Use UIRESUME instead of delete because the OutputFcn needs
% to get the updated handles structure.
uiresume(handles.figure1);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(handles.figure1, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(handles.figure1);
else
    % The GUI is no longer waiting, just close it
    delete(handles.figure1);
end


% --- Executes on key press over figure1 with no controls selected.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check for "enter" or "escape"
if isequal(get(hObject,'CurrentKey'),'escape')
    % User said no by hitting escape
    handles.output = 'No';
    
    % Update handles structure
    guidata(hObject, handles);
    
    uiresume(handles.figure1);
end    
    
if isequal(get(hObject,'CurrentKey'),'return')
    uiresume(handles.figure1);
end    



function editbOrder2_Callback(hObject, eventdata, handles)
% hObject    handle to editbOrder2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editbOrder2 as text
%        str2double(get(hObject,'String')) returns contents of editbOrder2 as a double


% --- Executes during object creation, after setting all properties.
function editbOrder2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editbOrder2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editaOrder2_Callback(hObject, eventdata, handles)
% hObject    handle to editaOrder2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editaOrder2 as text
%        str2double(get(hObject,'String')) returns contents of editaOrder2 as a double


% --- Executes during object creation, after setting all properties.
function editaOrder2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editaOrder2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editcOrder2_Callback(hObject, eventdata, handles)
% hObject    handle to editcOrder2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editcOrder2 as text
%        str2double(get(hObject,'String')) returns contents of editcOrder2 as a double


% --- Executes during object creation, after setting all properties.
function editcOrder2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editcOrder2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editWindowLength_Callback(hObject, eventdata, handles)
% hObject    handle to editWindowLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWindowLength as text
%        str2double(get(hObject,'String')) returns contents of editWindowLength as a double


% --- Executes during object creation, after setting all properties.
function editWindowLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWindowLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editForgTimeConst02_Callback(hObject, eventdata, handles)
% hObject    handle to editForgTimeConst02 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editForgTimeConst02 as text
%        str2double(get(hObject,'String')) returns contents of editForgTimeConst02 as a double


% --- Executes during object creation, after setting all properties.
function editForgTimeConst02_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editForgTimeConst02 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDR1_Callback(hObject, eventdata, handles)
% hObject    handle to editDR1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDR1 as text
%        str2double(get(hObject,'String')) returns contents of editDR1 as a double


% --- Executes during object creation, after setting all properties.
function editDR1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDR1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFreq1_Callback(hObject, eventdata, handles)
% hObject    handle to editFreq1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFreq1 as text
%        str2double(get(hObject,'String')) returns contents of editFreq1 as a double


% --- Executes during object creation, after setting all properties.
function editFreq1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFreq1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editWeight1_Callback(hObject, eventdata, handles)
% hObject    handle to editWeight1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWeight1 as text
%        str2double(get(hObject,'String')) returns contents of editWeight1 as a double


% --- Executes during object creation, after setting all properties.
function editWeight1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWeight1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editDR2_Callback(hObject, eventdata, handles)
% hObject    handle to editDR2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDR2 as text
%        str2double(get(hObject,'String')) returns contents of editDR2 as a double


% --- Executes during object creation, after setting all properties.
function editDR2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDR2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editFreq2_Callback(hObject, eventdata, handles)
% hObject    handle to editFreq2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFreq2 as text
%        str2double(get(hObject,'String')) returns contents of editFreq2 as a double


% --- Executes during object creation, after setting all properties.
function editFreq2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFreq2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editWeight2_Callback(hObject, eventdata, handles)
% hObject    handle to editWeight2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWeight2 as text
%        str2double(get(hObject,'String')) returns contents of editWeight2 as a double


% --- Executes during object creation, after setting all properties.
function editWeight2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWeight2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSaveMode.
function checkboxSaveMode_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSaveMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSaveMode
handles.SaveMode=get(handles.checkboxSaveMode,'Value');
guidata(hObject, handles);

