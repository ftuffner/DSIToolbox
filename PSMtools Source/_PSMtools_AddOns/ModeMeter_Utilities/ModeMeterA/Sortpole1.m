function [ur,cr,sr,Y]=sortpole1(zpoles,rhat,spoles,TrackFrqs)
%Sort poles to place critical modes at top of list
%  [ur,cr,sr,Y]=sortpole1(zpoles,rhat,spoles)
%
% inputs:  zpoles=zplane poles
%			rhat=correlation function of appropriate length
%			spoles=splane poles
%         F1=approximate mode frequency for sorting purposes
%         F2=approximate mode frequency for sorting purposes
% Outputs:
%			ur=ordered z-plane poles
%			cr=residues
%			sr=s-plane poles
%			Y=energies
%
%  Note:  This program should be modified to be more appropriate for ARMA
%  problem in general.
%
%  Developed by J. W. Pierre at U. Wyoming
%  Updated 12/3/99 (JWP)
%
% Functions called by Sortpole1:
%    prnyph3
%    orderener
%  
%  
% Last modified 10/23/00.  jfh
%*************************************************************************

F1=TrackFrqs(1);   %Temporary
F2=TrackFrqs(2);   %Temporary

%*************************************************************************
K=length(rhat);
N=length(spoles);
c=PRNYPH3(zpoles,rhat);  % find the residues
%presort to get only positive frequencies
[junk,I]=sort(imag(spoles));
spoles=spoles(I);
zpoles=zpoles(I);
c=c(I);
jnk=(imag(spoles)<0);
cmplxnu=sum(jnk);  %number of complex pole pairs
spoles=spoles(cmplxnu+1:N);  %this spoles contains real poles and positive freq. poles of complex pole pairs
zpoles=zpoles(cmplxnu+1:N);
c=c(cmplxnu+1:N);
%end of presort
%*************************************************************************

%*************************************************************************
[ur,cr,sr,Y]=orderener(zpoles,c,spoles,K);
%below is an additional sort to make sure the intertie mode is first
Q=5;  %number of high energy terms for additional sort
%%[junk,I]=sort((abs(abs(imag(sr(1:Q))/(2*pi))-0.26)));
[junk,I]=sort((abs(abs(imag(sr(1:Q))/(2*pi))-F1)));
%[junk,I]=sort(-real(sr(1:Q)));
sr(1:Q)=sr(I);
ur(1:Q)=ur(I);
cr(1:Q)=cr(I);
Y(1:Q)=Y(I);
%*************************************************************************

%*************************************************************************
%sort to make 0.43 Hz mode second in list
%%[junk,I]=sort((abs(abs(imag(sr(2:Q))/(2*pi))-0.45)));
[junk,I]=sort((abs(abs(imag(sr(2:Q))/(2*pi))-F2)));
sr(2:Q)=sr(I+1);
ur(2:Q)=ur(I+1);
cr(2:Q)=cr(I+1);
Y(2:Q)=Y(I+1);
%end of additional sort
%*************************************************************************

%end of ModeMeter script 