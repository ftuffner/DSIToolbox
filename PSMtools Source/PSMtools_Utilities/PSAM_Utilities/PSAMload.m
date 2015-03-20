
function [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =PSAMload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);

%function [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,...
%  DataPath]...
%   =PSAMload(caseID,chansX,CaseCom,decfacX,loadopt,...
%      saveopt,trackX)

% PSAMload.m is the main driver for loading signals recorded on a BPA
% developed Power System Analysis Monitor (PSAM) 	
% 
%  function [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,...
%    DataPath]...
%    =PSAMload(caseID,chansX,CaseCom,decfacX,loadopt,...
%       saveopt,trackX)
%
% Special functions used:
%   PSAMread
%	  promptyn,promptnv
%   PSMsave
%   
% Last modified 02/19/02.  jfh
% Last modified 10/18/2006 Ning Zhou to add macro. adjust input parameter
%                               according to new PSMload setup

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
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

SaveFile=''; CFname='';

CFname='PSAM';

%*************************************************************************
if isempty(PSMfiles)
  disp(['In PSAMload: Seeking PSMfiles for files to load' ])
  for N=1:10
    [filename,pathname]=uigetfile(['*.*'],'Locate file to retrieve:');
    if filename(1)==0|pathname(1)==0
      disp('No file indicated -- done'), break
    end
    if N==1, PSMfiles(N,:)=filename;
	   eval(['cd ' '''' pathname '''']) 
    else PSMfiles=str2mat(PSMfiles,filename); end
  end
end
%*************************************************************************

%*************************************************************************
%Display & document main control parameters
nXfiles=size(PSMfiles,1);
S1=['In PSAMload: Load option = ' sprintf('%3.1i',loadopt)];
S2=['In PSAMload: Seeking data from ' sprintf('%2.1i',nXfiles) ' files:'];
disp(str2mat(S1,S2))
disp(PSMfiles)
CaseCom=str2mat(CaseCom,S1,S2);
%*************************************************************************

%Clear storage
PSMsigsX=[]; PSMreftimes=[];
chankeyX=''; namesX='';

%*************************************************************************
%Proceed to extract data
disp('   Extracting signals: Dialog window may open')
PSMtype='PSAM';
for nXfile=1:nXfiles     %Start of main extraction loop
  PSMfile=deblank(PSMfiles(nXfile,:));
  [NewSigsX,snames,units,psamname,headerdat]=PSAMread(PSMfile);
  tstep=NewSigsX(2,1)-NewSigsX(1,1); 
  	maxpoints=size(NewSigsX,1); maxtime=(maxpoints-1)*tstep;
  S1=['PSAM File Extracted = ' PSMfile];
  S2=sprintf('Samples = %6.0i  Time Step = %10.5f   Max Time = %8.3f', [maxpoints tstep maxtime]);
  S3=['Time Stamp = ' headerdat.datestr];
  disp(str2mat(S1,S2,S3))
  CaseCom=str2mat(CaseCom,S1,S2,S3);
  reftime=headerdat.datenum;
  S1=[sprintf('PSAM Reference Time = %10.5f',reftime) ' Days'];
  day2sec=24*60*60;
  offset=datenum(1900,1,1,0,0,0)*day2sec;
  PSMreftime=reftime*day2sec-offset;
  PSMdatestr=PSM2Date(PSMreftime);
  S2=['PSAM Reference Time = ' PSMdatestr ' Local Time'];
  disp(str2mat(S1,S2))
  CaseCom=str2mat(CaseCom,PSMfile,S1,S2);
  snames(2,1:7)='unknown';
  if nXfile==1      %Determine signals to extract
    SampleRate=0;
    if tstep>0, SampleRate=1/tstep; end
    S1=sprintf('In PSAMload: tstep      = %6.6f',tstep);
    S2=sprintf('In PSAMload: SampleRate = %6.6f',SampleRate);
    disp(str2mat(S1,S2))
    CaseCom=str2mat(CaseCom,S1,S2);
    RefTimes=reftime;
    names=[snames char(ones(size(snames,1),1)*'  ') units];
    chankey=names2chans(names);
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    %keyboard;
    if ~isfield(PSMMacro, 'PSAMload_chansXok'), PSMMacro.PSAMload_chansXok=NaN; end
    if ~isfield(PSMMacro, 'PSAMload_chansX'), PSMMacro.PSAMload_chansX=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSAMload_chansXok))      % Not in Macro playing mode or selection not defined in a macro
        [chansX,chansXok]=SetExtr2(chansX,names,chankey,CFname);
    else
        chansXok=PSMMacro.PSAMload_chansXok;
        chansX=PSMMacro.PSAMload_chansX;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSAMload_chansXok=chansXok;
            PSMMacro.PSAMload_chansX=chansX;
        else
            PSMMacro.PSAMload_chansXok=NaN;
            PSMMacro.PSAMload_chansX=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------

    
    if ~chansXok, return, end
    if isempty(find(chansX==1)), chansX=[1 chansX]; end
    namesX=names(chansX,:);
  end
  maxpoints=size(NewSigsX,1);
  NewSigsX(:,1)=[0:maxpoints-1]'*tstep;
  NewSigsX=NewSigsX(:,chansX);
  if nXfile==1
    PSMreftimes=PSMreftime;
    PSMsigsX=NewSigsX;
  else 
    PSMreftimes=[PSMreftimes PSMreftime];
    NewSigsX(:,1)=NewSigsX(:,1)+(PSMreftimes(nXfile)-PSMreftimes(1));
    RefTpts=round((PSMreftimes(nXfile)-PSMreftimes(nXfile-1))/tstep);
    if RefTpts==maxpoints, PSMsigsX=[PSMsigsX',NewSigsX(:,chansX)']';
    else EndChecks
    end
  end
end     %End of main extraction loop
%Test for empty data array
if isempty(PSMsigsX)
	PSMtype='none';
  disp('In PSAMload: No signals -- return'), return
end
nfiles=size(PSMfiles,1);
maxpoints=size(PSMsigsX,1); 
maxtime=PSMsigsX(maxpoints,1);
S1=sprintf('In PPSMloadN: %4.0i Files Extracted:',nfiles);
S2=sprintf('Time axis has been inserted at column 1 of signal array');
S3=sprintf('No decimation during signal extraction');
S4=sprintf('Time Step = %10.5f    Max Time = %8.3f', [tstep maxtime]);
if decfacX>1
  S3=sprintf('Decimation factor= %3.0i',decfacX);
  S4=sprintf('Decimation Time Step = %10.5f    Max Time = %8.3f', [tstep maxtime]);
end
SS=str2mat(' ',S1,S2,S3,S4);
disp(SS)
CaseCom=str2mat(CaseCom,SS);
S1=['Configuration file = ' CFname]; disp(S1)
CaseCom=str2mat(CaseCom,S1,' ');
%************************************************************************

%************************************************************************
disp(['In PSAMload: Size PSMsigsX = ' num2str(size(PSMsigsX))])
%************************************************************************

%************************************************************************
%Define final channel key
[chankeyX]=names2chans(namesX)
%Extend & display case documentation array
CaseCom=str2mat(CaseCom,chankeyX);
%*************************************************************************

disp('Returning from PSAMload')
disp(' ')
return

%end of PSM script

