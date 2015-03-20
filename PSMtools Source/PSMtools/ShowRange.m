function [TRange,nrange,TRangeok]=ShowRange(PSMsigsX,namesX,DispSig,TRange,tstep,maxtrys)
% Interactive graphics to determine processing range
%
%  [TRange,nrange,TRangeok]=ShowRange(PSMsigsX,namesX,DispSig,TRange,tstep,maxtrys);
%
% Last modified 08/25/03.  jfh
% Modified 07/12/05 by Henry Huang.  Changed some defaults & prompts

% By J. F. Hauer, Pacific Northwest National Laboratory.
%
% Copyright (c) 1995-1998 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.

global Kprompt ynprompt nvprompt

nsigsX=size(PSMsigsX,2);	
maxpoints=size(PSMsigsX,1);
if ~exist('DispSig'), DispSig=[]; end
if  isempty(DispSig), DispSig=min(nsigsX,3); end
DispSig=min(DispSig,nsigsX);
if  ~exist('tstep'),  tstep=[]; end
if  isempty(tstep),   tstep=PSMsigsX(2,1)-PSMsigsX(1,1); end

tmin=PSMsigsX(1,1); tmax=PSMsigsX(maxpoints,1);
disp(sprintf('In ShowRange: Max TRange = [ %6.2f %6.2f ]', tmin,tmax))
if ~exist('TRange'), TRange=[]; end
if  isempty(TRange), TRange=[tmin tmax]; end
if TRange(2)<=TRange(1),TRange=[tmin tmax]; end
if ~exist('maxtrys'), maxtrys=1; end
if isempty(maxtrys),  maxtrys=5; end
maxtrys=max(maxtrys,1);

%*************************************************************************
TRangeok=0;
%keyboard;
for i=1:maxtrys
  if ~TRangeok
    if i==1, h=figure; end   %Initiate new figure
    plot(PSMsigsX(:,1),PSMsigsX(:,DispSig)); figure(h)
    Ptitle{1}=namesX(DispSig,:);
    Ptitle{2}=sprintf('TRange = [ %6.2f %6.2f ]', TRange);
    title(Ptitle); xlabel('Time in Seconds')
    set(gca,'TickDir','out')
    set(gca,'xlim',TRange)
    disp(sprintf('In ShowRange: Indicated TRange = [ %6.2f %6.2f ]', TRange))
	  TRangeok=promptyn('  Is this range ok? ', 'y');       % set default to 'y'. Henry 07/12/05
    if ~TRangeok
      disp('In ShowRange: Select time range for data operations')
      str=sprintf('Display signal is DispSig=%3.0i : ',DispSig);
      disp([str namesX(DispSig,:)]) 
      disp('EXAMPLE FOLLOWS:')
      disp(sprintf('  TRange=[ %6.2f %6.2f ]',TRange))
	    disp('Invoking "keyboard" command - Enter "return" when you are finished')
      keyboard
    end
    TRange(1)=max(TRange(1),tmin); TRange(2)=min(TRange(2),tmax); 
  end
end
if ~TRangeok
  disp(sprintf('Sorry -%5i chances is all you get!',maxtrys))
  disp('  Defaulting to full time range')
  disp('  Returning to invoking Matlab function')
  TRange=[tmin tmax]; nrange=[1 maxpoints]; return
end
%Determine save range in samples
n1=round((TRange(1)-tmin)/tstep+1); n2=round(min((TRange(2)-tmin)/tstep+1,maxpoints));
nrange=[n1 n2];


%end of PSMT m-file