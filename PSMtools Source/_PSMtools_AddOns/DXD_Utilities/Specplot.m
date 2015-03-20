function Specplot (freq,spectrum,Ptitle,Pscale)

Nplots=size(Ptitle,1);
Nscales=size(Pscale,1);	%number of rows
Ntraces=size(spectrum,2);

h=figure;
figure(h)
for n=1:Nplots
	F1=1+(n-1)*Ntraces/Nplots;
	Ff=n*Ntraces/Nplots;
	subplot(Nplots,1,n)
	plot(time,spectrum(:,F1:Ff))
	title(Ptitle(n,:))
end
pause
for m=1:Nscales
	for n=1:Nplots
	subplot(Nplots,1,n)
	set(gca,'xlim',Pscale(m,:))
	end
	pause
end

%end of PSM script


