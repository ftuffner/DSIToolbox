function [CaseCom,PRSmodel,PRSpoles]=...
   PRSdisp1(caseID,casetime,CaseCom,namesX,PSMsigsX,tstep);

%PRSdisp1 displays Prony solution (PRS) tables, returns Prony model
% for use in continued system analysis etc.
%
% [CaseCom,PRSmodel,PRSpoles]=...
%   PRSdisp1(caseID,casetime,CaseCom,namesX,PSMsigsX,tstep);
%
% PSM Tools called from PSMbrowser:
%   getmodel
%   Ringdown
%   RootSort1
%   ModeDisp1
%   
%   PickSigsN
%   promptyn, promptnv
%   (others)
%
% Modified 06/15/04.   jfh
% Modified 10/18/2006  by Ning Zhou to add macro function

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

persistent FigDef
%?????????? global FigDef

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

 
if 0
    keyboard
    save Debug_10
elseif 0
%    clear all 
%    close all
    clc
    load Debug_10
    funLoadMacro()
    PSMMacro.RunMode=1;  %run macro
%    PSMMacro.RunMode=0;  %record macro
%    PSMMacro.RunMode=-1; %normal orperation
end

if isempty(FigDef), FigDef=1; end

%Clear outputs
PRSmodel=[]; PRSpoles=[];

%Check inputs

Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '    casetime=' casetime];
disp(' ')
disp('In PRSdisp1: EXPERIMENTAL CODE FOR REVIEWING PRONY SOLUTION (PRS)');
disp('             AND CONSTRUCTING LINEAR [A B C D] MODEL');
disp(['In PRSdisp1: ' Ptitle{2}]);
 format short %May need diagnostic displays 

if 0  %Interactive diagnostics
  keyboard
  %help ringdown
  %type ringdown
  %help getmodel
end

FNname='PRSdisp1';
chankeyX=names2chans(namesX);

%************************************************************************
MaxTries=8;
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PRSdisp1_FigDef'), PSMMacro.PRSdisp1_FigDef=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PRSdisp1_FigDef))      % Not in Macro playing mode or selection not defined in a macro
    for M=1:MaxTries
      prompt='In PRSdisp1: Indicate figure number for Prony solution ';
      PRSfig=promptnv(prompt,FigDef);
      PRSfig=max(PRSfig,1);
      disp(['In PRSdisp1: PRSfig = ' num2str(PRSfig)])
      setok=promptyn('  Is this value ok?', 'y');
      if setok
        try idmodel=Getmodel(PRSfig,0,1); break
        catch
          disp('Bad figure number for Prony solution--try again')
        end
      end
      if M==MaxTries
        disp(['In PRSdisp1: Sorry -- ' num2str(M) ' tries is all you get']);
        return
      end
    end
    FigDef=PRSfig;
else
    FigDef=PSMMacro.PRSdisp1_FigDef;
    try idmodel=Getmodel(FigDef,0,1);
    catch
       disp('Bad figure number for Prony solution--try again');
       PSMMacro.RunMode=-1;
       return;
    end
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PRSdisp1_FigDef=FigDef;
    else
        PSMMacro.PRSdisp1_FigDef=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%
% End: Macro selection ZN 10/18/06
%----------------------------------------------------

%************************************************************************

%************************************************************************
%Get PRS parameters, place them in basic order
[AllPoles nfits]=size(idmodel.res);
Poles0 =idmodel.pol;
Bres0  =idmodel.bres;
Tres0  =idmodel.res;
RelEn0 =idmodel.releng;
Afpe0  =idmodel.afpe;
Select0=idmodel.select;
SigNames0=char(idmodel.titles);
thru=idmodel.thru; if isnan(thru), thru=zeros(nfits,1); end
%Order all Poles by ascending frequency, with real Poles first
disp(['In PRSdisp1: Full signal names are'])
disp(names2chans(SigNames0))
SigNames=SigNames0;  %Sometimes need to shorten these
[SigNames]=BstringOut(SigNames0,' ',3);
locsS0=zeros(AllPoles,nfits);
for N=1:nfits 
  SortType=1; SortTrack=(N==1);
  [PolesP,SortType,PoleCats,PoleCatNames,locsS0(:,N)]=...
    RootSort1(Poles0(:,N),SortType,SortTrack);
  Poles0(:,N) =Poles0(locsS0(:,N),N);
  Bres0(:,N)  =Bres0(locsS0(:,N),N);
  Tres0(:,N)  =Tres0(locsS0(:,N),N);
  RelEn0(:,N) =RelEn0(locsS0(:,N),N);
  Afpe0(:,N)  =Afpe0(locsS0(:,N),N);
  Select0(:,N)=Select0(locsS0(:,N),N);
end
%PRS is now in basic order
%Later versions of Ringdown GUI should do this internally
%disp('Let's just check things out'), keyboard
Poles=Poles0;
OKsort=zeros(AllPoles,1);
for M=1:AllPoles
  OKsort(M)=isempty(find(Poles(M,1)~=Poles(M,:)));
end
BadSort=~isempty(find(OKsort==0));
if BadSort
  disp('In PRSdisp1: Sorting discrepancies between signals')
  disp('  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end
Bres=Bres0; Tres=Tres0;
RelEn=RelEn0; Afpe=Afpe0;
Select=Select0;
%Determine category sort
N=1; SortType=1; SortTrack=0;
[PolesS1,SortType,PoleCats1,PoleCatNames,locsS1]=...
  RootSort1(Poles(:,N),SortType,SortTrack); %Already in basic order
%disp([PolesS1/(2*pi) Poles(:,N)/(2*pi) Poles(locsS1,N)/(2*pi)locsS1])
[PolesS2,SortType,PoleCats2,PoleCatNames,locsS2]=...
  RootSort1(Poles(:,N),2,0); %Sorted category order
%disp([PolesS2/(2*pi) Poles(:,N)/(2*pi) Poles(locsS2,N)/(2*pi)locsS2])
%disp([PolesS2/(2*pi) PoleCats2])
disp(['In PRSdisp1: ' Ptitle{2}]);
DispType=1; ZerosP=[];
[CaseCom]=ModeDisp1(caseID,casetime,CaseCom,'All PRS Poles (basic order)',...
  PolesS1(:,1),ZerosP,DispType,PoleCats1,PoleCatNames);
[CaseCom]=ModeDisp1(caseID,casetime,CaseCom,'All PRS Poles (category order)',...
  PolesS2(:,1),ZerosP,DispType,PoleCats2,PoleCatNames);
%Check for unused Poles
SelectSum=sum(Select,2);
locsU=find(SelectSum>0); %All  Poles in use
nNotUsed=AllPoles-length(locsU);
disp(' ')
disp(['In PRSdisp1: Full signal names are'])
disp(names2chans(SigNames0))
disp(' ')
disp(['In PRSdisp1: ' num2str(nNotUsed) ' unused Poles'])
[CaseCom]=ModeDisp1(caseID,casetime,CaseCom,'PRS Poles in use (category order)',...
  PolesS2(locsU,1),ZerosP,DispType,PoleCats2(locsU),PoleCatNames);
%************************************************************************

%************************************************************************
%Experimental code for repeat eigenvector solutions
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PRSdisp1_RepeatCase'), PSMMacro.PRSdisp1_RepeatCase=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PRSdisp1_RepeatCase))      % Not in Macro playing mode or selection not defined in a macro
    RepeatCase=promptyn(['In ' FNname ': Perform repeat solution with existing poles? '], '');
else
    RepeatCase=PSMMacro.PRSdisp1_RepeatCase;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PRSdisp1_RepeatCase=RepeatCase;
    else
        PSMMacro.PRSdisp1_RepeatCase=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%RepeatCase=promptyn(['In ' FNname ': Perform repeat solution with existing poles? '], '');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if RepeatCase
  %keyboard
  InSig=[]; FixedPoles=PolesS2(locsU);
  [maxpoints nsigs]=size(PSMsigsX);
  rgulocs=2:nsigs;  %All signals
  time=PSMsigsX(:,1);
  n1=1; timeN=time;
  swlocs=find(time(1:maxpoints-3)==time(2:maxpoints-2));
  if ~isempty(swlocs)
    disp(['In ' FNname ': Time axis indicates ' num2str(length(swlocs)) ' switching  times'])
    n1=max(swlocs); timeN=time(n1)+(0:maxpoints-n1)'*tstep;
    disp(['Ringdown analysis delayed to ' num2str(timeN(1)) ' seconds'])
  end
  
  if PSMMacro.RunMode<1 
      keybdok=promptyn(['In ' FNname ': Do you want the keyboard first? '], 'n');
      if keybdok
        disp(['In ' FNname ': Invoking "keyboard" command - Enter "return" when you are finished'])
        keyboard
        %rgulocs=[2 78];  %Example of special selection
      end
  end

    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    if ~isfield(PSMMacro, 'PRSdisp1_menusok'), PSMMacro.PRSdisp1_menusok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PRSdisp1_menusok))      % Not in Macro playing mode or selection not defined in a macro
        menusok=promptyn(['In ' FNname ': Do you want signal selection menus? '], '');
    else
        menusok=PSMMacro.PRSdisp1_menusok;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PRSdisp1_menusok=menusok;
        else
            PSMMacro.PRSdisp1_menusok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    %menusok=promptyn(['In ' FNname ': Do you want signal selection menus? '], '');
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------

  
  
  if menusok %Select signals to process
    disp(' ')
    disp(['In ' FNname ':  Select signals for input to GUI']);
    PRcom='input to GUI';

    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    %keyboard;
    if ~isfield(PSMMacro, 'PRSdisp1_chansPok'), PSMMacro.PRSdisp1_chansPok=NaN; end
    if ~isfield(PSMMacro, 'PRSdisp1_chansP'), PSMMacro.PRSdisp1_chansP=NaN; end
    if ~isfield(PSMMacro, 'PRSdisp1_MenuName'), PSMMacro.PRSdisp1_MenuName=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PRSdisp1_chansPok))      % Not in Macro playing mode or selection not defined in a macro
        [MenuName,chansP,chansPok]=PickSigsN(rgulocs,namesX,chankeyX,'',PRcom);
    else
        chansPok=PSMMacro.PRSdisp1_chansPok;
        chansP=PSMMacro.PRSdisp1_chansP;
        MenuName=PSMMacro.PRSdisp1_MenuName;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PRSdisp1_chansPok=chansPok;
            PSMMacro.PRSdisp1_chansP=chansP;
            PSMMacro.PRSdisp1_MenuName=MenuName;
        else
            PSMMacro.PRSdisp1_chansPok=NaN;
            PSMMacro.PRSdisp1_chansP=NaN;
            PSMMacro.PRSdisp1_MenuName=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % [MenuName,chansP,chansPok]=PickSigsN(rgulocs,namesX,chankeyX,'',PRcom);
    % End: Macro selection ZN 10/18/06
    %----------------------------------------------------

    
    if ~chansPok
      disp(' No menu selections')
      chansP=[];
    end
    locsP=find(chansP>1); chansP=chansP(locsP);
    if ~isempty(chansP), rgulocs=chansP; end
  end
  timeN=timeN(1:(maxpoints-n1+1)); %Safety check
  rguiopts.copyplotfcn='PSMlabl';
  rguiopts.copyplotargs={caseID casetime};
  ringdown([timeN PSMsigsX(n1:maxpoints,rgulocs)],namesX(rgulocs,:),InSig,FixedPoles,rguiopts);
  disp('In PRSdisp1: Repeat case done -- return')
  return
end
%************************************************************************

%########################################################################
%Top of display loop (need plot/print option)
MaxDisps=20;
for Ndisp=1:MaxDisps
disp(' '); disp(' ')
str=('In PRSdisp1: Top of display loop ');
str=[str '-- max displays = ' num2str(MaxDisps)];
disp(str)
prompt=['  Proceed with display cycle ' num2str(Ndisp) '?'];

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PRSdisp1_setok'), PSMMacro.PRSdisp1_setok=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PRSdisp1_setok))      % Not in Macro playing mode or selection not defined in a macro
    setok=promptyn(prompt, '');
else
    setok=PSMMacro.PRSdisp1_setok;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PRSdisp1_setok=setok;
    else
        PSMMacro.PRSdisp1_setok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%setok=promptyn(prompt, '');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if ~setok
  disp('  Terminating display loop')
  break
end

%************************************************************************
%Reload PRS data in basic order
Poles =Poles0;
Bres  =Bres0;
Tres  =Tres0;
RelEn =RelEn0;
Afpe  =Afpe0;
Select=Select0;
PoleCats=PoleCats1;
disp('  Pole display can be in basic order, or in category order')
CatOrd=promptyn('  Display in category order?', 'y');
if CatOrd
  Poles =Poles(locsS2,:);
  Bres  =Bres(locsS2,:);
  Tres  =Tres(locsS2,:);
  RelEn =RelEn(locsS2,:);
  Afpe  =Afpe(locsS2,:);
  Select=Select(locsS2,:);
  PoleCats=PoleCats(locsS2);
end
SelectSum=sum(Select,2);
locsU=find(SelectSum>0); %All  Poles in use 
nNotUsed=AllPoles-length(locsU);
disp(' ')
disp(['In PRSdisp1: ' num2str(nNotUsed) ' unused Poles'])
DiscNUP=promptyn('  Discard unused poles?', 'n');
if DiscNUP
  Poles =Poles(locsU,:);
  Bres  =Bres(locsU,:);
  Tres  =Tres(locsU,:);
  RelEn =RelEn(locsU,:);
  Afpe  =Afpe(locsU,:);
  Select=Select(locsU,:);
  SelectSum=sum(Select,2);
  PoleCats=PoleCats(locsU);
end
ZeroNUR=promptyn('  Zero unused residues for each signal?', 'n');
if ZeroNUR
  for N=1:nfits
    Bres(:,N)=Bres(:,N).*Select(:,N);
    Tres(:,N)=Tres(:,N).*Select(:,N);
  end
end
setok=promptyn('  Do you want the keyboard?', 'n');
if setok
  disp('  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end
%************************************************************************

%************************************************************************
disp(' ')
disp('In PRSdisp1: Select Poles to display')
DispMenu=str2mat('All Poles','All Poles in Use','none');
DispMenu=str2mat(DispMenu,PoleCatNames);
optsD=[6 7 8]; locbase=1; maxtrys=10;
[optsD,DispNames,optsok]=PickList2(DispMenu,optsD,locbase,maxtrys);
if ~optsok
  disp(' Returning to invoking Matlab function.')
  return
end
while 1
  if ~isempty(find(optsD==3)) %No Poles
    disp(' Returning to invoking Matlab function.')
    return
  end
  if ~isempty(find(optsD==1)) %All Poles
    locsD=1:size(Poles,1);
    if DiscNUP
      disp('  Sorry -- unused poles supressed for this display cycle')
      disp('  Can only show poles in use')
      locsD=find(SelectSum>0);
    end
    break
  end
  if ~isempty(find(optsD==2)) %All Poles in use  
    locsD=find(SelectSum>0);
    break
  end
  locsD=[];
  for Ncat=1:size(PoleCatNames,1)
    if ~isempty(find(Ncat==(optsD-3)))
      locs=find(PoleCats==Ncat);
      locsD=[locsD' locs']';
    end
  end
  break
end %Terminate while
%keyboard
Poles =Poles(locsD,:);
Bres  =Bres(locsD,:);
Tres  =Tres(locsD,:);
RelEn =RelEn(locsD,:);
Afpe  =Afpe(locsD,:);
Select=Select(locsD,:);
PoleCats=PoleCats(locsD);
%PoleCats(locsD)
%************************************************************************

%************************************************************************
CompassPlotsA
%************************************************************************

PRSpoles=Poles;
end  %Termination of display loop
%########################################################################

disp(' ')
disp('In PRSdisp1: Display loop completed')

disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
if ~isfield(PSMMacro, 'PRSdisp1_BuildSS'), PSMMacro.PRSdisp1_BuildSS=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PRSdisp1_BuildSS))      % Not in Macro playing mode or selection not defined in a macro
    BuildSS=promptyn('In PRSdisp1: Construct PRS simulation model?','');
else
    BuildSS=PSMMacro.PRSdisp1_BuildSS;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PRSdisp1_BuildSS=BuildSS;
    else
        PSMMacro.PRSdisp1_BuildSS=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
%BuildSS=promptyn('In PRSdisp1: Construct PRS simulation model?','');
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


if BuildSS
  setok=promptyn('  Prototype code -- Do you want the keyboard?','n');
  if setok
    disp('  Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
  NpolsP=size(Poles,1);
  AP=zeros(NpolsP,NpolsP,nfits);
  BP=zeros(NpolsP,1,nfits);
  CP=zeros(1,NpolsP,nfits);
  DP=zeros(1,1,nfits);
  Ptitle{1}=' ';
  Ptitle{2}=['caseID=' caseID '    casetime=' casetime];
  for N=1:nfits
    %Insertion point for future selection edit
    TresM=Tres(:,N).*Select(:,N);
    [AP(:,:,N),BP(:,:,N),CP(:,:,N),DP(:,:,N)]=...
      par2ss(TresM,Poles(:,N),thru);
    [NUM,DEN] = ss2tf(AP(:,:,N),BP(:,:,N),CP(:,:,N),DP(:,:,N),1);
    PolesP=roots(DEN); ZerosP=roots(NUM);
    PRStime=idmodel.sigmoddat(:,1);
    IrespA=impulse(AP(:,:,N),BP(:,:,N),CP(:,:,N),DP(:,:,N),1,PRStime);  %Ideal impulse response
    h=figure; %set up new plot 
    plot(PRStime,[idmodel.sigmoddat(:,2*N) IrespA])
    Ptitle{1}=['Prony fit for ' SigNames(N,:)];
    title(Ptitle)
    xlabel('Time in Seconds')
    h=figure; %set up new plot 
    fstep=0.02; wHz=[0:fstep:2]';   %frequency in Hz
    FrespI=TrfCalcS(NUM,DEN,wHz);
    plot(wHz,db(FrespI))
    Ptitle{1}=['PRS Frequency Response for ' SigNames(N,:)];
    title(Ptitle)
    xlabel('Frequency in Hertz')
    ylabel('Amplitude in dB')
    set(gca,'xlim',[0 2])
  end
  %help ss
  %help LTImodels
  %SYS=SS(AP,BP,CP,DP);
end

if PSMMacro.RunMode<1 
    setok=promptyn('In PRSdisp1: Do you want the keyboard?','n');
    if setok
      disp('  Invoking "keyboard" command - Enter "return" when you are finished')
      keyboard
    end
end

if 0 %Special calls to Ringdown GUI
  InSig=[]; FixedPoles=PRSpoles;
  [maxpoints nsigs]=size(PSMsigsX);
  rgulocs=2:nsigs;  %All signals
  n1=1; timeN=PSMsigsX(:,1);
  swlocs=find(timeN(1:maxpoints-3)==timeN(2:maxpoints-2));
  if ~isempty(swlocs)
    disp(['In PRSdisp1: Time axis indicates ' num2str(length(swlocs)) ' switching  times'])
    n1=max(swlocs); timeN=timeN(n1)+(0:maxpoints-n1)'*tstep;
    disp(['Ringdown analysis delayed to ' num2str(timeN(1)) ' seconds'])
  end
  rguiopts.copyplotfcn='PSMlabl';
  rguiopts.copyplotargs={caseID casetime};
  ringdown([timeN PSMsigsX(n1:maxpoints,rgulocs)],namesX(rgulocs,:),InSig,FixedPoles,rguiopts);
end

return
%end of PSMT utility

