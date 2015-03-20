function [PMUsigs,PMUfreqs,tstep,PMUtags,PMUnames,PhsrNames,VIcon,CFname,MatFmt,...
   CaseCom,PDCfileX,PSMreftime,NOGPS,chansX, chansXok]=PDCload4(caseID,PDCfileX,PMUsigs,PMUfreqs,...
   CaseCom,saveopt,trackX,trackPatch,nXfile, chansX, chansXok )
% PDCload4.m retrieves and restructures a PDC data file saved as .mat
%  [PMUsigs,PMUfreqs,tstep,PMUtags,PMUnames,PhsrNames,VIcon,CFname,MatFmt,...
%      CaseCom,PDCfileX,PSMreftimekPatch,,NOGPS]=PDCload4(caseID,PDCfileX,PMUsigs,PMUfreqs,...
%      CaseCom,saveopt,trackX,tracnXfile);
%
%  (Initial trackX not used in PDCload4)
%
% PDCload4.m utilizes new .ini file conventions for PDC configuration,
% data in Matlab formats 1:2
%
% Special functions used:
%   DeOscList (future utility)
%   pdcread2,inicopy,inipars2
%   PDCpatch1,PDCpatch2
%   PMUosc2
%   PSMsave
%	promptyn,promptnv
%   PSM2Date
%   funSelectRMS
%
% Modified 11/21/05 by jfh.  Changed recovery for CF name discrepancies
% Modified 02/01/06 by jfh.  Changed default to [] for invoking deosc logic
% Modified 03/30/06 by jfh.  Changed some display semantics
% Modified 04/11/06 by zn.   Selection of channels before patching
% Modified 04/21/06 by zn.   Extended Selection of channels before patching

% By J. F. Hauer, Pacific Northwest National Laboratory. 
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
global PSMMacro         % Macro Structure  
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
% End: Macro definition ZN 03/31/06
%----------------------------------------------------

%Global controls on prompt defaults
global Kprompt ynprompt nvprompt

global CFname initext
global PMUtags PMUnames PhsrNames VIcon MatFmt

%Local variables to reuse
persistent BnkLevelPU BnkFactor
persistent PatchMode LogPatch PlotPatch PlotDrops
persistent trimok Trim2N
persistent DeOscMatch TryDeOsc CkDeOsc DeOscI DeOscLocs UseDeOscLocs
persistent PMUretag PMUtagsImp PMUtagsExp

%********************************************************************
% add by ZN on 04/05/2006 for channel selection before patching
% 1.0 Check the arguments
if (nargin < 10);chansX=[]; end
if (nargin < 11);chansXok=[];end

if (isempty(chansX));    chansX=1:10; end;     % default is "no action (control)" check the status of the lock
if (isempty(chansXok));  chansXok=0; end;        % default is default key
% add by ZN on 04/05/2006 for channel selection before patching
%********************************************************************

%Conversion Factors 
r2deg=180/pi;    %Radians to degrees

FNname='PDCload4';
S1=['In PDCload4: Seeking data on file  ' PDCfileX];
disp(S1); 
SaveFile='';
PDCfileX=deblank(PDCfileX);

%************************************************************************
%Verify validity of data format
if ~(MatFmt==1|MatFmt==2)
  disp(' ')
  disp(['In PDCload4: MatFmt ' num2str(MatFmt) ' not recognized -- return'])
  return
end
if (MatFmt==1)&(nXfile==1)
  disp('In PDCload4: Warning--Matlab format 1 is obsolete')
end
%************************************************************************

%************************************************************************
%Retrieve stored phasors
if ~exist('CFname'), CFname=''; end
if nXfile==1,  %Initialize various controls
  MatFmt=[]; PatchMode=0; PlotDrops=1;
  PMUretag=0; PMUtagsImp=''; PMUtagsExp=''; PMUorder='';  
end
StartTime=[]; SampleRate=[]; StartSample=[]; 
%eval(['whos -file ' PDCfileX])
L1=findstr('.',PDCfileX); L2=length(PDCfileX);
if isempty(L1)|isempty(L2)
  disp(['In ' FNname' ': Bad file name = ' PDCfileX])
  disp( '  Invoking "keyboard" command - Enter "return" when you are finished');
  keyboard
end
ftype=PDCfileX(L1:L2);
if strcmp(ftype,'.dst')  %Normal PDC data file
  if nXfile==1
    query='In PDCload4: Enter Matlab format for translated files (1 or 2)';
    default=2;
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro, 'PDCload4_MatFmt'), PSMMacro.PDCload4_MatFmt=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_MatFmt))      % 'Macro record mode' or 'selection was not defined in a macro'
       [MatFmt]=promptnv(query, default);
       MatFmt=max(1,MatFmt); MatFmt=min(2,MatFmt);
    else
        MatFmt=PSMMacro.PDCload4_MatFmt;
    end
    
    if PSMMacro.RunMode==0      % if in macro recording mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCload4_MatFmt=MatFmt;
        else
            PSMMacro.PDCload4_MatFmt=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------
    
    
  
  end
  S1=['In ' FNname ': Translating extracted data into Matlab format '];
  S1=[S1 sprintf('%2.0i',MatFmt)]; 
  
  disp(S1); CaseCom=str2mat(CaseCom,S1);
 %*********************************************************************************
 % Start: Select the channels before patching (ZN) 05/04/2006
      if nXfile==1
          %tic;
          %keyboard%
          [errmsg,varnames]=pdcread2(PDCfileX,MatFmt);%disp(PMUorder)
          %disp(' '); disp(' ');
          %disp('*******t1**************')
          %t1=toc
          %disp('*******t1**************')
          %disp(' '); disp(' ');
      else
          %tic;
          tPMUNames=[];
          NPMUs=size(VIcon,3);
          for kIndex=1:NPMUs
            pIndex=findstr(PMUtags(kIndex,:),'pmu');
            if isempty(pIndex)
                tempPMUNames=PMUtags(kIndex,:);
            else
                tempPMUNames=PMUtags(kIndex,1:pIndex-1);
            end
            if isempty(tPMUNames)
                tPMUNames=tempPMUNames;
            else
                tPMUNames=str2mat(tPMUNames,tempPMUNames);
            end
          end
          [errmsg,varnames]=pdcread2(PDCfileX,MatFmt,[],VIcon,tPMUNames); 
          %disp(' '); disp(' ');
          %disp('*******t2**************')
          %t2=toc
          %disp('*******t2*************')
          %disp(' '); disp(' ');
      end
%    [errmsg,varnames]=pdcread2(PDCfileX,MatFmt);%disp(PMUorder)
 % End: Select the channels before patching (ZN) 05/04/2006
 %*********************************************************************************
 
  if ~isempty(errmsg)
    disp(['In ' FNname ': Error message returned from pdcread2 - processing paused'])
    disp(errmsg); pause
  end
  S1=['In ' FNname ': PDC File Extracted = ' PDCfileX];
  disp(S1); CaseCom=str2mat(CaseCom,S1);
else     %Assume PDC data translated to .mat
  eval(['load ' PDCfileX])
  S1=['In ' FNname ': PDC File Extracted = ' PDCfileX];
  disp(S1); CaseCom=str2mat(CaseCom,S1);
end
if isempty(StartTime)
  disp(['In ' FNname ': StartTime empty in ' PDCfileX ' -- Setting defaults'])
  StartTime=0; SampleRate=30; StartSample=0; 
end
if isempty(MatFmt)
  disp(['In ' FNname ': Matlab format not indicated in ' PDCfileX ' -- Please help!'])
  disp('Extracted variables are named as follows:')
  eval (['who -file ' PDCfileX]);
  query='  What format is this? (1,2, or keyboard(0))';
  default=0;
  [MatFmt]=promptnv(query, default);
  if MatFmt==0
    disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
  Comment=['  Processing data as Matlab format ' sprintf('%1.0i',MatFmt)];
  disp(Comment)
end
%*************************************************************************

%*************************************************************************
%Call iniparse for PMU/PDC configuration
if nXfile==1  %Read configuration file
  ctag=';';
%  keyboard
  
  %----------------------------------------------------
  % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PDCload4_CFname'), PSMMacro.PDCload4_CFname=[];end
    if ~isfield(PSMMacro, 'PDCload4_initext'), PSMMacro.PDCload4_initext=[];end
    if ~isfield(PSMMacro, 'PDCload4_fname'), PSMMacro.PDCload4_fname=[];end
  
    if ~isempty(PSMMacro.PDCload4_CFname) && PSMMacro.RunMode>=1       % name has been selected and in 'play' mode
        CFname=PSMMacro.PDCload4_CFname;
    end
    
     
    if (PSMMacro.RunMode<1 || isempty(PSMMacro.PDCload4_initext))      % 'Macro record mode' or 'selection was not defined in a macro'
        if PSMMacro.RunMode<1
            [initext,fname,CFname]=inicopy(CFname,ctag);
        else
            [initext,fname,CFname]=inicopy(PSMMacro.PDCload4_fname,ctag);
            if PSMMacro.RunMode==1
                prompt=['In ', FNname, ': Would you like to record this ini file selection in Macro?  Enter y or n [y]:  '];
                tempQKbdok1=input(prompt,'s'); if isempty(tempQKbdok1), tempQKbdok1='y'; end
                tempQKbdok2=strcmp(lower(tempQKbdok1(1)),'n');  %String comparison
                if ~tempQKbdok2
                    PSMMacro.PDCload4_initext=initext;
                    PSMMacro.PDCload4_fname=fname;
                    PSMMacro.PDCload4_CFname=CFname;
                    save(PSMMacro.MacroName,'PSMMacro');
                end
            end
        end
    else
        initext=PSMMacro.PDCload4_initext;
        fname=PSMMacro.PDCload4_fname;
        CFname=PSMMacro.PDCload4_CFname;
    end
    
    if PSMMacro.RunMode==0      % if in macro recording mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCload4_initext=initext;
            PSMMacro.PDCload4_fname=fname;
            PSMMacro.PDCload4_CFname=CFname;
        else
            PSMMacro.PDCload4_initext=[];
            PSMMacro.PDCload4_fname=[];
            PSMMacro.PDCload4_CFname=[];

        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------
  if isempty(CFname)|isempty(initext)
    disp('In PDCload4: No configuration data -- Try again') 
    [initext,fname,CFnameR]=inicopy('',ctag);
  end
  if isempty(CFname)|isempty(initext)
    disp('In PDCload4: No configuration data -- Terminating') 
    return
  end
end
if strcmp(ftype,'.mat')
  S1=['In PDCload4: Appending configuration data ' CFname ' to ' PDCfileX];
  disp(S1); CaseCom=str2mat(CaseCom,S1);
  str=['save ' PDCfileX ' CFname  ']; eval([str '-append'])
  str=['save ' PDCfileX ' initext ']; eval([str '-append'])
  str=['save ' PDCfileX ' MatFmt  ']; eval([str '-append'])
end
S1=['Configuration file = ' CFname]; disp(S1)
CaseCom=str2mat(CaseCom,S1);
ctag=';'; 



[PMUtags,PMUnames,VIcon,PhsrNames,comment,samplerate,PMUtagsA]=...
    inipars2(initext,ctag,nXfile==1);
if nXfile==1
  PMUmatch12=[]; PMUmatch13=[];
  PMUtagCk=1;  
  if PMUtagCk
    if isempty(PMUorder),PMUorder=PMUtags; end
    disp(['In ' FNname ': Checking PMU tags']); %keyboard
    NTord=size(PMUorder,1); NTCF=size(PMUtags,1); NTCFA=size(PMUtagsA,1);
    disp(['Column 1: ' num2str(NTord) ' PMU  tags in data file ' PDCfileX])
    disp(['Column 2: ' num2str(NTCF)  ' PMU  tags in configuration file ' CFname])
    disp(['Column 3: ' num2str(NTCFA) ' PMUA tags in configuration file ' CFname])
    PMUmatch12=0; PMUmatch13=0;
    MaxTags=max([NTord,NTCF,NTCFA]);
    for N=1:MaxTags
      str1='    '; if N<=NTord , str1=PMUorder(N,:); end
      str2='    '; if N<=NTCF  , str2=PMUtags(N,:) ; end
      str3='    '; if N<=NTCFA , str3=PMUtagsA(N,:); end
      disp(['  ' str1 '  ' str2 '  ' str3])
      for L=1:NTord
        if N<=NTCF , PMUmatch12=PMUmatch12+(~isempty(findstr(deblank(str2),PMUorder(L,:)))); end
        if N<=NTCFA, PMUmatch13=PMUmatch13+(~isempty(findstr(deblank(str3),PMUorder(L,:)))); end
      end
    end 
    MatchTags=max(PMUmatch12,PMUmatch13)==MaxTags;
    if ~MatchTags %Enable interactive repair by user
      disp(['In ' FNname ': Mismatch in PMU Tags--Defaulting to names in PDC data file'])
      PMUtags=PMUorder; PMUtagsImp=PMUorder;
      
      %----------------------------------------------------
      % Begin: Macro selection ZN 02/12/2007
      if ~isfield(PSMMacro, 'PDCload4_setok04'), PSMMacro.PDCload4_setok04=NaN;end
      if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_setok04))      % 'Macro record mode' or 'selection was not defined in a macro'
            setok=promptyn('Do you want the keyboard? ','n');
      else
            setok=PSMMacro.PDCload4_setok04;
      end
    
      if PSMMacro.RunMode==0      % if in macro recording mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PDCload4_setok04=setok;
            else
                PSMMacro.PDCload4_setok04=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
      end
      % End: Macro selection ZN 02/12/2007
      %----------------------------------------------------
        
      
      if setok
        disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
        keyboard
      end
      
      if 1 %Check repair (if any)
        NTord=size(PMUorder,1); NTCF=size(PMUtags,1); NTCFA=size(PMUtagsA,1);
        PMUmatch12=0; PMUmatch13=0;
        MaxTags=max([NTord,NTCF,NTCFA]);
        for N=1:MaxTags
          str1='    '; if N<=NTord , str1=PMUorder(N,:); end
          str2='    '; if N<=NTCF  , str2=PMUtags(N,:) ; end
          str3='    '; if N<=NTCFA , str3=PMUtagsA(N,:); end
          %disp(['  ' str1 '  ' str2 '  ' str3])
          for L=1:NTord
            if N<=NTCF , PMUmatch12=PMUmatch12+(~isempty(findstr(deblank(str2),PMUorder(L,:)))); end
            if N<=NTCFA, PMUmatch13=PMUmatch13+(~isempty(findstr(deblank(str3),PMUorder(L,:)))); end
          end
        end 
      end
    end  %Terminate interactive repair
    PMUtagsImp=PMUtags;  %Tags for data import
    if PMUmatch13>PMUmatch12
       PMUtagsImp=PMUtagsA;
    end
    PMUtagsExp=PMUtags;  %Tags for data export
    if ~isempty(PMUtagsA)
      AliasExp=promptyn('Use alias tags for data export?', '');
      if AliasExp
        comment='NONE';
        PMUtagsExp=PMUtagsA;
        [N1 N2 N3]=size(PhsrNames);
        for L3=1:NTCFA
          strS=PMUtags(L3,1:4); strA=PMUtagsA(L3,1:4);
          for L1=1:N1
            if findstr(strS,PhsrNames(L1,1:4,L3)), PhsrNames(L1,1:4,L3)=strA; end
          end
        end 
      end
    end
  end
end  %Terminate logic for nXfile==1
if abs(samplerate-SampleRate)>0.001*samplerate
  disp(' ')
  disp(['In ' FNname ': Sampling rate discrepancy'])
  disp(['Data file ' PDCfileX ' shows SampleRate=' num2str(SampleRate)])
  disp(['Configuration file ' CFname ' shows samplerate=' num2str(samplerate)])
  if samplerate<=0, samplerate=SampleRate; end
  disp(['Default is samplerate=' num2str(samplerate)])
  
  %----------------------------------------------------
  % Begin: Macro selection ZN 02/12/2007
  if ~isfield(PSMMacro, 'PDCload4_setok05'), PSMMacro.PDCload4_setok05=NaN;end
  if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_setok05))      % 'Macro record mode' or 'selection was not defined in a macro'
        setok=promptyn('Do you want the keyboard? ','n');
  else
        setok=PSMMacro.PDCload4_setok05;
  end

  if PSMMacro.RunMode==0      % if in macro recording mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCload4_setok05=setok;
        else
            PSMMacro.PDCload4_setok05=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
  end
  % End: Macro selection ZN 02/12/2007
  %----------------------------------------------------
      

  if setok
    disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end
tstep=1/samplerate; %keyboard
PSMreftime=StartTime+StartSample*tstep;
if MatFmt==1, sigsnameG='pmu00phsr00'; end

%-----------------------------------------------------------
% start: channel selection before patching (ZN 05/05/2006)
%if MatFmt==2, sigsnameG=[deblank(PMUtagsImp(1,:)) 'phsrs']; end
%eval(['maxpts=max(size(' sigsnameG '));'])
tagtest=0;
NPMUs=size(VIcon,3);
for K=1:NPMUs
    PMUtagK=deblank(PMUtagsImp(K,:));
    sigsnameG=[PMUtagK 'phsrs'];
    eval(['tagtest=exist(' '''' sigsnameG '''' ');']);
    if tagtest
        break;
    end
end

if tagtest
    eval(['maxpts=max(size(' sigsnameG '));'])
else
    maxpts=0;
end
% end: channel selection before patching (ZN 05/05/2006)
%-----------------------------------------------------------

maxtime=(maxpts-1)*tstep;
S1=sprintf('Time Step = %10.5f    Max Time = %8.3f', [tstep maxtime]);
S2=[sprintf('PDC Reference Time = %10.5f', PSMreftime) ' Seconds'];
PSMdatestr=PSM2Date(PSMreftime); 
S3=['PDC Reference Time = ' PSMdatestr ' GMT Standard'];
disp(S1); disp(S2); disp(S3)
CaseCom=str2mat(CaseCom,S1,S2,S3);
nphsrs=sum(sum(VIcon(:,1,:)==1|VIcon(:,1,:)==2));
%NPMUs=size(VIcon,3);
%*************************************************************************

%*********************************************************************************
% Start: Select the channels before patching (ZN) 04/21/2006
%   Major outputs:
%   1) Selected channels are stored in chansX; 
%   2) Relevant phasors are marked in VIcon(phasorIndex,7,pmuIndex)

[CaseCom, chansX, chansXok, VIcon ]...
      =funSelectRMS(CaseCom, chansX,chansXok, VIcon, NPMUs,CFname, PhsrNames, trackX, nXfile);
% End:   Select the channels before patching data (ZN) 04/21/2006
%*********************************************************************************

%*************************************************************************
%Test for misnamed or missing data arrays
PMUlocs=1:NPMUs; %Assumed true for MatFmt==1
if MatFmt==2
  PMUlocs=zeros(NPMUs,1);
  for K=1:NPMUs
  %-----------------------------------------------------------
  % start: channel selection before patching (ZN 05/04/2006)
  % if none of the phasors on this PMU is required for calculating rms values.  
  if sum(VIcon(:,7,K))==0      
      continue;
  end
  % end: channel selection before patching (ZN 05/04/2006)
  %-----------------------------------------------------------
    PMUtagK=deblank(PMUtagsImp(K,:));
    sigsnameG=[PMUtagK 'phsrs'];
    eval(['tagtest=exist(' '''' sigsnameG '''' ');']);
    if tagtest
      PMUlocs(K)=K;
    else
      disp(' ')
      strs=['In PDCload4: Discrepancy in phasor data or name:'];
      strs=str2mat(strs,['  sigsnameG = ' sigsnameG ' not found']);
      disp(strs)
      NN=length(PMUtagK); 
      disp(['  PMUtags(' num2str(K) ',1:' num2str(NN) ') = ' PMUtagK])
      disp(['  Phasor names are shown below:'])
      whos *phsrs
      disp('THIS IS A SERIOUS PROBLEM -- MISMATCH BETWEEN CONFIGURATION FILE & DATA')
      disp( '  Invoking "keyboard" command for possible repair by user - Enter "return" when you are finished');
      keyboard
      %Test for possible repair to data or name
      sigsnameG=[PMUtagK 'phsrs'];
      eval(['tagtest=exist(' '''' sigsnameG '''' ');']);
      if ~tagtest
        str2=['In PDCload4: Discrepancy remains -- Phasor array ' sigsnameG ' defined as zero'];
        strs=str2mat(strs,str2);
        disp(str2); CaseCom=str2mat(CaseCom,strs);
      end
    end
    if tagtest, PMUlocs(K)=K; end
  end
end
%*************************************************************************

%*************************************************************************
%Display logic for flag bits (optional)
%Quantities are pictured as "Big Endian" with the most significant bit 
% (bit 31) furthest left and the least significant furthest right (bit 0). 
%Flag bits:	
%31	Data valid in this cell? (y=0)
%30	No Transmission errors? (y=0)
%29	PMU synchronized? (y=0)
%28	Data sorted by time of arrival? (y=1)
%27	Data sorted by time stamp & sample number? (y=0)
%26	PDC Exchange format? (n=0)
%25	Macrodyne/IEEE format? (Macrodyne=1)
%24	Time stamp included? (y=0)
%Note:  Bit 26 will be set for PDC data & cleared for PMU data
if 0  %experimental code
  N=GC50chanflag(1)
  N=GC50chanflag;
  ckbits=dec2bin(N,32);
  size(ckbits)
  figure; plot(str2num(ckbits(:,1))); title('flag31'); set(gca,'ylim',[0 2])
  figure; plot(str2num(ckbits(:,2))); title('flag30'); set(gca,'ylim',[0 2])
  figure; plot(str2num(ckbits(:,3))); title('flag29'); set(gca,'ylim',[0 2])
end
%************************************************************************



%************************************************************************
%Scan PMU status for number of dropped points and loss of GPS synch
NOGPS=zeros(NPMUs,1); PMUckbits=zeros(NPMUs,1); Flags31=[]; 
PMUdrops=0; PMUnosync=0; PMUnodata=0;
for K=1:NPMUs
  %-----------------------------------------------------------
  % start: channel selection before patching (ZN 04/21/2006)
  % if none of the phasors on this PMU is required for calculating rms values.  
  if sum(VIcon(:,7,K))==0      
      continue;
  end
  % end: channel selection before patching (ZN 04/21/2006)
  %-----------------------------------------------------------
  PMUtagK=deblank(PMUtagsImp(K,:));
  if ~(PMUlocs(K)==K)
    PMUnodata=PMUnodata+1;
    str1=['PMU ' PMUtagK ': No data array'];
    disp(str1)
  else
    flagnameG=[PMUtagK 'chanflag'];
    eval(['PMUckbits(K)=exist(' '''' flagnameG '''' ');']);
    if PMUckbits(K)
      eval(['ckbits=dec2bin(' '' flagnameG '' ',32);']);
      flag31=str2num(ckbits(:,1)); %figure; plot(flag31); set(gca,'ylim',[0 2])
      %-----------------------------------------------------------
      % start: channel selection before patching (ZN 04/21/2006)
      if isempty(Flags31)
          Flags31=zeros(length(flag31),NPMUs);
      end
      Flags31(:,K)=flag31;
%     Flags31=[Flags31 flag31];  
      % end: channel selection before patching (ZN 04/21/2006)
      %-----------------------------------------------------------
      
      locs31=find(Flags31(:,K)==1); 
      Kdropped=size(locs31,1); if isempty(Kdropped), Kdropped=0; end
      if 1 
        PMUdrops=PMUdrops+Kdropped;
        str1=['PMU ' PMUtagK ': Status tags indicate ' num2str(Kdropped) ' dropped points'];
        disp(str1)
        if Kdropped==size(Flags31(:,K),1)            
          str2=['THIS IS THE ENTIRE PMU RECORD: Status tags may be in error'];
          disp(str2)
        end
        %figure; plot(Flags31(:,K)); set(gca,'ylim',[0 2]); title(str1); 
      end
      flag29=str2num(ckbits(:,3)); %figure; plot(flag29); set(gca,'ylim',[0 2])
      flag29=flag29&~flag31;
      locs29=find(flag29==1);
      if ~isempty(locs29)
        NOGPS(K)=1; PMUnosync=PMUnosync+1;
        disp(['PMU ' PMUtagK '  OUT OF SYNCH'])
        %figure; plot(flag29); title(['flag29 for ' PMUtagK]); set(gca,'ylim',[0 2])
      end
    else  %Diagnostic for bad channel flag
      disp(['No checkbits for PMU ' deblank(PMUtagK)]) 
    end
  end
end
if PMUdrops>0|PMUnosync>0|PMUnodata>0
    strs=['File ' PDCfileX ':'];
    strs=str2mat(strs,['  PMUs feeding no data=' num2str(PMUnodata)]);
    strs=str2mat(strs,['  PMUs w/o GPS synch  =' num2str(PMUnosync)]);
    strs=str2mat(strs,['  Dropped points      =' num2str(PMUdrops)]);
    disp(strs)
    if PlotDrops
        
      str=['File ' PDCfileX ': PMUs w/o GPS synch=' num2str(PMUnosync)];
      str=[str '  Dropped points=' num2str(PMUdrops)];
      %----------------------------------------------------
      % Begin: Macro selection ZN 03/31/06
      if PSMMacro.RunMode<1
          figure; plot(Flags31); set(gca,'ylim',[0 2])
          title(str); xlabel(['Graphical dropout summary for file ' PDCfileX])
      end
      if ~isfield(PSMMacro, 'PDCload4_setok'), PSMMacro.PDCload4_setok=NaN;end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_setok))      % 'Macro record mode' or 'selection was not defined in a macro'
            setok=promptyn('Show this plot for future files? ','n');
        else
            setok=PSMMacro.PDCload4_setok;
        end
    
        if PSMMacro.RunMode==0      % if in macro recording mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PDCload4_setok=setok;
            else
                PSMMacro.PDCload4_setok=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        % End: Macro selection ZN 03/31/06
        %----------------------------------------------------
      if ~setok, PlotDrops=0; end
    end
end
%************************************************************************





%************************************************************************
%Test for possible parasitic oscillations
SetDeOscLocs=0;
if nXfile==1  %Set DeOsc controls
  DeOscMatch=0; 
  TryDeOsc=0; CkDeOsc=0; DeOscI=0; 
  DeOscLocs=zeros(size(PhsrNames,3),size(PhsrNames,1)); 
  SetDeOscLocs=1; UseDeOscLocs=0;
  DeOscList1='BCHS_';  %Call to optional function here
  if ~isempty(DeOscList1)
    DeOscMatch=~isempty(findstr(DeOscList1,PDCfileX));
  end
  if DeOscMatch
    disp(' ')
    str1='In PDCload4: Data source is on list for oscillatory processing artifacts';
    str2='             in VMag signals, perhaps in IMag signals';
    disp(str2mat(str1,str2))
    disp(['   DST file=' PDCfileX])
    prompt='In PDCload4: Use experimental tool for removal of parasitic oscillations? ';
    TryDeOsc=promptyn(prompt,'');
    if TryDeOsc
      CkDeOsc=promptyn('Review and ok oscillation removal?','');
      if CkDeOsc
        DeOscI=promptyn('Process current phasors also?','');
        disp('HINT: You can use the keyboard to reduce or terminate the prompts')
        disp('  TryDeOsc = 0  will terminate the oscillation removal logic entirely') 
        disp('  CkDeOsc  = 0  will terminate just the review and ok logic') 
        disp('  DeOscI   = 0  will terminate just the processing of current phasors') 
      end
      DeOscLocs=zeros(size(PhsrNames,3),size(PhsrNames,1));
      DeOscLocs=...
       [1     7     8     0     0     0     0     0     0;
        1     5     6     7     0     0     0     0     0;
        1     7     8     0     0     0     0     0     0;
        1     6     7     0     0     0     0     0     0;
        1     5     6     7     0     0     0     0     0];
      Nshort=NPMUs-size(DeOscLocs,1);
      if Nshort
        DeOscLocs=[DeOscLocs' zeros(size(DeOscLocs,2),Nshort)]';
      end
      disp('In PDCload4: Array DeOscLocs was defined when processing an earlier file')
      disp('DeOscLocs='); disp(DeOscLocs)
      prompt='In PDCload4: Use existing DeOscLocs? ';
      UseDeOscLocs=promptyn(prompt,'y');
      if UseDeOscLocs
        SetDeOscLocs=0; %CkDeOsc=0;
      end
    end
  end
end
if DeOscMatch&(nXfile>1)     %Review/modify DeOsc controls
  if max(max(DeOscLocs))==0  %isempty(DeOscLocs)
    SetDeOscLocs=1; UseDeOscLocs=0; 
  else
    if 1 
      disp('In PDCload4: Array DeOscLocs was defined when processing an earlier file')
      disp('DeOscLocs='); disp(DeOscLocs)
      prompt='In PDCload4: Use existing DeOscLocs? ';
      UseDeOscLocs=promptyn(prompt,'y');
    end
  end
  if UseDeOscLocs
    SetDeOscLocs=0; CkDeOsc=0;
  end
end 
%************************************************************************

%************************************************************************
%Load retrieved data into arrays PMUsigs, PMUfreqs
PMUsigs =zeros(maxpts,nphsrs);
PMUfreqs=zeros(maxpts,NPMUs);
PMUbase =zeros(NPMUs,1);
if MatFmt==1
  loc=0;
  for K=1:NPMUs
    nphsrsK=sum(VIcon(:,1,K)==1|VIcon(:,1,K)==2);
    for N=1:nphsrsK
	  PMUbase(K)=loc;
      signameG=[sprintf('pmu%2.0iphsr%2.0i',K-1,N-1)];
	  bloc=signameG==' '; signameG(bloc)='0';
      command=['PMUsigs(:,loc+N)=' signameG '.''' ';'];
	  eval(command)
      if 0  %Use later?
        flag31=Flags31(:,K); locs31=find(flag31==1);
        if ~isempty(locs31)
          PMUsigs(locs31,loc+N)=0; %Special value to indicate bad data
        end
      end
    end
    signameG=['Freq' signameG(4:5)];
    command=['PMUfreqs(:,K)=' signameG '.''' ';'];
    eval(command)
    if 0  %Use later?
      if ~isempty(locs31)
        PMUfreqs(locs31,K)=-9999; %Special value to indicate bad data
      end
    end
    loc=PMUbase(K)+nphsrsK;
  end
end

if MatFmt==2
  loc=0;
  for K=1:NPMUs
    PMUbase(K)=loc;
    PMUtagK=deblank(PMUtagsImp(K,:));
    sigsnameG=[PMUtagK 'phsrs'];
    if PMUlocs(K)==K
      eval(['nsigsK=size(' sigsnameG ',2);'])
      nsigsck=sum(VIcon(:,1,K)>0)-1;
      %-----------------------------------------------------------
      % start: channel selection before patching (ZN 04/21/2006)
      % if any of the phasors on this PMU is required for calculating rms values.  
      if sum(VIcon(:,7,K))~=0      
          command=['PMUsigs(:,loc+1:loc+nsigsK)=' sigsnameG ';'];
          eval(command)
          signameG=[PMUtagK 'freq'];
          command=['PMUfreqs(:,K)=' signameG ';'];
          eval(command)
      end
    else     % modified by ZN (05/05/2006)
      nsigsK=sum(VIcon(:,1,K)==1)+sum(VIcon(:,1,K)==2);
      % start: channel selection before patching (ZN 04/21/2006)
      %-----------------------------------------------------------
    end
    loc=PMUbase(K)+nsigsK;    
  end
end
maxpoints=size(PMUsigs,1);
time=[0:(maxpoints-1)]'*tstep;
%figure; plot(PMUfreqs(:,8:10))
%************************************************************************

%************************************************************************
%Set controls for outlier repair
if nXfile==1 
  disp(' ')
  disp('In PDCload4: Setting controls for outlier repair')
  if max(PMUckbits)==0
    disp('In PDCload4: PMU check bits not found')
    disp('  Option for context based patching is turned off -- no outlier repair')
    PatchMode=0;
  else
    prompt='In PDCload4: Find & repair data outliers? ';
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PDCload4_PatchMode'), PSMMacro.PDCload4_PatchMode=NaN;end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_PatchMode))      % 'Macro record mode' or 'selection was not defined in a macro'
        PatchMode=promptyn(prompt,'y');
    else
        PatchMode=PSMMacro.PDCload4_PatchMode;
    end
    
    if PSMMacro.RunMode==0      % if in macro recording mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCload4_PatchMode=PatchMode;
        else
            PSMMacro.PDCload4_PatchMode=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
    
  end
  
  %----------------------------------------------------
  % Begin: Macro selection ZN 03/31/06
  %keyboard%
  if ~isfield(PSMMacro, 'PDCload4_BnkLevelPU'), PSMMacro.PDCload4_BnkLevelPU=NaN; end
  if ~isfield(PSMMacro, 'PDCload4_PlotPatch'), PSMMacro.PDCload4_PlotPatch=NaN; end
  if ~isfield(PSMMacro, 'PDCload4_BnkFactor'), PSMMacro.PDCload4_BnkFactor=NaN; end
  if ~isfield(PSMMacro, 'PDCload4_LogPatch'), PSMMacro.PDCload4_LogPatch=NaN; end
  
  if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_BnkLevelPU) || isnan(PSMMacro.PDCload4_PlotPatch))      % 'Not Macro playing mode' or 'selection was not defined in a macro'
        LogPatch=0; PlotPatch=0;
        BnkLevelPU=0.001; BnkFactor=0.2;
  else
        LogPatch=PSMMacro.PDCload4_LogPatch;
        PlotPatch=PSMMacro.PDCload4_PlotPatch;
        BnkLevelPU=PSMMacro.PDCload4_BnkLevelPU;
        BnkFactor=PSMMacro.PDCload4_BnkFactor;
  end
  % End: Macro selection ZN 03/31/06
  %----------------------------------------------------
  if PatchMode
    strs=['In PDCload4: PatchMode= ' num2str(PatchMode)]; 
    strs=str2mat(strs,'  Data patching is based upon PMU/PDC status bits');
    strs=str2mat(strs,'  Option for context based patching is turned off');
    disp(strs); disp(' ')
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    %keyboard%
    if ~isfield(PSMMacro, 'PDCload4_logpatch'),  PSMMacro.PDCload4_logpatch=NaN; end  
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_logpatch))      % 'Macro record mode' or 'selection was not defined in a macro'
        logpatch =promptyn('In PDCload4: Display data patching log? ','n');
    else
       logpatch=PSMMacro.PDCload4_logpatch;
    end
    
    if PSMMacro.RunMode==0      % if in macro recording mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCload4_logpatch=logpatch;
        else
            PSMMacro.PDCload4_logpatch=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
    
    
    if logpatch
      LogPatch=2;
      LogSum =promptyn('             Summary log only? ','y');
      LogPatch=LogPatch-LogSum;
    end
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PDCload4_PlotPatch'), PSMMacro.PDCload4_PlotPatch=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_PlotPatch))      % 'Macro record mode' or 'selection was not defined in a macro'
        PlotPatch=promptyn('In PDCload4: Plot patched phasors? ','n');
    else
        PlotPatch=PSMMacro.PDCload4_PlotPatch;
    end
    
    if PSMMacro.RunMode==0      % if in macro recording mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCload4_PlotPatch=PlotPatch;
        else
            PSMMacro.PDCload4_PlotPatch=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
    
    str1=['In PDCload4: Mode ' num2str(PatchMode) ' patching across outliers in phasor data'];
    setok=0; maxtrys=10;
    for i=1:maxtrys
      if ~setok
        disp('In PDCload4: General parameters for data patching')
        str1=sprintf('  Percent BlankLevel  is BnkLevelPU =%5.3f',BnkLevelPU); 
        str2=sprintf('  Percent BlankFactor is BnkFactor  =%5.3f',BnkFactor);
        str3=       ['  PlotPatch Control   is PlotPatch  = ' num2str(PlotPatch)];
        str4=       ['  LogPatch  Control   is LogPatch   = ' num2str(LogPatch)];
        str5=       ['  Patching  Control   is PatchMode  = ' num2str(PatchMode)];
        disp(str2mat(str1,str2,str3,str4,str5));
        %----------------------------------------------------
        % Begin: Macro selection ZN 03/31/06
        setok2=setok;
        
        if ~isfield(PSMMacro, 'PDCload4_setok2'), PSMMacro.PDCload4_setok2=NaN; end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_setok2))      % 'Not Macro playing mode' or 'selection was not defined in a macro'
       	    setok2=promptyn('In PDCload4: Are these values ok? ','y');
        else
            setok2=PSMMacro.PDCload4_setok2;
        end
    
        if PSMMacro.RunMode==0      % if in macro recording mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PDCload4_setok2=setok2;
            else
                PSMMacro.PDCload4_setok2=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        
        setok=setok2;
        % End: Macro selection ZN 03/31/06
        %----------------------------------------------------
        if ~setok
	      disp('Invoking "keyboard" command - Enter "return" when you are finished')
          keyboard
        end
      end
    end
    
     %----------------------------------------------------
     % Begin: Macro selection ZN 03/31/06
     if ~isfield(PSMMacro, 'PDCload4_BnkLevelPU'), PSMMacro.PDCload4_BnkLevelPU=NaN; end
     if ~isfield(PSMMacro, 'PDCload4_PlotPatch'), PSMMacro.PDCload4_PlotPatch=NaN; end
     if ~isfield(PSMMacro, 'PDCload4_BnkFactor'), PSMMacro.PDCload4_BnkFactor=NaN; end
     if ~isfield(PSMMacro, 'PDCload4_LogPatch'), PSMMacro.PDCload4_LogPatch=NaN; end
     
     if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_BnkLevelPU) || isnan(PSMMacro.PDCload4_PlotPatch))      % 'Not Macro playing mode' or 'selection was not defined in a macro'
         if ~setok
             disp(sprintf('Sorry -%5i chances is all you get!',maxtrys));
             disp('Reverting to default values');
             BnkLevelPU=0.001; BnkFactor=0.2;
         end
     else
         BnkLevelPU=PSMMacro.PDCload4_BnkLevelPU;
         BnkFactor=PSMMacro.PDCload4_BnkFactor;
         PlotPatch=PSMMacro.PDCload4_PlotPatch;
         LogPatch=PSMMacro.PDCload4_LogPatch;
         PatchMode=PSMMacro.PDCload4_PatchMode;
     end

     if PSMMacro.RunMode==0      % if in macro recording mode 
         if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCload4_BnkLevelPU=BnkLevelPU;
            PSMMacro.PDCload4_BnkFactor=BnkFactor;
            PSMMacro.PDCload4_PlotPatch=PlotPatch;
            PSMMacro.PDCload4_LogPatch=LogPatch;
            PSMMacro.PDCload4_PatchMode=PatchMode;
         else
            PSMMacro.PDCload4_BnkLevelPU=NaN;
            PSMMacro.PDCload4_BnkFactor=NaN;
            PSMMacro.PDCload4_PlotPatch=NaN;
            PSMMacro.PDCload4_LogPatch=NaN;
            PSMMacro.PDCload4_PatchMode=NaN;
         end
         save(PSMMacro.MacroName,'PSMMacro');
     end
     % End: Macro selection ZN 03/31/06
     %----------------------------------------------------
     
    str1=sprintf('In PDCload4:'); 
    str2=sprintf('  Percent BlankLevel  is BnkLevelPU =%5.3f',BnkLevelPU); 
    str2=sprintf('  Percent BlankFactor is BnkFactor  =%5.3f',BnkFactor);
    strs=str2mat(str1,str2,str3);
    CaseCom=str2mat(CaseCom,strs); 
    disp(strs); disp(' ')
  end
end
%************************************************************************

%************************************************************************
%Scale phasors, patch through outliers
%Remove parasitic oscillation if indicated
%Rotate phasors as needed
disp(' ')
disp('In PDCload4: Scaling phasors')
i=sqrt(-1);
patchop=1;
Npatched=0; BnkPts0=0; MaxBnkPts=0; 
AllBlanks=0; NoBlanks=0; Empties=0;
PlotNo=0;
for K=1:NPMUs
  PMUtagK=PMUtagsImp(K,:);
  PatchSig=0;
  if PatchMode&(PMUlocs(K)==K)
    %-----------------------------------------------------------
    % start: channel selection before patching (ZN 04/21/2006)
    % if any of the phasors on this PMU is required for calculating rms values.  
     if sum(VIcon(:,7,K))~=0    
        BnkPts0=find(Flags31(:,K)==1);
        Kdropped=length(BnkPts0); %if isempty(Kdropped), Kdropped=0; end
        AllBlanks=length(BnkPts0)==size(Flags31(:,K),1);
        NoBlanks=isempty(BnkPts0);
        PatchSig=~(AllBlanks|NoBlanks);
        str0='No outlier patching for this PMU';
          if NoBlanks
              str1=['PMU ' PMUtagK ': Status tags indicate no dropped points'];
              disp(str2mat(str1,str0))
          end
          
          if AllBlanks
              str1=['PMU ' PMUtagK ': Status tags indicate all points dropped'];
              disp(str2mat(str1,str0))
          else 
              if ~NoBlanks
                  str1=['PMU ' PMUtagK ': Status tags indicate ' num2str(Kdropped) ' dropped points'];
                  disp(str1); disp(' ')
              end
          end
      end
      % start: channel selection before patching (ZN 04/21/2006)
      %-----------------------------------------------------------
  end
  BnkTag=-9999;
  BnkLevel=0;
  nphsrsK=sum(VIcon(:,1,K)==1|VIcon(:,1,K)==2);
  FreqV=[]; 
  for N=1:nphsrsK 
   %-----------------------------------------------------------
   % start: channel selection before patching (ZN 04/06/2006)
   % if this phasor is not required for calculating rms values.    
   if VIcon(N,7,K)==0      
          continue;
   end
   % end: channel selection before patching (ZN 04/06/2006) 
   %-----------------------------------------------------------
    PhsrNameNK=deblank(PhsrNames(N,:,K));
	KNtag=sprintf('%2.0i %2.0i',[K N]);
    PhsrNo=PMUbase(K)+N;
	phsrtype=VIcon(N,1,K);
    EmptyType=phsrtype<1;
    EmptyName=~isempty(findstr('dummy' ,lower(PhsrNameNK)));
    EmptyName=EmptyName|~isempty(findstr('spare' ,lower(PhsrNameNK)));
    EmptyName=EmptyName|~isempty(findstr('empty' ,lower(PhsrNameNK)));
    EmptyName=EmptyName|~isempty(findstr('future',lower(PhsrNameNK)));
	if nXfile==1
      if EmptyName
        str=['Phasor ' PhsrNameNK ' has name indicating empty phasor: presumed empty'];
        disp(str)
      end
      if EmptyType
        str=['Phasor ' PhsrNameNK ' is type ' num2str(phsrtype) ': presumed empty'];
        disp(str)
      end
    end
    patched=0; 
    EmptySig=AllBlanks|EmptyType|EmptyName;
    if EmptySig, patched=-1; end
    if phsrtype==1|phsrtype==2  %Start of VI processing for present PMU
      if PatchSig&(~EmptySig)   %Start of VI patching
        if LogPatch==2
          disp(['Checking Phasor ' KNtag ': phasor name is ' PhsrNames(N,:,K)])
        end       
        BnkLevel=sum(abs(PMUsigs(1:10,PhsrNo)))*BnkLevelPU;
        [PatchedSig,patched,BnkPts,PlotNo]=PDCpatch2(PMUsigs(:,PhsrNo),PhsrNames(N,:,K),...
	        patchop,BnkLevel,BnkFactor,patched,LogPatch-1,PlotPatch,BnkPts0,BnkTag);
        if PatchMode, PMUsigs(:,PhsrNo)=PatchedSig; end
        if patched>0
	      if PatchMode, Npatched=Npatched+1; end
          NBnkPts=length(BnkPts);
          MaxBnkPts=max(NBnkPts,MaxBnkPts);
 	      if LogPatch>0
            str1=['Phasor ' KNtag ': ' sprintf('%3.0i points repaired',NBnkPts)];
            str1=[str1 ' for ' PhsrNames(N,:,K)]; disp(str1)
          end 
        end
	    if patched<0
	      Empties=Empties+1;
 	      if LogPatch>0
            disp(['phasor ' PhsrNames(N,:,K) ' seems empty'])
          end
	    end
	  end  %End of VI patching
      scale=1.0;
	  if phsrtype==1,scale=VIcon(N,2,K)*VIcon(N,3,K); end
	  if phsrtype==2,scale=VIcon(N,2,K)*VIcon(N,3,K)/VIcon(N,5,K); end
	  PMUsigs(:,PMUbase(K)+N)=PMUsigs(:,PMUbase(K)+N)*scale;
      rotation=VIcon(N,4,K);
	  if rotation~=0
		S1=sprintf('In PDCload4: %7.2f phasor rotation for ', rotation);
		disp([S1 PhsrNames(N,:,K)])
		rotation=rotation/r2deg;
		PMUsigs(:,PMUbase(K)+N)=PMUsigs(:,PMUbase(K)+N)*exp(i*rotation);
      end
 	  SigTest1=(phsrtype==1);
 	  SigTest2=(phsrtype==2)&DeOscI;
      DeOscTest=~EmptySig&(SigTest1|SigTest2);
      if DeOscTest  %Removal of parasitic oscillations
        %TryDeOsc=0; CkDeOsc=0; DeOscI=0;
        TryDeOscN=TryDeOsc; trackX=0; %keyboard
        Tlabel=''; 
        if TryDeOsc
          if CkDeOsc
             prompt='In PDCload4: Check parasitic oscillation in phasor ';
             prompt=[prompt PhsrNameNK '? '];
             CkDeOscN=promptyn(prompt,'y');
             if TryDeOscN, trackX=1; end  
          end
          if TryDeOscN
            decfacE=round(samplerate/4);
            namesE=str2mat('Time',[PhsrNameNK ' VMag '],[PhsrNameNK ' VAngD']);
            VAngD=PSMunwrap(angle(PMUsigs(:,PhsrNo))*180/pi);
            VAngDE=VAngD*pi/180;
            PSMsigsE=[time abs(PMUsigs(:,PhsrNo)) VAngD];
            signameE=['Phasor ' KNtag ': ' PhsrNameNK];
            [CaseComM,namesM,PSMsigsM,ModParsN,FreqE]...
              =PMUosc2(caseID,'',CaseCom,namesE,PSMsigsE,...
               tstep,decfacE,1,0,trackX,signameE,Tlabel,FreqV);
            UseDeOsc=1;
            if phsrtype==1, FreqV=FreqE; end 
            if CkDeOsc
              %----------------------------------------------------
              % Begin: Macro selection ZN 02/12/2007
              if ~isfield(PSMMacro, 'PDCload4_keybdok'), PSMMacro.PDCload4_keybdok=NaN;end
              if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_keybdok))      % 'Macro record mode' or 'selection was not defined in a macro'
                    keybdok=promptyn(['In PDCload4: Do you want the keyboard? '],'n');
              else
                    keybdok=PSMMacro.PDCload4_keybdok;
              end

              if PSMMacro.RunMode==0      % if in macro recording mode 
                    if PSMMacro.PauseMode==0            % if record mode is not paused
                        PSMMacro.PDCload4_keybdok=keybdok;
                    else
                        PSMMacro.PDCload4_keybdok=NaN;
                    end
                    save(PSMMacro.MacroName,'PSMMacro');
              end
              % End: Macro selection ZN 02/12/2007
              %----------------------------------------------------
              
              if keybdok
                disp(['In PDCload4: Invoking "keyboard" command - Enter "return" when you are finished'])
                keyboard
              end
              prompt='In PDCload4: Accept oscillation removal for phasor ';
              prompt=[prompt PhsrNameNK ' ? '];
              if phsrtype==1, UseDeOsc=promptyn(prompt,'y');
              else            UseDeOsc=promptyn(prompt,'n'); 
              end
            end
            if UseDeOscLocs, UseDeOsc=~isempty(find(N==DeOscLocs(K,:))); end
            if UseDeOsc
              if SetDeOscLocs
                locsZ=find(DeOscLocs(K,:)==0); LZ1=locsZ(1);
                DeOscLocs(K,LZ1)=N; 
              end
              VMagDE=PSMsigsM(:,5);
              PhsrDE=VMagDE.*cos(VAngDE)+j*VMagDE.*sin(VAngDE);
              PMUsigs(:,PhsrNo)=PhsrDE;
              TagDE=' DeOsc'; 
              PhsrNameNew=[deblank(PhsrNames(N,:,K)) TagDE]; 
              [Xlen,Ylen,Zlen]=size(PhsrNames);
              YlenNew=length(PhsrNameNew);
              if YlenNew<=Ylen
                PhsrNames(N,1:YlenNew,K)=PhsrNameNew;
              else
                PhsrNamesN=char(ones(Xlen,YlenNew+2,Zlen)*' ');
                PhsrNamesN(:,1:Ylen,:)=PhsrNames;
                PhsrNames=PhsrNamesN;
                PhsrNames(N,1:YlenNew,K)=PhsrNameNew;
              end 
              if 0 %Cut&paste diagnostics 
                PhsrSave=PMUsigs(:,PhsrNo);
                PhsrAngSave=PSMunwrap(angle(PhsrSave)*180/pi);
                PhsrAngNew =PSMunwrap(angle(PhsrDE  )*180/pi);
                disp(' '); disp([PhsrAngSave(1:2)';PhsrAngNew(1:2)']) 
                figure; plot([PhsrAngSave VAngD]); title('PhsrAngSave VAngD')
                figure; plot([PhsrAngSave PhsrAngNew]); title('PhsrAngSave PhsrAngNew')
                figure; plot([abs(PhsrSave) abs(PhsrDE)]); title('PhsrMags')
              end
            end
          end
        end
      end
    end   %End of VI processing for present PMU
    if PlotNo>=20   %Prevent graphics overload
      disp(' ')
      disp(sprintf('In PPDCload4: %3.0i diagnostic plots open',PlotNo))
      closeok=promptyn('In PPDCload4: Close all plots? ','y');
      if closeok, close all;
      else
          %----------------------------------------------------
          % Begin: Macro selection ZN 02/12/2007
          if ~isfield(PSMMacro, 'PDCload4_keybdok02'), PSMMacro.PDCload4_keybdok02=NaN;end
          if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_keybdok02))      % 'Macro record mode' or 'selection was not defined in a macro'
              keybdok=promptyn('In PPDCload4: Do you want the keyboard? ', 'n');
          else
              keybdok=PSMMacro.PDCload4_keybdok02;
          end

          if PSMMacro.RunMode==0      % if in macro recording mode 
                if PSMMacro.PauseMode==0            % if record mode is not paused
                    PSMMacro.PDCload4_keybdok02=keybdok;
                else
                    PSMMacro.PDCload4_keybdok02=NaN;
                end
                save(PSMMacro.MacroName,'PSMMacro');
          end
          % End: Macro selection ZN 02/12/2007
          %----------------------------------------------------
        
        
        if keybdok
          disp('In PDCload4: Invoking "keyboard" command - Enter "return" when you are finished')
          keyboard
        end
      end
      offok=promptyn('In PPDCload4: End plot sequence? ','n');
      if offok, PlotPatch=0; end
    end
  end    %Termination of loop N=1:nphsrsK
  N=nphsrsK+1;  %Frequency signal for present PMU

  %-----------------------------------------------------------
  % start: channel selection before patching (ZN 04/06/2006)
  % if this frequency is not required for displaying
  if VIcon(N,7,K)==0       
         continue;
  end
  % end: channel selection before patching (ZN 04/06/2006)
  %-----------------------------------------------------------


  
  BnkTag=-9999; 
  patched=0; if AllBlanks, patched=-1; end
  if PatchSig
    if LogPatch==2
      disp([sprintf('Checking Frequency %3.0i',[K]) ': Signal name is ' PhsrNames(N,:,K)])
    end
    [PatchedSig,patched,BnkPts,PlotNo]=PDCpatch1(PMUfreqs(:,K),PhsrNames(N,:,K),...
	     patchop,BnkLevel,BnkFactor,patched,LogPatch-1,PlotPatch,BnkPts0,BnkTag);
    if PatchMode, PMUfreqs(:,K)=PatchedSig; end
    if patched>0
	  if PatchMode, Npatched=Npatched+1; end
      NBnkPts=length(BnkPts);
      MaxBnkPts=max(NBnkPts,MaxBnkPts);
 	  if LogPatch>0
        str1=sprintf('Frequency %4.0i: %3.0i points repaired for ',[K NBnkPts]);
        str1=[str1 PhsrNames(N,:,K)]; disp(str1)
      end
    end 
    if patched<0
      Empties=Empties+1;
 	  if LogPatch>0
	    disp(['Signal ' PhsrNames(N,:,K) ' seems empty'])
      end
    end
  end  %End of frequency patching for PMU K
  scale=1/VIcon(N,2,K); offset=VIcon(N,3,K);
  PMUfreqs(:,K)=PMUfreqs(:,K)*scale+offset;
end  %Termination of loop K=1:NPMUs

%Processing summary
disp(' ')
%-----------------------------------------------------------
% start: channel selection before patching (ZN 04/21/2006)
countPhsrs=sum(sum(VIcon(:,7,:)));
str1=['In PDCload4: ' num2str(countPhsrs) ' phasors have been loaded '];
%str1=['In PDCload4: ' num2str(nphsrs) ' phasors have been loaded '];
% end: channel selection before patching (ZN 04/21/2006)
%-----------------------------------------------------------
disp(str1); CaseCom=str2mat(CaseCom,str1)
if PatchMode
  str1=['In PDCload4: ' num2str(Npatched) ' phasors have been patched '];
  str2=['- Worst Case = ' num2str(MaxBnkPts) ' points'];
  if MaxBnkPts>0, str1=[str1 str2]; end
  CaseCom=str2mat(CaseCom,str1); disp(str1)
  if Empties>0
    str1=['In PDCload4: ' num2str(Empties) ' phasors seem empty'];
    CaseCom=str2mat(CaseCom,str1); disp(str1)
  end
  if PlotNo>5
    disp(' ')
    disp(sprintf('In PPDCload4: %3.0i diagnostic plots open',PlotNo))
    closeok=promptyn('In PPDCload4: Close all plots? ', 'y');
    if closeok, close all;
    else
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/12/2007
      if ~isfield(PSMMacro, 'PDCload4_keybdok03'), PSMMacro.PDCload4_keybdok03=NaN;end
      if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCload4_keybdok03))      % 'Macro record mode' or 'selection was not defined in a macro'
          keybdok=promptyn('In PPDCload4: Do you want the keyboard? ', 'n');
      else
          keybdok=PSMMacro.PDCload4_keybdok03;
      end

      if PSMMacro.RunMode==0      % if in macro recording mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.PDCload4_keybdok03=keybdok;
            else
                PSMMacro.PDCload4_keybdok03=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
      end
      % End: Macro selection ZN 02/12/2007
      %----------------------------------------------------  

      if keybdok
        disp('In PDCload4: Invoking "keyboard" command - Enter "return" when you are finished')
        keyboard
      end
    end
  end
end
if max(max(DeOscLocs))>0
  disp('DeOscLocs='); disp(DeOscLocs)
  %disp(str); CaseCom=str2mat(CaseCom,str);
end
%************************************************************************

%*************************************************************************
PMUtags=PMUtagsExp;
CaseComPDC=CaseCom;
if saveopt  %Invoke utility for saving extracted phasors
  disp( 'In PDCload4: Invoking utility to save extracted phasors')
  disp(['In PDCload4: Data extracted from file  ' PDCfileX])
  ListName='none';
  SaveList=['PMUsigs PMUfreqs tstep PMUtags PMUnames PhsrNames VIcon'];
  SaveList=[SaveList ' CFname CaseComPDC PDCfileX'];
  PSMsave
end
%*************************************************************************

disp('Returning from PDCload4'); 
if nXfile==1
   %----------------------------------------------------
   % Begin: Macro selection ZN 03/31/06
   if (PSMMacro.RunMode>=1)      % 'Macro play mode' 
         keybdok=0;
   else
         keybdok=promptyn('Do you want the keyboard? ','n');
   end
   % End: Macro selection ZN 03/31/06
   %----------------------------------------------------
  if keybdok
    disp('In PDCload4: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
    if 0
      names2chans(num2str(PMUbase))
      PMUno=9; loc=PMUbase(PMUno);
      figure; plot(abs(PMUsigs(:,loc+1)))
      figure; plot(unwrap(angle(PMUsigs(:,loc+1))))
      PMUtagK=deblank(PMUtags(PMUno,:));
      signameG=[PMUtagK 'phsrs(:,1)'];
      figure; eval(['plot(abs(' signameG '))'])
      figure; eval(['plot(unwarp(angle(' signameG ')))'])    
    end
  end
end
return

%end of PSMT utility

