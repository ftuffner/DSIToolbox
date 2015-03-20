% JPmodeMeter Case Script TestSubspace2.m
% Menu of prepared examples on use of subspace method with power system data
%****************************************************************
% This code contains 9 examples on how to use the subspace method
% on Power data. It is beneficial to first time users to run it 
% to get a big picture about the power of subspace analysis.
%
% Users who need to have their own data processed are encouraged to 
% use another program called 'TestSubspace2.m' as a template. Modify
% its code to their owen application
%
% Ning Zhou. 04/23/2004
%
% Modified 05/17/04  jfh  Logic to track processing, compare against
%                         DSItools

%**********************************************************
% 1.0 Prepare data.
% Following variables must be provided for subspace analysis.
% Variables are: 
%       Ts:     sampling rate in seconds
%       NumExp: a positive integer indicating the number of input.
%       u1:     input matrix, each column of u1 contains a channel of an
%               input for first experiment
%       y1:     output matrix, each column of y1 contains a channel of an
%               input for first experiment
%
%       u2:     input matrix, each column of u2 contains a channel of an
%               input for second experiment
%       y2:     output matrix, each column of y2 contains a channel of an
%               input for second experiment

clear all
close all
%clc

%Set name for this case script
CSname='TestSubspace2';

disp(' ')
disp(['In JPmodeMeter Script ' CSname ':'])
disp('Menu of prepared examples on use of subspace method with power system data')
disp(' ')

SelectionCtrl=1;
while SelectionCtrl~=0
    close all
    disp('*********************************************************');
    disp('*  Learn to use subspace method over power data *');
    disp('*********************************************************');
    disp(' ');
    disp('1. 2000 Noise injection 10min 10MW experiment');
    disp('2. 2000 Noise injection 10 min 10MW experiment and 5 min 20MW experiment');
    disp('3. 2000 4 experiments of Impulse injection');
    disp('4. 2000 ambient test with basic parameter        (Multi-Output)');
    disp('5. 2000 Noise injection 10 min 10MW and 5 min 20MW experiment and all parameter selected (with known major modes number)');
    disp('6. 2000 Noise injection 10 min 10MW and 5 min 20MW experiment and all parameter selected (with known major modes freq)');
    disp('7. 2000 Noise injection 10 min 10MW experiment and 5 min 20MW experiment and validated with 4 experiments of Impulse injection');
    disp('8. 2003 Impulse Test Example')
    disp('9. 2003 Ambient Test Example');
    disp('10. Quit');
    disp('---------------------');
    
    YourChoice=input('Please select one experiment to perform [1-10]: ');
    if length(YourChoice)==0
       YourChoice=100;
    end
    
    strs0=str2mat('Signals for ModeMeter analysis:');
    FAcoms=str2mat('ModeMeter Outputs','ModeMeter Inputs');

    NumValidExp=-1;
    switch YourChoice
        case 1
            PSMfileN='datNoiseExampleData.mat';
            disp(['Loading data file ' PSMfileN])
            pfname=['''' [PSMfileN] '''']; eval(['load '  pfname])
            if ~exist('CaseComR'), CaseComR='[CaseComR Empty]'; end 
            Lines=min(size(CaseComR,1),6);
            disp(CaseComR(1:Lines,:))
            Ts=(PSMsigsX(2,1)-PSMsigsX(1,1));       % sampling rate in seconds
            NumExp=1;                               % number of experiments in identification.
            chansMM   =[2 3];         
            refchansMM=[9];
            nrange=[1 18000];
            locs=nrange(1):nrange(2);
            u1=PSMsigsX(locs,refchansMM);           % Experiment 1, input 
            y1=PSMsigsX(locs,chansMM);              % Experiment 1, output
            strs1=str2mat(FAcoms(1,:),chankeyX(chansMM,:));
            strs2=str2mat(FAcoms(2,:),chankeyX(refchansMM, :));
            RTstart=PSMsigsX(nrange(1),1); RTstop =PSMsigsX(nrange(2),1);
            disp(' ')
            disp(sprintf('Time span   = %6.2f %6.2f', RTstart,RTstop))
            disp(str2mat(strs0,strs1,strs2));
            SelectionCtrl=1;
            
        case 2
            load datNoiseExampleData.mat
            Ts=(PSMsigsX(2,1)-PSMsigsX(1,1));       % sampling rate in seconds
            NumExp=2;                               % number of experiments in identification.
            u1=PSMsigsX(1:18000,9);                 % Experiment 1, input 
            y1=PSMsigsX(1:18000,[2,3]);             % Experiment 1, output
            
            u2=PSMsigsX(19790:28820,9);             % Experiment 2, input
            y2=PSMsigsX(19790:28820,[2,3]);         % Experiment 2, output.
            
            SelectionCtrl=1;
        case 3
            PSMfileN='datModeProbesRingDown.mat';
            disp(['Loading data file ' PSMfileN])
            pfname=['''' [PSMfileN] '''']; eval(['load '  pfname])
            if ~exist('CaseComR'), CaseComR='[CaseComR Empty]'; end 
            Lines=min(size(CaseComR,1),6);
            disp(CaseComR(1:Lines,:))            
            Ts=(PSMsigsX(2,1)-PSMsigsX(1,1));       % sampling rate in seconds
            NumExp=4;                               % number of experiments in identification.
            u1=PSMsigsX(1852:2800,9);               % Experiment 1, input 
            y1=PSMsigsX(1852:2800,[2,3]);           % Experiment 1, output
            
            u2=PSMsigsX(5449:6200,9);               % Experiment 2, input
            y2=PSMsigsX(5449:6200,[2,3]);           % Experiment 2, output.
            
            u3=PSMsigsX(9020:9600,9);                 % Experiment 1, input 
            y3=PSMsigsX(9020:9600,[2,3]);             % Experiment 1, output
            
            u4=PSMsigsX(14436:15300,9);             % Experiment 2, input
            y4=PSMsigsX(14436:15300,[2,3]);        % Experiment 2, output.
            
            SelectionCtrl=1;          
            
        case 4
            % for ambient test
            PSMfileN='dataAmbientExampleData.mat';
            disp(['Loading data file ' PSMfileN])
            pfname=['''' [PSMfileN] '''']; eval(['load '  pfname])
            if ~exist('CaseComR'), CaseComR='[CaseComR Empty]'; end 
            Lines=min(size(CaseComR,1),6);
            disp(CaseComR(1:Lines,:))            
            Ts=(PSMsigsX(2,1)-PSMsigsX(1,1));       % sampling rate in seconds
            NumExp=1;                               % number of experiments in identification.
            u1=[];                                  % Experiment 1, No input for ambient data
            y1=PSMsigsX(:,[2,3]);                   % Experiment 1, output
            SelectionCtrl=1;
            
        case 5
            load datNoiseExampleData.mat
            Ts=(PSMsigsX(2,1)-PSMsigsX(1,1));       % sampling rate in seconds
            NumExp=2;                               % number of experiments in identification.
            u1=PSMsigsX(1:18000,9);                 % Experiment 1, input 
            y1=PSMsigsX(1:18000,[2,3]);             % Experiment 1, output
            
            u2=PSMsigsX(19790:28820,9);             % Experiment 2, input
            y2=PSMsigsX(19790:28820,[2,3]);         % Experiment 2, output.
            
            Order=23;
            NumMajorModes=5;
            DeciFactor=6;
            
            SelectionCtrl=2;
 
        case 6
            load datNoiseExampleData.mat
            Ts=(PSMsigsX(2,1)-PSMsigsX(1,1));       % sampling rate in seconds
            NumExp=2;                               % number of experiments in identification.
            u1=PSMsigsX(1:18000,9);                 % Experiment 1, input 
            y1=PSMsigsX(1:18000,[2,3]);             % Experiment 1, output
            
            u2=PSMsigsX(19790:28820,9);             % Experiment 2, input
            y2=PSMsigsX(19790:28820,[2,3]);        % Experiment 2, output.
            
            Order=23;                           % a proper model order known by users
            NumMajorModes=[0.39; 0.26; 0.63];   % major modes in Hz
            DeciFactor=6;                       % a proper decimation factor known by users
            
            SelectionCtrl=2;
            
         case 7
            % prepare for estimation data
            load datNoiseExampleData.mat
            Ts=(PSMsigsX(2,1)-PSMsigsX(1,1));       % sampling rate in seconds
            NumExp=2;                               % number of experiments in identification.
            u1=PSMsigsX(1:18000,9);                 % Experiment 1, input 
            y1=PSMsigsX(1:18000,[2,3]);             % Experiment 1, output
            
            u2=PSMsigsX(19790:28820,9);             % Experiment 2, input
            y2=PSMsigsX(19790:28820,[2,3]);        % Experiment 2, output.
            
            % prepare validation data
            load datModeProbesRingDown;
            NumValidExp=4;                               % number of experiments in identification.
            uV1=PSMsigsX(1852:2800,9);                 % Experiment 1, input 
            yV1=PSMsigsX(1852:2800,[2,3]);             % Experiment 1, output
            
            uV2=PSMsigsX(5449:6200,9);             % Experiment 2, input
            yV2=PSMsigsX(5449:6200,[2,3]);        % Experiment 2, output.
            
            uV3=PSMsigsX(9020:9600,9);                 % Experiment 1, input 
            yV3=PSMsigsX(9020:9600,[2,3]);             % Experiment 1, output
            
            uV4=PSMsigsX(14436:15300,9);             % Experiment 2, input
            yV4=PSMsigsX(14436:15300,[2,3]);        % Experiment 2, output.
            SelectionCtrl=3;
            
        case 8
            load datT0308122320.mat
            SelectionCtrl=1;
            
        case 9
            load datPreparedAmbient.mat 
            SelectionCtrl=1;

        case 10 
            SelectionCtrl=0;

        otherwise
            SelectionCtrl=-1;
          
    end
% 1.0 end prepare the data 
%***********************************************************************
    
    if SelectionCtrl>0
        % prepare for model estimation data
       MyInput=cell(NumExp,1);
       MyOutput=cell(NumExp,1);
       NumExpUW=round(NumExp);
       for nIndexUW=1:NumExpUW
           MyInput{nIndexUW}=evalin('base',['u' int2str(nIndexUW)]);
           MyOutput{nIndexUW}=evalin('base',['y' int2str(nIndexUW)]);
        end
        % prepare for model validation data
        if NumValidExp>0
           MyValidInput=cell(NumValidExp,1);
           MyValidOutput=cell(NumValidExp,1);
           for nIndexUW=1:NumValidExp
               MyValidInput{nIndexUW}=evalin('base',['uV' int2str(nIndexUW)]);
               MyValidOutput{nIndexUW}=evalin('base',['yV' int2str(nIndexUW)]);
            end
        end

        %******************************************************************
        % major function
        switch SelectionCtrl
            case 1
                [Model,MajorFreq,MajorDR]=funL1Subspace(MyOutput, MyInput, Ts);
            case 2
                [Model,MajorFreq,MajorDR]=funL1Subspace(MyOutput, MyInput, Ts, Order,NumMajorModes, DeciFactor);
            case 3
                [Model,MajorFreq,MajorDR]=funL1Subspace(MyOutput, MyInput, Ts, [], [], [],MyValidOutput, MyValidInput);
            otherwise
        end
        %******************************************************************
    
        beep;
        disp(' ');
        disp('---------------------------------------')
        disp(' This is the end of this exmple. ');
        disp(' The analysis result of this example will be deleted for some other examples.');
        disp(' Press any key to continue to another example.....');
        pause
        %clc
    elseif SelectionCtrl<0
        disp('unknown command');
        disp('Press any key to continue.....');
        pause
        %clc
    else
        disp(' ')
        disp(['In JPmodeMeter Script ' CSname ': CASE SEQUENCE COMPLETE'])
        keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
        if keybdok
          disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
          keyboard
        end
        disp(' ')
    end
end

