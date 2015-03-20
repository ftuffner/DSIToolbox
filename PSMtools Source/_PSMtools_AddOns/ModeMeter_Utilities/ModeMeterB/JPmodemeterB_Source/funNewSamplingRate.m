function DeciFactor=funNewSamplingRate(Ts)
Fs=1/Ts;
disp('  ');
if (Fs > 6)
    disp(sprintf('Your sample Freq is %5.2f Hz,which might be too high for identification purpose.',Fs));
    Response=input('Do you want to do decimation (decrease the sampling freq)?  Enter y or n [y]:','s');
    if isempty(Response)                 %Test for empty string
       setok=1;
    else
       setok=~strcmp(lower(Response(1)),'n');     %String comparison
    end
     
    if setok
       disp(' ');
       disp(sprintf('New sample freq = %5.2f/decimation factor',Fs));
       DeciFactor=input(sprintf('Input your decimation factor (which should be a positive integer)[%d]:', floor(Fs/5)));
       if isempty(DeciFactor) 
          DeciFactor=floor(Fs/5);
       else
          DeciFactor=round(DeciFactor);
       end
       disp(' ');
       disp(sprintf('New sampling rate= %5.2f Hz',Fs/DeciFactor));
       disp(' ');
    else
        DeciFactor=1;
        disp('........');
        disp('Decimation is not performed');
        disp(' '); disp(' ');
    end
else
   DeciFactor=1 
   disp('........');
   disp('Decimation is not performed');
   disp(' '); disp(' ');
end
