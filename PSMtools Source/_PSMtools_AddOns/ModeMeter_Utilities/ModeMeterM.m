function [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
     chansMM,refchansMM]...
    =ModeMeterM(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansMM,TRange,tstep,decfac,...
     refchansMM,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars);
 


%
%  [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
%     chansMM,refchansMM]...
%    =ModeMeterM(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%     chansMM,TRange,tstep,decfac,...
%     refchansMM,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars);
%
% Functions called by ModeMeterM:
%    CaseTags
%    PickList1
%    ShowRange
%    promptyn, promptnv
%    ModeMeterA     J. W. Pierre at U. Wyoming
%    ModeMeterB     J. W. Pierre at U. Wyoming
%    ModeMeterC     D. Trudnowski at Montana Tech
%    (others?)  
%
% Links ModeMeter codes developed by J. W. Pierre at U. Wyoming into DSI Toolbox
% J. F. Hauer, Pacific Northwest National Laboratory.
%
% Modified 05/18/05 by jfh.  Changed some defaults
% Modified 07/12/05 by Henry Huang.  Changed some defaults
% Modified 10/17/2006 by Ning Zhou.  Add Dan's Code for ModeMeterC and add macro function
%
 


global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------
 
if 0
    keyboard
    save Debug_03
   
elseif 0
    clear all 
    close all
    clc
    load Debug_03
    funLoadMacro()
    PSMMacro.RunMode=1;  %run macro
%     PSMMacro.RunMode=0;  %record macro
%    PSMMacro.RunMode=-1; %normal orperation
 end
 
FNname='ModeMeterM'; %name for this function

disp(' ')
DFtest=~(ynprompt&nvprompt);
str='off'; if DFtest, str='on'; end
disp(['In ModeMeterM: Automatic defaults ' str]);

%Optional change to use of standard defaults
ynprompt0=ynprompt; nvprompt0=nvprompt;

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'ModeMeterM_defsok'), PSMMacro.ModeMeterM_defsok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterM_defsok))      % Not in Macro playing mode or selection not defined in a macro
    defsok=promptyn(['In ' FNname ': Use standard defaults within this function? '],'y');
else
    defsok=PSMMacro.ModeMeterM_defsok;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterM_defsok=defsok;
    else
        PSMMacro.ModeMeterM_defsok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%defsok=promptyn(['In ' FNname ': Use standard defaults within this function? '],'y');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

if defsok
  disp(['In ' FNname ': Using standard defaults for all prompt returns:'])
  ynprompt=0; nvprompt=0;
else
  disp(['In ' FNname ': Standard defaults declined'])
  ynprompt=1; nvprompt=1;
end

namesX0 =namesX;
[namesX]=BstringOut(namesX0,' ',3);
chankeyX=names2chans(namesX); 

%Clear outputs
CaseComMM=''; SaveFileMM='';
namesMM=namesX; 
TRangeMM=TRange; tstepMM=tstep;

%*************************************************************************
%Generate case identification, for stamping on plots and other outputs  


%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'ModeMeterM_setok'), PSMMacro.ModeMeterM_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterM_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn(['In ' FNname ': Generate new case tags? '],'y');
else
    setok=PSMMacro.ModeMeterM_setok;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterM_setok=setok;
    else
        PSMMacro.ModeMeterM_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% setok=promptyn(['In ' FNname ': Generate new case tags? '],'y');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if setok
  disp(['Generating new case tags for case ' caseID ':'])
  [caseID,casetime,CaseComMM,Gtags]=CaseTags(caseID);
  CaseComS=str2mat('New case tags in ModeMeterM:',CaseComMM,CaseCom);
else
  CaseComMM=CaseCom;
  Gtags=str2mat(caseID,casetime);
end
%*************************************************************************

%*************************************************************************
%Generate case/time stamp for plots
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '  casetime=' casetime];
%*************************************************************************

%*************************************************************************
%Logic for local decimation
decfac=max(fix(decfac),1);
maxpoints=size(PSMsigsX,1);
tstepMM=tstep;
deftag='n'; if decfac>1, deftag=''; end
if decfac>1
  rawdecimate=promptyn('   Decimate raw data?',deftag);
  if rawdecimate
    disp(sprintf('In ModeMeterM: Local decimation factor =%4.0i',decfac))
    setok=promptyn('   Is this decimation factor ok? ', 'y');
    if ~setok
      decfac=promptnv('   Enter new decimation factor: ',decfac);
	  decfac=max(fix(decfac),1);
    end
    PSMsigsX=PSMsigsX(1:decfac:maxpoints,:);
    maxpoints=size(PSMsigsX,1);
	tstepMM=tstep*decfac; NyquistF=1/tstepMM;
    strs=['In PSMspec1: Local decimation factor = ' num2str(decfac)];
    strs=str2mat(strs,['  Local maxpoints = ' num2str(maxpoints)]);
    strs=str2mat(strs,['  Local Nyquist   = ' num2str(NyquistF)]);
    disp(strs)
    CaseComF=str2mat(CaseComMM,strs);
	decfac=1;
  end
end
simrate=1/tstepMM;
Nyquist=0.5*simrate;
%*************************************************************************

%*************************************************************************
%Determine record time parameters
maxpoints=size(PSMsigsX,1);
nsigsX=size(PSMsigsX,2);
str=lower(namesX(1,:));
if findstr(str,'time')
  startchan=2;
  time=PSMsigsX(:,1);
  RTmin=time(1);
  RTmax=time(maxpoints);
  tstart=max(RTmin,TRange(1)); tstop=min(RTmax,TRange(2));
else
  startchan=1;
  RTmax=(size(PSMsigsX,1)-1)*tstepMM;
  time=(0:tstepMM:RTmax);
  RTmin=time(1);
  RTmax=time(maxpoints);
  tstart=RTmin; tstop=RTmax;
end
disp(sprintf('  [maxpoints nsigsX] = %6.0i %4.0i', maxpoints, nsigsX))
disp(sprintf('  Record time span   = %6.2f %6.2f', RTmin,RTmax))
%*************************************************************************

%*************************************************************************
%Check length of processing window
disp(sprintf('  Processing length  = %6.2f ',      Tbar))
if (RTmax-RTmin)<Tbar
  disp(sprintf('Processing window too long: Tbar = %6.2f ',Tbar))
  setok=promptyn('Set to data length & continue? ', 'y');
  if ~setok
    disp('In ModeMeterM: Return to invoking routine'); return
  else
    Tbar=RTmax-RTmin;
  end
end
%*************************************************************************

%*************************************************************************
%Control for removing signal offsets
disp(' ')

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'ModeMeterM_offtrend'), PSMMacro.ModeMeterM_offtrend=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterM_offtrend))      % Not in Macro playing mode or selection not defined in a macro
    offtrend=promptyn(['In ' FNname ':  Remove signal offsets? '], 'y');
else
    offtrend=PSMMacro.ModeMeterM_offtrend;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterM_offtrend=offtrend;
    else
        PSMMacro.ModeMeterM_offtrend=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% offtrend=promptyn(['In ' FNname ':  Remove signal offsets? '], 'y');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------




if offtrend
  str='In ModeMeterB: Signal offsets will be removed'; disp(str)
  CaseComMM=str2mat(CaseComMM,str);
else
  SpecTrnd=0;
end
%*************************************************************************

%*************************************************************************
%Determine signals to analyze
disp(' ')
disp(['In ' FNname ':  Select signals for ModeMeter analysis']);
FAcoms=str2mat('ModeMeter Outputs','ModeMeter Inputs'); %keyboard

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'ModeMeterM_chansMM'), PSMMacro.ModeMeterM_chansMM=[]; end
if ~isfield(PSMMacro, 'ModeMeterM_refchansMM'), PSMMacro.ModeMeterM_refchansMM=[]; end

if (PSMMacro.RunMode<1 || (isempty(PSMMacro.ModeMeterM_chansMM) && isempty(PSMMacro.ModeMeterM_refchansMM)) )      % Not in Macro playing mode or selection not defined in a macro
    % start: origin code (zn 01)
    for MM=1:2
        if MM==2
            GetInSigs=promptyn(['In ' FNname ':  Are there ModeMeter input signals? '], '');
            if ~GetInSigs, refchansMM=[]; break, end
        end
        FAcom=deblank(FAcoms(MM,:));
        disp(' ')
        disp(['Select ' FAcom ':'])
        chansA=chansMM; 
        if MM==2, chansA=refchansMM; end
        [MenuName,chansAN,chansAok]=PickSigsN(chansA,namesX,chankeyX,'',FAcom);
        if ~chansAok
            disp([' No signals selected as ' FAcom])
            chansAN=[];
        end

        if ~isempty(chansAN)
            %locsA=find(chansAN>1); chansAN=chansAN(locsA); %Assumes time axis as column 1
            nsigsA=length(chansAN);
            chansA=[];
            for N=1:nsigsA  %Avoid processing of secondary time axes
                Loc=chansAN(N);
                if isempty(findstr('time',lower(namesX(Loc,:))))
                    chansA=[chansA Loc];
                end
            end
        end
        if MM==1, chansMM=chansA; end
        if MM==2, refchansMM=chansA; end
    end
   % end: origin code (zn 01)
else
    chansMM=PSMMacro.ModeMeterM_chansMM;
    refchansMM=PSMMacro.ModeMeterM_refchansMM;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterM_chansMM=chansMM;
        PSMMacro.ModeMeterM_refchansMM=refchansMM;
    else
        PSMMacro.ModeMeterM_chansMM=[];
        PSMMacro.ModeMeterM_refchansMM=[];        
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if isempty(chansMM)
  disp(['In ' FNname ': No signals selected as ModeMeter outputs'])
  disp('Index set chansMM is empty')
  keybdok=promptyn(['In ' FNname ':  Do you want the keyboard? '], 'n');
  if keybdok
    disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    keyboard
  end
end
if isempty(chansMM)
  str=['In ' FNname ': No signals selected as ModeMeter outputs -- Return']; disp(str)
  CaseComMM=str2mat(CaseComMM,str);
  ynprompt=ynprompt0; nvprompt=nvprompt0;
  return
end
%*************************************************************************

%*************************************************************************
%Confirm signal selections
disp(' ')
strs0=str2mat('Signals selected for ModeMeter analysis:');
strs1=str2mat(FAcoms(1,:),chankeyX(chansMM,:));
strs2=str2mat(FAcoms(2,:));
if isempty(refchansMM), strs2=[strs2 ' (none)']; 
else strs2=str2mat(strs2,chankeyX(refchansMM,:));
end
strs=str2mat(strs0,strs1,strs2);
disp(strs); 

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'ModeMeterM_keybdok'), PSMMacro.ModeMeterM_keybdok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterM_keybdok))      % Not in Macro playing mode or selection not defined in a macro
    keybdok=promptyn('Do you want to change these selections? ', '');
else
    keybdok=PSMMacro.ModeMeterM_keybdok;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterM_keybdok=keybdok;
    else
        PSMMacro.ModeMeterM_keybdok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% keybdok=promptyn('Do you want to change these selections? ', '');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------



if keybdok
    disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
    disp(['chansMM   =[' num2str(chansMM) '];'])
    disp(['refchansMM=[' num2str(refchansMM) '];'])
    keyboard
end
CaseComMM=str2mat(CaseComMM,strs);
%*************************************************************************

%*************************************************************************
%Verify time range for processing
%keyboard;
tmin=PSMsigsX(1,1); tmax=PSMsigsX(maxpoints,1);
disp(sprintf('In %s : Max TRange = [ %6.2f %6.2f ]', FNname, tmin,tmax))
%----------------------------------------------------
% Begin: Macro selection ZN 08/01/2007
%keyboard;
if ~isfield(PSMMacro, 'ModeMeterM_TimeRangeOK'), PSMMacro.ModeMeterM_TimeRangeOK=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterM_TimeRangeOK))      % Not in Macro playing mode or selection not defined in a macro
    TimeRangeOK=promptyn(['In ' FNname ': Use this Max TRange ? '],'y');
else
    TimeRangeOK=PSMMacro.ModeMeterM_TimeRangeOK;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterM_TimeRangeOK=TimeRangeOK;
    else
        PSMMacro.ModeMeterM_TimeRangeOK=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end

if  TimeRangeOK
    TRangeok=1;     %PSMMacro.ModeMeterM_TRangeok;
    TRangeMM=[tmin,tmax];
    nrangeN=[round((TRangeMM(1)-tmin)/tstep+1),...
             round(min((TRangeMM(2)-tmin)/tstep+1,maxpoints))];
    nranges=nrangeN.'; %keyboard     
else
    
%end
% End: Macro selection ZN 08/01/2007
%----------------------------------------------------

    disp(' ')
    nranges=[]; %keyboard
    disp(['In ' FNname ':  Define time range for up to 10 processing segments'])
    for Nexp=1:10
      disp(' ')
      disp(['Define time range for processing segment ' num2str(Nexp) ':'])
      DispSig=chansMM(1); maxtrys=10;

        %----------------------------------------------------
        % Begin: Macro selection ZN 10/18/06
        if ~isfield(PSMMacro, 'ModeMeterM_TRangeok'), PSMMacro.ModeMeterM_TRangeok=NaN; end
        if ~isfield(PSMMacro, 'ModeMeterM_nrangeN'), PSMMacro.ModeMeterM_nrangeN=NaN; end
        if ~isfield(PSMMacro, 'ModeMeterM_TRangeMM'), PSMMacro.ModeMeterM_TRangeMM=NaN; end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterM_TRangeok))      % Not in Macro playing mode or selection not defined in a macro
              [TRangeMM,nrangeN,TRangeok]=ShowRange(PSMsigsX,namesX,DispSig,...
                    [tstart tstop],tstepMM,maxtrys);
        else
            %keyboard;
            TRangeok=PSMMacro.ModeMeterM_TRangeok;
            nrangeN=PSMMacro.ModeMeterM_nrangeN;
            TRangeMM=PSMMacro.ModeMeterM_TRangeMM;
            tmin=PSMsigsX(1,1); tmax=PSMsigsX(maxpoints,1);
            %---------------------------------
            % Begin: modified by ZN 7/25/07
            if TRangeMM(1)<tmin 
                TRangeMM(1)=tmin; 
                nrangeN(1)=round((TRangeMM(1)-tmin)/tstep+1);
            end
            if TRangeMM(2)>tmax 
                TRangeMM(2)=tmax; 
                nrangeN(2)=round(min((TRangeMM(2)-tmin)/tstep+1,maxpoints));
            end
            % End: modified by ZN 7/25/07
            %---------------------------------
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.ModeMeterM_TRangeok=TRangeok;
                PSMMacro.ModeMeterM_nrangeN=nrangeN;
                PSMMacro.ModeMeterM_TRangeMM=TRangeMM;
            else
                PSMMacro.ModeMeterM_TRangeok=NaN;
                PSMMacro.ModeMeterM_nrangeN=NaN;
                PSMMacro.ModeMeterM_TRangeMM=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
        % End: Macro selection ZN 10/18/06
        %----------------------------------------------------



      if ~TRangeok, break, end
      nranges=[nranges nrangeN'];
      %breakok=~promptyn(['Define time range for another processing segment?
      %%'], ''); % disable another time range selection. there is only one
      %%segment for now. but it can be expanded multiple segments. Henry 07/12/05
      breakok=1;        
      if breakok, break, end
    end
    nranges=nranges';
    if isempty(nranges)
      strs=['In ' FNname ': No time ranges defined--Returning to invoking Matlab function'];
      ynprompt=ynprompt0; nvprompt=nvprompt0;
      return
    else
      Nexps=size(nranges,1);
      disp(' ')
      disp(['In ' FNname ': Time ranges defined for ' num2str(Nexps) ' processing segments'])
    end
    for N=1:Nexps
      disp(['Limits for processing segment ' num2str(N) ':'])
      disp(['  Time  range = [' num2str(time(nranges(N,:))') ']'])
      disp(['  Index range = [' num2str(nranges(N,:)) ']'])
    end
    if 1
      disp('Present code supports just one processing segment, but that will change.  jfh')
      nranges=nranges(1,:);  %Experiement 1 only
    end
    %*************************************************************************
end     %  if  TimeRangeOK (added 08/01/2007 by ZN)

%*************************************************************************
if (PSMMacro.RunMode<1)
    disp(' ')
    keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '], 'n');
    if keybdok
      disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
    end
end
%*************************************************************************

%************************************************************************
%Menu of ModeMeter Processing Types
 MMNos=[1];        MMtypes='ModeMeterA';
 MMNos=[MMNos 2];  MMtypes=str2mat(MMtypes,'ModeMeterB');
 MMNos=[MMNos 3];  MMtypes=str2mat(MMtypes,'ModeMeterC (Dan YW Code)');
 MMNos=[MMNos 4];  MMtypes=str2mat(MMtypes,'ModeMeterC (Dan YWSpectrum Code)');
 MMNos=[MMNos 5];  MMtypes=str2mat(MMtypes,'ModeMeterC (Dan N4SID Code)');
%MMNos=[MMNos 97]; MMtypes=str2mat(MMtypes,'Keyboard');
%MMNos=[MMNos 98]; MMtypes=str2mat(MMtypes,'Defaults on/off');
%MMNos=[MMNos 99]; MMtypes=str2mat(MMtypes,'end case');
%************************************************************************


%======================START OF MODEMETER PROCESSING LOOP================
MMpass=0;
while 1   %Start of WHILE loop for ModeMeter operations
MMpass=MMpass+1;

%************************************************************************
%Select ModeMeter processing type
NMMTypes=size(MMtypes,1);
disp('Select ModeMeter processing type: Options are')
for N=1:NMMTypes
  disp([sprintf('   %2.0i  ',MMNos(N)) MMtypes(N,:)]); 
end
disp(' ');
prompt=['  Indicate ModeMeter processing type - enter number from list above'];

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
% keyboard;
if ~isfield(PSMMacro, 'ModeMeterM_OpTypeN'), PSMMacro.ModeMeterM_OpTypeN=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterM_OpTypeN))      % Not in Macro playing mode or selection not defined in a macro
    OpTypeN=promptnv(prompt,[3]);
else
    OpTypeN=PSMMacro.ModeMeterM_OpTypeN;
end
    
if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.ModeMeterM_OpTypeN=OpTypeN;
    else
        PSMMacro.ModeMeterM_OpTypeN=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% OpTypeN=promptnv(prompt,[3]);
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if isempty(OpTypeN),OpTypeN=0; end 
OpLoc=find(OpTypeN==MMNos);
if isempty(OpLoc)
  disp(['    Selected ModeMeter processing type ' num2str(OpTypeN) ' is not valid'])
  OpLoc=1; 
end
OpTypeN=MMNos(OpLoc);
Data_Op=deblank(MMtypes(OpLoc,:));
disp(['   Indicated ModeMeter processing type = ' num2str(OpTypeN) ': ' MMtypes(OpLoc,:)])
%************************************************************************
%keyboard;

Data_Op=deblank(Data_Op);

%************************************************************************
if ~isempty(findstr('ModeMeterA',Data_Op))
  disp(' ')
  prompt=['In ' FNname ': Execute ModeMeterA? '];
     %----------------------------------------------------
    % Begin: Macro selection ZN 02/12/07
    % keyboard;
    if ~isfield(PSMMacro, 'ModeMeterM_setok04'), PSMMacro.ModeMeterM_setok04=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterM_setok04))      % Not in Macro playing mode or selection not defined in a macro
        setok=promptyn(prompt,'y');
    else
        setok=PSMMacro.ModeMeterM_setok04;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.ModeMeterM_setok04=setok;
        else
            PSMMacro.ModeMeterM_setok04=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % setok=promptyn(prompt,'y');
    % End: Macro selection ZN 02/12/07
    %----------------------------------------------------
  if ~setok, disp('Proceeding to next processing phase'), break, end
  clear functions
  locsA=[chansMM refchansMM];
  SigNames=namesX(locsA,:);
  locs=nranges(1):nranges(2);
  try
    [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
      spoles,zpoles]...
     =ModeMeterA(caseID,casetime,CaseCom,SigNames,PSMsigsX(locs,:),...
      chansMM,TRange,tstepMM,decfac,...
      refchansMM,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars);
  catch
    strs=[' ','In ' FNname ': ERROR ENCOUNTERED IN ModeMeterA',' '];
    CaseComMM=str2mat(CaseComMM,strs);
    disp(strs)
    disp(' Processing is paused - press any key to continue')
    pause
  end  
  break
end
%************************************************************************

%************************************************************************
if ~isempty(findstr('ModeMeterB',Data_Op))
  disp(' ')
  prompt=['In ' FNname ': Execute ModeMeterB? '];
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/12/07
    % keyboard;
    if ~isfield(PSMMacro, 'ModeMeterM_setok03'), PSMMacro.ModeMeterM_setok03=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterM_setok03))      % Not in Macro playing mode or selection not defined in a macro
        setok=promptyn(prompt,'y');
    else
        setok=PSMMacro.ModeMeterM_setok03;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.ModeMeterM_setok03=setok;
        else
            PSMMacro.ModeMeterM_setok03=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % setok=promptyn(prompt,'y');
    % End: Macro selection ZN 02/12/07
    %----------------------------------------------------
   if ~setok, disp('Proceeding to next processing phase'), break, end
   
  clear functions
  locsA=[chansMM refchansMM];
  SigNames=namesX(locsA,:);
  locs=nranges(1):nranges(2);
  try
    [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
      spoles,zpoles]...
     =ModeMeterB(caseID,casetime,CaseCom,SigNames,PSMsigsX(locs,:),...
      chansMM,TRange,tstepMM,decfac,...
      refchansMM,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars);
  catch
    strs=[' ','In ' FNname ': ERROR ENCOUNTERED IN ModeMeterB',' '];
    CaseComMM=str2mat(CaseComMM,strs);
    disp(strs)
    disp(' Processing is paused - press any key to continue')
    pause
  end    
  break
end
%************************************************************************


%************************************************************************
if ~isempty(findstr('ModeMeterC',Data_Op))
  disp(' ')
  prompt=['In ' FNname ': Execute ModeMeterC? '];
  
    %----------------------------------------------------
    % Begin: Macro selection ZN 02/12/07
    % keyboard;
    if ~isfield(PSMMacro, 'ModeMeterM_setok02'), PSMMacro.ModeMeterM_setok02=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.ModeMeterM_setok02))      % Not in Macro playing mode or selection not defined in a macro
        setok=promptyn(prompt,'y');
    else
        setok=PSMMacro.ModeMeterM_setok02;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.ModeMeterM_setok02=setok;
        else
            PSMMacro.ModeMeterM_setok02=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % setok=promptyn(prompt,'y');
    % End: Macro selection ZN 02/12/07
    %----------------------------------------------------
    if ~setok, disp('Proceeding to next processing phase'), break, end
  
  
  clear functions
  locsA=[chansMM refchansMM];
  SigNames=namesX(locsA,:);
  locs=nranges(1):nranges(2);

  if ~isempty(findstr('N4SID',Data_Op))
      AlgIndex=3;
  elseif ~isempty(findstr('YWS',Data_Op))
      AlgIndex=2;
  elseif ~isempty(findstr('YW',Data_Op))
      AlgIndex=1;
  else
      AlgIndex=NaN;
  end

  
  try
    [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
      spoles,zpoles]...
     =ModeMeterC(caseID,casetime,CaseCom,SigNames,PSMsigsX(locs,:),...
      chansMM,TRangeMM,tstepMM,decfac,...
      refchansMM,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars,AlgIndex, namesX);
  catch
    strs=[' ','In ' FNname ': ERROR ENCOUNTERED IN ModeMeterC',' '];
    CaseComMM=str2mat(CaseComMM,strs);
    disp(strs)
    disp(' Processing is paused - press any key to continue')
    pause
  end    
  break
end
%************************************************************************

end
%========================END OF MODEMETER PROCESSING LOOP================

disp(' ')
disp(['In ' FNname ': PROCESSING COMPLETE'])
if (PSMMacro.RunMode<1)      % Not in Macro playing mode or selection not defined in a macro
    keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '], 'n');
    if keybdok
      disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
      keyboard
    end
elseif PSMMacro.RunMode==1
    disp(' Processing is paused - press any key to continue')
    pause;
end

disp(['Return from ' FNname]); disp(' ')
ynprompt=ynprompt0; nvprompt=nvprompt0;

%end of ModeMeter function