function CaseComPlot(CaseCom,Ptitle,PrintPlot,SavePlot,SaveFileP)
% Plot lines of text
%
% CaseComPlot(CaseCom,Ptitle,PrintPlot,SavePlot,SaveFileP)
%
% Last modified 11/05/02.   jfh
% Last Modified 02/17/07.   by Ning Zhou to add macro function
%
% By J. F. Hauer, Pacific Northwest National Laboratory.

% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

if ~exist('PrintPlot'),PrintPlot=0;  end
if ~exist('SavePlot'), SavePlot=0;   end
if ~exist('SaveFileP'),SaveFileP=''; end

%----------------------------------------------------
% Begin: Macro definition ZN 03/31/06
global PSMMacro         % Macro Structure  
% End: Macro definition ZN 03/31/06
%----------------------------------------------------
%keyboard

tabchar='	';
[CaseCom]=Char2Blank(CaseCom,tabchar);  %Replace tabs 

%*************************************************************************
%Generate case header plot
lines0=size(CaseCom,1); 
lines=lines0; Plines=50;
Hpages=ceil(lines/Plines); HPtrim=0;
if Hpages>4
  disp(['Long case header: Pages = ', num2str(Hpages)])
    %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
        if ~isfield(PSMMacro, 'CaseComPlot_HPtrim'), PSMMacro.CaseComPlot_HPtrim=NaN; end
        if (PSMMacro.RunMode<1 || isnan(PSMMacro.CaseComPlot_HPtrim))      % Not in Macro playing mode or selection not defined in a macro
            HPtrim=promptyn('Plot first & last pages only? ', 'y');
        else
            HPtrim=PSMMacro.CaseComPlot_HPtrim;
        end

        if PSMMacro.RunMode==0      % if in macro record mode 
            if PSMMacro.PauseMode==0            % if record mode is not paused
                PSMMacro.CaseComPlot_HPtrim=HPtrim;
            else
                PSMMacro.CaseComPlot_HPtrim=NaN;
            end
            save(PSMMacro.MacroName,'PSMMacro');
        end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------  

	
  if HPtrim, Hpages=2; end
end
jbase=0; j1=1; j2=min(Plines,lines);
for Hpage=1:Hpages
  h=figure;                          %Case header plot
	plotno=sprintf('P%2.0i: ',h);
  set(gca,'xlim',[0 120])
  set(gca,'ylim',[-Plines -1])
  axis('off')
  Ptitle{1}=['Case Header'];
  if Hpage>1, Ptitle{1}=['Case Header (ctd)']; end
  Ptitle{1}=[plotno Ptitle{1}];
  title(Ptitle)
  %j1,j2,jbase
  for j=j1:j2
    linej=CaseCom(j,:);
    if HPtrim
      if Hpage==1&j==j2
       linej='START OF DISPLAY TRIMMING';
      end
      if Hpage==2&j==j1
       linej='END OF DISPLAY TRIMMING';
      end
    end
    text(0,jbase-(j+1),linej,'FontName','courier new',...
     'FontSize',8)
  end
  if PrintPlot, print -f, end
  if SavePlot
    SaveP=[SaveFileP num2str(h)];
    eval(['print -depsc -tiff ' SaveP])
  end
  lines=lines-Plines; jbase=jbase+Plines;
  j1=j1+Plines; j2=j2+min(Plines,lines);
  if HPtrim
    j1=lines0-Plines+1; j2=lines0; 
    jbase=j1-1; 
  end
end 
%*************************************************************************

%end of PSMT function