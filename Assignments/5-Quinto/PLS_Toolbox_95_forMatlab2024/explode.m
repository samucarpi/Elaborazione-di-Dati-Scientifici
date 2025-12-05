function varargout = explode(varargin)
%EXPLODE Extracts variables from a structure array to the workspace.
%  Writes the fields of the structure input (sdat) to variables
%  in the workspace with the same variable names as field names.
%
%  Optional string input (txt) appends a string (txt) to the variable names.
%  Optional input (options) is a structure with the following fields: 
%      model: [ 'no' | {'yes'} ] interpret (sdat) as a model if possible.
%    display: [ 'off' | {'on'} ] display model information.
%
%Example: explode(modl,'x01')
%
%I/O: explode(struct,txt,options)  %extracts structure fields and appends txt
%
%See also: ANALYSIS, MODELSTRUCT, MODLPRED, MPCA, NPLS, PARAFAC, PCA

%OLD I/O: explode(sdat,mod,txt,out)

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%NBG 10/97,1/98
%JMS 5/02 -renamed explode from xpldst
%  -updated for new model format
%  -updated io
%jms 8/02 -modified help

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1});
  options = [];
  options.name    = 'options';
  options.display = 'on';
  options.model   = 'yes';
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

switch nargin
case 1
  sdat    = varargin{1};
  txt     = [];
  options = explode('options');
case 2
  if isa(varargin{2},'struct')
    sdat    = varargin{1};
    txt     = [];
    options = varargin{2};
  elseif isa(varargin{2},'char')
    sdat    = varargin{1};
    txt     = varargin{2};
    options = explode('options');
  else
    error(['Unrecognized input to ' mfilename ])
  end
case 3
  if isa(varargin{2},'char') & isa(varargin{3},'struct')
    sdat    = varargin{1};
    txt     = varargin{2};
    options = varargin{3};
  else
    error(['Unrecognized input to ' mfilename ])
  end
otherwise
  error(['Unrecognized input to ' mfilename ])
end
if ~ismodel(sdat) & ~isstruct(sdat)
  error(['Input (sdat) is not a model or a structure'])
end
try
  options = reconopts(options,'explode');
catch
  error('Unrecognized options structure')
end

if strcmp(options.model,'yes');
  if ~ismodel(sdat)
    try 
      sdat = updatemod(sdat);          %try updating to ver3 model. Will give error if not a model
    catch
      options.model = 'no';
      disp('Input (sdat) is not a recognized model. Exploding as regular structure');
    end
  end
end

if strcmp(options.model,'no') | ~ismodel(sdat)
  if ismodel(sdat) & isfield(sdat,'content')
    sdat = sdat.content;
  end
  fields = fieldnames(sdat);
  for ii = fields';
    assignin('caller',[ii{:},txt],getfield(sdat,ii{:}))
  end
else
  assignin('caller',['loads',txt],sdat.loads)
  assignin('caller',['ssq',txt],sdat.detail.ssq)
  assignin('caller',['ssqresiduals',txt],sdat.ssqresiduals)
  assignin('caller',['reslm',txt],sdat.detail.reslim)
  assignin('caller',['tsqlm',txt],sdat.detail.tsqlim)
  assignin('caller',['tsqs',txt],sdat.tsqs)
  if strcmp(lower(sdat.modeltype),'pls')
    assignin('caller',['wts',txt],sdat.wts)
  end
  if strcmp(options.display,'on')
    disp(' ')
    modlrder(sdat)
  end   
end
