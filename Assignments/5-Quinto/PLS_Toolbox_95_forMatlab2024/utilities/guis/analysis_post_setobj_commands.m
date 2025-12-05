function analysis_post_setobj_commands(fig,item,obj,myid)
%ANALYSIS_SETOBJ_COMMANDS - Clearinghouse for post setobj commands in analysis.
% This code is called after an object is "set" in analysis.
% Shareddata commands will be called between pre and post commands. 
%  INPUTS:
%    fig - analysis figure handle.
%    item   - Type of item being set, 'model', 'xblock', 'yblockval' ...
%    obj    - Dataset or model being set.
%    myid   - Shareddata ID if available. May be empty on "pre" setobj. 
%
%I/O:   analysis_post_setobj_commands(fig,item,obj,myid)
%
%See also: EVRIADDON, PLOTGUIWINDOWBUTTONDOWN, PLOTGUIWINDOWBUTTONMOTION

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

switch item
  case 'model'
    multiblocktool('update_from_analysis',fig,'post',item,obj,myid)
end
