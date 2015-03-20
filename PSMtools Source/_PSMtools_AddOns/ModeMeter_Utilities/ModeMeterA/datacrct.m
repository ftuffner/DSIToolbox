function z=datacrct(x,thresh)
%****************************
%data correction for missing data
%usage:  z=datacrct(x,thresh)
%inputs:
%   x=input data
%   thresh=magnitude considered out of range indicating in correct data
%output
%   y=corrected data by linearly interpolating to correct for missing data
%****************************
z=x;  %Initialize output as input
N=length(x);  %total length of data
%locate the start and stop indexes of poor data
Istart=[];
Istop=[];
u=(abs(x)>thresh);  %vector of ones (bad data) and zeros(good data)
%special case for first sample
if u(1)==1
   Istart=[Istart 1];
end
if (u(1)==1)&(u(2)==0)
   Istop=[Istop 1];
end
%samples 2 through N-1
for n=2:(N-1)
   if (u(n)==1)&(u(n-1)==0)
      Istart=[Istart n];
   end
   if (u(n)==1)&(u(n+1)==0)
      Istop=[Istop n];
   end
end
%special case for last sample
if u(N)==1
   Istop=[Istop N];
end
if (u(N)==1)&(u(N-1)==0)
   Istart=[Istart N];
end
%now that the starting and stopping points of poor strings
%of data are stored in Istart and Istop
%we correct the data by linear interpolation
if length(Istart)>0
   for m=1:length(Istart)
      if Istart(m)==1   %special case if first data point is poor
         z(1:Istop(1))=x(Istop(1)+1);
      elseif Istop(m)==N   %special case if last data point is poor
         z(Istart(m):N)=x(Istart(m)-1);
      else
         slope=(x(Istop(m)+1)-x(Istart(m)-1))/(Istop(m)-Istart(m)+2);
         for j=Istart(m):Istop(m)
            z(j)=z(j-1)+slope;
         end
      end
   end
end
