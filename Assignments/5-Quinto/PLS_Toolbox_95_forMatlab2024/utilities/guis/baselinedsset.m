function [varargout] = baselinedsset(varargin)
%BASELINEDSSET GUI used to modfiy settings of of BASELINEDS.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI.
%
%I/O:   p = baselinedsset(p)
% (or)  p = baselinedsset('default')
%
%See also: BASELINEDS, PREPROCESS, WLSBASELINE

%Copyright Eigenvector Research 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%TODO: Add uiwait so you can't get error when close PP main window with
%baseline window still open.


if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))

  if nargin==0;
    p = default;
  else
    p = default(varargin{1});
  end
  
  newopts = optionsgui(p.userdata);
  if ~isempty(newopts);
    p.userdata = newopts;
  end
  p = default(p);  %make sure settings (desciption) are updated
  varargout = {p};
  
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return; 
  end
  
	try
    if nargout == 0;
      feval(varargin{:});
    else
      [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    end
	catch
		disp(lasterr);
	end

end

if nargout == 0
  varargout = {};
elseif nargout ==1 & exist('newopts', 'var') & isempty(newopts)
 [varargout{1:nargout}] = {};
end

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end

         
p = preprocess('validate',p);  %validate what was passed in
  
p.description   = ['Baseline Removal'];
p.calibrate     = {'[data,out{1}] = baselineds(data,userdata);'};
p.apply         = {'[data,out{1}] = baselineds(data,userdata);'};
p.undo          = {'[data] = baselineds(data,out{1})'};
p.out           = {};
p.settingsgui   = 'baselinedsset';
p.settingsonadd = 1;
p.usesdataset   = 1;
p.caloutputs    = 0;
p.keyword       = 'baselineds';
p.tooltip       = 'Baseline removal.';
p.category      = 'Filtering';


if isempty(p.userdata) | ~isfield(p.userdata,'definitions')
  p.userdata = baselineds('options');
end

p = setdescription(p);
%p.description   = ['Baseline (' upper(p.userdata.algorithm) ')'];

% --------------------------------------------------------------------
function p = setdescription(p)
%Add userdata values to description.

switch p.userdata.algorithm
  case 'whittaker'
    p.description = sprintf('Baseline (Automatic Whittaker Filter,asymmetry=%g  lambda=%g)',p.userdata.whittaker_options.p,p.userdata.whittaker_options.lambda);
  case 'wlsbaseline'
    p.description = sprintf('Baseline (Automatic Weighted Least Squares, order=%g)',p.userdata.order);
  case 'baseline'
    %p.description = sprintf('Baseline (Specified points)');
    p.description = sprintf('Baseline (Specified points, order=%g points=%g regions=%g)',p.userdata.order,sum(p.userdata.baseline_range),sum(diff([0 p.userdata.baseline_range])==1));
  case 'datafit'
    p.description = sprintf('Baseline (Datafit, order=%g, lambdas=%g)',p.userdata.order,p.userdata.datafit_options.lambdas);
end

