function [chansMenu,chansS]=PDCmenu(chansMenu,chansS,CFname,nsigs)   
%
%  [chansMenu,chansS]=PDCmenu(chansMenu,chansS,CFname,nsigs);
%
% Defines convenience menus for processing signals from particular
% PDC units, as identified by their configuration file names.
%
% Special functions used:
%   promptyn
%   
% Modified 09/12/05.  jfh    Added BPA2_050707.ini to dictionary
% Modified 02/01/06.  jfh    Updated BCH menus
% Modified 02/14/06.  jfh    Updated BPA menus
% Modified 02/15/06.  jfh    Updated APS menus

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

disp(['In PDCmenu: CFname = ' CFname])

%****************************************************************
%help uigetfile
%setok=promptyn('In PDCmenu: Load signal extraction menus from text file? ', 'n');
%if setok
  %(use uigetfile)
%end
%****************************************************************

%***********List of known PDC configurations***********
% BPA1_091698.ini
% BPA1X_122099.ini
% BPA1MX_050101.ini
% BPA1X_110101.ini
% BPA1XX_110101.ini
% BPA2_062602.ini
% BPA1_062802.ini
% BPA1_030320.ini
% BPA1_030320m.ini
% BPA1_031007.ini
% BPA1_040610m.ini; BPA2_040610m.ini;
% BPA2_040716.ini
% BPA1_040903.ini
% BPA2_040921.ini; BPA2_040921m.ini
% BPA2_050215.ini
% BPA1_050307.ini
% BPA2_050707.ini
%
% SCE1X_122999.ini
% sce1_032100.ini
% SCE1X_081401.ini
%
% wapa1.ini
% wapa_110398.ini
% wapa_041802.txt
% WAPA030504.ini
%
% BCH072400.ini 
% BCH042302X.ini
% BCH050703X.ini
% BCH072403X.ini
% BCH100203X.ini
% BCH042204.ini
% BCH061604.ini
%
% APS1_031230.ini

%****************************************************************
%Menus for PDC configurations at BPA [may need updates]
% BPA1X_122099.ini
% BPA1MX_050101.ini
match1=~isempty(findstr('bpa1x_122099',lower(CFname)));
match2=~isempty(findstr('bpa1mx_050101',lower(CFname)));
if match1|match2
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'Ringdown Summary');
str='[1 60 62 63 214 221 17 52 56  82 101 148 171]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Interactions Summary');
str='[1 63 214 221 17 52 56  82 101 148 171 2 60 156 211 218 79';
str=[str '3 61 157 212 219 80 4 62 158 213 220 81]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Coulee Overall');
str='[1 2:4 5:4:17 6:4:18]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Malin Overall');
str='[1 2:4 60:62 63:4:75 64:4:76]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Overall');
str='[1 98:100 101:4:105 102:4:106 137:139 144:4:148 145:4:149]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Sylmar Overall');
str='[1 156:158 159:4:171 160:4:172]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Colstrip Overall');
str='[1 79:81 82:4:86 83:4:87]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Model Validation #1');
str='[1 63 214 221 17 52 56  82 101 148 171 2 60 156 211 218 79';
str=[str ' 3 61 157 212 219 80 4 62 158 213 220 81]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'RobustSigs');
str='[1 21 22 63 67 64 68 211 212 218 219]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'BPA Datapost');
str='[1 63 214 221 17 52 56  82 101 148 171 2 60 156 211 218 79';
str=[str ' 3 61 157 212 219 80 4 62 158 213 220 81]'];
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at BPA [may need updates]
% BPA1X_110101.ini
match1=~isempty(findstr('bpa1x_110101',lower(CFname)));
match2=~isempty(findstr('bpa1xx_110101',lower(CFname)));
if match1|match2
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'Ringdown Summary');
str='[1 78 80 81 232 239 9 70 74 100 119 166 189 33]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Interactions Summary');
str='[1 81 232 239 9 70 74 100 119 166 189 33 2 78 174 229 236 97 ';
str=[str '3 79 175 230 237 98 4 80 176 231 238 99]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Coulee Overall');
str='[1 81 2:4 37:38 5:4:33 6:4:34]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Malin Overall');
str='[1 81:4:93 82:4:94 2 78 4 80 ]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Overall');
str='[1 81 116:118 119:4:123 120:4:124 155:157 162:4:166 163:4:167]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Sylmar Overall');
str='[1 81 174:176 177:4:189 178:4:190]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Colstrip Overall');
str='[1 81 97:99 100:4:104 101:4:105]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Model Validation #1');
str='[1 81 232 239 9 70 74 100 119 166 189 2 78 174 229 236 97 ';
str=[str '3 79 175 230 237 98 4 80 176 231 238 99]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'RobustSigs');
str='[1 39 40 78 79 81 85 82 86 229 230 236 237]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'BPA Datapost');
str='[1 81 232 239 9 70 74 100 119 166 189 33 2 78 174 229 236 97 ';
str=[str '3 79 175 230 237 98 4 80 176 231 238 99]'];
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at BPA
% BPA2_062602.ini or BPA1_062802.ini or BPA1_030320.ini or BPA1_031007.ini
match1=~isempty(findstr('bpa2_062602',lower(CFname)));
match2=~isempty(findstr('bpa1_062802',lower(CFname)));
match3=~isempty(findstr('bpa1_030320',lower(CFname)));
match4=~isempty(findstr('bpa1_031007',lower(CFname)));
if match1|match2|match3|match4
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'Ringdown Summary');
str='[1 81 301 308 9 280 267 250 70 74 100 119 166 189 33 ';
str=[str '2 78 298 305 4 80 300 307]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Interactions Summary');
str=['[1   4   80  176  300  307   99  275  258  231    '];  %Time & Freqs
str=[str '[2   78  174  298  305   97  273  256  229]+0 '];  %VMags
str=[str '[2   78  174  298  305   97  273  256  229]+1 '];  %VAngs
str=[str '[81 301  308    9  280  288  294 267  250   74  100  119  166  189   33]+0  ']; %MWs
str=[str '[81 301  308    9  280  288  294 267  250   74  100  119  166  189   33]+1 ]']; %MVars
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Coulee Overall');str='[1 81 2:4 37:38 5:4:33 6:4:34]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Malin/CJack Overall');
str='[1 81:4:93 244 232 250 267 263 259 82:4:94 245 233 251 268 264 260 2 78 229 248 256 4 80 231 300 307]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Overall');
str='[1 81 116:118 119:4:123 120:4:124 155:157 162:4:166 163:4:167]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Sylmar Overall');
str='[1 81 174:176 177:4:189 178:4:190]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Colstrip Overall');
str='[1 81 97:99 100:4:104 101:4:105]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Probe');
VBstr='[2 78 174  298 305 97 193 116 155]';
MWstr='[81 85 250 301 308 9 280 288 294 267 74 100 104 108 112 119 123 166 162 189 33 127 131 42 46]';
MVstr='[289  295  120  124  167  163  190   34  128  132   43   47  121  125  168  164]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Time & Freqs
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs
str=[str  MVstr '+0 ']; %MVars
str=[str '121 125 168 164']; %IMags
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Probe (ModeMeter)');
str='[1 81 308 100 119 121]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Model Validation #1');
str='[1 81 301 308 9 70 74 100 119 166 189 2 78 174 298 305 97 ';
str=[str '3 79 175 299 306 98 4 80 176 300 307 99]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'RobustSigs');
str='[1 39 40 78 79 81 85 82 86 298 299 305 306]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'BPA Datapost');
VBstr='[2 78 298 305 97 193 273 256 229 39 116 155 174]'; 
MWstr='[81 301 308 100  9 280 288 294 267 250 74 119 166 189]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at BPA
%BPA1_040610m.ini; 
%BPA2_040610m.ini
match1=~isempty(findstr('bpa1_040610m',lower(CFname)));
match2=~isempty(findstr('bpa2_040610m',lower(CFname)));
if match1|match2
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'Ringdown Summary');
str='[1 81 301 308 9 280 267 250 70 74 100 119 166 189 33 ';
str=[str '2 78 298 305 4 80 300 307]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Interactions Summary');
VBstr='[2   78 174 298 305  97 273 256 229]'; 
MWstr='[81 301 308   9 280 288 294 267 250  74 100 119 166 189  33]';
MVstr='[81 301 308   9 280 288 294 267 250  74 100 119 166 189  33]+1';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str  MVstr '+0 ']; %MVars  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Coulee Overall');
str='[1 81 2:4 37:38 5:4:33 6:4:34]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Malin/CJack Overall');
str='[1 81:4:93 244 232 250 267 263 259 82:4:94 245 233 251 268 264 260 2 78 229 248 256 4 80 231 300 307]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Overall');
str='[1 81 116:118 119:4:123 120:4:124 155:157 162:4:166 163:4:167]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Sylmar Overall');
str='[1 81 174:176 177:4:189 178:4:190]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Colstrip Overall');
str='[1 81 97:99 100:4:104 101:4:105]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Probe');
VBstr='[2 78 174  298 305 97 193 116 155]';
MWstr='[81 85 250 301 308 9 280 288 294 267 74 100 104 108 112 119 123 166 162 189 33 127 131 42 46]';
MVstr='[289  295  120  124  167  163  190   34  128  132   43   47  121  125  168  164]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Time & Freqs
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs
str=[str  MVstr '+0 ']; %MVars
str=[str '121 125 168 164']; %IMags
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Probe (ModeMeter)');
str='[1 81 308 100 119 121]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Model Validation #1');
str='[1 81 301 308 9 70 74 100 119 166 189 2 78 174 298 305 97 ';
str=[str '3 79 175 299 306 98 4 80 176 300 307 99]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'RobustSigs');
str='[1 39 40 78 79 81 85 82 86 298 299 305 306]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'BPA Datapost');
VBstr='[2 78 298 305 97 193 273 256 229 39 116 155 174]'; 
MWstr='[81 301 308 100  9 280 288 294 267 250 74 119 166 189]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at BPA2 [BPA2 latest; may need updates]
% BPA2_040610.ini
% BPA2_040716.ini
% BPA1_040903.ini
% BPA2_040921.ini; BPA2_040921m.ini
% BPA2_050215.ini, BPA1_050307.ini
% BPA2_050707.ini
match=~isempty(findstr('bpa2_040610' ,lower(CFname)));
match=match|~isempty(findstr('bpa2_040716' ,lower(CFname)));
match=match|~isempty(findstr('bpa1_040903' ,lower(CFname)));
match=match|~isempty(findstr('bpa2_040921' ,lower(CFname)));
match=match|~isempty(findstr('bpa2_050215' ,lower(CFname)));
match=match|~isempty(findstr('bpa2_050307' ,lower(CFname)));
match=match|~isempty(findstr('bpa2_050707' ,lower(CFname)));
if match
  disp(['In PDCmenu: Match found to ' CFname])
else
  match=~isempty(findstr('bpa' ,lower(CFname)));
  if match 
    disp(['In PDCmenu: No match found to ' CFname])
    disp('Defaulting to latest BPA menus')
  end
end
if match
chansMenu=str2mat(chansMenu,'Ringdown Summary');
str='[1 81 301 308 9 280 267 250 70 74 100 119 166 189 33 ';
str=[str '2 78 298 305 4 80 300 307]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Interactions Summary');
VBstr='[2   78 174 298 305  97 273 256 229]'; 
MWstr='[81 301 308   9 280 288 294 267 250  74 100 119 166 189  33]';
MVstr='[81 301 308   9 280 288 294 267 250  74 100 119 166 189  33]+1';
%WAPA quantities
VBstr=[' [' VBstr ' [ 2 17 51]+370]']; 
MWstr=[' [' MWstr ' [11  20  26  54  58  66  70  76]+370]'];
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str  MVstr '+0 ']; %MVars  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Coulee Overall');
str='[1 81 2:4 37:38 5:4:33 6:4:34]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Malin/CJack Overall');
VBstr='[78 229]'; 
MWstr='[81 85 250 267]';
MVstr='[81 85 250 267]+1';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str  MVstr '+0 ']; %MVars  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Overall');
str='[1 81 116:118 155:157 [119 123 162 166] [119 123 162 166]+1 [119 123 162 166]+2]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Sylmar Overall');
str='[1 81 174:176 177:4:189 178:4:190 179:4:191]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Colstrip Overall');
str='[1 81 97:99 100:4:104 101:4:105]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Probe');
VBstr='[2 78 174  298 305 97 193 116 155]';
MWstr='[81 85 250 301 308 9 280 288 294 267 74 100 104 108 112 119 123 166 162 177:4:189 33 127 131 42 46]';
MVstr='[289  295  120  124  167  163  178:4:190   34  128  132   43   47]';
IMstr='[121 125 168 164 179:4:191]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Time & Freqs
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs
str=[str  MVstr '+0 ']; %MVars
str=[str  IMstr '+0 ']; %IMags
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Celilo Probe (ModeMeter)');
str='[1 81 308 100 119 121]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'Model Validation #1');
str='[1 81 301 308 9 70 74 100 119 166 189 2 78 174 298 305 97 ';
str=[str '3 79 175 299 306 98 4 80 176 300 307 99]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'RobustSigs');
str='[1 39 40 78 79 81 85 82 86 298 299 305 306]';
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'BPA Datapost');
VBstr='[2 78 298 305 97 193 273 256 229 39 116 155 174]'; 
MWstr='[81 301 308 100  9 280 288 294 267 250 74 119 166 189]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configuration at SCE
match=~isempty(findstr('sce1x_102402',lower(CFname)));
if match
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'Model Validation Summary #1');
str='[1 63 67 60 22 61]';
chansS=str2mat(chansS,str);
if 0
chansMenu=str2mat(chansMenu,'SCE Datapost');
str='[1 ';                                                  %Time
str=[str '[2   50   31   67   86  105  142  178  214]+2 ']; %Freq
str=[str '[2   50   31   67   86  105  142  178  214]+0 ']; %Vmag
str=[str '[2   50   31   67   86  105  142  178  214]+1 ']; %Vang
str=[str '[5 17 55 34 38 217]] '];                          %MW  
chansS=str2mat(chansS,str);
end
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at WAPA
% wapa_110398.ini
% wapa1.ini
match1=~isempty(findstr('wapa_110398',lower(CFname)));
match2=~isempty(findstr('wapa1',lower(CFname)));
if match1|match2
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'WAPA Summary');
chansS=str2mat(chansS,'[1 2 10 18 4 5 11 20 26]');
chansMenu=str2mat(chansMenu,'Voltage & Frequency Summary');
chansS=str2mat(chansS,'[1 4 2:4 9 10 15 19 24 25]');
chansMenu=str2mat(chansMenu,'Voltage/Angle/Frequency Summary');
chansS=str2mat(chansS,'[1 4 2:4 9:10 15:19 24:25]');
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at WAPA
% wapa_041802.ini
% wapa030504.ini
match1=~isempty(findstr('wapa_041802',lower(CFname)));
match2=~isempty(findstr('wapa030504' ,lower(CFname)));
if match1|match2
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'WAPA Interactions Summary');
VBstr='[2 17 51]'; 
MWstr='[11  20  26  54  58  66  70  76]';
MVstr=' ';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'WAPA Datapost');
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at BCH
% BCH072400.ini 
match=~isempty(findstr('bch072400',lower(CFname)));
if match
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'BCH Interactions1');
str='[1 2 29 50 3 30 51 4 31 52 5 9 13 17 21 ';
str=[str '32 36 40 53 57 61 65 69]'];
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at BCH
% BCH042302.ini
% BCH042302X.ini
match=~isempty(findstr('bch042302',lower(CFname)));
if match
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'BCH Interactions1');
str='[1 2 29 50 3 30 51 4 31 52 5 9 13 17 21 ';
str=[str '32 36 40 53 57 61 65 69 96 97]'];
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'BCH Datapost');
str='[1 2 29 50 3 30 51 4 31 52 5 9 13 17 21 ';
str=[str '32 36 40 53 57 61 65 69 96 97]'];
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at BCH
% BCH050703.ini 
match=~isempty(findstr('bch050703',lower(CFname)));
if match
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'BCH Interactions1');
str='[1 4 31 52 79 2 46 50 77 96 3 30 51 78 97 5 9 13 17 21 32 36 40 ';
str=[str '53 57 61 65 69 80 84 88 92 81 85 89 93 41]'];  
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at BCH
% BCH072403.ini 
match=~isempty(findstr('bch072403',lower(CFname))); 
if match
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'Celilo Probe');
VBstr='[ 2   29   50   77  100]'; 
MWstr='[5 9 13 17 21 32 36 40 53 57 61 65 69 80 84 88 92 103 107 111]';
MVstr='[41]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str  MVstr '+0 ']; %MVars  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'BCH Interactions1');
str='[1 4 31 52 79 102 2 46 50 77 96 100 117 3 30 51 78 97 101 118 5 9 13 17 21 32 36 40 ';
str=[str '53 57 61 65 69 80 84 88 92 81 85 89 93 41 103 107 111]'];  
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at BCH [incomplete?]
% BCH100203X.ini
% BCH031015X.ini
match1=~isempty(findstr('bch100203',lower(CFname))); 
match2=~isempty(findstr('bch031015',lower(CFname)));
if match1|match2 %verify!!
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'Celilo Probe');
VBstr='[2 29 50 77 100]'; 
MWstr='[13 17 21 32 36 40 53 57 65 80 84 88 92 103 107 111]';
MVstr='[41]';
MWstr='[13 17 141 53 57 65 80 84 88 92 103 107 111 124 128 132]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str  MVstr '+0 ']; %MVars  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'BCH Interactions1');
%chansX=
%chansX=[1    4   31   52   79  102  123  140    2   25   27   29   44   46   48   
% 50   73   75   77   96   98  100  115  117  119  121  136  138    3   26   28   
% 30   45   47   49   51   74   76   78   97   99  101  116  118  120  122  137  
% 139    5    9   13   17   21   32   36   40   53   57   61   65   69   80   84   
% 88   92  103  107  111  124  128  132  141   41]
str=     '[ 1   4  31  52  79 102 123 140   2  25  27  29  44  46  48';
str=[str ' 50  73  75  77  96  98 100 115 117 119 121 136 138   3  26  28'];  
str=[str ' 30  45  47  49  51  74  76  78  97  99 101 116 118 120 122 137']; 
str=[str '139   5   9  13  17  21  32  36  40  53  57  61  65  69  80  84']; 
str=[str ' 88  92 103 107 111 124 128 132 141  41]'];
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at BCH [latest]
% BCH042204.ini
% BCH061604.ini 
match1=~isempty(findstr('bch042204',lower(CFname)));
match2=~isempty(findstr('bch061604',lower(CFname)));
match=match1|match2;
if match
  disp(['In PDCmenu: Match found to ' CFname])
else
  match=~isempty(findstr('bch' ,lower(CFname)));
  if match 
    disp(['In PDCmenu: No match found to ' CFname])
    disp('Defaulting to latest BCH menus')
  end
end
if match
chansMenu=str2mat(chansMenu,'Celilo Probe');
VBstr='[2 138 29 50 77 100 121]'; 
MWstr='[13 17 141 53 57 65 80 84 88 92 103 107 111 124 128 132]';
MVstr='[41]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str  MVstr '+0 ']; %MVars  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'BCH Summary');
VBstr='[2 77 100 121]'; 
MWstr='[13 17 80 84 103 128]';
MVstr='[]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str  MVstr '+0 ']; %MVars  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'BCH Interactions1');
VBstr='[2 138 29 50 77 100 121]'; 
MWstr='[5 9 13 17 141 21 32 36 40 53 57 61 65 69 80 84 88 92 103 107 111 124 128 132]';
MVstr='[41]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str  MVstr '+0 ']; %MVars  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at APS [latest]
% APS1_031230.ini 
match=~isempty(findstr('aps1_031230',lower(CFname)));
if match
  disp(['In PDCmenu: Match found to ' CFname])
else
  match=~isempty(findstr('aps1' ,lower(CFname)));
  if match 
    disp(['In PDCmenu: No match found to ' CFname])
    disp('Defaulting to latest APS1 menus')
  end
end
if match
chansMenu=str2mat(chansMenu,'Celilo Probe');
VBstr='[114 95 2]'; 
MWstr='[133 24]';
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
chansMenu=str2mat(chansMenu,'APS Interactions1');
VBstr='[2 21 60 75 89 95 114 153 192]'; 
MWstr='[5  9 13 24 28 32 36 40 44 48 52 63 67 71 77 81 85 98 102 106 110 117 121 125 ';
MWstr=[MWstr '129 133 137 141 145 149 156 160 164 168 172 176 180 184 195 199 203 207]'];
str='[1 ';              %Time
str=[str  VBstr '+2 ']; %Freq
str=[str  VBstr '+0 ']; %VMags
str=[str  VBstr '+1 ']; %VAngs
str=[str  MWstr '+0 ']; %MWs  
str=[str        ']'  ]; %terminate string
chansS=str2mat(chansS,str);
return
end
%****************************************************************

%****************************************************************
%Menus for PDC configurations at Ameren
% AMRN030821X.ini 
match=~isempty(findstr('amrn030821',lower(CFname)));
if match
disp(['In PDCmenu: Match found to ' CFname])
chansMenu=str2mat(chansMenu,'Ameren Interactions1');
str='[1 4  25   2  23  26   3  24  27   7  28  32  8  29  33]';
chansS=str2mat(chansS,str);
return
end
%****************************************************************

disp(['In PDCmenu: No match found to ' CFname])
return

%end of PSMT function


