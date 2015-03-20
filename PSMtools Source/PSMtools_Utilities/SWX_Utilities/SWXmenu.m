function [chansMenu,chansS]=SWXmenu(chansMenu,chansS,CFname,nsigs)   
%
%  [chansMenu,chansS]=SWXmenu(chansMenu,chansS,CFname,nsigs);
%
% Defines convenience menus for processing signals from particular
% SWX data sources, as identified by their configuration file names.
%
% Special functions used:
%   promptyn
%   
% Last modified 01/08/04.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

disp(['In SWXmenu: CFname = ' CFname])
disp(['Special version for PSLF Cases at BPA'])

%****************************************************************
%help uigetfile
%setok=promptyn('In SWXmenu: Load signal extraction menus from text file? ', 'n');
%if setok
  %(use uigetfile)
%end
%****************************************************************

%***********List of known SWX configurations***********
% BPA Example #1

%****************************************************************
%Menus for 
% BPA Example #1 (June7_OpCase3A.swx.txt)
% BPA Example #2 (undefined as yet)
match1=~isempty(findstr(lower('BPA Example #1'),lower(CFname)));
match2=~isempty(findstr(lower('BPA Example #2'),lower(CFname)));
if match1|match2
disp(['In SWXmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'Ringdown Summary');
str='[1 3 6 9 12 15 18 '; %Frequencies
str=[str '20 21 22 23 24 25 26 27 28 29 30 31 32 33 36 39 43 '];
str=[str '47 51 55 59 63 67 71 75 79 83 87 89 91 93 95 98 101 '];
str=[str '104 107 110 113]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Freq/VMag/VAng');
str='[1 3 6 9 12 15 18 ';                                %Frequencies
str=[str '4 7 10 13 16 19 35 38 41 42'];                 %VMags   
str=[str '2 5  8 11 14 17 97 100 103 106 109 112 115]']; %VAngs
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Coulee/Malin Summary');
str='[1 11   12   13    8    9   10   61   62   63   64  104  105  106]';                                %Frequencies
chansS=str2mat(chansS,str);
return
end
%****************************************************************


disp(['In SWXmenu: No match found to ' CFname])
return


%***********List of known channel keys***********


%****************************************************************
%chankey for BPA Example #1 (June7_OpCase3A.swx.txt)
%   1  time                                                      
%   2  50561 WSN500   500.00 - Selkirk]               abus   VAng
%   3  50561 WSN500   500.00                          fbus   Freq
%   4  50561 WSN500   500.00                          vbus   VMag
%   5  54150 LANGDON  500.00 0                        abus   VAng
%   6  54150 LANGDON  500.00                          fbus   Freq
%   7  54150 LANGDON  500.00                          vbus   VMag
%   8  40287 COULEE   500.00 0                        abus   VAng
%   9  40287 COULEE   500.00                          fbus   Freq
%  10  40287 COULEE   500.00                          vbus   VMag
%  11  40687 MALIN    500.00 0                        abus   VAng
%  12  40687 MALIN    500.00                          fbus   Freq
%  13  40687 MALIN    500.00                          vbus   VMag
%  14  24801 DEVERS   500.00 0                        abus   VAng
%  15  24801 DEVERS   500.00                          fbus   Freq
%  16  24801 DEVERS   500.00                          vbus   VMag
%  17  62057 COLSTRP  500.00 0                        abus   VAng
%  18  62057 COLSTRP  500.00                          fbus   Freq
%  19  62057 COLSTRP  500.00                          vbus   VMag
%  20  40145BOUN230   40909SACH230 1                  pbr    MW  
%  21  50561WSN5500   50704KLY5500 1                  pbr    MW  
%  22  54150LANG500   50791CBK5500 1                  pbr    MW  
%  23  62057COLS500   62054BROA500 1                  pbr    MW  
%  24  40687MALI500   30005ROUN500 1                  pbr    MW  
%  25  24801DEVE500   15021PALO500 1                  pbr    MW  
%  26  Interface 103 [WSN -- GLEN     ]               pif    MW  
%  27  50560KDS5500   50561WSN5500 1                  pbr    MW  
%  28  50558GMS5500   50561WSN5500 1                  pbr    MW  
%  29  50558GMS5500   50561WSN5500 1                  pbr    MW  
%  30  50558GMS5500   50561WSN5500 1                  pbr    MW  
%  31  Interface 111 [Nicola - Kelly L]               pif    MW  
%  32  Interface 112 [Nicola - Selkirk]               pif    MW  
%  33  41313 CELILO3  230.00 pa                       pacr   MW  
%  34  41313 CELILO3  230.00 qa                       qacr   Mvar
%  35  41313 CELILO3  230.00                          vbus   VMag
%  36  41311 CELILO1  500.00 pa                       pacr   MW  
%  37  41311 CELILO1  500.00 qa                       qacr   Mvar
%  38  41311 CELILO1  500.00                          vbus   VMag
%  39  26097 SYLMAR1  230.00 pa                       paci   MW  
%  40  26097 SYLMAR1  230.00 qa                       qaci   Mvar
%  41  26097 SYLMAR1  230.00                          vbus   VMag
%  42  26003 ADELANTO 500.00                          vbus   VMag
%  43  26003 ADELANTO 500.00 pa                       paci   MW  
%  44  26003 ADELANTO 500.00 qa                       qaci   Mvar
%  45  50495 GMS G1    13.80                          ang    Gang
%  46  50495 GMS G1    13.80                          spd    Gfrq
%  47  50495 GMS G1    13.80                          pg     MW  
%  48  50495 GMS G1    13.80                          qg     Mvar
%  49  50437 KMO G1    13.80                          ang    Gang
%  50  50437 KMO G1    13.80                          spd    Gfrq
%  51  50437 KMO G1    13.80                          pg     MW  
%  52  50437 KMO G1    13.80                          qg     Mvar
%  53  54122 SUND#1GN  18.50                          ang    Gang
%  54  54122 SUND#1GN  18.50                          spd    Gfrq
%  55  54122 SUND#1GN  18.50                          pg     MW  
%  56  54122 SUND#1GN  18.50                          qg     Mvar
%  57  62049 COLSTP 2  22.00                          ang    Gang
%  58  62049 COLSTP 2  22.00                          spd    Gfrq
%  59  62049 COLSTP 2  22.00                          pg     MW  
%  60  62049 COLSTP 2  22.00                          qg     Mvar
%  61  40289 COULEE 2  13.80                          ang    Gang
%  62  40289 COULEE 2  13.80                          spd    Gfrq
%  63  40289 COULEE 2  13.80                          pg     MW  
%  64  40289 COULEE 2  13.80                          qg     Mvar
%  65  37575 SHASTA1   13.80                          ang    Gang
%  66  37575 SHASTA1   13.80                          spd    Gfrq
%  67  37575 SHASTA1   13.80                          pg     MW  
%  68  37575 SHASTA1   13.80                          qg     Mvar
%  69  24129 S.ONOFR2  22.00                          ang    Gang
%  70  24129 S.ONOFR2  22.00                          spd    Gfrq
%  71  24129 S.ONOFR2  22.00                          pg     MW  
%  72  24129 S.ONOFR2  22.00                          qg     Mvar
%  73  14931 PALOVRD1  24.00                          ang    Gang
%  74  14931 PALOVRD1  24.00                          spd    Gfrq
%  75  14931 PALOVRD1  24.00                          pg     MW  
%  76  14931 PALOVRD1  24.00                          qg     Mvar
%  77  60188 KINPORT   14.40                          ang    Gang
%  78  60188 KINPORT   14.40                          spd    Gfrq
%  79  60188 KINPORT   14.40                          pg     MW  
%  80  60188 KINPORT   14.40                          qg     Mvar
%  81  50637 MCA G1    16.00                          ang    Gang
%  82  50637 MCA G1    16.00                          spd    Gfrq
%  83  50637 MCA G1    16.00                          pg     MW  
%  84  50637 MCA G1    16.00                          qg     Mvar
%  85  50644 REV G1    16.00                          ang    Gang
%  86  50644 REV G1    16.00                          spd    Gfrq
%  87  50644 REV G1    16.00                          pg     MW  
%  88  50644 REV G1    16.00                          qg     Mvar
%  89  Interface 100 [BOUNDARY - BCH  ]               pif    MW  
%  90  Interface 100 [BOUNDARY - BCH  ]               qif    Mvar
%  91  Interface 101 [CUSTER - ING500 ]               pif    MW  
%  92  Interface 101 [CUSTER - ING500 ]               qif    Mvar
%  93  Interface 102 [BOUNDARY - BELL ]               pif    MW  
%  94  Interface 102 [BOUNDARY - BELL ]               qif    Mvar
%  95  Interface 104 [KMO Plant       ]               pif    MW  
%  96  Interface 104 [KMO Plant       ]               qif    Mvar
%  97  50460 KMO287   287.00 0                        abus   VAng
%  98  Interface 105 [GMS Plant       ]               pif    MW  
%  99  Interface 105 [GMS Plant       ]               qif    Mvar
% 100  50558 GMS500   500.00 0                        abus   VAng
% 101  Interface 106 [Colstrip Plant  ]               pif    MW  
% 102  Interface 106 [Colstrip Plant  ]               qif    Mvar
% 103  62060 COLSTRP  230.00 0                        abus   VAng
% 104  Interface 107 [Coulee Plant    ]               pif    MW  
% 105  Interface 107 [Coulee Plant    ]               qif    Mvar
% 106  40283 COULEE   230.00 0                        abus   VAng
% 107  Interface 108 [Sundance Plant  ]               pif    MW  
% 108  Interface 108 [Sundance Plant  ]               qif    Mvar
% 109  54128 SUNDANCE 240.00 0                        abus   VAng
% 110  Interface 109 [Mica Plant      ]               pif    MW  
% 111  Interface 109 [Mica Plant      ]               qif    Mvar
% 112  50700 MCA500   500.00 0                        abus   VAng
% 113  Interface 110 [Revelstoke Plant]               pif    MW  
% 114  Interface 110 [Revelstoke Plant]               qif    Mvar
% 115  50701 REV500   500.00 0                        abus   VAng
%  Left column shows indexing for signals (including time)
%****************************************************************


%end of PSMT function


