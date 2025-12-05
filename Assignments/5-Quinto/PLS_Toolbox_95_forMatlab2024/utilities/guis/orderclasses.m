function classes = orderclasses(class)
%ORDERCLASSES Arranges classes into color and symbol-friendly order.
% Utility used by editds and plotgui to make sure colors are appropriately
% ordered.

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Put negative classes at end of vector to preserve default formatting for
%initial class assignment (from earlier in code) starting from 0.

if class == fix(class)
  %Class consists of integers only. Use existing loop to preserve
  %legacy behavior/style over multiple datasets. Negative class styles will
  %change if max positive value is increased.

  if min(abs(class))<20
    %lowest value is < 20 - include all classes
    %Append negative values after positive.
    classes = [(0:max(class)) (-1:-1:min(class))];
  else
    %lowest value is > 20, use symbols for 20+
    classes = [0:20 unique(class)];
    evritip('nonuniqueclasses','Non-unique Classes:  Because the classes in this data are of such large value, unique class symbols can not be shown. The class symbols used for a given class in this figure may not be the same as the symbol used for the same class in another figure.',1);
  end

else
  %Class contains noninteger values.
  %Construct a vector of unique classes.
  classes = unique(class);

  posStart = find(classes>=0);
  if isempty(posStart);
    posStart = 1;
  end;
  classes = [classes(posStart(1):end), classes(1:posStart(1)-1)];
end
