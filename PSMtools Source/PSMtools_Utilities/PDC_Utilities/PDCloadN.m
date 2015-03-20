function [caseID,casetime,CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
    =PDCloadN(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
     loadopt,rmsopt,saveopt,trackX);

% PDCloadN is the main driver for loading signals recorded on a BPA
% developed Phasor Data Concentrator (PDC) 	
% 
% [caseID,casetime,CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
%   =PDCloadN(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
%    loadopt,rmsopt,saveopt,trackX);
%
% This version accepts BPA configurations 1-3 plus two general versions
% that use .ini files to specify PDC configuration.
%
% Special functions used:
%   PDCload1,PDCload2,PDCload3,PDCload4, PDCCSVload
%   DSTalias0
%   PDCcalcA,PDCcalcC
%   PSMunwrap
%   PDCrefsig
%   PSMsave
%   names2chans
%	promptyn,promptnv
%   
% Modified 05/18/05 by jfh.  Changed some defaults
% Modified 07/22/05 by Henry Huang (PNNL).  Add PDC CSV reader for AEP
% Modified 03/30/06 by jfh.  Inserted elapsed time logic
% Modified 04/06/06 by zn.   Selection of channels before patching
% Modified 05/10/06 by zn.   Automatic Executions

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


global PSMtype CFname PSMfiles PSMreftimes
global PMUtags PMUnames PhsrNames VIcon 

chansXok=0;
%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
global PSMMacro         % Macro Structure 
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
% End: Macro definition ZN 03/31/06
%----------------------------------------------------

SaveFile='';

FNname='PDCloadN';
disp(['In ' FNname ': Loading PDCfiles']) 

%*************************************************************************
if isempty(PSMfiles)
  disp(['In ' FNname ': Seeking PSMfiles to load' ])
  for N=1:10
    [filename,pathname]=uigetfile(['*.*'],'Locate file to retrieve:');
    if filename(1)==0|pathname(1)==0
      disp('No file indicated -- done'), break
    end
    if N==1, PSMfiles=filename;
	   eval(['cd ' '''' pathname '''']) 
    else PSMfiles=str2mat(PSMfiles,filename); end
  end
end
DataPath=cd;
%*************************************************************************

%*************************************************************************
%Modify source names in PDC files
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro, 'PDCloadN_AliasOK'), PSMMacro.PDCloadN_AliasOK=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PDCloadN_AliasOK))      % 'Macro record mode' or 'selection was not defined in a macro'
        AliasOK=promptyn(['In ' FNname ': Modify source names in selected PDCfiles? '], 'n');
    else
        AliasOK=PSMMacro.PDCloadN_AliasOK;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCloadN_AliasOK=AliasOK;
        else
            PSMMacro.PDCloadN_AliasOK=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------
%help DSTalias0
if AliasOK
 %keyboard
  disp(['In ' FNname ': Launching dialog box for Master configuration file'])
  
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro, 'PDCloadN_n'), PSMMacro.PDCloadN_n=''; end
    if ~isfield(PSMMacro, 'PDCloadN_p'), PSMMacro.PDCloadN_p=''; end
    if (PSMMacro.RunMode<1 || isempty(PSMMacro.PDCloadN_n))      % 'Macro record mode' or 'selection was not defined in a macro'
        [n,p]=uigetfile('*.*','Select Master configuration file for sourcename modification:');
    else
        n=PSMMacro.PDCloadN_n;
        p=PSMMacro.PDCloadN_p;
    end

    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PDCloadN_n=n;
            PSMMacro.PDCloadN_p=p;
        else
            PSMMacro.PDCloadN_n='';
            PSMMacro.PDCloadN_p='';
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
   
  
  if n==0
    disp('No file selected -- return')
    return 
  end;
  inifile0=[p n];
  [fid,message]=fopen(inifile0,'r');
  if fid<0; error(message); end;
  DataPath=cd;
  opts.verbose=1;
  [PSMfilesA,errmsg]=dstalias0(DataPath,PSMfiles,inifile0,DataPath,opts);
  if ~isempty(errmsg)
    disp(' '); disp('ERROR RETURN from DSTaliasO:')
    disp(errmsg); disp(' ')
  end
  disp(' ')
  if isempty(PSMfilesA)
    disp(['In ' FNname ': No files changed']); disp(' ')
    AliasOK=0; 
  else
    disp(['In ' FNname ': Results of PDC rename operations']) 
    NfilesA=size(PSMfilesA,1); NfilesS=size(PSMfiles,1);
    if NfilesA~=NfilesS
      disp(['In ' FNname ': Wrong number of modified files'])
    end
    nbksS=max([length(PSMfiles(1,:)) ,4]); bksS=blanks(nbksS);
    nbksA=max([length(PSMfilesA(1,:)),4]); bksA=blanks(nbksA);
    MaxNames=max([NfilesS,NfilesA]);
    for N=1:MaxNames
      str1=bksS; if N<=NfilesS, str1=PSMfiles(N,:) ; end
      str2=bksA; if N<=NfilesA, str2=PSMfilesA(N,:); end
      disp(['  ' str1 '  ' str2])
    end
    keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '], 'n');
    if keybdok
      disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
    end
    UseAlias=promptyn(['In ' FNname ': Process modified files instead of original? '], '');
    if UseAlias
      disp(['In ' FNname ': Processing modified files']) 
      PSMfiles=PSMfilesA;
      disp(['In ' FNname ': Resetting caseID and comments file'])
      disp(['In ' FNname ': Define new case tags']);
      [caseID,casetime,CaseCom]=CaseTags('DSTalias');
    end
  end
end
%*************************************************************************

%*************************************************************************
%Display main control parameters
nXfiles=size(PSMfiles,1);
disp(['In PDCloadN: Seeking data from ' sprintf('%2.1i',nXfiles) ' files:'])
disp(PSMfiles)
disp(['In PDCloadN: Load option = ' sprintf('%3.1i',loadopt)])
disp(['In PDCloadN: rms option  = ' sprintf('%3.1i',rmsopt)])
Readt0=clock;
str=['In PDCloadN: Starting data read at ' datestr(now)];
disp(str); disp(' ')
%*************************************************************************

%Clear storage
PSMsigsX=[]; PSMreftimes=[];
chankeyX=''; namesX='';
PMUsigs=[]; PMUfreqs=[]; NewSigsX=[];
NOGPS=[]; 

%*************************************************************************
%Top of data extraction loop
trackPatch=0;
%trackPatch=promptyn('In PDCloadN: Display diagnostics for data repair? ','n');
for nXfile=1:nXfiles     %Start of main extraction loop
  PDCfile=deblank(PSMfiles(nXfile,:));  %May be overwritten if loadopt==-1
  PSMreftime=0;
  if (loadopt==-1)   %Extract previously translated file
	  eval(['load ' PDCfile])
	  maxpoints=size(PMUsigs,1); maxtime=(maxpoints-1)*tstep;
    S1=['PDC File Extracted = ' PDCfile];
    S2=sprintf('Time Step = %10.5f    Max Time = %8.3f', [tstep maxtime]);
    CaseCom=str2mat(CaseCom,S1,S2);
	  %rmsopt=1;
  end
  if (loadopt==1) 
    CFname='Old PDC Configuration 1'
    [PMUsigs,PMUfreqs,tstep,PMUnames,PhsrNames,blank,PDCfile,nIphsrs,CaseCom]...
      = PDCload1(caseID,PDCfile,PMUsigs,PMUfreqs,CaseCom,saveopt,trackX,trackPatch,...
	      nXfile);
	  rmsopt=1;
    if nXfile==1, PSMreftimes=PSMreftime;
    else PSMreftimes=[PSMreftimes PSMreftime];
    end
  end
  if (loadopt==2) 
    CFname='Old PDC Configuration 2';
    [PMUsigs,PMUfreqs,tstep,PMUnames,PhsrNames,blank,PDCfile,nIphsrs,CaseCom]...
      = PDCload2(caseID,PDCfile,PMUsigs,PMUfreqs,CaseCom,saveopt,trackX,trackPatch,...
	      nXfile);
	  rmsopt=1;
  end
  if (loadopt==3)  
    CFname='Old PDC Configuration 3';
    [PMUsigs,PMUfreqs,tstep,PMUnames,PhsrNames,blank,PDCfile,nIphsrs,CaseCom]...
      = PDCload3(caseID,PDCfile,PMUsigs,PMUfreqs,CaseCom,saveopt,trackX,trackPatch,...
	      nXfile);
	  rmsopt=1;
  end
  if (loadopt==4)  %MatLab formats 1:2, with configuration file
	  [PMUsigs,PMUfreqs,tstep,PMUtags,PMUnames,PhsrNames,VIcon,CFname,MatFmt,...
       CaseCom,PDCfile,PSMreftime,NOGPSN, chansX, chansXok] = PDCload4(caseID,PDCfile,PMUsigs,PMUfreqs,CaseCom,...
       saveopt,trackX,trackPatch,nXfile, chansX, chansXok);
       rmsopt=3;
    if nXfile==1
      PSMreftimes=PSMreftime;
      NOGPS=NOGPSN;
    else 
      PSMreftimes=[PSMreftimes PSMreftime];
      NOGPS=NOGPS+NOGPSN;
    end
  end

  if (loadopt==5)  %MatLab formats 1:2, with configuration file. PDC CSV reader, for AEP. Henry Huang, 2005-07-22
	  [PMUsigs,PMUfreqs,tstep,PMUtags,PMUnames,PhsrNames,VIcon,CFname,MatFmt,...
       CaseCom,PDCfile,PSMreftime,NOGPSN] = PDCCSVload(caseID,PDCfile,PMUsigs,PMUfreqs,CaseCom,...
       saveopt,trackX,trackPatch,nXfile);
	  rmsopt=3;
    if nXfile==1
      PSMreftimes=PSMreftime;
      NOGPS=NOGPSN;
    else 
      PSMreftimes=[PSMreftimes PSMreftime];
      NOGPS=NOGPS+NOGPSN;
    end
  end
  if ~isempty(get(0,'Children'))  %Test for open plots
    if trackX|trackPatch
	    closeok=promptyn('In PDCloadN: Close diagnostic plots? ', '');
      if closeok, close all, end
    end
  end
  if (rmsopt<=0)
	  disp('In PDCloadN: rmsopt<=0 -- return'), return
  end
 
  %Test for empty data array
  if isempty(PMUsigs)
	  PSMtype='none';
    disp('In PDCloadN: No signals -- return'), return
  end
  
  %General PDCcalc version A
  if rmsopt==1
    [CaseCom,RMSkey,namesX,NewSigsX,RMSnames,chansX]...
         =PDCcalcA(caseID,NewSigsX,chansX,PMUsigs,PMUfreqs,PMUnames,PhsrNames,...
          tstep,nIphsrs,CaseCom,saveopt,CFname,trackX,nXfile);
  end
  %Extended PDCcalc version C (general standard) 
  if rmsopt==3
  	  [CaseCom,RMSkey,namesX,NewSigsX,RMSnames,chansX, chansXok]...
         =PDCcalcC(caseID,NewSigsX,chansX,PMUsigs,PMUfreqs,PMUnames,PhsrNames,...
          tstep,VIcon,CaseCom,CFname,trackX,nXfile,NOGPS, chansXok);
  end 
  %Test for empty data array
  if isempty(NewSigsX)
	  disp('In PDCloadN: No signals -- return'), return
  end
  maxpoints=size(NewSigsX,1);
  NewSigsX(:,1)=[0:maxpoints-1]'*tstep+PSMreftimes(nXfile)-PSMreftimes(1);
  if nXfile==1
    PSMsigsX=NewSigsX; 
  else   %Test records continuity
    RefTpts=round((PSMreftimes(nXfile)-PSMreftimes(nXfile-1))/tstep);
    if RefTpts==maxpoints, 
      PSMsigsX=[PSMsigsX',NewSigsX']'; 
    else EndChecks
    end
  end
end     %End of main extraction loop
%************************************************************************

%************************************************************************
%Examine data characteristics
clear PMUsigs PMUfreqs
[maxpoints nsigs]=size(PSMsigsX);
disp(['In PDCloadN: Size PSMsigsX = ' num2str(size(PSMsigsX))])
NPMUs=size(PMUtags,1);
if isempty(NOGPS), NOGPS=0; end
LocsOut=find(NOGPS>0); Nout=length(LocsOut);
strs=['  Number of PMUs w/o GPS synch = ' num2str(Nout) ':'];
for L=1:Nout
  strs=str2mat(strs,['    ' PMUtags(LocsOut(L),:)]);  
end
disp(strs)
%disp('IN PDCloadN: Keyboard 1'); keyboard
if 0  %Cut&paste diagnostics
  names2chans(namesX(1:12,:))
  figure; plot(PSMsigsX(:,8))
  SaveSigs=PSMsigsX;
  PSMsigsX=SaveSigs;
end

%************************************************************************

%************************************************************************
%Unwrap voltage & current angles
%Indicate angles & frequencies w/o GPS synch
OutFound=0; %keyboard
[lines chars]=size(namesX);
for L=1:lines
  str1=namesX(L,:);
  locV=findstr('VAng',str1); 
  locI=findstr('IAng',str1);
  locF=findstr('Freq',str1);
  test1=~(isempty(locV)&isempty(locI)&isempty(locF));
  test2=~(isempty(locV)&isempty(locI));
  if test1
    if test2  %Unwrap angle
      [PSMsigsX(:,L)]=PSMunwrap(PSMsigsX(:,L));
    end
    for K=1:Nout
      str2 =deblank(PMUtags(LocsOut(K),1:4));
      test3=~isempty(findstr(str2,str1));
      if test3  %Indicate no GPS synch
        OutFound=1; 
        if locV, str1(locV:locV+5)='VAngLX'; end 
        if locI, str1(locI:locI+5)='IAngLX'; end
        if locF, str1(locF:locF+5)='FreqLX'; end
        namesX(L,:)=str1;
      end
    end  
  end
end
str1='Voltage & current angles have been unwrapped';
str2='No angles or frequencies w/o GPS synch';
if OutFound
  str2='Angles & frequencies w/o GPS synch denoted by X';
end
%Determine elapsed time for data read
Readtime=etime(clock,Readt0);
str3=['In PDCloadN: Data read time = ' num2str(Readtime) ' seconds'];
CaseCom=str2mat(CaseCom,str1,str2,str3);
disp(str1); disp(str2); disp(str3); disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if (PSMMacro.RunMode<1)      % 'Not in play Macro mode' 
    disp('In PDCloadN: Processing is paused - press any key to continue')
    pause
end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------
%************************************************************************


%************************************************************************
%Define final channel key
chankeyX=names2chans(namesX);
%Extend & display case documentation array
CaseCom=str2mat(CaseCom,chankeyX);
%*************************************************************************

disp('Returning from PDCloadN')
disp(' ');

return

%end of PSMT function

