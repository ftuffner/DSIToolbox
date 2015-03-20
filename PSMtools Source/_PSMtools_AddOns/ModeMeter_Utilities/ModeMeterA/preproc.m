function y=preproc(x,D,blp,bhp,ahp);
%*********************************
%Usage y=preproc(x,D,blp,bhp,ahp);
%  Inputs:
%     x:  signal to be preprocessed
%     D:  Decimation factor
%     blp:  Lowpass FIR filter coefficients
%     bhp:  Highpass numerator filter coefficients
%     ahp:  Highpass denominator filter coefficients
%  Outputs:
%     y:  signal after preprocessing
%**********************************
y=filter(blp,1,x);    %lowpass filtered data
y=y(1:D:length(y));   %decimated data
y=filter(bhp,ahp,y);  %highpassed filtered data
