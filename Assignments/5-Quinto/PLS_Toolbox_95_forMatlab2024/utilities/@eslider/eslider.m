function obj = eslider(varargin)
%ESLIDER/ESLIDER Create an Eigenvector slider graphical control.
% ESLIDER - creates a modified slider object using an axes and patch. This
% object can be used in conjunction with a listbox when very long lists are
% needed.
%   Properties:
%     parent      : parent figure.
%     position    : slider axis position.
%     range       : total number of items to scale to.
%     page_size   : increment size.
%     color       : axis color.
%     callbackfcn : function that contains callback functions. Input to
%                   these functions is the object.
%            'eslider_update' : called whenever slider position changes
%            'eslider_clear'  : called on "clear all" command
%     value       : Current value of slider.
%     axis        : axis handle for slider.
%     patch       : patch handle for slider.
%     selection   : selection index.
%     display_selection : show selections on slider.
%
%I/O: eslider(h)

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

switch nargin
  case 0
    %create shared data link object
    obj = getdefaults;
    obj = class(obj,'eslider');
    
  otherwise
    obj = getdefaults;
    %Passing handles and or value pairs.
    if ishandle(varargin{1})
      %Set as parent.
      obj.parent = varargin{1};
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
    obj = class(obj,'eslider');
    obj = create_axis(obj);
    setappdata(obj.parent,'eslider',obj)
end

function obj = getdefaults()
%Default values.
obj.esliderversion = 1.0;
obj.parent = get(0,'currentfigure');  %do NOT use gcf (in case no figure exists)
obj.position = [10 10 20 100];
obj.callbackfcn = '';
obj.range = 100;
obj.axis = '';
obj.patch = '';
obj.visible = 'on';
obj.enable = 'on';
obj.value = 1;
obj.page_size = 50;
obj.tag = '';
obj.color = [.4 .4 .6];
obj.selection = [];
obj.display_selection = true;
obj.patch_color = [.9 .9 .9];%grey






