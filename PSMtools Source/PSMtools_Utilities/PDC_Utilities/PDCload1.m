function [PMUsigs,PMUfreqs,tstep,PMUnames,PhsrNames,Phsrkey,PDCfileX,nIphsrs,CaseCom]...
   =PDCload1(caseID,PDCfileX,PMUsigs,PMUfreqs,CaseCom,saveopt,trackX,trackPatch,...
    nXfile)
% PDCload1.m retrieves and restructures a PDC data file saved as .mat
%  [PMUsigs,PMUfreqs,tstep,PMUnames,PhsrNames,Phsrkey,PDCfileX,nIphsrs,CaseCom]...
%    =PDCload1(caseID,PDCfileX,PMUsigs,PMUfreqs,CaseCom,saveopt,trackX,trackPatch,...
%     nXfile)
%
% PDCload1.m builds from earlier BPA script scale.m (renamed PDCscale.m)
% Retrieved data is in matlab .mat format; need changes there.
%
% Prototype code for processing phasor measurements data through PSM Tools
% Data source is BPA Phasor Data Concentrator (PDC) Unit #1,
% as specially configured on 09/04/97 (temporary access to Sylmar PMU).
% Other PDC configurations will need code revisions.
%
% WARNING: Earlier versions have a transpose error in tabling the phasors!
%
% Last modified 05/22/01.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


%Global controls on prompt defaults
global Kprompt ynprompt nvprompt

global CFname initext
global PMUtags PMUnames PhsrNames VIcon MatFmt

%Local variables to reuse
persistent BnkLevelPU BnkFactor
persistent PatchMode LogPatch PlotPatch
 
%Conversion Factors 
r2deg=180/pi;    %Radians to degrees

S1=['In PDCload1: Seeking data on file  ' PDCfileX];
disp(S1)
SaveFile=' ';
%keyboard

Nphsrs=25; NPMUs=5;  %Hardwiring for PDC1 configuration of of 09/04/97
nIphsrs=[4 4 4 4 4]';

%************************************************************************
%Define PMU names
%(temporary logic -- should read from external file)
PMUnames=[
'00 Grand Coulee '; 
'01 John Day     ';
'02 Malin        ';
'03 Colstrip     ';
'06 Sylmar       '];
%************************************************************************

%************************************************************************
%Define detailed phasor names
%(temporary logic -- should read from file 'DitPDC1_Scale.txt')
PhsrNamesT=[
' 0  0 Grand Coulee Hanford Voltage     ';
' 0  1 Grand Coulee 500-230 Bank 1      ';
' 0  2 Grand Coulee Hanford             ';
' 0  3 Grand Coulee Schultz 1           ';
' 0  4 Grand Coulee Chief Joseph        ';
' 1  0 John Day Grizzly #1 Line Voltage ';
' 1  1 John Day Grizzly #1              ';
' 1  2 John Day Not used                ';
' 1  3 John Day Not used                ';
' 1  4 John Day Not used                ';
' 2  0 Malin North Bus Voltage          ';
' 2  1 Malin Round Mountain #1          ';
' 2  2 Malin Round Mountain #2          ';
' 2  3 Malin Grizzly #2 Line            ';
' 2  4 Malin Captain Jack #1            ';
' 3  0 Colstrip North Bus               ';
' 3  1 Colstrip Broadview #1            ';
' 3  2 Colstrip Broadview #2            ';
' 3  3 Colstrip Generator #3            ';
' 3  4 Colstrip Generator #4            ';
' 5  0 Sylmar 230 kV bus #1             ';
' 5  1 Sylmar Rinaldi #1, phases A&C    ';
' 5  2 Sylmar Castaic #1, phases A&C    ';
' 5  3 Sylmar Bank E, phases A&C        ';
' 5  4 Sylmar Sylmar E Converter, normal'];
%************************************************************************

%************************************************************************
%Define phasor key
%(temporary logic?  Might read from external file)
text1=[PhsrNamesT(2,:)];
chars1=size(text1,2);
text2=['% ' sprintf('%2.0i',10) ' ' text1];
chars2=size(text2,2);
Phsrkey=''; PhsrNames='';
loc=1; 
for N=1:NPMUs
  for nchan=0:nIphsrs(N)
	  nPMU=N-1;
    text1=[PhsrNamesT(loc,:)];
	  text2=['% ' sprintf('%2.0i',loc) ' ' text1];
    PhsrNames(loc,1:chars1)=text1;
	  Phsrkey(loc,1:chars2)=text2;
	  loc=loc+1;
  end
end
%************************************************************************

%************************************************************************
%Define phasor scaling
%(temporary logic -- should read from file 'DitPDC1_Scale.txt')
PDCscales=zeros(Nphsrs,1);
PDCscales(01:05)=[27.254;0.1615;0.1615;0.24226;0.1615];  %Coulee
PDCscales(06:10)=[15.141;0.1615;1.0;1.0;1.0];            %John Day
PDCscales(11:15)=[27.254;0.24226;0.24226;0.1615;0.1615]; %Malin
PDCscales(16:20)=[27.254;0.1615;0.1615;0.08883;0.08883]; %Colstrip
PDCscales(21:25)=[7.2688;0.2019;0.2019;0.2019;0.3231];   %Sylmar
%************************************************************************

%************************************************************************
%Retrieve stored phasors
eval(['load ' PDCfileX])
%whos
tstep=1/samplerate;
maxpts=max(size(pmu00phsr00));
maxtime=(maxpts-1)*tstep;
%************************************************************************

%*************************************************************************
%Add documentation to CaseCom
S1=['In PDCload1: PDC File Extracted = ' PDCfileX];
S2=sprintf('Time Step = %10.5f    Max Time = %8.3f', [tstep maxtime]);
CaseCom=str2mat(CaseCom,S1,S2);
%*************************************************************************

%************************************************************************
%Load retrieved data into array PMUsigs
%(NOTE: data should likely have been saved in array form, not as distinct signals)
maxpts=max(size(pmu00phsr00));
PMUsigs=zeros(maxpts,Nphsrs);
PMUsigs(:,01:05)=[pmu00phsr00.' pmu00phsr01.' pmu00phsr02.' pmu00phsr03.' pmu00phsr04.'];
clear pmu00phsr00 pmu00phsr01 pmu00phsr02 pmu00phsr03 pmu00phsr04
PMUsigs(:,06:10)=[pmu01phsr00.' pmu01phsr01.' pmu01phsr02.' pmu01phsr03.' pmu01phsr04.'];
clear pmu01phsr00 pmu01phsr01 pmu01phsr02 pmu01phsr03 pmu01phsr04
PMUsigs(:,11:15)=[pmu02phsr00.' pmu02phsr01.' pmu02phsr02.' pmu02phsr03.' pmu02phsr04.'];
clear pmu02phsr00 pmu02phsr01 pmu02phsr02 pmu02phsr03 pmu02phsr04
PMUsigs(:,16:20)=[pmu03phsr00.' pmu03phsr01.' pmu03phsr02.' pmu03phsr03.' pmu03phsr04.'];
clear pmu03phsr00 pmu03phsr01 pmu03phsr02 pmu03phsr03 pmu03phsr04
PMUsigs(:,21:25)=[pmu05phsr00.' pmu05phsr01.' pmu05phsr02.' pmu05phsr03.' pmu05phsr04.'];
clear pmu05phsr00 pmu05phsr01 pmu05phsr02 pmu05phsr03 pmu05phsr04
PMUfreqs=zeros(maxpts,NPMUs);
PMUfreqs=[Freq00' Freq01' Freq02' Freq03' Freq05'];
clear Freq00 Freq01 Freq02 Freq03 Freq05
%************************************************************************

%************************************************************************
%Scale/clean/modify retrieved PMU data
%Patch through blank phasor points 
%Scale signals, patch through defective points
%Rotate phasors as needed
disp(' ')
disp('In PDCload1: Scaling phasors & scanning for data outliers:')
if nXfile==1
  LogPatch=0; PlotPatch=0;
  BnkLevelPU=0.001; BnkFactor=0.2;
  PatchMode=1;
  if PatchMode
    LogPatch =promptyn('In PDCload1: Display full patching log? ', 'n');
    PlotPatch=promptyn('In PDCload1: Plot patched signals? ', 'n');
    str1='In PDCload1: Patching across outliers in phasor data';
    setok=0; maxtrys=10;
    for i=1:maxtrys
      if ~setok
        str1=sprintf('In PDCload1: Percent BlankLevel  is BnkLevelPU =%5.3f',BnkLevelPU); 
        str2=sprintf('             Percent BlankFactor is BnkFactor  =%5.3f',BnkFactor);
        str3=       ['             PlotPatch Control   is PlotPatch  = ' num2str(PlotPatch)];
        str4=       ['             LogPatch  Control   is LogPatch   = ' num2str(LogPatch)];
        str5=       ['             Patching  Control   is PatchMode  = ' num2str(PatchMode)];
        disp(str2mat(str1,str2,str3,str4,str5));
	     setok=promptyn('In PDCload1: Are these values ok? ', 'y');
        if ~setok
	       disp('Invoking "keyboard" command - Enter "return" when you are finished')
          keyboard
        end
      end
    end
    if ~setok
      disp(sprintf('Sorry -%5i chances is all you get!',maxtrys));
      disp('Reverting to default values')
      BnkLevelPU=0.001; BnkFactor=0.2;
    end
    str1=sprintf('In PDCload1: Percent BlankLevel  is BnkLevelPU =%5.3f',BnkLevelPU); 
    str2=sprintf('             Percent BlankFactor is BnkFactor  =%5.3f',BnkFactor);
    CaseCom=str2mat(CaseCom,str1,str2); disp(str1); disp(str2)
  end
end
i=sqrt(-1);
patchop=1; 
Npatched=0; MaxBnkPts=0; Defectives=0;
for n=1:Nphsrs
	 if trackX
	   disp([sprintf('  Phasor %3.0i',n) ': unpatched'])
	   h=figure    %set up new plot
	   plot(abs(PMUsigs(:,n)))
	   title(PhsrNames(n,:))
	 end
	 BnkLevel=sum(abs(PMUsigs(1:10,n)))/1000;
	 BnkFactor=0.2; patched=0;
	 [PMUsigs(:,n),patched,BnkPts,PlotNo]=PDCpatch2(PMUsigs(:,n),PhsrNames(n,:),...
     patchop,BnkLevel,BnkFactor,patched,LogPatch,PlotPatch);
	 if patched>0
	   disp([sprintf('   n =%3.0i',n) ': Patched signal is ' PhsrNames(n,:)])
	   disp('Pause to examine display - to continue, press any key')
	   pause
	 end
	 if patched<0
	   disp([sprintf('   n =%3.0i',n) ': Defective signal is ' PhsrNames(n,:)])
	 end
     if trackX, pause, end
end
%Scale phasors
for n=1:Nphsrs
	PMUsigs(:,n)=PMUsigs(:,n)*PDCscales(n);
end
%Compensate Colstrip transposition
rotation=-120;  %Nominal correction
comment=['In PDCload1: Colstrip rotation = ' sprintf('%5.1f',rotation)];
disp(comment)
CaseCom=str2mat(CaseCom,comment);
for n=16:20
	PMUsigs(:,n)=PMUsigs(:,n)*exp(j*rotation/r2deg);
end
%Convert Frequency deviations to Hertz
for n=1:NPMUs
	PMUfreqs(:,n)=PMUfreqs(:,n)/1000+60;
end
%************************************************************************

%keyboard

%*************************************************************************
if saveopt  %Invoke utility for saving results
  disp( 'In PDCload1: Invoking utility for saving results')
  disp(['In PDCload1: Data extracted from file  ' PDCfileX])
  ListName='none';
  SaveList=['PMUsigs PMUfreqs tstep PMUnames PhsrNames Phsrkey CaseCom PDCfileX']
  PSMsave
end
%*************************************************************************

disp('Returning from PDCload1')
return

%Phsrkey =
%  1  0  0 Grand Coulee Hanford Voltage     
%  2  0  1 Grand Coulee 500-230 Bank 1      
%  3  0  2 Grand Coulee Hanford             
%  4  0  3 Grand Coulee Schultz 1           
%  5  0  4 Grand Coulee Chief Joseph        
%  6  1  0 John Day Grizzly #1 Line Voltage 
%  7  1  1 John Day Grizzly #1              
%  8  1  2 John Day Not used                
%  9  1  3 John Day Not used                
% 10  1  4 John Day Not used                
% 11  2  0 Malin North Bus Voltage          
% 12  2  1 Malin Round Mountain #1          
% 13  2  2 Malin Round Mountain #2          
% 14  2  3 Malin Grizzly #2 Line            
% 15  2  4 Malin Captain Jack #1            
% 16  3  0 Colstrip North Bus               
% 17  3  1 Colstrip Broadview #1            
% 18  3  2 Colstrip Broadview #2            
% 19  3  3 Colstrip Generator #3            
% 20  3  4 Colstrip Generator #4            
% 21  5  0 Sylmar 230 kV bus #1             
% 22  5  1 Sylmar Rinaldi #1, phases A&C    
% 23  5  2 Sylmar Castaic #1, phases A&C    
% 24  5  3 Sylmar Bank E, phases A&C        
% 25  5  4 Sylmar Sylmar E Converter, normal

%RMSkey using PDCcalcA =
%   1 Time                                         
%   2  0  0 Grand Coulee Hanford Voltage      VMag 
%   3  0  0 Grand Coulee Hanford Voltage      VAngL
%   4  0  0 Grand Coulee Hanford Voltage      FreqL
%   5  0  1 Grand Coulee 500-230 Bank 1       MW   
%   6  0  1 Grand Coulee 500-230 Bank 1       Mvar 
%   7  0  1 Grand Coulee 500-230 Bank 1       IMag 
%   8  0  1 Grand Coulee 500-230 Bank 1       IAngL
%   9  0  2 Grand Coulee Hanford              MW   
%  10  0  2 Grand Coulee Hanford              Mvar 
%  11  0  2 Grand Coulee Hanford              IMag 
%  12  0  2 Grand Coulee Hanford              IAngL
%  13  0  3 Grand Coulee Schultz 1            MW   
%  14  0  3 Grand Coulee Schultz 1            Mvar 
%  15  0  3 Grand Coulee Schultz 1            IMag 
%  16  0  3 Grand Coulee Schultz 1            IAngL
%  17  0  4 Grand Coulee Chief Joseph         MW   
%  18  0  4 Grand Coulee Chief Joseph         Mvar 
%  19  0  4 Grand Coulee Chief Joseph         IMag 
%  20  0  4 Grand Coulee Chief Joseph         IAngL
%  21  1  0 John Day Grizzly #1 Line Voltage  VMag 
%  22  1  0 John Day Grizzly #1 Line Voltage  VAngL
%  23  1  0 John Day Grizzly #1 Line Voltage  FreqL
%  24  1  1 John Day Grizzly #1               MW   
%  25  1  1 John Day Grizzly #1               Mvar 
%  26  1  1 John Day Grizzly #1               IMag 
%  27  1  1 John Day Grizzly #1               IAngL
%  28  1  2 John Day Not used                 MW   
%  29  1  2 John Day Not used                 Mvar 
%  30  1  2 John Day Not used                 IMag 
%  31  1  2 John Day Not used                 IAngL
%  32  1  3 John Day Not used                 MW   
%  33  1  3 John Day Not used                 Mvar 
%  34  1  3 John Day Not used                 IMag 
%  35  1  3 John Day Not used                 IAngL
%  36  1  4 John Day Not used                 MW   
%  37  1  4 John Day Not used                 Mvar 
%  38  1  4 John Day Not used                 IMag 
%  39  1  4 John Day Not used                 IAngL
%  40  2  0 Malin North Bus Voltage           VMag 
%  41  2  0 Malin North Bus Voltage           VAngL
%  42  2  0 Malin North Bus Voltage           FreqL
%  43  2  1 Malin Round Mountain #1           MW   
%  44  2  1 Malin Round Mountain #1           Mvar 
%  45  2  1 Malin Round Mountain #1           IMag 
%  46  2  1 Malin Round Mountain #1           IAngL
%  47  2  2 Malin Round Mountain #2           MW   
%  48  2  2 Malin Round Mountain #2           Mvar 
%  49  2  2 Malin Round Mountain #2           IMag 
%  50  2  2 Malin Round Mountain #2           IAngL
%  51  2  3 Malin Grizzly #2 Line             MW   
%  52  2  3 Malin Grizzly #2 Line             Mvar 
%  53  2  3 Malin Grizzly #2 Line             IMag 
%  54  2  3 Malin Grizzly #2 Line             IAngL
%  55  2  4 Malin Captain Jack #1             MW   
%  56  2  4 Malin Captain Jack #1             Mvar 
%  57  2  4 Malin Captain Jack #1             IMag 
%  58  2  4 Malin Captain Jack #1             IAngL
%  59  3  0 Colstrip North Bus                VMag 
%  60  3  0 Colstrip North Bus                VAngL
%  61  3  0 Colstrip North Bus                FreqL
%  62  3  1 Colstrip Broadview #1             MW   
%  63  3  1 Colstrip Broadview #1             Mvar 
%  64  3  1 Colstrip Broadview #1             IMag 
%  65  3  1 Colstrip Broadview #1             IAngL
%  66  3  2 Colstrip Broadview #2             MW   
%  67  3  2 Colstrip Broadview #2             Mvar 
%  68  3  2 Colstrip Broadview #2             IMag 
%  69  3  2 Colstrip Broadview #2             IAngL
%  70  3  3 Colstrip Generator #3             MW   
%  71  3  3 Colstrip Generator #3             Mvar 
%  72  3  3 Colstrip Generator #3             IMag 
%  73  3  3 Colstrip Generator #3             IAngL
%  74  3  4 Colstrip Generator #4             MW   
%  75  3  4 Colstrip Generator #4             Mvar 
%  76  3  4 Colstrip Generator #4             IMag 
%  77  3  4 Colstrip Generator #4             IAngL
%  78  5  0 Sylmar 230 kV bus #1              VMag 
%  79  5  0 Sylmar 230 kV bus #1              VAngL
%  80  5  0 Sylmar 230 kV bus #1              FreqL
%  81  5  1 Sylmar Rinaldi #1, phases A&C     MW   
%  82  5  1 Sylmar Rinaldi #1, phases A&C     Mvar 
%  83  5  1 Sylmar Rinaldi #1, phases A&C     IMag 
%  84  5  1 Sylmar Rinaldi #1, phases A&C     IAngL
%  85  5  2 Sylmar Castaic #1, phases A&C     MW   
%  86  5  2 Sylmar Castaic #1, phases A&C     Mvar 
%  87  5  2 Sylmar Castaic #1, phases A&C     IMag 
%  88  5  2 Sylmar Castaic #1, phases A&C     IAngL
%  89  5  3 Sylmar Bank E, phases A&C         MW   
%  90  5  3 Sylmar Bank E, phases A&C         Mvar 
%  91  5  3 Sylmar Bank E, phases A&C         IMag 
%  92  5  3 Sylmar Bank E, phases A&C         IAngL
%  93  5  4 Sylmar Sylmar E Converter, normal MW   
%  94  5  4 Sylmar Sylmar E Converter, normal Mvar 
%  95  5  4 Sylmar Sylmar E Converter, normal IMag 
%  96  5  4 Sylmar Sylmar E Converter, normal IAngL

%end of PSM script
