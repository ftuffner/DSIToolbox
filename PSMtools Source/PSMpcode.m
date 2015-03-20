%Script PSMpcode.m
% Compiles secondary Matlab scripts found in selected base directory
%
% Last modified 04/07/04  jfh

disp(' ')
CSname='PSMpcode'; %Case Script name
disp(['In ' CSname ': Compiling secondary Matlab scripts'])

command=['CDloc=which(' '''' CSname '''' ');'];
eval(command)
if isempty(CDloc)
  disp(['File ' CDloc ' not found on Matlab path:'])
  disp('Directory not changed')
end
ind=find(CDloc=='\'); 
last=ind(max(size(ind))); 
CDpath=CDloc(1:last);
command=['cd(' '''' CDpath '''' ');'];
eval(command);
base=cd;
disp('Base directory for Matlab compilation = ')
disp(['  ' base])
setyn=input('    Is this ok?  Enter y or n [y]: ','s');
if isempty(setyn), setyn='y'; end
setok=strcmp(lower(setyn(1)),'y');
if ~setok
  disp(' ')
  setyn=input('Enter new base directory?  Enter y or n [y]: ','s');
  if isempty(setyn), setyn='y'; end
  NewCD=strcmp(lower(setyn(1)),'y');
  if NewCD
    CDpath=input('Enter new base directory: ','s');  
  else
    disp(' ')
    disp('Return to calling program - change base directory and try again')
    return
  end
end


%Generalization to Mac & PC
Ctype=computer;
disp(['In ' CSname ': Computer type = ' Ctype])
D='\';  %Default delimiter
if strcmp(Ctype,'MAC2'), D=':'; end 
lenB=size(base,2);
if  base(lenB)~=D, base=[base D]; end

%Define specific files not to compile 
NoPcode='PSMbrowser';
NoPcode=str2mat(NoPcode,'PSMlaunch');
NoPcode=str2mat(NoPcode,'PDCmenu');
NoPcode=str2mat(NoPcode,'PPSMmenu',  'PPSMread');
NoPcode=str2mat(NoPcode,'SWXmenu');
NoPcode=str2mat(NoPcode,'PSAMmenu');
NoPcode=str2mat(NoPcode,'AddCom',    'Cread');
NoPcode=str2mat(NoPcode,'promptyn',  'promptnv');
NoPcode=str2mat(NoPcode,'Detrend',   'PSMunwrap');
NoPcode=str2mat(NoPcode,'PSMresamp', 'DXDcalc1');
NoPcode=str2mat(NoPcode,'db');
NoPcode=str2mat(NoPcode,'PSMautocov','SpecialDisp');
NoPcode=str2mat(NoPcode,'PRSdisp1');
NoPcode=str2mat(NoPcode,'PSMpaths',  'PSMIDpaths');
NoPcode=str2mat(NoPcode,'PSMpcode');
NoPcode=str2mat(NoPcode,'startup');
%Define folders not to compile 
NoPcode=str2mat(NoPcode,'pmu_');          
NoPcode=str2mat(NoPcode,'examples');          
NoPcode=str2mat(NoPcode,'development','checks','misc');          
NoPcode=str2mat(NoPcode,'syscheck','sysfit');
NoPcode=str2mat(NoPcode,'_Special');

disp(' ')
disp(['Files/folders not to compile: NoPcode =' ])
disp(NoPcode)
setyn=input('Is this ok?  Enter y or n [y]: ','s');
if isempty(setyn), setyn='y'; end
setok=strcmp(lower(setyn(1)),'y');
if ~setok
  disp(['In ' CSname ': Invoking "keyboard" command - Enter "return" when you are finished'])
  keyboard
end
setyn=input(' Delete source code after compilation?  Enter y or n [n]: ','s');
if isempty(setyn), setyn='n'; end
MfileDelete=strcmp(lower(setyn(1)),'y');


%************************************************************************
%Compile secondary Matlab files
%  Do not compile or delete files indicated in NoPcode 
disp(' ')
disp(['In ' CSname ': Compiling Matlab files in folders indicated below'])
PSMworkDir=dir;
PSMdirNames={};
PSMdirNames=char(PSMworkDir.name);
%PSMdirNames=sortrows(PSMdirNames); %Must sort all elements of PSMworkDir  
NoPcode=lower(NoPcode);
for N=1:length(PSMworkDir)
  eval(['cd ' '''' base ''''])
  disp(['In directory scan loop: Name ' num2str(N) ' = ' PSMdirNames(N,:)])
  if PSMworkDir(N).isdir
    str1=lower(deblank(PSMdirNames(N,:)));
    if length(str1)>2
      Mloc1=[];
      for ML=1:size(NoPcode,1)
        if ~isempty(findstr(str1,deblank(NoPcode(ML,:))))
          Mloc1=ML;
          disp(['Pcode operations denied for directory ' str1]) 
        end; 
      end
    end
    if length(str1)>2&isempty(Mloc1)
      disp(['  ' str1])
      eval(['cd ' '''' [base str1] ''''])
      disp('    Deleting files *.bk.m, *.bk.p, *.asv')
      delete *.bk.m; delete *.bk.p; delete *.asv
      PSMsubDir=dir;
      PSMsubNames={};
      PSMsubNames=lower(char(PSMsubDir.name));
      for NN=1:length(PSMsubDir)
        if ~PSMsubDir(NN).isdir
          str2=lower(deblank(PSMsubNames(NN,:)));
          ftype='';
          if length(str2)>2 
            last=length(str2); ftype=str2(last-1:last);
          end
          Mlocs=[];
          for ML=1:size(NoPcode,1)
            %if ~isempty(findstr(str2,deblank(NoPcode(ML,:)))), Mlocs=[Mlocs ML]; end; 
             Mtest=findstr(str2,deblank(NoPcode(ML,:))); if isempty(Mtest), Mtest=0; end
             if Mtest==1, Mlocs=[Mlocs ML]; end; 
          end
          if isempty(Mlocs)
            if strcmp(ftype,'.m')  %Generate new pfile 
              disp(['    Pcoding file ' str2])
              eval(['pcode  ' str2])
              if MfileDelete         %Delete source mfile
                disp(['    Deleting file ' str2])
                eval(['delete ' str2]);
              end
            end
          end
        end
      end
    end
  end
end
eval(['cd ' '''' base ''''])
%************************************************************************

  
%end of PSMT script


