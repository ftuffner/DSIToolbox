%************************************************
%2.0 check the definition of the default selections

%2.1 check the path for the *.dst files (data file)
if isempty(PSMMacro.EventScan1_PathName)
    for kIndex=1:3
        [n,p]=uigetfile('*.dst','Please choose your dst file directory:');
        if p
            PSMMacro.EventScan1_PathName=p;
            break;
        elseif kIndex==3
            disp('Selection is NOT a valid directory. This must be a valid directory.');
            NFiles=0;
            %keyboard%
            return;
        end
    end
end
    
if PSMMacro.EventScan1_PathName(end)~='/' && PSMMacro.EventScan1_PathName(end)~='\'
    PSMMacro.EventScan1_PathName=[PSMMacro.EventScan1_PathName '\'];
end

if ~isdir(PSMMacro.EventScan1_PathName)
    disp('The pathname is NOT a valid directory.');
    [n,p]=uigetfile('*.dst','Default.pathname is NOT valid. Please choose your dst file:');
    if p
        PSMMacro.EventScan1_PathName=p;
    else
        disp('The pathname is NOT a valid directory. This must be a valid directory.');
        NFiles=0;
        return;
    end
end

dstFileNames=dir([PSMMacro.EventScan1_PathName '*.dst']);
NFiles=length(dstFileNames);
if NFiles<=0
    message='No *.dst files are detected in specified directory. Please check the definition of the PSMMacro.EventScan1_PathName';
    disp(['In subCheckValid : ',message]);
%   disp('Press any key to continue...'); pause;
    return
end

%2.2 check the availability for the *.ini file (configuration file)
if isempty(PSMMacro.EventScan1_CFname)
    cd(PSMMacro.EventScan1_PathName);
    for kIndex=1:3
        [n,p]=uigetfile('*.ini','Please select PDC configuration file:');
        if n~=0; 
            PSMMacro.EventScan1_CFname=[p n];
            break;
        end
    end
end

PSMMacro.EventScan1_CFname=deblank(PSMMacro.EventScan1_CFname);
fid=fopen(setstr(PSMMacro.EventScan1_CFname),'r');

if fid<0
  disp(['The specified ini file can not be found. Launching dialog box for PDC configuration file'])
  cd(PSMMacro.EventScan1_PathName);
  [n,p]=uigetfile('*.ini','The specified ini file can not be found. Please select PDC configuration file:');
  if n==0; 
      NFiles=0;
      return; 
  end;
  PSMMacro.EventScan1_CFname=[p n];
  [fid,message]=fopen(PSMMacro.EventScan1_CFname,'r');
  if fid<0 
      NFiles=0;
      return
  else
      fclose(fid);
  end
else
    fclose(fid);
end
