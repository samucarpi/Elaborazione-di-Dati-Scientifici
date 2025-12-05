function out = encodexml(obj,varargin)
%EVRIMODEL/ENCODEXML Overload for the EVRIMODEL object.

%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%move outer object wrapping into sub-field "objectproperties" and use
%"content" as top-level (allows backwards compatibility for clients
%using XML content)
content                  = obj.content;
content.objectproperties = rmfield(struct(obj),'content');
content.encodexmlclass   = class(obj);  %give outer tag this class name

if isempty(varargin)
  varargin{1} = inputname(1);
end

if nargout
  out = encodexml(content,varargin{:});
else
  encodexml(content,varargin{:});
  if exist('ans','var')
    out = ans;
  end
end
