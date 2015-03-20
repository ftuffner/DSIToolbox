%PSMT Utility PSMPaths1.m
% Sets Matlab path to all folders sub-folders within 4 levels
%   of the selected base directory
%
% Last modified 08/14/01  jfh

disp(' ')
CSname='PSMpaths1'; %Case Script name
disp(['In ' CSname ': Adding paths for PSM_Tools'])

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
disp('Base directory for Matlab path generation = ')
disp(['  ' base])
setyn=input('    Is this ok?  Enter y or n [y]: ','s');
if isempty(setyn), setyn='y'; end
setok=strcmp(lower(setyn(1)),'y');
if ~setok
  disp(' ')
  disp('Return to calling program - change base directory and try again')
  return
end

%See new Matlab command below
%help genpath

%Generalization to Mac & PC
Ctype=computer;
disp(['In ' CSname ': Computer type = ' Ctype])
D='\';  %Default delimiter
if strcmp(Ctype,'MAC2'), D=':'; end 
lenB=size(base,2);
if  base(lenB)~=D, base=[base D]; end

%************************************************************************
%Determine files available for processing
disp(' ')
disp(['In ' CSname ': Determining paths to set'])
PSMtopDir=dir;
PSMdirNames={};
PSMdirNames=char(PSMtopDir.name);
%PSMdirNames=sortrows(PSMdirNames);
%keyboard
dirnames=' ';
for N=1:length(PSMtopDir)
  eval(['cd ' '''' base '''']); %cd
  if PSMtopDir(N).isdir
    str1=lower(deblank(PSMdirNames(N,:)));
    if length(str1)>2&~strcmp(str1,'private')
      dirnames=str2mat(dirnames,str1);
      eval(['cd ' '''' [base str1] '''']); %cd
      PSMsub1Dir=dir;
      PSMsub1Names={};
      PSMsub1Names=lower(char(PSMsub1Dir.name));
      for N1=1:length(PSMsub1Dir)
        if PSMsub1Dir(N1).isdir
          str2=lower(deblank(PSMsub1Names(N1,:)));
          if length(str2)>2&~strcmp(str2,'private') 
            dirnames=str2mat(dirnames,[str1 D str2]);
            eval(['cd ' '''' [base str1 D str2] '''']); %cd
            PSMsub2Dir=dir;
            PSMsub2Names={};
            PSMsub2Names=lower(char(PSMsub2Dir.name));
            for N2=1:length(PSMsub2Dir)
              if PSMsub2Dir(N2).isdir
                str3=lower(deblank(PSMsub2Names(N2,:)));
                if length(str3)>2&~strcmp(str3,'private') 
                  dirnames=str2mat(dirnames,[str1 D str2 D str3]);
                  eval(['cd ' '''' [base str1 D str2 D str3] '''']); %cd
                  PSMsub3Dir=dir;
                  PSMsub3Names={};
                  PSMsub3Names=lower(char(PSMsub3Dir.name));
                  for N3=1:length(PSMsub3Dir)
                    if PSMsub3Dir(N3).isdir
                      str4=lower(deblank(PSMsub3Names(N3,:)));
                      if length(str4)>2&~strcmp(str4,'private') 
                        dirnames=str2mat(dirnames,[str1 D str2 D str3 D str4]);
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
eval(['cd ' '''' base '''']); %cd
%************************************************************************

disp('    Directory names for paths:')
disp(dirnames)
eval(['addpath ' '''' [base] ''''])
for N=1:size(dirnames,1)
  eval(['addpath ' '''' [base  dirnames(N,:)] ''''])
end
  
%end of PSM utility


