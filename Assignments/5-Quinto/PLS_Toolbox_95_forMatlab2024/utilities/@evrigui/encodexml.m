function out = encodexml(obj,varargin)
%EVRIGUI/ENCODEXML Overload for the EVRIGUI object.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

enc = struct('type',obj.type,'handle',obj.handle,'interface',obj.interface,'encodexmlclass',class(obj));

if nargout==0
  encodexml(enc,varargin{:});
else
  out = encodexml(enc,varargin{:});
end
