function [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,PDCfiles]...
   =PDCload0(caseID,PDCfiles,SigMask,CaseCom,decfacX,loadopt,saveopt,trackX)
	
% PDCload0.m is the main driver in the logic that retrieves and 
% restructures PDC phasor data saved as .mat files.
%  [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,PDCfiles]...
%    =PDCload0(caseID,PDCfiles,SigMask,CaseCom,decfacX,loadopt,saveopt,trackX)
%
% Last modified 06/29/98.  jfh

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


global Kprompt ynprompt
SaveFile='';

if nargin==7
	disp('In PDCload0: old input list.  Need entry for LOADOPT.')
	trackX=saveopt
	saveopt=loadopt
	loadopt=1
end

%Determine number of files to load
nXfiles=size(PDCfiles,1);
disp(['In PDCload0: Seeking data from ' sprintf('%2.1i',nXfiles) ' files:'])
disp(PDCfiles)

%Clear storage
PMUsigs=[]; PMUfreqs=[]; RMSsigs=[];
chankeyX=''; namesX='';
PSMsigsX=[];

%Save original case comments
CaseCom0=CaseCom;

%*************************************************************************
%Proceed to extract data
for N=1:nXfiles
  PDCfile=PDCfiles(N,:);  close all;
  CaseCom=CaseCom0;
   if (loadopt==1) 
     [PMUsigs,PMUfreqs,tstep,PMUnames,PhsrNames,Phsrkey,PDCfile,CaseCom]...
      =PDCload1(caseID,PDCfile,PMUsigs,PMUfreqs,CaseCom,saveopt,trackX); end
   if (loadopt==2) 
     [PMUsigs,PMUfreqs,tstep,PMUnames,PhsrNames,Phsrkey,PDCfile,CaseCom]...
      =PDCload2(caseID,PDCfile,PMUsigs,PMUfreqs,CaseCom,saveopt,trackX); end
end
%*************************************************************************

CaseCom=CaseCom0;

return

%end of PSM script

