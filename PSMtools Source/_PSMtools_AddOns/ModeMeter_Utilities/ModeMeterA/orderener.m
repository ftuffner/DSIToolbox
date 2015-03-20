function [ur,cr,sr,Y]=orderener(u,c,s,K)
%***************************
%usage: [ur,cr,sr,Y]=orderener(u,c,s,K)
%inputs:
%			u=z-plane poles
%			c=residues
%			s=s-plane poles
%			K=length
%Outputs:  
%			ur=ordered z-plane poles
%			cr=residues
%			sr=s-plane poles
%			Y=energies
% see also reduce.m
%***************************
N=length(u);
k=(0:N-1)';
Matr=(diag(c)*((u*ones(1,K)).^(ones(size(u))*(0:K-1))));
Ener=sum((Matr.*conj(Matr))');
[Y,I]=sort(Ener);
Y=Y(N:-1:1)';
I=I(N:-1:1);
ur=u(I);
cr=c(I);
sr=s(I);
