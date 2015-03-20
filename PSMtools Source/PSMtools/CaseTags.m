function [caseID,casetime,CaseCom,Gtags]=CaseTags(caseID)
% CaseTags.m accepts case identification  and comments from the user.
%
%     [caseID,casetime,CaseCom,Gtags]=CaseTags
%
% a) "caseID" is a one-line case ID tag entered within CaseTags by the user.
% b) "casetime" is the time when case execution starts
% c) "CaseCom" is the initial value for a matrix of comments
% d) "Gtags" is a comment matrix to be pasted onto graphs
%
%  Last modified 01/09/01.  jfh
%  Last modified 03/31/2006  ZN for running macro


%Global controls on prompt defaults
global Kprompt ynprompt nvprompt
%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
global PSMMacro         % Macro Structure  
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
% End: Macro definition ZN 03/31/06
%----------------------------------------------------

disp('In CaseTags:')

if ~exist('caseID'),caseID=''; end

%*************************************************************************
%Obtain name for present case
setok=0;
maxtrys=10;
for i=1:maxtrys
  if ~setok
    disp(['In CaseTags: caseID = ' caseID])
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    if ~isfield(PSMMacro,'CaseTags_setok') PSMMacro.CaseTags_setok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.CaseTags_setok))      % Macro definition mode or selection not defined in a macro
        setok=promptyn('In CaseTags: Is this ok? ', 'y');
    else
        setok=PSMMacro.CaseTags_setok;
    end
    
    if PSMMacro.RunMode==0      % if macro is in record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.CaseTags_setok=setok;
        else                                % if record mode is paused
            PSMMacro.CaseTags_setok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
    
    if setok, break, end
    prompt='In CaseTags: Enter name for present case: ';
    caseID=input(prompt,'s');
  end
end
if ~setok
  disp(['Sorry - ' int2str(maxtrys) ' chances is all you get!'])
  disp(['In CaseTags: Using caseID = ' caseID])
end
%*************************************************************************

%*************************************************************************
%Set case time tag
tag=fix(clock); tag(1)=tag(1)-fix(tag(1)/100)*100;
casetime=[sprintf('%2.0i',tag(2)) '/' sprintf('%2.0i',tag(3)) '/'...
  sprintf('%2.0i',tag(1)) '_'];
casetime=[casetime sprintf('%2.0i',tag(4)) ':' sprintf('%2.0i',...
  tag(5)) ':' sprintf('%2.0i',tag(6))];
nchars=size(casetime,2);
for i=1:nchars
  if strcmp(casetime(i),' '), casetime(i)='0'; end
end
disp(['In CaseTags: Case Time = ' casetime])
%*************************************************************************

%*************************************************************************
%Initialize case documentation matrix CaseCom
S0=['Case ID   = ' caseID];       %defines string S0
S1=['Case Time = ' casetime];     %defines string S1
CaseCom=str2mat(S0,S1);           %loads strings into matrix
Gtags=str2mat(caseID,casetime);
%*************************************************************************

%*************************************************************************
%Permit user to add further comments
[CaseCom]=AddCom(CaseCom);
%*************************************************************************

return

%end of PSM script

