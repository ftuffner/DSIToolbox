function MyDataOut=funDecimate(MyDataIn,DeciFactor)

if DeciFactor> 1
    Ts=MyDataIn.Ts;
    Fs=1/Ts;
    DeciFactor=round(DeciFactor);
    TsFinal=Ts*DeciFactor;
    FsFinal=1/TsFinal;
    if length(MyDataIn.u)==0        % if ambient data is used
        % Anti-Alias low pass linear-phase FIR filter design using the Parks-McClellan algorithm
        n=90;               % order of the FIR filter
        %F=[0 0.01 0.02 FsFinal/2-0.5 FsFinal/2+0.5 Fs/2];     % Frequency in Hz
        F=[0 FsFinal/2-0.5 FsFinal/2+0.5 Fs/2];     % Frequency in Hz
        f=F/(Fs/2);         % f is a vector of pairs of normalized frequency points, specified in the range between 0 and 1, 
        m=[1 1 0 0];        % m is a vector containing the desired amplitudes at the points specified in f. 
        w=[1 3];
        %m=[0 0 1 1 0 0];        % m is a vector containing the desired amplitudes at the points specified in f. 
        %w=[0.5 1 3];
        b=remez(n,f,m,w);
        FilteredOutput=filter(b,1,MyDataIn.y);
        %Decimation 
        y=FilteredOutput(length(b)+1:DeciFactor:end,:);
        MyDataOut=iddata(y,[],TsFinal);
    else                            % if injection data is used
        % Anti-Alias low pass linear-phase FIR filter design using the Parks-McClellan algorithm
        FilterOrder=5;
        FilterWn=(FsFinal/2)/(Fs/2);
        MyData = idfilt(MyDataIn,FilterOrder,FilterWn,'noncausal');       
        MyDataOut = idresamp(MyData,DeciFactor);         
    end

%    disp(' ');
%    disp('Decimation has been performed on your data set');
%    disp(' ');
else
    MyDataOut=MyDataIn;
end