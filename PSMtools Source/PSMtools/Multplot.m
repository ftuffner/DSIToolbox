function Multplot(sigdat, sigtitles, pagetitles, options);

% MULTPLOT:  multiple signal plots, plot
%
% Functions for creating labeled plots of multiple signals.  Current
% options include creating one or more multi-trace plots with legends
% or creating stacked vertically aligned plots with one signal per plot.
%
% Usage:
%
%            Multplot(sigdat, sigtitles, pagetitles, options);
%
% where
%
%   sigdat       = Matrix with data to plot.  First column is horizontal
%                  axis data and second through last are signal data.
%
%   sigtitles    = Cell array of strings specifying titles for columns
%                  in sigdat.
%
%   pagetitles   = Structure with 3 fields
%                  pagetitles.title     = Title for page
%                  pagetitles.subtitleL = Subtitle for left side of page.
%                  pagetitles.subtitleR = Subtitle for right side of page.
%
%   options      = Structure specifying plot options.  Fields described below.
%                  options.plottype specifies plot type.
%                  options.plottype == 0 ==> Vertically aligned plots
%                  options.plottype == 1 ==> Multiple trace plots
%                  options.nnplots specifies number of plots per page
%                  options.linectrl specifies how to draw traces
%                  options.linectrl == 0 ==> All traces have same color,
%                                            style, and linewidth
%                  options.linectrl == 1 ==> Draw traces varying color and
%                                            linewidth
%                  options.linectrl == 2 ==> Draw traces varying color, style,
%                                            and linewidth

% Note:  Several of the functions below contain user editable parameters that
%        allow further customization of plot attributes.
%
% Author:  Jeff M. Johnson, Battelle Pacific Northwest National Laboratory
% Date:  January 4, 1999
%
% Copyright (c) 1995-1999 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$
%
% Last modification 02/04/2000   jmj
% Last modified 11/05/02.   jfh

% Check number of input arguments
error(nargchk(4, 4, nargin));

% Check input arguments
if ~isnumeric(sigdat); error('First input must be numeric array'); end

nnsigs = size(sigdat, 2) - 1;

if nnsigs < 1; error('No data to plot'); end

if ~isempty(sigtitles)

  if ~iscell(sigtitles)
    error('Second input must be cell array of strings');
  end

  if length(sigtitles) ~= nnsigs + 1
    error('Must be a title for each signal');
  end

end

if ~isstruct(pagetitles)
  error('Third input must be a structure containing title strings');
end

if ~isstruct(options)
  error('Fourth input must be a structure specifying plot options');
end

if ~isfield(options, 'plottype')
  error('Options structure must contain a field labeled ''plottype''');
end

% Initialized global variables in createfig.
[figparams, errmsg] = createfig(1, pagetitles);

% Return if error
error(errmsg);

% Call function to generate desired plot
switch options.plottype
  case 0, errmsg = stackplots(sigdat, sigtitles, options, figparams);
  case 1, errmsg = multtraceplots(sigdat, sigtitles, options, figparams);
  otherwise, errmsg = 'Unrecognized plot type option';
end

% Clear createfig variables
createfig(3);

% Return if error
error(errmsg);

%=========================================================================
% Function to create stacked plots
function errmsg = stackplots(sigdat, sigtitles, options, figparams);

% Inputs:
%
%   sigdat    = See help above
%
%   sigtitles = See help above
%
%   figparams = Figure parameter structure from createfig function

% Number of signals
nnsigs = size(sigdat, 2) - 1;

% Check options input
if ~isfield(options, 'nnplots') | ~isfield(options, 'linectrl')
  errmsg = ['Options input must contain fields labeled ''nnplots'' ' ...
            'and ''linectrl'''];
  return;
end

if ~isnumeric(options.nnplots) | ~isnumeric(options.linectrl)
  errmsg = 'Options.nnplots and options.linectrl must be numeric';
  return;
end

% Extract flags for plot printing & saving
PrntPlot=options.printplot;
SavePlot=options.saveplot;
SaveFile=options.savewhere;

nnplots = options.nnplots;
linectrl = options.linectrl;

if nnplots < 1
  errmsg = 'Number of traces per plot must be > 0';
  return;
end

if linectrl ~= 0 & linectrl ~= 1 & linectrl ~= 2
  errmsg = 'Line control option must be 0, 1, or 2 for stacked plots';
  return;
end

%-------------------------------------------------------------------------
% User configurable parameters.  Units for all position quantities below
% are inches.

% Vertical position of lower edge of bottom plot axes
axes0yPosI = 1.25;

% Vertical spacing between stacked plot axes
axesaxesySpacingI = 0.20;

% Vertical position between top of plot axes and signal title
axestitleySpacingI = 0.05;

% Font sizes for titles and labels.  Units are in points (1/72 inches).
sigtitleFontSizePt     = 7;
axesFontSizePt         = 8;
axesxlabelFontSizePt   = 10;

% Linewidths for axes and traces.  Units are in points
defaultAxesLineWidthPt = get(0,'DefaultAxesLineWidth');
defaultLineLineWidthPt = get(0,'DefaultLineLineWidth');

axesLineWidthPt        = defaultAxesLineWidthPt;
lineLineWidthPt        = defaultLineLineWidthPt;
lineLineWidthIncrement = 1;

% Colors and linestyles for multi-trace plots.
lineColors = { [0.00 0.00 1.00]; [0.00 0.50 0.00]; [0.00 0.75 0.75]; ...
               [0.75 0.00 0.75]; [0.75 0.75 0.00]; [0.25 0.25 0.25] };
lineColors = { [0.00 0.00 1.00]; [0.00 0.50 0.00]; [1.00 0.00 0.00]; ...
               [0.00 0.75 0.75]; [0.75 0.00 0.75]; [0.75 0.75 0.00];
               [0.25 0.25 0.25]};
lineColorsM = get(0,'defaultaxescolororder');
for N=1:size(lineColorsM,1), lineColors{N}=lineColorsM(N,:); end

lineLineStyles = {'-'; '--'; '-.'; ':'};

% Grid control for plots
axesXGrid = 'on';
axesYGrid = 'on';

%-------------------------------------------------------------------------
% Calculate position vectors for objects on page

% Position vectors for plot axes.
figHtI = figparams.figPaperPositionI(4);
onesmtx = ones(nnplots, 1);
axesPosN = onesmtx * figparams.axesPosdN;
daxesyPosI = (figparams.axesTopI - axes0yPosI) / nnplots;
axesyPosI = axes0yPosI + daxesyPosI * (nnplots - 1:-1:0)';
axesHtI = daxesyPosI - axesaxesySpacingI;
axesPosN(:, 2) = axesyPosI / figHtI;
axesPosN(:, 4) = axesHtI / figHtI;

% Check for too many plots per page
if axesHtI <= 0
  errmsg = 'Too many plots per page requested.';
  return;
end

% Positions for signal titles.  Titles will be right justified.
sigtitleXdata = (figparams.axesLeftI + figparams.axesWidI) * onesmtx;
sigtitleYdata = axesyPosI + axesHtI + axestitleySpacingI;

%-------------------------------------------------------------------------
% Draw plots

% Number of pages and number of plots on each page
nnpages = ceil(nnsigs / nnplots);
nnplotspage = nnplots * ones(nnpages, 1);
nnplotspage(nnpages) = nnsigs - nnplots * (nnpages - 1);

% Read the horizontal axis data
xdat = sigdat(:, 1);

% Determine number of colors and number of linestyles
nncolors = size(lineColors, 1);
nnstyles = length(lineLineStyles);

% Index for first signal
sigindx = 2;

addsigtitles = ~isempty(sigtitles);

% Loop to create plots
for ii = 1:nnpages

  % Indices for current signal, color, and linestyle
  colindx = 1;
  styindx = 1;
  lineColor = lineColors{1};
  lineLineStyle = lineLineStyles{1};

  % Initial linewidth
  if linectrl == 0

    linewidth = lineLineWidthPt;

  elseif linectrl == 1

    linewidth = lineLineWidthPt + ...
      lineLineWidthIncrement * (ceil(nnplotspage(ii) / nncolors) - 1);

  else

    linewidth = lineLineWidthPt + ...
      lineLineWidthIncrement * (ceil(nnplotspage(ii) / nnstyles) - 1);

  end

  % Create the parent figure
  figparams = createfig(2);

  % Create the signal titles
  if addsigtitles

    indx = 1:nnplotspage(ii);

    text(sigtitleXdata(indx), sigtitleYdata(indx), ...
      fliplr(deblank(fliplr(deblank(sigtitles(sigindx + indx - 1))))), ...
      'FontSize', sigtitleFontSizePt, 'HorizontalAlignment', 'right');

  end

  for jj = 1:nnplotspage(ii)

    % Create the plot axes
    axesHndl = axes('Position', axesPosN(jj, :), ...
      'LineWidth', axesLineWidthPt, 'FontSize', axesFontSizePt, ...
      'XTickLabel', '', 'XGrid', axesXGrid, 'YGrid', axesYGrid);

    % Plot the signal
    plot(xdat, sigdat(:, sigindx), 'Color', lineColor, ...
      'LineStyle', lineLineStyle, 'LineWidth', linewidth);

    % Change the line color, style, and width, if necessary
    if linectrl ~= 0

      if colindx == nncolors
        if linectrl == 1; linewidth = linewidth - lineLineWidthIncrement; end
        colindx = 1;
      else
        colindx = colindx + 1;
      end

      lineColor = lineColors{colindx};

      if linectrl == 2

        if styindx == nnstyles
          linewidth = linewidth - lineLineWidthIncrement;
          styindx = 1;
        else
          styindx = styindx + 1;
        end

        lineLineStyle = lineLineStyles{styindx};

      end

    end

    % Increment the signal index
    sigindx = sigindx + 1;

  end

  % Make the x-axis labels visible on the lowest axis
  set(axesHndl, 'XTickLabelMode', 'auto');

  % Add the xlabel to the lowest axis
  if addsigtitles

    set(get(axesHndl, 'XLabel'), 'String', deblank(sigtitles{1}), ...
      'FontSize', axesxlabelFontSizePt, 'HorizontalAlignment', 'center');

  end

   % Logic for hardcopy and save to file
   h=figparams.figHndl;
   if PrntPlot, print -f, end
   if SavePlot
     SaveP=[SaveFile num2str(h)]; disp(SaveP)
     eval(['print -depsc -tiff ' SaveP])
   end 

   % Hide the figure handle
   % set(figparams.figHndl, 'HandleVisibility', 'off');

end

% Assign the output
errmsg = '';

%=========================================================================
% Function to create multi-trace plots
function errmsg = multtraceplots(sigdat, sigtitles, options, figparams);

% Inputs:
%
%   sigdat    = See help above
%
%   sigtitles = See help above
%
%   options   = See help above
%
%   figparams = Figure parameter structure from createfig function

% Number of signals
nnsigs = size(sigdat, 2) - 1;

% Check options input
if ~isfield(options, 'nnplots') | ~isfield(options, 'linectrl')
  errmsg = ['Options input must contain fields labeled ''nnplots'' ' ...
            'and ''linectrl'''];
  return;
end

if ~isnumeric(options.nnplots) | ~isnumeric(options.linectrl)
  errmsg = 'Options.nnplots and options.linectrl must be numeric';
  return;
end

% Extract flags for plot printing & saving
PrntPlot=options.printplot;
SavePlot=options.saveplot;
SaveFile=options.savewhere;

nnplots = options.nnplots;
linectrl = options.linectrl;

if nnplots < 1
  errmsg = 'Number of traces per plot must be > 0';
  return;
end

if linectrl ~= 1 & linectrl ~= 2
  errmsg = 'Line control option must be 1 or 2 for multi-trace plots';
  return;
end

%-------------------------------------------------------------------------
% User configurable parameters.  Units for all position quantities below
% are inches.

% Height of plot axes
axesHtI   = 5;

% Vertical position of lower edge of legend box
legendboxyPosI = 1;

% Spacing between lower edge of plot axes and top of legend box
axeslegendySpacingI = 0.75;

% Spacing between top of legend box and base of legend box title
legendtitleySpacingI = 0.125;

% Position data for legend lines and signal titles.
% Left margins are relative to legend box.
legendlineLeftI = 0.125;
legendlineWidI  = 1;
sigtitleLeftI   = 1.25;

% Spacing between vertical centers of signal titles and legend box
sigtitlelegendySpacing = 0.25;

% Font sizes for titles and labels.  Units are in points (1/72 inches).
sigtitleFontSizePt     =  9;
axesFontSizePt         = 10;
axesxlabelFontSizePt   = 10;
legendlabelFontSizePt  = 12;

% Linewidths for axes and traces.  Units are in points
defaultAxesLineWidthPt = get(0,'DefaultAxesLineWidth');
defaultLineLineWidthPt = get(0,'DefaultLineLineWidth');

axesLineWidthPt        = defaultAxesLineWidthPt;
lineLineWidthPt        = defaultLineLineWidthPt;
lineLineWidthIncrement = 1;

% Colors and linestyles for multi-trace plots.
lineColors = { [0.00 0.00 1.00]; [0.00 0.50 0.00]; [0.00 0.75 0.75]; ...
               [0.75 0.00 0.75]; [0.75 0.75 0.00]; [0.25 0.25 0.25] };
lineColors = { [0.00 0.00 1.00]; [0.00 0.50 0.00]; [1.00 0.00 0.00]; ...
               [0.00 0.75 0.75]; [0.75 0.00 0.75]; [0.75 0.75 0.00];
               [0.25 0.25 0.25]};
lineColorsM = get(0,'defaultaxescolororder');
for N=1:size(lineColorsM,1), lineColors{N}=lineColorsM(N,:); end

lineLineStyles = {'-'; '--'; '-.'; ':'};

% Grid control for multi-trace plots
axesXGrid = 'on';
axesYGrid = 'on';

%-------------------------------------------------------------------------
% Calculate position vector for plot axes and legend box.

% Plot axes position in normalized coordinates
figHtI = figparams.figPaperPositionI(4);
axesPosN = figparams.axesPosdN;
axesyPosI = figparams.axesTopI - axesHtI;
axesPosN(2) = axesyPosI / figHtI;
axesPosN(4) = axesHtI / figHtI;

% Legend box will be a patch object plotted on title axis.
axesLeftI = figparams.axesLeftI;
legendboxHtI = axesyPosI - axeslegendySpacingI - legendboxyPosI;
legendboxXdata = axesLeftI + [0 figparams.axesWidI * [1 1] 0];
legendboxYdata = legendboxyPosI + [0 0 legendboxHtI * [1 1]];

% Vertical position for legend box title
legendtitleyPosI = legendboxYdata(3) + legendtitleySpacingI;

% Calculate position vectors for signal titles
sigtitleXdata = (axesLeftI + sigtitleLeftI) * ones(nnplots, 1);
sigtitleYdata = legendboxyPosI + sigtitlelegendySpacing + ...
  (legendboxHtI - 2 * sigtitlelegendySpacing) * ...
  (nnplots - 1:-1:0)' / (nnplots - 1);

% Vertical positions of legend lines
legendlineXdata = axesLeftI + legendlineLeftI + [0 legendlineWidI];
legendlineYdata = sigtitleYdata * [1 1];

%-------------------------------------------------------------------------
% Draw plots

% Number of pages and number of traces on each page
nnpages = ceil(nnsigs / nnplots);
nnplotspage = nnplots * ones(nnpages, 1);
nnplotspage(nnpages) = nnsigs - nnplots * (nnpages - 1);

% Read the horizontal axis data
xdat = sigdat(:, 1);

% Determine number of colors and number of linestyles
nncolors = size(lineColors, 1);
nnstyles = length(lineLineStyles);

% Index for first signal
sigindx = 2;

addsigtitles = ~isempty(sigtitles);

% Loop to create plots
for ii = 1:nnpages

  % Indices for current signal, color, and linestyle
  colindx = 1;
  styindx = 1;
  lineColor = lineColors{1};
  lineLineStyle = lineLineStyles{1};

  % Initial linewidth
  if linectrl == 0

    linewidth = lineLineWidthPt;

  elseif linectrl == 1

    linewidth = lineLineWidthPt + ...
      lineLineWidthIncrement * (ceil(nnplotspage(ii) / nncolors) - 1);

  else

    linewidth = lineLineWidthPt + ...
      lineLineWidthIncrement * (ceil(nnplotspage(ii) / nnstyles) - 1);

  end

  % Create the parent figure
  figparams = createfig(2);
  titleaxesHndl = figparams.titleaxesHndl;

  % Create the legend box and titles
  if addsigtitles

    patch(legendboxXdata, legendboxYdata, [1 1 1], ...
      'EdgeColor', [0 0 0], 'FaceColor', 'none', ...
      'LineWidth', axesLineWidthPt);

    text(axesLeftI, legendtitleyPosI, 'Key:', ...
      'FontSize', legendlabelFontSizePt, ...
      'HorizontalAlignment', 'left');

    indx = 1:nnplotspage(ii);

    text(sigtitleXdata(indx), sigtitleYdata(indx), ...
      fliplr(deblank(fliplr(deblank(sigtitles(sigindx + indx - 1))))), ...
      'FontName', 'courier new', 'FontSize', sigtitleFontSizePt, ...
      'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');

  end

  % Create the plot axes
  axesHndl = axes('Position', axesPosN, 'LineWidth', axesLineWidthPt, ...
    'FontSize', axesFontSizePt, 'XGrid', axesXGrid, 'YGrid', axesYGrid);

  % Plot signals and legend lines
  for jj = 1:nnplotspage(ii)

    plot(xdat, sigdat(:, sigindx), 'Color', lineColor, ...
      'LineStyle', lineLineStyle, 'LineWidth', linewidth);

    if addsigtitles

      axes(titleaxesHndl);

      plot(legendlineXdata, legendlineYdata(jj, :), 'Color', lineColor, ...
        'LineStyle', lineLineStyle, 'LineWidth', linewidth);

      axes(axesHndl);

    end

    % Change the line color, style, and width, if necessary
    if colindx == nncolors
      if linectrl == 1; linewidth = linewidth - lineLineWidthIncrement; end
      colindx = 1;
    else
      colindx = colindx + 1;
    end

    lineColor = lineColors{colindx};

    if linectrl == 2

      if styindx == nnstyles
        linewidth = linewidth - lineLineWidthIncrement;
        styindx = 1;
      else
        styindx = styindx + 1;
      end

      lineLineStyle = lineLineStyles{styindx};s

    end

    % Increment the signal index
    sigindx = sigindx + 1;

  end

  % Add the x-axis label
  if addsigtitles

    set(get(axesHndl, 'XLabel'), 'String', deblank(sigtitles{1}), ...
      'FontSize', axesxlabelFontSizePt, 'HorizontalAlignment', 'center');

  end

   % Logic for hardcopy and save to file
   h=figparams.figHndl;
   if PrntPlot, print -f, end
   if SavePlot
     SaveP=[SaveFile num2str(h)]; disp(SaveP)
     eval(['print -depsc -tiff ' SaveP])
   end

  % Hide the figure handle
  % set(figparams.figHndl, 'HandleVisibility', 'off');

end

% Assign the output
errmsg = '';

%=========================================================================
% Function to create figures
function [figparamsout, errmsg] = createfig(action, pagetitles);

% Creates a plot figure and places the title and subtitles and returns
% a structure containing parameters required by other plotting functions
%
% Arguments:
%
%   action        =
%
%   pagetitles    = See help above
%
%   figparamsout  = Structure containing figure parameters for plotting
%                   functions.

persistent pagetitle subtitleL subtitleR figPosP figparams
persistent pagetitlexPosI pagesubtitleLxPosI pagesubtitleRxPosI
persistent pagenumberxPosI

% Assign outputs
figparamsout=[];
errmsg='';

%-------------------------------------------------------------------------
% User configurable parameters.  Units for all position quantities below
% are inches.

% Vertical position and height for figures displayed on monitor.
% Units are pixels.
% figyPosP = 32;
% figHtP   = 695;

% Position vector for figures printed on paper.  Units are inches.
figPaperPositionI = [0.0 0.0 8.5 11.0];

% Vertical position for page title and subtitles.  Units are inches.
pagetitleyPosI    = 10;
pagesubtitleyPosI = 9.625;

% Vertical position for top of plot axes
axesTopI = 9.5;

% Font sizes for titles.  Units are in points (1/72 inches).
pagetitleFontSizePt    = 12;
pagesubtitleFontSizePt = 10;

% Vertical position and font size for page number
pagenumberyPosI = 0.75;
pagenumberFontSizePt = 8;

%-------------------------------------------------------------------------
% Initialization

if action == 1

  % Check inputs
  if ~isfield(pagetitles, 'pagetitle')
    errmsg = 'Pagetitles input must contain a field labeled ''pagetitle''';
    return;
  end

  if ~isfield(pagetitles, 'subtitleL')
    errmsg = 'Pagetitles input must contain a field labeled ''subtitleL''';
    return;
  end

  if ~isfield(pagetitles, 'subtitleR')
    errmsg = 'Pagetitles input must contain a field labeled ''subtitleR''';
    return;
  end

  % Read the titles
  pagetitle = fliplr(deblank(fliplr(deblank(pagetitles.pagetitle))));
  subtitleL = fliplr(deblank(fliplr(deblank(pagetitles.subtitleL))));
  subtitleR = fliplr(deblank(fliplr(deblank(pagetitles.subtitleR))));

  % Position vector (in pixels) for plot figures displayed on the monitor.
  un = get(0, 'DefaultFigureUnits');
  set(0, 'DefaultFigureUnits', 'pixels');
  figPosP = get(0, 'DefaultFigurePosition');
  set(0, 'DefaultFigureUnits', un);
%  figPosP(2) = figyPosP;
%  figPosP(4) = figHtP;

  % Read the default axes position.  Units are normalized
  un = get(0, 'DefaultAxesUnits');
  set(0, 'DefaultAxesUnits', 'normalized');
  axesPosdN = get(0, 'DefaultAxesPosition');
  set(0, 'DefaultAxesUnits', un);

  % Convert to inches
  axesLeftI = axesPosdN(1) * figPaperPositionI(3);
  axesWidI = axesPosdN(3) * figPaperPositionI(3);

  % Calculate positions for the titles and subtitles
  pagetitlexPosI = axesLeftI + axesWidI / 2;
  pagesubtitleLxPosI = axesLeftI;
  pagesubtitleRxPosI = axesLeftI + axesWidI;

  % Position for page number
  pagenumberxPosI = pagesubtitleRxPosI;

  % Create the output structure
  figparams.figHndl = [];
  figparams.titleaxesHndl = [];
  figparams.figPaperPositionI = figPaperPositionI;
  figparams.axesPosdN = axesPosdN;
  figparams.axesLeftI = axesLeftI;
  figparams.axesWidI = axesWidI;
  figparams.axesTopI = axesTopI;
  figparams.page = 1;

  figparamsout = figparams;

%-------------------------------------------------------------------------
% Create the figure and place the title and subtitles

elseif action == 2

  % Create the figure and an invisible axes for labels
  figparams.figHndl = figure('Units', 'pixels', 'Position', figPosP, ...
    'PaperUnits', 'inches', 'PaperPosition', figPaperPositionI, ...
    'DefaultAxesUnits','normalized', 'DefaultAxesBox', 'on', ...
    'DefaultAxesNextPlot', 'add', 'DefaultAxesTickDir', 'in', ...
    'DefaultTextInterpreter', 'none');

  figparams.titleaxesHndl = axes('Position', [0 0 1 1], 'Visible', 'off', ...
    'XLim', [0 figPaperPositionI(3)], 'YLim', [0 figPaperPositionI(4)]);

  % Place the title and subtitle on the figure
  if ~isempty(pagetitle)
    text(pagetitlexPosI, pagetitleyPosI, pagetitle, ...
      'FontSize', pagetitleFontSizePt, 'FontWeight', 'bold', ...
      'HorizontalAlignment', 'center');
  end

  if ~isempty(subtitleL)
    text(pagesubtitleLxPosI, pagesubtitleyPosI, subtitleL, ...
      'FontSize', pagesubtitleFontSizePt, 'HorizontalAlignment', 'left');
  end

  if ~isempty(subtitleR)
    text(pagesubtitleRxPosI, pagesubtitleyPosI, subtitleR, ...
      'FontSize', pagesubtitleFontSizePt, 'HorizontalAlignment', 'right');
  end

  % Page number
  page = figparams.page;

  text(pagenumberxPosI, pagenumberyPosI, sprintf('Page %d', page), ...
    'FontSize', pagenumberFontSizePt, 'HorizontalAlignment', 'right');

  figparams.page = page + 1;

  figparamsout = figparams;

%-------------------------------------------------------------------------
% Clean up

else

  % Clear persistent variables
  clear pagetitle subtitleL subtitleR figPosP figparams
  clear pagetitlexPosI pagesubtitleLxPos pagesubtitleRxPos
  clear pagenumberxPosI

end
