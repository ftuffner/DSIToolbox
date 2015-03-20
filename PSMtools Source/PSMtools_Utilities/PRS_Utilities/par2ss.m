function [a,b,c,d]=par2ss(res,pol,k);
%
%RES2SS [a,b,c,d]=par2ss(res,pol,k);
%       Converts a parallel SISO Transfer function to 
%       state-space form.
%
%       res = residues, (arranged as complexc conjugates)
%       pol = poles of residues.
%       k   = feedforward gain.
%       a,b,c,d = state-space matrices.
%

% Modified by Jeff Johnson.  5/10/93
% Modified to account for when the k matrix is empty.

res=res(:);pol=pol(:);n=length(res);
if n==0;stop;end;
if isempty(k)
  k=0;
end
[a,b,c,d]=tf2ss(k,1);
j=1;
while j <= n;
   if abs(imag(pol(j)))<100*eps;
      [a2,b2,c2,d2]=tf2ss([0 res(j)],[1 -pol(j)]);
      [a,b,c,d]=parallel(a,b,c,d,a2,b2,c2,d2);
      j=j+1;
   else
      num=[0 2*real(res(j)) real(-res(j)*pol(j+1)-res(j+1)*pol(j))];
      den=[1 -2*real(pol(j)) abs(pol(j))^2]; 
      [a2,b2,c2,d2]=tf2ss(num,den);
      [a,b,c,d]=parallel(a,b,c,d,a2,b2,c2,d2);
      j=j+2;
   end;
end; 


%end of PSM script