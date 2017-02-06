function rguisave(figNumber,action,ctrls);

% RGUISAVE:  Handles saving of analysis results to files for the BPA/PNNL
%            Ringdown Analysis Tool.
%
% This is a helper function for the Ringdown Analysis Tool.  It is not
% normally used directly from the MATLAB command prompt.

% By Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date : February 1997
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
      'Date of last source code modification:  05/30/2001 (JMJ)\n\n']);
    return
  end

% Check input arguments.
  error(nargchk(2,3,nargin));

% Strings with property names.
  Enable     ='Enable';
  Position   ='Position';
  String     ='String';
  Tag        ='Tag';
  UserData   ='UserData';
  Value      ='Value';

  callstr    ='caller';
  emptymat   =[];
  emptystr   ='';
  nostr      ='No';
  offstr     ='off';
  onstr      ='on';
  yesstr     ='Yes';

% Object tags.
  ctitctrlTag='ctitctrl';
  filctrlTag ='filctrl';
  fmodctrlTag='fmodctrl';
  smodctrlTag='smodctrl';
  stitctrlTag='stitctrl';
  timectrlTag='tresctrl';
  wksctrlTag ='wksctrl';
  wksvctrlTag='wksvctrl';

%============================================================================
% Create the "Save Results" figure.
  if action==1

  % Strings with property names and values for initialization.
    BackgroundColor    ='BackgroundColor';
    CallBack           ='CallBack';
    DUictrlFontName    ='DefaultUicontrolFontName';
    DUictrlFontSize    ='DefaultUicontrolFontSize';
    HorizontalAlignment='HorizontalAlignment';
    Style              ='Style';
    Units              ='Units';
    Visible            ='Visible';

    centerstr          ='center';
    checkboxstr        ='checkbox';
    editstr            ='edit';
    framestr           ='frame';
    leftstr            ='left';
    pixelstr           ='pixels';
    pushbuttonstr      ='pushbutton';
    radiobuttonstr     ='radiobutton';
    textstr            ='text';

  %======================================
  % Set the figure position.

    oldUnits=get(figNumber,Units); set(figNumber,Units,pixelstr);
    figPos=get(figNumber,Position); set(figNumber,Units,oldUnits);

    h=get(findobj(figNumber,Tag,'dsctrl'),Position); editHt=h(4);

    oldUnits=get(0,Units); set(0,Units,pixelstr);
    screensize=get(0,'ScreenSize'); set(0,Units,oldUnits);

    figWid=min(4*0.070*figPos(3)/0.580,screensize(3));
    figHt=min(editHt*figPos(4)/0.100,screensize(4));

    figPos=floor([(screensize(3:4)-[figWid figHt])/2 figWid figHt]);

    btnBackgroundColor=[0.7 0.7 0.7];
    edtBackgroundColor=[1.0 1.0 1.0];
    frmBackgroundColor=[0.5 0.5 0.5];
    if strcmp(computer,'PCWIN')
      chkBackgroundColor=[0.5 0.5 0.5];
    else
      chkBackgroundColor=[0.7 0.7 0.7];
    end

  %======================================
  % Create the figure and controls.
  
    %Version check, since things changed in 2014b+
    if verLessThan('matlab','8.4.0')
        % execute code for R2014a or earlier
        figNmbr=figure(Tag,sprintf('RGUIFIG%d',figNumber),'NumberTitle',offstr, ...
          'Name','Save Results','MenuBar','none','Resize',offstr,Units,pixelstr, ...
           Position,figPos,UserData,figNumber,Visible,offstr,'WindowStyle','modal', ...
          'DefaultUicontrolUnits','normalized','DefaultUicontrolInterruptible',offstr, ...
           DUictrlFontName,get(figNumber,DUictrlFontName), ...
           DUictrlFontSize,get(figNumber,DUictrlFontSize), ...
          'DefaultUicontrolForegroundColor','black');
    else
        % execute code for R2014b or later
        figNmbr=figure(Tag,sprintf('RGUIFIG%d',figNumber.Number),'NumberTitle',offstr, ...
          'Name','Save Results','MenuBar','none','Resize',offstr,Units,pixelstr, ...
           Position,figPos,UserData,figNumber,Visible,offstr,'WindowStyle','modal', ...
          'DefaultUicontrolUnits','normalized','DefaultUicontrolInterruptible',offstr, ...
           DUictrlFontName,get(figNumber,DUictrlFontName), ...
           DUictrlFontSize,get(figNumber,DUictrlFontSize), ...
          'DefaultUicontrolForegroundColor','black');
    end

    uicontrol(figNmbr,Style,framestr,Position,[0.000 0.000 1.000 1.000], ...
      BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Position,[0.030 0.870 0.340 0.080], ...
      HorizontalAlignment,leftstr,String,'Session Title:', ...
      BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,editstr,Tag,stitctrlTag, ...
      Position,[0.390 0.860 0.580 0.100],HorizontalAlignment,centerstr, ...
      BackgroundColor,edtBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Position,[0.030 0.750 0.340 0.080], ...
      HorizontalAlignment,leftstr,String,'Case Title:', ...
      BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,editstr,Tag,ctitctrlTag, ...
      Position,[0.390 0.740 0.580 0.100],HorizontalAlignment,centerstr, ...
      BackgroundColor,edtBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Position,[0.030 0.620 0.340 0.080], ...
      HorizontalAlignment,leftstr,String,'Modes to Save:', ...
      BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,radiobuttonstr,Tag,fmodctrlTag, ...
      Position,[0.390 0.610 0.280 0.100],HorizontalAlignment,leftstr, ...
      String,'All',Value,1,CallBack,'ringdown(''rguisave([],2);'');', ...
      BackgroundColor,chkBackgroundColor);

    uicontrol(figNmbr,Style,radiobuttonstr,Tag,smodctrlTag, ...
      Position,[0.690 0.610 0.280 0.100],HorizontalAlignment,leftstr, ...
      String,'Selected',Value,0,CallBack,'ringdown(''rguisave([],3);'');', ...
      BackgroundColor,chkBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Position,[0.030 0.490 0.340 0.080], ...
      HorizontalAlignment,leftstr,String,'Include:', ...
      BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,checkboxstr,Tag,timectrlTag, ...
      Position,[0.390 0.480 0.580 0.100],HorizontalAlignment,leftstr, ...
      String,'Time Response Data',Value,0,BackgroundColor,chkBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Position,[0.030 0.360 0.340 0.080], ...
      HorizontalAlignment,leftstr,String,'Save to:', ...
      BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,radiobuttonstr,Tag,filctrlTag, ...
      Position,[0.390 0.350 0.280 0.100],HorizontalAlignment,leftstr, ...
      String,'File',Value,1,CallBack,'ringdown(''rguisave([],4);'');', ...
      BackgroundColor,chkBackgroundColor);

    uicontrol(figNmbr,Style,radiobuttonstr,Tag,wksctrlTag, ...
      Position,[0.690 0.350 0.280 0.100],HorizontalAlignment,leftstr, ...
      String,'Workspace',Value,0,CallBack,'ringdown(''rguisave([],5);'');', ...
      BackgroundColor,chkBackgroundColor);

    uicontrol(figNmbr,Style,textstr,Position,[0.030 0.230 0.340 0.080], ...
      HorizontalAlignment,leftstr,String,'Workspace Variable:', ...
      BackgroundColor,frmBackgroundColor);

    uicontrol(figNmbr,Style,editstr,Tag,wksvctrlTag, ...
      Position,[0.390 0.220 0.580 0.100],HorizontalAlignment,centerstr, ...
      Enable,offstr,BackgroundColor,edtBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Position,[0.030 0.030 0.460 0.140], ...
      String,'Save',CallBack,'ringdown(''rguisave([],6);'');', ...
      BackgroundColor,btnBackgroundColor);

    uicontrol(figNmbr,Style,pushbuttonstr,Position,[0.510 0.030 0.460 0.140], ...
      String,'Cancel',CallBack,'delete(gcf);',BackgroundColor,btnBackgroundColor);

    drawnow;
    set(findobj(figNmbr),'HandleVisibility',CallBack); set(figNmbr,Visible,onstr);

    return;

%============================================================================
% Modes to Save control.
  elseif action==2 | action==3

    figNmbr=gcf;
    if action==2
      h1=gco; h2=findobj(figNmbr,Tag,smodctrlTag);
      if get(h1,Value); set(h2,Value,0); else; set(h1,Value,1); end
    else
      h1=findobj(figNmbr,Tag,fmodctrlTag); h2=gco;
      if get(h2,Value); set(h1,Value,0); else; set(h2,Value,1); end
    end

    return;

%============================================================================
% Save to control.
  elseif action==4 | action==5

    figNmbr=gcf; h=findobj(figNmbr,Tag,wksvctrlTag);
    if action==4
      h1=gco; h2=findobj(figNmbr,Tag,wksctrlTag);
      if get(h1,Value)
        set(h2,Value,0); set(h,Enable,offstr);
      else
        set(h1,Value,1);
      end
    else
      h1=findobj(figNmbr,Tag,filctrlTag); h2=gco;
      if get(h2,Value)
        set(h1,Value,0); set(h,Enable,onstr);
      else
        set(h2,Value,1);
      end
    end

    return;

%============================================================================
% Save Results.
  elseif action==6

    if nargin==2
      figNmbr=gcf; figNumber=get(figNmbr,UserData);
      stit=get(findobj(figNmbr,Tag,stitctrlTag),String);
      ctit=get(findobj(figNmbr,Tag,ctitctrlTag),String);
      fmod=get(findobj(figNmbr,Tag,fmodctrlTag),Value);
      inctim=get(findobj(figNmbr,Tag,timectrlTag),Value);
      swks=get(findobj(figNmbr,Tag,wksctrlTag),Value);
      if swks
        wksvar=deblank(get(findobj(figNmbr,Tag,wksvctrlTag),String));
        wksvar=fliplr(deblank(fliplr(wksvar)));
        if isempty(wksvar)
          errordlg('You must enter a valid Workspace Variable name.'); return;
        end
        h=0; evalin(callstr,[mfilename '(' wksvar ',0);'],'h=1;');
        if ~h
          h=['Replace current variable ''''' wksvar ''''' in workspace?'];
          eval(['q=questdlg(''' h ''','''',''Yes'',''No'',''Yes'');'],'return');
          if exist('q')~=1; return; end; if strcmp(q,nostr); return; end
        end
      else
        [n,p]=uiputfile('*.*','Select the results file:');
        if ~n; return; end; resfile=[p n]; fid=fopen(resfile,'rt'); ncase=1;
        if fid>2
          h=fseek(fid,0,1);
          if h<0; fclose(fid); errordlg('Error reading file.'); return; end
          fpos=ftell(fid);
          if fpos>0              % File already exists, find the last case number.
            k=10000;
            while fpos>=0
              fpos=max(fpos-k,0); h=fseek(fid,fpos,-1);
              if h<0; fclose(fid); errordlg('Error reading file.'); return; end
              h=char(fread(fid,k,'uchar')'); spos=findstr('**START OF CASE',h);
              if ~isempty(spos)
                spos=spos(length(spos))+16; ncase=sscanf(h(spos:length(h)),'%d',1)+1;
                fclose(fid); break;
              elseif ~spos
                fclose(fid); errordlg('File is not of correct format.'); return;
              end
            end
          else
            fclose(fid);
          end
        end
      end
    else
      ctit=''; swks=1; wksvar='idmodel';
      if ctrls(1)<=0; fmod=1; else; fmod=0; end; inctim=ctrls(2);
    end

    identmodel=get(findobj(figNumber,Tag,'polmenu'),UserData);
    inpulses=get(findobj(figNumber,Tag,'filmenu'),UserData);
    qcon=size(identmodel,1); sigcon=size(identmodel,3); ninputs=size(inpulses,1);
    if swks & ~fmod
      if nargin==2
        outind=get(findobj(figNumber,Tag,'rsoutctrl'),Value);
      else
        outind=ctrls(1);
      end
      sigcon=1;
    else
      outind=1:sigcon;
    end
    if fmod; rowind=ones(qcon,sigcon); else; rowind=identmodel(:,9,outind); end
    pronysave=get(findobj(figNumber,Tag,'rstrctrl1'),UserData);
    resultcon=get(findobj(figNumber,Tag,'rstrctrl2'),UserData);
    tstep=pronysave.tstep; startindex=resultcon.startindex; df=resultcon.df;
    dftstep=df*tstep; actoutlist=pronysave.actoutlist(outind);
    ds=resultcon.ds(outind); endind=resultcon.endindex(outind);
    incthru=resultcon.incthru(outind); thru=resultcon.thru(outind);
    thrudat=resultcon.thrudat(:,outind);

    if inctim
      ind0=1:df:size(thrudat,1); nncalc=length(ind0);
      sigmoddat=zeros(nncalc,2*sigcon+1);
      sigmoddat(:,1)=dftstep*(0:nncalc-1)';
      sigmoddat(:,2:2:end)=thrudat(ind0,:);
    else
      sigmoddat=[]; nncalc=0;
    end

    if (ninputs & fmod) | inctim
      for ii=1:sigcon
        h=identmodel(logical(rowind(:,ii)),:,outind(ii));
        [h2,thru(ii)]=transimf(h(:,1),h(:,2),h(:,5),h(:,6),inpulses,dftstep, ...
          nncalc,thrudat(1:df:(endind(ii)-startindex)+1,outind(ii)),incthru(ii));
        if inctim; sigmoddat(:,2*ii+1)=h2; end
        if ~incthru(ii); thru(ii)=NaN; end
      end
    end

    if ~ninputs; thru=[]; end; titles=cell(sigcon,1);
    for ii=1:sigcon
      h=sprintf('outsubmenu%d',actoutlist(ii));
      titles{ii}=get(findobj(figNumber,Tag,h),UserData);
    end

    if swks
      for jj=1:sigcon
        h=identmodel(logical(rowind(:,jj)),:,outind(jj)); h2=1;
        if jj==1; p=zeros(size(h,1)+nnz(h(:,2)>=1e-8),6,sigcon); end
        for ii=1:size(h,1)
          if h(ii,2)<1e-8
            p(h2,1,jj)=-h(ii,1); p(h2,3,jj)=2*h(ii,5);
            if h(ii,4)<0.17; p(h2,2,jj)=h(ii,3); else; p(h2,2,jj)=-h(ii,3); end
            p(h2,4,jj)=h(ii,7); p(h2,5,jj)=h(ii,8); p(h2,6,jj)=h(ii,9); h2=h2+1;
          else
            p(h2,1,jj)=-h(ii,1)+i*h(ii,2); p(h2+1,1,jj)=conj(p(h2,1,jj));
            p(h2,2,jj)=h(ii,3)*exp(i*h(ii,4))/2; p(h2+1,2,jj)=conj(p(h2,2,jj));
            p(h2,3,jj)=h(ii,5)+i*h(ii,6); p(h2+1,3,jj)=conj(p(h2,3,jj));
            p(h2,4,jj)=h(ii,7); p(h2+1,4,jj)=h(ii,7);
            p(h2,5,jj)=h(ii,8); p(h2+1,5,jj)=h(ii,8);
            p(h2,6,jj)=h(ii,9); p(h2+1,6,jj)=h(ii,9); h2=h2+2;
          end
        end
      end

      idmodel.titles=titles; idmodel.pol=squeeze(p(:,1,:));
      idmodel.bres=squeeze(p(:,2,:)); idmodel.res=squeeze(p(:,3,:));
      idmodel.thru=thru; idmodel.releng=squeeze(p(:,4,:));
      idmodel.afpe=squeeze(p(:,5,:)); idmodel.select=squeeze(p(:,6,:));
      idmodel.sigmoddat=sigmoddat;
      assignin(callstr,'wksvar',wksvar); assignin(callstr,'idmodel',idmodel);
      assignin(callstr,'h',1);
    else
      numfmt=get(findobj(figNumber,Tag,'rspzyctrl2'),UserData);
      if numfmt==1; fstr='%14.6f'; else; fstr='%14.6e'; end; tfstr=['\t' fstr];

    % Create file and case header string.
      tstart=tstep*(startindex-1); crstr=sprintf('\n');
      if ncase==1
        fhead=sprintf(['****PRONY ANALYSIS RESULTS****\n\n' ...
                       '  Session Title:                \t%s\n'],stit);
      else
        fhead=emptystr;
      end
      clk=fix(clock);
      switch(clk(2))
        case  1, mth='January';
        case  2, mth='February';
        case  3, mth='March';
        case  4, mth='April';
        case  5, mth='May';
        case  6, mth='June';
        case  7, mth='July';
        case  8, mth='August';
        case  9, mth='September';
        case 10, mth='October';
        case 11, mth='November';
        otherwise, mth='December';
      end
      if clk(4)<12; ap='AM'; else; ap='PM'; clk(4)=clk(4)-12; end
      if ~clk(4); clk(4)=12; end
      if pronysave.filtmod
        filtstr=yesstr;
        fcfstr=sprintf('  Cutoff Frequency (Hz):        \t%.6g\n',pronysave.filtcf);
      else
        filtstr=nostr; fcfstr=emptystr;
      end
      if ninputs
        inpstr=[sprintf('\n INPUT PULSES \t  SWITCH TIMES\t    AMPLITUDES\n') ...
          sprintf(['      %2d     ' tfstr tfstr crstr],[1:ninputs; inpulses'])];
      else
        inpstr=emptystr;
      end
      if pronysave.scalmod; scalstr=yesstr; else; scalstr=nostr; end
      switch(pronysave.lpmcon)
        case 1, lpmstr='Correlation';
        case 2, lpmstr='Pre-Windowed';
        case 3, lpmstr='Covariance';
        otherwise, lpmstr='Post-Windowed';
      end
      switch(pronysave.fbcon)
        case 1, fbstr='Forward';
        case 2, fbstr='Forward-Backward';
        otherwise, fbstr='Backward';
      end
      switch(pronysave.lpacon)
        case 1, lpastr='Singular Value Decomposition';
        case 2, lpastr='QR Factorization';
        otherwise, lpastr='Total Least Squares';
      end
      lpocon=pronysave.lpocon; pircon=pronysave.pircon; vdocon=pronysave.vdocon;
      ftrh=pronysave.ftrimh; ftrl=pronysave.ftriml; trre=pronysave.trimre;
      switch(pronysave.ordcon)
        case 1, ordstr='Akaike Final Prediction Error';
        otherwise, ordstr='Mode Energy';
      end
      wrnerr=pronysave.wrnerr;
      if isempty(wrnerr)
        wstr=sprintf('\n  NO WARNINGS');
      else
        wstr=sprintf('\n  WARNINGS:');
        for ii=1:length(wrnerr); wstr=[wstr sprintf('\n    %s',wrnerr{ii})]; end
      end

      headstr=[fhead ...
        sprintf(['\n**START OF CASE %d\n' ...
                 '  Case Title:                   \t%s\n' ...
                 '  Date and Time:                \t%s %d, %d at %d:%02d:%02d %s\n' ...
                 '  Number of Outputs:            \t%d\n' ...
                 '  Time Zero Reference:          \t%.6g\n' ...
                 '  Original Sample Period:       \t%.6g\n' ...
                 '  Decimate Factor:              \t%d\n' ...
                 '  Resulting Sample Period:      \t%.6g\n' ...
                 '  Smoothing Filter?             \t%s\n'],ncase,ctit,mth,clk(3), ...
          clk(1),clk(4),clk(5),clk(6),ap,sigcon,tstart,tstep,df,dftstep,filtstr) ...
        fcfstr sprintf('  Normalize Signal Data?        \t%s\n',scalstr) inpstr ...
        sprintf(['\nADVANCED PRONY FIT OPTIONS\n' ...
                 '  Linear prediction method:     \t%s\n' ...
                 '  Forward-backward formulation: \t%s\n' ...
                 '  Linear prediction algorithm:  \t%s\n' ...
                 '  Linear prediction order:      \t%d\n' ...
                 '  Linear prediction rank:       \t%d\n' ...
                 '  Vandermonde solution method:  \tQR Factorization\n' ...
                 '  Order of Vandermonde solution:\t%d\n' ...
                 '  Mode ordering criterion:      \t%s\n'], ...
          lpmstr,fbstr,lpastr,lpocon,pircon,vdocon,ordstr) wstr crstr];

    % Create the identified parameter strings.
      bhead=sprintf(['\nPRONY ANALYSIS FIT:\nMODE\tFREQUENCY (HZ)\tDAMPING/(2*pi)\t' ...
        ' DAMPING RATIO\t     AMPLITUDE\t   PHASE (DEG)\tREL. AMPLITUDE\t' ...
        '   REL. ENERGY\t    AKAIKE FPE\n']);
      thead=sprintf(['\nTRANSFER FUNCTION FIT:\nMODE\tFREQUENCY (HZ)\tDAMPING/(2*pi)\t' ...
        ' DAMPING RATIO\t     AMPLITUDE\t   PHASE (DEG)\tREL. AMPLITUDE\n']);
      tini=pronysave.tini; tend=pronysave.tend; nnfit=pronysave.nnfit;
      if ninputs; instep=startindex+df*floor(inpulses(ninputs,1)/dftstep+1e-6)>=endind; end
      dtmodes=pronysave.dtmodes; dttini=pronysave.dttini; dttend=pronysave.dttend;
      pstr=cell(sigcon,1);
      for ii=1:sigcon
        switch(dtmodes(ii))
          case 1, dtstr='Remove Initial Value';
          case 2, dtstr='Remove Mean Value';
          case 3, dtstr='Remove Final Value';
          case 4, dtstr='Remove Ramp';
          otherwise, dtstr='No Detrend';
        end
        if dtmodes(ii)==1 | dtmodes(ii)==2 | dtmodes(ii)==4
          dtistr=sprintf('  Detrend Initial Time:         \t%.6g\n',dttini(ii));
        else
          dtistr=emptystr;
        end
        if dtmodes(ii)==2 | dtmodes(ii)==3 | dtmodes(ii)==4
          dtestr=sprintf('  Detrend End Time:             \t%.6g\n',dttend(ii));
        else
          dtestr=emptystr;
        end
        if ninputs
          if instep(ii); h=yesstr; else; h=nostr; end
          insstr=sprintf('  Step Input?:                    \t%s\n',h);
        else
          insstr=emptystr;
        end
        if any(rowind(:,ii))
          h=identmodel(logical(rowind(:,ii)),:,outind(ii))'; h2=zeros(9,size(h,2));
          h2(1,:)=1:size(h2,2); h2(2,:)=h(2,:)/2/pi; h2(3,:)=h(1,:)/2/pi;
          h2(4,:)=h(1,:)./sqrt(h(1,:).^2+h(2,:).^2); jj=find(h(2,:)<100*eps);
          h2(4,jj)=NaN*ones(1,length(jj)); h2(5,:)=h(3,:); h2(6,:)=180/pi*h(4,:);
          h2(7,:)=h(3,:)./max(h(3,:)); h2(8,:)=h(7,:); h2(9,:)=h(8,:); bstr=[bhead ...
          sprintf(['%3d ' tfstr tfstr tfstr tfstr tfstr tfstr tfstr tfstr '\n'],h2)];
          h2(5,:)=sqrt(h(5,:).^2+h(6,:).^2); h2(6,:)=180/pi*atan2(h(6,:),h(5,:));
          h2(7,:)=h2(5,:)./max(h2(5,:)); trfstr=[thead ...
          sprintf(['%3d ' tfstr tfstr tfstr tfstr tfstr tfstr '\n'],h2(1:7,:))];
        else
          bstr=sprintf('\nNO MODES SELECTED FOR THIS OUTPUT.\n\n'); trfstr=emptystr;
        end
        if ninputs&incthru(ii)
          thrustr=sprintf('FEED FORWARD TERM:\t%.6g\n',thru(ii));
        else
          thrustr=emptystr;
        end
        pstr{ii}=[ ...
          sprintf(['\nOUTPUT %d\n' ...
            '  Number and Title:             \tSignal %d\t%s\n' ...
            '  Initial Time:                 \t%.6g\n' ...
            '  End Time:                     \t%.6g\n' ...
            '  Number of Points:             \t%d\n' ...
            '  Detrend Mode:                 \t%s\n'],ii,actoutlist(ii), ...
            titles{ii},tini(ii),tend(ii),nnfit(ii),dtstr) dtistr dtestr insstr ...
            bstr trfstr thrustr];
      end
      if sigcon>1; pstr=strcat(pstr{1},pstr{2:end}); else; pstr=pstr{1}; end
      str=[headstr pstr];

    % Write to file.
      [fid,msg]=fopen(resfile,'at');
      if fid<0
        errordlg(['Error opening ' resfile '.  Error message from MATLAB is "' msg '".']);
        return;
      end
      h=length(str); h2=fprintf(fid,str); clear headstr bstr trfstr pstr str;
      if h2~=h; fclose(fid); errordlg(['Error writing to ' resfile '.']); return; end

    % Create and write the time response data string.
      if inctim
        if ninputs
          h=zeros(nncalc,1); h2=sigmoddat(:,1); jj=find(inpulses(1,1)>h2);
          h(jj)=inpulses(1,2)*ones(size(jj,1),1);
          for ii=2:ninputs
            jj=find(inpulses(ii-1,1)<=h2 & inpulses(ii,1)>h2);
            h(jj)=inpulses(ii,2)*ones(size(jj,1),1);
          end
          sigmoddat=[h2 h sigmoddat(:,2:end)];
        end
        thead=sprintf('\nTIME DOMAIN RESPONSE (MEASURED VS. MODEL):\n          TIME');
        if any(abs(sigmoddat)>999999); fstr='%14.6e'; tfstr=['\t' fstr]; end; h=fstr;
        if ninputs; thead=[thead sprintf('\t         INPUT')]; h=[h tfstr]; end
        thead=[thead sprintf('\tOUTPUT %d MEAS.\tOUTPUT %d MODEL',[1; 1]*(1:sigcon))];
        for ii=1:sigcon; h=[h tfstr tfstr]; end; h=[h crstr]; tstr=sprintf(h,sigmoddat');
        repeatdat=get(findobj(figNumber,Tag,'scrmenu'),UserData);
        if isempty(repeatdat)
          rhead=emptystr; rstr=emptystr;
        else
          rhead=[sprintf('\nREPEATED TIME SAMPLE DATA\n          TIME') ...
            sprintf('\t      OUTPUT %d',1:sigcon)]; h=fstr;
          for ii=1:sigcon; h=[h tfstr]; end; h=[h crstr]; rstr=sprintf(h,repeatdat');
        end
        str=[thead crstr tstr rhead crstr rstr]; h=length(str); h2=fprintf(fid,str);
        if h2~=h; fclose(fid); errordlg(['Error writing to ' resfile '.']); return; end
      end
      fclose(fid);
    end
    if nargin==2; delete(figNmbr); end
  end
