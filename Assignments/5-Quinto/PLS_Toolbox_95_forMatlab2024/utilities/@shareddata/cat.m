function out = cat(dim,varargin)
%SHAREDDATA/CAT overload

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dim = 1;  %hard-code: never allow concatenation in other modes

%add objects to each other
out = varargin{1};
for j=2:length(varargin)
  if isempty(out);
    out = varargin{j};
  else
   if ~isshareddata(varargin{j}) & isshareddata(out)
     out = double(out);
   elseif isshareddata(varargin{j}) & ~isshareddata(out)
     varargin{j} = double(varargin{j});
   end 
   for k=1:length(varargin{1});
     out = nassign(out,varargin{j}(k),length(out)+1,dim);
   end
  end
end

