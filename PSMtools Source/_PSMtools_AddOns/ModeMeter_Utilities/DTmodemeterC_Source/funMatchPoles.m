function [MajorPoles,Err2,Degrade]=funMatchPoles(TruePoles,EstPoles,EmphasisFactor)
% find the estimation error square for estimation poles
% 
% TruePoles:        True possition of poles
% EstPoles:         Estimation of position of poles
% EmphasisFactor:   How much do we want to emphasis the image part
%
% Err2:              squares of estimation errors (inf if can not be found)
% MajorPoles:       Major poles close to TruePoles; (0 if can not be found)
if (nargin < 2);error('Pole match analysis needs at least 3 arguments');end
if (nargin < 4);EmphasisFactor=[];end
if (length(EmphasisFactor)==0); EmphasisFactor=1;end

Nt=length(TruePoles);
Ne=length(EstPoles);

%*************************************
% 1.0 establish distance matrix
Dist=zeros(Nt,Ne);  % distance matrix
MSErr=zeros(Nt,Ne);
for tIndex=1:Nt
    for eIndex=1:Ne
        dTemp=TruePoles(tIndex)-EstPoles(eIndex);
        MSErr(tIndex,eIndex)=abs(dTemp).^2;
        rTemp=real(dTemp);
        iTemp=imag(dTemp);
        Dist(tIndex,eIndex)=rTemp*rTemp/EmphasisFactor+iTemp*iTemp;  % distance between two poles; 2.5 used to reduce influene of distance on real direction
     end
end

%*************************************
% 2.0 establish pole matches
Err2=zeros(Nt,1);
MajorPoles=zeros(Nt,1);
PoleDegrade=zeros(Nt,1);
tempDist=Dist;
for tIndex=1:Nt
    [minRowsValue,minColIndex]=min(tempDist,[],2);      % find minmum distance for each true modes
    [minMatrixValue,minRowIndex]=min(minRowsValue);      % find minmum distance for whole disctance matrix.
    MajorPoles(minRowIndex)=EstPoles(minColIndex(minRowIndex));     % locate the correponding estimation poles for true modes.
    Err2(minRowIndex)=MSErr(minRowIndex,minColIndex(minRowIndex));                % find the error.

    for rIndex=1:Nt
        if rIndex~=minRowIndex
            if minColIndex(minRowIndex)==minColIndex(rIndex)
                if minRowsValue(rIndex)<inf
                   PoleDegrade(rIndex)=PoleDegrade(rIndex)+1;
               end
           end
       end
   end
   tempDist(:,minColIndex(minRowIndex))=inf;                        % delete the matched estimation pole from distance matrix.
   tempDist(minRowIndex,:)=inf;                        % delete the matched true pole from distance matrix.
end

if nargout ==3
    Degrade=PoleDegrade;
end