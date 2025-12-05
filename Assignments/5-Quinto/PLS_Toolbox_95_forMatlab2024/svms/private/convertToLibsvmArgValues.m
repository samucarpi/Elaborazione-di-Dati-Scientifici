function s = convertToLibsvmArgValues(s)
%CONVERTTOLIBSVMARGNAMES convert specific arg values to libsvm expectedform. 
% Example, the 's' arg value '0' means use C-classification, which
% might be called using 'C-SVC'.
% Should not be called before calling convertToLibsvmArgNames
%
% %I/O: out = convertToLibsvmArgValues(in); Convert argumnent values

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

ckeys = char(fieldnames(s));
for i = 1:size(ckeys,1)
  ckey = lower(deblank(ckeys(i,:)));
  switch ckey
    case {'s'}
      val = s.(ckey);
      if ischar(val)
        switch lower(val)
          case {'c-svc' '0'}
            s.(ckey) = 0;
          case {'nu-svc' '1'}
            s.(ckey) = 1;
          case {'one-class svm' '2'}
            s.(ckey) = 2;
          case {'epsilon-svr' '3'}
            s.(ckey) = 3;
          case {'nu-svr' '4'}
            s.(ckey) = 4;
        end
      end
      
    case {'t'}
      val = s.(ckey);
      if ischar(val)
        switch lower(val)
          case {'linear', '0'}
            s.(ckey) = 0;
          case {'polynomial', '1'}
            s.(ckey) = 1;
          case {'radial basis function', 'rbf', '2'}
            s.(ckey) = 2;
          case {'sigmoid', '3'}
            s.(ckey) = 3;
        end
      end
      
%     case {'q'}
%       %if q is there, but is = 0, REMOVE it altogether
%       if (ischar(s.q) & ismember(lower(s.q),{'0'})) | (isnumeric(s.q) & s.q==0)
%         s = rmfield(s,'q');
%       else
%         s.q = 1;
%       end
      
    otherwise
%       val = s.(ckey);
%       if length(val)==1 && isnumeric(val)
%         s.(ckey) = num2str(val);
%       end
  end
end
