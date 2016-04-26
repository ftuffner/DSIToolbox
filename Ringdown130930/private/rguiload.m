function rguiload(figNumber,action1,action2);

% RGUILOAD:  Subroutine to handle data import operations for the
%            BPA/PNNL Ringdown Analysis Tool.
%
% This is a helper function for the Ringdown Analysis Tool.  It is not
% normally used directly from the MATLAB command prompt.

% By Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date : January 1997
%
% Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% Print RCSID stamp and copyright
  if nargin==1 & ischar(figNumber) & strcmp(figNumber,'rcsid')
    fprintf(1,['\n$Id$\n\n' ...
      'Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government\n' ...
      'retains a paid-up nonexclusive, irrevocable worldwide license to\n' ...
      'reproduce, prepare derivative works, perform publicly and display\n' ...
      'publicly by or for the Government, including the right to distribute\n' ...
      'to other Government contractors.\n\n' ...
      'Date of last source code modification:  02/04/2008 (JMJ)\n\n']);
    return
  end

% Check input arguments.
  error(nargchk(2,3,nargin));

% Strings with property names.
  String     ='String';
  Tag        ='Tag';
  UserData   ='UserData';
  Visible    ='Visible';

  basestr    ='base';
  importstr  ='Import';
  offstr     ='off';
  onstr      ='on';
  nostr      ='No';

% Object tags.
  dectrlTag  ='dectrl';
  filctrlTag ='filctrl';
  inpctrlTag ='inpctrl';
  nscnindTag ='nscnind';
  nsigindTag ='nsigind';
  polctrlTag ='polctrl';
  ppsmctrlTag='ppsmctrl';
  psigctrlTag='psigctrl';
  sigctrlTag ='sigctrl';
  titctrlTag ='titctrl';
  wksctrlTag ='wksctrl';

%============================================================================
% Confirm that the user really wants to import new data.  Create the
% Data Import figure if so.
  if action1==1

    if ~isempty(figNumber)
      eval(['q=questdlg(''Replace current data and results?'','''',' ...
        '''Yes'',''No'',''Yes'');'],'return');
      if exist('q')~=1; return; end; if strcmp(q,nostr); return; end
    end

  % Strings with property names and values for initialization.
    BackgroundColor    ='BackgroundColor';
    CallBack           ='CallBack';
    DUictrlFontName    ='DefaultUicontrolFontName';
    DUictrlFontSize    ='DefaultUicontrolFontSize';
    HorizontalAlignment='HorizontalAlignment';
    Position           ='Position';
    Style              ='Style';
    ToolTipString      ='ToolTipString';
    Units              ='Units';

    cancelstr          ='Cancel';
    centerstr          ='center';
    delstr             ='delete(gcf);';
    editstr            ='edit';
    framestr           ='frame';
    leftstr            ='left';
    pixelstr           ='pixels';
    pushbuttonstr      ='pushbutton';
    textstr            ='text';

    wksvarbtnstr       ='Browse Workspace';
    wksvarctrlstr      ='Workspace Variable';

  %======================================
  % Set the figure size and position.  Set colors.
    if isempty(figNumber)
		load rguipref.mat;
      % rguipref('rguifcn',6);
    else
      oldUnits=get(figNumber,Units); set(figNumber,Units,pixelstr);
      figPos=get(figNumber,Position); set(figNumber,Units,oldUnits);
      uictrlFontName=get(figNumber,'DefaultUicontrolFontName');
      uictrlFontSize=get(figNumber,'DefaultUicontrolFontSize');
      h=get(findobj(figNumber,Tag,'dsctrl'),Position); editHt=h(4);
    end

    oldUnits=get(0,Units); set(0,Units,pixelstr);
    screensize=get(0,'ScreenSize'); set(0,Units,oldUnits);

    figWid=min(0.070*figPos(3)/0.200,screensize(3));
    figHt=min(editHt*figPos(4)/0.080,screensize(4));

    figPos=floor([(screensize(3:4)-[figWid figHt])/2 figWid figHt]);

    btnBackgroundColor=[0.7 0.7 0.7];
    edtBackgroundColor=[1.0 1.0 1.0];
    frmBackgroundColor=[0.5 0.5 0.5];
    indBackgroundColor=[0.6 0.6 0.6];

  %======================================
  % Create the figure and controls.

    figNmbr=figure(Tag,sprintf('RGUIFIG%d',figNumber),'NumberTitle',offstr, ...
      'Name','Import Data','MenuBar','none','Resize',offstr,Units,pixelstr, ...
       Position,figPos,UserData,figNumber,Visible,offstr,'WindowStyle','modal', ...
      'DefaultUicontrolUnits','normalized','DefaultUicontrolInterruptible',offstr, ...
       DUictrlFontName,uictrlFontName,DUictrlFontSize,uictrlFontSize, ...
      'DefaultUicontrolForegroundColor','black');

    uicontrol(figNmbr,Style,framestr,Position,[0.000 0.000 1.000 1.000], ...
      BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Tag,wksctrlTag, ...
      Position,[0.030 0.910 0.940 0.060],HorizontalAlignment,centerstr, ...
      String,'Workspace Variable Names',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Tag,wksctrlTag, ...
      Position,[0.030 0.760 0.490 0.060],HorizontalAlignment,leftstr, ...
      String,'Signal Data Matrix:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,editstr,Tag,sigctrlTag, ...
      Position,[0.540 0.750 0.310 0.080],HorizontalAlignment,centerstr, ...
      BackgroundColor,edtBackgroundColor,ToolTipString,wksvarctrlstr);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,wksctrlTag, ...
      Position,[0.890 0.750 0.090 0.080],String,'', ...
      CallBack,'ringdown(''rguiload([],7,1);'');', ...
      BackgroundColor,btnBackgroundColor,ToolTipString,wksvarbtnstr);

    uicontrol(figNmbr,Style,textstr,Tag,wksctrlTag, ...
      Position,[0.030 0.650 0.490 0.060],HorizontalAlignment,leftstr, ...
      String,'Signal Title Matrix:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,editstr,Tag,titctrlTag, ...
      Position,[0.540 0.640 0.310 0.080],HorizontalAlignment,centerstr, ...
      BackgroundColor,edtBackgroundColor,ToolTipString,wksvarctrlstr);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,wksctrlTag, ...
      Position,[0.890 0.640 0.090 0.080],String,'', ...
      CallBack,'ringdown(''rguiload([],7,2);'');', ...
      BackgroundColor,btnBackgroundColor,ToolTipString,wksvarbtnstr);

    uicontrol(figNmbr,Style,textstr,Tag,wksctrlTag, ...
      Position,[0.030 0.540 0.490 0.060],HorizontalAlignment,leftstr, ...
      String,'Input Pulse Matrix:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,editstr,Tag,inpctrlTag, ...
      Position,[0.540 0.530 0.310 0.080],HorizontalAlignment,centerstr, ...
      BackgroundColor,edtBackgroundColor,ToolTipString,wksvarctrlstr);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,wksctrlTag, ...
      Position,[0.890 0.530 0.090 0.080],String,'', ...
      CallBack,'ringdown(''rguiload([],7,3);'');', ...
      BackgroundColor,btnBackgroundColor,ToolTipString,wksvarbtnstr);

    uicontrol(figNmbr,Style,textstr,Tag,wksctrlTag, ...
      Position,[0.030 0.430 0.490 0.060],HorizontalAlignment,leftstr, ...
      String,'Known Pole Matrix:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,editstr,Tag,polctrlTag, ...
      Position,[0.540 0.420 0.310 0.080],HorizontalAlignment,centerstr, ...
      BackgroundColor,edtBackgroundColor,ToolTipString,wksvarctrlstr);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,wksctrlTag, ...
      Position,[0.890 0.420 0.090 0.080],String,'', ...
      CallBack,'ringdown(''rguiload([],9,4);'');', ...
      BackgroundColor,btnBackgroundColor,ToolTipString,wksvarbtnstr);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,wksctrlTag, ...
      Position,[0.030 0.030 0.300 0.110],String,importstr, ...
      CallBack,'ringdown(''rguiload([],2);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,wksctrlTag, ...
      Position,[0.350 0.030 0.300 0.110],String,'File', ...
      CallBack,'ringdown(''rguiload([],3);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,wksctrlTag, ...
      Position,[0.670 0.030 0.300 0.110],String,cancelstr, ...
      CallBack,delstr,BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Tag,filctrlTag,Visible,offstr, ...
      Position,[0.030 0.910 0.940 0.060],HorizontalAlignment,centerstr, ...
      String,'Select File Type',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,filctrlTag,Visible,offstr, ...
      Position,[0.030 0.720 0.940 0.110],String,'BPA PPSM', ...
      CallBack,'ringdown(''rguiload([],4);'');','Interruptible',onstr, ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,filctrlTag,Visible,offstr, ...
      Position,[0.030 0.580 0.940 0.110],String,'Ontario-Hydro DPSS', ...
      CallBack,'ringdown(''rguiload([],6,1);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,filctrlTag,Visible,offstr, ...
      Position,[0.030 0.440 0.940 0.110],String,'PSAM Text Format', ...
      CallBack,'ringdown(''rguiload([],6,2);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,filctrlTag,Visible,offstr, ...
      Position,[0.030 0.300 0.940 0.110],String,'PTI Text Format', ...
      CallBack,'ringdown(''rguiload([],6,3);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,filctrlTag,Visible,offstr, ...
      Position,[0.030 0.160 0.940 0.110],String,'Swing Export (SWX)', ...
      CallBack,'ringdown(''rguiload([],8);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,filctrlTag,Visible,offstr, ...
      Position,[0.030 0.030 0.940 0.110],String,cancelstr, ...
      CallBack,delstr,BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Tag,ppsmctrlTag,Visible,offstr, ...
      Position,[0.030 0.910 0.940 0.060],HorizontalAlignment,centerstr, ...
      String,'PPSM File Data',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Tag,ppsmctrlTag,Visible,offstr, ...
      Position,[0.030 0.820 0.610 0.060],HorizontalAlignment,leftstr, ...
      String,'Number of Signals:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Tag,nsigindTag,Visible,offstr, ...
      Position,[0.770 0.820 0.200 0.060],HorizontalAlignment,centerstr, ...
      BackgroundColor,indBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Tag,ppsmctrlTag,Visible,offstr, ...
      Position,[0.030 0.740 0.610 0.060],HorizontalAlignment,leftstr, ...
      String,'Total Number of Scans:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Tag,nscnindTag,Visible,offstr, ...
      Position,[0.770 0.740 0.200 0.060],HorizontalAlignment,centerstr, ...
      BackgroundColor,indBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Tag,ppsmctrlTag,Visible,offstr, ...
      Position,[0.030 0.640 0.940 0.060],HorizontalAlignment,centerstr, ...
      String,'Signals to Read',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,'ListBox',Tag,psigctrlTag,Visible,offstr, ...
      Position,[0.030 0.280 0.940 0.360],HorizontalAlignment,leftstr, ...
      'Min',1,BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Tag,ppsmctrlTag,Visible,offstr, ...
      Position,[0.030 0.180 0.610 0.060],HorizontalAlignment,leftstr, ...
      String,'Decimate Factor:',BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,editstr,Tag,dectrlTag,Visible,offstr, ...
      Position,[0.770 0.170 0.200 0.080],HorizontalAlignment,centerstr, ...
      String,'1',BackgroundColor,edtBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,ppsmctrlTag,Visible,offstr, ...
      Position,[0.030 0.030 0.460 0.110],String,importstr, ...
      CallBack,'ringdown(''rguiload([],5);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Tag,ppsmctrlTag,Visible,offstr, ...
      Position,[0.510 0.030 0.460 0.110],String,cancelstr, ...
      CallBack,delstr,BackgroundColor,btnBackgroundColor);

    drawnow;
    set(findobj(figNmbr),'HandleVisibility',CallBack); set(figNmbr,Visible,onstr);

    return;

%============================================================================
% Import variables out of the MATLAB workspace.
  elseif action1==2

    figNmbr=gcf; figNumber=get(figNmbr,UserData); h=cell(5,1);
    h2={sigctrlTag titctrlTag inpctrlTag polctrlTag};
    for ii=1:4
      h{ii}=get(findobj(figNmbr,Tag,h2{ii}),String);
      h{ii}=fliplr(deblank(fliplr(deblank(h{ii}))));
      if isempty(h{ii})
        if ii==1
          errordlg('Variable name for signal data matrix must be entered.');
          return;
        end
        h{ii}='[]';
      else
        if ~evalin(basestr,['exist(''' h{ii} ''',''var'')'])
          errordlg(['Unable to locate variable ''' h{ii} '''']);
          return;
        end
      end
    end
    if isempty(figNumber) h{5}='[]'; else; h{5}=sprintf('%d',figNumber); end
    evalin(basestr,['ringdown(' h{1} ',' h{2} ',' h{3} ',' h{4} ',[],' h{5} ');'], ...
      'q=errordlg(''Unknown error occurred while launching Ringdown Tool.'');');
    if exist('q')~=1; delete(figNmbr); end

    return;

%============================================================================
% Make the file import screen visible.
  elseif action1==3

    figNmbr=gcf;
    h=[findobj(figNmbr,Tag,wksctrlTag); findobj(figNmbr,Tag,sigctrlTag); ...
      findobj(figNmbr,Tag,titctrlTag); findobj(figNmbr,Tag,inpctrlTag); ...
      findobj(figNmbr,Tag,polctrlTag)];
    set(h,Visible,offstr); set(findobj(figNmbr,Tag,filctrlTag),Visible,onstr);

    return;

%============================================================================
% Read PPSM header information.  Make the PPSM screen visible.
  elseif action1==4

    figNmbr=gcf;
    eval(['q=questdlg(''Use embedded DAS listing if present?'','''',' ...
      '''Yes'',''No'',''Yes'');'],'delete(figNmbr); return;');
    drawnow; if exist('q')~=1; delete(figNmbr); return; end
    if strcmp(q,nostr); dfile='Select'; else; dfile=''; end
    [y,chan,name,unit,delay,ppath,pfile,dfile,pdat,errmsg]=PPSMread([],[],dfile,[],1);
    if ~isempty(errmsg); errordlg(['Error reading file:  ' errmsg]); return; end
    h=length(chan); if h<1; delete(figNmbr); return; end
    nsigindHndl=findobj(figNmbr,Tag,nsigindTag);
    nscnindHndl=findobj(figNmbr,Tag,nscnindTag);
    psigctrlHndl=findobj(figNmbr,Tag,psigctrlTag);
    dectrlHndl=findobj(figNmbr,Tag,dectrlTag);
    set(nsigindHndl,String,int2str(h),UserData,ppath);
    set(nscnindHndl,String,int2str(sum(pdat(:,2))),UserData,pfile);
    set(psigctrlHndl,String,name(2:end,:),'Max',h,UserData,dfile);
    set(findobj(figNmbr,Tag,filctrlTag),Visible,offstr);
    h=[findobj(figNmbr,Tag,ppsmctrlTag); nsigindHndl; nscnindHndl; ...
       psigctrlHndl; findobj(figNmbr,Tag,dectrlTag)];
    set(h,Visible,onstr);

    return;

%============================================================================
% Import PPSM data and launch the Ringdown Analysis Tool.
  elseif action1==5

    figNmbr=gcf; figNumber=get(figNmbr,UserData);
    df=str2num(get(findobj(figNmbr,Tag,dectrlTag),String));
    if isempty(df); df=1; return; end
    col=get(findobj(figNmbr,Tag,psigctrlTag),'Value');
    ppath=get(findobj(figNmbr,Tag,nsigindTag),UserData);
    pfile=get(findobj(figNmbr,Tag,nscnindTag),UserData);
    dfile=get(findobj(figNmbr,Tag,psigctrlTag),UserData);
    [y,chan,name,unit,h,h1,h2,h3,h4,errmsg]=PPSMread(ppath,pfile,dfile,col,df);
    if ~isempty(errmsg); errordlg(['Error reading files:  ' errmsg]); return; end
    delete(figNmbr); ringdown(y,name,[],[],[],figNumber);

    return;

%============================================================================
% Read data from Ontario-Hydro DPSS, PSAM header, or PTI text file.
  elseif action1==6

    figNmbr=gcf;
    switch action2
      case 1, y=dpssread([]);
      case 2, y=PSAMread([]);
      case 3, y=ptirread([]);
    end
    if isempty(y); return; end; delete(figNmbr);
    ringdown(y,[],[],[],[],figNumber);

    return;

%============================================================================
% Display a menu of workspace variables
  elseif action1==7

    figNmbr=gcf; h=evalin(basestr,'who');

    if isempty(h)
      errordlg('No variables found in workspace.');
      return;
    end

    ind=listdlg('PromptString','Select Workspace Variable', ...
      'SelectionMode','single','ListString',h);

    if ~isempty(ind)
      h2=h{ind};
      switch action2
        case 1, h=sigctrlTag;
        case 2, h=titctrlTag;
        case 3, h=inpctrlTag;
        case 4, h=polctrlTag;
      end
      set(findobj(figNmbr,Tag,h),String,h2);
    end

    return;

%============================================================================
% Read Swing Export (SWX) file.  This uses a user-customized file read routine
  elseif action1==8

    figNmbr=gcf; [y,name]=swxload0;
    if isempty(y); return; end; delete(figNmbr);
    ringdown(y,name,[],[],[],figNumber);

  end
