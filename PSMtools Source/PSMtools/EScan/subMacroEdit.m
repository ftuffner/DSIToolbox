% subMacroEdit
% For editing macro.
% It is used in promptyn.m and promptynv.m
% by Ning Zhou 02/14/2007
%
tempFile=[PSMMacro.MacroName(1:length(PSMMacro.MacroName)-3),'m'];
[fid,message] = fopen(tempFile, 'w');
if fid>0
    fwrite(fid,'');
    fprintf(fid, ' %% Edit macro function using matlab: \r' );
    fprintf(fid, ' %% --------------------------------------------------------------------------- \r' );
    fprintf(fid, ' %% 1)View/Edit/Save the macro. \r' );
    fprintf(fid, ' %% 2)Close this Edit windows. \r' );
    fprintf(fid, ' %% --------------------------------------------------------------------------- \r' );
    fprintf(fid, 'PSMMacro.PSMload_DataPath=''%s'';  %% The path for the *.dst files \r', PSMMacro.PSMload_DataPath);
    fprintf(fid, 'PSMMacro.PDCload4_fnameNew=''%s'';  %% The file name of the *.ini files \r', PSMMacro.PDCload4_fname);
    fprintf(fid, 'PSMMacro.SetExtPDC_chansX=[%s];  %% channel selections \r', num2str(PSMMacro.SetExtPDC_chansX));
    fclose(fid);
    open(tempFile);
    disp('Invoking Edit macro function.')
    disp(['Please view/edit/save: ' tempFile]);
    disp('After editing/saving the macro, press any key to continue...')
    pause
    clear(tempFile);
    run(tempFile);
    if isfield(PSMMacro, 'PDCload4_fnameNew')
        if ~strcmp(PSMMacro.PDCload4_fnameNew, PSMMacro.PDCload4_fname)
            PSMMacro.PDCload4_fname=PSMMacro.PDCload4_fnameNew;
            PSMMacro.PDCload4_initext=[];
        end
    end
    save(PSMMacro.MacroName,'PSMMacro');
    disp('-------------------------------------------------------------------------------' );
    fprintf(1, 'PSMMacro.PSMload_DataPath=''%s'';  %% The path for the *.dst files \r', PSMMacro.PSMload_DataPath);
    fprintf(1, 'PSMMacro.PDCload4_fnameNew=''%s'';  %% The file name of the *.ini files \r', PSMMacro.PDCload4_fname);
    fprintf(1, 'PSMMacro.SetExtPDC_chansX=[%s];  %% channel selections \r', num2str(PSMMacro.SetExtPDC_chansX));
    disp('-------------------------------------------------------------------------------' );
end

prompt=['In subEditMacro: Do you want the keyboard to view/edit macro?  Enter y or n [n]:  '];
tempQKbdok1=input(prompt,'s'); if isempty(tempQKbdok1), tempQKbdok1='n'; end
tempQKbdok2=strcmp(lower(tempQKbdok1(1)),'y');  %String comparison
if tempQKbdok2
    disp(' ');
    disp('Macro definition is stored in "PSMMacro"');
    disp('-------------------------------------------------------------------------------' );
    disp('1) To view all the Macro definition, type in "PSMMacro".' );
    disp('2) To view one Macro definition, type in PSMMacro.fieldname.' );
    disp('   For example: "PSMMacro.PSMload_DataPath"' );
    disp('   For example: "PSMMacro.SetExtPDC_chansX"' );
    disp('   For example: "PSMMacro.PDCload4_fname"' );
    disp('3) To edit a Macro definition, use matlab assignment command' );
    disp('   For example: "PSMMacro.PSMload_DataPath=''c:\DstFilefolder\''; "' );
    disp('   For example: "PSMMacro.SetExtPDC_chansX=[1, 2, 3]; "' );
    disp('   For example: "PSMMacro.PDCload4_fname=''c:\IniFilefolder\BPA2_051220.ini''; PSMMacro.PDCload4_initext=[];"' );
    disp('-------------------------------------------------------------------------------' );
    disp('In subEditMacro: Invoking "keyboard" command - Enter "return" when you are finished')
    keyboard
    save(PSMMacro.MacroName,'PSMMacro');
end
disp('Return from editing macro.');