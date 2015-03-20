% By ning zhou 04/01/2006 for macro
% Updated ning zhou 10/18/2006 for macro

function [LockStatus,KeyStatus]=funLoadMacro(LockCtrl, KeyCtrl,MacroNum, RunMode, PauseMode)
% Input Parameters:
%
% LockCtrl:     Macro Lock control; To be used to control if matro can be removed
%               =-1 or []  read the Macro only
%               =10,       read the lock and key status
%               = 0,       unlock
%               = 1,       lock
%               =99,       reset the macro;

% KeyCtrl:      =0,         all purpose key
%               =other,     key
%
% MacroNum:     the number of macro to be run
%
% RunMode:      Macro Run Mode,  
%                                =2  mode to play a batch macro,
%                                =1  mode to play a macro, 
%                                =0  mode to record a macro,
%                                =-1 mode to stop a macro from playing or recording
%                                =NaN remain original states
%
% PauseMode:    effective only under the Macro 'record mode' (i.e. RunMode=0).
%                                =1 record pause (wiped the previous recorded macro items), 
%                                =0 record continue;
% LockCtrl:     control the MacroLock,
%                                =-1 no action (return the lock status)
%                                = 0 unlock
%                                = 1 lock

% Output Parameters
%               LockStatus: 0 unlocked, 1 locked
%               KeyStatus: current key
% 

persistent pMacroLock pMacroKey pMacroNum pRunMode pPauseMode    % lock the macro;
global PSMMacro         % Macro Structure; =1 locked; =0 not locked



%***************************************************************************
% 1.0 Check the arguments
if (nargin < 1);LockCtrl=[];end
if (nargin < 2);KeyCtrl=[];end

if (nargin < 3);MacroNum=[];end
if (nargin < 4);RunMode=[];end
if (nargin < 5);PauseMode=[];end

if (isempty(LockCtrl));  LockCtrl=-1; end;     % default is "no action (control)" check the status of the lock
if (isempty(KeyCtrl));   KeyCtrl=-1; end;        % default is default key

if (isempty(MacroNum));  MacroNum=0; end;       % default macro
if (isempty(RunMode));   RunMode=-1; end;       % default Run Mode is "hyberhate"
if (isempty(PauseMode)); PauseMode=0; end;      % default pause model is "record continue"


if (isempty(pMacroLock))
    munlock;
    pMacroLock=0; 
    pMacroKey=0;
    pMacroNum=MacroNum;
    pRunMode=RunMode;
    pPauseMode=PauseMode;
end;                                    % default is that macro is not locked

if (LockCtrl==10)                    % check the locks' status request
    LockStatus=pMacroLock;
    KeyStatus=pMacroKey;
    return  
end

if (KeyCtrl==pMacroKey || KeyCtrl==0 )   % matched key or universal key
    KeyMatch=1;
else
    KeyMatch=0;
end


if pMacroLock                                % if the macro is locked
    if (KeyMatch==1 && LockCtrl==0)
        munlock;
        pMacroLock=0;
    end
else                                        % if the macro is not locked yet
    if (LockCtrl==1)                        % if lock command is issued
         mlock;
         pMacroLock=1;
         pMacroKey=KeyCtrl;                 % a new lock is applied
    end
end


if (pMacroLock==0 || KeyMatch)              % if the lock is open
    pMacroNum=MacroNum;                     % status is changed accordingly
    pRunMode=RunMode;
    pPauseMode=PauseMode;
end

%pathName='C:\';
%pathName=matlabroot;
pathName=tempdir;

switch pMacroNum
    case 1
      MacroName=fullfile(pathName, 'MacroDefault01.mat');
    case 2
      MacroName=fullfile(pathName, 'MacroDefault02.mat');  
    case 3
      MacroName=fullfile(pathName, 'MacroDefault03.mat');          
    otherwise
      MacroName=fullfile(pathName, 'MacroDefault.mat');
end

if (LockCtrl==99 && KeyMatch)
    ReadDefault=1;  
else
    try
        ReadDefault=0;
        load(MacroName);
    catch
        ReadDefault=1;  
    end
end

    

    
    PSMMacro.RunMode=pRunMode;      % Macro Run Mode,  =1  mode to play a macro, 
                                    %                  =0  mode to record a macro,
                                    %                  =-1 mode to hybernate
    PSMMacro.PauseMode=pPauseMode;  % effective only under the Macro 'record mode' (i.e. RunMode=0). =1 record pause, =0 record continue; 
    PSMMacro.MacroName=MacroName;

    if (ReadDefault)                 % can not find the files, which define a macro
        PSMMacro.EventScan1_PathName=[];     % path of Event scan
        PSMMacro.EventScan1_LogFname=[];     % file name of the event scan summary
        PSMMacro.EventScan1_PSMfilesIndex=0; % file index of the event scan
        
        % control in PSMlaunch*.m
        PSMMacro.PSMlaunch_CaseL=-1;      % Macro default definition
        % control in PSMlaunch*.m::PSMbrowser::CaseTags.m
        PSMMacro.CaseTags_setok=NaN;
        PSMMacro.AddCom_lineok=NaN;
        PSMMacro.EndChecks_keybdok=NaN;
        PSMMacro.EndChecks_fillok=NaN;
        PSMMacro.EndChecks_keybdok02=NaN;
        PSMMacro.EndChecks_omitok=NaN;
        
        PSMMacro.PSMbrowser_defsok=NaN;
        PSMMacro.PSMbrowser_logok=NaN;
        PSMMacro.PSMbrowser_extractok=NaN;
        PSMMacro.PSMbrowser_dispok=NaN;
        PSMMacro.PSMbrowser_OpTypeN=NaN;
        PSMMacro.PSMbrowser_setok=NaN;
        PSMMacro.PSMbrowser_setok21=NaN;
        PSMMacro.PSMbrowser_RepOK=NaN;
        PSMMacro.PSMbrowser_AppOK=NaN;
        PSMMacro.PSMbrowser_setok42=NaN;
        PSMMacro.PSMbrowser_closeok=NaN;
        PSMMacro.PSMbrowser_closeok03=NaN;
        PSMMacro.PSMbrowser_closeok05=NaN;
        PSMMacro.PSMbrowser_closeok06=NaN;
        PSMMacro.PSMbrowser_closeok07=NaN;
        PSMMacro.PSMbrowser_closeok08=NaN;
        PSMMacro.PSMbrowser_closeok09=NaN;
        PSMMacro.PSMbrowser_closeok21=NaN;
        PSMMacro.PSMbrowser_closeok70=NaN;
        PSMMacro.PSMbrowser_keybdok=NaN;
        PSMMacro.PSMbrowser_menusok=NaN;
        PSMMacro.PSMbrowser_chansPok=NaN;
        PSMMacro.PSMbrowser_chansP='';
        PSMMacro.PSMbrowser_MenuName='';
        PSMMacro.PSMbrowser_retrieveok=NaN;
        
        
        PSMMacro.PSMload_PSMntype=NaN;
        PSMMacro.PSMload_PSMtype=NaN;
        PSMMacro.PSMload_PSMtypeok=NaN;
        PSMMacro.PSMload_GetRange=NaN;
        PSMMacro.PSMload_PSMfiles=[];
        PSMMacro.PSMload_PSMpaths=[];
        PSMMacro.PSMload_dstFileChosen=NaN;
        PSMMacro.PSMload_filesok=NaN;
        PSMMacro.PSMload_savesok=NaN;
        PSMMacro.PSMload_DataPath='';
        PSMMacro.PSMload_FileType='';
        PSMMacro.PSMload_SWXtypeok=NaN;
        PSMMacro.PSMload_SWXtype=NaN;
        PSMMacro.PSMload_SWXntype=NaN;
        PSMMacro.PSMload_rangeFileChosen=NaN;
        
        PSMMacro.PDCloadN_AliasOK=NaN;
        PSMMacro.PDCloadN_n='';
        PSMMacro.PDCloadN_p='';

        
        PSMMacro.PDCload4_MatFmt=NaN;
        PSMMacro.PDCload4_initext=[];
        PSMMacro.PDCload4_fname=[];
        PSMMacro.PDCload4_CFname=[];
        PSMMacro.PDCload4_setok=NaN;
        PSMMacro.PDCload4_setok2=NaN;
        PSMMacro.PDCload4_setok04=NaN;
        PSMMacro.PDCload4_setok05=NaN;
        PSMMacro.PDCload4_PatchMode=NaN;
        PSMMacro.PDCload4_logpatch=NaN;
        PSMMacro.PDCload4_PlotPatch=NaN;
        PSMMacro.PDCload4_keybdok=NaN;
        PSMMacro.PDCload4_keybdok02=NaN;
        PSMMacro.PDCload4_keybdok03=NaN;
        
        
        PSMMacro.PDCload4_BnkLevelPU=NaN;
        PSMMacro.PDCload4_BnkFactor=NaN;
        
        PSMMacro.PDCload4_PlotPatch=NaN;
        PSMMacro.PDCload4_LogPatch=NaN; 
        
 
        PSMMacro.SetExtPDC_chansXok=NaN;
        PSMMacro.SetExtPDC_chansX=NaN;
        PSMMacro.SetExtPDC_MenuName='';
        

        PSMMacro.PSMplot2_PrintPlot=NaN;
        PSMMacro.PSMplot2_SavePlot=NaN;
        PSMMacro.PSMplot2_setok=NaN;
        PSMMacro.PSMplot2_TRangeok=NaN;
        PSMMacro.PSMplot2_TRangeok2=NaN;
        
        PSMMacro.PSMplot2_TUTypeok=NaN;
        PSMMacro.PSMplot2_TUName='';
        PSMMacro.PSMplot2_TUnits='';
        
        PSMMacro.PSMplot2_chansPok=NaN;
        PSMMacro.PSMplot2_chansP='';
        PSMMacro.PSMplot2_MenuName='';
        
        PSMMacro.PSMplot2_XchanOK=NaN;
        PSMMacro.PSMplot2_nStyle=NaN;
        PSMMacro.PSMplot2_PerPage=NaN;
        PSMMacro.PSMplot2_Detrendok=NaN;
        PSMMacro.PSMplot2_Normok=NaN;
        
        PSMMacro.PSMsave_saveok=NaN;
        PSMMacro.PSMsave_SWXok=NaN;
        PSMMacro.PSMsave_nameok=NaN;
        PSMMacro.PSMsave_AdjRefDate=NaN;
        PSMMacro.PSMsave_TRangeCk=NaN;
        PSMMacro.PSMsave_keyboardok=NaN;
        PSMMacro.PSMsave_TrimCC=NaN;
        
        
        PSMMacro.ModeMeterM_defsok=NaN;
        PSMMacro.ModeMeterM_setok=NaN;
        PSMMacro.ModeMeterM_setok02=NaN;
        PSMMacro.ModeMeterM_setok03=NaN;
        PSMMacro.ModeMeterM_setok04=NaN;
        PSMMacro.ModeMeterM_offtrend=NaN;
        PSMMacro.ModeMeterM_chansMM=[];
        PSMMacro.ModeMeterM_refchansMM=[];   
        PSMMacro.ModeMeterM_keybdok=NaN;
        PSMMacro.ModeMeterM_TRangeok=NaN;
        PSMMacro.ModeMeterM_nrangeN=NaN;
        PSMMacro.ModeMeterM_TRangeMM=NaN;
        PSMMacro.ModeMeterM_OpTypeN=NaN;
        

        
        PSMMacro.ModeMeterA_setok=NaN;
        PSMMacro.ModeMeterA_viewok=NaN;
        PSMMacro.ModeMeterA_Fullok=NaN;
        PSMMacro.ModeMeterA_scanok=NaN;
        PSMMacro.ModeMeterA_keybdok=NaN;
        PSMMacro.ModeMeterA_keybdok02=NaN;
        
        PSMMacro.ModeMeterC_Chosen=NaN;
        PSMMacro.ModeMeterC_saveok=NaN;
        
        PSMMacro.PDCrefsig_EstFrq=NaN;
        PSMMacro.PDCrefsig_UnWrap=NaN;
        PSMMacro.PDCrefsig_setok=NaN;
        PSMMacro.PDCrefsig_RefTypeok=NaN;
        PSMMacro.PDCrefsig_RefType=NaN;
        PSMMacro.PDCrefsig_RefNype=NaN;
        PSMMacro.PDCrefsig_refok=NaN;
        PSMMacro.PDCrefsig_RefName=NaN;
        PSMMacro.PDCrefsig_RefSigN=NaN;
        PSMMacro.PDCrefsig_appok=NaN;
        PSMMacro.PDCrefsig_DifTypeok=NaN;
        PSMMacro.PDCrefsig_DifType=NaN;
        PSMMacro.PDCrefsig_DifNype=NaN;
        PSMMacro.PDCrefsig_keybdok=NaN;
        
        PSMMacro.PSMfilt_setok=NaN;
        PSMMacro.PSMfilt_setok02=NaN;
        PSMMacro.PSMfilt_setok03=NaN;
        PSMMacro.PSMfilt_TagsEdit=NaN;
        PSMMacro.PSMfilt_rawdecimate=NaN;
        PSMMacro.PSMfilt_offtrend=NaN;
        PSMMacro.PSMfilt_FilTypeok=NaN;
        PSMMacro.PSMfilt_FilName=NaN;
        PSMMacro.PSMfilt_FilType_1=NaN;
        PSMMacro.PSMfilt_Show=NaN;
        PSMMacro.PSMfilt_offrestore=NaN;
        PSMMacro.PSMfilt_fildecimate=NaN;
        PSMMacro.PSMfilt_decfac=NaN;
        
        PSMMacro.PSMbutr4_filparsok=NaN;
        PSMMacro.PSMbutr4_FilTypeok=NaN;
        PSMMacro.PSMbutr4_FilName=NaN;
        PSMMacro.PSMbutr4_FilType_2=NaN;
        PSMMacro.PSMbutr4_HPnorm=NaN;
        PSMMacro.PSMbutr4_LPnorm=NaN;
        PSMMacro.PSMbutr4_FilOrd=NaN;
        PSMMacro.PSMbutr4_CheckFil=NaN;
        PSMMacro.PSMbutr4_plotok=NaN;
        PSMMacro.PSMbutr4_setok=NaN;
        
        PSMMacro.PSMresamp_CheckTimeok=NaN;
        PSMMacro.PSMresamp_keepsmooth=NaN;
        
        
        PSMMacro.PSMSinc_SincFac=NaN;
        PSMMacro.PSMSinc_LPcorner=NaN;
        PSMMacro.PSMSinc_plotok=NaN;
        PSMMacro.PSMSinc_setok=NaN;
        
        PSMMacro.SincHP_BSincH1=[];
        PSMMacro.SincHP_BSincH2=[];
        PSMMacro.SincHP_BSincH3=[];
        PSMMacro.SincHP_plotok=NaN;
        PSMMacro.SincHP_plotok02=NaN;
        PSMMacro.SincHP_setok=NaN;
        
        PSMMacro.PSMbox_LPcorner=NaN;
        PSMMacro.PSMbox_plotok=NaN;
        PSMMacro.PSMbox_setok=NaN;
        
        PSMMacro.PSMspec1_setok=NaN;
        PSMMacro.PSMspec1_WinTypeok=NaN;
        PSMMacro.PSMspec1_WinName=NaN;
        PSMMacro.PSMspec1_WinType_1=NaN;
        PSMMacro.PSMspec1_setok02=NaN;
        PSMMacro.PSMspec1_chansAok=NaN;
        PSMMacro.PSMspec1_chansAN=NaN;
        PSMMacro.PSMspec1_MenuName=NaN;
        PSMMacro.PSMspec1_refok=NaN;
        PSMMacro.PSMspec1_refname=NaN;
        PSMMacro.PSMspec1_refchan=NaN;
        PSMMacro.PSMspec1_TRangeCk=NaN;
        PSMMacro.PSMspec1_fftok=NaN;        
        PSMMacro.PSMspec1_tstart=NaN;
        PSMMacro.PSMspec1_tstop=NaN;
        PSMMacro.PSMspec1_nfft=NaN;
        PSMMacro.PSMspec1_lap=NaN;
        PSMMacro.PSMspec1_tstep=NaN;
        PSMMacro.PSMspec1_Tbar=NaN;
        PSMMacro.PSMspec1_SpecTrnd=NaN;
        PSMMacro.PSMspec1_WinType=NaN;
        PSMMacro.PSMspec1_Frange=NaN;
        PSMMacro.PSMspec1_PlotOps=NaN;
        PSMMacro.PSMspec1_ShowTRF=NaN;
        PSMMacro.PSMspec1_ShowTsigs=NaN;
        PSMMacro.PSMspec1_PrintPlot=NaN;
        PSMMacro.PSMspec1_ShowSyyWF=NaN;
        PSMMacro.PSMspec1_ShowCxyWF=NaN;
        PSMMacro.PSMspec1_setok03=NaN;
        PSMMacro.PSMspec1_WFparsOk=NaN;
        PSMMacro.PSMspec1_WFpars=NaN;
        PSMMacro.PSMspec1_chansWFok=NaN;
        PSMMacro.PSMspec1_namesWF=NaN;
        PSMMacro.PSMspec1_chansWF_1=NaN;
        PSMMacro.PSMspec1_setok04=NaN;
        PSMMacro.PSMspec1_Ringok=NaN;
        
        PSMMacro.PSMhist1_setok=NaN;
        PSMMacro.PSMhist1_offtrend=NaN;
        PSMMacro.PSMhist1_chansAok=NaN;
        PSMMacro.PSMhist1_namesA=NaN;
        PSMMacro.PSMhist1_chansA=NaN;
        PSMMacro.PSMhist1_TRangeCk=NaN;
        PSMMacro.PSMhist1_Histok=NaN;
        PSMMacro.PSMhist1_HistTrnd=NaN;
        PSMMacro.PSMhist1_nHist=NaN;
        PSMMacro.PSMhist1_tstart=NaN;
        PSMMacro.PSMhist1_tstop=NaN;
        PSMMacro.PSMhist1_KeepPlot=NaN;
        PSMMacro.PSMhist1_ShowHist=NaN;
        PSMMacro.PSMhist1_ShowTsigs=NaN;
        PSMMacro.PSMhist1_PrintPlot=NaN;
        PSMMacro.PSMhist1_SavePlot=NaN;
        
        PSMMacro.PRSdisp1_FigDef=NaN;
        PSMMacro.PRSdisp1_RepeatCase=NaN;
        PSMMacro.PRSdisp1_setok=NaN;
        PSMMacro.PRSdisp1_BuildSS=NaN;
        PSMMacro.PRSdisp1_menusok=NaN;
        PSMMacro.PRSdisp1_chansPok=NaN;
        PSMMacro.PRSdisp1_chansP=NaN;
        PSMMacro.PRSdisp1_MenuName=NaN;
        
        PSMMacro.RootSort1_FLIM1=NaN;
        PSMMacro.RootSort1_FLIM2=NaN;
        PSMMacro.RootSort1_DLIM1=NaN;
        
        PSMMacro.PSMcov1_chansAok=NaN;
        PSMMacro.PSMcov1_namesA=NaN;
        PSMMacro.PSMcov1_chansA=NaN;
        PSMMacro.PSMcov1_setok=NaN;
        PSMMacro.PSMcov1_Covok=NaN;
        PSMMacro.PSMcov1_tstart=NaN;
        PSMMacro.PSMcov1_tstop=NaN;
        PSMMacro.PSMcov1_maxlagT=NaN;
        PSMMacro.PSMcov1_biasok=NaN;
        PSMMacro.PSMcov1_ShowTsigs=NaN;
        PSMMacro.PSMcov1_setok02=NaN;
        PSMMacro.PSMcov1_keybdok=NaN;
        PSMMacro.PSMcov1_closeok=NaN;
        PSMMacro.PSMcov1_keybdok02=NaN;
        PSMMacro.PSMcov1_keybdok03=NaN;
        
        PSMMacro.DXDcalcs1_LocVsigs=NaN;
        PSMMacro.DXDcalcs1_LocIsigs=NaN;
        PSMMacro.DXDcalcs1_keybdok=NaN;
        PSMMacro.DXDcalcs1_PMUcalcs=NaN;
        PSMMacro.DXDcalcs1_FPSTtypeok=NaN;
        PSMMacro.DXDcalcs1_FPSstr=NaN;
        PSMMacro.DXDcalcs1_FPStype=NaN;
        PSMMacro.DXDcalcs1_trackok=NaN;
        PSMMacro.DXDcalcs1_trackok02=NaN;
        PSMMacro.DXDcalcs1_trackok03=NaN;
        PSMMacro.DXDcalcs1_keybdok03=NaN;
        PSMMacro.DXDcalcs1_CplotCase=NaN;
        PSMMacro.DXDcalcs1_keybdok04=NaN;
        PSMMacro.DXDcalcs1_setok=NaN;
        PSMMacro.DXDcalcs1_setok02=NaN;
        PSMMacro.DXDcalcs1_keybdok05=NaN;
        PSMMacro.DXDcalcs1_closeok=NaN;
        PSMMacro.DXDcalcs1_keybdok06=NaN;
        
        PSMMacro.SpecialDisp_launchok=NaN;
        PSMMacro.SpecialDisp_keybdok=NaN;
        
        PSMMacro.RobustPSMT_chansAok=NaN;
        PSMMacro.RobustPSMT_chansA=NaN;
        PSMMacro.RobustPSMT_TRangeCk=NaN;
        PSMMacro.RobustPSMT_RGok=NaN;
        PSMMacro.RobustPSMT_keybdok=NaN;
        
        PSMMacro.PDCCSVload_MatFmt=NaN;
        PSMMacro.PDCCSVload_initext=[];
        PSMMacro.PDCCSVload_fname=[];
        PSMMacro.PDCCSVload_CFname=[];
        PSMMacro.PDCCSVload_PatchMode=NaN;
        PSMMacro.PDCCSVload_logpatch=NaN;
        PSMMacro.PDCCSVload_setok=NaN;
        PSMMacro.PDCCSVload_BnkLevelPU=NaN;
        PSMMacro.PDCCSVload_BnkFactor=NaN;
        PSMMacro.PDCCSVload_PlotPatch=NaN;
        PSMMacro.PDCCSVload_LogPatch=NaN;
        PSMMacro.PDCCSVload_PatchMode=NaN;
        PSMMacro.PDCCSVload_LogSum=NaN;
        
        PSMMacro.SetExtPPSM_NullsOut=NaN;
        PSMMacro.SetExtPPSM_chansXok=NaN;
        PSMMacro.SetExtPPSM_chansX=NaN;
        PSMMacro.SetExtPPSM_MenuName='';        
        
        PSMMacro.PPSMload_PSMsigsX=NaN;
        PSMMacro.PPSMload_channels=NaN;
        PSMMacro.PPSMload_names=NaN;
        PSMMacro.PPSMload_units=NaN;
        PSMMacro.PPSMload_delay=NaN;
        PSMMacro.PPSMload_DataPath=NaN;
        PSMMacro.PPSMload_DataNames='';
        PSMMacro.PPSMload_PPSMlist=NaN;
        PSMMacro.PPSMload_errmsg=NaN;
        
        PSMMacro.Cread_setok=NaN;
        PSMMacro.Cread_keybdok=NaN;
        
        PSMMacro.SetExtSWX_chansXok=NaN;
        PSMMacro.SetExtSWX_chansX=NaN;
        PSMMacro.SetExtSWX_MenuName='';

        PSMMacro.SWXload_resample=NaN;
        PSMMacro.PSMload_keybdok=NaN;
        
        PSMMacro.PSAMload_chansXok=NaN;
        PSMMacro.PSAMload_chansX=NaN;
        
        PSMMacro.PSMTload_chansXok=NaN;
        PSMMacro.PSMTload_chansX=NaN;
        PSMMacro.PSMTload_MenuName=NaN;
        
        PSMMacro.CaseComPlot_HPtrim=NaN;
        
        PSMMacro.PSMreload_NewRate=NaN;
        PSMMacro.PSMreload_PSMfilesR='';
        PSMMacro.PSMreload_pathname='';
        PSMMacro.PSMreload_ratesok=NaN;
        PSMMacro.PSMreload_stampsok2=NaN;
        PSMMacro.PSMreload_stampok=NaN;
        PSMMacro.PSMreload_Xrangeok=NaN;
        PSMMacro.PSMreload_ApTags=NaN;
        PSMMacro.PSMreload_keybdok=NaN;
        PSMMacro.PSMreload_savesok=NaN;
    end

LockStatus=pMacroLock;
KeyStatus=pMacroKey;

return



