function  [CaseCom,timeN,tstepN,swlocs,roughlocs,smoothdef]...
    =CkTsteps(caseID,casetime,CaseCom,time,tstep,smoothdef);
% CkTsteps.m checks for repeated and irregular time steps 
% [CaseCom,timeN,tstepN,swlocs,roughlocs,smoothdef]...
%    =CkTsteps(caseID,casetime,CaseCom,time,tstep,smoothdef);
%
% Special functions used:
%  (none)
%  
%  Modified 02/19/04.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

if ~exist('smoothdef'), smoothdef=[];    end; 
if isempty(smoothdef),  smoothdef=0.005; end; 

str=['In CkTsteps: Using smoothdef= ' num2str(smoothdef)];
disp(str); CaseCom=str2mat(CaseCom,str); 

%Initialize outputs
timeN=time; tstepN=tstep; swlocs=[]; roughlocs=[];

%*************************************************************************
%Initialize plot headers
Ptitle{1}=' ';
Ptitle{2}=['caseID=' caseID '  casetime=' casetime];
%*************************************************************************

SampleRate=1/tstep;
maxpoints=length(time);
tsteps=time(2:maxpoints)-time(1:maxpoints-1);

%*************************************************************************
%Check for repeated points and irregular time steps
eps=0.001*tstep;
swlocs=find(abs(time(1:maxpoints-1)-time(2:maxpoints))<eps)';
swtimes=time(swlocs);
strs='In CkTsteps: Characteristics of extracted data';
strs=str2mat(strs,['  tstep      = ' num2str(tstep)]);
strs=str2mat(strs,['  SampleRate = ' num2str(SampleRate)]);
if ~isempty(swlocs)
  strs=str2mat(strs,['  Time axis indicates ' num2str(length(swlocs)) ' switching times']);
  for n=1:length(swlocs)
    strs=str2mat(strs,['    Switch time ' num2str(n) ' = ' sprintf('%3.6f',swtimes(n))]);
  end
end
disp(strs); %keyboard
CaseCom=str2mat(CaseCom,strs);
tstepsA=tsteps(find(tsteps>0));
Lmax=find(tstepsA==max(tstepsA)); Lmax=Lmax(1); 
Lmin=find(tstepsA==min(tstepsA)); Lmin=Lmin(1);
maxfrac=tstepsA(Lmax)/tstep; minfrac=tstepsA(Lmin)/tstep;
roughness=max(abs(maxfrac-1),abs(minfrac-1));
roughtime=roughness>smoothdef; 
if roughtime
  str1=['  Irregular time steps:'];
  str2=['  Maximum time step =' num2str(maxfrac) '  of standard'];
  str3=['            at  time= ' num2str(time(Lmax)) ' sec.  ' num2str(Lmax) ' samples' ];
  str4=['  Minimum time step =' num2str(minfrac) '  of standard'];
  str5=['            at  time= ' num2str(time(Lmin)) ' sec.  ' num2str(Lmin) ' samples' ];
  strs=str2mat(str1,str2,str3,str4,str5); disp(strs)
  CaseCom=str2mat(CaseCom,strs);
  h=figure; plot(time)
  Ptitle{1}='Irregular time steps';
  title(Ptitle)
  xlabel('Time in Samples')
  ylabel('Time in seconds')
  h=figure; plot(tsteps)
  Ptitle{1}='Irregular time steps';
  title(Ptitle)
  xlabel('Time in Samples')
  ylabel('Time Steps')
  roughck1=abs(tsteps/tstep-1); %figure; plot(roughck1)
  roughlocs=find(roughck1>smoothdef);
  str=['Number of rough time steps = ' num2str(length(roughlocs))];
  disp(str); CaseCom=str2mat(CaseCom,str);
end
%*************************************************************************  

disp('Returning from CkTsteps')
disp(' ')
return

%end of PSMT function

