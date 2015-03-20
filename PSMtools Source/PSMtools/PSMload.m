% Case Script PSMload.m
%
% Functions provided:
%   Data extraction from individual files
%   Repair of defective data
%   Data translation into standard PSM Tools (PSMT) format 
%   Serial linking of multiple files
%   Saving of extracted data
%
% PSMT utilities called from PSMload:
%   PSMscanFiles
%   PSMscanDirectory
%   PDCloadN
%   PPSMload
%   SWXload
%   DCUload
%   PSAMload
%   PMUload
%   SpecialLoad
%   PSMTload
%   F08load
%   PickList1
%   PSM2Date
%   (others) 
%
% Modified 03/13/03.  jfh
% Modified 02/13/04,  Henry.  [PPSM special data reader]
% Modified 02/03/04,  Henry.  [DFR data reader]
% Modified 07/14/06,  jfh.     Added DataPath to PSMscanFiles return
% Modified 03/16/04.  jfh
% Modified 10/181/06  Ning Zhou    [macro recording]
% Modified 12/09/13,  Frank Tuffner [CFF inclusion]
% Modified 03/03/14,  Frank Tuffner [SQL inclusion]

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
FNname='PSMload'
disp(' ')
disp('In PSMload: Read & link PSM files from one source')
disp(['Initial PSMtype = ' PSMtype])
strs='Functions provided by PSMload:';
strs=str2mat(strs,'  Data extraction from individual files');
strs=str2mat(strs,'  Repair of defective data');
strs=str2mat(strs,'  Data translation into standard PSM Tools (PSMT) format'); 
strs=str2mat(strs,'  Serial linking of multiple files');
strs=str2mat(strs,'  Saving of extracted data');
disp(strs)
strs='If you need the following functions then use PSMreload:';
strs=str2mat(strs,'  Timestamp editing');
strs=str2mat(strs,'  Signal resampling');
strs=str2mat(strs,'  Automatic renaming of signals to facilitate sorting'); 
strs=str2mat(strs,'  Parallel merging of multiple files');
strs=str2mat(strs,'  Saving of merged data');
disp(strs)
disp(' ')


%PDC loading parameters
if ~exist('loadopt'), loadopt=[];    end
if ~exist('rmsopt'),  rmsopt=[];     end
if ~exist('chansX'),  chansX=[];     end

%************************************************************************
%Logic to determine PSM type
extractok=1;
PSMtypes=str2mat('PDC','PDC CSV','PPSM','SWX','PDC Special','PMU','DCU','PSAM','special','PSMT');   % add 'PDC CSV', Henry. 2005-07-22
PSMtypes=str2mat(PSMtypes,'PSDM','F08','PPSM Special','CFF','SQL Database','exit or filemerge');					% Added CFF, SQL
Ntypes=size(PSMtypes,1);
PSMntype=0;
if ~isempty(PSMtype)
  for N=1:Ntypes
    test=findstr(deblank(lower(PSMtype)),lower(PSMtypes(N,:)));
    if ~isempty(test), PSMntype=N; break, end
  end
end
%if PSMntype==0, PSMntype=1; end
%PSMtype=PSMtypes(PSMntype,:);
locbase=1; maxtrys=5;

%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
% keyboard
if ~isfield(PSMMacro,'RunMode'), PSMMacro.RunMode=-1; end
if ~isfield(PSMMacro,'PSMload_PSMntype'), PSMMacro.PSMload_PSMntype=NaN; end
if ~isfield(PSMMacro, 'PSMload_PSMtypeok'), PSMMacro.PSMload_PSMtypeok=NaN;end
if ~isfield(PSMMacro, 'PSMload_PSMtype'), PSMMacro.PSMload_PSMtype=NaN; end
if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMload_PSMntype)...
       || isnan(PSMMacro.PSMload_PSMtypeok))      % 'Macro record mode' or 'selection was not defined in a macro'
    [PSMntype,PSMtype,PSMtypeok]=PickList1(PSMtypes,PSMntype,locbase,maxtrys);  % original function
else
    PSMntype=PSMMacro.PSMload_PSMntype;
    PSMtype=PSMMacro.PSMload_PSMtype;
    PSMtypeok=PSMMacro.PSMload_PSMtypeok;
end

if PSMMacro.RunMode==0      % if in macro definition mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMload_PSMntype=PSMntype;
        PSMMacro.PSMload_PSMtype=PSMtype;
        PSMMacro.PSMload_PSMtypeok=PSMtypeok;
    else
        PSMMacro.PSMload_PSMntype=NaN;
        PSMMacro.PSMload_PSMtype=NaN;
        PSMMacro.PSMload_PSMtypeok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------
if ~PSMtypeok
  disp('In PSMload: PSM type not determined')
  PSMtype='NONE';
  extractok=0; return
end
disp(['In PSMload: Selected PSMtype = ' PSMtype])
if ~isempty(findstr('exit',lower(PSMtype)))
	disp('In PSMload: No file load operations -- return'),
  extractok=0; diary off, return
end
if isempty(chansX)
  chansX=[1:10]; 
  if ~isempty(findstr('ppsm',lower(PSMtype)))
    chansX=[2:10];
  end 
end
%************************************************************************

%************************************************************************
%Determine range of PSM source files for data to extract
%See if it is a "File-based" load (not SQL) - if so, continue
if (isempty(findstr('sql',lower(PSMtype))))
	extractok=1;
	if ~exist('GetRange'), GetRange=''; end
	if extractok
	  if isempty(PSMfiles)&MaxFiles>1&isempty(GetRange)
		disp('  ')
		%----------------------------------------------------
		% Begin: Macro selection ZN 03/31/06
		%keyboard
		if ~isfield(PSMMacro, 'PSMload_GetRange'), PSMMacro.PSMload_GetRange=NaN; end
		if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMload_GetRange))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
			GetRange=promptyn('In PSMload: Select range of files to load?', '');
		else
			GetRange=PSMMacro.PSMload_GetRange;
		end
		
		if PSMMacro.RunMode==0      % if in macro definition mode 
			if PSMMacro.PauseMode==0            % if record mode is not paused
				PSMMacro.PSMload_GetRange=GetRange;
			else
				PSMMacro.PSMload_GetRange=NaN;
			end
			save(PSMMacro.MacroName,'PSMMacro');
		end
		% End: Macro selection ZN 03/31/06
		%----------------------------------------------------
		
		if GetRange
			%----------------------------------------------------
			% Begin: Macro selection ZN 03/31/06
			%keyboard
			if ~isfield(PSMMacro, 'PSMload_rangeFileChosen'), PSMMacro.PSMload_rangeFileChosen=NaN; end
			if ~isfield(PSMMacro, 'PSMload_PSMfiles'), PSMMacro.PSMload_PSMfiles=[]; end
			if ~isfield(PSMMacro, 'PSMload_DataPath'), PSMMacro.PSMload_DataPath=[]; end
			if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMload_rangeFileChosen))      % 'Macro record mode' or 'selection was not defined in a macro'
				[PSMfiles,DataPath]=PSMscanFiles(PSMtype);
			elseif PSMMacro.RunMode>=2      % supper macro play, (execute macro without stop)
				PSMfiles=PSMMacro.PSMload_PSMfiles;
				DataPath=PSMMacro.PSMload_DataPath;
				disp('In PSMload: Changing to directory shown below:')
				disp(DataPath(1,:));
				cd(DataPath(1,:));
			else                            % normal macro play. (confirm the file selection)
				disp(' ');
				disp('In PSMload: The data path selection was ')
				disp( ['    "',PSMMacro.PSMload_DataPath(1,:), '"'] )
				disp('In PSMload: The selected data files were')
				disp(PSMMacro.PSMload_PSMfiles);
				setokTemp=promptyn('In PSMload: Are these files OK?', 'y');
				if setokTemp
					 PSMfiles=PSMMacro.PSMload_PSMfiles;
					 DataPath=PSMMacro.PSMload_DataPath;
					 cd(DataPath(1,:));
				else
					[PSMfiles,DataPath]=PSMscanFiles(PSMtype);
				end
			end

			if PSMMacro.RunMode==0      % if in macro definition mode 
				if PSMMacro.PauseMode==0            % if record mode is not paused
					PSMMacro.PSMload_PSMfiles=PSMfiles;
					PSMMacro.PSMload_DataPath=DataPath;
					PSMMacro.PSMload_rangeFileChosen=1;
				else
					PSMMacro.PSMload_rangeFileChosen=NaN;
				end
				save(PSMMacro.MacroName,'PSMMacro');
			end
			% End: Macro selection ZN 03/31/06
			%----------------------------------------------------
		end
	  end
	end
	%************************************************************************


	%************************************************************************
	%Determine the directory of PSM source files for data to extract
	extractok=1;
	%keyboard;
	if ~exist('GetDirectory'), GetDirectory=''; end
	if extractok
	%  if isempty(PSMfiles)&MaxFiles>1&isempty(GetDirectory)
	  if isempty(PSMfiles)& MaxFiles>1 & ~GetRange
		disp('  ')
		%----------------------------------------------------
		% Begin: Macro selection ZN 10/18/06
		%keyboard
		if ~isfield(PSMMacro, 'PSMload_GetDirectory'), PSMMacro.PSMload_GetDirectory=NaN; end
		if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMload_GetDirectory))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
			GetDirectory=promptyn('In PSMload: Select the directory of files to load?', 'y');
		else
			GetDirectory=PSMMacro.PSMload_GetDirectory;
		end
		
		if PSMMacro.RunMode==0      % if in macro definition mode 
			if PSMMacro.PauseMode==0            % if record mode is not paused
				PSMMacro.PSMload_GetDirectory=GetDirectory;
			else
				PSMMacro.PSMload_GetDirectory=NaN;
			end
			save(PSMMacro.MacroName,'PSMMacro');
		end
		% End: Macro selection ZN 10/18/06
		%----------------------------------------------------
		if GetDirectory
			%----------------------------------------------------
			% Begin: Macro selection ZN 10/18/06
			% keyboard
			if ~isfield(PSMMacro, 'PSMload_DataPath'), PSMMacro.PSMload_DataPath=''; end
			if ~isfield(PSMMacro, 'PSMload_FileType'), PSMMacro.PSMload_FileType=''; end
			
			if (PSMMacro.RunMode<1 || isempty(PSMMacro.PSMload_FileType))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
				[PSMfiles,DataPath,FileType]=PSMscanDirectory(PSMtype, '', '');
			else
				DataPath=PSMMacro.PSMload_DataPath;
				FileType=PSMMacro.PSMload_FileType;
				disp(' ')
				disp(' The directory to be scanned is: ');
				disp(['       "', PSMMacro.PSMload_DataPath, '"']);
				if PSMMacro.RunMode<2
					setokTemp=promptyn('In PSMload: is this directory OK?', 'y');
					if ~setokTemp
						DataPath='';
						FileType='';
					end
				end
				[PSMfiles,DataPath,FileType]=PSMscanDirectory(PSMtype, DataPath,FileType);
				if ~strcmp(PSMMacro.PSMload_DataPath,DataPath)
					prompt=['In ', FNname, ': Would you like to record this folder selection in Macro?  Enter y or n [y]:  '];
					tempQKbdok1=input(prompt,'s'); if isempty(tempQKbdok1), tempQKbdok1='y'; end
					tempQKbdok2=strcmp(lower(tempQKbdok1(1)),'n');  %String comparison
					if ~tempQKbdok2
						PSMMacro.PSMload_DataPath=DataPath;
						PSMMacro.PSMload_FileType=FileType;
						save(PSMMacro.MacroName,'PSMMacro');
					end
				end
			end

			PSMpaths=DataPath;
			
			if PSMMacro.RunMode==0      % if in macro definition mode 
				if PSMMacro.PauseMode==0            % if record mode is not paused
					PSMMacro.PSMload_DataPath=DataPath;
					PSMMacro.PSMload_FileType=FileType;
				else
					PSMMacro.PSMload_DataPath='';
					PSMMacro.PSMload_FileType='';
				end
				save(PSMMacro.MacroName,'PSMMacro');
			end
			% End: Macro selection ZN 10/18/06
			%----------------------------------------------------
		end
	  end
	end
	%************************************************************************

	%************************************************************************
	%Determine individual PSM source files for data to extract
	%keyboard%
	if extractok&isempty(PSMfiles)
	  disp(' ')
	  disp('In PSMload: Select individual files to load:')
	  disp(['caseID = ' caseID])
		%----------------------------------------------------
		% Begin: Macro selection ZN 03/31/06
		%    keyboard
		if ~isfield(PSMMacro, 'PSMload_dstFileChosen'), PSMMacro.PSMload_dstFileChosen=NaN; end
		if ~isfield(PSMMacro, 'PSMload_PSMfiles'), PSMMacro.PSMload_PSMfiles=[]; end
		if ~isfield(PSMMacro, 'PSMload_PSMpaths'), PSMMacro.PSMload_PSMpaths=[]; end
		if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMload_dstFileChosen))      % 'Macro record mode' or 'selection was not defined in a macro'
			  for N=1:MaxFiles
				disp('  ')
				prompt=['Locate file ' sprintf('%2.1i',N) ' to load (else press Cancel to end)'];
				disp(prompt)
				%   keyboard
				if MaxFiles>1,disp('Processing paused - press any key to continue'); pause; end
				strx='*.*';
				if ~isempty(findstr('PDC',PSMtype)), strx='*.dst'; end
				if ~isempty(findstr('CSV',PSMtype)), strx='*.csv'; end      % added by Ning Zhou on 10/23/2006
				if ~isempty(findstr('PDC Special',PSMtype)), strx='*.*'; end
				if ~isempty(findstr('PSMT',PSMtype)), strx='*.mat'; end
				if ~isempty(findstr('CFF',PSMtype)), strx='*.cff'; end
				[filename,pathname]=uigetfile([strx],prompt);
				if filename(1)==0|pathname(1)==0
					disp('Selections complete -- processing'), break
				end
				filename=char(filename); pathname=char(pathname);
				if N==1
				  disp('In PSMload: Changing to directory shown below:')
				  disp(pathname)
				  eval(['cd ' '''' pathname ''''])
				  PSMfiles=filename; 
				  PSMpaths=pathname;
				else
				  PSMfiles=str2mat(PSMfiles,filename); 
				  PSMpaths=str2mat(PSMpaths,pathname);
				end
				disp('Files already selected:'); disp(PSMfiles)
			  end
		elseif PSMMacro.RunMode>=2      % supper macro play, (execute macro without stop)
			PSMfiles=PSMMacro.PSMload_PSMfiles;
			PSMpaths=PSMMacro.PSMload_PSMpaths;
			disp('In PSMload: Changing to directory shown below:')
			disp(PSMpaths(1,:));
			cd(PSMpaths(1,:));
		else                            % normal macro play. (confirm the file selection)
			disp(' ');
			disp('In PSMload: The data path selection was ')
			disp( ['    "',PSMMacro.PSMload_PSMpaths(1,:), '"'] )
			disp('In PSMload: The selected data files were')
			disp(PSMMacro.PSMload_PSMfiles);
			setokTemp=promptyn('In PSMload: Are these files OK?', 'y');
			if setokTemp
				 PSMfiles=PSMMacro.PSMload_PSMfiles;
				 PSMpaths=PSMMacro.PSMload_PSMpaths;
				 cd(PSMpaths(1,:));
			else
				for N=1:MaxFiles
					disp('  ')
					prompt=['Locate file ' sprintf('%2.1i',N) ' to load (else press Cancel to end)'];
					disp(prompt)
					%   keyboard
					if MaxFiles>1,disp('Processing paused - press any key to continue'); pause; end
					strx='*.*';
					if ~isempty(findstr('PDC',PSMtype)), strx='*.dst'; end
					if ~isempty(findstr('CSV',PSMtype)), strx='*.csv'; end      % added by Ning Zhou on 10/23/2006
					if ~isempty(findstr('PDC Special',PSMtype)), strx='*.*'; end
					if ~isempty(findstr('PSMT',PSMtype)), strx='*.mat'; end
					if ~isempty(findstr('CFF',PSMtype)), strx='*.cff'; end
					[filename,pathname]=uigetfile([strx],prompt);
					if filename(1)==0|pathname(1)==0
						disp('Selections complete -- processing'), break
					end
					filename=char(filename); pathname=char(pathname);
					if N==1
					  disp('In PSMload: Changing to directory shown below:')
					  disp(pathname)
					  eval(['cd ' '''' pathname ''''])
					  PSMfiles=filename; 
					  PSMpaths=pathname;
					else
					  PSMfiles=str2mat(PSMfiles,filename); 
					  PSMpaths=str2mat(PSMpaths,pathname);
					end
					disp('Files already selected:'); disp(PSMfiles)
				end
			end
		end
		
		if PSMMacro.RunMode==0      % if in macro definition mode 
			if PSMMacro.PauseMode==0            % if record mode is not paused
				PSMMacro.PSMload_PSMfiles=PSMfiles;
				PSMMacro.PSMload_PSMpaths=PSMpaths;
				PSMMacro.PSMload_dstFileChosen=1;
			else
				PSMMacro.PSMload_dstFileChosen=NaN;
			end
			save(PSMMacro.MacroName,'PSMMacro');
		end
		% End: Macro selection ZN 03/31/06
		%----------------------------------------------------
		
	  nXfiles=size(PSMfiles,1);        %number of files to load
	  disp(' ')
	  disp(['Number of files to load = ' sprintf('%2.1i',nXfiles)])
	  if nXfiles>0
		disp('File names in array PSMfiles are')
		disp(PSMfiles)
	  end
	 
		%----------------------------------------------------
		% Begin: Macro selection ZN 03/31/06
		%keyboard
		if ~isfield(PSMMacro, 'PSMload_filesok'), PSMMacro.PSMload_filesok=NaN; end
		if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMload_filesok))      % 'Macro record mode' or 'selection was not defined in a macro'
			filesok=promptyn('In PSMload: Is this ok? ','y');
		else
			filesok=PSMMacro.PSMload_filesok;
		end
		
		if PSMMacro.RunMode==0      % if in macro definition mode 
			if PSMMacro.PauseMode==0            % if record mode is not paused
				PSMMacro.PSMload_filesok=filesok;
			else
				PSMMacro.PSMload_filesok=NaN;
			end
			save(PSMMacro.MacroName,'PSMMacro');
		end
		% End: Macro selection ZN 03/31/06
		%----------------------------------------------------

	  
	  if ~filesok|nXfiles==0
		retok=promptyn('Return from PSMload? ','y');
		if retok
			disp('In PSMload: No file load operations -- return'),
		  PSMfiles=''; GetRange=''; GetDirectory=''; extractok=0; diary off, return
		end
		disp('Invoking "keyboard" command -  Type "return" when you are done')
		keyboard
	  end
	end
	%************************************************************************
else %Not a file-based one, just SQL for now
	PSMfiles='SQL';
end

%************************************************************************
%Extract PSM data
extractok=1; PSMreftimes=0;
if extractok
  if ~isempty(findstr('PDC',PSMtype))
    %Extract PDC signals
    decfacX=1;    %No signal decimation (can change later in processing) 
%    if isempty(loadopt)
      loadopt=4;    %Use general version (configuration data in .ini file)
%    end
    if ~isempty(findstr('CSV',PSMtype))
      loadopt=5;    %PDC CSV format (configuration data in .ini file). Henry Huang, 2005-07-22
    end
    if isempty(rmsopt)
      rmsopt=2;     %Use general version (configuration data in .ini file)
    end
    saveopt=0;    %No file save after data patching 
    trackX=0;     %Minimal printout for routine processing
    %keyboard%
    [caseID,casetime,CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =PDCloadN(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
  end
  if ~isempty(findstr('PPSM',PSMtype))
    %Extract PPSM signals
    decfacX=1;    %No signal decimation (can change later in processing) 
    if isempty(findstr('Special',PSMtype))
      loadopt=1;    
    else            % PPSM special data. Henry
      loadopt=2;    
    end
    rmsopt=1;     %(spare variable)
    saveopt=0;    %No intermediate data saves 
    trackX=0;     %Minimal printout for routine processing
    [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,ListPath,DataPath]...
      =PPSMload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
  end
  if ~isempty(findstr('SWX',PSMtype))
    %Extract SWX signals
    %SWXtypes=str2mat('PSMT ASCII','PSLF/PSDS ASCII','PTI PRNT','none');
    SWXtypes=str2mat('PSMT ASCII','PSLF/PSDS ASCII','PTI PRNT','PTI RAWC','DFR Comtrade','none');
    Ntypes=size(SWXtypes,1);
    CFname=deblank(CharTrim(CFname,' ','leading'));
    SWXntype=[];
    if findstr(CFname,'PSMT'),        SWXntype=1; end 
    if findstr(CFname,'PSDS'),        SWXntype=2; end 
    if findstr(CFname,'PSLF'),        SWXntype=2; end 
    if strcmp(CFname,'PTI PRNT'),     SWXntype=3; end 
    if strcmp(CFname,'PTI RAWC'),     SWXntype=4; end 
    if strcmp(CFname,'DFR Comtrade'), SWXntype=5; end
    locbase=1; maxtrys=5;
    disp(' ')
    
    %----------------------------------------------------
    % Begin: Macro selection ZN 10/18/06
    %keyboard;
    if ~isfield(PSMMacro, 'PSMload_SWXtypeok'), PSMMacro.PSMload_SWXtypeok=NaN; end
    if ~isfield(PSMMacro, 'PSMload_SWXtype'), PSMMacro.PSMload_SWXtype=NaN; end
    if ~isfield(PSMMacro, 'PSMload_SWXntype'), PSMMacro.PSMload_SWXntype=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMload_SWXtypeok))      % Not in Macro playing mode or selection not defined in a macro
        [SWXntype,SWXtype,SWXtypeok]=PickList1(SWXtypes,SWXntype,locbase,maxtrys);
    else
        SWXtypeok=PSMMacro.PSMload_SWXtypeok;
        SWXtype=PSMMacro.PSMload_SWXtype;
        SWXntype=PSMMacro.PSMload_SWXntype;
    end

    if PSMMacro.RunMode==0      % if in macro record mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMload_SWXtypeok=SWXtypeok;
            PSMMacro.PSMload_SWXtype=SWXtype;
            PSMMacro.PSMload_SWXntype=SWXntype;
        else
            PSMMacro.PSMload_SWXtypeok=NaN;
            PSMMacro.PSMload_SWXtype=NaN;
            PSMMacro.PSMload_SWXntype=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % [SWXntype,SWXtype,SWXtypeok]=PickList1(SWXtypes,SWXntype,locbase,maxtrys);
    % End: Macro selection ZN 10/18/06
    %---------------------------------------------------
    
    
    if ~SWXtypeok
      disp('In PSMload: SWX type not determined')
      PSMtype='NONE';
      extractok=0; return
    end
    disp(['In PSMload: Selected SWXtype = ' SWXtype])
    if ~isempty(findstr('none',lower(SWXtype)))
	    disp('In PSMload: No file load operations -- return'),
      extractok=0; diary off, return
    end
    decfacX=1;    %No signal decimation (can change later in processing)   
    loadopt=SWXntype;
    rmsopt=1;     %(spare variable)
    saveopt=0;    %No intermediate data saves 
    trackX=0;     %Minimal printout for routine processing
    [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =SWXload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
  end
  if ~isempty(findstr('DCU',PSMtype))
    disp(' ')
    disp(['In PSMload: PSM type '  '''DCU'''])
    AddOn=deblank(which('DCUload'));  %Check presence of PSMT add-on
    if isempty(AddOn)
      disp(['In PSMload: Cannot find PSMT Add-On called DCUload'])
      keybdok=promptyn('Do you want the keyboard? ', 'n');
      if keybdok
        disp('In PSMbrowser: Invoking "keyboard" command - Enter "return" when you are finished')
        keyboard
      else
        PSMtype='NONE'; return
      end
    end  
    %Extract DCU signals
    decfacX=1;    %No signal decimation (can change later in processing) 
    loadopt=1;    %LabVIEW unit
    loadopt=2;    %Visual Basic unit
    rmsopt=1;     %(spare variable)
    saveopt=0;    %No automatic file saves
    trackX=0;     %Minimal printout for routine processing
    [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =DCUload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
  end
  if ~isempty(findstr('PSAM',PSMtype))
    decfacX=1;    %No signal decimation (can change later in processing) 
    loadopt=1;    %Use general version (configuration data in .ini file)
    rmsopt=1;     %(spare variable)
    saveopt=0;    %No file save after data patching 
    trackX=0;     %Minimal printout for routine processing
%   keyboard
    [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =PSAMload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
  end
  if ~isempty(findstr('PMU',PSMtype))
    disp(' ')
    disp(['In PSMload: PSM type '  '''PMU'''])
    AddOn=deblank(which('PMUload'));  %Check presence of PSMT add-on
    if isempty(AddOn)
      disp(['In PSMload: Cannot find PSMT Add-On called PMUload'])
      keybdok=promptyn('Do you want the keyboard? ', 'n');
      if keybdok
        disp('In PSMbrowser: Invoking "keyboard" command - Enter "return" when you are finished')
        keyboard
      else
        PSMtype='NONE'; return
      end
    end  
    decfacX=1;    %No signal decimation (can change later in processing) 
    loadopt=1;    %Use general version
    rmsopt=0;     %No rms calculations
    saveopt=0;    %No file save after data patching 
    trackX=0;     %Minimal printout for routine processing
    [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =PMUload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
  end
  if ~isempty(findstr('special',PSMtype))
    disp(' ')
    disp(['In PSMload: PSM type '  '''Special'''])
    AddOn=deblank(which('SpecialLoad'));  %Check presence of PSMT add-on
    if isempty(AddOn)
      disp(['In PSMload: Cannot find PSMT Add-On called SpecialLoad'])
      keybdok=promptyn('Do you want the keyboard? ', 'n');
      if keybdok
        disp('In PSMbrowser: Invoking "keyboard" command - Enter "return" when you are finished')
        keyboard
      else
        PSMtype='NONE'; return
      end
    end  
    %Extract special type signals
    decfacX=1;    %No signal decimation (can change later in processing) 
    loadopt=1;    %(spare variable)
    rmsopt=1;     %(spare variable)
    saveopt=0;    %No intermediate data saves 
    trackX=0;     %Minimal printout for routine processing
    [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =SpecialLoad(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
  end
  if ~isempty(findstr('PSMT',PSMtype))
    %Extract .mat signals
    decfacX=1;    %No signal decimation (can change later in processing) 
    loadopt=1;    %(only option supported)
    rmsopt=1;     %(spare variable)
    saveopt=0;    %No intermediate data saves 
    trackX=0;     %Minimal printout for routine processing
    %disp('In PSMload'); keyboard
    [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =PSMTload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
  end
  if ~isempty(findstr('F08',PSMtype))
    disp(' ')
    disp(['In PSMload: PSM type '  '''F08'''])
    AddOn=deblank(which('F08load'));  %Check presence of PSMT add-on
    if isempty(AddOn)
      disp(['In PSMload: Cannot find PSMT Add-On called F08load'])
      keybdok=promptyn('Do you want the keyboard? ', 'n');
      if keybdok
        disp('In PSMbrowser: Invoking "keyboard" command - Enter "return" when you are finished')
        keyboard
      else
        PSMtype='NONE'; return
      end
    end  
    %Extract .F08 signals
    decfacX=1;    %No signal decimation (can change later in processing) 
    loadopt=1;    %(spare variable)
    rmsopt=1;     %(spare variable)
    saveopt=0;    %No intermediate data saves 
    trackX=0;     %Minimal printout for routine processing
    [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =F08load(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
  end
  if ~isempty(findstr('CFF',PSMtype))
    %Extract COMTRADE single file signals
    decfacX=1;    %No signal decimation (can change later in processing) 
    loadopt=1;  %spare
    rmsopt=1;     %(spare variable)
    saveopt=0;    %No intermediate data saves 
    trackX=0;     %Minimal printout for routine processing
    
    [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =CFFload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
  end
  if ~isempty(findstr('SQL',PSMtype))
    %Extract SQL signals
    decfacX=1;    %No signal decimation (can change later in processing) 
    loadopt=1;    %spare
    rmsopt=1;     %(spare variable)
    saveopt=0;    %No intermediate data saves 
    trackX=0;     %Minimal printout for routine processing
    
    [CaseCom,SaveFile,chankeyX,namesX,PSMsigsX,tstep,DataPath]...
      =SQLload(caseID,casetime,CaseCom,DataPath,chansX,decfacX,...
       loadopt,rmsopt,saveopt,trackX);
   
  end

  
end
%************************************************************************

%************************************************************************
%Check/display results
if isempty(PSMsigsX)
	disp('In PSMload: No file load operations -- return'),
  PSMfiles='';
  extractok=0; diary off, return
end
if isempty(PSMreftimes), PSMreftimes=0; end
AbsRefTime=PSMreftimes(1);
if AbsRefTime<=0
  disp('In PSMload: No GMT reference time')
  prompt1='Use keyboard to enter reference time in format 10-Aug-1996 15:48:46.133? ';
   %----------------------------------------------------
    % Begin: Macro selection ZN 03/31/06
    %keyboard
    if ~isfield(PSMMacro, 'PSMload_keybdok'), PSMMacro.PSMload_keybdok=NaN; end
    if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMload_keybdok))      % 'Macro record mode' or 'selection was not defined in a macro'
        keybdok=promptyn(prompt1,'');
    else
        keybdok=PSMMacro.PSMload_keybdok;
    end
    
    if PSMMacro.RunMode==0      % if in macro definition mode 
        if PSMMacro.PauseMode==0            % if record mode is not paused
            PSMMacro.PSMload_keybdok=keybdok;
        else
            PSMMacro.PSMload_keybdok=NaN;
        end
        save(PSMMacro.MacroName,'PSMMacro');
    end
    % End: Macro selection ZN 03/31/06
    %----------------------------------------------------
  
  
  if keybdok
    prompt2='Enter reference time in format 10-Aug-1996 15:48:46.133 ';
    DateString=input(prompt2,'s');
    [AbsRefTime]=Date2PSM(DateString);
    disp(['Reference time for first record = ' PSM2Date(AbsRefTime)])
    for N=1:size(PSMreftimes,1)
      PSMreftimes(N)=PSMreftimes(N)+AbsRefTime;
    end
  end
end
[maxpoints nsigs]=size(PSMsigsX);
time=PSMsigsX(:,1);
RecStart=PSM2Date(PSMsigsX(1,1)+PSMreftimes(1)); 
RecEnd  =PSM2Date(PSMsigsX(maxpoints,1)+PSMreftimes(1));
S2=['Record Start Time = ' RecStart ' GMT Standard']; disp(S2)
S3=['Record End Time   = ' RecEnd   ' GMT Standard']; disp(S3)
CaseCom=str2mat(CaseCom,S2,S3);
if ~isempty(PSMfiles)
  disp(' ')
  AbsRefStr=PSM2Date(AbsRefTime);
  strs=['In PSMload: Size PSMsigsX = ' num2str(size(PSMsigsX))];
  strs=str2mat(strs,'Data extracted from the following files:', PSMfiles);
  str=['Reference for absolute time calculations is AbsRefTime = '];
  str=[str sprintf('%2.12e',AbsRefTime) ' seconds'];
  strs=str2mat(strs,str,['Equivalent GMT standard time = ' AbsRefStr ]);
  CaseCom=str2mat(CaseCom,strs); disp(strs)
end
%************************************************************************

%************************************************************************
%%Delete extra blanks in signal names 
namesX0=namesX;
[namesX]=BstringOut(namesX0,' ',2);  
chankeyX=names2chans(namesX);
if size(namesX,2)<size(namesX0,2)
  disp('In PSMload: Contracting signal names') 
end
%************************************************************************

%************************************************************************
%Test if case is to post data for distribution
if extractok&(length('datapost')<=length(caseID))
  DataPost=~isempty(findstr('data',lower(caseID)));
  DataPost=DataPost&(~isempty(findstr('post',lower(caseID))));
  if DataPost
    loc=min(findstr('.',PSMfiles(1,:)))-1;
    if isempty(loc),loc=length(PSMfiles(1,:)); end
    EventTag=PSMfiles(1,1:loc);
    strs=['Data posting case for event ' EventTag];
    caseID=[caseID0 '_' EventTag];
    strs=str2mat(strs,['Case ID changed to caseID= ' caseID],' ');
    disp(' '); disp(strs); 
    CaseCom=str2mat(strs,CaseCom);
  end   
end
%************************************************************************

%*************************************************************************
%Optional data save to file
disp(' ')
%----------------------------------------------------
% Begin: Macro selection ZN 03/31/06
if ~isfield(PSMMacro, 'PSMload_savesok'), PSMMacro.PSMload_savesok=NaN;end
if (PSMMacro.RunMode<2 || isnan(PSMMacro.PSMload_savesok))      % 'Not in Macro batch play mode (special because of loop)' or 'selection was not defined in a macro'
%if (PSMMacro.RunMode<1 || isnan(PSMMacro.PSMload_savesok))      % 'Not in Macro play mode' or 'selection was not defined in a macro'
    savesok=promptyn('In PSMload: Invoke utility to save extracted signals? ', '');
else
    savesok=PSMMacro.PSMload_savesok;
end

if PSMMacro.RunMode==0      % if in macro definition mode 
    if PSMMacro.PauseMode==0            % if record mode is not paused
        PSMMacro.PSMload_savesok=savesok;
    else
        PSMMacro.PSMload_savesok=NaN;
    end
    save(PSMMacro.MacroName,'PSMMacro');
end
% End: Macro selection ZN 03/31/06
%----------------------------------------------------
if savesok
  disp('In PSMload: Loop for saving data to files:')
  CaseComR=CaseCom;
  for tries=1:10
    disp(' ')
    SaveFile='';
    SaveList=['PSMtype PSMsigsX tstep namesX chankeyX CaseComR PSMfiles PSMreftimes CFname'];

    PSMsave
    if isempty(SaveFile), break, end
  end
end
%*************************************************************************

disp('Return from PSMload')
disp(' ')

%end of PSMT utility
