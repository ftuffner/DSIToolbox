function [CaseComP,SaveFileP,namesP,TRangeP,tstepP,chansPN]...
    =PSMplot2(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansP,TRange,tstep,decfac,...
     Xchan,PlotPars);
%
%  [CaseComP,SaveFileP,namesP,TRangeP,tstepP,chansPN]...
%     =PSMplot2(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%      chansP,TRange,tstep,decfac,...
%       Xchan,PlotPars);
%
%  Provides batch plotting with interactive controls
%
%  chansP: 	Indicates channels to plot.  Can be either a numerical vector
%  of signal indices or a string such as 'chansP=[1:6]'.  User may edit
%	 initial value of chansP prior to plotting.
%
% PSM Tools called from PSMplot2:
%   PickSigsN
%   PickList1
%   Multplot
%   CaseTags
%   promptyn
%   IndSift
%
% Modified 06/08/05.   jfh  Time units
% Modified 04/01/06.   ZN   Macro function
%
% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 03/31/06
%----------------------------------------------------

disp(' ')
FNname='PSMplot2';
LcaseID=caseID;
disp(['In ' FNname ': Local caseID = ' LcaseID])

set(0,'DefaultTextInterpreter','none')

%Clear outputs
CaseComP=''; SaveFileP=''; 
namesP=namesX; chansPN=chansP; TRangeP=TRange; tstepP=tstep;

chansPstr=chansP;
if ~ischar(chansPstr)
  chansPstr=['chansP=[' num2str(chansPstr) '];'];
end
eval(chansPstr)
chansPN=chansP;

%*************************************************************************
%Validate inputs
if isempty(PSMsigsX)
  disp(['In ' FNname ': No signals provided to plot - Return']);
  return
end
nsigs=size(PSMsigsX,2);
[notlocs,locs]=IndSift(chansP,1:nsigs);
if isempty(locs)
  str=['In ' FNname ': No valid signal numbers in chansP - must be less than '];
  str=[str num2str(nsigs)]; disp(str)
  disp('Defaulting to plot of all available signals')
  disp(' ')
  chansP=[1:nsigs];
else
  chansP=locs;
end
if ~exist('Xchan'), Xchan=0; end; 
if isempty(Xchan) , Xchan=0; end
%*************************************************************************

chankeyX=names2chans(namesX,1);

%*************************************************************************
%Generate case identification, for stamping on plots and other outputs  

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
    if ~isfield(PSMMacro,'PSMplot2_setok'), PSMMacro.PSMplot2_setok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_setok))      % Not in Macro playing mode or selection not defined in a macro
        setok=promptyn(['In ' FNname ': Generate new case tags? '],'n');
    else
        setok=PSMMacro.PSMplot2_setok;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_setok=setok;
        else
            PSMMacro.PSMplot2_setok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  


if setok
  disp(['Generating new case tags for case ' LcaseID ':'])
  [LcaseID,casetime,CaseComP,Gtags]=CaseTags(LcaseID);
  CaseComP=str2mat('New case tags in PSMplot2:',CaseComP,CaseCom);
else
  CaseComP=CaseCom;
  Gtags=[]; Gtags(1,:)=casetime;
end
%*************************************************************************

%Initialize plot headers
Ptitle{1}=' ';
Ptitle{2}=['LcaseID=' LcaseID '    casetime=' casetime];
if ~isempty(PSMreftimes)
  str=['Plot Reference Time = ' PSM2Date(PSMreftimes(1))];
  disp(str); disp(' ')
end

%*************************************************************************
%Check desired operations
ShowPlot=1; SaveFileP='none';
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMplot2_PrintPlot'), PSMMacro.PSMplot2_PrintPlot=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_PrintPlot))      % Not in Macro playing mode or selection not defined in a macro
        PrintPlot=promptyn('In PSMplot2: Print generated plots? ', 'n');
    else
        PrintPlot=PSMMacro.PSMplot2_PrintPlot;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_PrintPlot=PrintPlot;
        else
            PSMMacro.PSMplot2_PrintPlot=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMplot2_SavePlot'), PSMMacro.PSMplot2_SavePlot=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_SavePlot))      % Not in Macro playing mode or selection not defined in a macro
        SavePlot =promptyn('In PSMplot2: Save generated plots to file(s)? ', 'n');
    else
        SavePlot=PSMMacro.PSMplot2_SavePlot;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_SavePlot=SavePlot;
        else
            PSMMacro.PSMplot2_SavePlot=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  



if SavePlot
  SaveFileP=[LcaseID casetime(13:14) casetime(16:17) 'P'];
  ws=cd;
  str1=['In PSMplot2: Saved plots have base name  ' SaveFileP];
  str2=['             and are saved in directory  ' ws];
  disp(str2mat(str1,str2))    
end
%*************************************************************************

%*************************************************************************
%Select signals to plot
disp(' ')
disp('In PSMplot2: Select signals to plot'); 

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMplot2_chansPok'), PSMMacro.PSMplot2_chansPok=NaN;end
    if ~isfield(PSMMacro, 'PSMplot2_chansP'), PSMMacro.PSMplot2_chansP=''; end
    if ~isfield(PSMMacro, 'PSMplot2_MenuName'), PSMMacro.PSMplot2_MenuName='';end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_chansPok))      % Not in Macro playing mode or selection not defined in a macro
        [MenuName,chansP,chansPok]=PickSigsN(chansP,namesX,chankeyX,'','plotting');
    else
        chansPok=PSMMacro.PSMplot2_chansPok;
        chansP=PSMMacro.PSMplot2_chansP;
        MenuName=PSMMacro.PSMplot2_MenuName;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_chansPok=chansPok;
            PSMMacro.PSMplot2_chansP=chansP;
            PSMMacro.PSMplot2_MenuName=MenuName;
        else
            PSMMacro.PSMplot2_chansPok=NaN;
            PSMMacro.PSMplot2_chansP='';
            PSMMacro.PSMplot2_MenuName='';
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  


if (~chansPok)|isempty(chansP)
  disp(' Returning to invoking Matlab function.')
  return
end
locsP=find(chansP>=1); chansP=chansP(locsP);
chansPstr=['chansP=[' num2str(chansP) '];']; %keyboard
nsigsP=length(chansP);
str1=['In PSMplot2: Number of selected signals= ' num2str(nsigsP)];
disp(str1)
chansPN=chansP; 
Gtags=str2mat(LcaseID,casetime);
%*************************************************************************

%*************************************************************************
%Select unit for time range
disp(' ')
disp('In PSMplot2: Select unit for time range')
TUnits=str2mat('Seconds','Minutes','Hours','Sample Number'); 
locbase=1; maxtrys=5;

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMplot2_TUTypeok'), PSMMacro.PSMplot2_TUTypeok=NaN;end
    if ~isfield(PSMMacro, 'PSMplot2_TUName'), PSMMacro.PSMplot2_TUName='';end
    if ~isfield(PSMMacro, 'PSMplot2_TUnits'), PSMMacro.PSMplot2_TUnits='';end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_TUTypeok))      % Not in Macro playing mode or selection not defined in a macro
        [TUnits,TUName,TUTypeok]=PickList1(TUnits,1,locbase,maxtrys);
    else
        TUTypeok=PSMMacro.PSMplot2_TUTypeok;
        TUName=PSMMacro.PSMplot2_TUName;
        TUnits=PSMMacro.PSMplot2_TUnits;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_TUTypeok=TUTypeok;
            PSMMacro.PSMplot2_TUName=TUName;
            PSMMacro.PSMplot2_TUnits=TUnits;
        else
            PSMMacro.PSMplot2_TUTypeok=NaN;
            PSMMacro.PSMplot2_TUName='';
            PSMMacro.PSMplot2_TUnits='';
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  


if ~TUTypeok
  disp('In PSMplot2: Time unit not determined')
  disp(' Returning to invoking Matlab function.')
  return
end
%Tidy this up someday
while 1
  if ~isempty(findstr('Seconds',TUName))
    Xname='Time in Seconds'; 
    tunit=1; PSMsigsX=[PSMsigsX PSMsigsX(:,1)/tunit];
    break 
  end
  if ~isempty(findstr('Minutes',TUName))
    Xname='Time in Minutes'; 
    tunit=60; PSMsigsX=[PSMsigsX PSMsigsX(:,1)/tunit];  
    break 
  end
  if ~isempty(findstr('Hours',TUName))
    Xname='Time in Hours'; namesX=str2mat(namesX,Xname);
    tunit=3600; PSMsigsX=[PSMsigsX PSMsigsX(:,1)/tunit];  
    break 
  end 
  if ~isempty(findstr('Sample Number',TUName))
    Xname='Sample Number'; maxpoints=size(PSMsigsX,1);
    tunit=1; PSMsigsX=[PSMsigsX [1:maxpoints]']; 
    tstepP=1; TRange=[1 maxpoints]; 
    break 
  end
  disp('In PSMplot2: Time unit not determined')
  disp(' Returning to invoking Matlab function.')
  return
end
TRangeSave=TRange;
TRange=TRange/tunit;
TPchan=size(PSMsigsX,2);
if PSMreftimes(1)>0
  RefString=PSM2Date(PSMreftimes(1));
  Xname=[Xname ' since ' RefString]; 
end
%*************************************************************************

%*************************************************************************
%Set time range for plotting
disp(' ')
disp('In PSMplot2: Set time range for plotting')
[maxpoints nsigs]=size(PSMsigsX);
timeP=PSMsigsX(:,TPchan);
tmin=timeP(1); tmax=timeP(maxpoints);
disp(['In PSMplot2: Max TRange = ' sprintf('[ %8.4f %8.4f ]',[tmin tmax]) ' ' TUName])
TRange(1)=max(TRange(1),tmin); TRange(2)=min(TRange(2),tmax);
if TRange(2)<=TRange(1)
  disp(['In PSMplot2: Bad plot range  = ' sprintf('[ %8.4f %8.4f ]', TRange) ' ' TUName])
  TRange=[tmin tmax];
  disp(['In PSMplot2: Using max range = ' sprintf('[ %8.4f %8.4f ]', TRange) ' ' TUName])
end
TRangeok=0;
maxtrys=10;
for i=1:maxtrys
  if ~TRangeok
    disp(['In PSMplot2: Indicated TRange = ' sprintf('[ %8.4f %8.4f ]', TRange) ' ' TUName])
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMplot2_TRangeok'), PSMMacro.PSMplot2_TRangeok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_TRangeok))      % Not in Macro playing mode or selection not defined in a macro
        TRangeok=promptyn('In PSMplot2: Is this plot range ok? ', 'y');
    else
        TRangeok=PSMMacro.PSMplot2_TRangeok;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_TRangeok=TRangeok;
        else
            PSMMacro.PSMplot2_TRangeok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------  

    
    if ~TRangeok
        %----------------------------------------------------
        % Begin: Macro selection ZN 03/31/06
        if ~isfield(PSMMacro, 'PSMplot2_TRangeok2'), PSMMacro.PSMplot2_TRangeok2=NaN; end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_TRangeok2))      % Not in Macro playing mode or selection not defined in a macro
              TRangeok2=promptyn('In PSMplot2: Do you want the maximum range? ', 'n');
              if TRangeok2, TRange=[tmin tmax]; end
        else
              TRangeok2=PSMMacro.PSMplot2_TRangeok2;
        end
    
        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PSMplot2_TRangeok2=TRangeok2;
            else
                PSMMacro.PSMplot2_TRangeok2=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        TRangeok=TRangeok2;
        % End: Macro selection ZN 03/31/06
        %----------------------------------------------------  
    end
    
    if ~TRangeok
      TRangeok=promptyn('In PSMplot2: Do you want no plots? ', 'n');
      if TRangeok, return, end
    end
    if ~TRangeok
      disp('In PSMplot2: Select plot range:')
      disp('EXAMPLE FOLLOWS:')
      disp(sprintf('  TRange=[ %8.4f %8.4f ]',TRange))
	    disp('Invoking "keyboard" command - Enter "return" when you are finished')
      keyboard
    end
  end
end
if ~TRangeok
  str1=sprintf('Sorry -%5i chances is all you get!',maxtrys);
  disp([str1,' Returning to invoking Matlab function.'])
end
disp(['In PSMplot2: Using TRange = ' sprintf('[ %8.4f %8.4f ]', TRange) ' ' TUName])
%Determine plot range in samples
TT1=TRange(1);          Er1=abs(PSMsigsX(:,TPchan)-TT1);
n1=find(Er1==min(Er1)); T1=PSMsigsX(n1,1);
TT2=TRange(2);          Er2=abs(PSMsigsX(:,TPchan)-TT2);
n2=find(Er2==min(Er2)); T2=PSMsigsX(n2,1);
disp('In PSMplot2: ')
disp(['  Sample range = ' sprintf('[ %8.0f %8.0f ]', [n1 n2])]); 
disp(['               = ' sprintf('[ %8.4f %8.4f ]', [T1 T2]) ' seconds']);
%keyboard
%*************************************************************************

%*************************************************************************
%Select signal for X-axis
disp(' ')
disp('In PSMplot2: Select signal for X-axis')
default='y'; if Xchan>1, default='n'; end
 %----------------------------------------------------
 % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMplot2_XchanOK'), PSMMacro.PSMplot2_XchanOK=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_XchanOK))      % Not in Macro playing mode or selection not defined in a macro
        XchanOK=promptyn('In PSMplot2: Use time as X-axis?', default);
    else
        XchanOK=PSMMacro.PSMplot2_XchanOK;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_XchanOK=XchanOK;
        else
            PSMMacro.PSMplot2_XchanOK=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  


if XchanOK
  Xchan=TPchan;
else
  locbase=1; maxtrys=5;
  [Xchan,Xname,XchanOK]=PickList1(namesX,Xchan,locbase,maxtrys);
  TUName=namesX(Xchan,:);
end
if ~XchanOK
  disp('In PSMplot2: Signal for X-axis not determined')
  disp(' Returning to invoking Matlab function.')
  return
end
%*************************************************************************

%*************************************************************************
%Select plotting style
disp(' ')
disp(['In PSMplot2: ' num2str(nsigsP) ' Signals to Plot'])
if PSMreftimes(1)>0
  str=['Plot Reference Time = ' PSM2Date(PSMreftimes(1))];
  disp(str); disp(' ')
end
maxperpage=30; mstr=[' ' num2str(maxperpage) ' '];
disp( 'In PSMplot2: Select a plotting style - options are')
StyleOpts='  option 1:  Detailed plots, 1 per page';
StyleOpts=str2mat(StyleOpts,['  option 2:  Summary  plots, max' mstr  'per page (1 trace each)']);
StyleOpts=str2mat(StyleOpts,['  option 3:  Summary  plots, 1 per page (max' mstr 'traces each)']);
StyleOpts=str2mat(StyleOpts,['  option 4:  Summary  plot,  all traces on one page']);
disp(StyleOpts)
prompt='  Select a value between 1 and 4: ';

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMplot2_nStyle'), PSMMacro.PSMplot2_nStyle=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_nStyle))      % Not in Macro playing mode or selection not defined in a macro
        nStyle=promptnv(prompt,2);
        nStyle=max(nStyle,1); nStyle=min(nStyle,4);
    else
        nStyle=PSMMacro.PSMplot2_nStyle;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_nStyle=nStyle;
        else
            PSMMacro.PSMplot2_nStyle=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  

disp(StyleOpts(nStyle,:))
%if nStyle~=1,chansP=chansP(find(chansP~=1));nsigsP=max(size(chansP));end
if nStyle==2|nStyle==3
  disp(' ')
  disp(['In PSMplot2: ' num2str(nsigsP) ' Signals to Plot'])
  disp( '  How many traces per page?');
  prompt=['  Select a value between 1 and ' mstr ': ' ];
  %----------------------------------------------------
  % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMplot2_PerPage'), PSMMacro.PSMplot2_PerPage=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_PerPage))      % Not in Macro playing mode or selection not defined in a macro
          PerPage=promptnv(prompt,min(nsigsP,5));
          PerPage=max(PerPage,1); PerPage=min(PerPage,maxperpage);
    else
          PerPage=PSMMacro.PSMplot2_PerPage;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_PerPage=PerPage;
        else
            PSMMacro.PSMplot2_PerPage=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
   % End: Macro selection ZN 03/31/06
   %----------------------------------------------------  
end
Legendok=1;
if nStyle==3
  Legendok=promptyn('  Show legend identifying traces? ','y');
end
disp(' ')
SigTag1='';

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMplot2_Detrendok'), PSMMacro.PSMplot2_Detrendok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_Detrendok))      % Not in Macro playing mode or selection not defined in a macro
          Detrendok=promptyn('In PSMplot2: Remove initial offsets? ', 'n');
    else
          Detrendok=PSMMacro.PSMplot2_Detrendok;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_Detrendok=Detrendok;
        else
            PSMMacro.PSMplot2_Detrendok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  


if Detrendok
  SigTag1=' Swings';
  PSMsigsX(n1:n2,chansP)=Detrend1(PSMsigsX(n1:n2,chansP),1);
end
disp(' ')
SigTag2='';

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PSMplot2_Normok'), PSMMacro.PSMplot2_Normok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMplot2_Normok))      % Not in Macro playing mode or selection not defined in a macro
          Normok=promptyn('In PSMplot2: Normalize all signals? ', 'n');
    else
          Normok=PSMMacro.PSMplot2_Normok;
    end
    
    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMplot2_Normok=Normok;
        else
            PSMMacro.PSMplot2_Normok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------  


if Normok
  SigTag2=' Normalized';
  scfac=max(abs(PSMsigsX(n1:n2,chansP)));
  scfac(find(scfac==0))=1; scfac=1./scfac;
  for N=1:length(chansP)
    NN=chansP(N);
    nameP=namesX(NN,:);
    test=isempty(findstr('time',lower(nameP)));
    test=test&isempty(findstr('sample',lower(nameP)));
    if test
       PSMsigsX(n1:n2,NN)=PSMsigsX(n1:n2,NN)*scfac(N);
    end
  end
end
%*************************************************************************

disp(['STARTING PLOTS FOR ' num2str(nsigsP) ' SIGNALS'])  

%*************************************************************************
%Plot case documentation
CaseComPlot(CaseCom,Ptitle,PrintPlot,SavePlot,SaveFileP)
%*************************************************************************

%*************************************************************************
%Logic for plot style 1
if nStyle==1
  for signo=1:nsigsP
    h=figure;
    plotno=sprintf('P%2.0i: ',h);
    plotsig=chansP(signo);
    plot(PSMsigsX(n1:n2,Xchan),PSMsigsX(n1:n2,plotsig))
    if Xchan==1, set(gca,'xlim',TRange); end
    Ptitle{1}=[plotno namesX(plotsig,:) SigTag1 SigTag2];
    title(Ptitle)
    xlabel(Xname)
    set(gca,'TickDir','out')
    grid off;
    SaveP=[SaveFileP num2str(h)];
    if PrintPlot, print -f, end
    if SavePlot, eval(['print -depsc -tiff ' SaveP]), disp(SaveP), end 
  end
  disp('PLOT SEQUENCE DONE')
end
%*************************************************************************

%*************************************************************************
%Logic for plot styles 2:3
if nStyle==2|nStyle==3
  if nStyle==3, chansP=chansP(find(chansP~=Xchan)); end
  LocSigsP=[Xchan chansP];
  slp=length(LocSigsP);
  clear namesXP;
  namesXP{1}=Xname;
  for i=2:slp , namesXP{i}=namesX(LocSigsP(i),:); end
  if ~Legendok, namesXP=''; end
  %Structure for page information
  MPtitles.pagetitle = [LcaseID SigTag1 SigTag2];
  MPtitles.subtitleL = LcaseID;
  MPtitles.subtitleR = casetime;
  %Structure for plot options
  MPoptions.plottype=nStyle-2;
  MPoptions.nnplots=PerPage;
  MPoptions.linectrl=1;
  MPoptions.printplot=PrintPlot;
  MPoptions.saveplot=SavePlot;
  MPoptions.savewhere=SaveFileP;
  if ~isempty(LocSigsP)
    Multplot(PSMsigsX(n1:n2,LocSigsP),namesXP,MPtitles,MPoptions)
  end
  disp('PLOT SEQUENCE DONE')
end
%*************************************************************************

%*************************************************************************
%Logic for plot style 4
if nStyle==4
  h=figure;
  plotno=sprintf('P%2.0i: ',h);
  chansP=chansP(find(chansP~=1));
  plot(PSMsigsX(n1:n2,Xchan),PSMsigsX(n1:n2,chansP))
  if Xchan==1, set(gca,'xlim',TRange); end
  Ptitle{1}=[plotno LcaseID SigTag1 SigTag2];
  title(Ptitle)
  xlabel(Xname)
  set(gca,'TickDir','out')
  grid off;
  SaveP=[SaveFileP num2str(h)];
  if PrintPlot, print -f, end
  if SavePlot
    command=eval(['print -depsc -tiff ' SaveP]);
    eval(command)
    disp(SaveP) 
  end 
  disp('PLOT SEQUENCE DONE')
end
%*************************************************************************

return

%end of PSMT utility

