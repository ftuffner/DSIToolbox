function [chansMenu,chansS]=PPSMmenu(chansMenu,chansS,CFname,nsigs)   
%
%  [chansMenu,chansS]=PPSMmenu(chansMenu,chansS,CFname,nsigs);
%
% Defines convenience menus for processing signals from particular
% PPSM units, as identified by their DAS listing names.
%
% Special functions used:
%   promptyn
%
%  Last modified 04/14/03.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

disp(['In PPSMmenu: CFname = ' CFname])

%*************************************************************************
%help uigetfile
%setok=promptyn('In PPSMmenu: Load signal extraction menus from text file? ', 'n');
%if setok
  %(use uigetfile)
%end
%*************************************************************************


%********************* List of known channel keys ********************

%*************************************************************************
%Menus for Dittmer Listings #9, #14, #16, #18, #20
MatchName1='dittmer #9 listing'; MatchName2='dittmer #14 listing';
MatchName3='dittmer #16 listing';MatchName4='dittmer #17 listing';
MatchName5='dittmer #18 listing';MatchName6='dittmer #20 listing';
MatchName7='dittmer #21 listing';MatchName8='dittmer listing 02-01-2002';

%REPLACE THIS WITH A FOR LOOP
match1=~isempty(findstr(MatchName1,lower(CFname)));
match2=~isempty(findstr(MatchName2,lower(CFname)));
match3=~isempty(findstr(MatchName3,lower(CFname)));
match4=~isempty(findstr(MatchName4,lower(CFname)));
match5=~isempty(findstr(MatchName5,lower(CFname)));
match6=~isempty(findstr(MatchName6,lower(CFname)));
match7=~isempty(findstr(MatchName7,lower(CFname)));
match8=~isempty(findstr(MatchName8,lower(CFname)));
if match1|match2|match3|match4|match5|match6|match7|match8
disp(['In PPSMmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'Ringdown Summary');
chansS=str2mat(chansS,'[9 3 33 34 21 24 25 37 31 6 5 11]');
chansMenu=str2mat(chansMenu,'Interactions Summary');
chansS=str2mat(chansS,'[9 3 33 34 37 31 3 6 5 11 9 10 82 84 19 20 21 23 24 25 55 56]');
chansMenu=str2mat(chansMenu,'BigView summary');
chansS=str2mat(chansS,'[9 3 6 5 9 36 38 33 34 21 24 25 18 26 56 71]');
chansMenu=str2mat(chansMenu,'Long Dynamics Summary');
chansS=str2mat(chansS,'[9 3 6 5 9 10 11 34 33 19 20 21 23 24 25 17 18 4 30 36 37 81 82 83]');
chansMenu=str2mat(chansMenu,'Generation Summary');
chansS=str2mat(chansS,'[9 3 6 5 9 10 50:65]');
chansMenu=str2mat(chansMenu,'AGC Summary');
chansS=str2mat(chansS,'[9 3 6 5 9 78:79 86:96]');
chansMenu=str2mat(chansMenu,'Montana Summary');
chansS=str2mat(chansS,'[9 3 6 5 9 16 20:25 59 58 57]');
chansMenu=str2mat(chansMenu,'Idaho Summary');
chansS=str2mat(chansS,'[9 3 6 5 9 71 18 19 26 32 24 25 48 58 54]');
chansMenu=str2mat(chansMenu,'Tacoma Summary');
chansS=str2mat(chansS,'[9 3 6 5 9 7 8]');
chansMenu=str2mat(chansMenu,'BPA DataPost');
chansS=str2mat(chansS,'[9 33 34 21 24 25 37 31 7 8 3 6 5 11 86:91]');
end
%*********************************************************************

return

%********************* List of known channel keys ********************

%*********************************************************************
%chankey for Dittmer #16
%   time                                             
%   001    0  BPA Net Actual Interchange MW (MW)     
%   002    1  Time Tick (Reference) (Volts)          
%   003    2  Dittmer System Frequency (Hz)          
%   004    3  AGC TieLine Bias (MW)                  
%   005    4  Tacoma 230 kV Bus Voltage (kV)         
%   006    5  Tacoma 230 kV - Bus Frequency (Hz)     
%   007    6  Tacoma NE 1-2-3 MW (MW)                
%   008    7  Tacoma NE 1-2-3 MVar (MVar)            
%   009    8  Malin-Round Mountain #1 MW (MW)        
%   010    9  Malin-Round Mountain #1 MVar (MVar)    
%   011   10  Malin N.Bus kV (kV)                    
%   012   11  Malin-Round Mountain #2 MW (MW)        
%   013   12  Malin-Round Mountain #2 MVar (MVar)    
%   014   13  Malin S.Bus kV (kV)                    
%   015   14  Garrison 500 kV Bus East (kV)          
%   016   15  Garrison 500 kV Bus West (kV)          
%   017   16  Custer 500 kV Bus Voltage (kV)         
%   018   17  IPC Lagrande MW (MW)                   
%   019   18  IPC Harney MW (MW)                     
%   020   19  Hot Springs E-W Tie MW (MW)            
%   021   20  MPC Garrison 500 kV MW (MW)            
%   022   21  MPC Kerr MW (MW)                       
%   023   22  MPC Broadview 500 kV MW (MW)           
%   024   23  MPC Anaconda MW (MW)                   
%   025   24  MPC Garrison 230 kV MW (MW)            
%   026   25  PPL E-W Tie Idaho Sum MW (MW)          
%   027   26  PSPL Covington MW (MW)                 
%   028   27  PSPL Maple Valley MW (MW)              
%   029   28  PSPL Bellingham MW (MW)                
%   030   29  PSPL Snohomish MW (MW)                 
%   031   30  LADWP Celilo 500 kV MW (MW)            
%   032   31  PPL Summer Lake (Grizzly) MW (MW)      
%   033   32  BCH Custer MW (MW)                     
%   034   33  BCH Boundary MW (MW)                   
%   035   34  BCH Ingledow MW (MW)                   
%   036   35  PG&E Malin Sum MW (MW)                 
%   037   36  LADWP Celilo 230 kV MW (MW)            
%   038   37  LADWP Sylmar Sum MW (MW)               
%   039   38  E-W Tie Burke Thompson MW (MW)         
%   040   39  Monroe-Chief Joe Line Load MW (MW)     
%   041   40  Snohomish-Chief Joe Line Load MW (MW)  
%   042   41  ChelanRR-Maple Valley Line Load MW (MW)
%   043   42  Sickler-Schultz Line Load MW (MW)      
%   044   43  Vantage-Schultz Line Load MW (MW)      
%   045   44  Ostrander-Hanford Line Load MW (MW)    
%   046   45  Raver-Schultz 1&2 Line Load MW (MW)    
%   047   46  Hanford-Grand Coulee Line Load MW (MW) 
%   048   47  LoMo-Hanford Line Load MW (MW)         
%   049   48  John Day-Hanford Line Load MW (MW)     
%   050   49  PGE Griz-RdBt (MW)                     
%   051   50  Bonneville Generation MW (MW)          
%   052   51  The Dalles Generation MW (MW)          
%   053   52  John Day Generation MW (MW)            
%   054   53  McNary Generation MW (MW)              
%   055   54  Chief Joe Generation MW (MW)           
%   056   55  Grand Coulee Generation MW (MW)        
%   057   56  Hungry Horse Generation MW (MW)        
%   058   57  Dworshak Generation MW (MW)            
%   059   58  Libby Generation MW (MW)               
%   060   59  WWP Noxon Generation MW (MW)           
%   061   60  WWP Cabinet Gorge Genertion MW (MW)    
%   062   61  Chelan Rocky Reach Generation MW (MW)  
%   063   62  Grant Priest Rapids Generation MW (MW) 
%   064   63  Grant Wanapum Generation MW (MW)       
%   065   64  Slatt-Boardman Generation MW (MW)      
%   066   65  Spare (None)                           
%   067   66  Spare (None)                           
%   068   67  Slatt-Boardman rms Amps (Amps)         
%   069   68  Slatt-Ashe rms Amps (Amps)             
%   070   69  Slatt-Buckley 3 phase MW (MW)          
%   071   70  Slatt-Buckley A phase kV (kV)          
%   072   71  Ross System Frequency (PTI) (Hz)       
%   073   72  Slatt-Buckley A phase Amps (Amps)      
%   074   73  PPL Hermistn (MW)                      
%   075   74  PPL Paul Gen (MW)                      
%   076   75  WNP2 Gen (MW)                          
%   077   76  Douglas Wells Gen (MW)                 
%   078   77  SCL Boundry Gen (MW)                   
%   079   78  GCL coord req (MW)                     
%   080   79  CHJ coord req (MW)                     
%   081   80  BCH Intalco MW (MW)                    
%   082   81  PG&E Captain Jack MW (MW)              
%   083   82  PPL Alvey 500 kV MW (MW)               
%   084   83  PG&E Olinda MW (MW)                    
%   085   84  PPL Dixonville MW (MW)                 
%   086   85  BPA Area Load MW (MW)                  
%   087   86  BPA Area Control Error MW (MW)         
%   088   87  BPA Total Generation MW (MW)           
%   089   88  BPA Spinning Reserve MW (MW)           
%   090   89  BPA Filtered ACE (MWh)                 
%   091   90  BPA Net Schedule Interchange MW (MW)   
%   092   91  Grand Coulee Mid-Col. Schedule MW (MW) 
%   093   92  Chief Joe Mid-Col. Schedule MW (MW)    
%   094   93  Grand Coulee Mid-Col. Bias MW (MW)     
%   095   94  Chief Joe Mid-Col. Bias MW (MW)        
%   096   95  PSAM Trigger (volts)                   
% Left column shows indexing for signals
%*********************************************************************

%*********************************************************************
%chankey for Dittmer #18
%   time                                              
%   001    0  BPA Net Actual Interchange MW (MW)      
%   002    1  Time Tick (Reference) (Volts)           
%   003    2  Dittmer System Frequency (Hz)           
%   004    3  BPA Frequency Bias Setting (MW/Hz)      
%   005    4  Tacoma 230 kV Bus Voltage (kV)          
%   006    5  Tacoma 230 kV - Bus Frequency (Hz)      
%   007    6  Tacoma NE 1-2-3 MW (MW)                 
%   008    7  Tacoma NE 1-2-3 MVar (MVar)             
%   009    8  Malin-Round Mountain #1 MW (MW)         
%   010    9  Malin-Round Mountain #1 MVar (MVar)     
%   011   10  Malin N.Bus (#1) kV (kV)                
%   012   11  Malin-Round Mountain #2 MW (MW)         
%   013   12  Malin-Round Mountain #2 MVar (MVar)     
%   014   13  Malin S.Bus (#2) kV (kV)                
%   015   14  Garrison 500 kV Bus East (kV)           
%   016   15  Garrison 500 kV Bus West (kV)           
%   017   16  Custer 500 kV Bus Voltage (kV)          
%   018   17  IPC Lagrande MW (MW)                    
%   019   18  IPC Harney MW (MW)                      
%   020   19  Hot Springs E-W Tie MW (MW)             
%   021   20  MPC Garrison 500 kV MW (MW)             
%   022   21  MPC Kerr MW (MW)                        
%   023   22  MPC Broadview 500 kV MW (MW)            
%   024   23  MPC Anaconda MW (MW)                    
%   025   24  MPC Garrison 230 kV MW (MW)             
%   026   25  PPL E-W Tie Idaho Sum MW (MW)           
%   027   26  PSPL Covington MW (MW)                  
%   028   27  PSPL Maple Valley MW (MW)               
%   029   28  PSPL Bellingham MW (MW)                 
%   030   29  PSPL Snohomish MW (MW)                  
%   031   30  LADWP Celilo 500 kV MW (MW)             
%   032   31  PPL Summer Lake (Grizzly) MW (MW)       
%   033   32  BCH Custer MW (MW)                      
%   034   33  BCH Boundary MW (MW)                    
%   035   34  BCH Ingledow MW (MW)                    
%   036   35  PG&E Malin Sum MW (MW)                  
%   037   36  LADWP Celilo 230 kV MW (MW)             
%   038   37  LADWP Sylmar Sum MW (MW)                
%   039   38  E-W Tie Burke Thompson MW (MW)          
%   040   39  Monroe-Chief Joe Line Load MW (MW)      
%   041   40  Snohomish-Chief Joe Line Load MW (MW)   
%   042   41  Chelan RR-Maple Valley Line Load MW (MW)
%   043   42  Sickler-Schultz Line Load MW (MW)       
%   044   43  Vantage-Schultz Line Load MW (MW)       
%   045   44  Ostrander-Hanford Line Load MW (MW)     
%   046   45  Raver-Schultz 1&2 Line Load MW (MW)     
%   047   46  Hanford-Grand Coulee Line Load MW (MW)  
%   048   47  LoMo-Hanford Line Load MW (MW)          
%   049   48  John Day-Hanford Line Load MW (MW)      
%   050   49  PGE Griz-RDB1 (MW)                      
%   051   50  Bonneville Generation MW (MW)           
%   052   51  The Dalles Generation MW (MW)           
%   053   52  John Day Generation MW (MW)             
%   054   53  McNary Generation MW (MW)               
%   055   54  Chief Joe Generation MW (MW)            
%   056   55  Grand Coulee Generation MW (MW)         
%   057   56  Hungry Horse Generation MW (MW)         
%   058   57  Dworshak Generation MW (MW)             
%   059   58  Libby Generation MW (MW)                
%   060   59  WWP Noxon Generation MW (MW)            
%   061   60  WWP Cabinet Gorge Genertion MW (MW)     
%   062   61  Chelan Rocky Reach Generation MW (MW)   
%   063   62  Grant Priest Rapids Generation MW (MW)  
%   064   63  Grant Wanapum Generation MW (MW)        
%   065   64  Slatt-Boardman Generation MW (MW)       
%   066   65  Calibration (Volts)                     
%   067   66  Spare (None)                            
%   068   67  Slatt-Boardman rms Amps (Amps)          
%   069   68  Slatt-Ashe rms Amps (Amps)              
%   070   69  Slatt-Buckley 3 phase MW (MW)           
%   071   70  Slatt-Buckley A phase kV (kV)           
%   072   71  Ross System Frequency (PTI) (Hz)        
%   073   72  Slatt-Buckley A phase Amps (Amps)       
%   074   73  PPL Hermiston MW (MW)                   
%   075   74  PPL Paul Generation MW (MW)             
%   076   75  WNP2 Generation MW (MW)                 
%   077   76  Douglas Wells Generation (MW)           
%   078   77  SCL Boundry Generation (MW)             
%   079   78  GCL Coord Req MW (MW)                   
%   080   79  CHJ Coord Req MW (MW)                   
%   081   80  BCH Intalco MW (MW)                     
%   082   81  PG&E Captain Jack MW (MW)               
%   083   82  PPL Alvey 500 kV MW (MW)                
%   084   83  PG&E Olinda MW (MW)                     
%   085   84  PPL Dixonville MW (MW)                  
%   086   85  BPA Area Load MW (MW)                   
%   087   86  BPA Area Control Error MW (MW)          
%   088   87  BPA Total Generation MW (MW)            
%   089   88  BPA Spinning Reserve MW (MW)            
%   090   89  BPA Filtered ACE (MWh)                  
%   091   90  BPA Integral ACE MW (MW)                
%   092   91  Grand Coulee Mid-Col. Schedule MW (MW)  
%   093   92  Chief Joe Mid-Col. Schedule MW (MW)     
%   094   93  Grand Coulee Mid-Col. Bias MW (MW)      
%   095   94  Chief Joe Mid-Col. Bias MW (MW)         
%   096   95  BPA Net Schedule Interchange MW (MW)    
%  Left column shows indexing for signals

%*********************************************************************
%chankey for Dittmer #20
%[ADD LATER]

%*********************************************************************
%chankey for Dittmer #21
%   time                                               
%   001    0  BPA Net Actual Interchange MW (MW)       
%   002    1  Spare (No connection) (None)             
%   003    2  Dittmer System Frequency (Hz)            
%   004    3  BPA Frequency Bias Setting (MW/Hz)       
%   005    4  Tacoma 230 kV Bus Voltage (kV)           
%   006    5  Tacoma 230 kV - Bus Frequency (Hz)       
%   007    6  Tacoma NE 1-2-3 MW (MW)                  
%   008    7  Tacoma NE 1-2-3 MVar (MVar)              
%   009    8  Malin-Round Mountain #1 MW (MW)          
%   010    9  Malin-Round Mountain #1 MVar (MVar)      
%   011   10  Malin No.Bus (#1) kV (kV)                
%   012   11  Malin-Round Mountain #2 MW (MW)          
%   013   12  Malin-Round Mountain #2 MVar (MVar)      
%   014   13  Malin So.Bus (#2) kV (kV)                
%   015   14  Garrison 500 kV Bus East (kV)            
%   016   15  Garrison 500 kV Bus West (kV)            
%   017   16  Custer 500 kV Bus Voltage (kV)           
%   018   17  IPC Lagrande MW (MW)                     
%   019   18  IPC Harney MW (MW)                       
%   020   19  Hot Springs E-W Tie MW (MW)              
%   021   20  MPC Garrison 500 kV MW (MW)              
%   022   21  MPC Kerr 115 kV MW (MW)                  
%   023   22  MPC Broadview 500 kV MW (MW)             
%   024   23  MPC Anaconda MW (MW)                     
%   025   24  MPC Garrison 230 kV MW (MW)              
%   026   25  E-W Tie Idaho MW (MW)                    
%   027   26  PSE Covington MW (MW)                    
%   028   27  PSE Maple Valley MW (MW)                 
%   029   28  PSE Bellingham MW (MW)                   
%   030   29  PSE Snohomish MW (MW)                    
%   031   30  LADWP Celilo 500 kV MW (MW)              
%   032   31  PAC Summer Lake (Grizzly) MW (MW)        
%   033   32  BCH Ingledow via Custer 500kV MW (MW)    
%   034   33  BCH Boundary_WKPL 230 kV MW (MW)         
%   035   34  BCH Ingledow via Ingledow 500 kV MW (MW) 
%   036   35  PG&E Malin (CalISO) 500 kV MW (MW)       
%   037   36  LADWP Celilo 230 kV MW (MW)              
%   038   37  LADWP Sylmar MW (MW)                     
%   039   38  E-W Tie Burke Thompson MW (MW)           
%   040   39  Monroe-Chief Joe 500 Line Load MW (MW)   
%   041   40  Snohomish-Chief Joe 230 Line Load MW (MW)
%   042   41  Chelan RR-Maple Valley Line Load MW (MW) 
%   043   42  Sickler-Schultz Line Load MW (MW)        
%   044   43  Vantage-Schultz Line Load MW (MW)        
%   045   44  Ostrander-Hanford Line Load MW (MW)      
%   046   45  Raver-Schultz 1&2 Line Load MW (MW)      
%   047   46  Hanford-Grand Coulee Line Load MW (MW)   
%   048   47  LoMo-Hanford Line Load MW (MW)           
%   049   48  John Day-Hanford Line Load MW (MW)       
%   050   49  PGE Redmond-RoundB (MW)                  
%   051   50  Bonneville PH Generation MW (MW)         
%   052   51  The Dalles PH Generation MW (MW)         
%   053   52  John Day PH Generation MW (MW)           
%   054   53  McNary PH Generation MW (MW)             
%   055   54  Chief JoePH Generation MW (MW)           
%   056   55  Grand Coulee Generation MW (MW)          
%   057   56  Hungry HorsePH Generation MW (MW)        
%   058   57  Dworshak PH Generation MW (MW)           
%   059   58  Libby PH Generation MW (MW)              
%   060   59  AVA Noxon Generation MW (MW)             
%   061   60  AVA Cabinet Gorge Genertion MW (MW)      
%   062   61  Chelan Rocky Reach Generation MW (MW)    
%   063   62  Grant Priest Rapids Generation MW (MW)   
%   064   63  Grant Wanapum Generation MW (MW)         
%   065   64  PGE Slatt-Boardman Generation MW (MW)    
%   066   65  AVA Westside MW (MW)                     
%   067   66  Slatt-John Day Amps (Amps)               
%   068   67  Slatt-Boardman Amps (Amps)               
%   069   68  Slatt-Ashe Amps (Amps)                   
%   070   69  Slatt-Buckley MW (MW)                    
%   071   70  Slatt-Buckley A phase kV (kV)            
%   072   71  Ross System Frequency (PTI) (Hz)         
%   073   72  Slatt-Buckley A phase Amps (Amps)        
%   074   73  PAC Hermiston Generation MW (MW)         
%   075   74  TEM (Centralia) Generation MW (MW)       
%   076   75  Columbia (WNP2) Generation MW (MW)       
%   077   76  Douglas Wells Generation (MW)            
%   078   77  SCL Boundry Generation (MW)              
%   079   78  GCL Coord Req MW (MW)                    
%   080   79  CHJ Coord Req MW (MW)                    
%   081   80  BCH Intalco MW (MW)                      
%   082   81  PG&E Captain Jack MW (MW)                
%   083   82  PAC Alvey 500 kV MW (MW)                 
%   084   83  PG&E Olinda MW (MW)                      
%   085   84  PAC Dixonville 500 kV MW (MW)            
%   086   85  BPA Area Load MW (MW)                    
%   087   86  BPA Area Control Error MW (MW)           
%   088   87  BPA Total Generation MW (MW)             
%   089   88  BPA Spinning Reserve MW (MW)             
%   090   89  BPA Filtered ACE (MWh)                   
%   091   90  BPA Integral ACE MW (MW)                 
%   092   91  MCol-GCL Uncoordinated Schedule MW (MW)  
%   093   92  MCOl-CHJ Uncoordinated Schedule MW (MW)  
%   094   93  MIDC GNT Bias used GCL MW (MW)           
%   095   94  MIDC GNT Bias used CHJ MW (MW)           
%   096   95  BPA Net Schedule Interchange MW (MW)     
% Left column shows indexing for signals
%*********************************************************************

%*********************************************************************
%chankey for Dittmer Listing 02-01-2002
%   time                                               
%   1    0  BPA Net Actual Interchange MW         MW   
%   2    1  Spare (No connection) (None)               
%   3    2  Dittmer System Frequency              FreqL
%   4    3  BPA Frequency Bias Setting (MW/Hz)         
%   5    4  Tacoma 230 kV Bus Voltage             VMag 
%   6    5  Tacoma 230 kV - Bus Frequency         FreqL
%   7    6  Tacoma NE 1-2-3 MW                    MW   
%   8    7  Tacoma NE 1-2-3 MVar                  Mvar 
%   9    8  Malin-Round Mountain #1 MW            MW   
%  10    9  Malin-Round Mountain #1 MVar          Mvar 
%  11   10  Malin No.Bus (#1) kV                  VMag 
%  12   11  Malin-Round Mountain #2 MW            MW   
%  13   12  Malin-Round Mountain #2 MVar          Mvar 
%  14   13  Malin So.Bus (#2) kV                  VMag 
%  15   14  Garrison 500 kV Bus East              VMag 
%  16   15  Garrison 500 kV Bus West              VMag 
%  17   16  Custer 500 kV Bus Voltage             VMag 
%  18   17  IPC Lagrande MW                       MW   
%  19   18  IPC Harney MW                         MW   
%  20   19  Hot Springs E-W Tie MW                MW   
%  21   20  MPC Garrison 500 kV MW                MW   
%  22   21  MPC Kerr 115 kV MW                    MW   
%  23   22  MPC Broadview 500 kV MW               MW   
%  24   23  MPC Anaconda MW                       MW   
%  25   24  MPC Garrison 230 kV MW                MW   
%  26   25  E-W Tie Idaho MW                      MW   
%  27   26  PSE Covington MW                      MW   
%  28   27  PSE Maple Valley MW                   MW   
%  29   28  PSE Bellingham MW                     MW   
%  30   29  PSE Snohomish MW                      MW   
%  31   30  LADWP Celilo 500 kV MW                MW   
%  32   31  PAC Summer Lake (Grizzly) MW          MW   
%  33   32  BCH Ingledow via Custer 500kV MW      MW   
%  34   33  BCH Boundary_WKPL 230 kV MW           MW   
%  35   34  BCH Ingledow via Ingledow 500 kV MW   MW   
%  36   35  PG&E Malin (CalISO) 500 kV MW         MW   
%  37   36  LADWP Celilo 230 kV MW                MW   
%  38   37  LADWP Sylmar MW                       MW   
%  39   38  E-W Tie Burke Thompson MW             MW   
%  40   39  Monroe-Chief Joe 500 Line Load MW     MW   
%  41   40  Snohomish-Chief Joe 230 Line Load MW  MW   
%  42   41  Chelan RR-Maple Valley Line Load MW   MW   
%  43   42  Sickler-Schultz Line Load MW          MW   
%  44   43  Vantage-Schultz Line Load MW          MW   
%  45   44  Ostrander-Hanford Line Load MW        MW   
%  46   45  Raver-Schultz 1&2 Line Load MW        MW   
%  47   46  Hanford-Grand Coulee Line Load MW     MW   
%  48   47  LoMo-Hanford Line Load MW             MW   
%  49   48  John Day-Hanford Line Load MW         MW   
%  50   49  PGE Redmond-RoundB                    MW   
%  51   50  Bonneville PH Generation MW           MW   
%  52   51  The Dalles PH Generation MW           MW   
%  53   52  John Day PH Generation MW             MW   
%  54   53  McNary PH Generation MW               MW   
%  55   54  Chief JoePH Generation MW             MW   
%  56   55  Grand Coulee Generation MW            MW   
%  57   56  Hungry HorsePH Generation MW          MW   
%  58   57  Dworshak PH Generation MW             MW   
%  59   58  Libby PH Generation MW                MW   
%  60   59  AVA Noxon Generation MW               MW   
%  61   60  AVA Cabinet Gorge Genertion MW        MW   
%  62   61  Chelan Rocky Reach Generation MW      MW   
%  63   62  Grant Priest Rapids Generation MW     MW   
%  64   63  Grant Wanapum Generation MW           MW   
%  65   64  PGE Slatt-Boardman Generation MW      MW   
%  66   65  AVA Westside MW                       MW   
%  67   66  Slatt-John Day Amps                   IMag 
%  68   67  Slatt-Boardman Amps                   IMag 
%  69   68  Slatt-Ashe Amps                       IMag 
%  70   69  Slatt-Buckley MW                      MW   
%  71   70  Slatt-Buckley A phase kV              VMag 
%  72   71  Ross System Frequency (PTI)           FreqL
%  73   72  Slatt-Buckley A phase Amps            IMag 
%  74   73  PAC Hermiston Generation MW           MW   
%  75   74  TEM (Centralia) Generation MW         MW   
%  76   75  Columbia (WNP2) Generation MW         MW   
%  77   76  Douglas Wells Generation              MW   
%  78   77  SCL Boundry Generation                MW   
%  79   78  GCL Coord Req MW                      MW   
%  80   79  CHJ Coord Req MW                      MW   
%  81   80  BCH Intalco MW                        MW   
%  82   81  PG&E Captain Jack MW                  MW   
%  83   82  PAC Alvey 500 kV MW                   MW   
%  84   83  PG&E Olinda MW                        MW   
%  85   84  PAC Dixonville 500 kV MW              MW   
%  86   85  BPA Area Load MW                      MW   
%  87   86  BPA Area Control Error MW             MW   
%  88   87  BPA Total Generation MW               MW   
%  89   88  BPA Spinning Reserve MW               MW   
%  90   89  BPA Filtered ACE (MWh)                     
%  91   90  BPA Integral ACE MW                   MW   
%  92   91  MCol-GCL Uncoordinated Schedule MW    MW   
%  93   92  MCOl-CHJ Uncoordinated Schedule MW    MW   
%  94   93  MIDC GNT Bias used GCL MW             MW   
%  95   94  MIDC GNT Bias used CHJ MW             MW   
%  96   95  BPA Net Schedule Interchange MW       MW
%*********************************************************************

	
%end of PSMT function

