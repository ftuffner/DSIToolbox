function chFreqSeq=funFindStr(namesX, MyStr)
MyStr=lower(MyStr);
nsigsX=size(namesX,1);
chFreqSeq=[];
for chIndex=1:nsigsX
    chName=lower(namesX(chIndex,:));
    if findstr(chName,MyStr)
        chFreqSeq=[chFreqSeq; chIndex];
    end
end