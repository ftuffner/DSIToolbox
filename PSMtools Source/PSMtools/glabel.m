function h=glabel(textstr,box_on,action,s);

% GLABEL Interactive placement of object labels on a plot figure.
%        GLABEL(textstr,box_on) displays the graph window, puts up a
%        cross-hair, and waits for the left mouse button to be pressed.
%        Pressing the left mouse button creates the label at the location
%        of the cross-hair.  Another cross-hair then allows the user to
%        select a marked point on the label box from which to extend a
%        pointer line.  Pressing the left mouse button selects this point.
%        Finally, a third cross-hair appears that allows the user to select
%        second endpoint of the pointer line.
%        Placing the mouse pointer over the text label and holding down the
%        left mouse button allows the label to be moved.
%        Placing the mouse pointer over the text label and double-clicking
%        brings up a font selection dialog box (PC and Macintosh only).
%
%        Usage
%
%          h=glabel(textstr,box_on);
%
%        Inputs:
%
%          textstr = String with label text.  Must be single-line.
%
%          box_on  = Control for frame around label.
%                    Set == 1 to create a frame around the label.
%                    Set == 0 for no frame.
%
%        Outputs:
%
%          h       = Handles of text object, frame, and pointer line.

% By Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date:  September 1996.
%
% Copyright (c) 1995-1996 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id: glabel.m,v 1.1 1996/09/18 23:37:35 d3h902 Exp $

% User configurable defaults.

  % Margins around label.  Enter these as a ratio of the horizontal
  % or vertical width of the label text object.
  c=computer;

  if isunix
    lmargin=0;
    rmargin=0;
    tmargin=0;
    bmargin=-0.2;
  elseif strcmp(c,'PCWIN')
    lmargin=0.1;
    rmargin=0.1;
    tmargin=0.1;
    bmargin=0.1;
  elseif strcmp(c,'MAC2')
    lmargin=0.15;
    rmargin=0.15;
    tmargin=0.25;
    bmargin=0;
  end

%============================================================
% Parse input arguments.
error(nargchk(2,4,nargin));

figHndl=gcf;
axesHndl=gca;

if nargin>2
  if ~strcmp(action,'but_dwn') & ~strcmp(action,'resize') ...
   & ~strcmp(action,'drawbox')
    error('Too many input arguments.')
  end

  if strcmp(action,'but_dwn')
    seltype=get(figHndl,'SelectionType');
    if strcmp(seltype,'open')
      if strcmp(c,'PCWIN') | strcmp(c,'MAC2')
        action='setfont';
      else
        return
      end
    else
      action='move';
    end
  end
else
  action='create';
end

%============================================================
% Create the label.

if strcmp(action,'create')

  % Check injput arguments
  if ~isstr(textstr)
    error('Input argument textstr must be a string.')
  end

  if size(textstr,1)~=1
    error('Input argument textstr must have 1 row.');
  end

  box_on=box_on(1);

  % Find the font and line properties used on the current plot axis.
  fontname=get(axesHndl,'FontName');
  fontsize=get(axesHndl,'FontSize');
  linewidth=get(axesHndl,'LineWidth');
  axesxLim=get(axesHndl,'XLim');
  axesyLim=get(axesHndl,'YLim');

  % Prompt the user to select the label position.
  disp('Select the position for the center of the label.');
  [textxPos,textyPos]=ginput(1);

  % Create the text label.
  textHndl=text(textxPos,textyPos,textstr, ...
       'Tag','glabel', ...
       'Units','data', ...
       'FontName',fontname, ...
       'FontSize',fontsize, ...
       'HorizontalAlignment','center', ...
       'VerticalAlignment','middle');

  textPos=get(textHndl,'Extent');

  % Draw the frame around the label
  lPos=textPos(1)-lmargin*textPos(3);
  rPos=textPos(1)+textPos(3)+rmargin*textPos(3);
  tPos=textPos(2)+textPos(4)+tmargin*textPos(4);
  bPos=textPos(2)-bmargin*textPos(4);
  hcPos=lPos+(rPos-lPos)/2;
  vcPos=bPos+(tPos-bPos)/2;

  if box_on
    boxxData=[lPos rPos rPos lPos lPos];
    boxyData=[bPos bPos tPos tPos bPos];

    boxHndl=line(boxxData,boxyData, ...
       'LineStyle','-', ...
       'LineWidth',linewidth, ...
       'Color','w');
  else
    boxHndl=[];
  end

  % Draw the selection frame around the label
  sboxxData=[lPos hcPos rPos rPos rPos hcPos lPos lPos];
  sboxyData=[bPos bPos bPos vcPos tPos tPos tPos vcPos];

  sboxHndl=line(sboxxData,sboxyData, ...
       'LineStyle','x', ...
       'Color','w');

  % Prompt the user to select the endpoints of the pointer line
  disp('Select the marker on the label from which to extend the pointer line.')

  selectxReg=(axesxLim(2)-axesxLim(1))/50;
  selectyReg=(axesyLim(2)-axesyLim(1))/50;
  plinxData=zeros(2,1);
  plinyData=plinxData;

  reselect=1;
  while reselect
    [selectxPos,selectyPos]=ginput(1);

    imarker=find(abs(sboxxData-selectxPos)<selectxReg & ...
                 abs(sboxyData-selectyPos)<selectyReg);

    if ~isempty(imarker)
      plinxData(1)=sboxxData(imarker(1));
      plinyData(1)=sboxyData(imarker(1));
      reselect=0;
    end
  end

  delete(sboxHndl);

  disp('Select where the line is to point.');
  [plinxData(2),plinyData(2)]=ginput(1);

  plinHndl=line(plinxData,plinyData, ...
       'LineStyle','-', ...
       'LineWidth',linewidth, ...
       'Color','w', ...
       'UserData',imarker(1));

  % Create the output variable and set the label object callbacks.
  h=[textHndl; boxHndl; plinHndl];

  c=computer;
  if ~strcmp(c,'PCWIN')  % MATLAB for Windows doesn't allow a resize function.
    set(figHndl,'ResizeFcn','glabel([],[],''resize'');');
  end

  set(textHndl, ...
       'ButtonDownFcn','glabel([],[],''but_dwn'',1);', ...
       'UserData',h);

%============================================================
% Redraw the frame and pointer line.
elseif strcmp(action,'drawbox')

  labelHndl=s;

  h=get(labelHndl,'UserData');

  textHndl=h(1);
  if length(h)==3
    boxHndl=h(2);
    plinHndl=h(3);
  else
    boxHndl=[];
    plinHndl=h(2);
  end

  textPos=get(textHndl,'Extent');

  lPos=textPos(1)-lmargin*textPos(3);
  rPos=textPos(1)+textPos(3)+rmargin*textPos(3);
  tPos=textPos(2)+textPos(4)+tmargin*textPos(4);
  bPos=textPos(2)-bmargin*textPos(4);

  if ~isempty(boxHndl)
    boxxData=[lPos rPos rPos lPos lPos];
    boxyData=[bPos bPos tPos tPos bPos];

    set(boxHndl,'XData',boxxData,'YData',boxyData,'Visible','on');
  end

  plinxData=get(plinHndl,'XData');
  plinyData=get(plinHndl,'YData');
  imarker=get(plinHndl,'UserData');

  if imarker==1
    plinxData(1)=lpos;
    plinyData(1)=bpos;
  elseif imarker==2
    plinxData(1)=lPos+(rPos-lPos)/2;
    plinyData(1)=bPos;
  elseif imarker==3
    plinxData(1)=rPos;
    plinyData(1)=bPos;
  elseif imarker==4
    plinxData(1)=rPos;
    plinyData(1)=bPos+(tPos-bPos)/2;
  elseif imarker==5
    plinxData(1)=rPos;
    plinyData(1)=tPos;
  elseif imarker==6
    plinxData(1)=lPos+(rPos-lPos)/2;
    plinyData(1)=tPos;
  elseif imarker==7
    plinxData(1)=lPos;
    plinyData(1)=tPos;
  else
    plinxData(1)=lPos;
    plinyData(1)=bPos+(tPos-bPos)/2;
  end

  set(plinHndl,'XData',plinxData,'YData',plinyData,'Visible','on');

%============================================================
% Figure was resized.
elseif strcmp(action,'resize')

  labelHndls=findobj(figHndl,'Tag','glabel');

  if isempty(labelHndls); return; end

  for ii=1:length(labelHndls)
    glabel([],[],'drawbox',labelHndls(ii));
  end

%============================================================
% Label is to be moved.
elseif strcmp(action,'move')

  curobj=gco;

  if s==1         % Mouse button down.
    h=get(curobj,'UserData');

    textHndl=h(1);
    if length(h)==3
      boxHndl=h(2);
      plinHndl=h(3);
    else
      boxHndl=[];
      plinHndl=h(2);
    end

    set([boxHndl plinHndl],'Visible','off');

    set(figHndl, ...
         'WindowButtonMotionFcn','glabel([],[],''but_dwn'',2);', ...
         'WindowButtonUpFcn','glabel([],[],''but_dwn'',3);');

  elseif s==2     % Motion
    ptPos=get(axesHndl,'CurrentPoint');

    set(curobj,'Position',[ptPos(1,1) ptPos(1,2)]);

  else            % Mouse button up.
    set(figHndl,'WindowButtonMotionFcn','','WindowButtonUpFcn','');

    glabel([],[],'drawbox',curobj);
  end

%============================================================
% Bring up font selection dialog box.
elseif strcmp(action,'setfont')

  curobj=gco;

  out=uisetfont(curobj,'Label Font');

  if out; glabel([],[],'drawbox',curobj); end

%============================================================
end


