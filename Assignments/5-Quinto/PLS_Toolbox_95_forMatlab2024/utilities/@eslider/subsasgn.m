function obj = subsasgn(obj,index,val)
%ESLIDER/SUBSASGN Subscript assignment reference for eslider.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

feyld = index(1).subs; %Field name.

if length(index)>1;
  error(['Index error, can''t assign into field: ' feyld '.'])
else
  switch feyld
    case 'position'
      %Reposition then update patch.
      if ~isvalid(obj); return; end
      obj.position = val;
      set(obj.axis,'position',val)
      update_axis(obj);
      obj = update_patch(obj,obj.value);
    case 'value'
      if obj.range<obj.page_size
        val = 1;  %NEVER scroll down if page size is > number of items (range)
      end
      obj = update_patch(obj,val);
      if ~isempty(obj.callbackfcn)
        feval(obj.callbackfcn,'eslider_update',obj)
      end
    case 'range'
      obj.range = val;
      %Need to clear the selection.
      obj.selection = [];
      update_axis(obj);
      %then update the patch
      if obj.value>obj.range
        %If current value is outside, make it = range.
        obj.value = val;
      end
      obj = update_patch(obj,obj.value);
    case 'page_size'
      obj.page_size = val;
      update_axis(obj);
      obj = update_patch(obj,obj.value);
    case 'enable'
      %Not used.
    case 'visible'
      obj.visible = val;
      set(obj.axis,'visible',val);
      set(obj.patch,'visible',val);
    case 'selection'
      %Make sure selection is within range.
      if ~isempty(val) & (max(val)>obj.range | min(val)<1)
        val = unique(min(max(val,1),obj.range));
      end
      obj.selection = val(:)';   %store as ROW vector (always)
      update_axis(obj);
      feval(obj.callbackfcn,'eslider_update',obj)
    otherwise
      
  end
  
end

setappdata(obj.parent,'eslider',obj);



