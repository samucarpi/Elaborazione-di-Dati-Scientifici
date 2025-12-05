function addcallbacks(obj,removeflag)
%EVRITREE/ADDCALLBACKS Add callbacks.
% If removeflag = 1 then set all callbacks to [].

% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%NOTE: Add 'MouseReleasedCallback' for drag/drop if needed.

%Get Java table.
jt = obj.java_tree;
jth = obj.tree;
jt_handle = handle(jt,'callbackproperties');

%NOTE: Wrap all of these in try/catch because sometimes they will error out
%if tree is not rendered/visible. 
drawnow

if nargin>1 & removeflag
  %Some people of fileexchange remove Callbacks during delete process to
  %help with possible memory leaks. Yair does not mention it so I can't be
  %sure if it really helps but doesn't hurt.
  try
    set(jth,'NodeSelectedCallback',[]);
    set(jt_handle,'MouseClickedCallback',[]);
    set(jt_handle,'MousePressedCallback',[]);
  end
else
  try
    set(jth,'NodeSelectedCallback',{@node_selected_callback,obj.parent_figure,obj.tag})
  end
  
  try
    %Function handle from object will be called.
    set(jt_handle,'MouseClickedCallback',{@mouse_clicked_callback,obj.parent_figure,obj.tag,'tree'})
    set(jt_handle,'MousePressedCallback',{@mouse_pressed_callback,obj.parent_figure,obj.tag,'tree'})
  end
end
try
%   if ~isempty(obj.selection_changed_callback) & ~isempty(jt.getSelectionModel)
%     %Add selectyion changed callback.
%     selectmod_row = evrijavaobjectedt(jt.getSelectionModel);
%     selectmodh_row = handle(selectmod_row,'CallbackProperties');
%     set(selectmodh_row,'ValueChangedCallback',{@selection_changed_callback,obj.parent_figure,obj.tag,'row'});
%     
%     selectmod_col = evrijavaobjectedt(jt.getColumnModel.getSelectionModel);
%     selectmodh_col = handle(selectmod_col,'CallbackProperties');
%     set(selectmodh_col,'ValueChangedCallback',{@selection_changed_callback,obj.parent_figure,obj.tag,'column'});
%   end
end

