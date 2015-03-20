function [rvarbnd,rvarlimit]=rvarbound(rtrue,N)
%*****************************
%Usage
%Input
%  rtrue=true correlation function
%	N=sample size for estimated r
%Output
%*****************************
L=length(rtrue);
r=[rtrue(L:-1:2) rtrue];
%for i=-(L-1-k):(L-1-k),
rvarsum=0;
for i=-(L-1):1:(L-1)
      m=i+L;  %convert the i index to a matlab index
      rvarsum=rvarsum+(r(m)^2);
end
rvarbnd=2*rvarsum/N;
rvarlimit=1*rvarsum/N;