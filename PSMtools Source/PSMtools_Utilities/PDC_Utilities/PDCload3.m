function [PMUsigs,PMUfreqs,tstep,PMUnames,PhsrNames,Phsrkey,PDCfiles,nIphsrs,CaseCom]...
   =PDCload3(caseID,PDCfiles,PMUsigs,PMUfreqs,CaseCom,saveopt,trackX,trackPatch,...
    nXfile)
% PDCload3.m retrieves and restructures a PDC data file saved as .mat
%  [PMUsigs,PMUfreqs,tstep,PMUnames,PhsrNames,Phsrkey,PDCfiles,nIphsrs,CaseCom]...
%    =PDCload1(caseID,PDCfiles,PMUsigs,PMUfreqs,CaseCom,saveopt,trackX,trackPatch,...
%     nXfile)
%
% PDCload3.m builds from earlier BPA script scale.m (renamed PDCscale.m)
% Retrieved data is in matlab .mat format; need changes there.
%
% Prototype code for processing phasor measurements data through PSM Tools
% Data source is BPA Phasor Data Concentrator (PDC) Unit #2,
% as configured in Spring 1998.
% Other PDC configurations will need code revisions.
%
% WARNING: Earlier versions have a transpose error in tabling the phasors!
%
% Last modified 09/29/98.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


global Kprompt ynprompt
 
%Conversion Factors 
DEG=180/pi;    %Radians to degrees

disp(['In PDCload3: Seeking data on file  ' PDCfiles])
SaveFile=' ';
%keyboard

Nphsrs=40; NPMUs=7;  %Hardwiring for data base of Spring 1998
nIphsrs=[4 4 4 4 9 4 4]';

%************************************************************************
%Define PMU names
%(temporary logic -- should read from external file)
PMUnames=[
'00 Grand Coulee '; 
'01 John Day     ';
'02 Malin        ';
'03 Colstrip     ';
'04 Big Eddy 230 ';
'05 Big Eddy 500 ';
'06 Sylmar       '];
%************************************************************************

%************************************************************************
%Define detailed phasor names
%(temporary logic -- should read from file 'DitPDC1_Scale.txt')
PhsrNamesT=[
' 0  0 Grand Coulee                     ';
' 0  1 Grand Coulee 500-230 Bank 1      ';
' 0  2 Grand Coulee Hanford             ';
' 0  3 Grand Coulee Schultz 1           ';
' 0  4 Grand Coulee Chief Joseph        ';
' 1  0 John Day                         ';
' 1  1 John Day Power House #1          ';
' 1  2 John Day Power House #2          ';
' 1  3 John Day Power House #3          ';
' 1  4 John Day Power House #4          ';
' 2  0 Malin                            ';
' 2  1 Malin Round Mountain #1          ';
' 2  2 Malin Round Mountain #2          ';
' 2  3 Malin Grizzly #2                 ';
' 2  4 Malin Captain Jack #1            ';
' 3  0 Colstrip                         ';
' 3  1 Colstrip Broadview #1            ';
' 3  2 Colstrip Broadview #2            ';
' 3  3 Colstrip Generator #3            ';
' 3  4 Colstrip Generator #4            ';
' 4  0 Big Eddy 230 kV                  ';
' 4  1 Big Eddy 230 Celilo #3           ';
' 4  2 Big Eddy 230 Celilo #4           ';
' 4  3 Big Eddy 230 Power House #3      ';
' 4  4 Big Eddy 230 Power House #4      ';
' 4  5 Big Eddy 230 Power House #5      ';
' 4  6 Big Eddy 230 Power House #6      ';
' 4  7 Big Eddy 230:500 Banks 2 & 3     ';
' 4  8 Big Eddy 230 Midway #1           ';
' 4  9 Big Eddy 230 Troutdale #1        ';
' 5  0 Big Eddy 500 kV                  ';
' 5  1 Big Eddy 500 Ostrander #1        ';
' 5  2 Big Eddy 500 Celilo #2           ';
' 5  3 Big Eddy 500 Celilo #1           ';
' 5  4 Big Eddy 500 John Day #1 & #2    ';
' 6  0 Sylmar                           ';
' 6  1 Sylmar Rinaldi #1, phases A&C    ';
' 6  2 Sylmar Castaic #1, phases A&C    ';
' 6  3 Sylmar Bank E, phases A&C        ';
' 6  4 Sylmar Sylmar E Converter, normal'];
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
PDCscales(21:25)=[12.113;0.24226;0.24226;0.12113;0.0969];%Big Eddy 230
PDCscales(26:30)=[0.0969;0.09690;0.24226;0.12113;0.0969];%Big Eddy 230
PDCscales(31:35)=[27.254;0.1615;0.24226;0.24226;0.1615]; %Big Eddy 500
PDCscales(36:40)=[7.2688;0.2019;0.2019;0.2019;0.3231];   %Sylmar
%************************************************************************

%************************************************************************
%Retrieve stored phasors
eval(['load ' PDCfiles])
%whos
tstep=1/samplerate;
maxpts=max(size(pmu01phsr00));
maxtime=(maxpts-1)*tstep;
%************************************************************************

%*************************************************************************
%Add documentation to CaseCom
S1=['In PDCload3: PDC File Extracted = ' PDCfiles];
S2=sprintf('Time Step = %10.5f    Max Time = %8.3f', [tstep maxtime]);
CaseCom=str2mat(CaseCom,S1,S2);
%*************************************************************************

%************************************************************************
%Load retrieved data into array PMUsigs
%(NOTE: data should likely have been saved in array form, not as distinct signals)
maxpts=max(size(pmu01phsr00));
PMUsigs=zeros(maxpts,Nphsrs);
PMUsigs(:,01:05)=[pmu00phsr00.' pmu00phsr01.' pmu00phsr02.' pmu00phsr03.' pmu00phsr04.'];
  clear pmu00phsr00 pmu00phsr01 pmu00phsr02 pmu00phsr03 pmu00phsr04
PMUsigs(:,06:10)=[pmu01phsr00.' pmu01phsr01.' pmu01phsr02.' pmu01phsr03.' pmu01phsr04.'];
  clear pmu01phsr00 pmu01phsr01 pmu01phsr02 pmu01phsr03 pmu01phsr04
PMUsigs(:,11:15)=[pmu02phsr00.' pmu02phsr01.' pmu02phsr02.' pmu02phsr03.' pmu02phsr04.'];
  clear pmu02phsr00 pmu02phsr01 pmu02phsr02 pmu02phsr03 pmu02phsr04
PMUsigs(:,16:20)=[pmu03phsr00.' pmu03phsr01.' pmu03phsr02.' pmu03phsr03.' pmu03phsr04.'];
  clear pmu03phsr00 pmu03phsr01 pmu03phsr02 pmu03phsr03 pmu03phsr04
PMUsigs(:,21:25)=[pmu04phsr00.' pmu04phsr01.' pmu04phsr02.' pmu04phsr03.' pmu04phsr04.'];
  clear pmu04phsr00 pmu04phsr01 pmu04phsr02 pmu04phsr03 pmu04phsr04
PMUsigs(:,26:30)=[pmu04phsr05.' pmu04phsr06.' pmu04phsr07.' pmu04phsr08.' pmu04phsr09.'];
  clear pmu04phsr00 pmu04phsr01 pmu04phsr02 pmu04phsr03 pmu04phsr04
PMUsigs(:,31:35)=[pmu05phsr00.' pmu05phsr01.' pmu05phsr02.' pmu05phsr03.' pmu05phsr04.'];
  clear pmu05phsr00 pmu05phsr01 pmu05phsr02 pmu05phsr03 pmu05phsr04
PMUsigs(:,36:40)=[pmu06phsr00.' pmu06phsr01.' pmu06phsr02.' pmu06phsr03.' pmu06phsr04.'];
  clear pmu06phsr00 pmu06phsr01 pmu06phsr02 pmu06phsr03 pmu06phsr04
PMUfreqs=zeros(maxpts,NPMUs);
PMUfreqs=[Freq00' Freq01' Freq02' Freq03' Freq04' Freq05' Freq06'];
  clear Freq00 Freq01 Freq02 Freq03 Freq04 Freq05 Freq06
%************************************************************************

%************************************************************************
%Scale/clean/modify retrieved PMU data
%Patch through blank phasor points 
patchop=1;
for n=1:Nphsrs
	 if trackX
	   disp([sprintf('  Phasor %3.0i',n) ': unpatched'])
	   h=figure, figure(h)  %set up new plot
	   plot(abs(PMUsigs(:,n)))
	   title(PhsrNames(n,:))
	 end
	 BnkLevel=sum(abs(PMUsigs(1:10,n)))/1000;
	 BnkFactor=0.2; patched=0;
	 [PMUsigs(:,n),patched]=PDCpatch1(PMUsigs(:,n),PhsrNames(n,:),patchop,BnkLevel,...
	  BnkFactor,patched,trackPatch);
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
comment=['In PDCload3: Colstrip rotation = ' sprintf('%5.1f',rotation)];
disp(comment)
CaseCom=str2mat(CaseCom,comment);
for n=16:20
	PMUsigs(:,n)=PMUsigs(:,n)*exp(j*rotation/DEG);
end
%Convert Frequency deviations to Hertz
for n=1:NPMUs
	PMUfreqs(:,n)=PMUfreqs(:,n)/1000+60;
end
%************************************************************************

%*************************************************************************
if saveopt  %Invoke utility for saving results
  disp( 'In PDCload3: Invoking utility for saving results')
  disp(['In PDCload3: Data extracted from file  ' PDCfiles])
  ListName='none';
  SaveList=['PMUsigs PMUfreqs tstep PMUnames PhsrNames Phsrkey CaseCom PDCfiles']
  PSMsave
end
%*************************************************************************

disp('Returning from PDCload3')
return

%Phsrkey =
%  1  0  0 Grand Coulee                     
%  2  0  1 Grand Coulee 500-230 Bank 1      
%  3  0  2 Grand Coulee Hanford             
%  4  0  3 Grand Coulee Schultz 1           
%  5  0  4 Grand Coulee Chief Joseph        
%  6  1  0 John Day                         
%  7  1  1 John Day Power House #1          
%  8  1  2 John Day Power House #2          
%  9  1  3 John Day Power House #3          
% 10  1  4 John Day Power House #4          
% 11  2  0 Malin                            
% 12  2  1 Malin Round Mountain #1          
% 13  2  2 Malin Round Mountain #2          
% 14  2  3 Malin Grizzly #2                 
% 15  2  4 Malin Captain Jack #1            
% 16  3  0 Colstrip                         
% 17  3  1 Colstrip Broadview #1            
% 18  3  2 Colstrip Broadview #2            
% 19  3  3 Colstrip Generator #3            
% 20  3  4 Colstrip Generator #4            
% 21  4  0 Big Eddy 230 kV                  
% 22  4  1 Big Eddy 230 Celilo #3           
% 23  4  2 Big Eddy 230 Celilo #4           
% 24  4  3 Big Eddy 230 Power House #3      
% 25  4  4 Big Eddy 230 Power House #4      
% 26  4  5 Big Eddy 230 Power House #5      
% 27  4  6 Big Eddy 230 Power House #6      
% 28  4  7 Big Eddy 230:500 Banks 2 & 3     
% 29  4  8 Big Eddy 230 Midway #1           
% 30  4  9 Big Eddy 230 Troutdale #1        
% 31  5  0 Big Eddy 500 kV                  
% 32  5  1 Big Eddy 500 Ostrander #1        
% 33  5  2 Big Eddy 500 Celilo #2           
% 34  5  3 Big Eddy 500 Celilo #1           
% 35  5  4 Big Eddy 500 John Day #1 & #2    
% 36  6  0 Sylmar                           
% 37  6  1 Sylmar Rinaldi #1, phases A&C    
% 38  6  2 Sylmar Castaic #1, phases A&C    
% 39  6  3 Sylmar Bank E, phases A&C        
% 40  6  4 Sylmar Sylmar E Converter, normal

%RMSkey using PDCcalcA =
%   1 Time                                         
%   2  0  0 Grand Coulee                      VMag 
%   3  0  0 Grand Coulee                      VAngL
%   4  0  0 Grand Coulee                      FreqL
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
%  21  1  0 John Day                          VMag 
%  22  1  0 John Day                          VAngL
%  23  1  0 John Day                          FreqL
%  24  1  1 John Day Power House #1           MW   
%  25  1  1 John Day Power House #1           Mvar 
%  26  1  1 John Day Power House #1           IMag 
%  27  1  1 John Day Power House #1           IAngL
%  28  1  2 John Day Power House #2           MW   
%  29  1  2 John Day Power House #2           Mvar 
%  30  1  2 John Day Power House #2           IMag 
%  31  1  2 John Day Power House #2           IAngL
%  32  1  3 John Day Power House #3           MW   
%  33  1  3 John Day Power House #3           Mvar 
%  34  1  3 John Day Power House #3           IMag 
%  35  1  3 John Day Power House #3           IAngL
%  36  1  4 John Day Power House #4           MW   
%  37  1  4 John Day Power House #4           Mvar 
%  38  1  4 John Day Power House #4           IMag 
%  39  1  4 John Day Power House #4           IAngL
%  40  2  0 Malin                             VMag 
%  41  2  0 Malin                             VAngL
%  42  2  0 Malin                             FreqL
%  43  2  1 Malin Round Mountain #1           MW   
%  44  2  1 Malin Round Mountain #1           Mvar 
%  45  2  1 Malin Round Mountain #1           IMag 
%  46  2  1 Malin Round Mountain #1           IAngL
%  47  2  2 Malin Round Mountain #2           MW   
%  48  2  2 Malin Round Mountain #2           Mvar 
%  49  2  2 Malin Round Mountain #2           IMag 
%  50  2  2 Malin Round Mountain #2           IAngL
%  51  2  3 Malin Grizzly #2                  MW   
%  52  2  3 Malin Grizzly #2                  Mvar 
%  53  2  3 Malin Grizzly #2                  IMag 
%  54  2  3 Malin Grizzly #2                  IAngL
%  55  2  4 Malin Captain Jack #1             MW   
%  56  2  4 Malin Captain Jack #1             Mvar 
%  57  2  4 Malin Captain Jack #1             IMag 
%  58  2  4 Malin Captain Jack #1             IAngL
%  59  3  0 Colstrip                          VMag 
%  60  3  0 Colstrip                          VAngL
%  61  3  0 Colstrip                          FreqL
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
%  78  4  0 Big Eddy 230 kV                   VMag 
%  79  4  0 Big Eddy 230 kV                   VAngL
%  80  4  0 Big Eddy 230 kV                   FreqL
%  81  4  1 Big Eddy 230 Celilo #3            MW   
%  82  4  1 Big Eddy 230 Celilo #3            Mvar 
%  83  4  1 Big Eddy 230 Celilo #3            IMag 
%  84  4  1 Big Eddy 230 Celilo #3            IAngL
%  85  4  2 Big Eddy 230 Celilo #4            MW   
%  86  4  2 Big Eddy 230 Celilo #4            Mvar 
%  87  4  2 Big Eddy 230 Celilo #4            IMag 
%  88  4  2 Big Eddy 230 Celilo #4            IAngL
%  89  4  3 Big Eddy 230 Power House #3       MW   
%  90  4  3 Big Eddy 230 Power House #3       Mvar 
%  91  4  3 Big Eddy 230 Power House #3       IMag 
%  92  4  3 Big Eddy 230 Power House #3       IAngL
%  93  4  4 Big Eddy 230 Power House #4       MW   
%  94  4  4 Big Eddy 230 Power House #4       Mvar 
%  95  4  4 Big Eddy 230 Power House #4       IMag 
%  96  4  4 Big Eddy 230 Power House #4       IAngL
%  97  4  5 Big Eddy 230 Power House #5       MW   
%  98  4  5 Big Eddy 230 Power House #5       Mvar 
%  99  4  5 Big Eddy 230 Power House #5       IMag 
% 100  4  5 Big Eddy 230 Power House #5       IAngL
% 101  4  6 Big Eddy 230 Power House #6       MW   
% 102  4  6 Big Eddy 230 Power House #6       Mvar 
% 103  4  6 Big Eddy 230 Power House #6       IMag 
% 104  4  6 Big Eddy 230 Power House #6       IAngL
% 105  4  7 Big Eddy 230:500 Banks 2 & 3      MW   
% 106  4  7 Big Eddy 230:500 Banks 2 & 3      Mvar 
% 107  4  7 Big Eddy 230:500 Banks 2 & 3      IMag 
% 108  4  7 Big Eddy 230:500 Banks 2 & 3      IAngL
% 109  4  8 Big Eddy 230 Midway #1            MW   
% 110  4  8 Big Eddy 230 Midway #1            Mvar 
% 111  4  8 Big Eddy 230 Midway #1            IMag 
% 112  4  8 Big Eddy 230 Midway #1            IAngL
% 113  4  9 Big Eddy 230 Troutdale #1         MW   
% 114  4  9 Big Eddy 230 Troutdale #1         Mvar 
% 115  4  9 Big Eddy 230 Troutdale #1         IMag 
% 116  4  9 Big Eddy 230 Troutdale #1         IAngL
% 117  5  0 Big Eddy 500 kV                   VMag 
% 118  5  0 Big Eddy 500 kV                   VAngL
% 119  5  0 Big Eddy 500 kV                   FreqL
% 120  5  1 Big Eddy 500 Ostrander #1         MW   
% 121  5  1 Big Eddy 500 Ostrander #1         Mvar 
% 122  5  1 Big Eddy 500 Ostrander #1         IMag 
% 123  5  1 Big Eddy 500 Ostrander #1         IAngL
% 124  5  2 Big Eddy 500 Celilo #2            MW   
% 125  5  2 Big Eddy 500 Celilo #2            Mvar 
% 126  5  2 Big Eddy 500 Celilo #2            IMag 
% 127  5  2 Big Eddy 500 Celilo #2            IAngL
% 128  5  3 Big Eddy 500 Celilo #1            MW   
% 129  5  3 Big Eddy 500 Celilo #1            Mvar 
% 130  5  3 Big Eddy 500 Celilo #1            IMag 
% 131  5  3 Big Eddy 500 Celilo #1            IAngL
% 132  5  4 Big Eddy 500 John Day #1 & #2     MW   
% 133  5  4 Big Eddy 500 John Day #1 & #2     Mvar 
% 134  5  4 Big Eddy 500 John Day #1 & #2     IMag 
% 135  5  4 Big Eddy 500 John Day #1 & #2     IAngL
% 136  6  0 Sylmar                            VMag 
% 137  6  0 Sylmar                            VAngL
% 138  6  0 Sylmar                            FreqL
% 139  6  1 Sylmar Rinaldi #1, phases A&C     MW   
% 140  6  1 Sylmar Rinaldi #1, phases A&C     Mvar 
% 141  6  1 Sylmar Rinaldi #1, phases A&C     IMag 
% 142  6  1 Sylmar Rinaldi #1, phases A&C     IAngL
% 143  6  2 Sylmar Castaic #1, phases A&C     MW   
% 144  6  2 Sylmar Castaic #1, phases A&C     Mvar 
% 145  6  2 Sylmar Castaic #1, phases A&C     IMag 
% 146  6  2 Sylmar Castaic #1, phases A&C     IAngL
% 147  6  3 Sylmar Bank E, phases A&C         MW   
% 148  6  3 Sylmar Bank E, phases A&C         Mvar 
% 149  6  3 Sylmar Bank E, phases A&C         IMag 
% 150  6  3 Sylmar Bank E, phases A&C         IAngL
% 151  6  4 Sylmar Sylmar E Converter, normal MW   
% 152  6  4 Sylmar Sylmar E Converter, normal Mvar 
% 153  6  4 Sylmar Sylmar E Converter, normal IMag 
% 154  6  4 Sylmar Sylmar E Converter, normal IAngL

%end of PSM script
