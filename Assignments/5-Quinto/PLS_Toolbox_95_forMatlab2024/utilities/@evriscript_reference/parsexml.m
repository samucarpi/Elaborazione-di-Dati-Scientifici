function obj = parsexml(varargin)
%EVRISCRIPT_REFERENCE/PARSEXML Overload for parsexml.
%I/O: obj = parsexml(obj,xml)

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

obj = varargin{1};
xml = varargin{2};
if str2double(obj.([class(obj) 'version']))~=str2double(xml.([class(obj) 'version']))
  error('Cannot import XML from a different version of this object.');
end
for f=fieldnames(xml)'; 
  %blindly copy fields from structure to the object (probably a bad idea,
  %but will work until we start making changes to these objects)
  if isfield(struct(obj),f{:})
    obj.(f{:}) = xml.(f{:});
  end
end
