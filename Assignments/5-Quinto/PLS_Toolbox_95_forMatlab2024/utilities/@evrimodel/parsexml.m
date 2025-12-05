function obj = parsexml(varargin)
%EVRIMODEL/PARSEXML Overload for parsexml.
%I/O: obj = parsexml(obj,xml)

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

xml = varargin{2};

if ~isfield(xml,'content') & isfield(xml,'objectproperties')
  %if this is a re-arranged XML where "content" is at the top level and
  %"objectproperties" is present (containing the top-level object fields),
  %invert it so we can load/convert it as expected
  temp = xml.objectproperties;
  temp.content = rmfield(xml,'objectproperties');
  xml = temp;
end

obj = evrimodel(xml);

