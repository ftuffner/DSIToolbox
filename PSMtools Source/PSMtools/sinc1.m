function w=sinc1(x)
%  w=sinc1(x)
%  basic function for computing sin(pi*x)/(pi*x)

sincpts=max(size(x));
if sincpts<=0
   EXCOM1=sprintf('In sinc1: Empty input array');
   EXCOM2=sprintf('In sinc1: Processing paused - press any key to continue');
   disp(str2mat(EXCOM1,EXCOM2))
   pause
end
w=ones(1,sincpts);
index=find(x);
w(index)=sin(pi*x(index))./(pi*x(index));

