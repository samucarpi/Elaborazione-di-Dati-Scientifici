function varargout = grooteditor(varargin)
%GROOTEDITOR - Edit graphics root properties and property sets.
%
%  Using:
%    * Table with complete list of properties is on top.
%    * Use top list box to filter objects in top table.
%    * Second table with current set default properties.
%    * Code makes copy of the grootmanager main structure and modifies it,
%      user must hit OK button to save it back to groot manager.
%    * Use lower list box to change default set. Last Set selected becomes
%      current set when OK button pushed.
%    * Select a property in either table to change the edit fields.
%    * Click Update to add to current set.
%    * Save To saves property to base workspace where it can be edited then
%      loaded back into property. Use this for complex data types.
%
%I/O: grooteditor
%
%See also: GET, GROOT, GROOTMANAGER, SET, FIGURE, AXES, RESET

%Copyright Eigenvector Research, Inc. 2022
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Data types of properties found in 2021b:
%    'categorical'
%    'cell'
%    'char'
%    'double'
%    'function_handle'
%    'logical'
%    'matlab.graphics.Graphics'
%    'matlab.graphics.GraphicsPlaceholder'
%    'matlab.graphics.axis.decorator.GeographicScalebar'
%    'matlab.graphics.axis.decorator.ScalableAxisRuler'
%    'matlab.graphics.illustration.legend.Text'
%    'matlab.graphics.layout.Text'
%    'matlab.graphics.primitive.Text'
%    'matlab.lang.OnOffSwitchState'
%    'table'
%
% Properties with numeric values bigger than 1x4 (e.g., position vector)
% that are converted to numeric descriptions (e.g, 2x4 double) rather than
% directly edit in text box. Need to save to workspace first.
%   'factoryAxesColorOrder'
%   'factoryFigureAlphamap'
%   'factoryFigureColormap'
%   'factoryFigurePointerShapeCData'
%   'factoryGeoaxesColorOrder'
%   'factoryHgtransformMatrix'
%   'factoryImageCData'
%   'factoryPatchVertices'
%   'factoryPolaraxesColorOrder'
%   'factorySurfaceCData'
%   'factorySurfaceXData'
%   'factorySurfaceYData'
%   'factorySurfaceZData'
%   'factoryTextPosition'
%   'factoryUitableBackgroundColor'

if verLessThan('matlab','9.6')
  %Need MATLAB 2019a or newer for grid layout.
  error('MATLAB 9.6 (2019a) or higher is required.')
end

persistent factoryproptable

%Get all saved properties from grootmanager.
allprops   = grootmanager('getparent');

%Gather factory property names, class, and value.
flist = grootmanager('listfactory');%Factory list.

if isempty(factoryproptable)
  %Takes a while to parse all the factory properties into a table so keep
  %it around as a persistent variable.
  factoryproptable = getpropitems(grootmanager('listfactory'));
end

%Get current set.
[currentprops,currentsetname] = grootmanager('getcurrentset');
currentproptable = getpropitems(currentprops);

%Get list of objects.
objectlist = grootmanager('listobjects');
objectlist = ['All';objectlist];
propsets   = [allprops.propertyset.name "Add New..."];

%Build UI.
fig    = uifigure('Name','Graphics Root Editor');
figpos = fig.Position;

%6 rows of controls.
grid1 = uigridlayout(fig,[6 1]);
grid1.RowHeight = {80  '2x'  45  '2x'  45  50};

%Factory object filter.
grid2 = uigridlayout(grid1,[2 2]);
grid2.ColumnWidth = {120,'1x'};
objlabel = uilabel(grid2,'Text','Object Filter:');
objdropdown  = uidropdown(grid2,'Items',objectlist,'ValueChangedFcn',@selectObject,...
  'Tooltip','Select specific object to list in factory property table.');
objsearchlbl = uilabel(grid2,'Text','Object Search:');
objsearchtxt = uieditfield(grid2,'ValueChangedFcn',@searchObjTableCallback,...
  'Tooltip','Highlight PropNames cells with yellow that have matching text.');

%Factory object table.
factorypropuitable = uitable(grid1,'data',factoryproptable,'CellSelectionCallback',{@tableClick,'factory'},...
  'Tooltip','Factory Object Table');

%Default object filter.
grid3 = uigridlayout(grid1,[1 2],'ColumnWidth',{120,'1x'});
setLabel = uilabel(grid3,'Text','Propery Set:');
setdropdown  = uidropdown(grid3,'Items',propsets,'ValueChangedFcn',@selectSet,...
  'Tooltip','Change Property Set','Value',currentsetname);

%Default (current set) table.
currentpropuitable = uitable(grid1,'data',currentproptable,'CellSelectionCallback',{@tableClick,'default'},...
  'Tooltip','Current Perperty Set Table');

%Set new value controls.
editpanel = uipanel(grid1);
grid4 = uigridlayout(editpanel,[1 4],'ColumnWidth',{'1x','1x',80,80,80,80});
propeditname = uieditfield(grid4,'Value','','Editable',false,'BackgroundColor',[.93 .93 .93],...
  'Tooltip','Property to add or edit.');
propeditval  = uieditfield(grid4,'Value','','Tooltip','Property value.');

updateprop  = uibutton(grid4,'Text','Update','Tooltip','Add/Update property in current set.','ButtonPushedFcn',@updateButtonCallback);
removeprop  = uibutton(grid4,'Text','Remove','Tooltip','Remove property from current set.','ButtonPushedFcn',@removeButtonCallback);
saveprop    = uibutton(grid4,'Text','Save To','Tooltip','Save property value to workspace.','ButtonPushedFcn',@saveToButtonCallback);
loadprop    = uibutton(grid4,'Text','Load','Tooltip','Load property value from workspace.','ButtonPushedFcn',@loadButtonCallback);

%Ok and cancel buttons.
grid5 = uigridlayout(grid1,[1 3],'ColumnWidth',{80 80 '1x',80,80});
helpbutton = uibutton(grid5,'Text','Help','Tooltip','Open help for Groot Manager.','ButtonPushedFcn',@helpButtonCallback);
resetbutton = uibutton(grid5,'Text','Reset','Tooltip','Reset all properties to factory setting.','ButtonPushedFcn',@resetButtonCallback);
grid6 = uigridlayout(grid5);%Spacer
okbutton = uibutton(grid5,'Text','OK','ButtonPushedFcn',@okButtonCallback,...
  'Tooltip','Save all changes and use selected Property Set.');
cancelbutton = uibutton(grid5,'Text','Cancel','ButtonPushedFcn',@cancelButtonCallback,...
  'Tooltip','Close without saving.');

%-----------------------------------
  function tableClick(obj,evt,thistbl)
    %Update edit property. Put name in edit area. If value is directly
    %editable then enable edit field othewise disable direct edit.
    if isempty(evt.Indices)
      %Click outside cells.
      return
    end

    propeditname.Value = obj.Data.PropNames{evt.Indices(1)};
    try
      propeditval.Value = obj.Data.PropVal{evt.Indices(1)};
    catch
      propeditval.Value = '';
    end

    %Clear user data in case it was used earlier. The user data field will
    %hold prop values when saving/loading complex data types to/from workspace.
    propeditval.UserData = [];

    %Not entirely sure if 'class' will always work on properties to put
    %into non-fatal try/catch.
    myclass = 'N/A';
    try
      myclass = class(flist.(strrep(propeditname.Value,'default','factory')));
    end

    %Same with factory value.
    factoryval = [];
    try
      factoryval = flist.(strrep(propeditname.Value,'default','factory'));
    end

    %Add any data types here that can be edited.
    if ~ismember(myclass,{'char' 'double' 'logical' 'matlab.lang.OnOffSwitchState' 'N/A'})
      %Dislable direct edit for unsupported data types.
      propeditval.Enable = 'off';
    else
      if ismember(myclass,{'double' 'logical'}) && ~isempty(factoryval) && (size(factoryval,1)>1 || size(factoryval,2)>4)
        propeditval.Enable = 'off';
        %If this is a default (no factory) then store value in userdata.
        if strncmpi(propeditname.Value,'default',7)
          thisSetIndex = matches([allprops.propertyset.name],setdropdown.Value);
          propeditval.UserData = allprops.propertyset(thisSetIndex).properties.(propeditname.Value);
        end
      else
        propeditval.Enable = 'on';
      end
    end
  end

%-----------------------------------
  function searchObjTableCallback(obj,evt)
    %Search for a term. Highlight with yellow if found.
    removeStyle(factorypropuitable);
    mytbl = factorypropuitable.Data;
    myidx = contains(mytbl.PropNames,obj.Value,'IgnoreCase',true);
    rows = find(myidx);
    if isempty(rows) || all(myidx)
      return
    end
    cols = ones(length(rows),1);
    yellowbg = uistyle('BackgroundColor','yellow');
    addStyle(factorypropuitable,yellowbg,'cell',[rows,cols]);
    scroll(factorypropuitable,"row",rows(1));

  end

%-----------------------------------
  function saveToButtonCallback(obj,evt)
    %Save/Load current property to/from workspace. For more complicated
    %data type this might be the only way to easily edit. A varialbe with
    %the exact name needs to be in the base workspace.

    mypropname = propeditname.Value;
    if isempty(mypropname)
      return
    else
      %Try to get value from current set. If not present, get it from factory
      %setting.
      mySetIndex = matches([allprops.propertyset.name],setdropdown.Value);
      if isfield(allprops.propertyset(mySetIndex).properties,mypropname)
        myval = allprops.propertyset(mySetIndex).properties.(mypropname);
      else
        myval = flist.(strrep(mypropname,'default','factory'));
      end
      assignin('base',mypropname,myval);
    end

  end

%-----------------------------------
  function removeButtonCallback(obj,evt)
    %Remove property from current set.

    mypropname = propeditname.Value;
    if isempty(mypropname)
      return
    else
      %Try to get value from current set. If not present, get it from factory
      %setting.
      mySetIndex = matches([allprops.propertyset.name],setdropdown.Value);

      if isfield(allprops.propertyset(mySetIndex).properties,mypropname)
        allprops.propertyset(mySetIndex).properties = rmfield(allprops.propertyset(mySetIndex).properties,mypropname);
        newtbl = getpropitems(allprops.propertyset(mySetIndex).properties);
        currentpropuitable.Data = newtbl;
        %Clear prop fields and unselect table so next time user clicks on
        %table it will work as expected.
        propeditval.Value = '';
        propeditname.Value = '';
        currentpropuitable.Selection = [];
      end
    end

  end

%-----------------------------------
  function loadButtonCallback(obj,evt)
    %Load current property from workspace. For more complicated data type
    %this might be the only way to easily edit. A varialbe with the exact
    %name needs to be in the base workspace.

    mypropname = propeditname.Value;
    wsvars = evalin("base","who");

    if ismember(mypropname,wsvars)
      thispropval = evalin("base",mypropname);
    else
      errordlg(['Can''t find variable with property name: ' mypropname ...
        '  in workspace. Push "Save To" button, edit value, then try loading.'],...
        'Missing Workspace Varialbe','modal');
      return
    end

    myclass = class(flist.(strrep(mypropname,'default','factory')));
    %Make sure class of WS variable is same.
    if ~isnumeric(thispropval) & ~strcmpi(myclass,class(thispropval))
      %Assume any property that isn't numeric will have a problem if it's
      %not the same class. Numeric should work even if different numeric
      %class. User might edit a unit8 and it becomes a double but that
      %shouldn't cause a probelm.
      warndlg(['Variable class (variable type) for property: ' mypropname ...
        '  in workspace does not match. Workspace variable is of type: [' class(thispropval)...
        '] expected type: [' myclass ']. Property value may not work as a default. '...
        'Try saving and editing again without changing data type.'],...
        'Variable Class Warning','modal');
      return
    end

    %Save variable to appdata because we have to change data type sometimes
    %in order to display it in the text box.
    propeditval.Value = getVarValue(thispropval,myclass);

    %Always put value in user data so it can be accessed by the update
    %callback. Some complex data types can't be displayed in text field.
    propeditval.UserData = thispropval;

  end

%-----------------------------------
  function updateButtonCallback(obj,evt)
    %Push new value into default, update table and allprops.

    if isempty(propeditname.Value)
      return
    end
    mypropname = propeditname.Value;
    myclass = class(flist.(strrep(mypropname,'default','factory')));

    %If mypropname is a factory name, get value from factory list.
    %If not and is description (e.g., "2x3 double" and edit box should be disabled)
    %then should be in user data.
    myval = '';
    if strncmpi(mypropname,'factory',7) && ~propeditval.Enable
      if isempty(propeditval.UserData)
        %Factory property name, editting is not enabled and there's no user
        %data. Pull value from factory list.
        myval = flist.(mypropname);
      else
        %User loaded from workspace.
        myval = propeditval.UserData;
      end
    else
      %This is a 'default' property or 'factory' property that is editable.
      if propeditval.Enable
        try
          switch myclass
            case 'char'
              myval = char(propeditval.Value);
            case {'double' 'logical' 'matlab.lang.OnOffSwitchState'}
              if ~isempty(propeditval.UserData)
                myval = propeditval.UserData;
              else
                myval = str2num(propeditval.Value);
              end
            otherwise
              %Weird datatype, should be loaded from workspace and in userdata.
              if ~isempty(propeditval.UserData)
                myval = propeditval.UserData;
              end
          end
        catch
          errordlg(['Can''t find value with property name: ' mypropname ...
            ' Try editing the property value again.'],...
            'Property Value Error','modal')
          return
        end
      else
        myval = propeditval.UserData;
      end
    end

    %Overwrite/add the property to current default then update table.
    thisSetIndex = matches([allprops.propertyset.name],setdropdown.Value);
    mypropname = strrep(mypropname,'factory','default');

    %Add new val to 'allprops' structure.
    allprops.propertyset(thisSetIndex).properties.(mypropname) = myval;

    %Update default table.
    myev.Value = setdropdown.Value;
    selectSet(objdropdown,myev)

  end

%-----------------------------------
  function selectSet(obj,evt)
    %Change to new set and show in table.
    if strcmp(evt.Value,'Add New...')
      answer = inputdlg('New set name:', 'Add New Property Set');
      if ~isempty(answer)&&~isempty(answer{:})
        answer = string(answer{:});
        newSetIndex = matches(lower([allprops.propertyset.name]),lower(answer));
        if any(newSetIndex)
          error(['Duplicate set name (' char(answer) ') found. Create new set name.']);
        end
        allprops.propertyset(end+1).name = answer;
        allprops.propertyset(end).properties = struct();
        %Add new set to dropdown and make current.
        propsets   = [allprops.propertyset.name "Add New..."];
        setdropdown.Items = propsets;
        setdropdown.Value = answer;
      else
        return
      end
    else
      answer = evt.Value;
    end
    newSetIndex = matches([allprops.propertyset.name],answer);
    newtbl = getpropitems(allprops.propertyset(newSetIndex).properties);
    currentpropuitable.Data = newtbl;
    figure(fig);%Inputdlg is java based and pulls focus back to MATLAB, need to set back to main figure

  end

%-----------------------------------
  function selectObject(obj,evt)
    %Update factory table to new object.
    removeStyle(factorypropuitable)
    objsearchtxt.Value = '';
    switch lower(evt.Value)
      case 'all'
        newtbl = factoryproptable;
      otherwise
        newtbl = getpropitems(grootmanager('listobject',evt.Value));
    end
    pause(.05)
    factorypropuitable.Data = newtbl;
  end

%-----------------------------------
  function okButtonCallback(obj,evt)
    %Store main structure and update current defaults.
    grootmanager('setparent',allprops);
    grootmanager('changeset',setdropdown.Value);
    delete(fig)
  end

%-----------------------------------
  function cancelButtonCallback(obj,evt)
    delete(fig);
  end

%-----------------------------------
  function helpButtonCallback(obj,evt)
    evrihelp('grooteditor')
  end

%-----------------------------------
  function resetButtonCallback(obj,evt)
    %Reset defaults to factory.
    mytxt = ['Reset all properties to factory setting? This will not remove '...
      'any saved properties in GROOTMANAGER. Click ''Cancel'' button after Reset '...
      'too keep factory settings.'];
    answer = questdlg(mytxt,'Reset All Properties','Yes','No','Yes');
    if strcmpi(answer,'yes')
      grootmanager('factoryreset')
    end
  end
drawnow

end

%--------------------------------------------------------------------------
function ptable = getpropitems(propStruct)
%Get table obj with property names, classes, and values from property structure.

pnams = fieldnames(propStruct);
pvals = cell(length(pnams),1);
pclss = cell(length(pnams),1);

n = 0;
for i = 1:length(pnams)
  pclss{i} = class(propStruct.(pnams{i}));
  pvals{i} = getVarValue(propStruct.(pnams{i}),pclss{i});
end

ptable = table(pnams, pclss, pvals,'VariableNames',{'PropNames','PropClass','PropVal'});

end

%--------------------------------------------------------------------------
function varval = getVarValue(thisvar,thiscls)
%Get value for a variable based on class and size. Return string
%description if size is more than 1x4 (e.g., position vector) and doesn't
%display well as a sting via num2str.
varval = 'N/A';
try
  switch thiscls
    case 'char'
      varval = thisvar;
    case {'double' 'logical' 'matlab.lang.OnOffSwitchState'}
      if size(thisvar,1)>1 || size(thisvar,2)>4
        varval = getVarSrting(thisvar);%E.g., 2x4 double
      else
        varval = num2str(thisvar);
      end
  end
end

end

%--------------------------------------------------------------------------
function varstr = getVarSrting(thisvar)
%Get variable description as a string to be displayed in edit box or
%possibly table.

szstr = sprintf('%dx',size(thisvar));
szstr(end)=[];
varstr = [szstr ' ' class(thisvar)];

end
