%function InitialVI
%
% NOTE: phasors here represent peak values, not rms
% WARNING: NOTE CONJ OPERATION WHEN TRANSPOSING COMPLEX ARRAYS!!
% Note call to seqTXmats
% 
% Last modified 03/12/02.  jfh

disp(' ')
disp('In M-File InitialVI:')

[TX,TXI]=seqTXmats;			%sequence transformations

%----------------------------------------------------------------
if defABC==0	%(define V & I in symmectrical coordinates)
	disp('WARNING--MAY BE A CONJ PROBLEM WITH SYMMETRICAL COORDINATES')
  pause
  if TXcase==0
		VIcomment='VIsym initialization 0: general conditions on V and I';
		VsymMag =[0.9067 0.0318 0.0318];			%peak voltages
		VsymAngD=[0.0000 153.0045 -153.0045];	%degrees
		IsymMag =[1.1100 0.0666 0.0666];			%peak currents
		IsymAngD=[30.0000 77.4802 -17.4802];	 %degrees
	end
	if TXcase==-1
		VIcomment='VIsym initialization -1: positive sequence only';
		VsymMag =[10 0 0];
		VsymAngD=[00 0 0];
		IsymMag =[35 0 0];
		IsymAngD=[00 0 0];
	end
	if TXcase==-2
		VIcomment='VIsym initialization -2: V +seq, I -seq';
		VsymMag =[10 0 0];
		VsymAngD=[00 0 0];
		IsymMag =[0 35 0];
		IsymAngD=[00 0 0];
	end
	if TXcase==-3
		VIcomment='VIsym initialization -3: unbalanced';
		VsymMag =[10 0.2 0];
		VsymAngD=[00 00 00];
		IsymMag =[35 1.0 0];
		IsymAngD=[00 00 00];
	end
	if TXcase==-4
		VIcomment='VIsym initialization -4: slight V unbalance';
		VsymMag =[10 0.1 0];
		VsymAngD=[00 00 00];
		IsymMag =[35 00 00];
		IsymAngD=[00 00 00];
	end
	if TXcase==-5
		VIcomment='VIsym initialization -5: slight zero seq in V';
		VsymMag =[10 00 0.1];
		VsymAngD=[00 00 00 ];
		IsymMag =[35 00 00 ];
		IsymAngD=[00 00 00 ];
	end
	VsymAng=VsymAngD*DEGI;
	IsymAng=IsymAngD*DEGI;
   Vsym=(VsymMag.*exp(j*VsymAng));
	Isym=(IsymMag.*exp(j*IsymAng));
	Vabc=(TXI*(Vsym.'))';
	Iabc=(TXI*(Isym.'))';
	VabcMag=abs(Vabc);
	IabcMag=abs(Iabc);
	VabcAng=angle(Vabc).*(VabcMag>1000*eps);
	IabcAng=angle(Iabc).*(IabcMag>1000*eps);	
	VabcAngD=VabcAng/DEGI;
	IabcAngD=IabcAng/DEGI;
end	

%----------------------------------------------------------------
if defABC==1	%(define V & I in abc coordinates)
	if TXcase==0 
		VIcomment='VIabc initialization 0: general conditions on V and I';
		VabcMag =[0.85 0.96 0.91];	%peak voltages
		VabcAngD=[0 -120 120];	   	%degrees
		IabcMag =[1.20 1.15 0.98];	%peak currents
		IabcAngD=[30 -90 150];	   	%degrees
	end
	if TXcase==-1
		VIcomment='VIabc initialization -1: V balanced, I balanced';
		VabcMag =[10 10 10];	
		VabcAngD=[0 -120 120];
		IabcMag =[35 35 35];	
		IabcAngD=[30 -90 150];		
	end
	if TXcase==-2
		VIcomment='VIabc initialization -2: V unbalanced, I unbalanced';
		VabcMag =[10 30 15];
		VabcAngD=[30 -60 145];
		IabcMag =[1.20 1.15 0.98];
		IabcAngD=[30 -90 150];
	end
	if TXcase==-3
		VIcomment='VIabc initialization -3: V unbalanced, I unbalanced';
		VabcMag =[0.85 0.96 0.91];	 %peak voltages
		VabcAngD=[0 -120 120];	 	   %degrees
		IabcMag =[1.20 1.15 0.98];  %peak currents
		IabcAngD=[30 -90 150];		   %degrees
	end
	VabcAng=VabcAngD*DEGI;
	IabcAng=IabcAngD*DEGI;
	Vabc=(VabcMag.*exp(j*VabcAng));
	Iabc=(IabcMag.*exp(j*IabcAng));
	Vsym=(TX*(Vabc.')).';
	Isym=(TX*(Iabc.')).';
	VsymMag=abs(Vsym);
	IsymMag=abs(Isym);
	VsymAng=angle(Vsym).*(VsymMag>1000*eps);
	IsymAng=angle(Isym).*(IsymMag>1000*eps);
	VsymAngD=VsymAng/DEGI;
	IsymAngD=IsymAng/DEGI;
end

%----------------------------------------------------------------
if traceTX==1
	VIcomment=VIcomment
	Vabc=Vabc
	Iabc=Iabc
	VabcMag=VabcMag
	VabcAngD=VabcAng*DEG
	IabcMag=IabcMag
	IabcAngD=IabcAng*DEG
	Vsym=Vsym
	VsymMag=VsymMag
	VsymAngD=VsymAng*DEG
	Isym=Isym
	IsymMag=IsymMag
	IsymAngD=IsymAng*DEG
end

%Compensate for spelling changes
Vabcmag=VabcMag;
Iabcmag=IabcMag;
Vabcang=VabcAng;
Iabcang=IabcAng;
Vsymmag=VsymMag;
Isymmag=IsymMag;
Vsymang=VsymAng;
Isymang=IsymAng;


disp(' ')
disp('RETURN FROM M-FILE InitialVI')
disp(' ')

return

%end of DXD utility InitialVI


