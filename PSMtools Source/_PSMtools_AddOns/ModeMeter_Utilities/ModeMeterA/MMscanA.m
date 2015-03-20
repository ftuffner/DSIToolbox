function [S,C,Rhat,U,YY,Cnd]=MMscanA(x,Nest,Kcor,Mest,Nbar,lap,srate,TrackFrqs);
%
%  [S,C,Rhat,U,YY,Cnd]=MMscanA(x,Nest,Kcor,Mest,Nbar,lap,srate,F1,F2);
%
% INPUTS: x=signal(s) to process
%         Nest=Initial denominator order for estimator
%         Kcor=length of correlation matrix
%         Mest=Initial numerator order for estimator
%         Nbar=Length of processing window in samples
%         lap =overlap of successive processing windows 
%         srate=sampling rate
%         F1=approximate mode frequency for sorting purposes
%         F2=approximate mode frequency for sorting purposes
%
% OUTPUTS: S=matrix of s-domain poles, where each column is from a new time
%            block and the elements in each column are ordered by energy
%          C=matrix of complex residues, where each column is from a new time
%            block and the elements in each column are ordered by energy
%          Rhat=matrix of autocorrelation functions where each column is 
%            from a new time block
%          U=matrix of z-domain poles, where each column is from a new time
%            block and the elements in each column are ordered by energy
%          YY=a matrix where each column is from a new time block and the 
%             elements of the column are the component energies ordered 
%             from largest to smallest.
%
% Functions called by MMscanA:
%    ARMAovr
%    Sortpole1   
%
%  Developed by J. W. Pierre, U. Wyoming
%  Updated 12/3/99 -- JWP
%
%  
% Last modified 10/23/00.  jfh
%
% Integration into PSM_Tools by J. F. Hauer, 
%   Pacific Northwest National Laboratory.


%Set working parameters
maxpoints=length(x); %overall length of the data
L=Nbar;              %Length of processing window in samples
nlap=fix(Nbar*lap);	%Overlap of successive processing windows in samples
Nshift=Nbar-nlap;    %Advance of processing window in samples
P=Nshift;
Dblocks=fix((maxpoints-Nbar)/Nshift)+1;  %Number of data blocks

%Initialize storage
U=zeros(Nest,Dblocks);
S=zeros(Nest,Dblocks);
C=zeros(Nest,Dblocks);
Rhat=zeros(Nest,Dblocks);
YY=zeros(Nest,Dblocks);
Cnd=zeros(1,Dblocks);
w=0; %window currently disabled

%*************************************************************************
for Nbk=1:Dblocks
  %disp(Nbk)
  index=1+(((Nbk-1)*P):1:((Nbk-1)*P+L-1));                       %Index for data block n
  RhatN=RHATFUNC(x(index),Kcor+Mest,w);                       %Estimate correlation function
  [a,spoles,zpoles,cnd]=ARMAovr(RhatN,Nest,Kcor,Mest,srate);  %Fit ARMA model for data block n
  [ur,cr,sr,Y]=Sortpole1(zpoles,RhatN,spoles,TrackFrqs);
  %%%c=prnyph3(zpoles,RhatN);  % find the residues
  %presort to get only positive frequencies
  %%%[junk,I]=sort(imag(spoles));
  %%%spoles=spoles(I);
  %%%zpoles=zpoles(I);
  %%%c=c(I);
  %%%jnk=(imag(spoles)<0);
  %%%cmplxnu=sum(jnk);
  %%%spoles=spoles(cmplxnu+1:Nest);
  %%%zpoles=zpoles(cmplxnu+1:Nest);
  %%%c=c(cmplxnu+1:Nest);
  %end of presort
  %%%[ur,cr,sr,Y]=orderener(zpoles,c,spoles,Kcor);
  %below is an additional sort to make sure the .27 Hz mode is first
  %the .43 Hz mode is second and the real mode is 3rd
  %%%Q=5;  %number of high energy terms for additional sort
  %%%[junk,I]=sort((abs(abs(imag(sr(1:Q))/(2*pi))-0.274)));
  %[junk,I]=sort(-real(sr(1:Q)));
  %%%sr(1:Q)=sr(I);
  %%%ur(1:Q)=ur(I);
  %%%cr(1:Q)=cr(I);
  %%%Y(1:Q)=Y(I);
  %end of additional sort
  Rhat(1:length(RhatN),Nbk)=RhatN;
  U(1:length(ur),Nbk)=ur;
  S(1:length(sr),Nbk)=sr;
  C(1:length(cr),Nbk)=cr;
  YY(1:length(Y),Nbk)=Y;
  Cnd(1,Nbk)=cnd;
end
%*************************************************************************

%end of ModeMeter script
