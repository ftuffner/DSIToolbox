function rguimgr(action1,action2,figNumber);

% RGUIMGR:  Implements most of the callbacks for the Graphical User
%           Interface to the BPA/PNNL Ringdown Analysis Tool.
%
% This is a helper function for the Ringdown Analysis Tool.  It is not
% normally used directly from the MATLAB command prompt.

% By Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date : November 1996
%
% Modification:
% 1. Mar. 20, 2003, add mode sorting function, Zhenyu (Henry) Huang 
% 2. Apr. 02, 2003, add sorting to the output # changes, Zhenyu (Henry) Huang
% 3. Apr. 03, 2003, add type names to sorting function and display them in the mode table, Zhenyu (Henry) Huang
% 4. Apr. 04, 2003, add one more option into the output number selection control for multi-signal setting, Zhenyu (Henry) Huang
% 5. Apr. 22, 2003, change default columns in the mode table, Zhenyu (Henry) Huang
% 6. Apr. 23, 2003, delete "multi-signal plots" control, Zhenyu (Henry) Huang
% 7. Apr. 28, 2003, sort by mode type as default, Zhenyu (Henry) Huang
% 8. May  20, 2003, "select all" in setup screen output menu, Zhenyu (Henry) Huang
% 9. May  20, 2003, safety check if signal number exceeds 20, Zhenyu (Henry) Huang
% 10.Jun  02, 2003, delete highlighting of sorting columns, Zhenyu (Henry) Huang
% 11.Jun  02, 2003, add "select all" function to pole submenu, Zhenyu (Henry) Huang
% 12.Jun  05, 2003, eliminate "unknown" mode type, Zhenyu (Henry) Huang
% 13.Jun  05, 2003, avoid redraw mode table twice when output # changes, Zhenyu (Henry) Huang
% 14.Jun  05, 2003, add "select all" function to mode selection in mode table, Zhenyu (Henry) Huang
% 15.Jun  05, 2003, add sorting by relative amplitude, Zhenyu (Henry) Huang
% 16.Jun  27, 2003, add legend for signal plots in setup screen, Zhenyu (Henry) Huang (disabled)
% 17.Aug  28, 2003, line width control for copying plots in setup screen, Zhenyu (Henry) Huang
% 18.Aug  28, 2003, add legend for copying plots in setup screen, Zhenyu (Henry) Huang
% 19.Oct  14, 2003, fix problem with line width, Zhenyu (Henry) Huang
% 20.Oct  09, 2012, fix for updated mexfile names and a nonexistence catch, Frank Tuffner
%
% Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% Print RCSID stamp and copyright
if nargin==1 & ischar(action1) & strcmp(action1,'rcsid')
  fprintf(1,['\n$Id$\n\n' ...
    'Copyright (c) 1995-2012 Battelle Memorial Institute.  The Government\n' ...
    'retains a paid-up nonexclusive, irrevocable worldwide license to\n' ...
    'reproduce, prepare derivative works, perform publicly and display\n' ...
    'publicly by or for the Government, including the right to distribute\n' ...
    'to other Government contractors.\n\n' ...
    'Date of last source code modification:  10/09/2012 (FKT)\n\n']);
  return
end

% Check for proper number of inputs
error(nargchk(2,3,nargin));

% Strings with property names and tags.
ButtonDownFcn      ='ButtonDownFcn';
CallBackObject     ='CallBackObject';
Checked            ='Checked';
Children           ='Children';
Color              ='Color';
ColorOrder         ='ColorOrder';
DAxesBox           ='DefaultAxesBox';
DAxesColor         ='DefaultAxesColor';
DAxesColorOrder    ='DefaultAxesColorOrder';
DAxesFontName      ='DefaultAxesFontName';
DAxesFontSize      ='DefaultAxesFontSize';
DAxesLineStyleOrder='DefaultAxesLineStyleOrder';
DAxesXColor        ='DefaultAxesXColor';
DAxesXGrid         ='DefaultAxesXGrid';
DAxesYColor        ='DefaultAxesYColor';
DAxesYGrid         ='DefaultAxesYGrid';
DTextColor         ='DefaultTextColor';
DTextFontName      ='DefaultTextFontName';
DTextFontSize      ='DefaultTextFontSize';
Enable             ='Enable';
HighlightColor     ='red';          % Highlight the sorting column. Henry, 04/03/03
Label              ='Label';
LineStyle          ='LineStyle';
LineWidth          ='LineWidth';
NextPlot           ='NextPlot';
OType              ='Type';
Pointer            ='Pointer';
Position           ='Position';
String             ='String';
Style              ='Style';
Tag                ='Tag';
Units              ='Units';
UserData           ='UserData';
Value              ='Value';
Visible            ='Visible';
XColor             ='XColor';
XData              ='XData';
XLim               ='XLim';
XTickLabel         ='XTickLabel';
YData              ='YData';
YLim               ='YLim';
YLimMode           ='YLimMode';

addstr             ='add';
ampstr             ='Amplitude';
arrowstr           ='arrow';
autostr            ='auto';
axeslinStyle       =':';
axesstr            ='axes';
dashstr            ='-';
dbstr              =' dB';
degstr             ='(deg)';
emptystr           ='';
ffstr              ='Feed-Forward Term = ';
figstr             ='figure';
framestr           ='frame';
frmylabstr         ='Magnitude (dB)';
frpylabstr         ='Phase (deg)';
frxlablstr         ='Frequency (Hz)';
newstr             ='new';
offstr             ='off';
onstr              ='on';
phsstr             ='Phase';
pixelstr           ='pixels';
psstr              ='%s';
rdrstr             ='-----';
relstr             ='Relative';
replacestr         ='replace';
snrstr             ='Signal/Noise Ratio = ';
spacestr           =' ';
textstr            ='text';
titlestr           ='title';
tzlinStyle         ='--';
watchstr           ='watch';
xlablstr           ='xlabel';
ylablstr           ='ylabel';

% Object tags
adctrlbtnTag      ='adctrlbtn';
adfrmlabbtnTag    ='adfrmlabbtn';
copmenuTag        ='copmenu';
copyfrTag         ='copyfr';
copymtTag         ='copymt';
copypzTag         ='copypz';
copytrTag         ='copytr';
displtbtnTag      ='displtbtn';
dsctrlTag         ='dsctrl';
dtinictrlTag      ='dtinictrl';
dtendctrlTag      ='dtendctrl';
etctrlTag         ='etctrl';
expmenuTag        ='expmenu';
fbctrlTag         ='fbctrl';
fcctrlTag         ='fcctrl';
ffctrlTag         ='ffctrl';
ffindTag          ='ffind';
filmenuTag        ='filmenu';
ftrhctrlTag       ='ftrhctrl';
ftrhctrl1Tag      ='ftrhctrl1';
ftrhctrl2Tag      ='ftrhctrl2';
ftrhindTag        ='ftrhind';
ftrlctrlTag       ='ftrlctrl';
ftrlctrl1Tag      ='ftrlctrl1';
ftrlctrl2Tag      ='ftrlctrl2';
ftrlindTag        ='ftrlind';
inpaxesTag        ='inpaxes';
lpactrlTag        ='lpactrl';
lpmctrlTag        ='lpmctrl';
lpoctrlTag        ='lpoctrl';
lpoctrl1Tag       ='lpoctrl1';
lpoctrl2Tag       ='lpoctrl2';
lpoindTag         ='lpoind';
%msigctrlTag       ='msigctrl';   % deleted by Henry. 04/23/03
mtblTag           ='mtbl';
mtcol2ctrlTag     ='mtcol2ctrl';
mtcol3ctrlTag     ='mtcol3ctrl';
mtcol4ctrlTag     ='mtcol4ctrl';
mtcol5ctrlTag     ='mtcol5ctrl';
mtpgctrlTag       ='mtpgctrl';
mtselctrlTag      ='mtselctrl';
npindTag          ='npind';
nqindTag          ='nqind';
ordctrlTag        ='ordctrl';
outmenuTag        ='outmenu';
outsubmenuTag     ='outsubmenu';
pabtnTag          ='pabtn';
polmenuTag        ='polmenu';
polsubmenuTag     ='polsubmenu';

allpolsubmenuTag   ='allpolsubmenu';      % Henry, 06/02/03

prfmenuTag        ='prfmenu';
pzxlinTag         ='pzxlin';
pzylinTag         ='pzylin';
rrctrlTag         ='rrctrl';
rscfctrlTag       ='rscfctrl';
rsdectrlTag       ='rsdectrl';
rsdtmodctrlTag    ='rsdtmodctrl';
rsfillctrlTag     ='rsfillctrl';
rsfiltctrlTag     ='rsfiltctrl';

rsDLIM1labTag     ='rsDLIM1lab';    % Henry, 03/25/03
rsDLIM1ctrlTag    ='rsDLIM1ctrl';   % Henry, 03/25/03
rsFLIM1labTag     ='rsFLIM1lab';    % Henry, 03/25/03
rsFLIM1ctrlTag    ='rsFLIM1ctrl';   % Henry, 03/25/03
rsFLIM2labTag     ='rsFLIM2lab';    % Henry, 03/25/03
rsFLIM2ctrlTag    ='rsFLIM2ctrl';   % Henry, 03/25/03
  
rsfraxs1Tag       ='rsfraxs1';
rsfraxs2Tag       ='rsfraxs2';
rsfrctrlTag       ='rsfrctrl';
rsfrctrl1Tag      ='rsfrctrl1';
rsfrctrl2Tag      ='rsfrctrl2';
rsfrmlabbtnTag    ='rsfrmlabbtn';
rsmenuTag         ='rsmenu';
rsoutctrlTag      ='rsoutctrl';
rspzaxesTag       ='rspzaxes';
rspzctrlTag       ='rspzctrl';
rspzxctrl1Tag     ='rspzxctrl1';
rspzxctrl2Tag     ='rspzxctrl2';
rspzyctrl1Tag     ='rspzyctrl1';
rspzyctrl2Tag     ='rspzyctrl2';
rstitctrlTag      ='rstitctrl';
rstraxesTag       ='rstraxes';
rstrctrl1Tag      ='rstrctrl1';
rstrctrl2Tag      ='rstrctrl2';
rswinctrlTag      ='rswinctrl';
scctrlTag         ='scctrl';
snrindTag         ='snrind';

sortctrlTag       ='sortctrl';      % Henry, 03/20/03

sscfctrlTag       ='sscfctrl';
ssdectrlTag       ='ssdectrl';
ssdtmodctrlTag    ='ssdtmodctrl';
ssfiltctrlTag     ='ssfiltctrl';
ssfraxs1Tag       ='ssfraxs1';
ssfraxs2Tag       ='ssfraxs2';
ssfrctrl1Tag      ='ssfrctrl1';
ssfrctrl2Tag      ='ssfrctrl2';
ssfrmlabbtnTag    ='ssfrmlabbtn';
ssfillctrlTag     ='ssfillctrl';
ssfrctrlTag       ='ssfrctrl';
ssmenuTag         ='ssmenu';
ssoutctrlTag      ='ssoutctrl';
sstitctrlTag      ='sstitctrl';
sstraxesTag       ='sstraxes';
sstrctrl1Tag      ='sstrctrl1';
sstrctrl2Tag      ='sstrctrl2';
sswinctrlTag      ='sswinctrl';
stctrlTag         ='stctrl';
tnpindTag         ='tnpind';
trrectrlTag       ='trrectrl';
trrectrl1Tag      ='trrectrl1';
trrectrl2Tag      ='trrectrl2';
trreindTag        ='trreind';
tsind1Tag         ='tsind1';
tsind2Tag         ='tsind2';
tzlinTag          ='tzlin';

if nargin<3; figNumber=gcf; end; ep=1e-6;

%============================================================================
% User changed setup screen control.
if action1==1

% action2 =  1 ==> Update everything using current control values.
% action2 =  2 ==> Update plots using current control values.
% action2 =  3 ==> Output submenu.
% action2 =  4 ==> Pole submenu.
% action2 =  5 ==> Setup screen output number control.
% action2 =  6 ==> Offset Time (data shift) control.
% action2 =  7 ==> End Time control.
% action2 =  8 ==> Setup screen detrend mode control.
% action2 =  9 ==> Detrend Initial Time control.
% action2 = 10 ==> Detrend End Time control.
% action2 = 11 ==> Time Zero Reference (start time) control.
% action2 = 12 ==> Decimate control.
% action2 = 13 ==> Normalize control.
% action2 = 14 ==> Full Calculation control.
% action2 = 15 ==> Residues Only control.
% action2 = 16 ==> Smoothing Filter control.
% action2 = 17 ==> Cutoff Frequency control.

  if action2==5
    outctrlHndl=gco; outctrlval=get(outctrlHndl,Value);
    if outctrlval==get(outctrlHndl,UserData); return; end
    set(outctrlHndl,UserData,outctrlval);
  else
    outctrlHndl=findobj(figNumber,Tag,ssoutctrlTag);
  end

  updatedttit=0; updatedtinet=0; updatedset=0; redraw=0; minnn=3;
  inpulses=get(findobj(figNumber,Tag,filmenuTag),UserData);
  ninputs=size(inpulses,1); if ninputs; delayf=inpulses(ninputs,1); end
  stctrlHndl=findobj(figNumber,Tag,stctrlTag); setupcon1=get(stctrlHndl,UserData);
  tstep=setupcon1(1); nnout=setupcon1(2); startindex=setupcon1(3);
  tstart=tstep*(startindex-1); df=setupcon1(4); dftstep=df*tstep; filtcf=setupcon1(5);
  fc=setupcon1(6); knwpol=setupcon1(7); fcknwpol=fc*knwpol; lpmcon=setupcon1(8);
  fbcon=setupcon1(9); lpomax=setupcon1(10); lpocon=setupcon1(11); ftrh=setupcon1(12);
  dectrlHndl=findobj(figNumber,Tag,ssdectrlTag); setupcon2=get(dectrlHndl,UserData);
  sigcon=size(setupcon2,2); actout=setupcon2(1,:); ds=setupcon2(2,:); ind0=isnan(ds);
  endindex=setupcon2(3,:); dtmodes=setupcon2(4,:); dtiniindex=setupcon2(5,:);
  dtendindex=setupcon2(6,:); filtout=setupcon2(7,:);
  actoutlist=find(actout); nnactout=length(actoutlist);
  outctrlval=get(outctrlHndl,Value); % curout=actoutlist(outctrlval);        %curout becomes a vector for multi-signal setting. Henry, 04/04/03
  if outctrlval == 1                % for multi-signal setting. Henry, 04/04/03
    curout = actoutlist;
    plotall = 1;
  else
    curout = actoutlist(outctrlval - 1);
    plotall = 0;
  end
  dsctrlHndl=findobj(figNumber,Tag,dsctrlTag);
  etctrlHndl=findobj(figNumber,Tag,etctrlTag);
  filtctrlHndl=findobj(figNumber,Tag,ssfiltctrlTag); filtmod=get(filtctrlHndl,Value);
  lpoctrlHndl=findobj(figNumber,Tag,lpoctrlTag);
  % plotall=get(findobj(figNumber,Tag,msigctrlTag),Value);        % ?? to be deleted. Henry. 04/23/03

  if action2==4 | action2==14 | action2==15
    fcctrlHndl=findobj(figNumber,Tag,fcctrlTag);
    rrctrlHndl=findobj(figNumber,Tag,rrctrlTag);
  end

  endindmax=startindex+df*(fix((nnout-startindex)/df)-fcknwpol);
  endind=min(endindmax,startindex+df*fix((endindex-startindex)/df));

  if any(ind0)
    minshift=zeros(1,nnz(ind0));
    if ninputs
      instep=startindex+df*fix(delayf/dftstep+ep)>=endind(ind0);
      ind1=find(ninputs-instep>0);
      minshift(ind1)=fix(inpulses(ninputs-instep(ind1),1)/dftstep+ep)+1;
    end
    ds(ind0)=minshift; ind0=~ind0;
  end
 
  if action2==1       % Update everything.

    updatedttit=1; updatedtinet=1; updatedset=1; redraw=1;

  elseif action2==2   % Update plots.

    redraw=1;

  elseif action2==3   % Output submenu.

    curmenu=get(0,CallBackObject); h=get(curmenu,Tag);
    curmenupos=eval(h(length(outsubmenuTag)+1:end));
    if curmenupos == 0 & strcmp(get(curmenu,Checked),offstr)          % select all signals. Henry, 05/20/03
      nactout = length(actout);
      actout(1:nactout)=1; actoutlist=find(actout);
      set(curmenu,Checked,onstr); 

      % check all other submenus
      for ii = 1:1000                % 1000 is the limti of signal numbers. should not be exceeded for real cases
        submenuTag = sprintf('%s%d',outsubmenuTag,ii);
        submenuHndl = findobj(figNumber,Tag,submenuTag); 
        if submenuHndl; set(submenuHndl,Checked,onstr); else break; end
      end
      
      if outctrlval == 1         % if multi-signal setting, then add the signal to the current output list. Henry, 04/07/03

        % use the current time ranges and detrend mode for this signal.
        ot=str2num(get(dsctrlHndl,String));                       % set initial time
        if ~isempty(ot) & all(~isnan(ds(curout)))
          ds(1:nactout) = max(fix(ot/dftstep),0); 
          ind0(1:nactout) = 1; 
        end
        tend=str2num(get(etctrlHndl,String));                     % set end time
        if ~isempty(tend) & all(~isnan(endindex(curout)))
          endindex(1:nactout) = min(floor((tend+tstart)/tstep+ep)+1,nnout);
          endind(1:nactout) = min(endindmax,startindex+df*fix((endindex(1:nactout)-startindex)/df));
        end
        dtmodctrlHndl = findobj(figNumber,Tag,ssdtmodctrlTag); dtmodes(1:nactout) = get(dtmodctrlHndl,Value)-1;    % set detrend mode
        dtinictrlHndl = findobj(figNumber,Tag,dtinictrlTag); dtinitim=str2num(get(dtinictrlHndl,String));
        if ~isempty(dtinitim) & all(~isnan(dtiniindex(curout))); dtiniindex(1:nactout) = max(floor((dtinitim+tstart)/tstep+ep)+1,1); end  % set detrend initial time
        dtendctrlHndl = findobj(figNumber,Tag,dtendctrlTag); dtendtim=str2num(get(dtendctrlHndl,String));
        if ~isempty(dtendtim) & all(~isnan(dtendindex(curout))); dtendindex(1:nactout) = min(floor((dtendtim+tstart)/tstep+ep)+1,nnout); end  % set detrend end time
        
        % update the current output numbers and set display update flags
        curout = actoutlist; 
        updatedttit=1; updatedtinet=1; updatedset=1; redraw=1;
      else                          % if not multi-signal setting, point to the multi-signal setting
        curout=actoutlist; outctrlval = 1; plotall = 1;  
        updatedttit=1; updatedtinet=1; updatedset=1; redraw=1;
      end
    elseif curmenupos == 0 & strcmp(get(curmenu,Checked),onstr)          % unselect all signals except the 1st one. Henry, 05/20/03
      if nnactout<2; return; end        % keep at least one signal be selected.

      nactout = length(actout);

      % reset all the time ranges and detrend mode before de-selecting the signal.
      ds(2:nactout) = 0; ind0(2:nactout) = 1;   % reset initial time
      endindex(2:nactout) = nnout; % reset end time  ??
      endind(2:nactout) = min(endindmax,startindex+df*fix((endindex(2:nactout)-startindex)/df));      % reset end index ??
      dtmodes(2:nactout) = 0;    % reset detrend mode
      dtiniindex(2:nactout) = NaN;   % set detrend initial time
      dtendindex(2:nactout) = NaN;  % set detrend end time

      % select the 1st signal, update the current output numbers and set display update flags
      actout(1)=1; actout(2:nactout)=0; actoutlist=find(actout);
      set(curmenu,Checked,offstr); 
      
      % uncheck all other submenus except the 1st one
      for ii = 2:1000                % 1000 is the limit of signal numbers. should not be exceeded for real cases
        submenuTag = sprintf('%s%d',outsubmenuTag,ii);
        submenuHndl = findobj(figNumber,Tag,submenuTag); 
        if submenuHndl; set(submenuHndl,Checked,offstr); else break; end
      end
      
      curout=actoutlist(1); outctrlval=2;
      updatedttit=1; updatedtinet=1; updatedset = 1; redraw=1;
    elseif actout(curmenupos)           % if it has been selected, then de-select it
      
      if nnactout<2; return; end        % keep at least one signal be selected.
      
      % uncheck the "All signals" submenu. Henry, 05/20/03
      submenuTag = sprintf('%s%d',outsubmenuTag,0);
      submenuHndl = findobj(figNumber,Tag,submenuTag); 
      set(submenuHndl,Checked,offstr);
            
      % reset all the time ranges and detrend mode before de-selecting the signal. Henry, 04/15/03
      ds(curmenupos) = 0; ind0(curmenupos) = 1;   % reset initial time
      endindex(curmenupos) = nnout; % reset end time  ??
      endind(curmenupos) = min(endindmax,startindex+df*fix((endindex(curmenupos)-startindex)/df));      % reset end index ??
      dtmodes(curmenupos) = 0;    % reset detrend mode
      dtiniindex(curmenupos) = NaN;   % set detrend initial time
      dtendindex(curmenupos) = NaN;  % set detrend end time

      % update the current output numbers and set display update flags
      actout(curmenupos)=0; actoutlist=find(actout);
      set(curmenu,Checked,offstr); %updatedset=1;   % put "updatedset" inside the "if" block
      if outctrlval == 1         % if multi-signal setting, then delete the signal from the current output list. Henry, 04/07/03
        curout = actoutlist; 
        updatedttit=1; updatedtinet=1; updatedset = 1; redraw=1;
      elseif curout==curmenupos         % if it is the current signal, then set the 1st selected signal as the current.
        curout=actoutlist(1); outctrlval=2;
        updatedttit=1; updatedtinet=1; updatedset = 1; redraw=1;
      else                          % if it is not the current signal, 
        outctrlval=find(curout==actoutlist) + 1;            % ?? no need % "+ 1" for multi-signal setting. Henry, 04/07/03
      end
    else                            % if it has not been selected, then select it
%      if nnactout>5; return; end

      % uncheck the "All signals" submenu. Henry, 05/20/03
      submenuTag = sprintf('%s%d',outsubmenuTag,0);
      submenuHndl = findobj(figNumber,Tag,submenuTag); 
      set(submenuHndl,Checked,offstr);

      actout(curmenupos)=1; actoutlist=find(actout);
      set(curmenu,Checked,onstr);
      if outctrlval == 1         % if multi-signal setting, then add the signal to the current output list. Henry, 04/07/03

        % use the current time ranges and detrend mode for this signal. Henry, 04/15/03
        ot=str2num(get(dsctrlHndl,String));                       % set initial time
        if ~isempty(ot) & all(~isnan(ds(curout)))
          ds(curmenupos) = max(fix(ot/dftstep),0); 
          ind0(curmenupos) = 1; 
        end
        tend=str2num(get(etctrlHndl,String));                     % set end time
        if ~isempty(tend) & all(~isnan(endindex(curout)))
          endindex(curmenupos) = min(floor((tend+tstart)/tstep+ep)+1,nnout);
          endind(curmenupos) = min(endindmax,startindex+df*fix((endindex(curmenupos)-startindex)/df));
        end
        dtmodctrlHndl = findobj(figNumber,Tag,ssdtmodctrlTag); dtmodes(curmenupos) = get(dtmodctrlHndl,Value)-1;    % set detrend mode
        dtinictrlHndl = findobj(figNumber,Tag,dtinictrlTag); dtinitim=str2num(get(dtinictrlHndl,String));
        if ~isempty(dtinitim) & all(~isnan(dtiniindex(curout))); dtiniindex(curmenupos) = max(floor((dtinitim+tstart)/tstep+ep)+1,1); end  % set detrend initial time
        dtendctrlHndl = findobj(figNumber,Tag,dtendctrlTag); dtendtim=str2num(get(dtendctrlHndl,String));
        if ~isempty(dtendtim) & all(~isnan(dtendindex(curout))); dtendindex(curmenupos) = min(floor((dtendtim+tstart)/tstep+ep)+1,nnout); end  % set detrend end time
        
        % update the current output numbers and set display update flags
        curout = actoutlist; 
        updatedttit=1; updatedtinet=1; updatedset=1; redraw=1;
      else                          % if not multi-signal setting, point to the selected signal
        curout=curmenupos; outctrlval=find(curout==actoutlist) + 1;   % "+ 1" for multi-signal setting. Henry, 04/07/03
        updatedttit=1; updatedtinet=1; updatedset=1; redraw=1;
      end
    end
    nnactout=length(actoutlist);
    h=sprintf('Output %d|',actoutlist); h=h(1:end-1);
    h=strcat('All selected outputs|', h);     %add "All outputs". Henry, 04/04/03
    set(outctrlHndl,String,h,Value,outctrlval,UserData,outctrlval);     

  elseif action2==4   % Pole submenu.

    curmenu=get(0,CallBackObject);
    polmenuHndl = findobj(figNumber,Tag,polmenuTag);
    identmodel=get(polmenuHndl,UserData);
    
    if get(curmenu,Position) == 2       % add "select all" function to pole submenu, Henry, 06/02/03
      if strcmp(get(curmenu,Checked),offstr)        % if "all poles" not checked 
        h2 = length(find(identmodel(:,2,1)<1e-8)) + 2*length(find(identmodel(:,2,1)>=1e-8));   % calculate # of poles. real poles count 1; complex poles count 2.
      else
        h2 = 0;
      end
      newknwpol = h2; if newknwpol > 128 | newknwpol == knwpol; return; end      
    else
      %frqrps=identmodel(get(curmenu,Position)-1,2,1);
      frqrps=identmodel(get(curmenu,Position)-2,2,1);     % for one more submenu "all poles" added. Henry, 06/02/03
      if abs(frqrps)<1e-8; h2=1; else; h2=2; end
      if strcmp(get(curmenu,Checked),onstr); h2=-h2; end
      newknwpol=knwpol+h2; if newknwpol>128; return; end
    end

    if newknwpol; h2=df*fc*h2; else; h2=df*h2; end; h=1;                    % ?????
    newendind=min(endindmax-h2,startindex+df*fix((endindex-startindex)/df));
    if any(newendind~=endind)
      if startindex+df*(ds+minnn+newknwpol-1)<=newendind
        ssvis=strcmp(get(outctrlHndl,Visible),onstr);
        if (newendind(curout)~=endind(curout) & ssvis) % | plotall        % ?? why plotall? Henry, 04/17/03
          updatedset=1; updatedtinet=1; redraw=1;
        end
        endind=newendind;
      else
        h=0;
      end
    end
    if h
      if knwpol<newknwpol; h2=onstr; else; h2=offstr; end
      knwpol=newknwpol; set(curmenu,Checked,h2);
      if get(curmenu,Position) == 2             % for "select all" function in pole submenu. Henry, 06/02/03
          set(findobj(polmenuHndl,Tag,polsubmenuTag),Checked,h2);
      else
          set(findobj(polmenuHndl,Position,2),Checked, offstr);
      end
    end

    if ~knwpol; set(fcctrlHndl,Value,1); set(rrctrlHndl,Value,0); fc=1; end

  elseif action2==5   % Output number control.

    updatedttit=1; updatedtinet=1; updatedset=1;
    if ~plotall; redraw=1; end
    if plotall; rguimgr(9, 3, figNumber); end               % for multi-signal setting. Henry, 04/07/03

  elseif action2==6   % Initial time (data shift) control.

    newot=str2num(get(dsctrlHndl,String));
    if ~isempty(newot)
      newds=max(fix(newot/dftstep),0) * ones(1, length(curout));    % "ones". Henry, 04/08/03
      if any(newds~=ds(curout))                      % ?? any change exists. Henry, 04/08/03
        if ninputs
          instep=startindex+df*fix(delayf/dftstep+ep)>=endind(curout);      % ??
          ind1 = find(ninputs-instep>0);                 % Henry, 04/08/03
          minshift = zeros(1, length(curout));           % Henry, 04/08/03
          minshift(ind1)=fix(inpulses(ninputs-instep(ind1),1)/dftstep+ep)+1;           % Henry, 04/08/03
          %if ninputs-instep>0
          %  minshift=fix(inpulses(ninputs-instep,1)/dftstep+ep)+1;
          %else
          %  minshift=0;
          %end
          newds=max(newds,minshift);
        end
        ind1 = find(startindex+df*(newds+minnn+fcknwpol-1)<=endind(curout));            % Henry, 04/08/03
        ds(curout(ind1)) = newds(ind1); ind0(curout(ind1)) = 1;                         % Henry, 04/08/03
        updatedset=1; redraw=1; if any(isnan(dtiniindex(curout))); updatedtinet=1; end  % Henry, 04/08/03
        %if startindex+df*(newds+minnn+fcknwpol-1)<=endind(curout)       % ??
        %  ds(curout)=newds; ind0(curout)=1;                             % ??
        %  updatedset=1; redraw=1; if isnan(dtiniindex(curout)); updatedtinet=1; end         % ??
        %end
      end
    end
    if ~updatedset
      if max(ds(curout)) == min(ds(curout))           % for multi-signal setting. Henry, 04/08/03
        set(dsctrlHndl,String,num2str(min(ds(curout))*dftstep));      % display the value same for all signals
      else
        set(dsctrlHndl,String,' ');                                   % display ' ' when not same
      end
      %set(dsctrlHndl,String,num2str(ds(curout)*dftstep));           % ??
    end

  elseif action2==7   % End time control.

    newtend=str2num(get(etctrlHndl,String));
    if ~isempty(newtend)
      newendindex=min(floor((newtend+tstart)/tstep+ep)+1,nnout) * ones(1, length(curout));    % "ones". Henry, 04/08/03
      if any(newendindex~=endindex(curout))                              % ?? any change exists. Henry, 04/08/03
        newendind=min(endindmax,startindex+df*fix((newendindex-startindex)/df));
        newds=ds(curout);                                           % ??
        if ninputs
          instep=startindex+df*fix(delayf/dftstep+ep)>=newendind;

          ind1 = find(ninputs-instep>0);                 % Henry, 04/08/03
          minshift = zeros(1, length(curout));           % Henry, 04/08/03
          minshift(ind1)=fix(inpulses(ninputs-instep(ind1),1)/dftstep+ep)+1;           % Henry, 04/08/03
          
          %if ninputs-instep>0
          %  minshift=fix(inpulses(ninputs-instep,1)/dftstep+ep)+1;
          %else
          %  minshift=0;
          %end
          newds=max(newds,minshift);
          
          ind1 = find(startindex+df*(newds+minnn+fcknwpol-1)>newendind);                % Henry, 04/08/03
          newds(ind1) = minshift(ind1);                                                 % Henry, 04/08/03
          % if startindex+df*(newds+minnn+fcknwpol-1)>newendind; newds=minshift; end
        end
        
        ind1 = find(startindex+df*(newds+minnn+fcknwpol-1)<=newendind);                 % Henry, 04/08/03
        endindex(curout(ind1))=newendindex(ind1); endind(curout(ind1))=newendind(ind1); ds(curout(ind1))=newds(ind1);     % Henry, 04/08/03
        updatedset=1; redraw=1; if any(isnan(dtiniindex(curout))); updatedtinet=1; end  % Henry, 04/08/03
        %if startindex+df*(newds+minnn+fcknwpol-1)<=newendind
        %  endindex(curout)=newendindex; endind(curout)=newendind; ds(curout)=newds;     % ??
        %  updatedset=1; redraw=1; if isnan(dtiniindex(curout)); updatedtinet=1; end     % ??
        %end
      end
    end
    if ~updatedset
      if max(endind(curout)) == min(endind(curout))           % for multi-signal setting. Henry, 04/08/03
        set(etctrlHndl,String,num2str(tstep*(min(endind(curout))-1)-tstart));     % display the value same for multi-signal setting
      else
        set(etctrlHndl,String,' ');                                               % display ' ' when not same
      end
      % set(etctrlHndl,String,num2str(tstep*(endind(curout)-1)-tstart));                  % ??
    end

  elseif action2==8   % Detrend mode control.

    dtmodctrlHndl=gco;
    dt=get(dtmodctrlHndl,Value)-1;
    if dt==5
      dtiniindex(curout)=NaN; dtendindex(curout)=NaN;                       % ??
      updatedtinet=1; set(dtmodctrlHndl,Value,min(dtmodes(curout)) * (min(dtmodes(curout)) == max(dtmodes(curout))) + 1);           % for multi-signal setting. Henry, 04/15/03
    else
      if dt==dtmodes(curout); return; end                                   % ??
      dtmodes(curout)=dt;                                                    % ??
    end
    redraw=1;

  elseif action2==9   % Detrend Initial Time control.

    updatedtinet=1;                             % update it anyway. Henry, 04/08/03
    newdtinitim=str2num(get(gco,String));
    if ~isempty(newdtinitim)
      newdtiniindex=max(floor((newdtinitim+tstart)/tstep+ep)+1,1) * ones(1, length(curout));    % "ones". Henry, 04/08/03
      
      newdtendindex = dtendindex(curout);               % Henry, 04/08/03
      ind1 = find(isnan(newdtendindex));                % Henry, 04/08/03
      newdtendindex(ind1) = endindex(curout(ind1));     % use endindex for those NaNs of dtendindex. Henry, 04/08/03
      %if isnan(dtendindex(curout))                      % ??
      %  newdtendindex=endindex(curout);                 % ??
      %else
      %  newdtendindex=dtendindex(curout);               % ??
      %end

      ind1 = find(newdtiniindex<=newdtendindex);        % Henry, 04/08/03
      dtiniindex(curout(ind1))=newdtiniindex(ind1); dtendindex(curout(ind1))=newdtendindex(ind1);     % Henry, 04/08/03
      if any(dtmodes(curout)>0); redraw=1; end                     % Henry, 04/08/03
      %if newdtiniindex<=newdtendindex
      %  dtiniindex(curout)=newdtiniindex; dtendindex(curout)=newdtendindex;     % ??
      %  updatedtinet=1; if dtmodes(curout)>0; redraw=1; end                     % ??
      %end
    end

  elseif action2==10  % Detrend End Time control.

    updatedtinet=1;                             % update it anyway. Henry, 04/08/03
    newdtendtim=str2num(get(gco,String));
    if ~isempty(newdtendtim)
      newdtendindex=min(floor((newdtendtim+tstart)/tstep+ep)+1,nnout) * ones(1, length(curout));    % "ones". Henry, 04/08/03
      
      newdtiniindex = dtiniindex(curout);                       % Henry, 04/08/03
      ind1 = find(isnan(newdtiniindex));                        % Henry, 04/08/03
      newdtiniindex(ind1) = startindex+df*ds(curout(ind1));     % Henry, 04/08/03
      %if isnan(dtiniindex(curout))                              % ??
      %  newdtiniindex=startindex+df*ds(curout);                 % ??
      %else
      %  newdtiniindex=dtiniindex(curout);                       % ??
      %end
      
      ind1 = find(newdtiniindex<=newdtendindex);                % Henry, 04/08/03
      dtiniindex(curout(ind1))=newdtiniindex(ind1); dtendindex(curout(ind1))=newdtendindex(ind1);     % Henry, 04/08/03
      if any(dtmodes(curout)>0); redraw=1; end                     % Henry, 04/08/03
      %if newdtiniindex<=newdtendindex
      %  dtiniindex(curout)=newdtiniindex; dtendindex(curout)=newdtendindex;     % ??
      %  updatedtinet=1; if dtmodes(curout)>0; redraw=1; end                     % ??
      %end
    end

  elseif action2==11  % Time zero reference (start time) control.

    newtstart=str2num(get(stctrlHndl,String));
    if ~isempty(newtstart)
      newstartindex=max(floor(newtstart/tstep+ep)+1,1);
      if newstartindex~=startindex
        h=newstartindex+df*(fix((nnout-newstartindex)/df)-fcknwpol);
        newendind=min(h,newstartindex+df*fix((endindex-newstartindex)/df));
        newds=ds; ind=find(ind0);
        newds(ind)=max(fix((startindex-newstartindex)/df)+ds(ind),0);
        if ninputs
          instep=newstartindex+df*fix(delayf/dftstep+ep)>=newendind;
          minshift=zeros(1,sigcon); ind1=find(ninputs-instep>0);
          minshift(ind1)=fix(inpulses(ninputs-instep(ind1),1)/dftstep+ep)+1;
          newds=max(newds,minshift);
          ind1=newstartindex+df*(newds+minnn+fcknwpol-1)>newendind;
          newds(ind1)=minshift(ind1);
        end
        if newstartindex+df*(newds+minnn+fcknwpol-1)<=newendind
          startindex=newstartindex; tstart=tstep*(startindex-1);
          ds=newds; endind=newendind;
          updatedset=1; updatedtinet=1; redraw=1;
        end
      end
    end
    set(stctrlHndl,String,num2str(tstart));

  elseif action2==12  % Decimate control.

    newdf=floor(str2num(get(dectrlHndl,String)));
    if ~isempty(newdf)
      if newdf<1; newdf=1; end
      if newdf~=df
        h=startindex+newdf*(fix((nnout-startindex)/newdf)-fcknwpol);
        newendind=min(h,startindex+newdf*fix((endindex-startindex)/newdf));
        newds=fix(df/newdf*ds); newdftstep=newdf*tstep;
        if ninputs
          instep=startindex+newdf*fix(delayf/newdftstep+ep)>=newendind;
          minshift=zeros(1,sigcon); ind1=find(ninputs-instep>0);
          minshift(ind1)=fix(inpulses(ninputs-instep(ind1),1)/newdftstep+ep)+1;
          newds=max(newds,minshift);
          ind1=startindex+newdf*(newds+minnn+fcknwpol-1)>newendind;
          newds(ind1)=minshift(ind1);
        end
        if startindex+newdf*(newds+minnn+fcknwpol-1)<=newendind
          df=newdf; dftstep=newdftstep; ds=newds; endind=newendind;
          ftrhd=1/(3*dftstep); nyqs=num2str(1/(2*dftstep)); ftrhds=num2str(ftrhd);
          set(findobj(figNumber,Tag,tsind2Tag),String,num2str(dftstep));
          set(findobj(figNumber,Tag,nqindTag),String,nyqs);
          set(findobj(figNumber,Tag,ftrhindTag),String,ftrhds);
          if get(findobj(figNumber,Tag,ftrhctrl1Tag),Value)
            ftrh=ftrhd;
            set(findobj(figNumber,Tag,ftrhctrlTag),String,ftrhds);
          end
          updatedset=1; updatedtinet=1; redraw=1;
        end
      end
    end
    set(dectrlHndl,String,int2str(df));

  elseif action2==13  % Normalize control.

    redraw=1;

  elseif action2==14 | action2==15  % Full Calculation or Residues Only control.

    if action2==14
      if fc; set(fcctrlHndl,Value,1); return; end; h2=df*knwpol;
    else
      if ~fc; set(rrctrlHndl,Value,1); return; end
      if ~knwpol; set(rrctrlHndl,Value,0); return; end; h2=-df*knwpol;
    end
    newendind=min(endindmax-h2,startindex+df*fix((endindex-startindex)/df)); h=1;
    if any(newendind~=endind)
      if startindex+df*(ds+minnn+(1-fc)*knwpol-1)<=newendind
        endind=newendind; updatedset=1; updatedtinet=1; redraw=1;
      else
        h=0;
      end
    end
    if action2==14
      if h; set(rrctrlHndl,Value,0); fc=1; else; set(fcctrlHndl,Value,0); end
    else
      if h; set(fcctrlHndl,Value,0); fc=0; else; set(rrctrlHndl,Value,0); end
    end

  elseif action2==16  % Smoothing filter control.

    redraw=1;

  elseif action2==17  % Filter cutoff frequency control.

    sscfctrlHndl=gco;
    newfiltcf=str2num(get(sscfctrlHndl,String));
    if ~isempty(newfiltcf)
      if newfiltcf>0
        filtcf=newfiltcf; filtout=zeros(1,sigcon);
        if filtmod; redraw=1; end
      end
    end
    set(sscfctrlHndl,String,num2str(filtcf));

  end

  if updatedttit
%    disp(' action1 == 1: updatedttit. Henry')
    if outctrlval == 1              % for multi-signal setting. Henry, 04/08/03
%      disp('      action1 == 1: outctrlval == 1. Henry')
      dtm = min(dtmodes(curout)) * (max(dtmodes(curout)) == min(dtmodes(curout))) + 1;  % if all detrend modes are same, display it. or display "no detrend"
      set(findobj(figNumber,Tag,ssdtmodctrlTag), Value, dtm);                       % detrend mode display
      set(findobj(figNumber,Tag,sstitctrlTag), String, 'All selected outputs', Enable, offstr);        % disable signal title control
    else
      set(findobj(figNumber,Tag,ssdtmodctrlTag),Value,dtmodes(curout)+1);             
      outsubmenuHndl=findobj(figNumber,Tag,sprintf('%s%d',outsubmenuTag,curout));     
      set(findobj(figNumber,Tag,sstitctrlTag),String,get(outsubmenuHndl,UserData), Enable, onstr);   % enable title control. Henry, 04/08/03
    end
  end

  if updatedset
%    disp(' action1 == 1: updatedset. Henry')
%    curout          % for debug only
    % set(dsctrlHndl,String,num2str(ds(curout)*dftstep));
    if max(ds(curout)) == min(ds(curout))           % for multi-signal setting. Henry, 04/08/03
      set(dsctrlHndl,String,num2str(min(ds(curout))*dftstep));      % display the value same for all signals
    else
      set(dsctrlHndl,String,' ');                                   % display ' ' when not same
    end
    % set(etctrlHndl,String,num2str(tstep*(endind(curout)-1)-tstart));
    if max(endind(curout)) == min(endind(curout))           % for multi-signal setting. Henry, 04/08/03
      set(etctrlHndl,String,num2str(tstep*(min(endind(curout))-1)-tstart));     % display the value same for all signals
    else
      set(etctrlHndl,String,' ');                                               % display ' ' when not same
    end

    nnfit=(endind(actoutlist)-startindex)/df-ds(actoutlist)+1; tnnfit=sum(nnfit);
    if outctrlval == 1                                      % for multi-signal setting. Henry, 04/07/03
      if max(nnfit) == min(nnfit)                           % if all have the smae data points, display it
          set(findobj(figNumber,Tag,npindTag),String, int2str(min(nnfit)));        
      else                                                  % otherwise display nothing
          set(findobj(figNumber,Tag,npindTag),String, ' ');        
      end
    else    
      %set(findobj(figNumber,Tag,npindTag),String,int2str(nnfit(outctrlval)));
      set(findobj(figNumber,Tag,npindTag),String,int2str(nnfit(outctrlval - 1)));     % for multi-signal setting. Henry, 04/07/03
    end
    set(findobj(figNumber,Tag,tnpindTag),String,int2str(tnnfit));
    lpomax=floor(max(nnfit)/2); if lpomax+knwpol>127; lpomax=127-knwpol; end
    set(findobj(figNumber,Tag,lpoindTag),String,int2str(floor(11*lpomax/12)));
    if get(findobj(figNumber,Tag,lpoctrl1Tag),Value) | lpocon>lpomax
      lpocon=lpomax; set(lpoctrlHndl,String,int2str(lpocon));
    end
  end

  if updatedtinet
%    disp(' action1 == 1: updatedtinet. Henry')
    if outctrlval == 1                              % for multi-signal setting. Henry, 04/08/03

      dtinictrlHndl=findobj(figNumber,Tag,dtinictrlTag);      % detrend initial time control
      
      dtiniindexdisp = dtiniindex(curout);      % detrend initial time, only for display. Henry, 04/16/03
      ind1 = find(isnan(dtiniindexdisp));       % find NaNs 
      dtiniindexdisp(ind1) = startindex+df*ds(curout(ind1));   % use ds for NaNs
      if max(dtiniindexdisp) == min(dtiniindexdisp)   % if all have the same initial time, display it
        dtiniind=startindex+df*fix((min(dtiniindexdisp)-startindex)/df);      
        set(dtinictrlHndl,String,num2str(tstep*(dtiniind-1)-tstart));
      else                                                    % otherwise, display nothing
        set(dtinictrlHndl,String, ' ');
      end

      dtendctrlHndl=findobj(figNumber,Tag,dtendctrlTag);      % detrend end time control

      dtendindexdisp = dtendindex(curout);  % detrend end time, only for display. Henry, 04/16/03
      ind1 = find(isnan(dtendindexdisp));       % find NaNs 
      dtendindexdisp(ind1) = endindex(curout(ind1));   % use endind for NaNs
      if max(dtendindexdisp) == min(dtendindexdisp)   % if all have the same end time, display it
        dtendind=startindex+df*fix((min(dtendindexdisp)-startindex)/df);      
        set(dtendctrlHndl,String,num2str(tstep*(dtendind-1)-tstart));
      else                                                    % otherwise, display nothing
        set(dtendctrlHndl,String, ' ');
      end        
    else
      if isnan(dtiniindex(curout))             
        dtiniind=startindex+df*ds(curout);      
        dtendind=endind(curout);                
      else
        dtiniind=startindex+df*fix((dtiniindex(curout)-startindex)/df);    
        dtendind=startindex+df*fix((dtendindex(curout)-startindex)/df);      
      end
      dtinictrlHndl=findobj(figNumber,Tag,dtinictrlTag);
      set(dtinictrlHndl,String,num2str(tstep*(dtiniind-1)-tstart));
      dtendctrlHndl=findobj(figNumber,Tag,dtendctrlTag);
      set(dtendctrlHndl,String,num2str(tstep*(dtendind-1)-tstart));
    end
  end

  setupcon1(3)=startindex; setupcon1(4)=df; setupcon1(5)=filtcf; setupcon1(6)=fc;
  setupcon1(7)=knwpol; setupcon1(8)=lpmcon; setupcon1(9)=fbcon;
  setupcon1(10)=lpomax; setupcon1(11)=lpocon; setupcon1(12)=ftrh;
  set(stctrlHndl,UserData,setupcon1); ind=find(ind0);
  setupcon2(1,:)=actout; setupcon2(2,ind)=ds(ind); setupcon2(3,:)=endindex;
  setupcon2(4,:)=dtmodes; setupcon2(5,:)=dtiniindex;
  setupcon2(6,:)=dtendindex; setupcon2(7,:)=filtout;
  set(dectrlHndl,UserData,setupcon2);

  if redraw & strcmp(get(lpoctrlHndl,Visible),offstr);
    traxesHndl=findobj(figNumber,OType,axesstr,Tag,sstraxesTag);
    axes(traxesHndl); set(figNumber,Pointer,watchstr);
    linHndls=get(traxesHndl,UserData); startindexd=fix((startindex-1)/df)+1;
    if action2~=6 & action2~=7 | any(dtmodes(curout).*isnan(dtiniindex(curout)))          % ??
      ind0=startindex-df*fix((startindex-1)/df):df:nnout; timdat=tstep*(ind0-1)'-tstart;
      if plotall
        outdats=zeros(size(timdat,1),nnactout); inilintim=zeros(2,nnactout);
        endlintim=inilintim; inilindat=inilintim; endlindat=inilintim;
        if action2<4 | action2>10
          ind1=1:nnactout; ind2=actoutlist;
        else
          for ii=[1:1:nnactout]                            % ?? for multi-signal setting. Henry, 04/07/03
          %for ii=[1:outctrlval-1 outctrlval+1:nnactout]      ?? why skip one signal
            outdats(:,ii)=get(linHndls(ii,1),YData)';
            inilintim(:,ii)=get(linHndls(ii,2),XData)';
            endlintim(:,ii)=get(linHndls(ii,3),XData)';
            inilindat(:,ii)=get(linHndls(ii,2),YData)';
            endlindat(:,ii)=get(linHndls(ii,3),YData)';
          end
          %ind1=outctrlval; ind2=curout;                             % ??
          ind1=1:nnactout; ind2=actoutlist;                 % for multi-signal setting, Henry, 04/15/03
        end
      else
        outdats=zeros(size(timdat,1),1); inilintim=zeros(2,1);
        endlintim=inilintim; inilindat=inilintim; endlindat=inilintim;
        ind1=1; ind2=curout;                                        % ??
      end
      dsd=ds(ind2); endindexd=startindexd+fix((endindex(ind2)-startindex)/df);
      dtmodesd=dtmodes(ind2); nncalc=length(ind1);
      outdat=get(findobj(figNumber,Tag,outmenuTag),UserData);
      if filtmod
        if any(filtout); filtoutdat=get(filtctrlHndl,UserData); end
        ind=find(actout&~filtout);
        if ~isempty(ind)
          newfiltout=filtout|actout; newfiltoutdat=zeros(nnout,nnz(newfiltout));
          filtind=~filtout(find(newfiltout));
          newfiltoutdat(:,find(filtind))=rguifilt(outdat(:,ind+1),tstep,filtcf);
          if any(filtout); newfiltoutdat(:,find(~filtind))=filtoutdat; end
          filtoutdat=newfiltoutdat; filtout=newfiltout;
          set(filtctrlHndl,UserData,filtoutdat);
        end
        filtoutlist=find(filtout);
        if nncalc>1
          ind=zeros(1,nnactout);
          for ii=1:nnactout; ind(ii)=find(actoutlist(ii)==filtoutlist); end
        else
          ind=find(curout==filtoutlist);                        % ??
        end
        outdats(:,ind1)=filtoutdat(ind0,ind);
      else
        outdats(:,ind1)=outdat(ind0,ind2+1);                % ??
      end
      if any(dtmodesd)
        dtiniindexd=startindexd+fix((dtiniindex(ind2)-startindex)/df);
        dtendindexd=startindexd+fix((dtendindex(ind2)-startindex)/df);
        ind=find(isnan(dtiniindexd));
        dtiniindexd(ind)=startindexd+dsd(ind); 
        ind=find(isnan(dtendindexd));           % find NaN in dtendindexd. Henry, 04/24/03
        dtendindexd(ind)=endindexd(ind);
        outdats(:,ind1)=rguidt(outdats(:,ind1),dtiniindexd,dtendindexd,dtmodesd);
      end
      if get(findobj(figNumber,Tag,scctrlTag),Value)        % normalize signals. modified to avoid dividing by 0. Henry, 04/23/03
        scfac=0;
        for ii=1:nncalc
          scfac=max(abs(outdats(startindexd+dsd(ii):endindexd(ii),ind1(ii))));
          if scfac ~= 0; outdats(:,ind1(ii))=outdats(:,ind1(ii))/scfac; end
        end
      end
%      if get(findobj(figNumber,Tag,scctrlTag),Value)        % normalize signals
%        scfac=zeros(nncalc);
%        for ii=1:nncalc
%          scfac(ii,ii)=max(abs(outdats(startindexd+dsd(ii):endindexd(ii),ind1(ii))));
%        end
%        outdats(:,ind1)=outdats(:,ind1)/scfac;
%      end

      tzlindat=outdats(startindexd,1)*[1 1]; nnsigs=size(outdats,2);
      for ii=1:nncalc
        ind1a=ind1(ii);
        inilintim(1:2,ind1a)=[1; 1]*timdat(startindexd+dsd(ii));
        endlintim(1:2,ind1a)=[1; 1]*timdat(endindexd(ii));
        inilindat(1:2,ind1a)=[1; 1]*outdats(startindexd+dsd(ii),ind1a);
        endlindat(1:2,ind1a)=[1; 1]*outdats(endindexd(ii),ind1a);
      end
      axesForeColor=get(traxesHndl,XColor); set(traxesHndl,YLimMode,autostr);
      linHndls=zeros(nnsigs,3); linHndls(:,1)=plot(timdat,outdats);             % plot
      clrs=get(findobj(figNumber,Tag,prfmenuTag),UserData); h=size(clrs,1)-3;
      nncolors = size(clrs, 1); % number of colors, Henry, 08/29/03
      legendStr = [];           % legend, Henry, 06/27/03
%      legendStr1 = [];           % legend, Henry, 06/30/03
      for ii=1:nnsigs;
          lineW = 0.5+floor((ii-1)/nncolors); if lineW>4; lineW = 1; end                 % calculate line width. Henry, 06/27/03
          set(linHndls(ii,1),Color,clrs(rem(ii,h)+3,:), 'LineWidth', lineW);    % set color and line width (for same color). Henry, 06/27/03
%          set(linHndls(ii,1),Color,clrs(rem(ii,h)+3,:)); 
          legendStr0 = sprintf('Output %3d',ii); legendStr = [legendStr; legendStr0];            % legend, Henry, 06/27/03
%          legendStr1 = strcat(legendStr1, legendStr0, '|');            % legend list, Henry, 06/30/03
      end               % get line handles: 1st field
      if nnsigs < 20; legendLen = nnsigs; else; legendLen = 20; end     % legend, Henry, 06/27/03
%      legend(linHndls(1:legendLen,1),legendStr(1:legendLen,:));            % legend, Henry, 06/27/03
%      set(findobj(figNumber, Tag, 'sslegend'), String, legendStr1);               % Legend list, Henry, 06/30/03
      linHndls(:,2)=line(inilintim,inilindat,Color,axesForeColor,LineStyle,dashstr);    % draw start line: 2nd field
      linHndls(:,3)=line(endlintim,endlindat,Color,axesForeColor,LineStyle,dashstr);    % draw end line: 3rd field
      line([0 0],tzlindat,Tag,tzlinTag, ...
        Color,axesForeColor,LineStyle,tzlinStyle,UserData,tzlindat);
      set(gca,Tag,sstraxesTag,UserData,linHndls);
    else
      if plotall; ind2=1:nnactout; else; ind2=1; end                        % ?? for multi-signal setting. Henry, 04/15/03

      legendStr = [];           % legend, Henry, 06/27/03
      endindexd = startindexd+fix((endindex(curout)-startindex)/df);        % ?? end index 
      for ii = 1:length(ind2)                                               % for multi-signal setting. Henry, 04/15/03
          timdat=get(linHndls(ind2(ii),1),XData); outdats=get(linHndls(ind2(ii),1),YData);      % get line handles: 1st field
        set(linHndls(ind2(ii),2), ...
          XData,[1 1]*timdat(startindexd+ds(curout(ii))), ...     % ?? set line handles: 2nd field
          YData,[1 1]*outdats(startindexd+ds(curout(ii))));       % ??
        set(linHndls(ind2(ii),3), ...
          XData,[1 1]*timdat(endindexd(ii)), ...                  % ?? set line handles: 3rd field
          YData,[1 1]*outdats(endindexd(ii)));                    % ??

        legendStr0 = sprintf('Output %3d',ii); legendStr = [legendStr; legendStr0];            % legend, Henry, 06/27/03
      end
      if length(ind2) < 20; legendLen = length(ind2); else; legendLen = 20; end     % legend, Henry, 06/27/03
%      legend(linHndls(1:legendLen,1),legendStr(1:legendLen,:));            % legend, Henry, 06/27/03
    end
  end

  if redraw
    sstrctrl1Hndl=findobj(figNumber,Tag,sstrctrl1Tag);      % time response lower limit
    pltctrls=get(sstrctrl1Hndl,UserData);
    if plotall
      %pltctrls(1,2)=startindex; pltctrls(2,2)=max(endindex(actoutlist));  
      pltctrls(1,2)=startindex+df*min(ds(actoutlist)); pltctrls(2,2)=max(endindex(actoutlist));     % Get the minimum start point. Henry, 04/14/03
    else
      pltctrls(1,2)=startindex+df*ds(curout); pltctrls(2,2)=endindex(curout);   % ??
    end
    pltctrls(4,2)=1/(2*dftstep); set(sstrctrl1Hndl,UserData,pltctrls);
    rguimgr(2,1,figNumber); set(figNumber,Pointer,arrowstr);
  end

  return;

%============================================================================
% Set the limits on the time response plots for the setup screen.
% Draw the Fourier analysis plots.
elseif action1==2

% action2==1 ==> Set the plot axis limits normally.  Update Fourier plots.
% action2==2 ==> Time response lower plot limit control.
% action2==3 ==> Time response upper plot limit control.
% action2==4 ==> Time response Reset button.
% action2==5 ==> Frequency spectrum lower plot limit control.
% action2==6 ==> Frequency spectrum upper plot limit control.
% action2==7 ==> Frequency spectrum Reset button.
% aciton2==8 ==> Left Fill or Hanning window control.

  redraw=0; updatetrlim=0; updatefrlim=0;
  trctrl1Hndl=findobj(figNumber,Tag,sstrctrl1Tag);
  pltctrls=get(trctrl1Hndl,UserData);
  trindex1=pltctrls(1,1); trindex2=pltctrls(2,1);
  if isnan(trindex1); trindex1=pltctrls(1,2); trindex2=pltctrls(2,2); end
  frlim1=pltctrls(3,1); frlim2=pltctrls(4,1);
  if isnan(frlim1); frlim1=pltctrls(3,2); frlim2=pltctrls(4,2); end
  setupcon1=get(findobj(figNumber,Tag,stctrlTag),UserData);
  tstep=setupcon1(1); nnout=setupcon1(2); startindex=setupcon1(3);
  tstart=tstep*(startindex-1); df=setupcon1(4); dftstep=df*tstep;

  if action2==1

    redraw=1; updatetrlim=1; updatefrlim=1;

  elseif action2==2  % Time response lower plot limit control.

    newtrlim1=str2num(get(gco,String));
    if ~isempty(newtrlim1)
      newtrindex1=max(floor((newtrlim1+tstart)/tstep+ep)+1,1);
      if newtrindex1<=trindex2
        trindex1=newtrindex1; pltctrls(1,1)=trindex1;
        pltctrls(2,1)=trindex2; redraw=1; updatetrlim=1;
      end
    end
    if ~updatetrlim
      set(gco,String,num2str(dftstep*fix((trindex1-startindex)/df)));
    end

  elseif action2==3  % Time response upper plot limit control.

    newtrlim2=str2num(get(gco,String));
    if ~isempty(newtrlim2)
      newtrindex2=min(floor((newtrlim2+tstart)/tstep+ep)+1,nnout);
      if trindex1<=newtrindex2
        trindex2=newtrindex2; pltctrls(2,1)=trindex2;
        pltctrls(1,1)=trindex1; redraw=1; updatetrlim=1;
      end
    end
    if ~updatetrlim
      set(gco,String,num2str(dftstep*fix((trindex2-startindex)/df)));
    end

  elseif action2==4  % Time response Reset button.

    if isnan(pltctrls(1,1)); return; end
    pltctrls(1,1)=NaN; pltctrls(2,1)=NaN;
    trindex1=pltctrls(1,2); trindex2=pltctrls(2,2);
    redraw=1; updatetrlim=1;

  elseif action2==5  % Frequency spectrum lower plot limit control.

    newfrlim1=str2num(get(gco,String));
    if ~isempty(newfrlim1)
      if newfrlim1<frlim2
        frlim1=max(newfrlim1,0); pltctrls(3,1)=frlim1;
        pltctrls(4,1)=frlim2; redraw=1; updatefrlim=1;
      end
    end
    if ~updatefrlim; set(gco,String,num2str(frlim1)); end

  elseif action2==6  % Frequency spectrum upper plot limit control.

    newfrlim2=str2num(get(gco,String)); updatefrlim=1;
    if ~isempty(newfrlim2)
      if newfrlim2>frlim1
        frlim2=min(newfrlim2,pltctrls(4,2)); pltctrls(4,1)=frlim2;
        pltctrls(3,1)=frlim1; redraw=1;
      end
    end
    if ~updatefrlim; set(gco,String,num2str(frlim2)); end

  elseif action2==7  % Frequency spectrum Reset button.

    if isnan(pltctrls(3,1)); return; end
    pltctrls(3,1)=NaN; pltctrls(4,1)=NaN;
    frlim1=pltctrls(3,2); frlim2=pltctrls(4,2);
    redraw=1; updatefrlim=1;

  elseif action2==8  % Left Fill or Hanning window control.

    redraw=1;

  end

  set(trctrl1Hndl,UserData,pltctrls);
  trind1=startindex+df*fix((trindex1-startindex)/df);
  trind2=startindex+df*fix((trindex2-startindex)/df);
  trlim1=tstep*(trind1-1)-tstart; trlim2=tstep*(trind2-1)-tstart;

  if updatetrlim
    set(trctrl1Hndl,String,num2str(trlim1));
    set(findobj(figNumber,Tag,sstrctrl2Tag),String,num2str(trlim2));
  end

  if updatefrlim
    set(findobj(figNumber,Tag,ssfrctrl1Tag),String,num2str(frlim1));
    set(findobj(figNumber,Tag,ssfrctrl2Tag),String,num2str(frlim2));
  end

  if redraw & strcmp(get(findobj(figNumber,Tag,lpoctrlTag),Visible),offstr)
    traxesHndl=findobj(figNumber,Tag,sstraxesTag,OType,axesstr);
    linHndls=get(traxesHndl,UserData); nnsigs=size(linHndls,1);
    if action2<5
      if ~isempty(get(findobj(figNumber,Tag,filmenuTag),UserData))
        set(findobj(figNumber,Tag,inpaxesTag,OType,axesstr),XLim,[trlim1 trlim2]);
      end
      tzlinHndl=findobj(traxesHndl,Tag,tzlinTag);
      set(tzlinHndl,YData,get(tzlinHndl,UserData));
      inilindat=zeros(nnsigs,1); endlindat=inilindat;
      for ii=1:nnsigs
        inilindat(ii)=sum(get(linHndls(ii,2),YData))/2;
        set(linHndls(ii,2),YData,[1 1]*inilindat(ii));
        endlindat(ii)=sum(get(linHndls(ii,3),YData))/2;
        set(linHndls(ii,3),YData,[1 1]*endlindat(ii));
      end
      set(traxesHndl,YLimMode,autostr,XLim,[trlim1 trlim2]); % drawnow;
      axesYLim=get(traxesHndl,YLim); set(tzlinHndl,YData,axesYLim);
      axesYRngd=[-1 1]*(axesYLim(2)-axesYLim(1))/20;
      for ii=1:nnsigs
        set(linHndls(ii,2),YData,inilindat(ii)+axesYRngd);
        set(linHndls(ii,3),YData,endlindat(ii)+axesYRngd);
      end
      set(traxesHndl,YLim,axesYLim);
    end
    if get(findobj(figNumber,Tag,ssfrctrlTag),Value)
      fraxs1Hndl=findobj(figNumber,Tag,ssfraxs1Tag,OType,axesstr);
      fraxs2Hndls=findobj(figNumber,Tag,ssfraxs2Tag);
      fraxs2Hndl=findobj(fraxs2Hndls,OType,axesstr);
      if action2<5 | action2==8
        ind0=fix((trind1-1)/df)+1:fix((trind2-1)/df)+1;
        outdats=zeros(length(ind0),nnsigs);
        for ii=1:nnsigs; h=get(linHndls(ii,1),YData); outdats(:,ii)=h(ind0)'; end
        fillmod=get(findobj(figNumber,Tag,ssfillctrlTag),Value);
        winmod=get(findobj(figNumber,Tag,sswinctrlTag),Value);
        [fftr,ffti,frqdat]=rguifft(outdats,df*tstep,fillmod,winmod);
        [magdat,phsdat]=tranfrq0([],[],[],[],[],frqdat,fftr,ffti);
        linHndls=zeros(nnsigs,2);
        axes(fraxs1Hndl); linHndls(:,1)=plot(frqdat,magdat); fraxs1Hndl=gca;    % plot magnitudes
        set(fraxs1Hndl,Tag,ssfraxs1Tag,UserData,linHndls(:,1),XTickLabel,[]);
        axes(fraxs2Hndl); linHndls(:,2)=plot(frqdat,phsdat); fraxs2Hndl=gca;    % plot phases
        set(fraxs2Hndl,Tag,ssfraxs2Tag,UserData,linHndls(:,2));
        clrs=get(findobj(figNumber,Tag,prfmenuTag),UserData); h=size(clrs,1)-3;
        %for ii=1:nnsigs; set(linHndls(ii,1),Color,clrs(rem(ii,h)+3,:)); end
        for ii=1:nnsigs; 
%            set(linHndls(ii,1),Color,clrs(rem(ii,h)+3,:)); 
            lineW = 0.5+floor((ii-1)/6); if lineW>4; lineW = 1; end                 % calculate line width. Henry, 06/27/03
            set(linHndls(ii,1),Color,clrs(rem(ii,h)+3,:), 'LineWidth', lineW);    % set color and line width (for same color). Henry, 06/27/03
%            set(linHndls(ii,2),Color,clrs(rem(ii,h)+3,:)); 
            set(linHndls(ii,2),Color,clrs(rem(ii,h)+3,:), 'LineWidth', lineW);    % set color and line width (for same color). Henry, 06/27/03 
        end  % make the phase plots visible. Henry, 04/16/03
      end
      set([fraxs1Hndl fraxs2Hndl],XLim,[frlim1 frlim2]);
    end
  end

  return;

%============================================================================
% Mode table parameter.
elseif action1==3

% action2==1 ==> Mode table mode parameter.
% action2==2 ==> Select All button.
% action2==3 ==> Deselect All button.
% action2==4 ==> Cancel button.

  mtblHndl=findobj(figNumber,Tag,mtblTag,OType,axesstr);
  mttextHndls=get(mtblHndl,UserData);
  vcells=size(mttextHndls,1)-3; mtselctrls=findobj(figNumber,Tag,mtselctrlTag);
  selctrlvis=strcmp(get(mtselctrls(1),Visible),onstr);
  clrs=get(findobj(figNumber,Tag,prfmenuTag),UserData);
  polmenuHndl=findobj(figNumber,Tag,polmenuTag); identmodel=get(polmenuHndl,UserData);
  outctrlval=get(findobj(figNumber,Tag,rsoutctrlTag),Value);                                % select output to display
  prowof=vcells*(get(findobj(figNumber,Tag,mtpgctrlTag),Value)-1);                          % page #

  if action2==1
    h=gco; if ~strcmp(get(h,OType),textstr); return; end
    textPos=get(h,Position); textind=floor((vcells+4)*textPos(2));
    rowind=prowof+vcells-textind+1;
    if strcmp(get(figNumber,'SelectionType'),'extend')                  % ???
      if selctrlvis
        seltext=get(mttextHndls(1,1),UserData);
      else
        delete(get(findobj(figNumber,Tag,rstraxesTag,OType,axesstr),Children));
        delete(get(findobj(figNumber,Tag,rsfraxs1Tag,OType,axesstr),Children));
        delete(get(findobj(figNumber,Tag,rsfraxs2Tag,OType,axesstr),Children));
        delete(get(findobj(figNumber,Tag,rspzaxesTag,OType,axesstr),Children));
        menuList=findobj(figNumber,OType,'uimenu',Enable,onstr);
        ctrlList=findobj(figNumber,OType,'uicontrol',Visible,onstr);
        set(menuList,Enable,offstr); set(ctrlList,Visible,offstr);
        set(findobj(figNumber,Tag,ffindTag),Visible,offstr);
        set(findobj(figNumber,Tag,snrindTag),Visible,offstr);
        set(mtselctrls,Visible,onstr); seltext=zeros(vcells,1);
        set(findobj(mtselctrls,Style,framestr),UserData,menuList);
        set(findobj(mtselctrls,Style,textstr),UserData,ctrlList);
      end
      if seltext(textind)
        seltext(textind)=0;
        if identmodel(rowind,9,outctrlval)
           clr=clrs(1,:);
        else
           clr=clrs(2,:);
        end
      else
        seltext(textind)=1; clr=clrs(3,:);
      end
      set(mttextHndls(textind,:),Color,clr);
      set(mttextHndls(1,1),UserData,seltext); return;
    else
      if identmodel(rowind,9,outctrlval)
        identmodel(rowind,9,outctrlval)=0; clr=clrs(2,:);
      else
        identmodel(rowind,9,outctrlval)=1; clr=clrs(1,:);
      end
      set(mttextHndls(textind,:),Color,clr);
    end
  elseif action2==2 | action2==3
%    rowind=prowof+vcells-find(get(mttextHndls(1,1),UserData))+1;
%    lrowind=length(rowind);
%    if action2==2; sel=ones(lrowind,1); else; sel=zeros(lrowind,1); end
%    identmodel(rowind,9,outctrlval)=sel;

    % enable (de-)select-all-modes-on-current-page functions for mode selection in the mode table. Henry, 06/05/03
    nModes = length(identmodel(:,9,outctrlval));     % total mode number
    if prowof + vcells < nModes; rowind = [prowof+vcells:-1:prowof+1]; else; rowind = [nModes:-1:prowof+1]; end   % determine the mode indices on the current page
    lrowind=length(rowind);
    if action2==2;              % select all
        sel=ones(lrowind,1); clr = clrs(1,:); 
        set(mtselctrls, String,'De-select all', 'CallBack','ringdown(''rguimgr(3,3)'');', ...
            'ToolTipString','De-select all modes on the current page in the mode table');        % enable de-select-all function
    else;                       % de-select all
        sel=zeros(lrowind,1); clr = clrs(2,:); 
        set(mtselctrls, String,'Select all', 'CallBack','ringdown(''rguimgr(3,2)'');', ...
            'ToolTipString','Select all modes on the current page in the mode table');        % enable select-all function
    end
    identmodel(rowind,9,outctrlval)=sel;
    for ii=1:lrowind; set(mttextHndls(vcells-ii+1,:),Color,clr); end          % change color of mode texts
  end

%  if selctrlvis
%    textind=find(get(mttextHndls(1,1),UserData));
%    rowind=prowof+vcells-textind+1; lrowind=length(rowind);
%    clr=zeros(lrowind,3); ind3=identmodel(rowind,9,outctrlval);
%    clr(find(ind3),:)=ones(nnz(ind3),1)*clrs(1,:); ind3=~ind3;
%    clr(find(ind3),:)=ones(nnz(ind3),1)*clrs(2,:);
%    for ii=1:lrowind; set(mttextHndls(textind(ii),:),Color,clr(ii,:)); end
%    set(mtselctrls,Visible,offstr);
%    set(get(findobj(mtselctrls,Style,framestr),UserData),Enable,onstr);
%    set(get(findobj(mtselctrls,Style,textstr),UserData),Visible,onstr);
%    set(findobj(figNumber,Tag,ffindTag),Visible,onstr);            %???
%    set(findobj(figNumber,Tag,snrindTag),Visible,onstr);           %???
%  end

  if action2<4; set(polmenuHndl,UserData,identmodel); end
  rguimgr(4,2,figNumber);

  return;

%============================================================================
% Results screen
elseif action1==4

% action2==1  ==> Update everything using current control values.
% action2==2  ==> Mode table parameter selected.
% action2==3  ==> Plot options button selected.
% action2==4  ==> Time response lower plot limit control.
% action2==5  ==> Time response upper plot limit control.
% action2==6  ==> Time response Reset button.
% action2==7  ==> Smoothing Filter control.
% action2==8  ==> Cutoff Frequency control.
% action2==9  ==> Decimate control.
% action2==10 ==> Results screen detrend mode control.
% action2==11 ==> Feed-Forward term parameter.
% action2==12 ==> Frequency spectrum lower plot limit control.
% action2==13 ==> Frequency spectrum upper plot limit control.
% action2==14 ==> Frequency spectrum Reset button.
% aciton2==15 ==> Left Fill or Hanning window control.
% action2==16 ==> Pole-Zero lower horizontal limit control.
% action2==17 ==> Pole-Zero upper horizontal limit control.
% action2==18 ==> Pole-Zero horizontal limit Reset button.
% action2==19 ==> Pole-Zero lower vertical limit control.
% action2==20 ==> Pole-Zero upper vertical limit control.
% action2==21 ==> Pole-Zero vertical limit Reset button.

  trctrl1Hndl=findobj(figNumber,Tag,rstrctrl1Tag);
  trctrl2Hndl=findobj(figNumber,Tag,rstrctrl2Tag);
  pronysave=get(trctrl1Hndl,UserData);
  resultcon=get(trctrl2Hndl,UserData);
  outctrlval=get(findobj(figNumber,Tag,rsoutctrlTag),Value);

  calcsigtr=0; calcmodtr=0; plottim=0; plotfrq=0; plotpz=0;
  updatetrlim=0; updatefrlim=[0 0]; updatepzxlim=[0 0]; updatepzylim=[0 0];

  if action2==1     % Update everything.

    set(findobj(figNumber,Tag,rsdtmodctrlTag),Value,resultcon.dtmodes(outctrlval)+1);
    h=findobj(figNumber,Tag,sprintf('%s%d',outsubmenuTag,pronysave.actoutlist(outctrlval)));
    set(findobj(figNumber,Tag,rstitctrlTag),String,get(h,UserData));
    h=get(findobj(figNumber,Tag,rsdectrlTag),Value);
    if h; resultcon.df=pronysave.df; else; resultcon.df=1; end
    calcsigtr=1; calcmodtr=1; plottim=1; plotfrq=1; plotpz=1;
    updatetrlim=1; updatefrlim=[1 1]; updatepzxlim=[1 1]; updatepzylim=[1 1];

  elseif action2==2  % Mode table parameter selected.

    calcmodtr=1; plottim=1; plotfrq=1; plotpz=1;

  elseif action2==3  % Plot options button selected.

    plottim=1; plotfrq=1; plotpz=1; updatepzxlim=[1 1]; updatepzylim=[1 1];

  elseif any(action2==[4 5])

    tstart=pronysave.tstart; tstep=pronysave.tstep; updatetrlim=1;

    if action2==4    % Time response lower plot limit control.

      newtrlim1=str2num(get(gco,String));
      if ~isempty(newtrlim1)
        newtrindex1=max(floor((newtrlim1+tstart)/tstep+ep)+1,1);
        trindex2=resultcon.trindex2(outctrlval);
        if isnan(trindex2); trindex2=resultcon.endindex(outctrlval); end
        if newtrindex1<trindex2
          resultcon.trindex1(outctrlval)=newtrindex1;
          resultcon.trindex2(outctrlval)=trindex2;
          plottim=1; plotfrq=1;
        end
      end

    else             % Time response upper plot limit control.

      newtrlim2=str2num(get(gco,String));
      if ~isempty(newtrlim2)
        newtrindex2=min(floor((newtrlim2+tstart)/tstep+ep)+1,resultcon.nnout);
        trindex1=resultcon.trindex1(outctrlval);
        if isnan(trindex1)
          trindex1=resultcon.startindex+pronysave.df*resultcon.ds(outctrlval);
        end
        if trindex1<newtrindex2
          resultcon.trindex1(outctrlval)=trindex1;
          resultcon.trindex2(outctrlval)=newtrindex2;
          plottim=1; plotfrq=1;
        end
      end

    end

  elseif action2==6  % Time response Reset button.

    if isnan(resultcon.trindex1); return; end
    resultcon.trindex1(outctrlval)=NaN; resultcon.trindex2(outctrlval)=NaN;
    plottim=1; plotfrq=1; updatetrlim=1;

  elseif action2==7  % Smoothing filter control.

    resultcon.filtmod=get(gco,Value);
    calcsigtr=1; plottim=1; plotfrq=1;

  elseif action2==8  % Filter cutoff frequency control.

    h=gco; newfiltcf=str2num(get(h,String));
    if ~isempty(newfiltcf)
      if newfiltcf>0
        resultcon.filtcf=newfiltcf;
        if resultcon.filtmod; calcsigtr=1; plottim=1; plotfrq=1; end
      end
    end
    set(h,String,num2str(resultcon.filtcf));

  elseif action2==9  % Decimate control.

    if get(gco,Value); resultcon.df=pronysave.df; else; resultcon.df=1; end
    calcsigtr=1; calcmodtr=1; plottim=1; plotfrq=1;
    updatetrlim=1; updatefrlim(1)=1;

  elseif action2==10 % Detrend mode control.

    h=get(gco,Value)-1;
    if h==resultcon.dtmodes(outctrlval)
      return;
    else
      resultcon.dtmodes(outctrlval)=h;
      plottim=1; plotfrq=1;
    end

  elseif action2==11 % Feed-Forward term parameter.

    if resultcon.incthru(outctrlval); h=0; else; h=1; end
    resultcon.incthru(outctrlval)=h;
    calcmodtr=1; plottim=1; plotfrq=1; plotpz=1;

  elseif any(action2==[12 13])

    updatefrlim=[1 1];

    if action2==12   % Frequency spectrum lower plot limit control.

      newfrlim1=str2num(get(gco,String));
      if ~isempty(newfrlim1)
        frlim2=resultcon.frlim2(outctrlval);
        if isnan(frlim2); frlim2=1/(2*resultcon.df*pronysave.tstep); end
        if newfrlim1<frlim2
          resultcon.frlim1(outctrlval)=newfrlim1;
          resultcon.frlim2(outctrlval)=frlim2;
        end
      end

    else             % Frequency spectrum upper plot limit control.

      newfrlim2=str2num(get(gco,String));
      if ~isempty(newfrlim2)
        frlim1=resultcon.frlim1(outctrlval);
        if isnan(frlim1); frlim1=0; end
        if newfrlim2>frlim1
          resultcon.frlim1(outctrlval)=frlim1;
          resultcon.frlim2(outctrlval)=newfrlim2;
        end
      end

    end

  elseif action2==14 % Frequency spectrum Reset button.

    if isnan(resultcon.frlim1); return; end
    resultcon.frlim1(outctrlval)=NaN; resultcon.frlim2(outctrlval)=NaN;
    updatefrlim=[1 1];

  elseif action2==15 % Left Fill or Hanning window control.

    plotfrq=1;

  elseif any(action2==[16 17])

    updatepzxlim=[1 1];

    if action2==16   % Pole-Zero lower horizontal limit control.

      newpzxlim1=str2num(get(gco,String));
      if ~isempty(newpzxlim1)
        pzxlim2=resultcon.pzxlim2(outctrlval);
        if isnan(pzxlim2); pzxlim2=resultcon.pzxlim2d(outctrlval); end
        if newpzxlim1<pzxlim2
          resultcon.pzxlim1(outctrlval)=newpzxlim1;
          resultcon.pzxlim2(outctrlval)=pzxlim2;
        end
      end

    else             % Pole-Zero upper horizontal limit control.

      newpzxlim2=str2num(get(gco,String));
      if ~isempty(newpzxlim2)
        pzxlim1=resultcon.pzxlim1(outctrlval);
        if isnan(pzxlim1); pzxlim1=resultcon.pzxlim1d(outctrlval); end
        if newpzxlim2>pzxlim1
          resultcon.pzxlim1(outctrlval)=pzxlim1;
          resultcon.pzxlim2(outctrlval)=newpzxlim2;
        end
      end

    end

  elseif action2==18  % Pole-Zero horizontal limit Reset button.

    if isnan(resultcon.pzxlim1); return; end
    resultcon.pzxlim1(outctrlval)=NaN; resultcon.pzxlim2(outctrlval)=NaN;
    updatepzxlim=[1 1];

  elseif any(action2==[19 20])

    updatepzylim=[1 1];

    if action2==19   % Pole-Zero lower vertical limit control.

      newpzylim1=str2num(get(gco,String));
      if ~isempty(newpzylim1)
        pzylim2=resultcon.pzylim2(outctrlval);
        if isnan(pzylim2); pzylim2=resultcon.pzylim2d(outctrlval); end
        if newpzylim1<pzylim2
          resultcon.pzylim1(outctrlval)=newpzylim1;
          resultcon.pzylim2(outctrlval)=pzylim2;
        end
      end

    else             % Pole-Zero upper vertical limit control.

      newpzylim2=str2num(get(gco,String));
      if ~isempty(newpzylim2)
        pzylim1=resultcon.pzylim1(outctrlval);
        if isnan(pzylim1); pzylim1=resultcon.pzylim1d(outctrlval); end
        if newpzylim2>pzylim1
          resultcon.pzylim1(outctrlval)=pzylim1;
          resultcon.pzylim2(outctrlval)=newpzylim2;
        end
      end

    end

  elseif action2==21  % Pole-Zero vertical limit Reset button.

    if isnan(resultcon.pzylim1); return; end
    resultcon.pzylim1(outctrlval)=NaN; resultcon.pzylim2(outctrlval)=NaN;
    updatepzylim=[1 1];

  end

  if ~get(findobj(figNumber,Tag,rsfrctrlTag),Value)
    plotfrq=0; updatefrlim(2)=0;
  end
  if ~get(findobj(figNumber,Tag,rspzctrlTag),Value)
    plotpz=0; updatepzxlim(2)=0; updatepzylim(2)=0;
  end

  clrs=get(findobj(figNumber,Tag,prfmenuTag),UserData);

  if plottim | (calcmodtr & ~isempty(inpulses))
    pzyctrl2Hndl=findobj(figNumber,Tag,rspzyctrl2Tag);
    if get(pzyctrl2Hndl,UserData)==1; fstr='%.6f'; else; fstr='% 12.4e'; end
  end

  if calcmodtr | plotfrq | plotpz
    identmodel=get(findobj(figNumber,Tag,polmenuTag),UserData);
    identmodel=identmodel(:,:,outctrlval); rowind=find(identmodel(:,9));
    dampf=identmodel(rowind,1); frqrps=identmodel(rowind,2);
    bresr=identmodel(rowind,3).*cos(identmodel(rowind,4))/2;
    bresi=identmodel(rowind,3).*sin(identmodel(rowind,4))/2;
    resr=identmodel(rowind,5); resi=identmodel(rowind,6);
  end

  if calcsigtr
    outdat=get(findobj(figNumber,Tag,outmenuTag),UserData);
    curout=pronysave.actoutlist(outctrlval); startindex=resultcon.startindex;
    df=resultcon.df; tstep=pronysave.tstep;
    ind0=startindex-df*fix((startindex-1)/df):df:size(outdat,1);
    if resultcon.filtmod
      outdat=rguifilt(outdat(:,curout+1),tstep,resultcon.filtcf);
      outdat=outdat(ind0,1);
    else
      outdat=outdat(ind0,curout+1);
    end
    trndln=resultcon.trndln(:,outctrlval);
    if trndln(1)
      outdat=outdat-trndln(1)*(ind0-1)'-trndln(2);
    elseif trndln(2)
      outdat=outdat-trndln(2);
    end
    resultcon.timdat=tstep*(ind0-1)'-pronysave.tstart;
    resultcon.outdat=outdat;
  end

  if calcmodtr
    inpulses=get(findobj(figNumber,Tag,filmenuTag),UserData);
    startindex=resultcon.startindex; df=resultcon.df;
    dftstep=df*pronysave.tstep; endindex=resultcon.endindex(outctrlval);
    nncalc=fix((resultcon.nnout-startindex)/df)+1;
    thrudat=resultcon.thrudat(1:df:resultcon.endindex-startindex+1,outctrlval);
    incthru=resultcon.incthru(outctrlval); moddat=zeros(size(resultcon.timdat,1),1);
    [moddat(end-nncalc+1:end),thru1]= ...
      transimf(dampf,frqrps,resr,resi,inpulses,dftstep,nncalc,thrudat,incthru);
    resultcon.moddat=moddat;
    if ~isempty(inpulses)
      str=sprintf([ffstr fstr],thru1);
      if incthru; clr=clrs(1,:); else; clr=clrs(2,:); end
      set(findobj(figNumber,Tag,ffindTag),String,str,Color,clr,UserData,thru1);
      resultcon.thru(outctrlval)=thru1;
    end
  end

  if plottim | plotfrq
    trindex1=resultcon.trindex1(outctrlval); trindex2=resultcon.trindex2(outctrlval);
    startindex=resultcon.startindex; df=resultcon.df; tstep=pronysave.tstep;
    dtmode=resultcon.dtmodes(outctrlval); startindexd=fix((startindex-1)/df)+1;
    if isnan(trindex1)
      trindexd1=startindexd+pronysave.df*resultcon.ds(outctrlval)/df;
      trindexd2=startindexd+fix((resultcon.endindex(outctrlval)-startindex)/df);
    else
      trindexd1=startindexd+fix((trindex1-startindex)/df);
      trindexd2=startindexd+fix((trindex2-startindex)/df);
    end
    ind0=trindexd1:trindexd2;
    if dtmode
      [outdat,trends]=rguidt(resultcon.outdat(ind0),1,length(ind0),dtmode);
      if plottim; moddat=resultcon.moddat(ind0)-trends; end
    else
      outdat=resultcon.outdat(ind0);
      if plottim; moddat=resultcon.moddat(ind0); end
    end

    if plottim
      traxesHndl=findobj(figNumber,OType,axesstr,Tag,rstraxesTag);
      timdat=resultcon.timdat(ind0); set(traxesHndl,YLimMode,autostr); 
      axes(traxesHndl); linHndls=plot(timdat,outdat,timdat,moddat); traxesHndl=gca;
      set(linHndls(1),Color,clrs(4,:)); set(linHndls(2),Color,clrs(5,:));
      trlim1=timdat(1); trlim2=timdat(end); set(traxesHndl,XLim,[trlim1 trlim2]);
      drawnow; axesYLim=get(traxesHndl,YLim);
      if trlim1<0 & trlim2>0
        line([0 0],axesYLim,Color,get(traxesHndl,XColor),LineStyle,tzlinStyle);
      end
      set(traxesHndl,Tag,rstraxesTag,YLim,axesYLim,UserData,linHndls);
      resultcon.trlim1(outctrlval)=trlim1; resultcon.trlim2(outctrlval)=trlim2;
      signeng=sum(moddat.^2); noiseng=sum((outdat-moddat).^2);
      if noiseng<10*eps
        snr=[]; str=[snrstr 'Inf'];
      elseif signeng<10*eps
        snr=[]; str=[snrstr '-Inf'];
      else
        snr=10*log10(signeng/noiseng); str=sprintf([snrstr fstr dbstr],snr);
      end
      set(findobj(figNumber,Tag,snrindTag),String,str,UserData,snr);
    end

    if plotfrq
      fraxs1Hndl=findobj(figNumber,Tag,rsfraxs1Tag,OType,axesstr);
      fraxs2Hndl=findobj(figNumber,Tag,rsfraxs2Tag,OType,axesstr);
      fillmod=get(findobj(figNumber,Tag,rsfillctrlTag),Value);
      winmod=get(findobj(figNumber,Tag,rswinctrlTag),Value);
      dftstep=df*tstep; dly=(trindexd1-startindexd)*dftstep; i=sqrt(-1);
      bres0=(bresr+i*bresi).*exp((-dampf+i*frqrps)*dly);
      bres0r=real(bres0); bres0i=imag(bres0);
      [fftr,ffti,frqdat]=rguifft(outdat,dftstep,fillmod,winmod);
      [magdat,phsdat]=tranfrq0(dampf,frqrps,bres0r,bres0i,0,frqdat,fftr,ffti);
      axes(fraxs1Hndl); linHndls=plot(frqdat,magdat); fraxs1Hndl=gca;           % plot freqency response
      set(linHndls(1),Color,clrs(4,:)); set(linHndls(2),Color,clrs(5,:));
      set(fraxs1Hndl,Tag,rsfraxs1Tag,UserData,linHndls,XTickLabel,[]);
      axes(fraxs2Hndl); linHndls=plot(frqdat,phsmatch(phsdat)); fraxs2Hndl=gca;
      set(linHndls(1),Color,clrs(4,:)); set(linHndls(2),Color,clrs(5,:));
      set(fraxs2Hndl,Tag,rsfraxs2Tag,UserData,linHndls); updatefrlim(2)=1;
    end
  end

  if plotpz
    pzaxesHndl=findobj(figNumber,Tag,rspzaxesTag,OType,axesstr);
    qcon=length(dampf); i=sqrt(-1); pol=zeros(qcon+nnz(frqrps>=1e-8),1);
    res=pol; jj=1; thru1=0;
    for ii=1:qcon
      if frqrps(ii)<1e-8
        pol(jj)=-dampf(ii); res(jj)=2*resr(ii);
      else
        pol(jj)=-dampf(ii)+i*frqrps(ii); res(jj)=resr(ii)+i*resi(ii); jj=jj+1;
        pol(jj)=-dampf(ii)-i*frqrps(ii); res(jj)=resr(ii)-i*resi(ii);
      end
      jj=jj+1;
    end
    if resultcon.incthru(outctrlval); thru1=resultcon.thru(outctrlval); end
    if qcon
      [num,den]=residue(res,pol,thru1);
      zer=roots(num); zerr=real(zer)/2/pi; zeri=imag(zer)/2/pi;
      polr=real(pol)/2/pi; poli=imag(pol)/2/pi; axes(pzaxesHndl);
      linHndls=plot(polr,poli,'x',zerr,zeri,'o'); pzaxesHndl=gca; h=size(clrs,1)-3;     % plot poles and zeros
      for ii=1:length(linHndls); set(linHndls(ii),Color,clrs(rem(ii,h)+3,:)); end
      set(pzaxesHndl,Tag,rspzaxesTag,UserData,linHndls);
      hrange1=min([polr; zerr; 0]); hrange2=max([polr; zerr; 0]);
      vrange1=min([abs([poli; zeri]); 0]); vrange2=max([poli; zeri]);
      hmargin=0.1*(hrange2-hrange1); vmargin=0.1*(vrange2-vrange1);
      if hmargin
        pzxlim1d=hrange1-hmargin; pzxlim2d=hrange2+hmargin;
      else
        pzxlim1d=-0.1; pzxlim2d=0.1;
      end
      if vmargin
        pzylim1d=vrange1-vmargin; pzylim2d=vrange2+vmargin;
      else
        pzylim1d=-0.1; pzylim2d=0.1;
      end
    else
      h=get(pzaxesHndl,Children); if ~isempty(h); delete(h); end; linHndls=[];
      pzxlim1d=-1.1; pzxlim2d=0.1; pzylim1d=-0.1; pzylim2d=1.1;
    end
    resultcon.pzxlim1d(outctrlval)=pzxlim1d; resultcon.pzxlim2d(outctrlval)=pzxlim2d;
    resultcon.pzylim1d(outctrlval)=pzylim1d; resultcon.pzylim2d(outctrlval)=pzylim2d;
    updatepzxlim=[1 1]; updatepzylim=[1 1];
  end

  if updatetrlim
    set(trctrl1Hndl,String,num2str(resultcon.trlim1(outctrlval)));
    h=findobj(figNumber,Tag,rstrctrl2Tag);
    set(h,String,num2str(resultcon.trlim2(outctrlval)));
  end

  if any(updatefrlim)
    frlim1=resultcon.frlim1(outctrlval); frlim2=resultcon.frlim2(outctrlval);
    if isnan(frlim1); frlim1=0; frlim2=1/(2*resultcon.df*pronysave.tstep); end
    if updatefrlim(1)
      set(findobj(figNumber,Tag,rsfrctrl1Tag),String,num2str(frlim1));
      set(findobj(figNumber,Tag,rsfrctrl2Tag),String,num2str(frlim2));
    end
    if updatefrlim(2)
      if ~plotfrq
        fraxs1Hndl=findobj(figNumber,Tag,rsfraxs1Tag,OType,axesstr);
        fraxs2Hndl=findobj(figNumber,Tag,rsfraxs2Tag,OType,axesstr);
      end
      set([fraxs1Hndl fraxs2Hndl],XLim,[frlim1 frlim2]);
    end
  end

  if any(updatepzxlim)
    pzxlim1=resultcon.pzxlim1(outctrlval); pzxlim2=resultcon.pzxlim2(outctrlval);
    if isnan(pzxlim1)
      pzxlim1=resultcon.pzxlim1d(outctrlval);
      pzxlim2=resultcon.pzxlim2d(outctrlval);
    end
    if updatepzxlim(1)
      set(findobj(figNumber,Tag,rspzxctrl1Tag),String,num2str(pzxlim1));
      set(findobj(figNumber,Tag,rspzxctrl2Tag),String,num2str(pzxlim2));
    end
    if updatepzxlim(2)
      if ~plotpz; pzaxesHndl=findobj(figNumber,Tag,rspzaxesTag,OType,axesstr); end
      h=findobj(pzaxesHndl,Tag,pzxlinTag); if ishandle(h); delete(h); end
      h=[pzxlim1 pzxlim2]; axesForeColor=get(pzaxesHndl,XColor); axes(pzaxesHndl);
      line(h,[0 0],Tag,pzxlinTag,Color,axesForeColor,LineStyle,axeslinStyle);
      set(pzaxesHndl,XLim,h);
    end
  end

  if any(updatepzylim)
    pzylim1=resultcon.pzylim1(outctrlval); pzylim2=resultcon.pzylim2(outctrlval);
    if isnan(pzylim1)
      pzylim1=resultcon.pzylim1d(outctrlval);
      pzylim2=resultcon.pzylim2d(outctrlval);
    end
    if updatepzylim(1)
      set(findobj(figNumber,Tag,rspzyctrl1Tag),String,num2str(pzylim1));
      set(findobj(figNumber,Tag,rspzyctrl2Tag),String,num2str(pzylim2));
    end
    if updatepzylim(2)
      if ~plotpz; pzaxesHndl=findobj(figNumber,Tag,rspzaxesTag,OType,axesstr); end
      h=findobj(pzaxesHndl,Tag,pzylinTag); if ishandle(h); delete(h); end
      h=[pzylim1 pzylim2]; axesForeColor=get(pzaxesHndl,XColor); axes(pzaxesHndl);
      line([0 0],h,Tag,pzylinTag,Color,axesForeColor,LineStyle,axeslinStyle);
      set(pzaxesHndl,YLim,h);
    end
  end

  set(trctrl2Hndl,UserData,resultcon);

  return;

%============================================================================
% Mode table control.
elseif action1==5

% action2==1 ==> Update mode table using current control values.
% action2==2 ==> Results screen output number control.
% action2==3 ==> Mode table page control.
% action2==4 ==> Mode table column 2 control.
% action2==5 ==> Mode table column 3 control.
% action2==6 ==> Mode table column 4 control.
% action2==7 ==> Mode table column 5 control.
% action2==8 ==> Preference menu Numeric Format control.
% action2==9 ==> Copy mode table menu selected.

  colselect=zeros(1,5);

  if action2==1 | action2==8; updatecol=1:5; end

  if action2==2
    h=gco; outctrlval=get(h,Value);
    if outctrlval==get(h,UserData); return; end
    set(h,UserData,outctrlval); updatecol=1:5;
    rguimgr(18,6,figNumber);                         % Sort modes according to current sorting criterion. Henry, Apr. 2, 2003
    rguimgr(4,1,figNumber);             % moved from the end of this action1 to avoid redraw again the mode able. Henry, 06/05/03
    return;                             % added to avoid redraw again the mode able. Henry, 06/05/03
  else
    outctrlval=get(findobj(figNumber,Tag,rsoutctrlTag),Value);
  end

  if action2==3
    h=gco; curpage=get(h,Value);
    if curpage==get(h,UserData); return; end
    set(h,UserData,curpage); updatecol=1:5;
  else
    curpage=get(findobj(figNumber,Tag,mtpgctrlTag),Value);
  end

  if action2==4
    h=gco; colselect(2)=get(h,Value);
    if colselect(2)==get(h,UserData); return; end
    set(h,UserData,colselect(2)); updatecol=2;
  else
    colselect(2)=get(findobj(figNumber,Tag,mtcol2ctrlTag),Value);
  end

  if action2==5
    h=gco; colselect(3)=get(h,Value);
    if colselect(3)==get(h,UserData); return; end
    set(h,UserData,colselect(3)); updatecol=3;
  else
    colselect(3)=get(findobj(figNumber,Tag,mtcol3ctrlTag),Value);
  end

  if action2==6
    h=gco; colselect(4)=get(h,Value);
    if colselect(4)==get(h,UserData); return; end
    set(h,UserData,colselect(4)); updatecol=4;
  else
    colselect(4)=get(findobj(figNumber,Tag,mtcol4ctrlTag),Value);
  end

  if action2==7
    h=gco; colselect(5)=get(h,Value);
    if colselect(5)==get(h,UserData); return; end
    set(h,UserData,colselect(5)); updatecol=5;
  else
    colselect(5)=get(findobj(figNumber,Tag,mtcol5ctrlTag),Value);
  end

  if action2==9
    mtfig=findobj(0,Tag,['mtfig' int2str(figNumber)],OType,figstr);
    updatecol=1:5;
  else
    mtfig=figNumber;
  end

  mttextHndls=get(findobj(mtfig,Tag,mtblTag,OType,axesstr),UserData);
  set(mttextHndls(:,updatecol),Visible,offstr); vcells=size(mttextHndls,1)-3;
  clrs=get(findobj(figNumber,Tag,prfmenuTag),UserData);
  numfmt=get(findobj(figNumber,Tag,rspzyctrl2Tag),UserData);
  identmodel=get(findobj(figNumber,Tag,polmenuTag),UserData);
  identmodel=identmodel(:,:,outctrlval); qcon=size(identmodel,1);
  if action2<9
    if curpage*vcells>qcon
      nncells=qcon-vcells*floor(qcon/vcells);
    else
      nncells=vcells;
    end
    rowind=vcells*(curpage-1)+(1:nncells);
    clr=zeros(nncells,3); ind3=identmodel(rowind,9);
    clr(find(ind3),:)=ones(nnz(ind3),1)*clrs(1,:); ind3=~ind3;
    clr(find(ind3),:)=ones(nnz(ind3),1)*clrs(2,:);
  else
    nncells=vcells; rowind=find(identmodel(:,9));
  end 
  textind=vcells:-1:(vcells-nncells+1);

  sortctrlval=get(findobj(figNumber,Tag,sortctrlTag), UserData);      % get current sorting criterion. Henry, 04/03/03
  for jj=updatecol
    highlight = 0;                                                      % "1" to highlight the sorting column. Henry, 04/03/03
    if jj==1
      [k,fpemin]=min(identmodel(:,8));
      for ii=1:nncells
        % display mode type, Henry, 04/03/03
        %Mode types:
        % 1) Simple trends:             0 == freq                         
        % 2) Oscillatory trends:        0 <  freq < FLIM2 & DLIM1 <= dampRatio   
        % 3) Interarea oscillations:    0 <  freq <=FLIM1 &     0 <  dampRatio <  DLIM1   
        % 4) Local oscillations:    FLIM1 <= freq < FLIM2 &     0 <  dampRatio <  DLIM1   
        % 5) Unstable oscillations:     0 <= freq < FLIM2 &          dampRatio <= 0   
        % 6) Fast noise:            FLIM2 <= freq    
        switch identmodel(rowind(ii), 10)     % 10th column for mode type
            case 1, strType = 'SmpTrd';
            case 2, strType = 'OscTrd';
            case 3, strType = 'IntOsc';
            case 4, strType = 'LocOsc';
            case 5, strType = 'UnsOsc';
            case 6, strType = 'FstNse';
            otherwise, strType = 'Unknown';
        end
        % end - display mode type, Henry, 04/03/03
        
        if action2<9
%        for ii=1:nncells
          if rowind(ii)==fpemin
            str=sprintf('*%d*',rowind(ii));
          else
            str=sprintf('%d',rowind(ii));
          end
          str = strcat(str, ' - ', strType);            % to display mode types. Henry, Apr.3, 2003
          %if sortctrlval == 4                           % highlight the mode type column. Henry, Apr.3, 2003
          %  set(mttextHndls(textind(ii),1),String,str,Color,HighlightColor);
          %else
            set(mttextHndls(textind(ii),1),String,str,Color,clr(ii,:));
          %end
%        end
        else
%        for ii=1:nncells
          str = strcat(sprintf('%d',ii), ' - ', strType);      % to display mode types. Henry, Apr.3, 2003
          %if sortctrlval == 4                           % highlight the mode type column. Henry, Apr.3, 2003
          %  set(mttextHndls(textind(ii),1),String, str, Color, HighlightColor);
          %else
            set(mttextHndls(textind(ii),1),String, str);
          %end
%        end
        end
      end
    else
      if colselect(jj)==1
        header1='Frequency'; header2='(Hz)'; params=identmodel(rowind,2)/2/pi;
        if sortctrlval == 1; highlight = 0; end                           % Henry, 04/03/03
      elseif colselect(jj)==2
        header1='Damping'; header2='/2\pi'; params=identmodel(rowind,1)/2/pi;
      elseif colselect(jj)==3
        wn=sqrt(identmodel(rowind,1).^2+identmodel(rowind,2).^2);
        header1='Damping'; header2='Ratio'; params=identmodel(rowind,1)./wn;
        ind=find(identmodel(rowind,2)<1e-8);
        if ~isempty(ind); params(ind)=NaN*ones(length(ind),1); end
        if sortctrlval == 2; highlight = 0; end                           % Henry, 04/03/03
      elseif colselect(jj)==4
        header1=ampstr; header2=spacestr; params=identmodel(rowind,3);
      elseif colselect(jj)==5
        header1=phsstr; header2=degstr; params=180/pi*identmodel(rowind,4);
      elseif colselect(jj)==6
        maxamp=max(identmodel(:,3));
        header1=relstr; header2=ampstr; params=identmodel(rowind,3)/maxamp;
      elseif colselect(jj)==7
        header1=ampstr; header2=spacestr;
        params=sqrt(identmodel(rowind,5).^2+identmodel(rowind,6).^2);
      elseif colselect(jj)==8
        header1=phsstr; header2=degstr;
        params=180/pi*atan2(identmodel(rowind,6),identmodel(rowind,5));
      elseif colselect(jj)==9
        amp=sqrt(identmodel(:,5).^2+identmodel(:,6).^2);
        header1=relstr; header2=ampstr; params=amp(rowind)/max(amp);
      elseif colselect(jj)==10
        header1='Akaike FPE'; header2=spacestr; params=identmodel(rowind,8);
      else
        header1=relstr; header2='Energy'; params=identmodel(rowind,7);
        if sortctrlval == 3; highlight = 0; end                           % Henry, 04/03/03
      end
      if numfmt==1
        h=max(abs(params(~isnan(params)))); fstr='%.6f';
        if h; exppmax=floor(log10(h)); else; exppmax=0; end
        if abs(exppmax)>3
          params=params/10^exppmax; header3=sprintf('10^{%d}  x',exppmax);
        else
          header3=spacestr;
        end
      else
        header3=spacestr; fstr='% 12.4e';
      end
      if highlight                                                        % highlight the sorting column. Henry, 04/03/03
        set(mttextHndls(vcells+3,jj),String,header1, Color, HighlightColor);
        set(mttextHndls(vcells+2,jj),String,header2, Color, HighlightColor);
        set(mttextHndls(vcells+1,jj),String,header3, Color, HighlightColor);
      else
        set(mttextHndls(vcells+3,jj),String,header1, Color, 'white');
        set(mttextHndls(vcells+2,jj),String,header2, Color, 'white');
        set(mttextHndls(vcells+1,jj),String,header3, Color, 'white');
      end
      if action2<9
        textxPos=0.2125+(jj-2)*0.2250;
        for ii=1:nncells
          textPos=get(mttextHndls(textind(ii),jj),Position);
          if isnan(params(ii)); h=rdrstr; else; h=sprintf(fstr,params(ii)); end
          if highlight                                                         % highlight the sorting column. Henry, 04/03/03
            set(mttextHndls(textind(ii),jj),String,h,Color,HighlightColor, ...
              Position,[textxPos textPos(2)]);
          else
            set(mttextHndls(textind(ii),jj),String,h,Color,clr(ii,:), ...
              Position,[textxPos textPos(2)]);
          end
        end
      else
        for ii=1:nncells
          if isnan(params(ii)); h=rdrstr; else; h=sprintf(fstr,params(ii)); end
          if highlight                                                         % highlight the sorting column. Henry, 04/03/03
            set(mttextHndls(textind(ii),jj),String,h, Color, HighlightColor);
          else
            set(mttextHndls(textind(ii),jj),String,h);
          end
        end
      end
    end
  end
  if action2<9
    set(mttextHndls(textind,:),ButtonDownFcn,'ringdown(''rguimgr(3,1);'');');
    set(mttextHndls((vcells-nncells):-1:1,:),String,spacestr, ...
      ButtonDownFcn,emptystr);
  end
  if numfmt==1
    drawnow;
    for jj=updatecol
      if jj>1
        textPos=zeros(nncells,3); textExt=zeros(nncells,4); ind=ones(nncells,1);
        for ii=1:nncells
          h=mttextHndls(textind(ii),jj);
          textPos(ii,:)=get(h,Position); textExt(ii,:)=get(h,'Extent');
          if strcmp(get(h,String),rdrstr); ind(ii)=0; end
        end
        newtextPos=textPos; ind=find(ind);
        newtextPos(ind,1)=textPos(ind,1)+(max(textExt(ind,3))-textExt(ind,3))/2;
        for ii=1:nncells
          set(mttextHndls(textind(ii),jj),Position,newtextPos(ii,:));
        end
      end
    end
  end

%  if action2>1; set(mttextHndls(:,updatecol),Visible,onstr); end
  set(mttextHndls(:,updatecol),Visible,onstr);

  if action2==2
%    rguimgr(4,1,figNumber);        % moved to the beginning to avoid redraw again the mode table. the sorting function has redrawn the table. Henry, 06/05/03
  elseif action2==8
    ffindHndl=findobj(figNumber,Tag,ffindTag); thru1=get(ffindHndl,UserData);
    if ~isempty(thru1); set(ffindHndl,String,sprintf([ffstr fstr],thru1)); end
    snrindHndl=findobj(figNumber,Tag,snrindTag); snr=get(snrindHndl,UserData);
    if ~isempty(snr); set(snrindHndl,String,sprintf([snrstr fstr dbstr],snr)); end
  end

  return;

%============================================================================
% Advanced Options screen control.
elseif action1==6

% action2==1  ==> Linear Prediction Method control.
% action2==2  ==> Forward/Backward Logic control.
% action2==3  ==> Linear Prediction Order auto control.
% action2==4  ==> Linear Prediction Order set control.
% action2==5  ==> Linear Prediction Order text control.
% action2==6  ==> Upper Trim Frequency auto control.
% action2==7  ==> Upper Trim Frequency set control.
% action2==8  ==> Upper Trim Frequency text control.
% action2==9  ==> Lower Trim Frequency auto control.
% action2==10 ==> Lower Trim Frequency set control.
% action2==11 ==> Lower Trim Frequency text control.
% action2==12 ==> Residue Trim Level auto control.
% action2==13 ==> Residue Trim Level set control.
% action2==14 ==> Residue Trim Level text control.

  if action2==1
    lpmctrlHndl=gco; lpmcon=get(lpmctrlHndl,Value);
    if lpmcon==get(lpmctrlHndl,UserData); return; end
    set(lpmctrlHndl,UserData,lpmcon);
  elseif action2==2
    fbctrlHndl=gco; fbcon=get(fbctrlHndl,Value);
    if fbcon==get(fbctrlHndl,UserData); return; end
    set(fbctrlHndl,UserData,fbcon);
  end

  stctrlHndl=findobj(figNumber,Tag,stctrlTag); setupcon1=get(stctrlHndl,UserData);

  if action2==3       % Linear Prediction Order auto control.

    lpoctrl2Hndl=findobj(figNumber,Tag,lpoctrl2Tag);
    if get(lpoctrl2Hndl,Value)
      set(lpoctrl2Hndl,Value,0); lpomax=setupcon1(10);
      lpocon=floor(11*lpomax/12); setupcon1(11)=lpocon;
      set(findobj(figNumber,Tag,lpoctrlTag),String,int2str(lpocon));
    else
      set(gco,Value,1);
    end

  elseif action2==4   % Linear Prediction Order set control.

    lpoctrl1Hndl=findobj(figNumber,Tag,lpoctrl1Tag);
    if get(lpoctrl1Hndl,Value)
      set(lpoctrl1Hndl,Value,0);
    else
      set(gco,Value,1);
    end

  elseif action2==5   % Linear Prediction Order text control.

    lpoctrlHndl=gco;
    newlpocon=str2num(get(lpoctrlHndl,String));
    lpomax=setupcon1(10); lpocon=setupcon1(11);
    if ~isempty(newlpocon)
      if newlpocon>0
        lpocon=min(newlpocon,lpomax); setupcon1(11)=lpocon;
      end
    end
    set(lpoctrlHndl,String,lpocon);

  elseif action2==6   % Upper Trim Frequency auto control.

    ftrhctrl2Hndl=findobj(figNumber,Tag,ftrhctrl2Tag);
    if get(ftrhctrl2Hndl,Value)
      set(ftrhctrl2Hndl,Value,0); tstep=setupcon1(1); df=setupcon1(4);
      ftrh=1/(3*df*tstep); setupcon1(12)=ftrh;
      set(findobj(figNumber,Tag,ftrhctrlTag),String,num2str(ftrh));
    else
      set(gco,Value,1);
    end

  elseif action2==7   % Upper Trim Frequency set control.

    ftrhctrl1Hndl=findobj(figNumber,Tag,ftrhctrl1Tag);
    if get(ftrhctrl1Hndl,Value)
      set(ftrhctrl1Hndl,Value,0);
    else
      set(gco,Value,1);
    end

  elseif action2==8   % Upper Trim Frequency text control.

    ftrhctrlHndl=gco;
    newftrh=str2num(get(ftrhctrlHndl,String)); ftrh=setupcon1(12);
    if ~isempty(newftrh)
      if newftrh>0; ftrh=max(newftrh,ftrl); setupcon1(12)=ftrh; end
    end
    set(ftrhctrlHndl,String,num2str(ftrh));

  elseif action2==9   % Lower Trim Frequency auto control.

    ftrlctrl2Hndl=findobj(figNumber,Tag,ftrlctrl2Tag);
    if get(ftrlctrl2Hndl,Value)
      set(ftrlctrl2Hndl,Value,0); ftrl=0; setupcon1(13)=ftrl;
      set(findobj(figNumber,Tag,ftrlctrlTag),String,num2str(ftrl));
    else
      set(gco,Value,1);
    end

  elseif action2==10  % Lower Trim Frequency set control.

    ftrlctrl1Hndl=findobj(figNumber,Tag,ftrlctrl1Tag);
    if get(ftrlctrl1Hndl,Value)
      set(ftrlctrl1Hndl,Value,0);
    else
      set(gco,Value,1);
    end

  elseif action2==11  % Lower Trim Frequency text control.

    ftrlctrlHndl=gco;
    newftrl=str2num(get(ftrlctrlHndl,String)); ftrl=setupcon1(13);
    if ~isempty(newftrl)
      if newftrl>0; ftrl=min(newftrl,ftrh); setupcon1(13)=ftrl; end
    end
    set(ftrlctrlHndl,String,num2str(ftrl));

  elseif action2==12  % Residue Trim Level auto control.

    trrectrl2Hndl=findobj(figNumber,Tag,trrectrl2Tag);
    if get(trrectrl2Hndl,Value)
      set(trrectrl2Hndl,Value,0); trre=1e-8; setupcon1(14)=trre;
      set(findobj(figNumber,Tag,trrectrlTag),String,num2str(trre));
    else
      set(gco,Value,1);
    end

  elseif action2==13  % Residue Trim Level set control.

    trrectrl1Hndl=findobj(figNumber,Tag,trrectrl1Tag);
    if get(trrectrl1Hndl,Value)
      set(trrectrl1Hndl,Value,0);
    else
      set(gco,Value,1);
    end

  elseif action2==14  % Residue Trim Level text control.

    trrectrlHndl=gco;
    newtrre=str2num(get(trrectrlHndl,String)); trre=setupcon1(14);
    if ~isempty(newtrre)
      if newtrre>=0; trre=newtrre; setupcon1(14)=trre; end
    end
    set(trrectrlHndl,String,num2str(trre));

  end

  set(stctrlHndl,UserData,setupcon1);

  return;

%============================================================================
% Make the setup or results screen visible.  Also used to make both invisible.
elseif action1==7

% action2==1 ==> Make the setup screen visible.
% action2==2 ==> Make both screens invisible.
% action2==3 ==> Make the results screen visible.

  ssoutctrlHndl=findobj(figNumber,Tag,ssoutctrlTag);
  ssvis=strcmp(get(ssoutctrlHndl,Visible),onstr);
  rsoutctrlHndl=findobj(figNumber,Tag,rsoutctrlTag);
  rsvis=strcmp(get(rsoutctrlHndl,Visible),onstr);

  if action2==1 & ssvis
    return;
  elseif action2==3 & rsvis
    return;
  end

  if action2==1 | ssvis
    ssHndls=[findobj(figNumber,Tag,ssfrmlabbtnTag); ssoutctrlHndl; ...
      findobj(figNumber,Tag,sstitctrlTag); findobj(figNumber,Tag,dsctrlTag); ...
      findobj(figNumber,Tag,npindTag); findobj(figNumber,Tag,etctrlTag); ...
      findobj(figNumber,Tag,dtinictrlTag); findobj(figNumber,Tag,ssdtmodctrlTag); ...
      findobj(figNumber,Tag,dtendctrlTag); findobj(figNumber,Tag,ssfrctrlTag); ...
      findobj(figNumber,Tag,tsind1Tag); ...
      findobj(figNumber,Tag,ssfiltctrlTag); findobj(figNumber,Tag,sscfctrlTag); ...
      findobj(figNumber,Tag,ssdectrlTag); findobj(figNumber,Tag,tsind2Tag); ...
      findobj(figNumber,Tag,nqindTag); findobj(figNumber,Tag,stctrlTag); ...
      findobj(figNumber,Tag,tnpindTag); findobj(figNumber,Tag,fcctrlTag); ...
      findobj(figNumber,Tag,rrctrlTag); findobj(figNumber,Tag,scctrlTag); ...
      findobj(figNumber,Tag,adctrlbtnTag); findobj(figNumber,Tag,pabtnTag); ...
      findobj(figNumber,Tag,ssfillctrlTag); findobj(figNumber,Tag,sswinctrlTag); ...
      findobj(figNumber,Tag,sstrctrl1Tag); findobj(figNumber,Tag,sstrctrl2Tag); ...
      findobj(figNumber,Tag,ssfrctrl1Tag); findobj(figNumber,Tag,ssfrctrl2Tag)];
%      findobj(figNumber,Tag,msigctrlTag);              % deleted by Henry. 04/23/03
%      findobj(figNumber,Tag,'sslegend'); ...                              % Legend list, Henry, 06/30/03
  end

  if action2==3 | rsvis
    mtblHndl=findobj(figNumber,Tag,mtblTag);
    mttextHndls=get(findobj(mtblHndl,OType,axesstr),UserData);
    rsHndls=[findobj(figNumber,Tag,rsfrmlabbtnTag); rsoutctrlHndl; ...
      findobj(figNumber,Tag,rstitctrlTag); findobj(figNumber,Tag,mtpgctrlTag); ...
      findobj(figNumber,Tag,mtcol2ctrlTag); findobj(figNumber,Tag,mtcol3ctrlTag); ...
      findobj(figNumber,Tag,mtcol4ctrlTag); findobj(figNumber,Tag,mtcol5ctrlTag); ...
      findobj(figNumber,Tag,rsfrctrlTag); findobj(figNumber,Tag,rspzctrlTag); ...
      findobj(figNumber,Tag,rstrctrl1Tag); findobj(figNumber,Tag,rstrctrl2Tag); ...
      findobj(figNumber,Tag,rsfrctrl1Tag); findobj(figNumber,Tag,rsfrctrl2Tag); ...
      findobj(figNumber,Tag,rspzxctrl1Tag); findobj(figNumber,Tag,rspzxctrl2Tag); ...
      findobj(figNumber,Tag,rspzyctrl1Tag); findobj(figNumber,Tag,rspzyctrl2Tag); ...
      findobj(figNumber,Tag,rsfiltctrlTag); findobj(figNumber,Tag,rscfctrlTag); ...
      findobj(figNumber,Tag,rsdectrlTag); findobj(figNumber,Tag,rsdtmodctrlTag);  ...
      findobj(figNumber,Tag,rsfillctrlTag); findobj(figNumber,Tag,rswinctrlTag);  ...
      findobj(figNumber,Tag,ffindTag); findobj(figNumber,Tag,snrindTag); ...
      findobj(figNumber,Tag,mtselctrlTag); ...                                               % Henry, 06/05/03. Mode table select buttons
      findobj(figNumber,Tag,rsDLIM1labTag); findobj(figNumber,Tag,rsDLIM1ctrlTag); ...       % Henry, 03/25/03
      findobj(figNumber,Tag,rsFLIM1labTag); findobj(figNumber,Tag,rsFLIM1ctrlTag); ...       % Henry, 03/25/03
      findobj(figNumber,Tag,rsFLIM2labTag); findobj(figNumber,Tag,rsFLIM2ctrlTag); ...       % Henry, 03/25/03
      findobj(figNumber,Tag,sortctrlTag) ];                                                  % Henry, 03/20/03

  end

  
  if ssvis
    if strcmp(get(findobj(figNumber,Tag,lpoctrlTag),Visible),onstr)
      rguimgr(8,2,figNumber);
    else
      set(findobj(figNumber,Tag,inpaxesTag),Visible,offstr);
      sstraxesHndl=findobj(figNumber,Tag,sstraxesTag);
      legend off                                  % legend off, Henry, 06/27/03
      h=findobj(sstraxesHndl,OType,axesstr);
      delete(get(h,Children)); set(h,UserData,[]);
      ssfraxs1Hndl=findobj(figNumber,Tag,ssfraxs1Tag);
      h=findobj(ssfraxs1Hndl,OType,axesstr);
      delete(get(h,Children)); set(h,UserData,[]);
      ssfraxs2Hndl=findobj(figNumber,Tag,ssfraxs2Tag);
      h=findobj(ssfraxs2Hndl,OType,axesstr);
      delete(get(h,Children)); set(h,UserData,[]);
      set([sstraxesHndl; ssfraxs1Hndl; ssfraxs2Hndl],Visible,offstr);
    end
    set(ssHndls,Visible,offstr);
  end

  if rsvis
    rstraxesHndl=findobj(figNumber,Tag,rstraxesTag);
    h=findobj(rstraxesHndl,OType,axesstr);
    delete(get(h,Children)); set(h,UserData,[]);
    rsfraxs1Hndl=findobj(figNumber,Tag,rsfraxs1Tag);
    h=findobj(rsfraxs1Hndl,OType,axesstr);
    delete(get(h,Children)); set(h,UserData,[]);
    rsfraxs2Hndl=findobj(figNumber,Tag,rsfraxs2Tag);
    h=findobj(rsfraxs2Hndl,OType,axesstr);
    delete(get(h,Children)); set(h,UserData,[]);
    rspzaxesHndl=findobj(figNumber,Tag,rspzaxesTag);
    h=findobj(rspzaxesHndl,OType,axesstr);
    delete(get(h,Children)); set(h,UserData,[]);
    set([rstraxesHndl; rsfraxs1Hndl; rsfraxs2Hndl; rspzaxesHndl],Visible,offstr);
    set(rsHndls,Visible,offstr); set(mtblHndl,Visible,offstr);
    set(mttextHndls,Visible,offstr);
  end

  drawnow;

  if action2==1 | action2==3
    outmenuHndl=findobj(figNumber,Tag,outmenuTag);
    copymtHndl=findobj(figNumber,Tag,copymtTag);
    rsmenuHndl=findobj(figNumber,Tag,rsmenuTag);
    ssmenuHndl=findobj(figNumber,Tag,ssmenuTag);
  end

  if action2==1
    set(ssHndls,Visible,onstr); set(outmenuHndl,Enable,onstr);
    set([copymtHndl findobj(figNumber,Tag,copypzTag)],Enable,offstr);
    set(ssmenuHndl,Checked,onstr); set(rsmenuHndl,Checked,offstr);
    rguimgr(9,1,figNumber);
  elseif action2==3
    set(mtblHndl,Visible,onstr); set(mttextHndls,Visible,onstr);
    set(rsHndls,Visible,onstr); set(outmenuHndl,Enable,offstr);
    set(copymtHndl,Enable,onstr); set(ssmenuHndl,Checked,offstr);
    set(rsmenuHndl,Checked,onstr); rguimgr(10,1,figNumber);
  end

  return;

%============================================================================
% Toggle the Advanced Options screen.
elseif action1==8

% action2==1 ==> Make advanced options screen visible.
% action2==2 ==> Make advanced options screen invisible.

  lpoctrlHndl=findobj(figNumber,Tag,lpoctrlTag);
  if action2==1 & strcmp(get(lpoctrlHndl,Visible),onstr); return; end

  adHndls=[findobj(figNumber,Tag,displtbtnTag); ...
    findobj(figNumber,Tag,adfrmlabbtnTag); findobj(figNumber,Tag,lpmctrlTag); ...
    findobj(figNumber,Tag,fbctrlTag); findobj(figNumber,Tag,lpactrlTag); ...
    findobj(figNumber,Tag,lpoctrl1Tag); findobj(figNumber,Tag,lpoindTag); ...
    findobj(figNumber,Tag,lpoctrl2Tag); lpoctrlHndl; ...
    findobj(figNumber,Tag,ftrhctrl1Tag); findobj(figNumber,Tag,ftrhindTag); ...
    findobj(figNumber,Tag,ftrhctrl2Tag); findobj(figNumber,Tag,ftrhctrlTag); ...
    findobj(figNumber,Tag,ftrlctrl1Tag); findobj(figNumber,Tag,ftrlindTag); ...
    findobj(figNumber,Tag,ftrlctrl2Tag); findobj(figNumber,Tag,ftrlctrlTag); ...
    findobj(figNumber,Tag,trrectrl1Tag); findobj(figNumber,Tag,trreindTag); ...
    findobj(figNumber,Tag,trrectrl2Tag); findobj(figNumber,Tag,trrectrlTag); ...
    findobj(figNumber,Tag,ordctrlTag)];
  copytrHndl=findobj(figNumber,Tag,copytrTag);

  if action2==1
    set(findobj(figNumber,Tag,inpaxesTag),Visible,offstr);
    sstraxesHndl=findobj(figNumber,Tag,sstraxesTag);
    delete(get(findobj(sstraxesHndl,OType,axesstr),Children));
    ssfraxs1Hndl=findobj(figNumber,Tag,ssfraxs1Tag);
    delete(get(findobj(ssfraxs1Hndl,OType,axesstr),Children));
    ssfraxs2Hndl=findobj(figNumber,Tag,ssfraxs2Tag);
    delete(get(findobj(ssfraxs2Hndl,OType,axesstr),Children));
    adctrlbtnHndl=findobj(figNumber,Tag,adctrlbtnTag);
    set([adctrlbtnHndl; sstraxesHndl; ssfraxs1Hndl; ssfraxs2Hndl],Visible,offstr);
    set(adHndls,Visible,onstr); set(copytrHndl,Enable,offstr);
    set(findobj(figNumber,Tag,copyfrTag),Enable,offstr);
  else
    set(adHndls,Visible,offstr); set(copytrHndl,Enable,onstr);
  end

  return;

%============================================================================
% Setup screen plot selection control.
elseif action1==9

% action2==1 ==> Make setup screen axes visible according to plot controls.
% action2==2 ==> Setup screen frequency response plot control selected.
% action2==3 ==> Multiple signal plot control selected.

  if strcmp(get(findobj(figNumber,Tag,lpoctrlTag),Visible),onstr)
    rguimgr(8,2,figNumber); set(findobj(figNumber,Tag,adctrlbtnTag),Visible,onstr);
  end

  plotfrq=get(findobj(figNumber,Tag,ssfrctrlTag),Value);
  %plotall=get(findobj(figNumber,Tag,msigctrlTag),Value);    % deleted by Henry. 04/23/03
  outctrlval = get(findobj(figNumber,Tag,ssoutctrlTag),Value);    % for multi-signal setting. Henry, 04/07/03
  if outctrlval == 1; plotall = 1; else plotall = 0; end          % for multi-signal setting. Henry, 04/07/03

  inpulses=get(findobj(figNumber,Tag,filmenuTag),UserData);
  if ~isempty(inpulses); set(findobj(figNumber,Tag,inpaxesTag),Visible,onstr); end
  sstraxesHndl=findobj(figNumber,Tag,sstraxesTag);
  ssfraxs1Hndl=findobj(figNumber,Tag,ssfraxs1Tag);
  ssfraxs2Hndl=findobj(figNumber,Tag,ssfraxs2Tag);
  set([sstraxesHndl; ssfraxs1Hndl; ssfraxs2Hndl],Visible,offstr);
  if plotfrq
    if isempty(inpulses)
      traxesPos=[0.100 0.760 0.540 0.200];
      trtitlPos=[0.370 0.980]; trxlabPos=[0.370 0.715];
    else
      traxesPos=[0.100 0.680 0.540 0.160];
      trtitlPos=[0.370 0.860]; trxlabPos=[0.370 0.635];
    end
  else
    traxesPos=[0.100 0.250 0.540 0.590];
    trtitlPos=[0.370 0.860]; trxlabPos=[0.370 0.205];
  end
  set(findobj(sstraxesHndl,OType,axesstr),Position,traxesPos);
  set(findobj(sstraxesHndl,UserData,titlestr),Position,trtitlPos);
  set(findobj(sstraxesHndl,UserData,xlablstr),Position,trxlabPos);
  delete(get(findobj(ssfraxs1Hndl,OType,axesstr),Children));
  delete(get(findobj(ssfraxs2Hndl,OType,axesstr),Children));
  if plotfrq
    set([sstraxesHndl; ssfraxs1Hndl; ssfraxs2Hndl],Visible,onstr); menuenbl=onstr;
  else
    set(sstraxesHndl,Visible,onstr); menuenbl=offstr;
  end
  set(findobj(figNumber,Tag,copyfrTag),Enable,menuenbl);

  if action2==1; rguimgr(1,1,figNumber); else; rguimgr(1,2,figNumber); end

  return;

%============================================================================
% Results screen plot selection control.
elseif action1==10

% action2==1 ==> Make results screen plot axes visible according to plot controls.
% action2==2 ==> Results screen frequency response plot control selected.
% action2==3 ==> Results screen pole-zero plot control selected.

  plotfrq=get(findobj(figNumber,Tag,rsfrctrlTag),Value);
  plotpz=get(findobj(figNumber,Tag,rspzctrlTag),Value);

  rstraxesHndl=findobj(figNumber,Tag,rstraxesTag);
  rsfraxs1Hndl=findobj(figNumber,Tag,rsfraxs1Tag);
  rsfraxs2Hndl=findobj(figNumber,Tag,rsfraxs2Tag);
  rspzaxesHndl=findobj(figNumber,Tag,rspzaxesTag);
  set([rstraxesHndl; rsfraxs1Hndl; rsfraxs2Hndl; rspzaxesHndl],Visible,offstr);
  if plotfrq & plotpz
    traxesPos=[0.680 0.820 0.300 0.140]; trxlabPos=[0.830 0.775];
  else
    traxesPos=[0.680 0.700 0.300 0.260]; trxlabPos=[0.830 0.655];
  end
  set(findobj(rstraxesHndl,OType,axesstr),Position,traxesPos);
  set(findobj(rstraxesHndl,UserData,xlablstr),Position,trxlabPos);
  if plotfrq
    if plotpz
      fraxes1Pos=[0.680 0.585 0.300 0.140]; fraxes2Pos=[0.680 0.420 0.300 0.140];
      frtitlePos=[0.830 0.745]; fr1ylblPos=[0.625 0.655];
      fr2ylblPos=[0.625 0.490]; frxlablPos=[0.830 0.375];
    else
      fraxes1Pos=[0.680 0.345 0.300 0.260]; fraxes2Pos=[0.680 0.065 0.300 0.260];
      frtitlePos=[0.830 0.625]; fr1ylblPos=[0.625 0.475];
      fr2ylblPos=[0.625 0.195]; frxlablPos=[0.830 0.020];
    end
    set(findobj(rsfraxs1Hndl,OType,axesstr),Position,fraxes1Pos);
    set(findobj(rsfraxs2Hndl,OType,axesstr),Position,fraxes2Pos);
    set(findobj(rsfraxs1Hndl,UserData,titlestr),Position,frtitlePos);
    set(findobj(rsfraxs1Hndl,UserData,ylablstr),Position,fr1ylblPos);
    set(findobj(rsfraxs2Hndl,UserData,ylablstr),Position,fr2ylblPos);
    set(findobj(rsfraxs2Hndl,UserData,xlablstr),Position,frxlablPos);
  end
  if plotpz
    if plotfrq
      pzaxesPos=[0.680 0.065 0.300 0.260];
      pztitlePos=[0.830 0.345]; pzylab1Pos=[0.625 0.195];
    else
      pzaxesPos=[0.680 0.065 0.300 0.310];
      pztitlePos=[0.830 0.395]; pzylab1Pos=[0.625 0.220];
    end
    set(findobj(rspzaxesHndl,OType,axesstr),Position,pzaxesPos);
    set(findobj(rspzaxesHndl,UserData,titlestr),Position,pztitlePos);
    set(findobj(rspzaxesHndl,UserData,ylablstr),Position,pzylab1Pos);
  end
  set(rstraxesHndl,Visible,onstr);
  delete(get(findobj(rsfraxs1Hndl,OType,axesstr),Children));
  delete(get(findobj(rsfraxs2Hndl,OType,axesstr),Children));
  delete(get(findobj(rspzaxesHndl,OType,axesstr),Children));
  if plotfrq
    set([rsfraxs1Hndl; rsfraxs2Hndl],Visible,onstr); menuenbl=onstr;
  else
    menuenbl=offstr;
  end
  set(findobj(figNumber,Tag,copyfrTag),Enable,menuenbl);
  if plotpz
    set(rspzaxesHndl,Visible,onstr); menuenbl=onstr;
  else
    menuenbl=offstr;
  end
  set(findobj(figNumber,Tag,copypzTag),Enable,menuenbl);

  if action2==1; rguimgr(4,1,figNumber); else; rguimgr(4,3,figNumber); end

  return;

%============================================================================
% Setup or results screen title control.
elseif action1==11

% action2==1 ==> Setup screen title control.
% action2==2 ==> Results screen title control.

  outtitle=deblank(get(gco,String));
  if action2==1
    outctrlval=get(findobj(figNumber,Tag,ssoutctrlTag),Value);
    setupcon2=get(findobj(figNumber,Tag,ssdectrlTag),UserData);
    actoutlist=find(setupcon2(1,:)); curout=actoutlist(outctrlval);     %???
  else
    outctrlval=get(findobj(figNumber,Tag,rsoutctrlTag),Value);
    pronysave=get(findobj(figNumber,Tag,rstrctrl1Tag),UserData);
    curout=pronysave.actoutlist(outctrlval);
  end
  if isempty(outtitle)
    menustr=int2str(curout);
  else
    menustr=[int2str(curout) ':  ' outtitle];
  end
  outsubmenuHndl=findobj(figNumber,Tag,sprintf('%s%d',outsubmenuTag,curout));
  set(outsubmenuHndl,Label,menustr,UserData,outtitle);

  return;

%============================================================================
% Akaike plot button.
elseif action1==12

  outctrlval=get(findobj(figNumber,Tag,rsoutctrlTag),Value);
  identmodel=get(findobj(figNumber,Tag,polmenuTag),UserData);
  afpe=identmodel(:,8,outctrlval); qcon=size(identmodel,1);
  pronysave=get(findobj(figNumber,Tag,rstrctrl1Tag),UserData);
  curout=pronysave.actoutlist(outctrlval);
  akplotTag=['akplot' int2str(figNumber)];
  figHndl=findobj(0,Tag,akplotTag,OType,figstr);
  if isempty(figHndl)
    axesForeColor=get(figNumber,DAxesXColor); axesGrid=get(figNumber,DAxesXGrid);
    axesFontName=get(figNumber,DAxesFontName); axesFontSize=get(figNumber,DAxesFontSize);
    figHndl=figure(Tag,['newpltfig' int2str(figNumber)],Color,get(figNumber,Color), ...
      DAxesBox,onstr,DAxesColor,get(figNumber,DAxesColor), ...
      DAxesXColor,axesForeColor,DAxesYColor,axesForeColor, ...
      DAxesXGrid,axesGrid,DAxesYGrid,axesGrid, ...
      DAxesColorOrder,get(figNumber,DAxesColorOrder), ...
      DAxesLineStyleOrder,get(figNumber,DAxesLineStyleOrder), ...
      DAxesFontName,axesFontName,DAxesFontSize,axesFontSize,DTextColor,axesForeColor, ...
      DTextFontName,axesFontName,DTextFontSize,axesFontSize);
  else
%    set(figHndl,Tag,['newpltfig' int2str(figNumber)]);
    set(0, 'CurrentFigure', figHndl);           % set current figure
  end
  clrs=get(findobj(figNumber,Tag,prfmenuTag),UserData);
  newlinHndls=plot(1:qcon,afpe,Color,clrs(4,:));        % the figHndl Tag is lost after this plot. Weird!!! Henry
  newaxesHndl=gca;
  title(['Akaike Final Prediction Error for Signal ' int2str(curout) '.']);
  set(newaxesHndl,UserData,newlinHndls); set(figHndl,UserData,newaxesHndl);
  set(figHndl,Tag,['newpltfig' int2str(figNumber)]);    % set Tag just before rguimgr(17,6) to make the Tag is passed down properly. Henry, 04/24/03
%  get(figHndl,Tag)          % debug. Henry
  xlabel('Number of Modes'); rguimgr(17,6,figNumber);
  if ishandle(figHndl); set(figHndl,Tag,akplotTag); end

  return;

%============================================================================
% Copy mode table menu.
elseif action1==14

% action2==1 ==> Copy mode parameters only.
% action2==2 ==> Copy mode parameters, include FF term and SNR.

  outctrlval=get(findobj(figNumber,Tag,rsoutctrlTag),Value);
  identmodel=get(findobj(figNumber,Tag,polmenuTag),UserData);
  identmodel=identmodel(:,:,outctrlval);
  rowind=identmodel(:,9); nnrow=nnz(rowind);
  if ~nnrow; errordlg('No modes selected.','Error'); return; end
  if action2==2; nnrow=nnrow+4; else; nnrow=nnrow+3; end; cellHt=1/nnrow;

  oldUnits=get(0,Units); set(0,Units,pixelstr);
  screensize=get(0,'ScreenSize'); set(0,Units,oldUnits);
  mtblHndl=findobj(figNumber,Tag,mtblTag,OType,axesstr);
  mttextHndls=get(mtblHndl,UserData); vcells=size(mttextHndls,1)-3;
  oldUnits=get(mtblHndl,Units); set(mtblHndl,Units,pixelstr);
  mtblPos=get(mtblHndl,Position); set(mtblHndl,Units,oldUnits);
  mtblLeft=40; mtblyPos=30; mtblHt=nnrow*mtblPos(4)/(vcells+4);
  mtblPos=[mtblLeft mtblyPos mtblPos(3) mtblHt];
  axesForeColor=get(mtblHndl,XColor);

  figWid=2*mtblLeft+mtblPos(3); figLeft=(screensize(3)-figWid)/2;
  figHt=2*mtblyPos+mtblHt; figyPos=max((screensize(4)-figHt)/2,0);

  figHndl=figure(Tag,['mtfig' int2str(figNumber)],Units,pixelstr, ...
    Position,[figLeft figyPos figWid figHt],Color,get(figNumber,Color), ...
    DAxesBox,onstr,DAxesColor,get(mtblHndl,Color),DAxesXColor,axesForeColor, ...
    DAxesYColor,axesForeColor,DTextColor,axesForeColor, ...
    DTextFontName,get(figNumber,DTextFontName), ...
    DTextFontSize,get(figNumber,DTextFontSize), ...
    'DefaultTextHorizontalAlign','center');

  newmtblHndl=axes(Tag,mtblTag,Units,pixelstr,Position,mtblPos, ...
    XLim,[0 1],YLim,[0 1],'XTick',[],'YTick',[], ...
    ColorOrder,axesForeColor,'LineStyleOrder',dashstr);

  h=line([0 1],[cellHt; cellHt]*[1:nnrow-3]);
  if action2==1
    linydata=[0 1];
    textxPos=ones(nnrow,1)*[0.0500 0.2125 0.4375 0.6625 0.8875];
    textyPos=(0.5+[0:nnrow-1])/nnrow; h=zeros(nnrow,5);
  else
    set(h(1),LineWidth,5*get(h(1),LineWidth));
    line([0.5 0.5],[0 cellHt]); linydata=[cellHt 1];
    text(0.25,cellHt/2,get(findobj(figNumber,Tag,ffindTag),String));
    text(0.75,cellHt/2,get(findobj(figNumber,Tag,snrindTag),String));
    textxPos=ones(nnrow-1,1)*[0.0500 0.2125 0.4375 0.6625 0.8875];
    textyPos=(0.5+[1:nnrow-1])/nnrow; h=zeros(nnrow-1,5);
  end
  line([0.100; 0.325; 0.550; 0.775]*[1 1],linydata);
  for ii=1:5; h(:,ii)=text(textxPos(:,ii),textyPos,spacestr); end
  %set(h(size(h,1),1),String,'Mode'); set(newmtblHndl,Units,'norm',UserData,h);
  set(h(size(h,1),1),String,'Mode Type'); set(newmtblHndl,Units,'norm',UserData,h);     % Henry, 04/03/03
  rguimgr(5,9,figNumber); set(newmtblHndl,UserData,[]);
  set(figHndl,Tag,['newpltfig' int2str(figNumber)],UserData,newmtblHndl);
  rguimgr(17,7,figNumber);

  return;

%============================================================================
% Copy plot to figure.
elseif action1==15

% action2==1 ==> Copy Time Response plot to a figure.
% action2==2 ==> Copy Frequency Spectrum plots to a figure.
% action2==3 ==> Copy Magnitude plot to a figure.
% action2==4 ==> Copy Phase plot to a figure.
% action2==5 ==> Copy Pole-Zero plot to a figure.

  ssvis=strcmp(get(findobj(figNumber,Tag,ssoutctrlTag),Visible),onstr);
  if ssvis
    setLineWidth = questdlg('Would you like to set different line width?','Line width');       % ask if the line width should be set differently. Henry, 08/30/03
    if strcmp(setLineWidth, 'Cancel'); return; end      % if 'Cancel', do nothing. Henry, 08/30/03
    switch action2
      case 1, h=sstraxesTag;
      case 2, h=ssfraxs1Tag; h2=ssfraxs2Tag;
      case 3, h=ssfraxs1Tag;
      otherwise, h=ssfraxs2Tag;
    end
  else
    switch action2
      case 1, h=rstraxesTag;
      case 2, h=rsfraxs1Tag; h2=rsfraxs2Tag;
      case 3, h=rsfraxs1Tag;
      case 4, h=rsfraxs2Tag;
      otherwise, h=rspzaxesTag;
    end
  end

  axesHndl=findobj(figNumber,Tag,h,OType,axesstr);
  axesForeColor=get(figNumber,DAxesXColor); axesGrid=get(figNumber,DAxesXGrid);
  axesFontName=get(figNumber,DAxesFontName); axesFontSize=get(figNumber,DAxesFontSize);
  clrs=get(findobj(figNumber,Tag,prfmenuTag),UserData);
  if action2==2; axesHndl=[axesHndl; findobj(figNumber,Tag,h2,OType,axesstr)]; end

  figHndl=figure(Tag,['newpltfig' int2str(figNumber)],Color,get(figNumber,Color), ...
    DAxesBox,onstr,DAxesColor,get(figNumber,DAxesColor),DAxesXColor,axesForeColor, ...
    DAxesYColor,axesForeColor,DAxesXGrid,axesGrid,DAxesYGrid,axesGrid, ...
    DAxesColorOrder,get(figNumber,DAxesColorOrder), ...
    DAxesLineStyleOrder,get(figNumber,DAxesLineStyleOrder), ...
    DAxesFontName,axesFontName,DAxesFontSize,axesFontSize,DTextColor,axesForeColor, ...
    DTextFontName,axesFontName,DTextFontSize,axesFontSize);

  newaxesHndl=axes;
  if action2==2
    axesPos=get(newaxesHndl,Position); newaxesHt=axesPos(4)/2-0.020;
    newaxs1Pos=[axesPos(1) axesPos(2)+newaxesHt+0.040 axesPos(3) newaxesHt];
    newaxs2Pos=[axesPos(1) axesPos(2) axesPos(3) newaxesHt];
    set(newaxesHndl,Position,newaxs1Pos); 
    newaxesHndl=[newaxesHndl; axes(Position,newaxs2Pos)];
  end

  linHndls=get(axesHndl(1),UserData);
  xlimit=get(axesHndl(1),XLim); ylimit=get(axesHndl(1),YLim);
  if action2<5
    xdat=get(linHndls(1,1),XData); ind=find(xdat>=xlimit(1) & xdat<=xlimit(2));
    xdat=xdat(ind); nnsigs=size(linHndls,1); ydat=zeros(nnsigs,length(ind));
    for ii=1:nnsigs; ydat2=get(linHndls(ii,1),YData); ydat(ii,:)=ydat2(ind); end
    axes(newaxesHndl(1)); newlinHndls=plot(xdat,ydat);
    set(newaxesHndl(1),XLim,xlimit,YLim,ylimit,UserData,newlinHndls); h=size(clrs,1)-3;
    legendStr = [];             % legend, Henry, 06/27/03
    legendColor = [];
    legendWidth = [];
    legendStyle = [];
    for ii=1:nnsigs; 
        lineStyle = '-';                                    % Henry
        if ssvis & strcmp(setLineWidth, 'Yes')              % add ssvis to avoid use line width for results screen, Henry, 10/14/03
            lineWidth = 0.5+floor((ii-1)/h);                  % calculate line width. Henry, 08/29/03
        else
            lineWidth = 1;                  % calculate line width. Henry, 08/29/03
        end
        set(newlinHndls(ii),Color,clrs(rem(ii,h)+3,:), 'LineWidth', lineWidth, 'LineStyle', lineStyle);     % Add line width and style, Henry, 08/30/03
        legendStr = [legendStr; sprintf('Output %3d',ii)];            % legend, Henry, 06/27/03
        legendColor = [legendColor; clrs(rem(ii,h)+3,:)];
        legendWidth = [legendWidth; lineWidth];
        legendStyle = [legendStyle; lineStyle];
    end
%    if nnsigs < 20; legendLen = nnsigs; else; legendLen = 20; end     % legend, Henry, 06/27/03
%    if ssvis; legend(linHndls(1:legendLen,1),legendStr(1:legendLen,:)); end       % legend if copy plots in setup screen, Henry, 06/27/03
    if action2==1
      if size(linHndls,2)==3
        for jj=2:3
          for ii=1:nnsigs
            h=linHndls(ii,jj);
            line(get(h,XData),get(h,YData),Color,get(h,Color),LineStyle,dashstr);
          end
        end
      end
      h2=findobj(axesHndl,Tag,tzlinTag);
      if ~isempty(h2) & xlimit(1)<0 & xlimit(2)>0
        line([0 0],get(h2,YData),Color,axesForeColor,LineStyle,'--');
      end
    elseif action2==2
      set(newaxesHndl(1),XTickLabel,[]);
      ylimit=get(axesHndl(2),YLim); linHndls=get(axesHndl(2),UserData);
      for ii=1:nnsigs; ydat2=get(linHndls(ii,1),YData); ydat(ii,:)=ydat2(ind); end
      axes(newaxesHndl(2)); newlinHndls=plot(xdat,ydat);
      set(newaxesHndl(2),XLim,xlimit,YLim,ylimit,UserData,newlinHndls); h=size(clrs,1)-3;
      for ii=1:nnsigs; 
          lineStyle = '-';                                  % Henry
        if ssvis & strcmp(setLineWidth, 'Yes')              % add ssvis to avoid use line width for results screen, Henry, 10/14/03
              lineWidth = 0.5+floor((ii-1)/h);                  % calculate line width. Henry, 08/29/03
          else
              lineWidth = 1;                  % calculate line width. Henry, 08/29/03
          end
          set(newlinHndls(ii),Color,clrs(rem(ii,h)+3,:), 'LineWidth', lineWidth, 'LineStyle', lineStyle);     % Add line width and style, Henry, 08/30/03 
      end
    end
  else
    if ~isempty(linHndls)
      polr=get(linHndls(1),XData); poli=get(linHndls(1),YData);
      zerr=get(linHndls(2),XData); zeri=get(linHndls(2),YData);
      newlinHndls=plot(polr,poli,'x',zerr,zeri,'o');
      set(newlinHndls(1),Color,clrs(4,:)); set(newlinHndls(2),Color,clrs(5,:));
    else
      newlinHndls=[];
    end
    set(newaxesHndl,XLim,xlimit,YLim,ylimit,UserData,newlinHndls);
    line([0 0],ylimit,Color,axesForeColor,LineStyle,axeslinStyle);
    line(xlimit,[0 0],Color,axesForeColor,LineStyle,axeslinStyle);
  end

  if action2==1
    title('Time Response'); xlabel('Time (sec)');
  elseif action2<5
    if ssvis
      tit='Discrete Fourier Transform Spectrum';
    else
      tit='Signal Spectrum and Model Response';
    end
    if action2==2
      axes(newaxesHndl(1)); title(tit); ylabel(frmylabstr);
      axes(newaxesHndl(2)); xlabel(frxlablstr); ylabel(frpylabstr);
    else
      title(tit); xlabel(frxlablstr);
      if action2==3; ylabel(frmylabstr); else; ylabel(frpylabstr); end
    end
  else
    title('Pole-Zero Plot'); xlabel('Real Axis'); ylabel('Imaginary Axis');
  end

  % Legend, Henry Huang (PNNL), Aug. 28, 2003
  if ssvis      % legend is only needed for setup screen
      % create title strings
      setupcon2=get(findobj(figNumber,Tag,ssdectrlTag),UserData);
      actoutlist=find(setupcon2(1,:));
      outctrlval = get(findobj(figNumber,Tag,ssoutctrlTag),Value);    % for multi signals
      if outctrlval == 1           % multi signals
        nnactout=length(actoutlist); 
        legendStr=cell(nnactout,1);
        for ii=1:length(actoutlist)
          outsubmenuHndl=findobj(figNumber,Tag,sprintf('%s%d',outsubmenuTag,actoutlist(ii)));
          legendStr{ii}=get(outsubmenuHndl,UserData);
        end
      else
        curout=actoutlist(outctrlval - 1);      % current signal
        outsubmenuHndl=findobj(figNumber,Tag,sprintf('%s%d',outsubmenuTag,curout));
        legendStr=get(outsubmenuHndl,UserData);
      end

      creatlegend(legendStr, legendWidth, legendColor, legendStyle);
  end
  % end, Legend, Henry Huang (PNNL), Aug. 28, 2003

  
  set(figHndl,UserData,newaxesHndl); 
  rguimgr(17,action2,figNumber);

  return;

%============================================================================
% Perform the Prony analysis.
  elseif action1==16

    outmenuHndl=findobj(figNumber,Tag,outmenuTag); outdat=get(outmenuHndl,UserData);
    filmenuHndl=findobj(figNumber,Tag,filmenuTag); inpulses=get(filmenuHndl,UserData);
    polmenuHndl=findobj(figNumber,Tag,polmenuTag); identmodel=get(polmenuHndl,UserData);
    paindHndl=findobj(figNumber,Tag,'paind'); polenbl=get(polmenuHndl,Enable);
    stctrlHndl=findobj(figNumber,Tag,stctrlTag); setupcon1=get(stctrlHndl,UserData);
    tstep=setupcon1(1); nnout=setupcon1(2); startindex=setupcon1(3);
    tstart=tstep*(startindex-1); df=setupcon1(4); dftstep=df*tstep;
    filtcf=setupcon1(5); fc=setupcon1(6); knwpol=setupcon1(7); fcknwpol=fc*knwpol;
    lpmcon=setupcon1(8); fbcon=setupcon1(9); lpocon=setupcon1(11); ftrh=setupcon1(12);
    ftrl=setupcon1(13); trre=setupcon1(14);
    setupcon2=get(findobj(figNumber,Tag,ssdectrlTag),UserData);
    actoutlist=find(setupcon2(1,:)); nnactout=length(actoutlist);
    ds=setupcon2(2,actoutlist); ind0=isnan(ds); endindex=setupcon2(3,actoutlist);
    dtmodes=setupcon2(4,actoutlist); dtiniindex=setupcon2(5,actoutlist);
    dtendindex=setupcon2(6,actoutlist); filtout=setupcon2(7,:);

    endindmax=startindex+df*(fix((nnout-startindex)/df)-fcknwpol);
    endind=min(endindmax,startindex+df*fix((endindex-startindex)/df));

    if any(ind0)
      minshift=zeros(1,nnz(ind0)); ninputs=size(inpulses,1);
      if ninputs
        instep=startindex+df*fix(inpulses(end,1)/dftstep+ep)>=endind(logical(ind0));
        ind1=find(ninputs-instep>0);
        minshift(ind1)=fix(inpulses(ninputs-instep(ind1),1)/dftstep+ep)+1;
      end
      ds(ind0)=minshift;
    end

    % Logic used in PRSPAK to check number of data points. 
    % and check the number of signals. Henry, 05/20/03
    nnfit=(endind-startindex)/df-ds+1; tnnfit=sum(nnfit); ntaille=8192; 
    maxnnout = 20;                     % Henry, 05/20/03
    if fbcon==2; h=ntaille/2; else; h=ntaille; end
    if lpmcon==1; maxtnnfit=floor(2*(h-2)/3); else; maxtnnfit=h-2; end
    maxnnfit=min([ntaille-ds-fcknwpol maxtnnfit]);
    
    if length(nnfit) > 20               % Henry, 05/20/03
      str=sprintf('Number of signals should not exceed %d.',maxnnout);
      errordlg(str,'Prony Analysis Error','modal');
      return;
    end
    
    if tnnfit>=maxtnnfit | any(nnfit>=maxnnfit)
      str=cell(2,1);
      str{1}=sprintf('Number of points from each signal must be less than %d.',maxnnfit);
      str{2}=sprintf('Total number of points must be less than %d.',maxtnnfit);
      errordlg(str,'Prony Analysis Error','modal');
      return;
    end

    menuHndls=[filmenuHndl; findobj(figNumber,Tag,copmenuTag); outmenuHndl; ...
      polmenuHndl; findobj(figNumber,Tag,'scrmenu')];
    set(figNumber,Pointer,watchstr); set(menuHndls,Enable,offstr);
    rguimgr(7,2,figNumber); drawnow;

    filtmod=get(findobj(figNumber,Tag,ssfiltctrlTag),Value);
    if filtmod
      outdat=rguifilt(outdat(:,actoutlist+1),tstep,filtcf);
    else
      outdat=outdat(:,actoutlist+1);
    end

    if any(dtmodes)
      startindexd=fix((startindex-1)/df)+1;
      ind0=startindex-df*(startindexd-1):df:size(outdat,1);
      ind1=logical(isnan(dtiniindex));
      dtiniindex(ind1)=startindex+df*ds(ind1); dtendindex(ind1)=endind(ind1);
      dtiniindexd=startindexd+fix((dtiniindex-startindex)/df);
      dtendindexd=startindexd+fix((dtendindex-startindex)/df);
      outdat0=rguidt(outdat(ind0,:),dtiniindexd,dtendindexd,dtmodes);
      trndpts=outdat(ind0([1 2]),:)-outdat0([1 2],:);
      trndln=[1; -ind0(1)]*diff(trndpts)/df+[zeros(1,nnactout); trndpts(1,:)];
      ind0=startindex:max(endind);
      
      thrudat=outdat(ind0,:)-[ind0'-1 ones(length(ind0),1)]*trndln;
      outdat=outdat0(startindexd+(0:(max(endind)-startindex)/df),:);
    else
      trndln=zeros(2,nnactout);
      thrudat=outdat(startindex:max(endind),:);
      outdat=outdat(startindex:df:max(endind),:);
    end

    polsubmenuHndls=findobj(polmenuHndl,Tag,polsubmenuTag,Checked,onstr);
    allpolsubmenuHndl = findobj(polmenuHndl,Position, 2);       % all pole submenu. Henry, 06/02/03
    polsubmenuHndls = setdiff(polsubmenuHndls, allpolsubmenuHndl);    % take allpolsubmenuHndl out of the polsubmenuHndls
    nnknwmod=length(polsubmenuHndls); knwmod=zeros(nnknwmod,2);
    for ii=1:nnknwmod
      %knwmod(ii,:)=identmodel(get(polsubmenuHndls(ii),Position)-1,1:2,1);
      knwmod(ii,:)=identmodel(get(polsubmenuHndls(ii),Position)-2,1:2,1);   % for adding "select all" function in pole submenu. Henry, 06/02/03
    end

  % xcon(1)=modes; xcon(2)=scalmod; xcon(3)=lpocon; xcon(4)=pircon;
  % xcon(5)=dmodes; xcon(6)=lpmcon; xcon(7)=lpacon; xcon(8)=fbcon;
  % xcon(9)=ordcon; xcon(10)=trimre; xcon(11)=ftrimh; xcon(12)=ftriml;
    xcon=-ones(12,1);
    xcon(1)=-fc; xcon(2)=get(findobj(figNumber,Tag,scctrlTag),Value);
    if get(findobj(figNumber,Tag,lpoctrl2Tag),Value); xcon(3)=lpocon; end
    xcon(6)=lpmcon; xcon(7)=get(findobj(figNumber,Tag,lpactrlTag),Value);
    xcon(8)=fbcon; xcon(9)=get(findobj(figNumber,Tag,ordctrlTag),Value);
    if get(findobj(figNumber,Tag,trrectrl2Tag),Value); xcon(10)=trre; end
    if get(findobj(figNumber,Tag,ftrhctrl2Tag),Value); xcon(11)=ftrh; end
    if get(findobj(figNumber,Tag,ftrlctrl2Tag),Value); xcon(12)=ftrl; end

    h=[ds; nnfit]; set(paindHndl,Visible,onstr); drawnow;
    [identmodel,xcon,wrnerr,mret]=prgv2_5(outdat,dftstep,h,inpulses,knwmod,xcon);
    set(paindHndl,Visible,offstr); drawnow;

    if isempty(mret)
      if isempty(wrnerr); wrnerr=cell(0,0); else; wrnerr=cellstr(char(wrnerr)); end
      %delete(findobj(polmenuHndl,Tag,polsubmenuTag)); 
      qcon=size(identmodel,1);
      identmodel=reshape(identmodel,qcon,8,size(identmodel,2)/8);
      %dampf=identmodel(:,1,1); frqrps=identmodel(:,2,1);
      %h=[[dampf frqrps]/2/pi dampf./sqrt(dampf.^2+frqrps.^2)];
      %for ii=1:qcon
      %  if frqrps(ii)<1e-8
      %    menustr=sprintf('% 12.4e     % 12.4e        -----',h(ii,2),h(ii,1));
      %  else
      %    menustr=sprintf('% 12.4e     % 12.4e     % 12.4e',h(ii,2),h(ii,1),h(ii,3));
      %  end
      %  uimenu(polmenuHndl,Tag,polsubmenuTag,Label,menustr, ...
      %    'CallBack','ringdown(''rguimgr(1,4);'');');
      %end
      %set(polmenuHndl,UserData,cat(2,identmodel,zeros(qcon,1,nnactout)));
      %set(polmenuHndl,UserData,cat(2,identmodel,zeros(qcon,2,nnactout)));   % add one more column (10th) for mode types, Henry

      identmodel = cat(2,identmodel,zeros(qcon,2,nnactout));        % one column (9th) for colors. add one more column (10th) for mode types, Henry
      
      FLIM1 = 1.0; FLIM2 = 1.8; DLIM1 = 0.15; DLIM2 = 0.15;                                % range to determine mode types. DLIM2 is not used yet. Henry, 04/28/03
      set(findobj(figNumber,Tag,sortctrlTag),Value,4,UserData,4);                          % Sorting criterion. Henry, Mar. 20, 2003
      set(findobj(figNumber,Tag,rsDLIM1ctrlTag),String,num2str(DLIM1),UserData,DLIM1);             % Damping ratio limit. Henry, 03/25/03
      set(findobj(figNumber,Tag,rsFLIM1ctrlTag),String,num2str(FLIM1),UserData,FLIM1);             % Low freq limit. Henry, 03/25/03
      set(findobj(figNumber,Tag,rsFLIM2ctrlTag),String,num2str(FLIM2),UserData,FLIM2);             % High freq limit. Henry, 03/25/03

      % As a default, sort by mode type. Henry, 04/28/03
        %Mode types:
        % 1) Simple trends:             0 == freq                         
        % 2) Oscillatory trends:        0 <  freq < FLIM2 & DLIM1 <= dampRatio   
        % 3) Interarea oscillations:    0 <  freq <=FLIM1 &     0 <  dampRatio <  DLIM1   
        % 4) Local oscillations:    FLIM1 <= freq < FLIM2 &     0 <  dampRatio <  DLIM1   
        % 5) Unstable oscillations:     0 <= freq < FLIM2 &          dampRatio <= 0   
        % 6) Fast noise:            FLIM2 <= freq    
        outctrlval = 1;
        sigma = identmodel(:, 1, outctrlval)/2/pi; freq = identmodel(:, 2, outctrlval)/2/pi;
        dampRatio = sigma ./ sqrt(sigma.^2 + freq.^2);
        for n = 1 : qcon            % the 10th column in "identmodel" is for mode type
            if                      (freq(n)  <  FLIM2) & (DLIM1 <= dampRatio(n))                     , identmodel(n, 10, outctrlval) = 2; end 
            if                      (freq(n)  <= FLIM1) & (0 < dampRatio(n)) & (dampRatio(n) < DLIM1) , identmodel(n, 10, outctrlval) = 3; end 
            if (FLIM1 <= freq(n)) & (freq(n)  <  FLIM2) & (0 < dampRatio(n)) & (dampRatio(n) < DLIM1) , identmodel(n, 10, outctrlval) = 4; end 
            if                      (freq(n)  <  FLIM2) & (dampRatio(n) <= 0)                         , identmodel(n, 10, outctrlval) = 5; end 
            if                      (FLIM2    <= freq(n) )                                            , identmodel(n, 10, outctrlval) = 6; end 
            if (freq(n) < 1e-8 )                                                                      , identmodel(n, 10, outctrlval) = 1; end 
        end
        [identmodel(:, :, outctrlval), locs] = sortrows(identmodel(:, :, outctrlval), [10 2]);    % sort by type then by freq

        % update the pole menu
        polmenuHndl = findobj(figNumber, Tag, polmenuTag);
        set( polmenuHndl, UserData, identmodel);
  
        delete( findobj(polmenuHndl, Tag, polsubmenuTag));    % delete old pole submenus
        
        uimenu(polmenuHndl,Tag,polsubmenuTag,Label,'All poles', ...
            'CallBack','ringdown(''rguimgr(1,4);'');');                 % Add "select all" function for pole submenu. Henry, 06/02/03
        
        h = [sigma freq dampRatio];
        for n = 1 : qcon
          if freq(n)<1e-8
            menustr = sprintf('% 12.4e     % 12.4e        -----', h(n, 2), h(n, 1));
          else
            menustr = sprintf('% 12.4e     % 12.4e     % 12.4e', h(n, 2), h(n, 1), h(n, 3));
          end
          uimenu(polmenuHndl, Tag, polsubmenuTag, Label, menustr, ...
            'CallBack','ringdown(''rguimgr(1,4);'');');
        end
      % End - As a default, sort by mode type. Henry, 04/28/03
            
      setupcon1(6)=1; setupcon1(7)=0; set(stctrlHndl,UserData,setupcon1);
      set(findobj(figNumber,Tag,fcctrlTag),Value,1);
      set(findobj(figNumber,Tag,rrctrlTag),Value,0);

      pronysave.actoutlist=actoutlist; pronysave.tstart=tstart; pronysave.tstep=tstep;
      pronysave.tini=dftstep*ds; pronysave.tend=tstep*(endind-startindex);
      pronysave.df=df; pronysave.nnfit=nnfit; pronysave.filtmod=filtmod;
      pronysave.filtcf=filtcf; pronysave.scalmod=xcon(2); pronysave.dtmodes=dtmodes;
      pronysave.dttini=tstep*(dtiniindex-startindex);
      pronysave.dttend=tstep*(dtendindex-startindex);
      pronysave.lpmcon=xcon(6); pronysave.fbcon=xcon(8); pronysave.lpacon=xcon(7);
      pronysave.ordcon=xcon(9); pronysave.lpocon=xcon(3); pronysave.pircon=xcon(4);
      pronysave.ftrimh=xcon(11); pronysave.ftriml=xcon(12); pronysave.trimre=xcon(10);
      pronysave.vdocon=xcon(5); pronysave.wrnerr=wrnerr;

      resultcon.nnout=nnout; resultcon.startindex=startindex; resultcon.ds=ds;
      resultcon.endindex=endind; resultcon.df=0; resultcon.filtmod=filtmod;
      resultcon.filtcf=filtcf; % resultcon.dtmodes=zeros(1,nnactout);
      resultcon.dtmodes=dtmodes;                            % get dtmodes from setup screen. Henry, 04/28/03
      resultcon.trindex1=NaN*ones(1,nnactout); resultcon.trindex2=resultcon.trindex1;
      resultcon.trndln=trndln; resultcon.incthru=zeros(1,nnactout);
      resultcon.thrudat=thrudat; resultcon.thru=resultcon.incthru;
      resultcon.timdat=[]; resultcon.outdat=[]; resultcon.moddat=[];
      resultcon.trlim1=NaN*ones(1,nnactout); resultcon.trlim2=resultcon.trlim1;
      resultcon.frlim1=resultcon.trlim1; resultcon.frlim2=resultcon.trlim1;
      resultcon.pzxlim1d=-1.1*ones(1,nnactout); resultcon.pzxlim1=resultcon.trlim1;
      resultcon.pzxlim2d= 0.1*ones(1,nnactout); resultcon.pzxlim2=resultcon.trlim1;
      resultcon.pzylim1d=-0.1*ones(1,nnactout); resultcon.pzylim1=resultcon.trlim1;
      resultcon.pzylim2d= 1.1*ones(1,nnactout); resultcon.pzylim2=resultcon.trlim1;
      
      pltctrls=get(findobj(figNumber,Tag,sstrctrl1Tag),UserData);                   % freqnecy plot limits from setup screen. Henry, 04/28/03
      resultcon.frlim1=pltctrls(3,1)*ones(1,nnactout); resultcon.frlim2=pltctrls(4,1)*ones(1,nnactout);      % pass the freqnency plot limits to result screen. Henry, 04/28/03

      h=sprintf('Output %i|',actoutlist); h=h(1:end-1);
      set(findobj(figNumber,Tag,rsoutctrlTag),String,h,Value,1,UserData,1);
      vcells=9; h=sprintf('Page %i|',1:floor(qcon/vcells)+1); h=h(1:end-1);
      set(findobj(figNumber,Tag,mtpgctrlTag),String,h,Value,1,UserData,1);

      set(findobj(figNumber,Tag,mtcol2ctrlTag),Value,1,UserData,1);
      set(findobj(figNumber,Tag,mtcol3ctrlTag),Value,3,UserData,3);                        % change default column. Henry, 04/22/03
      set(findobj(figNumber,Tag,mtcol4ctrlTag),Value,4,UserData,4);                        % change default column. Henry, 04/22/03
      set(findobj(figNumber,Tag,mtcol5ctrlTag),Value,5,UserData,5);                        % change default column. Henry, 04/22/03
      %set(findobj(figNumber,Tag,mtcol3ctrlTag),Value,2,UserData,2);
      %set(findobj(figNumber,Tag,mtcol4ctrlTag),Value,3,UserData,3);
      %h=xcon(9)+9; set(findobj(figNumber,Tag,mtcol5ctrlTag),Value,h,UserData,h);
      set(findobj(figNumber,Tag,rstrctrl1Tag),UserData,pronysave);
      set(findobj(figNumber,Tag,rstrctrl2Tag),UserData,resultcon);
      set(findobj(figNumber,Tag,rsfiltctrlTag),Value,filtmod);
      set(findobj(figNumber,Tag,rscfctrlTag),String,num2str(filtcf));
      h=get(findobj(figNumber,Tag,ssfrctrlTag),Value);
      set(findobj(figNumber,Tag,rsfrctrlTag),Value,h);
      set(findobj(figNumber,Tag,rsdectrlTag),Value,0);
      h=get(findobj(figNumber,Tag,ssfillctrlTag),Value);
      set(findobj(figNumber,Tag,rsfillctrlTag),Value,h);
      h=get(findobj(figNumber,Tag,sswinctrlTag),Value);
      set(findobj(figNumber,Tag,rswinctrlTag),Value,h);
      rguimgr(5,1,figNumber); set(menuHndls,Enable,onstr);
      set(findobj(figNumber,Tag,rsmenuTag),Enable,onstr);
      set(findobj(figNumber,Tag,expmenuTag),Enable,onstr);
      rguimgr(7,3,figNumber); if ~isempty(wrnerr); warndlg(wrnerr,'Warning(s)'); end
    else
      set(menuHndls,Enable,onstr); set(polmenuHndl,Enable,polenbl);
      rguimgr(7,1,figNumber); errordlg(mret,'Prony Analysis Error');
    end
    drawnow; set(figNumber,Pointer,arrowstr);

  return;

%============================================================================
% Prepare inputs for and execute user defined copyplot function.
elseif action1==17

% action2==1 ==> Time Response plot copied to a figure.
% action2==2 ==> Frequency Spectrum plots copied to a figure.
% action2==3 ==> Magnitude plot copied to a figure.
% action2==4 ==> Phase plot copied to a figure.
% action2==5 ==> Pole-Zero plot copied to a figure.
% action2==6 ==> Akaike plot copied to a figure.
% action2==7 ==> Mode Table copied to a figure.

  figHndl=findobj(0,Tag,['newpltfig' int2str(figNumber)],OType,figstr);
  
  opts=get(findobj(figNumber,Tag,copmenuTag),UserData); copyplotfcn=opts.copyplotfcn;
  if ~isempty(copyplotfcn)
    if exist([copyplotfcn '.m'])~=2
      errordlg(['Error unable to locate function ''' copyplotfcn '''.'],'Error');
      return;
    end
    axesHndl=get(figHndl,UserData); linHndls=get(axesHndl,UserData);
    switch action2
      case 1, plottypes='tr';
      case 2, plottypes=cell(2,1); plottypes{1}='frm'; plottypes{2}='frp';
      case 3, plottypes='frm';
      case 4, plottypes='frp';
      case 5, plottypes='pz';
      case 6, plottypes='ak';
      otherwise, plottypes='mtbl';
    end
    if strcmp(get(findobj(figNumber,Tag,ssoutctrlTag),Visible),onstr)
      setupcon2=get(findobj(figNumber,Tag,ssdectrlTag),UserData);
      actoutlist=find(setupcon2(1,:));
      outctrlval = get(findobj(figNumber,Tag,ssoutctrlTag),Value);    % for multi-signal setting. Henry, 04/07/03
      if outctrlval == 1           % multi-signal setting. Henry, 04/07/03
      %if get(findobj(figNumber,Tag,msigctrlTag),Value)
        nnactout=length(actoutlist); titles=cell(nnactout,1);
        for ii=1:length(actoutlist)
          outsubmenuHndl=findobj(figNumber,Tag,sprintf('%s%d',outsubmenuTag,actoutlist(ii)));
          titles{ii}=get(outsubmenuHndl,UserData);
        end
      else
        %curout=actoutlist(get(findobj(figNumber,Tag,ssoutctrlTag),Value));
        curout=actoutlist(outctrlval - 1);      % for multi-signal setting. Henry, 04/07/03
        outsubmenuHndl=findobj(figNumber,Tag,sprintf('%s%d',outsubmenuTag,curout));
        titles{1}=get(outsubmenuHndl,UserData);
      end
    else
      pronysave=get(findobj(figNumber,Tag,rstrctrl1Tag),UserData);
      curout=pronysave.actoutlist(get(findobj(figNumber,Tag,rsoutctrlTag),Value));
      outsubmenuHndl=findobj(figNumber,Tag,sprintf('%s%d',outsubmenuTag,curout));
      titles{1}=get(outsubmenuHndl,UserData); if action2==2; titles{2,1}='Model'; end
    end
    figInfo.figHndl=figHndl; figInfo.axesHndls=axesHndl; figInfo.lineHndls=linHndls;
    figInfo.plottypes=plottypes; figInfo.titles=titles;
    h=0; eval('feval(copyplotfcn,figInfo,opts.copyplotargs{:});','h=1;');
    if h; errordlg(['Error evaluating ''' copyplotfcn '''.'],'Error'); end
  end

  if (exist('axesHndl'))
    if ishandle(axesHndl); set(axesHndl,UserData,[]); end
  end
  if ishandle(figHndl); set(figHndl,Tag,emptystr,UserData,[],NextPlot,replacestr); end

%============================================================================
% Added by Huang, Zhenyu (Henry), Mar. 21, 2003 -----------------------------
% Sort modes according to the criterion slected by user.
elseif action1 == 18

% action2==1 ==> Sort modes according to the criterion slected by user.
% action2==2 ==> Sort modes when low freq limit is changed.
% action2==3 ==> Sort modes when high freq limit is changed.
% action2==4 ==> Sort modes when damping ratio limit is changed.
% action2==5 ==> Sort modes when DLIM2 is changed. (reserved)
% action2==6 ==> Sort modes when the output # is changed.

  if action2 == 1      
    sortctrlHndl = gco; sortctrlval=get(sortctrlHndl,Value);        % get selected sorting criterion
    if sortctrlval == get(sortctrlHndl,UserData); return; end          % no need to re-sort
    set(sortctrlHndl,UserData,sortctrlval);                             % save current sorting creterion
  end
  if action2 == 2
    rsFLIM1ctrlHndl = findobj(figNumber,Tag,rsFLIM1ctrlTag);
    FLIM1 = str2num( get(rsFLIM1ctrlHndl, String) );       % FLIM1
    if isempty(FLIM1); FLIM1 = get(rsFLIM1ctrlHndl,UserData); set(rsFLIM1ctrlHndl,String,num2str(FLIM1)); return; end
    if FLIM1 == get(rsFLIM1ctrlHndl,UserData); return; end          % no need to re-sort
    set(rsFLIM1ctrlHndl,UserData,FLIM1);                             % save current low freq limit 
  end
  if action2 == 3
    rsFLIM2ctrlHndl = findobj(figNumber,Tag,rsFLIM2ctrlTag);
    FLIM2 = str2num( get(rsFLIM2ctrlHndl, String) );       % FLIM2
    if isempty(FLIM2); FLIM2 = get(rsFLIM2ctrlHndl,UserData); set(rsFLIM2ctrlHndl,String,num2str(FLIM2)); return; end
    if FLIM2 == get(rsFLIM2ctrlHndl,UserData); return; end          % no need to re-sort
    set(rsFLIM2ctrlHndl,UserData,FLIM2);                             % save current high freq limit
  end
  if action2 == 4
    rsDLIM1ctrlHndl = findobj(figNumber,Tag,rsDLIM1ctrlTag); 
    DLIM1 = str2num( get(rsDLIM1ctrlHndl, String) );       % DLIM1
    if isempty(DLIM1); DLIM1 = get(rsDLIM1ctrlHndl,UserData); set(rsDLIM1ctrlHndl,String,num2str(DLIM1)); return; end
    if DLIM1 == get(rsDLIM1ctrlHndl,UserData); return; end          % no need to re-sort
    set(rsDLIM1ctrlHndl,UserData,DLIM1);                             % save current damping ratio limit
  end
  if action2 == 5          % reserved for DLIM2
    DLIM2 = 0.15; %(DLIM2 not used yet) 
  end
  if action2 == 6
    % no need to do anything here
  end
  
    sortctrlval=get(findobj(figNumber,Tag,sortctrlTag), UserData);      % get current sorting criterion
    FLIM1 = get(findobj(figNumber,Tag,rsFLIM1ctrlTag), UserData);      % FLIM1
    FLIM2 = get(findobj(figNumber,Tag,rsFLIM2ctrlTag), UserData);      % FLIM2
    DLIM1 = get(findobj(figNumber,Tag,rsDLIM1ctrlTag), UserData);      % DLIM1
    DLIM2 = 0.15;           %(DLIM2 not used yet) 
    outctrlval = get(findobj(figNumber,Tag,rsoutctrlTag), UserData);    % get current output number
    identmodel = get(findobj(figNumber,Tag,polmenuTag), UserData);      % Get mode information
    nMode = size(identmodel, 1); 
    
    % determine what modes are selected, which will be sorted first: 
    % FLIM1 <= freq <= FLIM2 and DampRatio <= DLIM1, plus all the real modes
    % not apply to sorting by mode type
    sigma = identmodel(:, 1, outctrlval)/2/pi; freq = identmodel(:, 2, outctrlval)/2/pi;
    dampRatio = sigma ./ sqrt(sigma.^2 + freq.^2);
    locsR = find(freq < 1e-8);                                              % real modes
    %locsSel = find(freq >= FLIM1 & freq <= FLIM2 & dampRatio <= DLIM1);     % selected range
    locsSel = [1:1:nMode]';                                                 % select all the modes for now, but leave the room for selected range
    locsSel = union(locsR, locsSel);                                        % real modes are always selected
    locsC = setxor(locsR, locsSel);                                         % selected complex modes
    locsNonSel = setxor(locsSel, [1:1:length(freq)]');                      % unselected modes
    
    %Determine mode types:
    % 1) Simple trends:             0 == freq                         
    % 2) Oscillatory trends:        0 <  freq < FLIM2 & DLIM1 <= dampRatio   
    % 3) Interarea oscillations:    0 <  freq <=FLIM1 &     0 <  dampRatio <  DLIM1   
    % 4) Local oscillations:    FLIM1 <= freq < FLIM2 &     0 <  dampRatio <  DLIM1   
    % 5) Unstable oscillations:     0 <= freq < FLIM2 &          dampRatio <= 0   
    % 6) Fast noise:            FLIM2 <= freq    
    for n = 1 : nMode            % the 10th column in "identmodel" is for mode type
        if                      (freq(n)  <  FLIM2) & (DLIM1 <= dampRatio(n))                     , identmodel(n, 10, outctrlval) = 2; end 
        if                      (freq(n)  <= FLIM1) & (0 < dampRatio(n)) & (dampRatio(n) < DLIM1) , identmodel(n, 10, outctrlval) = 3; end 
        if (FLIM1 <= freq(n)) & (freq(n)  <  FLIM2) & (0 < dampRatio(n)) & (dampRatio(n) < DLIM1) , identmodel(n, 10, outctrlval) = 4; end 
        if                      (freq(n)  <  FLIM2) & (dampRatio(n) <= 0)                         , identmodel(n, 10, outctrlval) = 5; end 
        if                      (FLIM2    <= freq(n) )                                            , identmodel(n, 10, outctrlval) = 6; end 
        if (freq(n) < 1e-8 )                                                                      , identmodel(n, 10, outctrlval) = 1; end 
    end
        
    % sorting
    if sortctrlval == 1              % Sort by Freqency, real modes first.
        % sort real modes
        [dummy, locsRsort] = sort(sigma(locsR));
        locsRsort = locsR(locsRsort);               % row numbers of real modes after sorting
        % sort selected complex modes
        [dummy, locsCsort] = sort(freq(locsC));
        locsCsort = locsC(locsCsort);               % row numbers of selected complex modes after sorting
        % sort unselected modes
        [dummy, locsNonSelsort] = sort(freq(locsNonSel));
        locsNonSelsort = locsNonSel(locsNonSelsort);         % row numbers of unselected complex modes after sorting
        % merge all modes to form new identmodel
        locs = [locsRsort; locsCsort; locsNonSelsort];
        identmodel(:, :, outctrlval) = identmodel(locs, :, outctrlval);
    elseif sortctrlval == 2          % Sort by Damping Ratio, real modes first. 
        % sort real modes
        [dummy, locsRsort] = sort(sigma(locsR));
        locsRsort = locsR(locsRsort);               % row numbers of real modes after sorting
        % sort selected complex modes
        [dummy, locsCsort] = sort(dampRatio(locsC));
        locsCsort = locsC(locsCsort);               % row numbers of selected complex modes after sorting
        % sort unselected modes
        [dummy, locsNonSelsort] = sort(dampRatio(locsNonSel));
        locsNonSelsort = locsNonSel(locsNonSelsort);         % row numbers of unselected complex modes after sorting
        % merge all modes to form new identmodel
        locs = [locsRsort; locsCsort; locsNonSelsort];
        identmodel(:, :, outctrlval) = identmodel(locs, :, outctrlval);
    elseif sortctrlval == 3          % Sort by Relative Energy. 
        % sort selected modes
        [dummy, locsSelsort] = sort(identmodel(locsSel, 7, outctrlval));
        locsSelsort = locsSel(locsSelsort);         % row numbers of unselected complex modes after sorting
        locsSelsortReverse = [];
        for n = 1:length(locsSelsort)
            locsSelsortReverse = [locsSelsortReverse; locsSelsort(length(locsSelsort) + 1 - n)];   % reverse to get descending order
        end
        % sort unselected modes
        [dummy, locsNonSelsort] = sort(identmodel(locsNonSel, 7, outctrlval));
        locsNonSelsort = locsNonSel(locsNonSelsort);         % row numbers of unselected complex modes after sorting
        locsNonSelsortReverse = [];
        for n = 1:length(locsNonSelsort)
            locsNonSelsortReverse = [locsNonSelsortReverse; locsNonSelsort(length(locsNonSelsort) + 1 - n)];   % reverse to get descending order
        end
        % merge all modes to form new identmodel
        locs = [locsSelsortReverse; locsNonSelsortReverse];
        identmodel(:, :, outctrlval) = identmodel(locs, :, outctrlval);
    elseif sortctrlval == 4          % Sort by mode type.
%        disp('In RGUImgr: Sort modes by type') 
        [identmodel(:, :, outctrlval), locs] = sortrows(identmodel(:, :, outctrlval), [10 2]);    % sort by type then by freq
    elseif sortctrlval == 5          % Sort by relative damping amplitude.
        % sort selected modes
        [dummy, locsSelsort] = sort(identmodel(locsSel, 3, outctrlval));
        locsSelsort = locsSel(locsSelsort);         % row numbers of unselected complex modes after sorting
        locsSelsortReverse = [];
        for n = 1:length(locsSelsort)
            locsSelsortReverse = [locsSelsortReverse; locsSelsort(length(locsSelsort) + 1 - n)];   % reverse to get descending order
        end
        % sort unselected modes
        [dummy, locsNonSelsort] = sort(identmodel(locsNonSel, 3, outctrlval));
        locsNonSelsort = locsNonSel(locsNonSelsort);         % row numbers of unselected complex modes after sorting
        locsNonSelsortReverse = [];
        for n = 1:length(locsNonSelsort)
            locsNonSelsortReverse = [locsNonSelsortReverse; locsNonSelsort(length(locsNonSelsort) + 1 - n)];   % reverse to get descending order
        end
        % merge all modes to form new identmodel
        locs = [locsSelsortReverse; locsNonSelsortReverse];
        identmodel(:, :, outctrlval) = identmodel(locs, :, outctrlval);
    end
  
  % update the pole menu userdata to save new identmodel
  polmenuHndl = findobj(figNumber, Tag, polmenuTag);
  set( polmenuHndl, UserData, identmodel);
  
  if action2 ~= 6       % update pole submenu. output # change (action2 == 6) doesn't affect the pole submenu, so no need to update the pole submenu
  % update the pole menu
  checkstr0 = get(findobj(polmenuHndl,Tag,polsubmenuTag), Checked);   % save "check" informatio for the pole submenu
 
  delete( findobj(polmenuHndl, Tag, polsubmenuTag));    % delete old pole submenus

  uimenu(polmenuHndl,Tag,polsubmenuTag,Label,'All poles', ...
     'CallBack','ringdown(''rguimgr(1,4);'');');                 % Add "select all" function for pole submenu. Henry, 06/02/03
  
  qcon = size(identmodel, 1);       % number of modes
  sigma = identmodel(:, 1, outctrlval); freq = identmodel(:, 2, outctrlval);
  h = [[sigma freq]/2/pi sigma./sqrt(sigma.^2 + freq.^2)];
  for n = 1 : qcon
      if freq(n)<1e-8
          menustr = sprintf('% 12.4e     % 12.4e        -----', h(n, 2), h(n, 1));
      else
          menustr = sprintf('% 12.4e     % 12.4e     % 12.4e', h(n, 2), h(n, 1), h(n, 3));
      end
          uimenu(polmenuHndl, Tag, polsubmenuTag, Label, menustr, ...
            'CallBack','ringdown(''rguimgr(1,4);'');');
  end

  % check poles that already are checked before sorting
  if ~isempty(checkstr0)
      for ii = 1:qcon+1
          checkstr(ii) = checkstr0(qcon-ii+2);      % reverse checkstr
      end
      checkstr = checkstr(:, [1; locs+1]);         % reorder checkstr according to the sorting result
      for ii = 2:qcon+2
          if strcmp(checkstr(:, ii-1), onstr)          % can't use checkstr directly???
              set(findobj(polmenuHndl, Position, ii), Checked, onstr);
          else
              set(findobj(polmenuHndl, Position, ii), Checked, offstr);
          end
      end
  end
  end

  % redraw the mode table
  rguimgr(5, 1, figNumber);

% end - Added by Huang, Zhenyu (Henry), Mar. 21, 2003 -----------------------

end


function [fftr,ffti,frq]=rguifft(sigdat,tstep,fillmod,win);

% RGUIFFT:  Calculate frequency spectrum data using an FFT for
%           the BPA/PNNL Ringdown Analysis Tool.
%
% Usage:
%
%  [fftr,ffti,frq]=rguifft(sigdat,tstep,fillmod,win);
%
% where
%
%  sigdat = Matrix with time response data.
%
%  tstep  = Sample period.
%
%  fillmod = Zero fill control
%            fillmod==1 ==> No Fill
%            fillmod==2 ==> Left Fill
%            fillmod==3 ==> Right Fill
%
%  win    = Window control
%           win==1 ==> No windowing
%           win==2 ==> Hanning Window
%
%  fftr   = Real part of spectrum data.
%
%  ffti   = Imaginary part of spectrum data.
%
%  frq    = Sample frequencies in Hz.

% By Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date : December 1996.

% error(nargchk(4,4,nargin));
m=size(sigdat,1); n=size(sigdat,2); tstep=tstep(1); fillmod=fillmod(1); win=win(1);
if fillmod==1
  nnfft=m;
elseif fillmod==2
  nnfft=2*m; sigdat=[zeros(m,n); sigdat];
else
  nnfft=2*m; sigdat=[sigdat; zeros(m,n)];
end
if win==2
  winn=0.5*(1-cos(2*pi*(0:nnfft-1)'/nnfft));
  sigdat2=zeros(nnfft,n);
  for ii=1:n; sigdat2(:,ii)=winn.*sigdat(:,ii); end
  sigdat=sigdat2;
end
if rem(nnfft,2); ind=1:(nnfft+1)/2; else; ind=1:nnfft/2+1; end
fftdat=fft(sigdat); fftdat=tstep*fftdat(ind,:); frq=(ind'-1)/(nnfft*tstep);
if fillmod==2; ind=2:2:length(ind); fftdat(ind,:)=-fftdat(ind,:); end
fftr=real(fftdat); ffti=imag(fftdat);

function phsdat0=phsmatch(phsdat);

% PHSMATCH:  Adjusts phase response data so measured and model phase responses
%            match more closely when plotted.  This function is experimental!!

% By Jeff M. Johnson, Pacific Northwest National Laboratory
% Date : May 31, 2001

phsdat0=phsdat; mphsdat=size(phsdat,1); mxdif=300;
mxdifpt=find(abs(phsdat0(:,2)-phsdat0(:,1))>=mxdif);

while ~isempty(mxdifpt)
  mxdifpt0=mxdifpt(1); ptindx=mxdifpt0:mphsdat;
  [h,mxjmpsig]=max(max(abs(diff(phsdat0)))); h=phsdat0(mxdifpt0,:);
  if h(mxjmpsig)-h(3-mxjmpsig)<0; sgn=1; else; sgn=-1; end
  phsdat0(ptindx,mxjmpsig)=phsdat0(ptindx,mxjmpsig)+360*sgn;
  mxdifpt=find(abs(phsdat0(:,2)-phsdat0(:,1))>=mxdif);
end

%=========================================================================
% created by Henry Huang (PNNL), based on JeffJ's code. Aug. 28, 2003
% Function to create legend. 
function [errmsg] = creatlegend(sigtitles, linewidths, linecolors, linestyles);
% Manually create legend besed on line width, color, style. 

errmsg = '';
[figparams, errmsg] = createfig(1);
[figparams, errmsg] = createfig(2);

% Legend box will be a patch object plotted on title axis.

nnplots = size(sigtitles, 1);
% Vertical position of lower edge of legend box
legendboxyPosI = 1;

% Spacing between lower edge of plot axes and top of legend box
axeslegendySpacingI = 0.75;         %????

% Spacing between top of legend box and base of legend box title
legendtitleySpacingI = 0.3; 

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
lineLineWidthPt        = defaultLineLineWidthPt;        % ??? get from saved data
lineLineWidthIncrement = 1;

% Legend box will be a patch object plotted on title axis.
axesHtI = 0;      % no axes needed!
axesyPosI = figparams.axesTopI - axesHtI;
axesLeftI = figparams.axesLeftI;
legendboxHtI = axesyPosI - axeslegendySpacingI - legendboxyPosI;
legendboxXdata = axesLeftI + [0 figparams.axesWidI * [1 1] 0];
legendboxYdata = legendboxyPosI + [0 0 legendboxHtI * [1 1]];

% Vertical position for legend box title
legendtitleyPosI = legendboxYdata(3) + legendtitleySpacingI;
% Calculate position vectors for signal titles
sigtitleXdata = (axesLeftI + sigtitleLeftI) * ones(nnplots, 1);
if nnplots == 1
    sigtitleYdata = legendboxyPosI + sigtitlelegendySpacing + ...
        (legendboxHtI - 2 * sigtitlelegendySpacing) / 2;
else
    sigtitleYdata = legendboxyPosI + sigtitlelegendySpacing + ...
        (legendboxHtI - 2 * sigtitlelegendySpacing) * ...
        (nnplots - 1:-1:0)' / (nnplots - 1);
end

% Vertical positions of legend lines
legendlineXdata = axesLeftI + legendlineLeftI + [0 legendlineWidI];
legendlineYdata = sigtitleYdata * [1 1];

patch(legendboxXdata, legendboxYdata, [1 1 1], ...
    'EdgeColor', [0 0 0], 'FaceColor', 'none', ...
    'LineWidth', axesLineWidthPt);

text(axesLeftI, legendtitleyPosI, 'Key:', ...
    'FontSize', legendlabelFontSizePt, ...
    'HorizontalAlignment', 'left');

indx = 1:nnplots;

text(sigtitleXdata(indx), sigtitleYdata(indx), ...
    fliplr(deblank(fliplr(deblank(sigtitles(indx,:))))), ...
    'FontName', 'courier new', 'FontSize', sigtitleFontSizePt, ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');

% Plot legend lines
for jj = 1:nnplots
    plot(legendlineXdata, legendlineYdata(jj, :), 'Color', linecolors(jj, :), ...
        'LineStyle', linestyles(jj), 'LineWidth', linewidths(jj));
end


errmsg = createfig(3);


%=========================================================================
% copy from Multplot.m (JffJ), Henry Huang (PNNL), Aug. 28, 2003
% Function to create figures
function [figparamsout, errmsg] = createfig(action);

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

persistent figPosP figparams
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
axesTopI = 10.5;

% Font sizes for titles.  Units are in points (1/72 inches).
pagetitleFontSizePt    = 12;
pagesubtitleFontSizePt = 10;

% Vertical position and font size for page number
pagenumberyPosI = 0.75;
pagenumberFontSizePt = 8;

%-------------------------------------------------------------------------
% Initialization

if action == 1

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
  axesLeftI = axesPosdN(1) * figPaperPositionI(3) - 0.5;
  axesWidI = axesPosdN(3) * figPaperPositionI(3) + 1;

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

  % Page number
  page = figparams.page;

%  text(pagenumberxPosI, pagenumberyPosI, sprintf('Page %d', page), ...
%    'FontSize', pagenumberFontSizePt, 'HorizontalAlignment', 'right');

  figparams.page = page + 1;

  figparamsout = figparams;

%-------------------------------------------------------------------------
% Clean up

else

  % Clear persistent variables
  clear figPosP figparams
  clear pagetitlexPosI pagesubtitleLxPos pagesubtitleRxPos
  clear pagenumberxPosI

end
