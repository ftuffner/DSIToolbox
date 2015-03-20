function rvar=rvariance(rtrue,N)
%*****************************
%Usage
%Input
%  rtrue=true correlation function
%	N=sample size for estimated r
%Output
%*****************************
L=length(rtrue);
r=[rtrue(L:-1:2) rtrue];
for k=0:L-1,
   rvar(k+1)=0;
   for i=-(L-1-k):(L-1-k),
      m=i+L;  %convert the i index to a matlab index
      %rvar(k+1)=rvar(k+1)+(1-(k+abs(i))/L)*(r(m)^2+r(m+k)*r(m-k));
		rvar(k+1)=rvar(k+1)+(N-k-abs(i))*(r(m)^2+r(m+k)*r(m-k));
   end
end
rvar=rvar/(N^2);
