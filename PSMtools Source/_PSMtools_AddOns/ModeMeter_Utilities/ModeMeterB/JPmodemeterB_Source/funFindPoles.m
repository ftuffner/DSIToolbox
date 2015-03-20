function [sPoles,sMajorPoles,MRED]=funFindPoles(MyModel,NumMajorPoles);
%
% function [sPoles,sMajorPoles,MRED]=funFindPoles(MyModel,NumMajorPoles);
%
%***********************************************************************************
% Input parameters  
%       MyModel:          The state space model
%       NumMajorPoles:  # of the major modes of state space model
%
% Output parameters
%      Poles: All the continuous poles found from State Space model.
%      MajorPoles: Major continuous poles from State Space model.
%
% Modified 05/26/04.  jfh   (Displays to track processing)
 
FNname='funFindPoles';  %name for this function

disp(' ')
disp(['In JPmodeMeter function ' FNname ':'])
disp(' ')

%***********************************************************************************
%  1 Check the arguments
if (nargin < 1); error('SubspaceAmbient needs at least one argument'); end
if (nargin < 2); NumMajorPoles=[]; end
Fs=1/MyModel.Ts;
%  end  of 1.0 Check the arguments
%***********************************************************************************

%***********************************************************************************
% 2.3 find all identified Poles
A=MyModel.a;
Order=length(A);
zPoles=eig(A);                                          % discrete modes
sPoles=log(zPoles).*Fs;                                % continuous modes in radian/s
% end of 2
%***********************************************************************************

%***********************************************************************************
% 3. find the main poles for state space model
NRawPoles=length(sPoles);
if length(NumMajorPoles)<2          
    if length(NumMajorPoles)==0     % number of major modes is not given
        MainOrder=min([max([round(Order/2),13]),Order]);               % Order of state space model
    elseif length(NumMajorPoles)==1      %number of major modes is given
        MainOrder=NumMajorPoles*2;
    end       
    MRED = idmodred(MyModel,MainOrder);  %do model reduction
    MainOrder =length(MRED.a);
    zMainPoles=eig(MRED.a);          %find the major discrete poles
    sMainPoles=log(zMainPoles).*Fs;  %convert to continuous poles
    NMainPoles=length(sMainPoles); NpolesE=NRawPoles-NMainPoles;
    disp(['In ' FNname ': Model reduction has eliminated ' num2str(NpolesE) ' poles'])
else                                % frequency matrix is given
    sMainPoles=2*pi*NumMajorPoles*i;    
end
%***********************************************************************************

%***********************************************************************************
NMainPoles=length(sMainPoles);  % number of main freq
sMajorPoles=zeros(NMainPoles,1);
for pIndex=1:NMainPoles
    tempDist=100000;
    for ywIndex=1:Order
        dTemp=sMainPoles(pIndex)-sPoles(ywIndex);
        rTemp=real(dTemp);
        iTemp=imag(dTemp);
        %Distance between two poles; 2.5  is used to reduce influence of distance on real direction
        dTemp=rTemp*rTemp/1.5+iTemp*iTemp;
        if  dTemp<tempDist
            tempDist=dTemp;
            tempPoles=sPoles(ywIndex);
        end
     end
     sMajorPoles(pIndex)=tempPoles;
end
NMajorPoles=length(sMajorPoles); NpolesE=NMainPoles-NMajorPoles;
disp(['In ' FNname ': Distance test has eliminated ' num2str(NpolesE) ' poles'])
%***********************************************************************************

%End of JPmodeMeter function 