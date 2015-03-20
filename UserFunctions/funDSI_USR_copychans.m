function [PSMsigsXout,namesXout,chankeyXout,CaseComRout]=funDSI_USR_copychans(PSMsigsX,namesX,chankeyX,CaseComR)
% [PSMsigsX,namesX,chankeyX,CaseComR]=funDSI_USR_copychans(PSMsigsX,namesX,chankeyX,CaseComR)
% Sample user-defined function that duplicates the channels of PSMsigsX
%
%
% This function is a simple example of how a user-defined DSI function may work
% This function merely takes the input data, and duplicates the data to a new set
% of channels.
%
% Usage:
% [PSMsigsXout,namesXout,chankeyXout,CaseComRout]=...
%               funDSI_USR_copychans(PSMsigsX,namesX,chankeyX,CaseComR)
%
% where:
% PSMsigsXout is the output data matrix
% namesXout is the output, unnumbered channel information variable
% chankeyXout is the output, numbered channel information variable
% CaseComRout is the output, system log for the actions taken on this data
%
% PSMsigsX is the input data matrix
% namesX is the input, unnumbered channel information variable
% chankeyX is the input, numbered channel information variable
% CaseComR is the input, system log for the actions taken on this data
%
% Created March 4, 2014 by Frank Tuffner

%Error checks
if ((nargin~=4) || (nargout~=4))
    error('In funDSI_USR_copychans: Failed to provide all necessary input variables!');
end

%Get initial size information
[DataLength,NumChansIn]=size(PSMsigsX);
FinalChansSize=(1+(NumChansIn-1)*2);

%Create a new output variable
PSMsigsXout=zeros(DataLength,FinalChansSize);
PSMsigsXout(:,(1:NumChansIn))=PSMsigsX;
PSMsigsXout(:,((NumChansIn+1):FinalChansSize))=PSMsigsX(:,(2:NumChansIn));

%Create the new namesX variable
namesXout=[namesX; namesX((2:NumChansIn),:)];

%Create new chankeyX - do this from namesX since it is easier that way
chankeyXout=[repmat('% ',FinalChansSize,1) num2str((1:FinalChansSize).','%d') repmat('  ',FinalChansSize,1) namesXout];

%Append the CaseComR with what we did
CaseComRout=str2mat(CaseComR,'funDSI_USR_copychans - duplicated channel listing');