function [CFname,PSMfiles,PSMsigsX,chankeyX,tstep,CaseComR,PSMreftimes,PSMtype,namesX]=funUserFunctionInterface(CFname,PSMfiles,PSMsigsX,chankeyX,tstep,CaseComR,PSMreftimes,PSMtype,namesX)
% This function serves as the interface point for all user-defined functions
% for the DSI toolbox. This includes generating a menu of available
% functions, as well as making the calls to the user functions.
%
% User functions must follow the guidelines in "User Function Guildines.txt"
% to properly integrate and be used by this routine and the DSI toolbox.
%
% Created March 4, 2014 by Frank Tuffner

%% Find where we're located
ThisFilesLocation=which('funUserFunctionInterface.m');

%Start from the right and go back until the first slash is encountered
IdxVal=length(ThisFilesLocation);
while (IdxVal>=1)
    if ((ThisFilesLocation(IdxVal)=='\') || (ThisFilesLocation(IdxVal)=='/'))
        break;
    end
    %Decrement
    IdxVal = IdxVal - 1;
end

%See if the "beginning" was reached
if (IdxVal==0)
    disp('In funUserFunctionInterface: Failed to find path for user functions -- exiting');
    return;
end

%Extract the path
FunctionFilePath=ThisFilesLocation(1:IdxVal);

%% Determine the functions present

%Get the list
FunctionsDIRList=dir([FunctionFilePath 'funDSI_USR_*.m']);

%Get number of functions found
NumFunctionsAvail=size(FunctionsDIRList,1);

%Make sure there are some
if (NumFunctionsAvail==0)
    disp('In funUserFunctionInterface: No user functions found, exiting');
    return;
end

%Make sure it isn't too big
if (NumFunctionsAvail>=99)
    disp('In funUserFunctionInterface: Over 98 functions have been found -- the list will be truncated!');
    
    %Truncate it
    NumFunctionsAvail = 98;
end

%% Print the menu and make a choice

%Create the number vector, just so all justify right
NumVectorText=num2str([(1:NumFunctionsAvail) 99].','%d');

disp(' ');
disp('Available user functions:');
disp(' ');

%Display loop
for pVals=1:NumFunctionsAvail
    
    %Try to pull the help information
    HelpCMD=['help ' FunctionsDIRList(pVals).name];
    tempOutpre=evalc(HelpCMD);
    
    %Remove MATLAB's <strong> items, since they muck up the results
    tempOutFirst=strrep(tempOutpre,'<strong>','');
    tempOut=strrep(tempOutFirst,'</strong>','');
    
    %See if there are any line break
    LineBreaks=(tempOut.'==sprintf('\n'));
    
    if (sum(LineBreaks)~=0) %1 or more
        %Create an indexing vector for this
        IdxVector=(1:length(tempOut));
        
        %Get line break points
        LineBreakPoints=IdxVector(LineBreaks);
        
        %Check the counts and see which one we want to do
        if (sum(LineBreaks)<=2)
            disp(['  ' NumVectorText(pVals,:) '   ' FunctionsDIRList(pVals).name]);
        else	%Must be big
            disp(['  ' NumVectorText(pVals,:) ' ' tempOut((LineBreakPoints(1)+1):(LineBreakPoints(2)-1))]);
        end
    else
        disp(['In funUserFunctionInterface: Unable to parse the help command for entry ' FunctionsDIRList(pVals).name]);
        return;
    end
end

%Add on the quit option
disp(['  ' NumVectorText((NumFunctionsAvail+1),:) '   Return to PSMbrowser']);
disp(' ');

%Prompt the user
UserMenuChoice=promptnv('Please select the user function to run:',99);

%% Now execute the function

if (UserMenuChoice~=99)
    %Rerun the help question
    HelpCMD=['help ' FunctionsDIRList(UserMenuChoice).name];
    tempOutpre=evalc(HelpCMD);
    
    %Remove MATLAB's <strong> items, since they muck up the results
    tempOutFirst=strrep(tempOutpre,'<strong>','');
    tempOut=strrep(tempOutFirst,'</strong>','');
    
    %See if there are any line break
    LineBreaks=(tempOut.'==sprintf('\n'));
    
    %Create an indexing vector for this
    IdxVector=(1:length(tempOut));

    %Get line break points
    LineBreakPoints=IdxVector(LineBreaks);
    
    %Extract the command
    UserCMD=strtrim([tempOut(1:(LineBreakPoints(1)-1)) ';']);
    
    %Execute this
    try
        evalc(UserCMD);
    catch exception
        disp(' ');
        disp(['In funUserFunctionInterface: Function ' FunctionsDIRList(UserMenuChoice).name ' had an error!']);
        disp(' ');
        disp(exception.message);
    end

else %Case 99, exit
    disp('In funUserFunctionInterface: Exiting user routines and going back to PSMbrowser');
    return;
end