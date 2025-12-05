function [ output_args ] = click(obj,jump)
%CLICK Change value and move patch.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Get current point, compare to obj.value, add/remove page to obj.value
%depending on if above or below.

if obj.range<obj.page_size
  subsasgn(obj,struct('subs','value'),1);
  return;
end

curpoint = round(get(obj.axis,'currentpoint'));
curpoint = -curpoint(1,2);

seltype = get(obj.parent,'selectiontype');
if nargin<2
  switch seltype
    case 'alt'
      return
    case 'extend'
      jump = curpoint;
    otherwise
      jump = 0;
  end
end

if jump
  %jump to location
  newval = max(1,jump-obj.page_size/2);
else
  %move down by one page
  if curpoint<obj.value
    newval = obj.value-obj.page_size;
  else
    newval = obj.value+obj.page_size;
  end
end

%Set the value, subsasgn will update everything.
subsasgn(obj,struct('subs','value'),newval);
