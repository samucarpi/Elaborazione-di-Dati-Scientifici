function display(obj)
%EVRIADDON_CONNECTION/DISPLAY Display contents of object.
% Displays evriaddon_connection object product description and connection
% entry points.

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

disp('EVRI Add-On Connection Object');
disp(sprintf('   Name     : %s',obj.name));
disp(sprintf('   Priority : %f',obj.priority));
disp(sprintf('   Entry Points:'))

f = obj.entrypoints;
fpadded = char(f);
for j=1:length(f);
  fns = obj.(f{j});
  for k = 1:length(fns);
    fns{k} = ['@' func2str(fns{k})];
  end
  if isempty(fns); fns = {'---'}; end
  disp([sprintf('       %s :',fpadded(j,:)) sprintf(' %s',fns{1:end})]);
end

disp('   Entrypoint Help: use "obj.help.entrypoint"');
