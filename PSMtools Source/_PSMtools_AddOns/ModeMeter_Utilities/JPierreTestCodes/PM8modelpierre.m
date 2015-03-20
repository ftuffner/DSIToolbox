%PM8 Model
%Model PM8: Basic model for Malin-Round Mtn MW response to Brake060700A (positive gain)
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
  %find the transfer function
  [b,a]=residue(resN,polN,0);
  b=real(b);
  %b=b/a(1);
  %a=a/a(1);
  Fs=10;
  T=1/Fs;
  L=50*Fs;
  %find the impulse response
  for k=0:L
     h(k+1)=resN.'*exp(polN*T*k);
  end
  h=real(h);
  %figure 1 impulse response
  figure(1)
  plot(0:L,real(h))
  %pause
  %approximate the correlation function using conv
  hrev=h(length(h):-1:1);
  rconvmethod=conv(h,hrev)/Fs;
  %figure 2 approximate correlation function
  figure(2)
  plot(0:L,rconvmethod((L+1):(2*L+1)))
  %compute the true correlation function
  %%[r,junk,junk]=TrueCovS(b,a,L,Fs);
  [r,junk,junk]=RtrueCt(b,a,L,Fs);
  %figure 3 both the approximate and true
  figure(3)
  plot(0:L,r,'b',0:L,rconvmethod((L+1):(2*L+1)),'r')
  %plot(0:6000,r/max(r),'b',0:6000,rconvmethod(6001:12001)/max(rconvmethod),'r')
  %figure 4 the true autocorrelation function
  figure(4)
  plot(0:L,r)

%*********************************************************************
%variance of correlation estimate
N=30*60*Fs;  %30 minutes
figure(5)
rvar=rvariance(r,N);
plot(0:L,rvar)   %fig. 5 variance

figure(6)
plot(0:L,r,0:L,sqrt(rvar));  
figure(7)
plot(0:L,r,'-',0:L,r+sqrt(rvar),'--',0:L,r-sqrt(rvar),'--')
%*********************************************************************
