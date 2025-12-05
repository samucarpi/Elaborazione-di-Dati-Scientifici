function [cx] = arithmetic(x, operation, const, indices, modes, options)
%ARITHMETIC Apply simple arithmetic operations to all or part of dataset.
% Apply an arithmetic operation to the input dataset or array (n-way), or a
% specified subset thereof. The supported operations are:
% 'add', 'subtract', 'multiply', 'divide', 'inverse', 'power', 'root',
% 'modulus', 'round', 'log', 'antilog', 'noop'.
% These are applied element-wise, so 'multiply' is applied as '.*' for 
% example. The operation is applied to x or the specified subset of x.
% Available operations:
% add       +  : Adds const.                        xij = xij+const
% subtract  -  : Subtract const.                    xij = xij-const
% multiply  *  : Multiply by const.                 xij = xij*const
% divide    /  : Divide by const.                   xij = xij/const
% inverse   \  : Invert and multiply by const.      xij = const/xij
% power     ^  : Raise to power of const.           xij = xij^const
% root      ^/ : Take const root.                   xij = xij^(1/const)
% modulus   %  : Modulus after division by const.   xij = mod(xij,const)
% round     r  : Round to nearest 1/const fraction. xij = round(xij*const)/const
% log       l  : Log to base const.                 xij = log(xij)/log(const)
% antilog   a  : Antilog to base const.             xij = const^(xij)
% noop      n  : Identity op. Make no change.       xij = xij
%
% The character(s) after each operation name above indicates the "shortcut"
% character that can be used in place of the full operation name.
%
% INPUTS:
%    x = dataset or array.
% OPTIONAL INPUTS:
%  operation = name (char) of arithmetic operation to apply,
%      const = value (double) used in the operation,
%    indices = a cell of requested indices (e.g. {[1:5] [10:20]} ),
%      modes = modes (integer, or vector) to which indicies should be 
%              applied. See nindex/nassign for indices and modes usage.
% OUTPUTS:
%    cx = modified dataset or array.
%
%I/O: [cx] = arithmetic(x);                                 
%I/O: [cx] = arithmetic(x, op, const);                      
%I/O: [cx] = arithmetic(x, op, const, indices);             
%I/O: [cx] = arithmetic(x, op, const, indices, modes);      
%
%See also: nindex, preprocess

% Copyright © Eigenvector Research, Inc. 1991
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin == 0; x = 'io'; end

if ischar(x);
  switch lower(x)
    case 'default' %create default preprocessing
      cx = defaultprepro;
      return;
    case 'list'
      cx = getallowedops;
      return
    otherwise;
      options = [];
      options.name     = 'options';
      options.isundo   = false;
      
      if nargout==0; evriio(mfilename,x,options); else
        cx = evriio(mfilename,x,options); end
      return
  end
end

if ~isnumeric(x) & ~isdataset(x) & ~islogical(x)
  error('Input x must be a dataset or a numeric');
end

switch nargin
  case 1
    % 1. arithmetic(x)
    operation = 'noop';
    const = [];
    indices = {};
    modes  = [];
    options     = arithmetic('options');
  case 2
    % 2. arithmetic(x, options)
    options = operation;
    if isstruct(options) | isempty(options)
      options   = reconopts(options,mfilename);
    else
      error('Unexpected second argument');
    end
    operation = 'noop';
    const = [];
    indices = {};
    modes  = [];
  case 3
    % 3. arithmetic(x, op, const);   
    operation = checkopconst(operation, const);
    indices = {};
    modes  = [];  
    options     = arithmetic('options');
  case 4
    % 4. arithmetic(x, op, const, options);
    % 4. arithmetic(x, op, const, indices)
    operation = checkopconst(operation, const);
    if isstruct(indices)
      % got options, no indices
      options = indices;
      options   = reconopts(options,mfilename);
      indices = {};
    else
      % got indices, no options
      options     = arithmetic('options');
    end
    modes  = [];
  case 5
    % 5. arithmetic(x, op, const, indices, options);
    % 5. arithmetic(x, op, const, indices, modes)
    operation = checkopconst(operation, const);
    if isstruct(modes)
      % got options, no modes
      options = modes;
      options   = reconopts(options,mfilename);
      modes = [];
    else
      % got modes, no options
      options     = arithmetic('options');
    end
  case 6
    % as is
    operation = checkopconst(operation, const);
    if isstruct(options) | isempty(options)
      options   = reconopts(options,mfilename);
    else
      error('Unexpected sixth argument');
    end
  otherwise
    error('Unexpected number of arguments');
end

if ~iscell(indices)
  indices = {indices};
end

% rules for indices and modes
% 1. if indices is empty, use everything
% 2. if indices has length = 1 and modes is empty or length~=1, set modes = 2
% 3. if indices not empty and modes is empty, set modes = 1:length(indices)
if isempty(indices) | all(cellfun('isempty',indices))
  indices = {};                 % rule 1
  modes  = [];
elseif length(indices)==1
  if isempty(modes) | length(modes)~=1
    modes = 2;                  % rule 2
  end
else
  modes = 1:length(indices);    % rule 3
end

% Check for DataSet object
originaldso = [];
if isdataset(x)
  originaldso = x;
  % Extract data from x for initial calculation.
  % No need to consider includes. Apply to all.
  x = x.data;
end

if ~isempty(indices)
  % Extract the subset of x which the operation will be applied to
  xsub = nindex(x, indices, modes);
else
  xsub = x;
end

% check if this is an undo, change operation if appropriate
if options.isundo
  operation = changeOpForUndo(operation);
end

% Apply the operation
switch operation
  
  case {'add'}
    if isempty(const)
      const = 0;
    end
    xsub = xsub+const;
  
  case {'subtract'}
    if isempty(const)
      const = 0;
    end
    xsub = xsub-const;
  
  case {'multiply'}
    if isempty(const)
      const = 1;
    end
    xsub = xsub.*const;
  
  case {'divide'}
    if isempty(const)
      const = 1;
    end
    if const==0
      error('Cannot divide by zero')
    end
    xsub = xsub./const;
  
  case {'inverse'}
    if isempty(const)
      const = 1;
    end
    xsub = xsub.\const;
  
  case {'power'}
    % % For now we'll allow fractional powers on negatives, but maybe we'll
    % % remove this in the future (throwing an error as per the code below).
    %     isanint = const-round(const) < eps;  % is const close enough to an int
    %     if ~isempty(find(xsub<0)) & ~isanint
    %       error('Cannot take non-integer power of negative value');
    %     end
    if isempty(const)
      const = 1;
    end
    xsub = xsub.^const;
  
  case {'root' }
    if isempty(const)
      const = 1;
    end
    xsub = xsub.^(1/const);
    
  case {'modulus'}
    if isempty(const)
      const = 1;
    end
    xsub = mod(xsub, const);
    
  case {'round'}
    if isempty(const)
      const = 1;
    end
    xsub = round(xsub*const)/const;
    
  case {'log'}  % log base const = (1/log(const))*log
    if isempty(const)
      const = exp(1);  % so natural log
    elseif const<=0
      error('operation log requires const is a positive value')
    end
    xsub = (1/log(const))*log(xsub);
    
  case {'antilog'}  % antilog base const = const.^
    if isempty(const)
      const = exp(1);  % e based exponentiation
    elseif const<=0
      error('operation antilog requires const is a positive value')
    end
    xsub = const.^(xsub);

  case {'noop'}
    % Do nothing

  otherwise
    error('Unknown arithmetic operation: %s', operation);
    
end

if ~isreal(xsub)
  error('Result of arithmetic operation (''%s'') has Imaginary part.', operation)
end

if ~isempty(indices)
  % Insert the modified subset into the original full array
  xt = nassign(x, xsub, indices, modes);
else
  xt = xsub;
end

% update originaldso
if isdataset(originaldso);
  %if we started with a DSO, re-insert back into DSO
  originaldso.data = xt;
  cx = originaldso;
else
  cx = xt;
end

%--------------------------------------------------------------------------
function allowedops = getallowedops(nlist)
%If nlist > 0 then only output is given column (1 = names, 2 = equations, 
% 3 = aliases).

if nargin<1
  nlist = 0;
end

allowedops = {
  'add'      'x = x+c'              '+'
  'subtract' 'x = x-c'              '-'
  'multiply' 'x = x*c'              '*'
  'divide'   'x = x/c'              '/'
  'inverse'  'x = c/x'              '\'
  'power'    'x = x^c'              '^'
  'root'     'x = x^(1/c)'          '^/'
  'modulus'  'x = mod(x,c)'         '%'
  'round'    'x = round(x*c)/c'     'r'
  'log'      'x = log(x)/log(c)'    'l'
  'antilog'  'x = c^(x)'            'a'
  'noop'     'x = x'                'n'
  };
            
if nlist
  allowedops = allowedops(:,nlist);
end

%--------------------------------------------------------------------------
function operation = changeOpForUndo(operation)
% Change operation to the reverse operation if this is "undo" prepro mode
switch operation
  case {'add'}
    operation = 'subtract';
  
  case {'subtract'}
    operation = 'add';
  
  case {'multiply'}
    operation = 'divide';
  
  case {'divide'}
    operation = 'multiply';
  
%   case {'inverse', '\'}
%     operation = 'inverse';  % applying inverse again should undo
  
  case {'power'}
    operation = 'root';
  
  case {'root' }
    operation = 'power';
    
  case {'modulus'}
    error('undo operation not supported for modulus operation');
    
  case {'round'}
    error('undo operation not supported for round operation');
    
  case {'log'}
    operation = 'antilog';
    
  case {'antilog'}
    operation = 'log';
    
  case {'noop'}
    operation = 'noop';
end


%--------------------------------------------------------------------------
function op = checkopconst(op, const)
% check op is one of allowed operations and const is a double with numel=1
if isempty(const) | ~isnumeric(const)
  error('constant must be non-empty double');
end
if ~any(size(const)==1)
  error('constant must be a scalar or vector')
end
% check op is allowed value
if isempty(op)
  error('operation is empty')
end
if ~ismember(op, getallowedops(1))
  alias = ismember(getallowedops(3),op);
  if any(alias)
    list = getallowedops;
    op = list{alias,1};  %substitute operation for alias
  else
    error('operation %s is not a supported operation', op)
  end
end

%--------------------------------------------------------------------------
function pp = defaultprepro
%generate default preprocessing structure for this method

p = preprocess('validate');    %get a blank structure

pp.description = 'Arithmetic Operation';
pp.calibrate = { 'userdata.options.isundo=false;[data] = arithmetic(data,userdata.operation, userdata.constant, userdata.indices, userdata.modes, userdata.options);' };
pp.apply     = { 'userdata.options.isundo=false;[data] = arithmetic(data,userdata.operation, userdata.constant, userdata.indices, userdata.modes, userdata.options);' };
pp.undo      = { 'userdata.options.isundo=true; [data] = arithmetic(data,userdata.operation, userdata.constant, userdata.indices, userdata.modes, userdata.options);' };
pp.out       = {};
pp.settingsgui   = 'arithmeticset';
pp.settingsonadd = 1;
pp.usesdataset   = 1;
pp.caloutputs    = 0;
pp.keyword  = 'arithmetic';
pp.tooltip  = 'Apply arithmetic operation';
pp.category = 'Transformations';
pp.userdata = [];
pp.userdata.operation = 'noop';
pp.userdata.constant  = 0;
pp.userdata.indices   = {};
pp.userdata.modes     = [];
options.name = 'options';
pp.userdata.options   = options;

pp = preprocess('validate',pp);

