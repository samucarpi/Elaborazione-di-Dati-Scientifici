function hmap = m2javaopts(s)
% convert Matlab struct to a Java HashMap

%Copyright Eigenvector Research, Inc. 2019
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

hmap = java.util.HashMap;

ckeys = fieldnames(s);
for i = 1:size(ckeys,1)
  switch ckeys{i}
    case {'max_depth', 'num_class', 'silent'}
        % add as int
        val = int8(s.(ckeys{i}));
        hmap.put(ckeys{i}, val);
        
      case {'preprocessing', 'definitions', 'cvi'}
          %do not add to hashtable
                            
      otherwise
        % add
        hmap.put(ckeys{i}, s.(ckeys{i}));
  end
end