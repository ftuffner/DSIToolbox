%PSI Script PSM_ButtonsP2.m
%Experimental pushbutton logic to select processing operations 
%
%Operations supported:
%  Batch Plots    
%  Filter/Decimate
%  Backload Filtered Data  
%  Fourier        
%  Histograms     
%  Ringdown GUI   
%  ModeMeter
%  save results      
%  keyboard       
%  end case 
%
%NOTES:
%  a) GUI is figure number FigNo_GUI2
%  b) Secected operation is in text string BP2_Op  
%
% Last modified 09/20/00.  jfh


%************************************************************************ 
FigNo_GUI2 = figure('Name','PSM Processing','units','normal',...
              		   'position',[0.7 0.4 0.25 0.5]);
  
% Batch Plots pushbutton
  pb_BatchPlots=uicontrol(FigNo_GUI2,'style','push','string','Batch Plots',...
      'units','normal','position',[.1,.920,.50,.06],...
		 'callback','BP2_Op=''Batch Plots'';');
	
% Filter/Decimate pushbutton	 
  pb_FilterDec=uicontrol(FigNo_GUI2,'style','push','string','Filter/Decimate',...
      'units','normal','position',[.1,.850,.50,.06],...
		 'callback','BP2_Op=''Filter/Decimate'';');

% Backload Filtered pushbutton
  pb_BkldFiltered=uicontrol(FigNo_GUI2,'style','push','string','Backload Filtered Data',...
      'units','normal','position',[.1,.780,.50,.06],...
		 'callback','BP2_Op=''Backload Filtered'';');		 

% Fourier pushbutton
  pb_Fourier=uicontrol(FigNo_GUI2,'style','push','string','Fourier Analysis',...
      'units','normal','position',[.1,.710,.50,.06],...
		 'callback','BP2_Op=''Fourier'';');		 

% Histograms pushbutton
  pb_Histograms=uicontrol(FigNo_GUI2,'style','push','string','Histogram Analysis',...
      'units','normal','position',[.1,.640,.50,.06],...
		 'callback','BP2_Op=''Histograms'';');		 
		 		 		 		 
% Ringdown GUI pushbutton
  pb_RingdownGUI=uicontrol(FigNo_GUI2,'style','push','string','Launch Ringdown GUI',...
      'units','normal','position',[.1,.570,.50,.06],...
		 'callback','BP2_Op=''Ringdown GUI'';');

% ModeMeter pushbutton
  pb_ModeMeter=uicontrol(FigNo_GUI2,'style','push','string','Launch ModeMeter',...
      'units','normal','position',[.1,.500,.50,.06],...
		 'callback','BP2_Op=''ModeMeter'';');

% Save Results pushbutton
  pb_SaveResults=uicontrol(FigNo_GUI2,'style','push','string','save latest results',...
      'units','normal','position',[.1,.400,.50,.06],...
		 'callback','BP2_Op=''save results'';');

% Keyboard pushbutton
  pb_keyboard=uicontrol(FigNo_GUI2,'style','push','string','keyboard',...
      'units','normal','position',[.1,.330,.50,.06],...
		 'callback','BP2_Op=''keyboard'';');
  
% End Case pushbutton
  pb_EndCase=uicontrol(FigNo_GUI2,'style','push','string','end case',...
      'units','normal','position',[.1,.260,.50,.06],...
		 'callback','BP2_Op=''end case'';');

%************************************************************************


% End of PSI m-file

