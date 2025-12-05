function cowtest(X,T,seg,slack)

out = cow(X,T,seg,slack,[1 1 1 0 0]);

function varargout = fprintf(varargin)

if nargout>0;
  [varargout{1:nargout}] = deal([]);
end