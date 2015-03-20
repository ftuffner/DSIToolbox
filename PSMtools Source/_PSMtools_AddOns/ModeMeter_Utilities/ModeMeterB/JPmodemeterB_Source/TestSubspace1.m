% JPmodeMeter Case Script TestSubspace1.m
% Template to process user defined data
%****************************************************************
% This code can be used as a template to process user defined data.
% Users are encouraged to modify som pre-defined variables to have
% their data processed.
%
% First time users are encouraged to run 'TestSubspace2.m', which
% contains 9 examples on how to use subspace method on power data.
%
% Ning Zhou. 04/23/2004
%
% Modified 05/13/04   jfh

%*******************************************************************
% 1.0 Prepare data.
% you may change the following variables according to your situation.
%
% Estimation Variablbes are: 
%
%       Ts:     sampling rate in seconds
%       NumExp: a positive integer indicating the number of input.
%       u1:     input matrix, each column of u1 contains a channel of an
%               input for first experiment;  set to [] for ambient data
%       y1:     output matrix, each column of y1 contains a channel of an
%               input for first experiment
%
%       u2:     input matrix, each column of u2 contains a channel of an
%               input for second experiment
%       y2:     output matrix, each column of y2 contains a channel of an
%               input for second experiment
%
% Validation Variables are
%       NumValidEx;             % number of estimation experiments in identification.
%       uV1;                    % Validation Experiment 1, input. set it to
%                                 set to [] for ambient data
%       yV1;                    % Validation Experiment 1, output.
% 
% Optional Variables may improve calcuation efficiency if given. If not
%                           sure, please set them to [];
%       Order:                % order of state space model
%       NumMajorModes:        % major modes if known ahead (Hz)
%       DeciFactor:           % decimation factor if known ahead

clear all
clc
close all

%Set name for this case script
CSname='TestSubspace1';

disp(' ')
disp(['In JPmodeMeter Script ' CSname ':'])
disp('(Template to process user defined data)')
disp(' ')

load datModeProbesRingDown;             % theses data came from 2000 test for single mode square wave injection.
            
Ts=(PSMsigsX(2,1)-PSMsigsX(1,1));       % sampling rate in seconds

NumExp=3;                               % number of estimation experiments in identification.
u1=PSMsigsX(1852:2800,9);               % Experiment 1, input 
y1=PSMsigsX(1852:2800,[2,3]);           % Experiment 1, output
            
u2=PSMsigsX(5449:6200,9);               % Experiment 2, input
y2=PSMsigsX(5449:6200,[2,3]);           % Experiment 2, output.

u3=PSMsigsX(9020:9600,9);                 % Experiment 3, input 
y3=PSMsigsX(9020:9600,[2,3]);             % Experiment 3, output

NumValidExp=1;                           % number of estimation experiments in identification.
% NumValidExp=-1;                        % if there is no validation data set 'NumValidExp' to -1

uV1=PSMsigsX(14436:15300,9);             % Validation Experiment 1, input
yV1=PSMsigsX(14436:15300,[2,3]);         % Validation Experiment 1, output.

Order=[];                               % order of state space model
NumMajorModes=[0.26; 0.38; 0.6];        % major modes if known ahead (Hz)
DeciFactor=[];                          % decimation factor if known ahead

%Order=16;                               % order of state space model
%NumMajorModes=[];                      % major modes if known ahead
%DeciFactor=6;                          % decimation factor if known ahead

% 2.0prepare for model estimation data
MyInput=cell(NumExp,1);
MyOutput=cell(NumExp,1);
NumExpUW=round(NumExp);

for nIndexUW=1:NumExpUW
    MyInput{nIndexUW}=evalin('base',['u' int2str(nIndexUW)]);
    MyOutput{nIndexUW}=evalin('base',['y' int2str(nIndexUW)]);
end

%prepare for model validation data
if NumValidExp>0
   MyValidInput=cell(NumValidExp,1);
   MyValidOutput=cell(NumValidExp,1);
   for nIndexUW=1:NumValidExp
       MyValidInput{nIndexUW}=evalin('base',['uV' int2str(nIndexUW)]);
       MyValidOutput{nIndexUW}=evalin('base',['yV' int2str(nIndexUW)]);
   end
else
    MyValidOutput=[];
    MyValidInput=[];
end
if 0
figure
hold on
h1=plot(u1,'r')
plot(u2,'g');
h3=plot(u3,'b')
legend([h1;h3],{'u1';'u3d'})
end

[Model,MajorFreq,MajorDR]=funL1Subspace(MyOutput, MyInput, Ts, Order,NumMajorModes, DeciFactor,MyValidOutput, MyValidInput);

disp(' ')
disp(['In JPmodeMeter Script ' CSname ': CASE SEQUENCE COMPLETE'])
keybdok=promptyn(['In ' CSname ': Do you want the keyboard? '], 'n');
if keybdok
  disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end
disp(' ')
 

