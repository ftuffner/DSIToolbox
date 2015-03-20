function [chansMenu,chansS]=PSAMmenu(ListName,nsigs)   
%
% function [chansMenu,chansS]=PSAMmenu(ListName,nsigs)
%
% Defines convenience menus for processing signals from particular
% PSAM units, as identified by their file names.
%
% Special functions used:
%   promptyn
%
%  Last modified 09/09/99.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

disp(['In PSAMmenu: ListName = ' ListName])

nsigsS=num2str(nsigs);

%Define default menus for PPSM channel extraction
%*************************************************************************
chansMenu=('Initial user selections');
chansS='[1]';
chansMenu=str2mat(chansMenu,'All channels');
chansS=str2mat(chansS,['[1:' nsigsS ']']);
chansMenu=str2mat(chansMenu,'No channels');
chansS=str2mat(chansS,'[1]');
chansMenu=str2mat(chansMenu,'Interactive selection of channels');
chansS=str2mat(chansS,'[1 4 2:4]');
chansMenu=str2mat(chansMenu,'Sort by signal type');
chansS=str2mat(chansS,'[1]');
%*************************************************************************

%*************************************************************************
%help uigetfile
%setok=promptyn('In PSAMmenu: Load signal extraction menus from text file? ', 'n');
%if setok
  %(use uigetfile)
%end
%*************************************************************************


%********************* List of known channel keys ********************

%*************************************************************************
%Menu for Dittmer PSAM Unit
disp(['In PSAMmenu: Standard PSAM unit'])
chansMenu=str2mat(chansMenu,'BigView summary');
chansS=str2mat(chansS,'[3 6 5 9 36 38 33 34 21 24 18 26 56 71]');
chansMenu=str2mat(chansMenu,'Short dynamics summary');
chansS=str2mat(chansS,'[3 6 5 9 10 11 33 34 19 20 21 23 25 55 37]');
chansMenu=str2mat(chansMenu,'Long dynamics summary');
chansS=str2mat(chansS,'[3 6 5 9 10 11 34 33 19 20 21 23 25 17 18 4 30 36 37 81 82 83]');
chansMenu=str2mat(chansMenu,'Generation summary');
chansS=str2mat(chansS,'[3 6 5 9 10 50:65]');
chansMenu=str2mat(chansMenu,'AGC summary');
chansS=str2mat(chansS,'[3 6 5 9 86:95]');
chansMenu=str2mat(chansMenu,'Montana summary');
chansS=str2mat(chansS,'[3 6 5 9 16 20:25 59 58 57]');
chansMenu=str2mat(chansMenu,'Idaho summary');
chansS=str2mat(chansS,'[3 6 5 9 71 18 19 26 32 24 48 58 54]');
chansMenu=str2mat(chansMenu,'Tacoma summary');
chansS=str2mat(chansS,'[3 6 5 9 7 8]');
%*************************************************************** *****

return

%********************* List of known channel keys ********************

%*********************************************************************
%chankey for Dittmer PSAM Unit
%  1 Time          sec 
%  2 unknown       sec 
%  3 System  Freq  Hz  
%  4 AGC Bias MW/  Hz  
%  5 Tacoma 230    KV  
%  6 Tacoma 230    Hz  
%  7 Tacoma N.E.   MW  
%  8 Tacoma N.E.   MVAR
%  9 Malin RMTN1   MW  
% 10 Malin RMTN1   MVAR
% 11 Malin RMTN1   KV  
% 12 Malin RMTN2   MW  
% 13 Malin RMTN2   MVAR
% 14 Malin RMTN2   KV  
% 15 Garrison  5E  KV  
% 16 Garrison 5W   KV  
% 17 Phase Angle   degr
% 18 IDA Lagrande  MW  
% 19 IDA Harney    MW  
% 20 EWTIE Hot Sp  MW  
% 21 MPC Garr 500  MW  
% 22 MPC Kerr      MW  
% 23 MPC Broadv    MW  
% 24 MPC Anaconda  MW  
% 25 MPC Garr 230  MW  
% 26 EWTIE Idaho   MW  
% 27 PSPL Covingt  MW  
% 28 PSPL MapleV   MW  
% 29 PSPL Belham   MW  
% 30 PSPL Snohom   MW  
% 31 LADWP Cel500  MW  
% 32 PPL SumrLake  MW  
% 33 BCH Ing-Cust  MW  
% 34 BCH Boundary  MW  
% 35 BCH Ingledow  MW  
% 36 PG&E Malin    MW  
% 37 LADWP Cel230  MW  
% 38 LADWP Sylmar  MW  
% 39 EWTIE Burke   MW  
% 40 Monr-Chjo LL  MW  
% 41 Snoh-Chjo LL  MW  
% 42 Chel-RR-Mpvl  MW  
% 43 Sick-Rave LL  MW  
% 44 Vant-Rave LL  MW  
% 45 Ostr-Hanf LL  MW  
% 46 Rave-Coul LL  MW  
% 47 Hanf-Coul LL  MW  
% 48 LoMo-Hanf LL  MW  
% 49 JDay-Hanf LL  MW  
% 50 JDay MVAR Gn  MVAR
% 51 Bonville Gen  MW  
% 52 TDalles Gen   MW  
% 53 John Day Gen  MW  
% 54 McNary Gen    MW  
% 55 Chief Jo Gen  MW  
% 56 GCL AP Gen    MW  
% 57 HHorse Gen    MW  
% 58 Dworshak Gen  MW  
% 59 Libby Gen     MW  
% 60 WWP Noxon Gn  MW  
% 61 WWP CabG Gen  MW  
% 62 RockyR Gen    MW  
% 63 PriestR Gen   MW  
% 64 Wanapum Gen   MW  
% 65 PGE Slatt Gn  MW  
% 66 Slatt-McNar   Amps
% 67 Slatt-JDay    Amps
% 68 Slatt-Brdman  Amps
% 69 Slatt-Ashe    Amps
% 70 Slatt-Buckly  MW  
% 71 Slatt-Buckly  KV  
% 72 TCSC Ohms     MW  
% 73 Slatt-Buckly  Amps
% 74 SPARE         MW  
% 75 SPARE         MW  
% 76 SPARE         MW  
% 77 SPARE         MW  
% 78 SPARE         MW  
% 79 SPARE         MW  
% 80 SPARE         MW  
% 81 SPARE         MW  
% 82 PG&E CP JK P  MW  
% 83 PP&L ALV 500  MW  
% 84 PG&E OLINDA   MW  
% 85 PP&L DIXONVL  MW  
% 86 AREA LOAD     MW  
% 87 ACE           MW  
% 88 TOTAL GEN     MW  
% 89 SPIN RESER    MW  
% 90 FILTERED ACE  MW  
% 91 INTEG ACE     MW  
% 92 MIDC-GCL SCH  MW  
% 93 MIDC-CHJ SCH  MW  
% 94 MIDC-GCL BIA  MW  
% 95 MIDC-CHJ BIA  MW  
% 96 BPA NET SCH   MW  
% 97 BPA NET ACT   MW  
% Left column shows indexing for signals

	
% End of jfh m-file


