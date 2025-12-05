function next = nextmode()
%NEXTMODE Unspported utility.

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 5/3/04 -added logic to store current mode in AXES in addition to
%figure (allows independent cycling of figures)

m = get(gcf,'userdata');
if strcmpi(m{1}.modeltype,'tucker')
    order = length(m{1}.loads);
    order = order-1;
else
    order = length(m{1}.loads);
end

% Below doesn't work for e.g. tucker(X,[3 3 1])
% order = length(m{1}.loads);
% if length(size(m{1}.loads{end}))>2 % Tucker
%   order = order-1;
% end

current = getappdata(gca,'mode');  %check axes for a current mode
if isempty(current);
  current = m{3};
end
next=current+1;
if next>order,
  next=1;
end
setappdata(gca,'mode',next);
