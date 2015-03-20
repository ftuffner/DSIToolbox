%Case Script CompassPlotsA
% CompassPlotsA displays Prony solution (PRS) tables, 
% compass plots, and other modeshape information
%
% PSM Tools called from CompassPlotsA:
%   promptyn, promptnv
%   (others)
%
% Modified 05/18/05 by jfh.  Changed heading for Mode Table display

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

CSname='CompassPlotsA';

%************************************************************************
disp(' ')
disp(['In ' CSname ': Start of Mode Table Displays'])
setok=promptyn('  Do you want the keyboard?','');
if setok
  disp('  Invoking "keyboard" command - Enter "return" when you are finished')
  keyboard
end
disp(' ')
SigTables=promptyn('  Display Mode Table for each signal?','');
if SigTables
  disp(['In ' CSname ': ' Ptitle{2}]);
  for FitNo=1:nfits
    strs=' ';
    SigName=SigNames(FitNo,:);
    strs=str2mat(strs,['Sorted Mode Table for ' SigName ':']);
    strs=str2mat(strs,' Pole    Freq in Hz   Damp Ratio (pu)    Res Mag      Res Angle');
    CaseCom=str2mat(CaseCom,strs); disp(strs)
    Npoles=size(Poles,1);
    for N=1:Npoles
      CatN=PoleCats(N); CatName='';
      if CatN>0, CatName=PoleCatNames(CatN,:); end
      sigma=real(Poles(N,FitNo)); omd=imag(Poles(N,FitNo));
      zeta=sigma/sqrt(sigma*sigma+omd*omd);
      ResMag=abs  (Tres(N,FitNo));
      ResAng=angle(Tres(N,FitNo))*180/pi;
      if omd>0 %complex pole pair
        dampPU=-zeta; ResMag=2*ResMag;
        frqHz=omd/(2*pi); sigHz=sigma/(2*pi);
        str=sprintf('%4.0i %14.8f %14.8f %14.8f %14.8f',[N frqHz dampPU ResMag ResAng]);
        str=[str '  ' CatName];
        CaseCom=str2mat(CaseCom,str); disp(str)
      end
      if omd==0 %real pole
        sigHz=-sigma/(2*pi);
        str=[sprintf('%4.0i %14.8f',[N sigHz]) '        N/A     ']; 
        str=[str sprintf('%14.8f %14.8f',[ResMag ResAng])];
        str=[str '  ' CatName];
        CaseCom=str2mat(CaseCom,str); disp(str)
      end
    end
  end
end
disp(' ')
defret=''; if ~SigTables, defret='y'; end 
CompassPlots=0; CompassNorm=0; CompassLegn=0;
PoleTables=promptyn('  Display Mode Table for each pole?',defret);
%NOTE: Need logic for long signal names
if PoleTables
  CompassPlots=promptyn('  Compass plots of signal residues for complex poles?','y');
  if CompassPlots
    CompassNorm=promptyn('  Compass plots of residue angles only?','');
    CompassLegn=promptyn('  Legend for each compass plot?','');
  end
  disp(['In ' CSname ': ' Ptitle{2}]);
  strN=SigNames(1,:); chars=length(strN);
  Head2=[strN '      Freq in Hz   Damp Ratio (pu)    Res Mag      Res Angle'];
  Head2(1:chars)=' '; Head2(1:6)='Signal';
  Npoles=size(Poles,1);
  for N=1:Npoles
    CatN=PoleCats(N); CatName='';
    if CatN>0, CatName=PoleCatNames(CatN,:); end
    omd=imag(Poles(N,1));
    if omd>=0
      strs=' '; 
      strs=str2mat(strs,['Sorted Mode Table for pole' num2str(N) ': ' CatName]);
      strs=str2mat(strs,Head2);
      CaseCom=str2mat(CaseCom,strs); disp(strs)
    end
    Compass=[];
    for FitNo=1:nfits
      strN=SigNames(FitNo,:);
      sigma=real(Poles(N,FitNo)); omd=imag(Poles(N,FitNo));
      zeta=sigma/sqrt(sigma*sigma+omd*omd);
      TresN=(Tres(N,FitNo));
      ResMag=abs  (TresN);
      ResAng=angle(TresN)*180/pi;
      if omd>0 %complex pole pair
        dampPU=-zeta; ResMag=2*ResMag;
        frqHz=omd/(2*pi); sigHz=sigma/(2*pi);
        str=sprintf('%14.8f %14.8f %14.8f %14.8f',[frqHz dampPU ResMag ResAng]);
        str=[strN '  ' str];
        CaseCom=str2mat(CaseCom,str); disp(str)
        CvecN=TresN;
        if CompassNorm
          CvecN=TresN/abs(TresN);
        end
        Compass=[Compass CvecN];
      end
      if omd==0 %real pole
        sigHz=-sigma/(2*pi);
        str=[sprintf('%14.8f',[sigHz]) '        N/A     ']; 
        str=[str sprintf('%14.8f %14.8f',[ResMag ResAng])];
        str=[strN '  ' str];
        CaseCom=str2mat(CaseCom,str); disp(str)
      end
    end
    if CompassPlots&omd>0
      figure;
      str=sprintf('%14.8f Hz @ %14.8f damping',[frqHz dampPU]);
      if CompassNorm, 
        str=['Normalized Compass Plot for mode ' str]; 
      else
        str=['Scaled Compass Plot for mode ' str]; 
      end
      Ptitle{1}=str;
      Cvecs=[zeros(length(Compass),1) Compass']';
      plot(Cvecs); %set(gca,'TickDir','out')
      Len=max(abs(Compass)); 
      LLen=floor(log10(Len)); Inc=10^(LLen-1); 
      Len=ceil(Len/Inc)*Inc;
      range=[-Len Len];
      set(gca,'xlim',range,'ylim',range); axis square
      title(Ptitle)
      xlabel(str);
      if CompassLegn
        legend(SigNames)
      end
    end
  end
  if CompassPlots
    figure; 
    Ptitle{1}=['Color sequence for signals in compass plots'];
    Clines=conj([ones(nfits,1)-(i*[1:nfits])']);
    ClinesN=conj([i*imag(Clines) Clines]');   %Rectangular
    %ClinesN=conj([zeros(nfits,1) Clines]'); %Polar
    plot(ClinesN); set(gca,'TickDir','out');
    set(gca,'xlim',[0 4],'ylim',[-(nfits+1) 0]);
    title(Ptitle)
    legend(SigNames)
    xlabel(' ')
  end
end
%************************************************************************

%end of PSMT utility

