function y = Detrend1(sigs,Mtrend)
%
% function y = Detrend1(sigs,Mtrend)
%				   
% Mtrend	Mode for removing signal trends.  Primary options are
%	1		Remove initial value
%	2		Remove average value			
%	3		Remove least-squares fitted ramp
%	4		Remove final value
%
%  Last modified 01/09/02.  jfh

nsigpts=size(sigs,1);
nsigs=size(sigs,2);
%
if Mtrend<=0
	y=sigs; end

if Mtrend==1
	y=sigs-ones(nsigpts,1)*sigs(1,:); end
				
if Mtrend==2
	y=sigs-ones(nsigpts,1)*sum(sigs)/nsigpts; end				

if Mtrend==3
	LSmat = [(1:nsigpts)'/nsigpts ones(nsigpts,1)];
	y=sigs-LSmat*(LSmat\sigs); end
	
if Mtrend==4
	y=sigs-ones(nsigpts,1)*sigs(nsigpts,:); end
	

	
%end of PSM script

