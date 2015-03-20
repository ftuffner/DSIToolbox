%***********************************************************************************
% Input parameters  
%       Y:   Ambient data matrix. Each channel should be put into each 
%            column of Y matrix
%       Fs:  Sample Frequency. 

%       DeciFactor:     Decimation factor ( to decrease the sampling rate )
%       MyI:            'i' for the subsapce method (should be greater than the order
%                       of system (default value =50);
%       Order:          The selected order of state space model
%       NumMajorModes:  # of the major modes of state space model

%
% Output parameters
%      IdentifiedModel: State Space model identified.
%

function IdentifiedModel=funSubspace(MyData,DeciFactor,Order,OrderRange)

path(path,'subfun');        % set a sub directory for some functions used
%***************************************************************************
%  1 Check the arguments
if (nargin < 1);error('SubspaceAmbient needs at least one argument');end
if (nargin < 2);DeciFactor=[];end
if (nargin < 3);Order=[];end
if (nargin < 4);NumMajorModes=[];end

if iscell(MyData.Ts)
    Fs=1/MyData.Ts{1};
else
    Fs=1/MyData.Ts;
end

%  1.2 Check the detrend need of Y
MyData=detrend(MyData,'constant');
%  1.3 Check the sample frequency and down sample the original signal if
%  necessary.
disp(' ');
disp('------------------------------ ');
if length(DeciFactor)==0   % not decimation number is selected
    if (Fs > 6)
        disp(sprintf('Your sample Freq is %5.2f Hz,which might be too high for identification purpose.',Fs));
        Response=input('Do you want to do decimation (decrease the sampling freq)?  Enter y or n [y]:','s');
        if isempty(Response)                 %Test for empty string
          setok=1;
        else
          setok=strcmp(Response(1),'y');     %String comparison
        end
     
        if setok
           disp(' ');
           disp(sprintf('New sample freq = %5.2f/decimation factor',Fs));
           DeciFactor=input(sprintf('Input you decimation factor (which should be a positive integer)[%d]:', floor(Fs/5)));
           if isempty(Response) 
               DeciFactor=floor(Fs/5);
           end
       end
   else
       DeciFactor=1 
       disp('Decimation is not performed');
   end
end

if DeciFactor> 1
    DeciFactor=round(DeciFactor);
    FsFinal=Fs/DeciFactor;
    % Anti-Alias low pass linear-phase FIR filter design using the Parks-McClellan algorithm
    FilterOrder=5;
    FilterWn=(FsFinal/2)/(Fs/2);
    MyData = idfilt(MyData,FilterOrder,FilterWn,'noncausal')       
    MyData = idresamp(MyData,DeciFactor)         
    Fs=FsFinal;
    disp('Decimation has been performed on your data set');
end

end
disp(sprintf('Sample Frequency= %5.2f Hz',Fs));
%  end  of 1.0 Check the arguments
%***************************************************************************


%********************************************************************
%2 subspace method in modes finding

% 2.1 Input parameters preparation
if (length(MyI)==0); MyI=50;end         % The 'i' for subspace method ( 'i' should be greater than the order)

% 2.2 CVA of subspace method
[A,K,C,R] = sto_alt(Y,MyI,Order);   % 'CVA weighted' 

% 2.3 find all identified modes
Order=length(A);
zPolesCVA=eig(A);                                            % discrete modes
sPolesCVA=log(zPolesCVA).*Fs;                                % continuous modes in radian/s

Freq=imag(sPolesCVA)./(2*pi);                                % find corresponding Frequencies
DR=abs(100*cos(pi-atan2(imag(sPolesCVA),real(sPolesCVA))));  % find corresponding Damping ratios
[tempF,Is]=sort(Freq);                                       % Arrange modes
IdentifiedModes=[Freq(Is),DR(Is)];                           % Freq and DR of all modes

disp('     ')
disp('----------------------');
disp(sprintf('Identified modes from CVA:(i=%d,  order=%d)',MyI,Order));
for nIndex=1:Order
    disp(sprintf('freq=%5.4f      DR=%5.4f', IdentifiedModes(nIndex,1),IdentifiedModes(nIndex,2)));
end
disp('-----------------------');
% end of 2
%**************************************************************************

%***************************************************
% 3. find the main poles for CVA
% 3.1 construct the state space model
[l,n]=size(C);          % l is the # of outputs; n is the # of order
m=l;                    % m is the # of input
D=zeros(l,m);
MyModel = idss(A,K,C,D);        % construct the model from identified Parameter Matrix 

if ( length(NumMajorModes)==0)
    MainOrder=[];               % Order of state space model
else
    MainOrder=NumMajorModes*2;
end       
disp(' ');
disp(' ');
disp('-----------------------');
disp('Finding major modes');
MRED = idmodred(MyModel,MainOrder);       % do the model reduction
MainOrder=length(MRED.a);
zMainPoles= eig(MRED.a);        % find the major discrete poles
sMainPoles=log(zMainPoles).*Fs; % convert it into continuous poles
MainFreq=imag(sMainPoles)./(2*pi);      % find corresponding Frequencies
MainDR=cos(pi-atan2(imag(sMainPoles),real(sMainPoles))); %find corresponding Damping ratios

[tempF,I]=sort(MainFreq);
[MainFreq(I),MainDR(I)];

sMainPolesHalf=sMainPoles(I(floor(MainOrder/2)+1:end));

Np=length(sMainPolesHalf);                               % number of main freq
CVAsMainPolesHalf=zeros(Np,1);
    
    for pIndex=1:Np
        tempDist=100000;
        for ywIndex=1:Order
            dTemp=sMainPolesHalf(pIndex)-sPolesCVA(ywIndex);
            rTemp=real(dTemp);
            iTemp=imag(dTemp);
            dTemp=rTemp*rTemp/2.5+iTemp*iTemp;  % distance between two poles; 2.5  is used to reduce influene of distance on real direction
            if  dTemp<tempDist
                tempDist=dTemp;
                tempPoles=sPolesCVA(ywIndex);
            end
        end
        CVAsMainPolesHalf(pIndex)=tempPoles;
    end

MajorModes=[imag(CVAsMainPolesHalf)./(2*pi), -100*real(CVAsMainPolesHalf)./abs(CVAsMainPolesHalf)];

disp('     ')
disp('----------------------');
disp(sprintf('Major modes from CVA:(i=%d,  order=%d)',MyI,Order));
for nIndex=1:Np
    disp(sprintf('freq=%5.4f      DR=%5.4f', MajorModes(nIndex,1),MajorModes(nIndex,2)));
end
disp('-----------------------');
