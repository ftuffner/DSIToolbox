function ringdown(outdat,titles,inpulses,pol,opts,figNumber);

% RINGDOWN:  BPA/PNNL Ringdown Analysis Tool, Version 3.1.8, 30-Sept-2013
%
% Opens the BPA/PNNL Ringdown Analysis Tool.
% This tool provides an environment for analyzing signals using Fourier and/or
% Prony analysis based techniques.
%
% Usage:
%
%                    ringdown(outdat,titles,inpulses,pol,opts);
%
%                                       or
%
%                                    ringdown;
%
% If this function is called using the first statement above, the input arguments
% have the following meanings.
%
% outdat   = Signal Data matrix.
%            First column contains sample times and second through last contain
%            response data for each signal.  Time samples must have uniform spacing.
%
% titles   = Signal Title matrix.
%            Each row contains a title for the corresponding signal in outdat.
%            Enter as an empty string matrix ('') if no titles are known.
%
% inpulses = Input Pulse matrix.
%            First column is switch times T(i), i = 1, ..., ninputs, and second is
%            amplitudes P(i).  The matrix elements have the following interpretations.
%
%      Input |
%            |
%            |
%            |        --------------o P(2)
%            |        |             |        -------------o P(4)
%            |--------o P(1)        |        |            |
%            |                      ---------o P(3)       |
%            |                                            |        ...
%           -|--------|-------------|--------|------------|---------------->
%       Start Time   T(1)          T(2)     T(3)         T(4)           Time
%
%            Enter as an empty matrix ([]) is there are no input pulses.
%
% pol      = Known Pole matrix.
%            Enter as an empty matrix ([]) if there are no known pole locations.
%            Note that this is given as a vector of complex poles
%
% opts     = Structure containing additional options.  This allows additional
%            entry of additional customization options and can be omitted by
%            most users.  Type 'type ringdown' to view additional information
%            about this argument.
%
% If the function is called using the second statement above, the user is prompted
% to either provide variable names for the input arguments or select a file from
% which to read signal data.
%
% See also GETMODEL.

% Currently, the Ringdown Analysis Tool recognizes the following 'opts' structure
% fields:
%
%              copyplotfcn  = Name of function to call when any setup or results
%                             screen plots are copied to separate figures.  This
%                             function must accept as it's first input a structure
%                             containing information about the generated figure.
%                             This structure contains the following fields:
%
%                             figHndl   = Handle to generated figure.
%                             axesHndls = Handles to axes objects on figure.  Top
%                                         axis is listed first.
%                             plottypes = String specifying plot type for axes.
%                                         This can be one of the following:
%                                         'tr'   = Time response plot
%                                         'frm'  = Frequency response (magnitude) plot
%                                         'frp'  = Frequency response (phase) plot
%                                         'pz'   = Pole-Zero plot
%                                         'ak'   = Akaike information vector plot
%                                         'mtbl' = Mode table plot
%                             lineHndls = Vector of handles to lines on axis object.
%                                         This argument is empty for mode table plots.
%                             titles    = Cell array of strings.  Each cell contains
%                                         the signal title corresponding to the line
%                                         in lineHndls.  For pole-zero plots, titles
%                                         has only one cell although lineHndls will
%                                         contain two elements.  The first represents
%                                         the pole markers, the second the zero markers.
%
%              Note:  If more than one axis handle is present, plottype, lineHndls,
%                     and titles will each be cell arrays with each cell containing
%                     information for the corresponding axis.
%
%              copyplotargs = Cell array containing additional input arguments
%                             to copyplotfcn.

% MATLAB interface by Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date:  October 1996
%
% Improved for 20 signals and 8192 points. April 2003
% Translation of various features to native MATLAB. September 2013
%
% Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% Disable warnings.  Remember the warning state.
  warnstate=warning; warning off;

  if nargin==1 & ischar(outdat)
    if strcmp(outdat,'rcsid')               % Print RCSID stamp and copyright
      fprintf(1,['\n$Id$\n\n' ...
        'Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government\n' ...
        'retains a paid-up nonexclusive, irrevocable worldwide license to\n' ...
        'reproduce, prepare derivative works, perform publicly and display\n' ...
        'publicly by or for the Government, including the right to distribute\n' ...
        'to other Government contractors.\n\n' ...
        'Date of last source code modification:  02/04/2008 (JMJ)\n\n']);
    else
      h=0; eval(outdat); if h; assignin('caller',wksvar,idmodel); end
    end
    warning warnstate;
    return
  end

% If no input arguments are present, open the data import tool and exit.
  if nargin==0; rguiload([],1); warning warnstate; return; end

  % If nargin<6, cause a new figure to be generated.
  if nargin<6; figNumber=[]; end

  % Fill in missing inputs
  if nargin<5; opts=[]; end
  if nargin<4; pol=[]; end
  if nargin<3; inpulses=[]; end
  if nargin<2; titles=''; end

% Check input arguments.
  dbl='double';
  if ~isa(outdat,dbl)
    warning warnstate;
    errmsg='Signal Data matrix must be a double precision matrix.';
    if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
  end
  if ~isempty(titles) & ~ischar(titles)
    warning warnstate;
    errmsg='Signal Title matrix must be a character matrix.';
    if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
  end
  if ~isa(inpulses,dbl)
    warning warnstate;
    errmsg='Input Pulse matrix must be a double precision matrix.';
    if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
  end
  if ~isa(pol,dbl)
    warning warnstate;
    errmsg='Known Pole matrix must be a double precision matrix.';
    if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
  end
  if ~isempty(opts) & ~isstruct(opts)
    warning warnstate;
    errmsg='Options structure must be empty or a 1 x 1 structure array.';
    if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
  end

  tol=10*eps; ep=1e-6;
  sigcon=size(outdat,2)-1;
  ninputs=size(inpulses,1);
  if sigcon<=0
    warning warnstate;
    errmsg='Signal Data matrix must have at least two columns.';
    if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
  end
  if ~isempty(titles)
    if size(titles,1)==sigcon+1; titles=titles(2:end,:); end
    if size(titles,1)~=sigcon
      warning warnstate;
      errmsg=['Number of rows in Signal Title matrix must be one less than ' ...
              'number of columns in Signal Data matrix.'];
      if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
    end
  end
  if ninputs
    if size(inpulses,2)~=2
      warning warnstate;
      errmsg='Input Pulse matrix must be empty or have two columns.';
      if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
    end

    if any(diff(inpulses(:,1))<0)
      warning warnstate;
      errmsg='Input Pulse switch times must be in ascending order.';
      if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
    end
  end

  % Make sure sample times are in ascending order
  if any(diff(outdat(:,1))<0)
    [jj,ind]=sort(outdat(:,1));
    outdat=outdat(ind,2:sigcon);
  end

  % Find and remove repeated sample times.
  ind=diff(outdat(:,1))<tol;
  if any(ind)
    ind=[ind; 0];
    ind2=ind | [0; ind(1:length(ind)-1)];
    repeatdat=outdat(ind2,:);
    ind3=diff([0; ind])>0;
    for ii=find(ind3)'
      jj=1;
      while ind(ii+jj); jj=jj+1; end
      outdat(ii,:)=mean(outdat(ii:ii+jj,:));
    end
    outdat(xor(ind2,ind3),:)=[];
  else
    repeatdat=[];
  end

  % Calculate and check tstep.
  delt=diff(outdat(:,1));
  tstep=mean(delt);
  if tstep<=1e-12
    warning warnstate;
    errmsg='Sample period too small.  Must be > 1e-12.';
    if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
  end
  if any(delt>=1.1*tstep | delt<=0.9*tstep)
    warning warnstate;
    errmsg='Sample times must have uniform spacing.';
    if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
  end

  nnout=size(outdat,1);
  outdat(:,1)=tstep*(0:nnout-1)';
  tend=outdat(nnout,:);
  ftrh=1/(3*tstep);
  trre=1e-8;

  % Make sure last pulse amplitude is nonzero.  Calculate the minimum shift.
  if ninputs
    while abs(inpulses(ninputs,2))<tol; ninputs=ninputs-1; end
  end

  if ninputs
    inpulses=inpulses(1:ninputs,:);
    instep=inpulses(ninputs,1)>=tend(1);
  else
    inpulses=[];
    instep=0;
  end

  if ninputs-instep>0
    minshift=floor(inpulses(ninputs-instep,1)/tstep+ep)+1;
  else
    minshift=0;
  end

  % Check the number of data points.
  if nnout-minshift<4
    warning warnstate;
    errmsg='Number of samples per signal is too small.';
    if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
  end

  % Find the known modes.
  if isempty(pol)
    knwmod=[];
  else
    ind=imag(pol(:,1))>=0;
    knwmod=[-real(pol(ind)) imag(pol(ind))];
  end

  % Make control strings.
  tsteps=num2str(tstep);
  ftrhs=num2str(ftrh);
  nyqs=num2str(1/(2*tstep));
  trres=num2str(trre);

  % Setup screen parameter matrices.
  setupcon1=zeros(14,1); setupcon1(1)=tstep; setupcon1(2)=nnout;
  setupcon1(3)=1; setupcon1(4)=1; setupcon1(5)=1; setupcon1(6)=1;
  setupcon1(8)=3; setupcon1(9)=1; setupcon1(12)=ftrh; setupcon1(14)=trre;
  setupcon2=zeros(7,sigcon);
  setupcon2(1,1)=1; setupcon2([2 5 6],:)=NaN*ones(3,sigcon);
  setupcon2(3,:)=nnout*ones(1,sigcon);

  % Setup screen plot controls.
  pltctrls=zeros(4,2); pltctrls(:,1)=NaN*zeros(4,1); pltctrls(4,2)=1/(2*tstep);

  % Setup screen frequency response plot axes positions.
  if ninputs
    fraxs1Pos=[0.100 0.430 0.540 0.160]; fraxs2Pos=[0.100 0.250 0.540 0.160];
    frtitlPos=[0.370 0.610]; frylb1Pos=[0.045 0.510]; frylb2Pos=[0.045 0.330];
  else
    fraxs1Pos=[0.100 0.470 0.540 0.200]; fraxs2Pos=[0.100 0.250 0.540 0.200];
    frtitlPos=[0.370 0.690]; frylb1Pos=[0.045 0.570]; frylb2Pos=[0.045 0.350];
  end

%===============================================
% Strings with object property names and values.

  CallBack        ='CallBack';
  Checked         ='Checked';
  Enable          ='Enable';
  Label           ='Label';
  OType           ='Type';
  Pointer         ='Pointer';
  Position        ='Position';
  String          ='String';
  Tag             ='Tag';
  UserData        ='UserData';
  Value           ='Value';
  Visible         ='Visible';

  addstr          ='add';
  axesstr         ='axes';
  newstr          ='new';
  offstr          ='off';
  onestr          ='1';
  onstr           ='on';
  output1str      ='Output 1';
  output1str      ='All selected outputs | Output 1';        % add "all signals". Henry, 04/04/03
  textstr         ='text';
  titlestr        ='title';
  xlablstr        ='xlabel';
  ylablstr        ='ylabel';
  zerstr          ='0';

  adfrmlabbtnTag  ='adfrmlabbtn';
  expmenuTag      ='expmenu';
  fbctrlTag       ='fbctrl';
  fcctrlTag       ='fcctrl';
  ffindTag        ='ffind';
  ftrhctrlTag     ='ftrhctrl';
  ftrhctrl1Tag    ='ftrhctrl1';
  ftrhctrl2Tag    ='ftrhctrl2';
  ftrhindTag      ='ftrhind';
  ftrlctrlTag     ='ftrlctrl';
  ftrlctrl1Tag    ='ftrlctrl1';
  ftrlctrl2Tag    ='ftrlctrl2';
  inpaxesTag      ='inpaxes';
  lpactrlTag      ='lpactrl';
  lpmctrlTag      ='lpmctrl';
  lpoctrl1Tag     ='lpoctrl1';
  lpoctrl2Tag     ='lpoctrl2';
  mtblTag         ='mtbl';
%  msigctrlTag     ='msigctrl';     % deleted by Henry, 04/23/03
  mtselctrlTag    ='mtselctrl';
  nqindTag        ='nqind';
  ordctrlTag      ='ordctrl';
  outmenuTag      ='outmenu';
  outsubmenuTag   ='outsubmenu';
  polmenuTag      ='polmenu';
  polsubmenuTag   ='polsubmenu';
  
  allpolsubmenuTag   ='allpolsubmenu';      % Henry, 06/02/03

  prfmenuTag      ='prfmenu';
  rrctrlTag       ='rrctrl';
  rscfctrlTag     ='rscfctrl';
  rsdectrlTag     ='rsdectrl';
  rsfiltctrlTag   ='rsfiltctrl';

  rsDLIM1labTag   ='rsDLIM1lab';    % Henry, 03/25/03
  rsDLIM1ctrlTag  ='rsDLIM1ctrl';   % Henry, 03/25/03
  rsFLIM1labTag   ='rsFLIM1lab';    % Henry, 03/25/03
  rsFLIM1ctrlTag  ='rsFLIM1ctrl';   % Henry, 03/25/03
  rsFLIM2labTag   ='rsFLIM2lab';    % Henry, 03/25/03
  rsFLIM2ctrlTag  ='rsFLIM2ctrl';   % Henry, 03/25/03
  
  rsfraxs1Tag     ='rsfraxs1';
  rsfraxs2Tag     ='rsfraxs2';
  rsfrmlabbtnTag  ='rsfrmlabbtn';
  rsmenuTag       ='rsmenu';
  rspzaxesTag     ='rspzaxes';
  rstraxesTag     ='rstraxes';
  rswinctrlTag    ='rswinctrl';
  scctrlTag       ='scctrl';
  
  sortctrlTag     ='sortctrl';      % Henry, 03/20/03
  
  sscfctrlTag     ='sscfctrl';
  ssdectrlTag     ='ssdectrl';
  ssfiltctrlTag   ='ssfiltctrl';
  ssfraxs1Tag     ='ssfraxs1';
  ssfraxs2Tag     ='ssfraxs2';
  ssfrctrlTag     ='ssfrctrl';
  ssfrmlabbtnTag  ='ssfrmlabbtn';
  ssfillctrlTag   ='ssfillctrl';
  ssmenuTag       ='ssmenu';
  ssoutctrlTag    ='ssoutctrl';
  sstraxesTag     ='sstraxes';
  sstrctrl1Tag    ='sstrctrl1';
  sswinctrlTag    ='sswinctrl';
  stctrlTag       ='stctrl';
  trrectrlTag     ='trrectrl';
  trrectrl1Tag    ='trrectrl1';
  trrectrl2Tag    ='trrectrl2';
  tsind1Tag       ='tsind1';
  tsind2Tag       ='tsind2';

  if tstep<1; fltenbl=onstr; else; fltenbl=offstr; end

%============================================================================
% If no Ringdown GUI figure handle was entered, create the figure.
  if isempty(figNumber)

    newfig=1;

  % More strings with object property names and values.

    BackgroundColor    ='BackgroundColor';
    Color              ='Color';
    DAxesFontName      ='DefaultAxesFontName';
    DTextHAlign        ='DefaultTextHorizontalAlignment';
    HorizontalAlignment='HorizontalAlignment';
    LineWidth          ='LineWidth';
    Rotation           ='Rotation';
    Separator          ='Separator';
    Style              ='Style';
    ToolTipString      ='ToolTipString';
    Units              ='Units';
    XColor             ='XColor';
    XLim               ='XLim';
    XTick              ='XTick';
    YColor             ='YColor';
    YLim               ='YLim';
    YTick              ='YTick';

    centerstr          ='center';
    checkboxstr        ='checkbox';
    editstr            ='edit';
    framestr           ='frame';
    leftstr            ='left';
    nonstr             ='none';
    normstr            ='normalized';
    popupmenustr       ='popupmenu';
    pushbuttonstr      ='pushbutton';
    radiobuttonstr     ='radiobutton';
    togglebuttonstr    ='togglebutton';

    aktitlestr         ='Akaike Final Prediction Error for Signal %d.';
    autostr            ='Auto:';
    cancelstr          ='Cancel';
    dashstr            ='-';
    etstr              ='End Time:';
    frctrllablstr      ='Frequency:';
    frtitl1str         ='Discrete Fourier Transform Spectrum';
    frtitl2str         ='Signal Spectrum and Model Response';
    frmylabstr         ='Magnitude (dB)';
    frpylabstr         ='Phase (deg)';
    frxlablstr         ='Frequency (Hz)';
    itstr              ='Initial Time:';
    fillstr            ='No Fill|Left Fill';
    postr              ='Plot Options';
    prlabel1str        ='Plot Range Controls';
    prlabel2str        ='*Also used for Fourier calculations.';
    pztitlestr         ='Pole-Zero Plot';
    resetstr           ='Reset';
    sfiltstr           ='Smoothing Filter';
    spacestr           =' ';
    ststr              ='Set:';
    titlstr            ='Title:';
    trctrllablstr      ='Time Series*:';
    trtitlestr         ='Time Response';
    trxlablstr         ='Time (sec)';
    winstr             ='No Window|Hanning Window';

  %===============================================
  % Check the options structure.

    if ~isempty(opts); opts=opts(1); end
    if isfield(opts,'copyplotfcn')
      if ~isempty(opts.copyplotfcn); opts.copyplotfcn=opts.copyplotfcn(1,:); end
      if ~ischar(opts.copyplotfcn)
        warning warnstate;
        errmsg=['Field ''copyplotfcn'' in opts input must be a string.'];
        if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
      end
      if exist([opts.copyplotfcn '.m'])~=2
        h=questdlg(['Unable to locate function ''' opts.copyplotfcn '''.'], ...
          '''Opts'' Input Warning','Continue',cancelstr,cancelstr);
        if strcmp(h,cancelstr); return; end
      end
    else
      opts.copyplotfcn='';
    end
    if isfield(opts,'copyplotargs')
      if ~iscell(opts.copyplotargs)
        warning warnstate;
        errmsg=['Field ''copyplotargs'' in opts input must be a cell array.'];
        if nargin==6; errordlg(errmsg); return; else; error(errmsg); end
      end
    else
      opts.copyplotargs=cell(0);
    end

  %===============================================
  % Set the figure size and position.  Set colors.
    rguipref('rguifcn',6); editHt2=editHt/2;

    rguiprefs=[mtbAParameterColor; mtbIParameterColor; ...
               mtbSParameterColor; lineColorOrder];

  %===============================================
  % Display the title screen.
  %===============================================

    fprintf(1,['\nOpening BPA/PNNL Ringdown Analysis Tool, please wait ']);
    rguitit(1,axesFontName,axesFontSize);

  %===============================================
  % Create the GUI figure.  Set default property values.
  %===============================================

    figNumber=figure('NumberTitle',onstr, ...
      'Name','BPA/PNNL Ringdown Analysis Tool','MenuBar',nonstr, ...
      Pointer,'watch',Units,'pixels',Position,figPos,Visible,offstr, ...
      Color,figBackgroundColor);

    figTag=sprintf('RGUIFIG%d',figNumber);
    closefcn=['delete(findobj(0,''Tag'',''' figTag '''));'];

    set(figNumber,Tag,figTag,'CloseRequestFcn',closefcn, ...
      'DefaultUicontrolUnits',normstr, ...
      'DefaultUicontrolFontSize',uictrlFontSize, ...
      'DefaultUicontrolForegroundColor','black', ...
      'DefaultUicontrolInterruptible',offstr, ...
      'DefaultUimenuInterruptible',offstr, ...
      'DefaultAxesUnits',normstr,'DefaultAxesBox',onstr, ...
      'DefaultAxesXColor',axesForegroundColor, ...
      'DefaultAxesYColor',axesForegroundColor, ...
      'DefaultAxesXGrid',axesGrid,'DefaultAxesYGrid',axesGrid, ...
      'DefaultAxesColor',axesBackgroundColor, ...
      'DefaultAxesFontSize',axesFontSize, ...
      'DefaultAxesColorOrder',axesBackgroundColor, ...
      'DefaultAxesLineStyleOrder',lineStyleOrder, ...
      'DefaultAxesLineWidth',get(0,'FactoryAxesLineWidth'), ...
      'DefaultAxesTickDir','in', ...
      'DefaultLineLineWidth',get(0,'FactoryLineLineWidth'), ...
      'DefaultTextColor',axesForegroundColor, ...
      'DefaultTextFontSize',axesFontSize, ...
      'DefaultTextInterruptible',offstr, ...
      'DefaultTextInterpreter','tex');

    h=0;
    eval(['set(figNumber,''DefaultAxesFontName'',''' axesFontName ''');'],'h=1;');
    if h
      axesFontName=axesFontNamed; h=0;
      eval(['set(figNumber,''DefaultAxesFontName'',''' axesFontName ''');'],'h=1;');
      if h
        axesFontName=get(0,DAxesFontName);
        set(figNumber,DAxesFontName,axesFontName); h=0;
      end
    end
    set(figNumber,'DefaultTextFontName',axesFontName);
    eval(['set(figNumber,''DefaultUicontrolFontName'',''' uictrlFontName ''');'],'h=1;');
    if h
      eval(['set(figNumber,''DefaultUicontrolFontName'',''' uictrlFontNamed ''');'],'');
    end

  %===============================================
  % Create the menus.
  %===============================================
  % The File menu and submenus.

    h=uimenu(figNumber,Tag,'filmenu',Label,'File',UserData,inpulses);
 
    uimenu(h,Label,'Import Data',CallBack,'ringdown(''rguiload(gcf,1);'');', ...
      'Interruptible',onstr);

    uimenu(h,Tag,expmenuTag,Label,'Export Results',Enable,offstr, ...
      CallBack,'ringdown(''rguisave(gcf,1);'');');

    uimenu(h,Tag,prfmenuTag,Label,'Preferences',Separator,onstr, ...
      UserData,rguiprefs,CallBack,'ringdown(''rguipref(gcf,1);'');');

    uimenu(h,Label,'Exit Ringdown Tool',Separator,onstr,CallBack,closefcn);

  %===============================================
  % The Copy menu and submenus
 
    h=uimenu(figNumber,Tag,'copmenu',Label,'Copy',UserData,opts);

    uimenu(h,Tag,'copytr',Label,'Time Response Plot', ...
      CallBack,'ringdown(''rguimgr(15,1);'');');

    h2=uimenu(h,Tag,'copyfr',Label,'Frequency Plots');
    uimenu(h2,Label,'Magnitude and Phase',CallBack,'ringdown(''rguimgr(15,2);'');');
    uimenu(h2,Label,'Magnitude Only',CallBack,'ringdown(''rguimgr(15,3);'');');
    uimenu(h2,Label,'Phase Only',CallBack,'ringdown(''rguimgr(15,4);'');');

    uimenu(h,Tag,'copypz',Label,pztitlestr,CallBack,'ringdown(''rguimgr(15,5);'');');

    h2=uimenu(h,Tag,'copymt',Label,'Active Mode Parameters');
    uimenu(h2,Label,'Mode Parameters Only',CallBack,'ringdown(''rguimgr(14,1);'');');
    uimenu(h2,Label,'Include FF Term and SNR',CallBack,'ringdown(''rguimgr(14,2);'');');
 
  %===============================================
  % The Outputs menu.
 
    outmenuHndl=uimenu(figNumber,Tag,outmenuTag,Label,'Outputs',UserData,outdat);

  %===============================================
  % The Poles menu and submenus.

    polmenuHndl=uimenu(figNumber,Tag,polmenuTag,Label,'Poles',UserData,knwmod);
 
    uimenu(polmenuHndl,Label,'Frequency (Hz)     Damping        Damping Ratio');

  %===============================================
  % The Screen menu and submenus.

    h=uimenu(figNumber,Tag,'scrmenu',Label,'Screen',UserData,repeatdat);
 
    uimenu(h,Tag,ssmenuTag,Label,'Setup Screen',Checked,onstr, ...
      CallBack,'ringdown(''rguimgr(7,1);'');');

    uimenu(h,Tag,rsmenuTag,Label,'Results Screen',Enable,offstr, ...
      CallBack,'ringdown(''rguimgr(7,3);'');');

    uimenu(h,Label,'About',Separator,onstr,CallBack,'ringdown(''rguitit(2);'');');
 
    drawnow; set(figNumber,Visible,onstr); fprintf(1,'.')

  %===============================================
  % Create the setup screen.
  %===============================================
  % The setup screen plot axes and labels.

    bkaxesHndl=axes(Visible,offstr,Position,[0 0 1 1],XLim,[0 1],YLim,[0 1], ...
      Color,nonstr,DTextHAlign,centerstr);

    text(0.370,0.980,'Input Pulses',Tag,inpaxesTag,Visible,offstr);
    text(0,0,trtitlestr,Tag,sstraxesTag,Visible,offstr,UserData,titlestr);
    text(0,0,trxlablstr,Tag,sstraxesTag,Visible,offstr,UserData,xlablstr);
    text(frtitlPos(1),frtitlPos(2),frtitl1str,Tag,ssfraxs1Tag,Visible,offstr, ...
      UserData,titlestr);

    text(frylb1Pos(1),frylb1Pos(2),frmylabstr,Tag,ssfraxs1Tag,Visible,offstr, ...
      Rotation,90,UserData,ylablstr);

    text(frylb2Pos(1),frylb2Pos(2),frpylabstr,Tag,ssfraxs2Tag,Visible,offstr, ...
      Rotation,90,UserData,ylablstr);

    text(0.370,0.205,frxlablstr,Tag,ssfraxs2Tag,Visible,offstr,UserData,xlablstr);

    axes(Tag,inpaxesTag,Visible,offstr,Position,[0.100 0.880 0.540 0.080]);
    axes(Tag,sstraxesTag,Visible,offstr,Position,[0 0 1 1]);
    axes(Tag,ssfraxs1Tag,Visible,offstr,Position,fraxs1Pos);
    axes(Tag,ssfraxs2Tag,Visible,offstr,Position,fraxs2Pos);

  %===============================================
  % The setup screen uicontrols.

%    uicontrol(figNumber,Style,'listbox',Tag,'sslegend',Visible,offstr, ...
%      Position,[0.005 0.20 0.075 0.200],BackgroundColor,frmBackgroundColor, ...
%      ToolTipString,'Legend');                                                              % Legend list, Henry, 06/30/03

    uicontrol(figNumber,Style,framestr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.000 0.000 0.610 0.185],BackgroundColor,frmBackgroundColor, ...
      ToolTipString,['Set Prony Analysis parameters for current signal']);

    uicontrol(figNumber,Style,popupmenustr,Tag,ssoutctrlTag,Visible,offstr, ...
      Position,[0.010 0.135 0.170 0.040],HorizontalAlignment,centerstr, ...
      String,output1str,Value, 2, UserData,[2 2],CallBack,'ringdown(''rguimgr(1,5);'');', ...       % Set Value to 2. Henry, 04/07/03
      BackgroundColor,btnBackgroundColor,ToolTipString,'Selects current signal');

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.200 0.140 0.040 0.030],HorizontalAlignment,leftstr, ...
      String,titlstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'sstitctrl',Visible,offstr, ...
      Position,[0.240 0.155-editHt2 0.360 editHt],HorizontalAlignment,leftstr, ...
      CallBack,'ringdown(''rguimgr(11,1);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Signal title (editable)');

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.095 0.100 0.030],HorizontalAlignment,leftstr, ...
      String,itstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'dsctrl',Visible,offstr, ...
      Position,[0.110 0.110-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(1,6);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,['Time of first sample from current signal to use in Prony ' ...
      'Analysis (relative to Time-Zero Reference)']);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.220 0.095 0.100 0.030],HorizontalAlignment,leftstr, ...
      String,'Data Points:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,'npind',Visible,offstr, ...
      Position,[0.320 0.095 0.070 0.030],HorizontalAlignment,centerstr, ...
      BackgroundColor,indBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.430 0.095 0.100 0.030],HorizontalAlignment,leftstr, ...
      String,etstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'etctrl',Visible,offstr, ...
      Position,[0.530 0.110-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(1,7);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,['Time of last sample from current signal to use in Prony ' ...
      'Analysis (relative to Time-Zero Reference)']);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.190 0.055 0.230 0.030],HorizontalAlignment,centerstr, ...
      String,'Trend Removal Controls',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.015 0.100 0.030],HorizontalAlignment,leftstr, ...
      String,itstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'dtinictrl',Visible,offstr, ...
      Position,[0.110 0.030-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(1,9);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,['Time of first sample to use for calculating trend ' ...
      '(relative to Time-Zero reference)']);

    uicontrol(figNumber,Style,popupmenustr,Tag,'ssdtmodctrl',Visible,offstr, ...
      Position,[0.190 0.010 0.230 0.040],String,['No Detrend|Remove initial ' ...
      'value|Remove mean value|Remove final value|Remove ramp|Reset Detrend Times'], ...
      CallBack,'ringdown(''rguimgr(1,8);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Select trend removal method for Fourier and Prony analyses');

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.430 0.015 0.100 0.030],HorizontalAlignment,leftstr, ...
      String,etstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'dtendctrl',Visible,offstr, ...
      Position,[0.530 0.030-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(1,10);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,['Time of last sample to use for calculating trend ' ...
      '(relative to Time-Zero reference)']);

    uicontrol(figNumber,Style,framestr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.670 0.870 0.330 0.130],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.960 0.310 0.030],HorizontalAlignment,centerstr, ...
      String,postr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,togglebuttonstr,Tag,ssfrctrlTag,Visible,offstr, ...
      Position,[0.680 0.920 0.310 0.030],HorizontalAlignment,leftstr, ...
      String,'Fourier Spectrum Plots',Value,0,CallBack,'ringdown(''rguimgr(9,2);'');', ...
      BackgroundColor,btnBackgroundColor,ToolTipString,'Toggles frequency spectrum plots');

%    uicontrol(figNumber,Style,togglebuttonstr,Tag,msigctrlTag,Visible,offstr, ...          % deleted by Henry, 04/23/03
%      Position,[0.680 0.880 0.310 0.030],HorizontalAlignment,leftstr, ...
%      String,'Multiple Signal Plots',Value,0,CallBack,'ringdown(''rguimgr(9,3);'');', ...
%      BackgroundColor,btnBackgroundColor,ToolTipString,'Toggles multi-signal plots');

    uicontrol(figNumber,Style,framestr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.670 0.775 0.330 0.090],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.825 0.310 0.030],HorizontalAlignment,centerstr, ...
      String,'Filter Options',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,togglebuttonstr,Tag,ssfiltctrlTag,Visible,offstr, ...
      Position,[0.680 0.785 0.160 0.030],HorizontalAlignment,leftstr, ...
      String,sfiltstr,Value,0,Enable,fltenbl,CallBack,'ringdown(''rguimgr(1,16);'');', ...
      BackgroundColor,btnBackgroundColor,ToolTipString,['Apply Sinc-Hamming FIR ' ...
      'filter to all signals']);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.850 0.785 0.070 0.030],HorizontalAlignment,leftstr, ...
      String,'Cutoff:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,sscfctrlTag,Visible,offstr, ...
      Position,[0.920 0.800-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      String,onestr,Enable,fltenbl,CallBack,'ringdown(''rguimgr(1,17);'');', ...
      BackgroundColor,edtBackgroundColor,ToolTipString,'Filter cutoff frequency');

    uicontrol(figNumber,Style,framestr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.670 0.560 0.330 0.210],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.730 0.310 0.030],HorizontalAlignment,centerstr, ...
      String,'Decimate Options',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.690 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Original Sample Period:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,tsind1Tag,Visible,offstr, ...
      Position,[0.920 0.690 0.070 0.030],HorizontalAlignment,centerstr, ...
      String,tsteps,BackgroundColor,indBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.650 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Decimate Factor:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,ssdectrlTag,Visible,offstr, ...
      Position,[0.920 0.665-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      String,onestr,UserData,setupcon2,CallBack,'ringdown(''rguimgr(1,12);'');', ...
      BackgroundColor,edtBackgroundColor,ToolTipString,['Factor by which to ' ...
      'decimate all signals']);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.610 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Resulting Sample Period:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,tsind2Tag,Visible,offstr, ...
      Position,[0.920 0.610 0.070 0.030],HorizontalAlignment,centerstr, ...
      String,tsteps,BackgroundColor,indBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.570 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Resulting Nyquist Frequency:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,nqindTag,Visible,offstr, ...
      Position,[0.920 0.570 0.070 0.030],HorizontalAlignment,centerstr, ...
      String,nyqs,BackgroundColor,indBackgroundColor);

    uicontrol(figNumber,Style,framestr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.670 0.295 0.330 0.260],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.515 0.310 0.030],HorizontalAlignment,centerstr, ...
      String,'Prony Analysis Options',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.475 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Time Zero Reference:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,stctrlTag,Visible,offstr, ...
      Position,[0.920 0.490-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      String,zerstr,UserData,setupcon1,CallBack,'ringdown(''rguimgr(1,11);'');', ...
      BackgroundColor,edtBackgroundColor,ToolTipString,['Time Prony Analysis ' ...
      'model will reference as zero']);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.435 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Total Data Points:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,'tnpind',Visible,offstr, ...
      Position,[0.920 0.435 0.070 0.030],HorizontalAlignment,centerstr, ...
      BackgroundColor,indBackgroundColor);

    uicontrol(figNumber,Style,radiobuttonstr,Tag,fcctrlTag,Visible,offstr, ...
      Position,[0.680 0.395 0.150 0.030],HorizontalAlignment,leftstr, ...
      String,'Full Calculation',Value,1,CallBack,'ringdown(''rguimgr(1,14);'');', ...
      BackgroundColor,chkBackgroundColor,ToolTipString,['Full calculation ' ...
      '(poles and residues).  Known poles are selected from ''Poles'' menu']);

    uicontrol(figNumber,Style,radiobuttonstr,Tag,rrctrlTag,Visible,offstr, ...
      Position,[0.840 0.395 0.150 0.030],HorizontalAlignment,leftstr, ...
      String,'Residues Only',Value,0,CallBack,'ringdown(''rguimgr(1,15);'');', ...
      BackgroundColor,chkBackgroundColor,ToolTipString,['Residue only ' ...
      'calculation.  Poles are selected from ''Poles'' menu']);

    uicontrol(figNumber,Style,togglebuttonstr,Tag,scctrlTag,Visible,offstr, ...
      Position,[0.680 0.355 0.310 0.030],String,'Normalize all Signals', ...
      Value,0,CallBack,'ringdown(''rguimgr(1,13);'');', ...
      BackgroundColor,btnBackgroundColor,ToolTipString,['Scale all signals ' ...
      'so maximum amplitudes are 1']);

    uicontrol(figNumber,Style,pushbuttonstr,Tag,'adctrlbtn',Visible,offstr, ...
      Position,[0.680 0.305 0.150 0.040],String,'Advanced Options', ...
      CallBack,'ringdown(''rguimgr(8,1);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Show advanced options screen');

    uicontrol(figNumber,Style,pushbuttonstr,Tag,'displtbtn',Visible,offstr, ...
      Position,[0.680 0.305 0.150 0.040],String,'Display Plots', ...
      CallBack,'ringdown(''rguimgr(9,1);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Hide advanced options screen');

    uicontrol(figNumber,Style,pushbuttonstr,Tag,'pabtn',Visible,offstr, ...
      Position,[0.840 0.305 0.150 0.040],String,'Prony Analysis', ...
      CallBack,'ringdown(''rguimgr(16,1);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Perform Prony Analysis');

    uicontrol(figNumber,Style,framestr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.670 0.190 0.330 0.100],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.680 0.250 0.310 0.030],HorizontalAlignment,centerstr, ...
      String,'Fourier Options',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,popupmenustr,Tag,ssfillctrlTag,Visible,offstr, ...
      Position,[0.680 0.200 0.150 0.040],String,fillstr,Value,2, ...
      CallBack,'ringdown(''rguimgr(2,8);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Fourier analysis zero pad options');

    uicontrol(figNumber,Style,popupmenustr,Tag,sswinctrlTag,Visible,offstr, ...
      Position,[0.840 0.200 0.150 0.040],String,winstr,Value,2, ...
      CallBack,'ringdown(''rguimgr(2,8);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Fourier analysis windowing options');

    uicontrol(figNumber,Style,framestr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.615 0.000 0.385 0.185],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.625 0.145 0.365 0.030],HorizontalAlignment,centerstr, ...
      String,prlabel1str,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.625 0.010 0.370 0.030],HorizontalAlignment,leftstr, ...
      String,prlabel2str,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.625 0.095 0.110 0.030],HorizontalAlignment,leftstr, ...
      String,trctrllablstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,sstrctrl1Tag,Visible,offstr, ...
      Position,[0.735 0.110-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      UserData,pltctrls,CallBack,'ringdown(''rguimgr(2,2);'');', ...
      BackgroundColor,edtBackgroundColor,ToolTipString,['Time response plot lower ' ...
      'limit']);

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.810 0.095 0.010 0.030],HorizontalAlignment,leftstr, ...
      String,dashstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'sstrctrl2',Visible,offstr, ...
      Position,[0.825 0.110-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(2,3);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Time response plot upper limit');

    uicontrol(figNumber,Style,pushbuttonstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.900 0.110-editHt2 0.090 editHt],String,resetstr, ...
      CallBack,'ringdown(''rguimgr(2,4);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Reset time response plot limits');

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.625 0.055 0.110 0.030],HorizontalAlignment,leftstr, ...
      String,frctrllablstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'ssfrctrl1',Visible,offstr, ...
      Position,[0.735 0.070-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(2,5);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Frequency spectrum plot lower limit');

    uicontrol(figNumber,Style,textstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.810 0.055 0.010 0.030],HorizontalAlignment,leftstr, ...
      String,dashstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'ssfrctrl2',Visible,offstr, ...
      Position,[0.825 0.070-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(2,6);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Frequency spectrum plot upper limit');

    uicontrol(figNumber,Style,pushbuttonstr,Tag,ssfrmlabbtnTag,Visible,offstr, ...
      Position,[0.900 0.070-editHt2 0.090 editHt],String,resetstr, ...
      CallBack,'ringdown(''rguimgr(2,7);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Reset frequency spectrum plot limits');

    uicontrol(figNumber,Style,framestr,Tag,adfrmlabbtnTag,Visible,offstr, ...
      Position,[0.000 0.460 0.610 0.540],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,adfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.960 0.590 0.030],HorizontalAlignment,centerstr, ...
      String,'Advanced Prony Analysis Options (* = Default)', ...
      BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,adfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.905 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Linear Prediction Method:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,popupmenustr,Tag,lpmctrlTag,Visible,offstr, ...
      Position,[0.240 0.900 0.360 0.040], ...
      String,'Correlation|Pre-Windowed|*Covariance|Post-Windowed', ...
      Value,3,CallBack,'ringdown(''rguimgr(6,1);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,adfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.845 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Forward/Backward Logic:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,popupmenustr,Tag,fbctrlTag,Visible,offstr, ...
      Position,[0.240 0.840 0.360 0.040],String,'*Forward|Forward-Backward|Backward', ...
      CallBack,'ringdown(''rguimgr(6,2);'');',BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,adfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.785 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Linear Prediction Algorithm:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,popupmenustr,Tag,lpactrlTag,Visible,offstr, ...
      Position,[0.240 0.780 0.360 0.040],String,['*Singular Value Decomposition|' ...
      'QR Factorization|Total Least Squares'],BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,adfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.725 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Linear Prediction Order:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,radiobuttonstr,Tag,lpoctrl1Tag,Visible,offstr, ...
      Position,[0.240 0.720 0.175 0.040],HorizontalAlignment,leftstr, ...
      String,autostr,Value,1,CallBack,'ringdown(''rguimgr(6,3);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,'lpoind',Visible,offstr, ...
      Position,[0.340 0.725 0.070 0.030],HorizontalAlignment,centerstr, ...
      BackgroundColor,indBackgroundColor);

    uicontrol(figNumber,Style,radiobuttonstr,Tag,lpoctrl2Tag,Visible,offstr, ...
      Position,[0.425 0.720 0.175 0.040],HorizontalAlignment,leftstr, ...
      String,ststr,Value,0,CallBack,'ringdown(''rguimgr(6,4);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'lpoctrl',Visible,offstr, ...
      Position,[0.525 0.740-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(6,5);'');',BackgroundColor,edtBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,adfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.665 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Upper Trim Frequency (Hz):',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,radiobuttonstr,Tag,ftrhctrl1Tag,Visible,offstr, ...
      Position,[0.240 0.660 0.175 0.040],HorizontalAlignment,leftstr, ...
      String,autostr,Value,1,CallBack,'ringdown(''rguimgr(6,6);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,ftrhindTag,Visible,offstr, ...
      Position,[0.340 0.665 0.070 0.030],HorizontalAlignment,centerstr, ...
      String,ftrhs,BackgroundColor,indBackgroundColor);

    uicontrol(figNumber,Style,radiobuttonstr,Tag,ftrhctrl2Tag,Visible,offstr, ...
      Position,[0.425 0.660 0.175 0.040],HorizontalAlignment,leftstr, ...
      String,ststr,Value,0,CallBack,'ringdown(''rguimgr(6,7);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,ftrhctrlTag,Visible,offstr, ...
      Position,[0.525 0.680-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      String,ftrhs,CallBack,'ringdown(''rguimgr(6,8);'');', ...
      BackgroundColor,edtBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,adfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.605 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Lower Trim Frequency (Hz):',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,radiobuttonstr,Tag,ftrlctrl1Tag,Visible,offstr, ...
      Position,[0.240 0.600 0.175 0.040],HorizontalAlignment,leftstr, ...
      String,autostr,Value,1,CallBack,'ringdown(''rguimgr(6,9);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,'ftrlind',Visible,offstr, ...
      Position,[0.340 0.605 0.070 0.030],HorizontalAlignment,centerstr, ...
      String,zerstr,BackgroundColor,indBackgroundColor);

    uicontrol(figNumber,Style,radiobuttonstr,Tag,ftrlctrl2Tag,Visible,offstr, ...
      Position,[0.425 0.600 0.175 0.040],HorizontalAlignment,leftstr, ...
      String,ststr,Value,0,CallBack,'ringdown(''rguimgr(6,10);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,ftrlctrlTag,Visible,offstr, ...
      Position,[0.525 0.620-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      String,zerstr,CallBack,'ringdown(''rguimgr(6,11);'');', ...
      BackgroundColor,edtBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,adfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.545 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Residue Trim Level:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,radiobuttonstr,Tag,trrectrl1Tag,Visible,offstr, ...
      Position,[0.240 0.540 0.175 0.040],HorizontalAlignment,leftstr, ...
      String,autostr,Value,1,CallBack,'ringdown(''rguimgr(6,12);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,'trreind',Visible,offstr, ...
      Position,[0.340 0.545 0.070 0.030],HorizontalAlignment,centerstr, ...
      String,trres,BackgroundColor,indBackgroundColor);

    uicontrol(figNumber,Style,radiobuttonstr,Tag,trrectrl2Tag,Visible,offstr, ...
      Position,[0.425 0.540 0.175 0.040],HorizontalAlignment,leftstr, ...
      String,ststr,Value,0,CallBack,'ringdown(''rguimgr(6,13);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,trrectrlTag,Visible,offstr, ...
      Position,[0.525 0.560-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      String,trres,CallBack,'ringdown(''rguimgr(6,14);'');', ...
      BackgroundColor,edtBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,adfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.485 0.230 0.030],HorizontalAlignment,leftstr, ...
      String,'Mode Ordering Algorithm:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,popupmenustr,Tag,ordctrlTag,Visible,offstr, ...
      Position,[0.240 0.480 0.360 0.040],String,['Akaike Final Prediction Error|' ...
      '*Mode Energy'],Value,2,BackgroundColor,btnBackgroundColor);

    drawnow; fprintf(1,'.')

  %===============================================
  % Create the results screen.
  %===============================================
  % The mode table, and results screen plot axes.

    mtblHndl=axes(Tag,mtblTag,Visible,offstr, ...
      Position,[0.005 0.350 0.585 0.535],XLim,[0 1],YLim,[0 1], ...
      XTick,[],YTick,[],XColor,mtbForegroundColor,YColor,mtbForegroundColor, ...
      Color,mtbBackgroundColor,'ColorOrder',mtbForegroundColor, ...
      'LineStyleOrder',dashstr,DTextHAlign,centerstr, ...
      'DefaultTextColor',mtbForegroundColor,'DefaultLineColor',mtbForegroundColor);

    vcells=9; nnrow=vcells+4; cellHt=1/nnrow;
    h=line([0 1],[cellHt; cellHt]*[1:nnrow-3],Tag,mtblTag,Visible,offstr);
    set(h(1),LineWidth,5*get(h(1),LineWidth));
    line([0.5 0.5],[0 cellHt],Tag,mtblTag,Visible,offstr);
    line([0.100; 0.325; 0.550; 0.775]*[1 1],[cellHt 1],Tag,mtblTag,Visible,offstr);
    ffindHndl=text(0.25,0.5*cellHt,spacestr,Tag,ffindTag,Visible,offstr);
    text(0.75,0.5*cellHt,spacestr,Tag,'snrind',Visible,offstr);
    textxPos=ones(nnrow-1,1)*[0.0500 0.2125 0.4375 0.6625 0.8875];
    textyPos=(0.5+[1:nnrow-1])/nnrow; h=zeros(nnrow-1,5);
    for ii=1:5; h(:,ii)=text(textxPos(:,ii),textyPos,spacestr); end
    set(h(nnrow-1,1),String,'Mode Type',Visible,offstr); set(mtblHndl,UserData,h);

    axes(bkaxesHndl);
    text(0.830,0.980,trtitlestr,Tag,rstraxesTag,Visible,offstr,UserData,titlestr);
    text(0,0,trxlablstr,Tag,rstraxesTag,Visible,offstr,UserData,xlablstr);
    text(0,0,frtitl2str,Tag,rsfraxs1Tag,Visible,offstr,UserData,titlestr);
    text(0,0,frmylabstr,Tag,rsfraxs1Tag,Visible,offstr,Rotation,90,UserData,ylablstr);
    text(0,0,frpylabstr,Tag,rsfraxs2Tag,Visible,offstr,Rotation,90,UserData,ylablstr);
    text(0,0,frxlablstr,Tag,rsfraxs2Tag,Visible,offstr,UserData,xlablstr);
    text(0,0,pztitlestr,Tag,rspzaxesTag,Visible,offstr,UserData,titlestr);
    text(0.830,0.020,'Real Axis',Tag,rspzaxesTag,Visible,offstr,UserData,xlablstr);
    text(0,0,'Imaginary Axis',Tag,rspzaxesTag,Visible,offstr,Rotation,90,UserData,ylablstr);

    axes(Tag,rstraxesTag,Visible,offstr,Position,[0 0 1 1]);
    axes(Tag,rsfraxs1Tag,Visible,offstr,Position,[0 0 1 1]);
    axes(Tag,rsfraxs2Tag,Visible,offstr,Position,[0 0 1 1]);
    axes(Tag,rspzaxesTag,Visible,offstr,Position,[0 0 1 1]);

  %===============================================
  % The results screen uicontrols.

    uicontrol(figNumber,Style,framestr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.000 0.890 0.590 0.110],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,popupmenustr,Tag,'rsoutctrl',Visible,offstr, ...
      Position,[0.010 0.950 0.140 0.040],String,spacestr, ...
      CallBack,'ringdown(''rguimgr(5,2);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Select signal for which to display model');

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.160 0.955 0.040 0.030],HorizontalAlignment,leftstr, ...
      String,titlstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'rstitctrl',Visible,offstr, ...
      Position,[0.210 0.970-editHt2 0.270 editHt],HorizontalAlignment,leftstr, ...
      CallBack,'ringdown(''rguimgr(11,2);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Signal title (editable)');

    uicontrol(figNumber,Style,popupmenustr,Tag,'mtpgctrl',Visible,offstr, ...
      Position,[0.490 0.950 0.095 0.040],String,spacestr, ...
      CallBack,'ringdown(''rguimgr(5,3);'');',BackgroundColor,btnBackgroundColor);

% Added by Huang, Zhenyu (Henry) for pole sorting, 03/19/03
    uicontrol(figNumber,Style,popupmenustr,Tag,sortctrlTag,Visible,offstr, ...
      Position,[0.400 0.905 0.185 0.040],String,['Sort by Freqency, real modes ' ...
      'first|Sort by Damping Ratio, real modes first|Sort by Relative Energy|Sort by Mode Type' ...
      '|Sort by Relative Amplitude'], ...
      CallBack,'ringdown(''rguimgr(18,1);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Select mode sorting criterion');
  
    uicontrol(figNumber,Style,textstr,Tag,rsFLIM1labTag,Visible,offstr, ...
      Position,[0.020 0.925 0.08 0.015],HorizontalAlignment,leftstr, ...
      String,'Low freq limit:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,rsFLIM1ctrlTag,Visible,offstr, ...
      Position,[0.078 0.945-editHt2 0.040 editHt/2],HorizontalAlignment,centerstr, ...
      String,onestr,Enable,fltenbl,CallBack,'ringdown(''rguimgr(18,2);'');', ...
      BackgroundColor,edtBackgroundColor,ToolTipString,'Low freq limit');
  
    uicontrol(figNumber,Style,textstr,Tag,rsFLIM2labTag,Visible,offstr, ...
      Position,[0.140 0.925 0.08 0.015],HorizontalAlignment,leftstr, ...
      String,'High freq limit:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,rsFLIM2ctrlTag,Visible,offstr, ...
      Position,[0.200 0.945-editHt2 0.040 editHt/2],HorizontalAlignment,centerstr, ...
      String,onestr,Enable,fltenbl,CallBack,'ringdown(''rguimgr(18,3);'');', ...
      BackgroundColor,edtBackgroundColor,ToolTipString,'High freq limit');
  
    uicontrol(figNumber,Style,textstr,Tag,rsDLIM1labTag,Visible,offstr, ...
      Position,[0.260 0.925 0.08 0.015],HorizontalAlignment,leftstr, ...
      String,'Damping ratio limit:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,rsDLIM1ctrlTag,Visible,offstr, ...
      Position,[0.337 0.945-editHt2 0.040 editHt/2],HorizontalAlignment,centerstr, ...
      String,onestr,Enable,fltenbl,CallBack,'ringdown(''rguimgr(18,4);'');', ...
      BackgroundColor,edtBackgroundColor,ToolTipString,'Damping ratio limit');
  
% End - Added by Huang, Zhenyu (Henry) for pole sorting, 03/19/03

    ctrlstr=['Frequency|Damping|Damp. Ratio|Amplitude|Phase|Rel. Amp.|' ...
      'TF Amplitude|TF Phase|TF Rel. Amp.|Akaike FPE|Rel. Energy'];

    uicontrol(figNumber,Style,popupmenustr,Tag,'mtcol2ctrl',Visible,offstr, ...
      Position,[0.070 0.875 0.125 0.040],String,ctrlstr, ...
      CallBack,'ringdown(''rguimgr(5,4);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Parameters to display in this column');

    uicontrol(figNumber,Style,popupmenustr,Tag,'mtcol3ctrl',Visible,offstr, ...
      Position,[0.200 0.875 0.125 0.040],String,ctrlstr, ...
      CallBack,'ringdown(''rguimgr(5,5);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Parameters to display in this column');

    uicontrol(figNumber,Style,popupmenustr,Tag,'mtcol4ctrl',Visible,offstr, ...
      Position,[0.330 0.875 0.125 0.040],String,ctrlstr, ...
      CallBack,'ringdown(''rguimgr(5,6);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Parameters to display in this column');

    uicontrol(figNumber,Style,popupmenustr,Tag,'mtcol5ctrl',Visible,offstr, ...
      Position,[0.460 0.875 0.125 0.040],String,ctrlstr, ...
      CallBack,'ringdown(''rguimgr(5,7);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Parameters to display in this column');

%    uicontrol(figNumber,Style,framestr,Tag,mtselctrlTag,Visible,offstr, ...
%      Position,[0.000 0.890 0.590 0.110],BackgroundColor,frmBackgroundColor);

%    uicontrol(figNumber,Style,textstr,Tag,mtselctrlTag,Visible,offstr, ...
%      Position,[0.010 0.960 0.575 0.030],HorizontalAlignment,centerstr, ...
%      String,'Mode Select Options',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,pushbuttonstr,Tag,mtselctrlTag,Visible,offstr, ...
      Position,[0.005 0.775 0.060 0.020],String,'Select all', ...
      CallBack,'ringdown(''rguimgr(3,2)'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Select all modes on the current page in the mode table');   % select all modes in mode table. modified by Henry, 06/05/03

%    uicontrol(figNumber,Style,pushbuttonstr,Tag,mtselctrlTag,Visible,offstr, ...
%      Position,[0.010 0.900 0.190 0.040],String,'Select', ...
%      CallBack,'ringdown(''rguimgr(3,2)'');',BackgroundColor,btnBackgroundColor);

%    uicontrol(figNumber,Style,pushbuttonstr,Tag,mtselctrlTag,Visible,offstr, ...
%      Position,[0.205 0.900 0.190 0.040],String,'Deselect', ...
%      CallBack,'ringdown(''rguimgr(3,3)'');',BackgroundColor,btnBackgroundColor);

%    uicontrol(figNumber,Style,pushbuttonstr,Tag,mtselctrlTag,Visible,offstr, ...
%      Position,[0.400 0.900 0.185 0.040],String,cancelstr, ...
%      CallBack,'ringdown(''rguimgr(3,4);'');',BackgroundColor,btnBackgroundColor);

    uicontrol(figNumber,Style,framestr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.000 0.255 0.390 0.090],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.305 0.375 0.030],HorizontalAlignment,centerstr, ...
      String,postr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,togglebuttonstr,Tag,'rsfrctrl',Visible,offstr, ...
      Position,[0.010 0.265 0.120 0.030],String,'Frequency', ...
      CallBack,'ringdown(''rguimgr(10,2);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Toggles frequency spectrum/response plots');

    uicontrol(figNumber,Style,togglebuttonstr,Tag,'rspzctrl',Visible,offstr, ...
      Position,[0.135 0.265 0.125 0.030],String,'Pole-Zero', ...
      CallBack,'ringdown(''rguimgr(10,3);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Toggles pole-zero plot');

    uicontrol(figNumber,Style,pushbuttonstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.265 0.265 0.120 0.030],String,'Akaike', ...
      CallBack,'ringdown(''rguimgr(12,1);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Create Akaike FPE plot');

    uicontrol(figNumber,Style,framestr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.000 0.000 0.390 0.250],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.210 0.375 0.030],HorizontalAlignment,centerstr, ...
      String,prlabel1str,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.010 0.375 0.030],HorizontalAlignment,leftstr, ...
      String,prlabel2str,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.170 0.110 0.030],HorizontalAlignment,leftstr, ...
      String,trctrllablstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'rstrctrl1',Visible,offstr, ...
      Position,[0.120 0.185-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(4,4);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Time response plot lower limit');

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.200 0.170 0.010 0.030],HorizontalAlignment,leftstr, ...
      String,dashstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'rstrctrl2',Visible,offstr, ...
      Position,[0.220 0.185-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(4,5);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Time response plot upper limit');

    uicontrol(figNumber,Style,pushbuttonstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.295 0.185-editHt2 0.090 editHt],String,resetstr, ...
      CallBack,'ringdown(''rguimgr(4,6);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Reset time response plot limits');

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.130 0.110 0.030],HorizontalAlignment,leftstr, ...
      String,frctrllablstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'rsfrctrl1',Visible,offstr, ...
      Position,[0.120 0.145-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(4,12);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Frequency response plot lower limit');

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.200 0.130 0.010 0.030],HorizontalAlignment,leftstr, ...
      String,dashstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'rsfrctrl2',Visible,offstr, ...
      Position,[0.220 0.145-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(4,13);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Frequency response plot upper limit');

    uicontrol(figNumber,Style,pushbuttonstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.295 0.145-editHt2 0.090 editHt],String,resetstr, ...
      CallBack,'ringdown(''rguimgr(4,14);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Reset frequency response plot limits');

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.090 0.110 0.030],HorizontalAlignment,leftstr, ...
      String,'Pole-Zero X:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'rspzxctrl1',Visible,offstr, ...
      Position,[0.120 0.105-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(4,16);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Pole-zero plot lower horizontal limit');

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.200 0.090 0.010 0.030],HorizontalAlignment,leftstr, ...
      String,dashstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'rspzxctrl2',Visible,offstr, ...
      Position,[0.220 0.105-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(4,17);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Pole-zero plot upper horizontal limit');

    uicontrol(figNumber,Style,pushbuttonstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.295 0.105-editHt2 0.090 editHt],String,resetstr, ...
      CallBack,'ringdown(''rguimgr(4,18);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Reset pole-zero plot horizontal limits');

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.010 0.050 0.110 0.030],HorizontalAlignment,leftstr, ...
      String,'Pole-Zero Y:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'rspzyctrl1',Visible,offstr, ...
      Position,[0.120 0.065-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      CallBack,'ringdown(''rguimgr(4,19);'');',BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Pole-zero plot lower vertical limit');

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.200 0.050 0.010 0.030],HorizontalAlignment,leftstr, ...
      String,dashstr,BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,'rspzyctrl2',Visible,offstr, ...
      Position,[0.220 0.065-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      UserData,numformat,CallBack,'ringdown(''rguimgr(4,20);'');', ...
      BackgroundColor,edtBackgroundColor, ...
      ToolTipString,'Pole-zero plot upper vertical limit');

    uicontrol(figNumber,Style,pushbuttonstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.295 0.065-editHt2 0.090 editHt],String,resetstr, ...
      CallBack,'ringdown(''rguimgr(4,21);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Reset pole-zero plot vertical limits');

    uicontrol(figNumber,Style,framestr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.395 0.000 0.195 0.345],BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.405 0.305 0.180 0.030],HorizontalAlignment,centerstr, ...
      String,'Other Options',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,togglebuttonstr,Tag,rsfiltctrlTag,Visible,offstr, ...
      Position,[0.405 0.265 0.180 0.030],String,sfiltstr,Enable,fltenbl, ...
      CallBack,'ringdown(''rguimgr(4,7);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Apply Sinc-Hamming FIR filter to all signals');

    uicontrol(figNumber,Style,textstr,Tag,rsfrmlabbtnTag,Visible,offstr, ...
      Position,[0.405 0.225 0.110 0.030],HorizontalAlignment,leftstr, ...
      String,'Filter Cutoff:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNumber,Style,editstr,Tag,rscfctrlTag,Visible,offstr, ...
      Position,[0.515 0.240-editHt2 0.070 editHt],HorizontalAlignment,centerstr, ...
      String,onestr,Enable,fltenbl,CallBack,'ringdown(''rguimgr(4,8);'');', ...
      BackgroundColor,edtBackgroundColor,ToolTipString,'Filter cutoff frequency');

    uicontrol(figNumber,Style,togglebuttonstr,Tag,rsdectrlTag,Visible,offstr, ...
      Position,[0.405 0.160 0.180 0.030],String,'Decimate', ...
      CallBack,'ringdown(''rguimgr(4,9);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Decimate time-response data for Fourier analysis');

    uicontrol(figNumber,Style,popupmenustr,Tag,'rsdtmodctrl',Visible,offstr, ...
      Position,[0.405 0.110 0.180 0.040],String,['No Detrend|Remove initial ' ...
      'value|Remove mean value|Remove final value|Remove ramp'], ...
      CallBack,'ringdown(''rguimgr(4,10);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Select trend removal method for Fourier analysis');

    uicontrol(figNumber,Style,popupmenustr,Tag,'rsfillctrl',Visible,offstr, ...
      Position,[0.405 0.060 0.180 0.040],String,fillstr, ...
      CallBack,'ringdown(''rguimgr(4,15);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Fourier analysis zero pad options');

    uicontrol(figNumber,Style,popupmenustr,Tag,'rswinctrl',Visible,offstr, ...
      Position,[0.405 0.010 0.180 0.040],String,winstr, ...
      CallBack,'ringdown(''rguimgr(4,15);'');',BackgroundColor,btnBackgroundColor, ...
      ToolTipString,'Fourier analysis windowing options');

    axes(bkaxesHndl);
    text(0.5,0.5,'Performing Prony Analysis',Tag,'paind',Visible,offstr);

    drawnow; fprintf(1,'.')

%============================================================================
% If a Ringdown GUI handle was entered, clear the figure and find the 
% handles to the setup screen objects.
  else

    newfig=0;

    set(findobj(figNumber,OType,'line'),Visible,offstr);
    set(findobj(figNumber,OType,textstr),Visible,offstr);
    set(findobj(figNumber,OType,axesstr),Visible,offstr);
    set(findobj(figNumber,OType,'uicontrol'),Visible,offstr);
    delete(findobj(figNumber,Tag,outsubmenuTag));
    delete(findobj(figNumber,Tag,polsubmenuTag));
    outmenuHndl=findobj(figNumber,Tag,outmenuTag);
    polmenuHndl=findobj(figNumber,Tag,polmenuTag);
    set(findobj(figNumber,Tag,expmenuTag),Enable,offstr);
    set(findobj(figNumber,Tag,ssmenuTag),Checked,onstr);
    set(findobj(figNumber,Tag,rsmenuTag),Checked,offstr,Enable,offstr);
    rguiprefs=get(findobj(figNumber,Tag,prfmenuTag),UserData);
    ffindHndl=findobj(figNumber,Tag,ffindTag); drawnow;

    set(outmenuHndl,UserData,outdat);
    set(polmenuHndl,UserData,knwmod);
%    set(findobj(figNumber,Tag,ssoutctrlTag),String,output1str,Value,1,UserData,[1 1]);
    set(findobj(figNumber,Tag,ssoutctrlTag),String,output1str,Value,2,UserData,[2 2]);      % Set Value to 2. Henry, 04/04/03
    set(findobj(figNumber,Tag,ssfrctrlTag),Value,0);
%    set(findobj(figNumber,Tag,msigctrlTag),Value,0);       % deleted by Henry, 04/23/03
    set(findobj(figNumber,Tag,ssfiltctrlTag),Value,0,Enable,fltenbl);
    set(findobj(figNumber,Tag,sscfctrlTag),String,onestr,Enable,fltenbl);
    set(findobj(figNumber,Tag,tsind1Tag),String,tsteps);
    set(findobj(figNumber,Tag,ssdectrlTag),String,onestr,UserData,setupcon2);
    set(findobj(figNumber,Tag,tsind2Tag),String,tsteps);
    set(findobj(figNumber,Tag,nqindTag),String,nyqs);
    set(findobj(figNumber,Tag,stctrlTag),String,zerstr,UserData,setupcon1);
    set(findobj(figNumber,Tag,scctrlTag),Value,0);
    set(findobj(figNumber,Tag,fcctrlTag),Value,1);
    set(findobj(figNumber,Tag,rrctrlTag),Value,0);
    set(findobj(figNumber,Tag,ssfillctrlTag),Value,2);
    set(findobj(figNumber,Tag,sswinctrlTag),Value,2);
    set(findobj(figNumber,Tag,sstrctrl1Tag),UserData,pltctrls);
    set(findobj(figNumber,Tag,lpmctrlTag),Value,3);
    set(findobj(figNumber,Tag,fbctrlTag),Value,1);
    set(findobj(figNumber,Tag,lpactrlTag),Value,1);
    set(findobj(figNumber,Tag,lpoctrl1Tag),Value,1);
    set(findobj(figNumber,Tag,lpoctrl2Tag),Value,0);
    set(findobj(figNumber,Tag,ftrhctrl1Tag),Value,1);
    set(findobj(figNumber,Tag,ftrhindTag),String,ftrhs);
    set(findobj(figNumber,Tag,ftrhctrl2Tag),Value,0);
    set(findobj(figNumber,Tag,ftrhctrlTag),String,ftrhs);
    set(findobj(figNumber,Tag,ftrlctrl1Tag),Value,1);
    set(findobj(figNumber,Tag,ftrlctrl2Tag),Value,0);
    set(findobj(figNumber,Tag,ftrlctrlTag),String,zerstr);
    set(findobj(figNumber,Tag,trrectrl1Tag),Value,1);
    set(findobj(figNumber,Tag,trrectrl2Tag),Value,0);
    set(findobj(figNumber,Tag,trrectrlTag),String,trres);
    set(findobj(figNumber,Tag,ordctrlTag),Value,2);
    set(findobj(figNumber,Tag,rsfiltctrlTag),Enable,fltenbl);
    set(findobj(figNumber,Tag,rscfctrlTag),Enable,fltenbl);
    set(findobj(figNumber,Tag,ssfraxs1Tag,UserData,titlestr),Position,frtitlPos);
    set(findobj(figNumber,Tag,ssfraxs1Tag,UserData,ylablstr),Position,frylb1Pos);
    set(findobj(figNumber,Tag,ssfraxs2Tag,UserData,ylablstr),Position,frylb2Pos);
    set(findobj(figNumber,Tag,ssfraxs1Tag,OType,axesstr),Position,fraxs1Pos);
    set(findobj(figNumber,Tag,ssfraxs2Tag,OType,axesstr),Position,fraxs2Pos);

  end

%============================================================================
% Create the output submenus.  Store the outdat matrix.

  menulen=30;

  h = uimenu(outmenuHndl,Tag,sprintf('%s%d',outsubmenuTag,0),Label, 'All signals', ...
      UserData,'All outputs',CallBack,'ringdown(''rguimgr(1,3);'');');
  
  if sigcon<=menulen; parentHndl=outmenuHndl; else; parentHndl=[]; end
  nnsubmenus=1;

  for ii=1:sigcon
    if isempty(titles)
      outtitle='';
    else
      outtitle=deblank(strjust(titles(ii,:),leftstr));
    end

    if isempty(outtitle)
      menustr=int2str(ii);
    else
      menustr=[int2str(ii) ':  ' outtitle];
    end

    if isempty(parentHndl)
      h=sprintf('Signals %d - %d',ii,min(sigcon,ii+menulen-1));
      parentHndl=uimenu(outmenuHndl,Label,h);
    end

    h=uimenu(parentHndl,Tag,sprintf('%s%d',outsubmenuTag,ii),Label,menustr, ...
      UserData,outtitle,CallBack,'ringdown(''rguimgr(1,3);'');');

    if ii==1; set(h,Checked,onstr); end

    nnsubmenus=nnsubmenus+1;
    if nnsubmenus>menulen; nnsubmenus=1; parentHndl=[]; end

  end

%===============================================
% Create the known pole submenus.  Store the known modes.

  qcon=size(knwmod,1);

  if qcon>0
    uimenu(polmenuHndl,Tag,polsubmenuTag,Label,'All poles', ...
      CallBack,'ringdown(''rguimgr(1,4);'');');                 % Add "select all" function for pole submenu. Henry, 06/02/03

    h=[knwmod/2/pi knwmod(:,1)./sqrt(knwmod(:,1).^2+knwmod(:,2).^2)];
    for ii=1:qcon
      if knwmod(ii,2)<1e-8
        menustr=sprintf('% 12.4e     % 12.4e        -----',h(ii,2),h(ii,1));
      else
        menustr=sprintf('% 12.4e     % 12.4e     % 12.4e',h(ii,2),h(ii,1),h(ii,3));
      end
      uimenu(polmenuHndl,Tag,polsubmenuTag,Label,menustr, ...
        CallBack,'ringdown(''rguimgr(1,4);'');');
    end
    set(polmenuHndl,Enable,onstr);
  else
    set(polmenuHndl,Enable,offstr);
  end

%===============================================
% Draw the input pulse waveform.
% Also enable or disable the feed-forward term indicator.

  if ninputs
    t=[1; 1]*inpulses(:,1)'; tim=[0; 0; t(:)];
    t=[1; 1]*inpulses(:,2)'; inp=[0; t(:); 0];
    axes(findobj(figNumber,Tag,inpaxesTag,OType,axesstr));
    plot(tim,inp,Tag,inpaxesTag,Visible,offstr,Color,rguiprefs(4,:));
    set(gca,Tag,inpaxesTag,'XTickLabel',[]);
    h='ringdown(''rguimgr(4,11);'');';
  else
    h='';
  end

  set(ffindHndl,'ButtonDownFcn',h);

%===============================================
% Final tasks.

  rguimgr(7,1,figNumber);
  if newfig
    set(figNumber,'DefaultAxesHandleVisibility',CallBack, ...
      'DefaultLineHandleVisibility',CallBack, ...
      'DefaultUimenuHandleVisibility',CallBack);
    set(findobj(figNumber),'HandleVisibility',CallBack); fprintf(1,' done.\n\n');
  end
  set(figNumber,Pointer,'arrow');

function rguitit(action,fntname,fntsize);

% RGUITIT:  Display the title screen for the BPA/PNNL Ringdown Analysis Tool.

% By Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date : October 1996.

%  error(nargchk(1,3,nargin));

%===============================================
% Revision number and datestamp
  verstr='3.1.8';
  datestamp='September 30, 2013';

%===============================================
% Strings with object property names and values.

  Extent  ='Extent';
  FontSize='FontSize';
  Position='Position';
  Units   ='Units';
  Visible ='Visible';

  normstr ='normalized';
  offstr  ='off';

%===============================================
% Platform dependent font size and figure position.

  if action==2
    figNumber=gcf; fntname=get(figNumber,'DefaultAxesFontName');
    fntsize=get(figNumber,'DefaultAxesFontSize'); h=sprintf('RGUIFIG%d',figNumber);
  else
    h='';
  end

  if strcmp(computer,'PCWIN')
    fntsizel=fntsize+4; fntsizell=fntsize+8;
  else
    fntsizel=fntsize+5; fntsizell=fntsize+10;
  end

%===============================================
% Create the figure and text objects.

  figNmbr=figure('Tag',h,'NumberTitle',offstr, ...
    'Name','About BPA/PNNL Ringdown Analysis Tool','MenuBar','none', ...
    'Resize',offstr,Units,normstr,Position,[0.000 0.000 1.000 1.000], ...
    Visible,offstr,'Color',[0 0 0]);

  axes(Visible,offstr,Units,normstr,Position,[0.000 0.000 1.000 1.000], ...
    'XLim',[0 1],'YLim',[0 1],'DefaultTextColor',[1.0 1.0 1.0], ...
    'DefaultTextFontName',fntname,'DefaultTextFontSize',fntsize, ...
    'DefaultTextHorizontalAlignment','center','DefaultTextVerticalAlignment','middle');

  h2=text(0.500,0.850,'BPA/PNNL Dynamic System Identification Toolbox',FontSize,fntsizell);
  drawnow; h=get(h2,Extent); figWidHt=min(h(3)/0.8,1)*[1 1];
  set(figNmbr,Position,[(1-figWidHt)/2 figWidHt]);
  text(0.500,0.750,['Ringdown Analysis Tool, Version ' verstr],FontSize,fntsizel);
  text(0.500,0.650,datestamp);
  text(0.500,0.500,'Copyright (c) 1995-2013 Battelle Memorial Institute.');
  h=cell(3,1);
  h{1}='The Government retains a paid-up nonexclusive, irrevocable worldwide license to';
  h{2}='reproduce, prepare derivative works, perform publicly and display publicly by or for';
  h{3}='the Government, including the right to distribute to other Government contractors.';
  h2=text(0.100,0.200,h,'HorizontalAlignment','left'); drawnow;
  h=get(h2,Extent); set(h2,Position,[0.5-h(3)/2 0.200]);

  if action==2
    uicontrol(figNmbr,'Style','pushbutton',Units,normstr, ...
      Position,[0.400 0.020 0.200 0.080],'String','OK', ...
     'CallBack','delete(gcf);','BackgroundColor',[0.7 0.7 0.7]);
  end

  drawnow; set(figNmbr,Visible,'on'); warning warnstate;
  if action==1; pause(3); delete(figNmbr); end
