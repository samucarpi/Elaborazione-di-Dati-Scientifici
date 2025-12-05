function display(obj)
%EVRIADDON/DISPLAY Display EVRIAddOn object products and entry points.
% Displays an evriaddon object products and connection entry points.

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

disp('EVRI Add-On Products:');
p = products(obj);
if isempty(p)
  disp('     None Found');
else
  %convert to "given name" if set
  for j=1:length(p);
    name{1,j} = getfield(feval(['addon_' p{j}],obj),'name');
    if isempty(name{j});
      %no name? use method name
      name{j} = p{j};
    end
  end
  %and display
  names = [name;p];
  disp(sprintf('   %s (%s)\n',names{:}))
end

disp('EVRI Add-On Entry Points:');
p = evriaddon_connection;
p = p.entrypoints;
if isempty(p)
  disp('     None Found');
else
  disp(sprintf('   %s\n',p{:}))
end
