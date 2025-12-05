function obj = magnifytool(varargin)
%MAGNIFYTOOL/MAGNIFYTOOL View a zoomed region on a second axis.
% This object creates a second axis next to (right side) a single axis
% magnifying a region selected by the user. It copies all objects from the
% "target" axis to the "display" axis and sets the x/y lims of the display
% axis to magnify (zoom) the display axis. It's very similar to the zoom
% function but uses a second axis.
%
% This object stores the state of all graphics objects used to create the
% magnification. A region is selected using SETPATCH method (opens a rbbox)
% then a patch with light gray alpha and outline is drawn on top of the
% "target" axis. This patch can be dragged around. A callback is assigned
% to the patch which continuously updates the magnified axis limits.
%
% See the following functions for specific actions:
%   SETPATCH    - Opens an rbbox to indicate region to magnify.
%   UPDATEPATCH - Uses info stored in object to create/update patch.
%   UPDATEPLOT  - Uses info stored in object to update magnified plot.
%
%I/O: obj = magnifytool(varargin)
%I/O: obj = magnifytool(figure_handle)%Starts tool.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

switch nargin
  case 0
    obj = getdefaults;
    obj = class(obj,'magnifytool');
  otherwise
    %See if lookup is requried for update or delete.
    if ischar(varargin{1}) && (strcmp(varargin{1},'update') || strcmp(varargin{1},'delete'))
      dax = finddisplayax(varargin{2});
      if isempty(dax)
        %No obj to find, make sure button is off then do nothing.
        bh = findobj(allchild(varargin{2}),'tag','pgtmagnify');
        set(bh,'State','off');
        magnifytooltoggle(varargin{2},1);
        return
      end
      
      thisobj = getappdata(dax,'magnifytool');
      if isempty(thisobj)
        %No object.
        return
      end
      
      switch varargin{1}
        case 'update'
          updatepatch(thisobj);
        case 'delete'
          delete(thisobj);  
      end
      
      return
    end
    
    obj = getdefaults;
    %Passing handles and or value pairs.
    if ~ischar(varargin{1}) && ishandle(varargin{1}) && strcmp(get(varargin{1},'type'),'figure')
      dax = finddisplayax(varargin{1});
      if ~isempty(dax)
        %If object already exists then just update.
        thisobj = getappdata(dax,'magnifytool');
        updatepatch(thisobj);
        return
      end
      
      %Check if more than one plot, spawn if needed.
      ax = findobj(varargin{1},'type','axes','tag','');
      if ~isempty(ax) && length(ax)>1 && strcmpi(getappdata(varargin{1},'figuretype'),'plotgui')
        obj.parent_figure = plotgui('duplicate',varargin{1});
        %Set button off on orginal figure.
        bh = findobj(allchild(varargin{1}),'tag','pgtmagnify');
        set(bh,'State','off');
        magnifytooltoggle(varargin{1},1);
      else
        obj.parent_figure = varargin{1};
      end

      varargin = varargin(2:end);
    end
    property_argin = varargin;
    %Try to assign value pairs.
    while length(property_argin) >= 2,
      prop = property_argin{1};
      val = property_argin{2};
      property_argin = property_argin(3:end);
      if isfield(obj,prop)
        obj.(prop) = val;
      end
    end
    %TODO: Maybe implement "initialize" type function as in drill tool.
    obj = class(obj,'magnifytool');
    obj = setpatch(obj);
end

%-------------------------------
function obj = getdefaults
%Default values.
obj.magnifytoolversion = 1.0;
obj.parent_figure = [];%Figure handle of target axis.
obj.parent_figure_oposition = [];%Original position of parent.

obj.target_axis = [];%Axis handle to be magnified.
%Target limits for checking after plotgui update.
obj.target_xlim = [];
obj.target_ylim = [];

obj.display_axis = [];%Axis handle for zoomed displayed.
obj.display_orientation = 'right';%Orientation of diplay, can also be 'under'.
obj.show_menu = 1;%Show right-click menu for closing magnify tool.
obj.display_delete = 1;%Delete display axis when deleting object.

obj.patch_handle = [];
obj.patch_xdata  = [];%Xdata of patch object.
obj.patch_ydata  = [];%Ydata of patch object.
obj.patch_alpha  = .3;%Alpha of patch.
obj.patch_color  = [.9 .9 .9];%Gray of patch.

obj.position_checking  = 1;%If code should check to see if patch is on screen. Make this numeric so it's fast to check.
obj.moveobj_constraint = 'on';%Type of movement for moveobj {'on' 'x' 'y'}.

obj.show_resize   = 1;%Show resize corner point.
obj.resize_handle = [];%Corner point for resizing pathc.

obj.buttonmotion_fcn = [];%Additional move object callback.

%-------------------------------
function testcode
% close all force
% f = figure;
% ax = axes;
% plot(ax,rand(1,10));
% mobj = magnifytool;
% mobj.target_axis = ax;
% mobj.parent_figure = f;
% mobj.display_orientation = 'bottom';
% mobj = setpatch(mobj);
% %mobj = create_patch(mobj);
% 
% close all force
% load mandrill
% f = figure;
% image(X)
% colormap(map)
% mobj = magnifytool('parent_figure',1);
% 
% close all force
% load smbread
% plotgui(bread)
% mobj = magnifytool(1);
