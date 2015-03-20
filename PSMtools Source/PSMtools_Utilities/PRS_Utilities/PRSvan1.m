function [CaseCom,PRSmodel]=...
   PRSvan1(caseID,casetime,CaseCom);
%PRSvan1 solves the Vandermonde equations for multiple signals, 
% given a collection of poles upon which to project
%
% [CaseCom,PRSmodel]=...
%   PRSvan1(caseID,casetime,CaseCom);
%
%  Last modified 02/13/02.   jfh

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


persistent FigDef
if isempty(FigDef), FigDef=1; end

%Clear outputs
PRSmodel=[];

%Check inputs

Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '    casetime=' casetime];
disp(' ')
str='In PRSvan1: EXPERIMENTAL CODE FOR EXTENDING A PRONY SOLUTION ';
str=[str ' TO MULTIPLE SIGNALS'];  %Temporary warning
disp(str)
disp(['In PRSvan1: ' Ptitle{2}]);
 format short %May need diagnostic displays 
%format short %May need diagnostic displays 
%keyboard

%************************************************************************
prompt=['In PRSvan1: Indicate figure number for Prony solution '];
PRSfig=promptnv(prompt,FigDef);
PRSfig=max(PRSfig,1);
disp(['In PRSvan1: PRSfig = ' num2str(PRSfig)])
setok=promptyn('  Is this value ok?', 'y');
if ~setok
  disp('  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end
FigDef=PRSfig;
%************************************************************************

%************************************************************************
%Get PRS parameters, place them in basic order
idmodel=Getmodel(PRSfig,0,1);
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
disp(['In PRSvan1: Full signal names are'])
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
%************************************************************************



setok=promptyn('In PRSvan1: Do you want the keyboard?', 'n');
if setok
  disp('  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end


return
%end of PSMT utility

