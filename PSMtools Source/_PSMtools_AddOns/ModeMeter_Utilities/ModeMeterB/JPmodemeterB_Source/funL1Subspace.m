function [MyModelUW,Freq,DR]=funL1Subspace(caseID,casetime,CaseCom,namesX,MyOutput,MyInput,Ts,...
           Order,NumMajorModes,DeciFactor,MyValidOutput,MyValidInput);
% [MyModelUW,Freq,DR]=funL1Subspace(caseID,casetime,CaseCom,namesX,MyOutput,MyInput,Ts,...
%    Order,NumMajorModes,DeciFactor,MyValidOutput,MyValidInput);
% Input parameters:  
%   MyOutput: Cell array containing output data for model estimation
%   MyInput:  Cell array containing input data for model estimation 
%             [] indicates the ambient data analysis
%   Ts:             Sampling Interval (in seconds).       
%   Order:          Selected order of state space model
%   NumMajorModes:  # of the major modes of state space model
%   DeciFactor:     Decimation factor (to decrease the sampling rate)
%   MyValidOutput:  Cell array containing validation output
%   MyValidInput:   Cell array containing validation input

% Output parameters:
%   MyModel: The identified state space model       
%   Freq:    Frequencies of major modes in "Hz".   
%   DR:      Damping Ratios of major modes in 'percentage'
%
% Special functions called from funL1Subspace:
%   detrend
%   funDecimate
%   merge
%   n4sid
%   funFindPoles
%   funFindModes
%   compare
%   
%***************************************************************************
% Core code developed by J. W. Pierre at U. Wyoming
%
% Modified 05/27/04   jfh    Displays to track processing
% Modified 08/17/04   Ning   Display changed to MRAWs

global Kprompt ynprompt nvprompt
global PSMtype CFname PSMfiles PSMreftimes

FNname='funL1Subspace';  %name for this function

disp(' ')
disp(['In JPmodeMeter function ' FNname ':'])
disp(' ')

% 1.0 Check the arguments
if (nargin < 7); error('Subspace analysis needs at least 7 arguments'); end
if (nargin < 8); Order=[];        end
if (nargin < 9); NumMajorModes=[];end
if (nargin <10); DeciFactor=[];   end
if (nargin <11); MyValidOutput=[];end
if (nargin <12); MyValidInput=[]; end
disp('Begin Subspace Analysis for Power System Data......')
disp(' ')

disp('------------------------------------------------------------------------------------')
disp('1. Data preprocess');
disp(' ');
% 1.1 Check the arrangement of u and y
NumExp=length(MyOutput);
MinN=inf;                   % minimun data length
for eIndex=1:NumExp
    [tempN,tempL]=size(MyInput{eIndex});
    nu=min([tempN,tempL]);  % number of channels of input
    if tempN<tempL
        MyInput{eIndex}=MyInput{eIndex}.';
    end
    [tempN,tempL]=size(MyOutput{eIndex});
    ny=min([tempN,tempL]);  % number of channels of output
    MinN=min([MinN,max([tempN,tempL])]);
    if tempN<tempL
      MyOutput{eIndex}=MyOutput{eIndex}.';
    end
end

% 1.2 Form the data structure and data preprocess
if length(DeciFactor)==0
    DeciFactorUW=funNewSamplingRate(Ts);
else
    DeciFactorUW=DeciFactor;
end

MinN=floor(MinN/DeciFactorUW);
MyDataUW=detrend(iddata(MyOutput{1},MyInput{1},Ts),'constant');
MyDataUW=funDecimate(MyDataUW,DeciFactorUW);

if NumExp>1
    for nIndexUW=2:NumExp
        MyAddDataUW=detrend(iddata(MyOutput{nIndexUW},MyInput{nIndexUW},Ts),'constant');
        MyAddDataUW=funDecimate(MyAddDataUW,DeciFactorUW);
        MyDataUW=merge(MyDataUW,MyAddDataUW);
    end
end

%1.3 IdentifiedModel
if NumExp>1       
    AmbientUW=isempty(MyDataUW.u{1});   % multiple experiments
else
    AmbientUW=isempty(MyDataUW.u);      % single experiments
end

disp('------------------------------------------------------------------------------------')
disp('2. Model identification (Please wait....)');
disp('  ');
for MaxOrder=4:30
    if MinN<=(ceil(MaxOrder/ny)+1)*(1+ny+nu)+(1+nu+ny)*ceil((MaxOrder-ny+1)/(nu+ny))
       MaxOrder=MaxOrder-2;
       break;
    end
end
%MaxOrder;
    
if AmbientUW
  disp(['In ' FNname ': Calling N4SID for ambient data analysis:'])
  if length(Order)==0     % default selection
    MyModelUW=n4sid(MyDataUW,[1:MaxOrder]); % ambient data analysis
  else
    MyModelUW=n4sid(MyDataUW,Order);        % ambient data analysis
  end
else
  disp(['In ' FNname ': Calling N4SID for noise injection analysis:'])
  if length(Order)==0     % default selection
    MyModelUW=n4sid(MyDataUW,[1:MaxOrder],'Focus','Sim'); % noise injection analysis
  else
    MyModelUW=n4sid(MyDataUW,Order,'Focus','Sim');        % noise injection analysis
  end
end

%1.4 Find the major modes
disp(' ')
disp(['########## In ' FNname ': Summary results display for N4SID Models ##########']) 
[sPolesUW,sMajorPolesUW,MREDz]=funFindPoles(MyModelUW,NumMajorModes);
[Freq, DR]=funFindModes(sMajorPolesUW);
funFindModes(sMajorPolesUW);

%*********************** Start of jfh display logic ************************
%Start of jfh display logic
disp(' ')
disp(['########## In ' FNname ': Detailed results display for N4SID Models ##########']) 
%keyboard
MRAWs=d2c(MyModelUW,'tustin');
MREDs=d2c(MREDz,'tustin');
for NModel=1:2
  if NModel==1
    ModelName='N4SID Raw Model ';
    [A,B,C,D]=ssdata(MRAWs);
  else
    ModelName='N4SID Reduced Model ';
    [A,B,C,D]=ssdata(MREDs);
  end
  %Assuming just one input -- install test later
  [Noutsigs Nstates]=size(C);
  Ninsigs=size(B,2);
  if Ninsigs<1
    disp(['In ' FNname ': NO INPUTS TO THIS MODEL -- zeros not determined'])
  end
  BDcols=max(Ninsigs,1);
  if isempty(B), B=zeros(Nstates,BDcols);  end
  if isempty(D), D=zeros(Noutsigs,BDcols); end
  disp(' ')
  disp(['********** ' ModelName ' **********']); %keyboard 
  [NUMS,DEN]=ss2tf(A,B,C,D,1);
  NCHANS=min(size(NUMS));
  InSigName='(none)';
  if size(namesX,1)>NCHANS, InSigName=namesX(NCHANS+1,:); end
  for NCHAN=1:NCHANS  %Start of main display loop
    NUM=NUMS(NCHAN,:);
    disp(' '); 
    CHstr=['Chan ' num2str(NCHAN)];
    MCstr=[ModelName CHstr];
    disp(['In ' FNname ': Results for ' MCstr])
    OutSigName=namesX(NCHAN,:);
    disp(['   Output signal = ' OutSigName]);
    disp(['   Input signal  = ' InSigName]);
    disp(['In ' FNname ': ' CHstr ' Sorted mode table for ' MCstr])
    [R,P,K]  =residue(NUM,DEN); if isempty(K), K=0; end
    %ModelRes=R; ModelPoles=P; ModelThru=K;
    SortType=1; SortTrack=0; DispType=1;
    [Poles,SortType,RootCatsP,PoleCatNames,PoleLocs]=...
      RootSort1(roots(DEN),SortType,SortTrack);
    SortType=1; SortTrack=0; DispType=1;
    [Zeros,SortType,RootCatsZ,ZeroCatNames,ZeroLocs]=...
      RootSort1(roots(NUM),SortType,SortTrack);
    [CaseCom]=ModeDisp1(caseID,casetime,CaseCom,MCstr,...
      Poles,Zeros,DispType,RootCatsP,PoleCatNames);
    if ~isempty(find(real(Zeros)>0))
      disp('Nonminimum-Phase Zeros: '); %disp(Zeros)
    end
  end
end

%***************************************************************************
%ModeShape plots for selected model (reduced model assumed for now)
disp(' ')
MSplots=promptyn(['In ' FNname ': Do ModeShape plots for N4SID Model? '], '');
if MSplots
  disp(['In ' FNname ': Using N4SID Reduced Model'])
  %[A,B,C,D]=ssdata(MREDs);    
   [A,B,C,D]=ssdata(MRAWs);    
  [Noutsigs Nstates]=size(C);
  Ninsigs=size(B,2);
  if Ninsigs<1
    disp(['In ' FNname ': NO INPUTS TO THIS MODEL -- Setting B=I as temporary expedient'])
    disp(['In ' FNname ': Processing paused - press any key to resume'])
    pause
  end
  BDcols=max(Ninsigs,1);
  if isempty(B), B=ones(Nstates,BDcols);   end
  if isempty(D), D=zeros(Noutsigs,BDcols); end
  [NUMS,DEN]=ss2tf(A,B,C,D,1);
  nfits=min(size(NUMS));
  %Order all Poles by ascending frequency, with real poles first
  Tres=[]; Poles=[];
  for N=1:nfits
    NUM=NUMS(N,:);
    [R,P,K]=residue(NUM,DEN); if isempty(K), K=0; end
    SortType=1; SortTrack=(N==1);
    [PolesP,SortType,PoleCats,PoleCatNames,locsS0]=...
      RootSort1(P,SortType,SortTrack);
    Poles=[Poles PolesP];
    Tres =[Tres  R(locsS0)];
  end
  SigNames=namesX;
  Ptitle{1}=' ';
  Ptitle{2}=['caseID=' caseID '    casetime=' casetime];
  %keyboard
  CompassPlotsA
end
%***************************************************************************


%***************************************************************************
keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '], 'n');
if keybdok
  disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end
%***************************************************************************

%************************ End of jfh display logic *************************

disp(['In ' FNname ': Processing paused - press any key to resume']);
pause

disp(' ')
disp(['In ' FNname ': Proceeding with model validation displays'])
%1.5 Validation
NumValidExp=length(MyValidOutput);
if NumValidExp==0     % no validataion data set provided
   disp(' ');
   disp('------------------------------------------------------------------------------------')
   disp('3.0 Model Validation is performed on estimation data')
   disp(' ');
   disp('Please see figure-1 for validation result......')
   disp('(press "Return" key to continue)');
   disp(' ');
   figure;
   compare( MyModelUW,MyDataUW,1);  % use the estimation data to evaluate the model
else                    % if validataion data set is provided
   disp(' ');
   disp('------------------------------------------------------------------------------------')
   disp('3.0 Model Validation is performed on validation data')
   disp(' ');
   % check validation data format
   for eIndex=1:NumValidExp
     [tempN,tempL]=size(MyValidInput{eIndex});
     if tempN<tempL
       MyValidInput{eIndex}=MyValidInput{eIndex}.';
     end
     [tempN,tempL]=size(MyValidOutput{eIndex});
     if tempN<tempL
       MyValidOutput{eIndex}=MyValidOutput{eIndex}.';
     end
   end
%   preprocess validation data (detrend, decimation)
    MyValidData=detrend(iddata(MyValidOutput{1},MyValidInput{1},Ts),'constant');
%   MyValidData=detrend(iddata(MyValidOutput{1},MyValidInput{1},Ts),'linear');
    MyValidData=funDecimate(MyValidData,DeciFactorUW);

    if NumValidExp>1
        for nIndexUW=2:NumValidExp
            MyAddData=detrend(iddata(MyValidOutput{nIndexUW},MyValidInput{nIndexUW},Ts),'constant');
            MyAddData=funDecimate(MyAddData,DeciFactorUW);
            MyValidData=merge(MyValidData,MyAddData);
        end
    end
    disp('Please see figure(s) for validation result......')
    disp('(press "Return" key to continue)');
    disp(' ');
    figure;
    compare(MyModelUW,MyValidData,1);
end
disp('(press "Return" key to continue)');
pause

disp(' ')
disp(['In ' FNname ': PROCESSING COMPLETE'])
keybdok=promptyn(['In ' FNname ': Do you want the keyboard? '], 'n');
if keybdok
  disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end
disp(' ')

