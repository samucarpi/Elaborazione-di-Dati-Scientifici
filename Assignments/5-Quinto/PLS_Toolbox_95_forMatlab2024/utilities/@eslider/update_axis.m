function obj = update_axis(obj)
%UPDATE_AXIS Update axis with selection.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isvalid(obj); return; end

%adjust axis to match range (in case it changed)
ax = [1 obj.position(3) -(max(2,obj.range))+.5-floor(obj.range*.01) 0.5+floor(obj.range*.01)];
axis(obj.axis,ax)

if obj.display_selection
  %Add lines for selections.
  delete(findobj(obj.axis,'tag','eslider_selection'));
  mypos = obj.position;
  selection = obj.selection;
  clr = [1 0 0];
  x = [2 mypos(3) mypos(3) 2];
  if ~isempty(selection)
    
    group = [];
    if length(selection)>100  %if there are a good number of selections
      %look for selections which are adjacent. We'll do those in one
      %big patch rather than creating individual patches for each (that is
      %too slow for lots of selections)
      adjacent = (diff(selection)==1);
      if any(adjacent)
        %form groups from adjacent selections
        while any(adjacent)
          start = min(find(adjacent));
          stop  = min(find(~adjacent(start:end)))+start-1;
          if isempty(stop)
            stop = length(adjacent);
          end
          group(end+1,1:2) = selection([start stop]);   %note start and stop of range
          adjacent(start:stop) = 0;     %clear adjacent flags (to find next)
          selection(start:stop) = nan;  %flag those for removal
        end
        selection = selection(isfinite(selection));  %keep ungrouped items only
      end
    end

    %patch settings for all patches (groups and individual selections)
    defaults = {'parent',obj.axis,'xdata',x,...
      'facecolor',clr,'edgecolor',clr,'linewidth',2,'tag','eslider_selection',...
      'facealpha',.5,'edgealpha',.5,...
      'uicontextmenu',findobj(obj.parent,'tag','eslider_contextmenu'),...
      'ButtonDownFcn','click(getappdata(gcbf,''eslider''),get(gcbo,''userdata''));'};

    %Create patches for groups (if any existed)
    for i = 1:size(group,1)
      y = group([i i],1:2);
      h = patch(defaults{:},'ydata',-y(:)'+[-.5 -.5 .5 .5]+1,'userdata',round(mean(group(i,1:2))));
      moveobj('link',h,obj.patch);
    end

    %Create patches for individual selections
    for i = 1:length(selection)
      h = patch(defaults{:},'ydata',-selection(i)+[-.5 -.5 .5 .5]+1,'userdata',selection(i));
      moveobj('link',h,obj.patch);
    end
    
  end
end

