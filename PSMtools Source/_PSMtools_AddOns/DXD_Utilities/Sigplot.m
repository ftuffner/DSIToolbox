function [h]=Sigplot (time,signal,Ptitle,Pscale,Gtags)
%
%	jfh m-file Sigplot:
%		[h]=Sigplot (time,signal,Ptitle,Pscale,Gtags)
%
%		Displays time and signal data.
%
%	THIS FUNCTION HAS A LOT OF OPTIONS--READ THE CODE!!
%
% Last modified 09/01/99.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

Nplots=size(Ptitle,1);
Nscales=size(Pscale,1);	%number of rows
Ntraces=size(signal,2);
	
h=figure;
for n=1:Nplots
	T1=1+(n-1)*Ntraces/Nplots;
	Tf=n*Ntraces/Nplots;
	subplot(Nplots,1,n)
	plot(time,signal(:,T1:Tf))
	title(Ptitle(n,:))
	set(gca,'TickDir','out')
end
pause
for m=1:Nscales
	for n=1:Nplots
	subplot(Nplots,1,n)
	set(gca,'xlim',Pscale(m,:))
	end
  pause
end

