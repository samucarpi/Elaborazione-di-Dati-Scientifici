function recordevent(msg)
%RECORDEVENT Records events when object rules are violated.
% This function is used to note when old code is not in compliance with the
% new EVRImodel object.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent recorded

return  %HARD CODED TO IGNORE THIS CODE!!

if ~iscell(recorded)
  recorded = {};
end

stack = dbstack;
if length(stack)>3 & ~strcmpi(stack(4,1).name,'datatipinfo')
%   key = encode(stack(3:4));
%   if ~ismember(key,recorded)
%     if exist('C:\Users\Jeremy\Desktop\','file')
%       try
%         fid = fopen('C:\Users\Jeremy\Desktop\modelevent.txt','a');
%         fprintf(fid,'--------------------------------------------\n');
%         fprintf(fid,'%s\n',msg);
%         fprintf(fid,'%s\n',encode(stack(3:end)));
%         fclose(fid);
%       catch
%       end
%     end
%     
%     disp(' ');
%     disp(msg)
%     disp(encode(stack(3:end)))
%     disp(' ');
%     recorded{end+1} = key;
%     
%   end
  if getfield(evrimodel('options'),'fatalalerts')
    error(msg)
  end
end
