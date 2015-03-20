function [pol,bres,res,thru,releng,afpe,sigmoddat]=Getmodel(figNumber,output,inctim);

% GETMODEL:  BPA/PNNL Ringdown Analysis Tool identified model parameters.
%
% Obtains model parameters identified using the BPA/PNNL Ringdown Analysis Tool.
%
% Usage:
%
%                   idmodel=Getmodel(figNumber,output,inctim);
%
%                                       or
%
%    [pol,bres,res,thru,releng,afpe,sigmoddat]=Getmodel(figNumber,output,inctim);
%
% where
%
%   figNumber = Figure number of the Ringdown Analysis Tool from which to
%               extract the identified model.
%
%   output    = System output number for which to return model.
%               Set output == 0 to obtain parameters for all outputs.
%
%   inctim    = Include time-domain response data?
%               Set inctim == 0 to not include data. 
%               Set inctim == 1 to include data.
%               Applies only when the first calling statement above is used.
%
%   pol       = Matrix with identified model poles.  Output number varies over
%               columns.
%
%   bres      = Matrix with identified signal residues.
%
%   res       = Matrix with identified transfer function residues.
%
%   thru      = Vector with identified feed-forward terms.
%
%   releng    = Matrix with relative mode energies.
%
%   afpe      = Matrix with Akaike Final Prediction Errors.
%
%   sigmoddat = Matrix with time-domain data for each output.  First column
%               is time.  Second through last columns are measurement and
%               model response data for each output.
%
%   idmodel   = Structure with identified model parameters.  Contains the following fields:
%               pol, bres, res, thru, releng, afpe, sigmoddat = See above
%               select = Logical matrix indicating if mode selected by user.
%
% See also RINGDOWN.

% By Jeff M. Johnson, Pacific Northwest National Laboratory.
% Date:  August 1997
%
% Copyright (c) 1995-2001 Battelle Memorial Institute.  The Government
% retains a paid-up nonexclusive, irrevocable worldwide license to
% reproduce, prepare derivative works, perform publicly and display
% publicly by or for the Government, including the right to distribute
% to other Government contractors.
%
% $Id$

% Initialize output arguments
  if nargout; pol=[]; bres=[]; res=[]; thru=[]; releng=[]; afpe=[]; sigmoddat=[]; end

% Print RCSID stamp and copyright
  if nargin==1 & ischar(figNumber) & strcmp(figNumber,'rcsid')
    fprintf(1,['\n$Id$\n\n' ...
      'Copyright (c) 1995-2013 Battelle Memorial Institute.  The Government\n' ...
      'retains a paid-up nonexclusive, irrevocable worldwide license to\n' ...
      'reproduce, prepare derivative works, perform publicly and display\n' ...
      'publicly by or for the Government, including the right to distribute\n' ...
      'to other Government contractors.\n\n' ...
      'Date of last source code modification:  05/22/2001 (JMJ)\n\n']);
    return
  end

% Strings with property names and values.
  ShowHiddenHandles='ShowHiddenHandles';
  Tag              ='Tag';

  dbl              ='double';
  figerr           ='Invalid Ringdown Analysis Tool figure.';

% Check input arguments.
  error(nargchk(2,3,nargin));

  if nargin<3; if nargout==7; inctim=1; else; inctim=0; end; end

  if ~isa(figNumber,dbl) | ~isa(output,dbl) | ~isa(inctim,dbl)
    error('All inputs arguments must be double precision matrices.')
  end

  figNumber=figNumber(1); output=output(1); inctim=inctim(1);
  if ~ishandle(figNumber); error(figerr); end

% Make all handles on figNumber visible.
  showhid=get(0,ShowHiddenHandles); set(0,ShowHiddenHandles,'on');

  polmenuHndl=findobj(figNumber,Tag,'polmenu');
  figTag=sprintf('RGUIFIG%d',figNumber);

  if isempty(polmenuHndl) | ~strcmp(get(figNumber,Tag),figTag)
    set(0,ShowHiddenHandles,showhid); error(figerr);
  end

% Determine if the identified model contains data for the selected output.
  identmodel=get(polmenuHndl,'UserData');
  if size(identmodel,2)<3 | output>size(identmodel,3)
    set(0,ShowHiddenHandles,showhid); error('Invalid output number.');
  end

% Extract the identified model parameters.
  ctrls=[output inctim]; rguisave(figNumber,6,ctrls);
  if nargout>1
    pol=idmodel.pol; bres=idmodel.bres; res=idmodel.res; thru=idmodel.thru;
    releng=idmodel.releng; afpe=idmodel.afpe; sigmoddat=idmodel.sigmoddat;
  else
    pol=idmodel;
  end
  set(0,ShowHiddenHandles,showhid);
