%PM8 Model
%Model PM8: Basic model for Malin-Round Mtn MW response to Brake060700A (positive gain)
if 1
polN = ...
[-0.15419956706393 + 2.43691280436634i;
 -0.15419956706393 - 2.43691280436634i;
 -0.09754281439425 + 1.66058598793799i;
 -0.09754281439425 - 1.66058598793799i;
 -0.20420514486904 + 4.17533672226152i;
 -0.20420514486904 - 4.17533672226152i;
 -0.80977979323152 + 4.77815826036951i;
 -0.80977979323152 - 4.77815826036951i;
 -0.93559712934217 + 2.41744059422614i;
 -0.93559712934217 - 2.41744059422614i;
 -0.21773720547956 + 3.50367820274193i;
 -0.21773720547956 - 3.50367820274193i;
 -0.20380215340867 + 5.10532348969056i;
 -0.20380215340867 - 5.10532348969056i;
 -0.48401505410779 + 6.53044206852783i;
 -0.48401505410779 - 6.53044206852783i];
resN = ...
[-0.06481880377600 + 0.08402103193323i;
 -0.06481880377600 - 0.08402103193323i;
 -0.03401862116192 + 0.06850146990542i;
 -0.03401862116192 - 0.06850146990542i;
  0.00257847075459 + 0.11031507438192i;
  0.00257847075459 - 0.11031507438192i;
 -0.26787066673572 + 0.15803841601557i;
 -0.26787066673572 - 0.15803841601557i;
  0.24791301549663 + 0.13501750601199i;
  0.24791301549663 - 0.13501750601199i;
  0.02181405038964 + 0.00841169160788i;
  0.02181405038964 - 0.00841169160788i;
  0.01184359971217 - 0.00655104907378i;
  0.01184359971217 + 0.00655104907378i;
  0.02125660608642 - 0.01898113797930i;
  0.02125660608642 + 0.01898113797930i];
  resN=-resN;  %Reverse model gain (initially negative) 
  thru=0;
  [A,B,C,D]=par2ss(resN,polN,thru);
end
%*********************************************************************

%*********************************************************************
%Determine state-space parameters & Ideal impulse response
[NUM,DEN] = ss2tf(A,B,C,D,1);
disp('System poles/2pi:')
disp(roots(DEN)./(2*pi))
disp('System zeros/2pi:')
disp(roots(NUM)./(2*pi))
[NUM,DEN] = ss2tf(A,B,C,D,1);
[R,P,K] = residue(NUM,DEN);
disp('System residues & feedforward:')
disp(R)   %(Residues do not change with D)
disp(K)
tstep=0.02;
disp('Display of Ideal Impulse Response');
tstep=0.02; ImpStep=tstep; 
time=[0:tstep:100]; timepts=length(time);
IrespA=impulse(A,B,C,D,1,time);  %Ideal impulse response
figure; plot(time,IrespA)
Ptitle{1}='Ideal Impulse Response';
title(Ptitle)
xlabel('Time in Seconds')
disp('Display of Self-Convolution of Ideal Impulse Response');
npts=length(IrespA);
IrespA2=[IrespA(npts:-1:2)' IrespA']'; %figure; plot(IrespA2)
ACVrespU=xcorr(IrespA2,'unbiased'); %figure; plot(ACVrespU)
ACVrespB=xcorr(IrespA2,  'biased'); %figure; plot(ACVrespB) 
npts1=length(ACVrespU); centrPt=fix(npts1/2)+1;
ACVrespU=2*ACVrespU(centrPt:npts1); 
ACVrespB=2*ACVrespB(centrPt:npts1); 
%figure; plot([ACVrespU ACVrespB])
figure; plot(time,[ACVrespU(1:timepts) ACVrespB(1:timepts)])
Ptitle{1}='Self-Convolutions of Ideal Impulse Response';
title(Ptitle)
xlabel('Time in Seconds')
%Calculate true autocovariance function
[Rtrue,alpha,p]=TrueCovS(NUM,DEN,length(time),1/tstep);
Rtrue=real(Rtrue(2:length(Rtrue)));
scale=1; 
%scale=max(ACVrespB)/max(Rtrue);
 scale=max(IrespA)/max(Rtrue);
Rtrue=Rtrue*scale;
%figure; plot(time,[ACVrespB(1:timepts) Rtrue])
 figure; plot(time,[IrespA Rtrue])
Ptitle{1}='Checks on ideal autocovariance';
title(Ptitle)
xlabel('Time in Seconds')
keybdok=promptyn('In ModelCksPN2: Do you want the keyboard? ', 'n');
if keybdok
  disp('In ModelCksPN2: Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
  %polN(3)=-imag(polN(3))*0.02+i*imag(polN(3)); polN(4)=conj(polN(3));
end
%*********************************************************************

return

%End of PSMT utility