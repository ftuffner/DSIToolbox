function C=PRNYPH3(u,f)
%*************************
%
%*************************
n=length(u);
N=length(f);
%for i=1:N,
%  for j=1:n,
%    U(i,j)=u(j)^(i-1);
%  end
%end
junk=ones(N,1)*u.';
power=(0:1:(N-1))'*ones(1,n);
U=junk.^power;
C=U\f;
