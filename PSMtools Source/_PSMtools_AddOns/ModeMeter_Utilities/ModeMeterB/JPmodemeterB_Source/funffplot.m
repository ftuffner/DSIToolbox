function [amp,phas,w,sdamp,sdphas] = funffplot(varargin)
%FFPLOT Plots a diagram of a frequency function or spectrum with linear 
%       frequency scales and Hz as the frequency unit.
%
%   FFPLOT(M)  or  FFPLOT(M,'SD',SD) or FFPLOT(M,W) or FFPLOT(M,SD,W)
%
%   where M is an IDMODEL or IDFRD object, like IDPOLY, IDSS, IDARX or
%   IDGREY, obtained by any of the estimation routines, including 
%   ETFE and SPA. The frequencies in W are specified in Hz.
%
%   The syntax is the same as for BODE. See also  IDMODEL/BODE for all
%   details. When used with output arguments,
%   [Mag,Phase,W,SDMAG,SDPHASE] = FFPLOT(M,W)
%   the frequency unit of W is Hz.

%   Copyright 1986-2001 The MathWorks, Inc.
%   $Revision: 1.9 $ $Date: 2001/04/06 14:22:30 $

try
   if nargout == 0
      funbodeaux(0,varargin{:});
   elseif nargout <= 3
      [amp,phas,w] = funbodeaux(0,varargin{:});
      w=w/2/pi;
   else
      [amp,phas,w,sdamp,sdphas] = funbodeaux(0,varargin{:});
      w=w/2/pi;
   end
catch
   error(lasterr)
end
