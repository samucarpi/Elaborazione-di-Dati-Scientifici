function s = isfield(obj, varargin)
%EVRIMODEL/ISFIELD Overload for object.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent virtual

if stricttesting & length(varargin)==1 & strcmpi(varargin{1},'modeltype')
  recordevent('** Call to isfield(___,''modeltype'')')
end

if isempty(virtual)
  virtual = virtualfields(obj);
  virtual = [virtual(:,1)' 't2' 'q' 'tcon' 'qcon' 'ncomp' 'lvs' 'pcs' 'prediction' 'plotloads' 'plotscores' 'ploteigen'];
end

switch lower(varargin{1})
  case virtual
    s = true;
  otherwise
    if ismember(varargin{1},fieldnames(obj));
      s = true;
    else
      s = isfield(obj.content, varargin{:});
    end
end
