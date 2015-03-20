function [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
     spoles,zpoles]...
    =ModeMeterB(caseID,casetime,CaseCom,namesX,PSMsigsX,...
     chansAout,TRange,tstepMM,decfac,...
     chansAin,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars);
%
%  [CaseComMM,SaveFileMM,namesMM,TRangeMM,tstepMM,...
%    spoles,zpoles]...
%   =ModeMeterA(caseID,casetime,CaseCom,namesX,PSMsigsX,...
%    chansAout,TRange,tstep,decfac,...
%    chansAin,SpecTrnd,WinType,Tbar,lap,Frange,decfrq,MMpars);
%
% Functions called by ModeMeterB:
%    funL1Subspace
%    promptyn, promptnv
%    (others?)  
%
% Core code developed by J. W. Pierre at U. Wyoming
% Integration into PSM_Tools by J. F. Hauer, 
% Pacific Northwest National Laboratory.
%
% Modified 05/27/04.  jfh

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

FNname='ModeMeterB';

disp(' ')
disp(['In ' FNname ': EXPERIMENTAL CODE'])

chankeyX=names2chans(namesX); 

%Clear outputs
CaseComMM=''; SaveFileMM='';
namesMM=namesX; TRangeMM=TRange;
spoles=[]; zpoles=[];

%*************************************************************************
%Set parameters for ModeMeter analysis [old code]
disp(' ')
disp('In ModeMeterB: Parameters for ModeMeter processing')
%[put display here]
%*************************************************************************

%*************************************************************************
%Setup using JP template
Ts=tstepMM;                             % sampling rate in seconds
NumExp=1;                               % number of estimation experiments in identification.
locs=1:size(PSMsigsX,1);
u1=[]; y1=[];
if ~isempty(chansAin)
  u1=PSMsigsX(locs,chansAin );          % Experiment 1, input 
end
y1=PSMsigsX(locs,chansAout);            % Experiment 1, output
 NumValidExp=1;                         % number of estimation experiments in identification.
%NumValidExp=-1;                        % if there is no validation data set 'NumValidExp' to -1
uV1=PSMsigsX(locs,chansAin );           % Validation Experiment 1, input
yV1=PSMsigsX(locs,chansAout);           % Validation Experiment 1, output.
Order=[];                               % order of state space model
NumMajorModes=[0.26; 0.38; 0.6];        % major modes if known ahead (Hz)
DeciFactor=[];                          % decimation factor if known ahead
%Order=16;                              % order of state space model
%NumMajorModes=[];                      % major modes if known ahead
%DeciFactor=6;                          % decimation factor if known ahead
%prepare model estimation data
MyInput =cell(NumExp,1);
MyOutput=cell(NumExp,1);
NumExpUW=round(NumExp);
for nIndexUW=1:NumExpUW
  MyInput{nIndexUW} =eval(['u' int2str(nIndexUW)]);
  MyOutput{nIndexUW}=eval(['y' int2str(nIndexUW)]);
end
%prepare model validation data
MyValidInput=[]; MyValidOutput=[];
if NumValidExp>0
  MyValidInput =cell(NumValidExp,1);
  MyValidOutput=cell(NumValidExp,1);
  for nIndexUW=1:NumValidExp
    MyValidInput{nIndexUW} =eval(['uV' int2str(nIndexUW)]);
    MyValidOutput{nIndexUW}=eval(['yV' int2str(nIndexUW)]);
  end
end
%*************************************************************************

%*************************************************************************
%Using logic from TestSubspace2
SelectionCtrl=1;
switch SelectionCtrl
  case 1 
    [Model,MajorFreq,MajorDR]=funL1Subspace(caseID,casetime,CaseCom,namesX,MyOutput,MyInput,Ts);
  case 2
    [Model,MajorFreq,MajorDR]=funL1Subspace(caseID,casetime,CaseCom,namesX,MyOutput,MyInput,Ts,...
      Order,NumMajorModes,DeciFactor);
  case 3
    [Model,MajorFreq,MajorDR]=funL1Subspace(caseID,casetime,CaseCom,namesX,MyOutput,MyInput,Ts,...
      [],[],[],MyValidOutput,MyValidInput);
  otherwise
    disp(['In ' FNname ': No processing selected'])
end
%*************************************************************************

disp(' ')
disp(['In ' FNname ': PROCESSING COMPLETE'])
keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '],'n');
if keybdok
  disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end

disp(['Return from ' FNname]); disp(' ')

%end of ModeMeter function