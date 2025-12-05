function str = encode(item,varargin)
%EVRIMODEL/ENCODE Overload for EVRIMODEL object

%Copyright (c) Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<4
  %initial call, wrap for call to general encode
  
  %find options (or create if none passed)
  optsind = 0;
  for j=1:nargin-1
    if isstruct(varargin{j})
      optsind = j;
      break;
    end
  end
  if optsind==0
    varargin{end+1} = [];
    optsind = length(varargin);
  end
  %set wrappedobject item
  varargin{optsind}.wrappedobject = 'on';
  
  if optsind==1
    %no name passed? add one
    varargin{2} = varargin{1};
    varargin{1} = inputname(1);
  end
  if isempty(varargin{1})
    varargin{1} = 'ans';
  end

  %call encode with object wrapped
  str = encode({item},varargin{:});
  return
end

%got what we need...
varname = varargin{1};
varindex = varargin{2};
options = varargin{3};

if ~isempty(varname);
  varname = [varname ' = '];
end

%convert model to struct
temp = struct(item);
temp = rmfield(temp,{'calibrate','downgradeinfo','parent'});

%create encoding for model
myvar = ['ECTemp' num2str(varindex)];
str = '';
if strcmpi(options.includeclear,'on');
  str = [str 'clear ' myvar ';\n'];
end
str = [str encode(temp,myvar,varindex,options)];
str = [str ';\n'];
str = [str varname ' evrimodel( ' myvar ' );\n'];
str = [str 'clear ' myvar];
