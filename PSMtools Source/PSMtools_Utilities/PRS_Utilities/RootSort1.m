function [RootsN,SortType,RootCatsN,RootCatNames,RootLocs]=...
  RootSort1(Roots0,SortType,SortTrack);
%RootSort1 sorts poles & zeros according to SortType 
%
% [Roots,Zeros,SortType,RootCats,RootCatNames,RootLocs]=...
%   RootSort1(Roots0,SortType,SortTrack);
%
%  Last modified 05/21/03.   jfh
%  Modified 10/18/2006  by Ning Zhou to add macro function
%  

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


%Clear outputs

%Check inputs

%----------------------------------------------------
% Begin: Macro definition ZN 10/18/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 10/18/06
%----------------------------------------------------

if ~exist('SortType'),  SortType=1;  end
if ~exist('SortTrack'), SortTrack=0; end
if ~exist('Roots0'),    Roots0  =[]; end

if SortTrack
  disp(' ')
  strs= 'In RootSort1:';
  strs=str2mat(strs, ['   SortType  = ' num2str(SortType)]); 
  strs=str2mat(strs, ['   SortTrack = ' num2str(SortTrack)]); 
  disp(strs)
  %keyboard
end

%Initialize outputs
RootsN=Roots0;RootCatsN=[];RootCatNames='';RootLocs=[]; 
RootCats=[]; 

%Determine if sorting is desired
if length(Roots0)==0|SortType<=0
  disp('In RootSort1: No sorting done -- Returning')
  return
end

%Save original input data
Roots=Roots0;

%*************************************************************************
%Test complex pairing of roots
%Determine if -jw roots are present
RootsV=[real(Roots) imag(Roots)];  %Convert to real vectors
locsP=find(RootsV(:,2)>0); locsN=find(RootsV(:,2)<0); 
HalfPoles=1; 
if length(locsP)==length(locsN)
  HalfPoles=0; %-jw roots are present
  PNtest=find(locsN~=locsP+1);
  if ~isempty(PNtest)
    disp('In RootSort1: Problems with complex root pairing')
    disp([locsP locsN])
    disp('  Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
end
%*************************************************************************

%*************************************************************************
%Categorize roots
%Root categories:
% 1) Simple trends:             0==freq                         
% 2) Oscillatory trends:        0< freq< FLIM2 & DLIM1<=PUdamp   
% 3) Interarea oscillations:    0< freq<=FLIM1 &     0< PUdamp< DLIM1   
% 4) Local oscillations:    FLIM1<=freq< FLIM2 &     0< PUdamp< DLIM1   
% 5) Unstable oscillations:     0< freq< FLIM2 &        PUdamp<=0   
% 6) Fast noise:            FLIM2<=freq    
RootCatNames=str2mat('Simple trend ','Oscillatory trend','Interarea oscillation');
RootCatNames=str2mat(RootCatNames,'Local oscillation','Unstable oscillation');
RootCatNames=str2mat(RootCatNames,'Fast noise');
FLIM1=1.0; DLIM1=0.15; %Maximum frequency & damping for interarea oscillation 
FLIM2=1.8; DLIM2=0.15; %(DLIM2 not used yet) 

%----------------------------------------------------
% Begin: Macro selection ZN 10/18/06
%keyboard;
if ~isfield(PSMMacro, 'RootSort1_FLIM1'), PSMMacro.RootSort1_FLIM1=NaN; end
if ~isfield(PSMMacro, 'RootSort1_FLIM2'), PSMMacro.RootSort1_FLIM2=NaN; end
if ~isfield(PSMMacro, 'RootSort1_DLIM1'), PSMMacro.RootSort1_DLIM1=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.RootSort1_FLIM1))      % Not in Macro playing mode or selection not defined in a macro
    if SortTrack
      disp( 'In RootSort1: Category parameters are')
      disp(['   FLIM1=' sprintf('%6.3f',FLIM1) '  DLIM1=' sprintf('%6.4f',DLIM1)])
      disp(['   FLIM2=' sprintf('%6.3f',FLIM2)])
      setok=promptyn('In RootSort1: Are these values ok?', 'y');
      if ~setok
        disp('  Invoking "keyboard" command - Enter "return" when you are finished')
        keyboard
      end
    end
else
    FLIM1=PSMMacro.RootSort1_FLIM1;
    FLIM2=PSMMacro.RootSort1_FLIM2;
    DLIM1=PSMMacro.RootSort1_DLIM1;
end

if PSMMacro.RunMode==0      % if in macro record mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.RootSort1_FLIM1=FLIM1;
        PSMMacro.RootSort1_FLIM2=FLIM2;
        PSMMacro.RootSort1_DLIM1=DLIM1;
    else
        PSMMacro.RootSort1_FLIM1=NaN;
        PSMMacro.RootSort1_FLIM2=NaN;
        PSMMacro.RootSort1_DLIM1=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 10/18/06
%----------------------------------------------------


nRoots=size(RootsV,1); RootCats=zeros(nRoots,1);
for N=1:nRoots
  sigma=RootsV(N,1); omd=RootsV(N,2); freq=abs(omd/(2*pi));
  PUdamp=-sigma/sqrt(sigma*sigma+omd*omd);
  if               (freq< FLIM2)&(DLIM1<=PUdamp)          , RootCats(N)=2; end 
  if               (freq<=FLIM1)&(0<PUdamp)&(PUdamp<DLIM1), RootCats(N)=3; end 
  if (FLIM1<=freq)&(freq< FLIM2)&(0<PUdamp)&(PUdamp<DLIM1), RootCats(N)=4; end 
  if               (freq<FLIM2 )&(PUdamp<=0)              , RootCats(N)=5; end 
  if               (FLIM2<=freq)                          , RootCats(N)=6; end 
  if (freq==0    )                                        , RootCats(N)=1; end 
  %[N freq PUdamp RootCats(N)]
end
RootCats0=RootCats;
%*************************************************************************

%*************************************************************************
if SortTrack
  disp('In RootSort1: Type 1 sort');
  disp('Roots ordered by ascending frequency, real roots first')
end 
%Order real Roots
locs0=find(RootsV(:,2)==0); reals=length(locs0); 
if reals>0
  [RRoots,locsR]=sortrows(-RootsV(locs0,:),1);
  locs0=locs0(locsR);
end
%Order complex roots
imags=length(locsP);
if imags>0
  [IRoots,locsI]=sortrows(RootsV(locsP,:),2);
  locsP=locsP(locsI);
end
%Determine root locations after type 1 sort
NewLocs=[locs0' locsP'];
if ~HalfPoles
  NewLocs=locs0';
  for I=1:length(locsP)
    NewLocs=[NewLocs locsP(I) locsP(I)+1];
  end
  NewLocs=NewLocs';
end
RootLocs1=NewLocs; 
RootsN1=Roots0(RootLocs1);
RootCatsN1=RootCats0(RootLocs1);
RootLocs=RootLocs1;
RootsN=RootsN1;
RootCatsN=RootCatsN1;
%*************************************************************************

if SortTrack
  disp('In RootSort1: Type 1 sorting done')
  if PSMMacro.RunMode<1 
      setok=promptyn('In RootSort1: Do you want the keyboard?', 'n');
      if setok
        disp('  Invoking "keyboard" command - Enter "return" when you are finished')
        keyboard
        %disp(names2chans(RootCatNames))
        %disp([RootsN/(2*pi) RootCatsN)
        %disp(names2chans(RootCatNames))
      end
  end
end
if SortType<2
  if SortTrack, disp('Return from RootSort1'); end
  return
end

%*************************************************************************
if SortTrack
  disp('In RootSort1: Type 2 sort');
  disp('Roots ordered by category, real roots first')
end
%Determine root locations after type 2 sort
%JeffJ will laugh at this, but then it's just draft code
Roots=RootsN1; RootCats=RootCatsN1;
locs1=find(RootCats==1); locs2=find(RootCats==2);
locs3=find(RootCats==3); locs4=find(RootCats==4);
locs5=find(RootCats==5); locs6=find(RootCats==6);
locsP=[locs2' locs3' locs4' locs5' locs6'];
NewLocs=[locs1' locsP]';
RootsN2=RootsN1(NewLocs);
RootCatsN2=RootCatsN1(NewLocs);
RootLocs2=RootLocs1(NewLocs); 
RootsN=Roots0(RootLocs2);
RootCatsN=RootCats0(RootLocs2);
RootLocs=RootLocs2;
%disp([RootsN/(2*pi) RootCats RootCatsN]) 
%*************************************************************************

if size(RootsN2,1)~=size(RootsN1)
  disp('In RootSort1: Missing category in type 2 sorting')
  disp('  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end

if SortTrack
  disp('In RootSort1: Type 2 sorting done')
  setok=promptyn('In RootSort1: Do you want the keyboard?', 'n');
  if setok
    disp('  Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
  end
end

disp('Return from RootSort1')
return

%end of PSMT function
