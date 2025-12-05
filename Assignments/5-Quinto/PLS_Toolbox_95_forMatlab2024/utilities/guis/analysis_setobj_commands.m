function analysis_setobj_commands(fig,action,item,obj,myid)
%ANALYSIS_SETOBJ_COMMANDS - Clearinghouse for setobj commands in analysis.
% This code is called before and after an object is "set" in analysis.
% Shareddata commands will be called between pre and post commands. 
%  INPUTS:
%    fig - analysis figure handle.
%    action - ['pre' | 'post'] key workd for when call is coming from.
%    item   - Type of item being set, 'model', 'xblock', 'yblockval' ...
%    obj    - Dataset or model being set.
%    myid   - Shareddata ID if available. May be empty on "pre" setobj. 
%
%I/O:   analysis_setobj_commands(fig,action,item,obj,myid)
%
%See also: EVRIADDON, PLOTGUIWINDOWBUTTONDOWN, PLOTGUIWINDOWBUTTONMOTION

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

switch action
  case 'pre'
    switch item
      case 'model'
        disp('Pre set obj model')
    end
    
  case 'post'
    switch item
      case 'model'
        multiblocktool('update_from_analysis',fig,action,item,obj,myid)
    end
end
