function [CaseCom]=ModeDisp1(caseID,casetime,CaseCom,SigName,...
  Poles0,Zeros0,DispType,PoleCats0,PoleCatNames);
%ModeDisp1 displays poles & zeros according to DispType 
%
% [CaseCom]=ModeDisp1(caseID,casetime,CaseCom,SigName,...
%   Poles,Zeros,DispType,PoleCats);
%
%  Last modified 11/13/01.   jfh

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.


%Clear outputs

%Check inputs
if ~exist('DispType'), DispType=0; end
if ~exist('Zeros'),    Zeros=[];   end 
if ~exist('PoleCats'), PoleCats=0; end 
if ~exist('PoleCatNames'),PoleCatNames=''; end
Npoles0=length(Poles0);
if length(PoleCats0)~=Npoles0 
  PoleCats0=zeros(Npoles0,1); 
end 

disp(' ')
disp(['In ModeDisp1:'])
if ~DispType, return, end

%keyboard

Poles=Poles0; Zeros=Zeros0; PoleCats=PoleCats0;
Npoles=length(Poles);
Nzeros=length(Zeros);
if Npoles==0&Nzeros==0
  disp('Nothing to display')
  disp('Return from ModeDisp1')
  return
end

%Display mode table (by pole number)
strs=['Sorted Mode Table for ' SigName ':'];
strs=str2mat(strs,' Pole       Sigma         Omega        Freq in Hz   Damp Ratio (pu)');
CaseCom=str2mat(CaseCom,strs); disp(strs)
for N=1:Npoles
  CatN=PoleCats(N); CatName='';
  if CatN>0, CatName=PoleCatNames(CatN,:); end
  sigma=real(Poles(N)); omd=imag(Poles(N));
  zeta=sigma/sqrt(sigma*sigma+omd*omd);
  if omd>0 %complex pole pair
    dampPU=-zeta;
    frqHz=omd/(2*pi); sigHz=sigma/(2*pi);
    str=sprintf('%4.0i %14.8f %14.8f %14.8f %14.8f',[N sigma omd frqHz dampPU]);
    str=[str '  ' CatName];
    CaseCom=str2mat(CaseCom,str); disp(str)
  end
  if omd==0 %real pole
    sigHz=-sigma/(2*pi);
    str=sprintf('%4.0i %14.8f %14.8f %14.8f',[N sigma omd sigHz]); 
    str=[str '        N/A      ' CatName];
    CaseCom=str2mat(CaseCom,str); disp(str)
  end
end

if Nzeros==0
  disp('Return from ModeDisp1')
  return
end

%Display zeros table
strs=['Sorted Zeros Table for ' SigName ':'];
strs=str2mat(strs,' zero       Sigma         Omega        Freq in Hz    Sigma/(2*pi)');
CaseCom=str2mat(CaseCom,strs); disp(strs)
for N=1:Nzeros
  sigma=real(Zeros(N)); omd=imag(Zeros(N));
  zeta=sigma/sqrt(sigma*sigma+omd*omd);
  if omd>0 %complex zero pair
    sigHz=sigma/(2*pi);
    frqHz=omd/(2*pi); sigHz=sigma/(2*pi);
    str=sprintf('%4.0i %14.8f %14.8f %14.8f %14.8f',[N sigma omd frqHz sigHz]);
    CaseCom=str2mat(CaseCom,str); disp(str)
  end
  if omd==0 %real zero
    sigHz=-sigma/(2*pi);
    str=sprintf('%4.0i %14.8f %14.8f %14.8f %14.8f',[N sigma omd sigHz sigHz]); 
    CaseCom=str2mat(CaseCom,str); disp(str)
  end
end


disp('Return from ModeDisp1')
return

%end of PSMT function
