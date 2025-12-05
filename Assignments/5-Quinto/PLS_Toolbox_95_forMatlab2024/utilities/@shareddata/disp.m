function disp(id)
%SHAREDDATA/DISP Overload

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

switch length(id)
  case 0
    disp(sprintf('  ** Empty Shared Data Object **'));
    
  case 1
    %non-array
    item = getshareddata(id,'all');
    if isempty(item)
      disp('  ** Unassigned Shared Data Object **');
    else
      out = {
        sprintf('  ** Shared Data Object **')
        sprintf('       object: (%s)',class(item.object))
        sprintf('        links: %i',length(item.links))
        sprintf('       source: %s',num2str(double(getshareddata(id,'handle'))))
        sprintf('     siblings: %i',size(getshareddata(id,'list'),1)-1)
        sprintf(' ')
        sprintf('    + properties')
        };

      disp(char(out));
      disp(item.properties)
    end

  otherwise
    disp(sprintf('  ** Shared Data Object Array of %i items **',length(id)));

end
