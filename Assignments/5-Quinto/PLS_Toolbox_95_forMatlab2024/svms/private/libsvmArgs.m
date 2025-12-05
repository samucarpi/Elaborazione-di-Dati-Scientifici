function [newargs] = libsvmArgs(args)
%LIBSVMARGS	 filter and convert args struct to cell array suitable for libsvm.
% libsvmArgs converts input options structure to a cell array form suitable 
% for input to libsvm, keeping only the args which libsvm accepts.
%
% Input: Struct (e.g., field 't' with value 2)
% Output: Cell array (e.g. contains two cells, together, as '-t' '2'.
%
% The set of allowable libsvm one-character args is:
% v, t, g, c, s, b, p, d, r, n, m, e, h, w, q, x.

%
% %I/O: out = libsvmArgs(options); convert options to cell array form for
% libsvm.
%
%See also:

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

allowableargs = {'v', 't', 'g', 'c', 's', 'b', 'p', 'd', 'r', 'n', 'm', 'e', 'h', 'w', 'q', 'x'};

fnames = fieldnames(args);
cargs = struct2cell(args);
newargs = {};
ismem = find(ismember(fnames,allowableargs));
for i=ismem(:)'
  newargs{end+1} = ['-' fnames{i,1}];
  val = cargs{i,1};
  if ~ischar(val);
    val = num2str(val);
  end
  newargs{end+1} = val;
end
