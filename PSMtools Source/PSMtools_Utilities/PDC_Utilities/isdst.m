% Function to determine whether a given time is
% Daylight Saving Time or not.

function f = isdst(datnm,yr,mon,dom,hr)
dow=weekday(datnm)-1;
f = 1;

if (mon>4 & mon<10), return; end;
if (mon==4 & dom>7), return; end;
if (mon==4 & dom<=7 & dow==0 & hr>=7), return; end;
if (mon==4 & dom<=7 & dow>0 & dom>dow), return; end;

if (mon==10 & dom<25), return; end;
if (mon==10 & dom>=25 & dow==0 & hr<6), return; end;
if (mon==10 & dom>=25 & dow>0 & dom-24-dow < 1), return; end;

f = 0;
return