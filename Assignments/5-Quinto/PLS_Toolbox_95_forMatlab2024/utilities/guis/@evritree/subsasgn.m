function obj = subsasgn(obj,index,val)
%EVRITREE/SUBSASGN Subscript assignment reference for EVRITREE.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

feyld = index(1).subs; %Field name.

if strcmp(feyld,'data') & length(index)>1;
  %Shortcut to direct assign.
  index = index(2);
end

if length(index)>1;
  error(['Index error, can''t assign into field: ' feyld '.'])
else
  switch feyld
    case 'time_stamp'
      %Don't allow change of timestamp, may use this for ID.
      return
    case 'column_format_silent'
      %Update column format without calling updatetree. Use this in the
      %case of conditional formatting, need a different format for data
      %being updated (silently change format of column/s then update
      %data).
      obj.column_format = val;
    case 'data_silent'
      %Add data to tree using treemodel so renderers don't get reset.
      obj.data = val;
      update_data_silent(obj);
    case 'column_label_silent'
      %Add data to tree using treemodel so renderers don't get reset.
      obj.column_labels = val;
      update_column_label_silent(obj);
    otherwise
      obj.(feyld) = val;
      jt = obj.java_tree;
      switch feyld
        case 'autoresize'
          jt.setAutoResizeMode(jt.(obj.autoresize));
        case 'background'
          setbackground(obj,val)
        case 'column_labels'
          updatecolumns(obj);
        case 'tree_data'
          updatetree(obj);%Recreate root node.
        case 'editree'
          %Not used yet.
        case 'hide_panel'
          error('HIDE_PANEL porperty can only be used when creating tree.')
        case 'tag'
          set(obj.tree_container,'tag',obj.tag);
        case 'tree_fontname'
          setfont(obj,obj.tree_fontname,'','');
        case 'tree_fontsize'
          setfont(obj,'','',obj.tree_fontsize);
        case 'tree_fontstyle'
          setfont(obj,'',obj.tree_fontstyle,'');
        case 'position'
          set(obj.tree_container,'position',obj.position);
        case 'root_visible'
          if strcmp(val,'on')
            jt.setRootVisible(true);
          else
            jt.setRootVisible(false);
          end
        case 'root_handles_show'
          if strcmp(val,'on')
            jt.setShowsRootHandles(true);
          else
            jt.setShowsRootHandles(false);
          end
        case 'selection_type'
          switch val
            case 'contiguous'
              mymode = javax.swing.tree.TreeSelectionModel.CONTIGUOUS_TREE_SELECTION;
            case 'discontiguous'
              mymode = javax.swing.tree.TreeSelectionModel.DISCONTIGUOUS_TREE_SELECTION;
            otherwise
              mymode = javax.swing.tree.TreeSelectionModel.SINGLE_TREE_SELECTION;
          end
          jt.getSelectionModel.setSelectionMode(mymode)
        case 'units'
          set(obj.tree_container,'units',obj.units);
        case 'visible'
          set(obj.tree_container,'visible',obj.visible);
        case {'tree_clicked_callback' 'row_clicked_callback' 'column_clicked_callback' 'selection_changed_callback'}
          %If callbacks being assigned then be sure callbacks are there,
          %they sometimes won't be assigned if tree not rendered
          %visually.
          addcallbacks(obj);
      end
  end
end

if ~isempty(obj.tree)
  %Save to parent figure if possible.
  set_evritree_obj(obj)
end
