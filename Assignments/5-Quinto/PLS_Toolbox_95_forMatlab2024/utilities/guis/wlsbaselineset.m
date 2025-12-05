function varargout = wlsbaselineset(varargin)
%WLSBASELINESET GUI used to modfiy settings of of WLSBASELINE.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI.
%
%I/O:   p = wlsbaselineset(p)
% (or)  p = wlsbaselineset('default')
%
%See also: PREPROCESS, WLSBASELINE

%Copyright Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 4/12/06

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))

  if nargin==0;
    p = default;
  else
    p = default(varargin{1});
  end
  
  %get appropriate definitions
  defs  = p.userdata.definitions;
  wdefs = ismember({defs.tab},'Whittaker Filter');
  cdefs = ismember({defs.tab},'Common');
  if strcmpi(p.userdata.filter,'whittaker')
    p.userdata.definitions =  p.userdata.definitions((wdefs|cdefs)); %show only Whittaker and Common defs
  else
    p.userdata.definitions(wdefs,:) = [];  %drop Whittaker definitions
  end
  newopts = optionsgui(p.userdata);
  if ~isempty(newopts);
    p.userdata = newopts;
  end
  p.userdata.definitions = defs;
  if strcmpi(p.userdata.filter,'whittaker')
    p.userdata.metabasis = p.userdata.lambda;
  elseif isempty(p.userdata.basis);
    p.userdata.metabasis = p.userdata.order;
  else
    p.userdata.metabasis = p.userdata.basis;
  end
  p = default(p);  %make sure settings are updated
  varargout = {p};
  
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    options.settingsonadd = 1;  %define if settings should be shown on "Add"
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

setopts = wlsbaselineset('options');
         
p = preprocess('validate',p);  %validate what was passed in
  
p.description   = 'Baseline (Automatic)';  %REASSIGNED BELOW based on algorithm!
p.calibrate     = {'[data,out{1},out{2}] = wlsbaseline(data,userdata.metabasis,userdata);'};
p.apply         = {'[data,out{1},out{2}] = wlsbaseline(data,userdata.metabasis,userdata);'};
p.undo          = {'data.data(:,data.include{2}) = data.data(:,data.include{2})+out{1}*out{2};'};
p.out           = {};
p.settingsgui   = 'wlsbaselineset';
p.settingsonadd = setopts.settingsonadd;
p.usesdataset   = 1;
p.caloutputs    = 0;
p.keyword       = '';  %REASSIGNED BELOW based on algorithm!
p.tooltip       = '';  %REASSIGNED BELOW based on algorithm!
p.category      = 'Filtering';

if isempty(p.userdata) | ~isfield(p.userdata,'definitions')
  opts = wlsbaseline('options');
  addopts = {
    'order'   'Basis Filter' 'double' 'int{1:100}' 'novice' 'Order of polynomial to fit to data. Used with filter = "basis".'
    'basis'   'Basis Filter' 'matrix' [] 'novice' 'Basis spectra for background. If empty: use polynomial defined in "order" option. Used with filter = "basis"'
    'lambda'  'Whittaker Filter' 'double' [] 'novice' 'Lambda parameter for Whittaker filter indicating baseline curvature to allow. The smaller the value, the more curved the baseline fit. Larger values fit only broader, less-curved features. ';
    };
  opts.definitions = [makesubops(addopts);feval(opts.definitions)];
  opts.definitions(ismember({opts.definitions.name},{'filter' 'plots'})) = [];  %do NOT show plots as an option
  
  %reorder fields...
  opts.definitions = opts.definitions([4 1:3 5:end]);
  
  opts.filter = 'whittaker';  %DEFAULT is now whittaker from here

  defaults = [];
  defaults.order = 2;
  defaults.basis = [];
  defaults.lambda = 100;
  opts = reconopts(opts,defaults);
  if isempty(opts.basis);
    opts.metabasis = opts.order;  %what we'll actually USE (GUI will make this the same as order if basis is empty, otherwise it will be basis)
  else
    opts.metabasis = opts.basis;
  end
  
  opts.plots = 'none';  %ALWAYS have plots be none
  p.userdata = opts;
end

p = setdescription(p);

% --------------------------------------------------------------------
function p = setdescription(p)
%Add userdata values to description.

if strcmpi(p.userdata.filter,'whittaker')
  p.description = sprintf('Baseline (Automatic Whittaker Filter,asymmetry=%g  lambda=%g)',p.userdata.p,p.userdata.lambda);
  p.keyword     = 'whittaker';
  p.tooltip     = 'Whittaker filter automatic baseline removal.';
else
  p.description = sprintf('Baseline (Automatic Weighted Least Squares, order=%g)',p.userdata.order);
  p.keyword     = 'baseline'; 
  p.tooltip     = 'Weighted Least Squares automatic baseline removal.';
end
