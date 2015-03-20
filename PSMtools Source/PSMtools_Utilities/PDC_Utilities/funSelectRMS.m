
%   1) selected channel is stored in chansX; 
%   2) relevant phasors are marked in VIcon(:,7,:) as 1

function [CaseCom, chansX, chansXok, VIcon ]...
      =funSelectRMS(CaseCom, chansX,chansXok, VIcon, NPMUs,CFname, PhsrNames, trackX, nXfile)

% Extended code for processing phasor measurements data through PSM_Tools.
%
% This version uses .ini files that specify PDC configuration.
%
% Special functions used:
%   SetExtPDC
%	promptyn,promptnv
%
% Modified 04/05/06.  zn   selection of channels before patching data 
% Modified from PDCcalcC.m By J. F. Hauer, Pacific Northwest National Laboratory.
% Modified 04/18/06.  jfh  message to track processing 
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

%-------------------------------------------------------------------------
% Start: This following is to improve implementation effiency. It can be removed.
%persistent VIconHist
%if isempty(VIconHist)
%    VIconHist=zeros(size(VIcon(:,7,:)));
%elseif nXfile~=1 || chansXok~=0
%    VIcon(:,7,:)=VIconHist;
%    return
%end
%end: This following is to improve implementation effiency. It can be removed.
%-------------------------------------------------------------------------

FNname='funSelectRMS';
S1=['In ' FNname ': Selecting signals to use'];
disp(S1); 

%*********************************************************************************
% Start: Select the channels before repairing the data (ZN) 04/05/2006
if nXfile==1 && chansXok==0
    %---------------------------------------------------------------
    text=[PhsrNames(1,:,1) ' VAng' '  '];
    chars=size(text,2);
    RMSnames='';
    Sloc=1;
    PMUbase=zeros(NPMUs+1,1);
    for K=1:NPMUs
      AngTag='L '; 
      % GPSlost=NOGPS; if GPSlost(K), AngTag='LX'; end 
        nphsrsK=sum(VIcon(:,1,K)==1|VIcon(:,1,K)==2);
        for N=1:nphsrsK
            loc=PMUbase(K)+N;
            phsrtype=VIcon(N,1,K);
            if phsrtype==1
                RMSnames(Sloc+0,1:chars)=[PhsrNames(N,:,K) ' VMag' '  '  ];
                RMSnames(Sloc+1,1:chars)=[PhsrNames(N,:,K) ' VAng' AngTag];
                Sloc=Sloc+2;
                if N==1
                    RMSnames(Sloc,1:chars)=[PhsrNames(N,:,K) ' Freq' AngTag];
                    Sloc=Sloc+1;
                end
            end

            if phsrtype==2
                RMSnames(Sloc+0,1:chars)=[PhsrNames(N,:,K) ' MW  ' '  '  ];
                RMSnames(Sloc+1,1:chars)=[PhsrNames(N,:,K) ' Mvar' '  '  ];
                RMSnames(Sloc+2,1:chars)=[PhsrNames(N,:,K) ' IMag' '  '  ];
                RMSnames(Sloc+3,1:chars)=[PhsrNames(N,:,K) ' IAng' AngTag];
                Sloc=Sloc+4;
            end
            
            if phsrtype~=1&phsrtype~=2
                disp(['In PDCcalcC: Unrecognized phasor type = ',sprintf('%4.0i',phsrtype)])
                pause
            end
        end
        PMUbase(K+1)=PMUbase(K)+nphsrsK;
    end
    RMSnames=str2mat('Time',RMSnames);
    %---------------------------------------------------------------

    %---------------------------------------------------------------
    %Define RMS key
    RMSkey=names2chans(RMSnames);
    %---------------------------------------------------------------

    %---------------------------------------------------------------
    %Determine rms signals to extract
    %disp('In PDCcalcC:'), keyboard

    [MenuName,chansX,chansXok]=SetExtPDC(chansX,RMSnames,RMSkey,CFname);
    if ~chansXok 
        disp('No menu selected - return');
        VIcon(:,7,:)=ones(size(VIcon(:,7,:)));
        return
    end
    str1=['Starting menu = ' MenuName];
    CaseCom=str2mat(CaseCom,str1);
    nsigs=max(size(chansX));
    str1='chansX='; disp(str1)
    CaseCom=str2mat(CaseCom,str1);
    for n1=1:15:nsigs
        n2=min(n1+15-1,nsigs);
        str1=[' ' num2str(chansX(n1:n2))]; 
        if n1==1, str1(1)='['; end
        if n2==nsigs, str1=[str1 ']']; end
        disp(str1)
        CaseCom=str2mat(CaseCom,str1);
    end
%---------------------------------------------------------------
end % end for "if nXfile==1 && chansXok==0"

%---------------------------------------------------------------
% Find the phasors required for RMS calculations and store them in the
% VIcon(:,7,:): =1 required field, =0 not required field
Sloc=2; Phloc=1;
PMUbase=zeros(NPMUs+1,1);
for K=1:NPMUs
    nphsrsK=sum(VIcon(:,1,K)==1|VIcon(:,1,K)==2);
    for N=1:nphsrsK
        loc=PMUbase(K)+N;
    	phsrtype=VIcon(N,1,K);
        if phsrtype==1                  % voltage phasors
            Vloc=Phloc;
            SXloc=find(Sloc+0==chansX);  %Voltage magnitude
            if ~isempty(SXloc)
                VIcon(N,7,K)=1;
            end
            SXloc=find(Sloc+1==chansX);   %Voltage angle
            if ~isempty(SXloc)
                VIcon(N,7,K)=1;
            end
        
            Sloc=Sloc+2;     %Increment signal counter 
        
            if N==1           
                SXloc=find(Sloc+0==chansX); %Frequency
                if ~isempty(SXloc)
                    VIcon(nphsrsK+1,7,K)=1;
                end
                Sloc=Sloc+1;    %Increment signal counter 
            end
            Phloc=Phloc+1;  %Increment phasor counter
        end
        
        if phsrtype==2                      % current phasors
            Vref=VIcon(N,6,K);              
            if Vref>0, Vloc=PMUbase(K)+Vref; end
            SXloc=find(Sloc+0==chansX);     % Real power
            if ~isempty(SXloc)
                VIcon(N,7,K)=1;
                if Vref>0
                    VIcon(Vref,7,K)=1;      % voltage position
                end
            end
            
            SXloc=find(Sloc+1==chansX);     %Reactive power
            if ~isempty(SXloc)
                VIcon(N,7,K)=1;
                if Vref>0
                    VIcon(Vref,7,K)=1;      % voltage position
                end
            end
            
            SXloc=find(Sloc+2==chansX);     %Current magnitude
            if ~isempty(SXloc)
                VIcon(N,7,K)=1;
            end
 
            SXloc=find(Sloc+3==chansX);      %Current angle
            if ~isempty(SXloc)
                VIcon(N,7,K)=1;
            end
            Sloc=Sloc+4; Phloc=Phloc+1;  %Increment counters
        end

        if phsrtype~=1&phsrtype~=2
            disp(['In PDCcalcC: Unrecognized phasor type = ',sprintf('%4.0i',phsrtype)])
            pause
        end
    end
    PMUbase(K+1)=PMUbase(K)+nphsrsK;
end
%---------------------------------------------------------------



% End:   Select the channels before repairing the data (ZN) 04/05/2006
%*********************************************************************************  