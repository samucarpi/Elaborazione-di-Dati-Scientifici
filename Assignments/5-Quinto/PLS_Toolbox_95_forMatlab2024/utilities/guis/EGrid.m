classdef EGrid<EControl
  %EGRID - Property grid control based on Jide Property Table.
  % Inputs are options structure.
  % NOTE: Only supports options structures (because we rely on definitions).
  % Can add support for "native" inferred datatypes in the future.
  %
  %I/O: EGrid(panel_handle,'PropertyData',options_structure);
  %
  %See also: @EControl, GRIDLIST, OPTIONSEDITOR
  
  %Copyright Eigenvector Research, Inc. 2013
  %Licensee shall not re-compile, translate or convert "M-files" contained
  % in PLS_Toolbox for use with any software other than MATLAB®, without
  % written permission from Eigenvector Research, Inc.
  
  %Based on Levente Hunyadi's PropertyGrid:
  %   http://www.mathworks.com/matlabcentral/fileexchange/28732-property-grid-using-jide-implementation
  
  properties (Dependent)
    % Virtual fields.
    
    % Matlab uicontrol that holds the java control. In this case it's the
    % uipanel.
    Control;%Needed by EControl.
    % Current prop listed in the property grid, maps to PropertyData.
    Properties;
    % Parent figure.
    ParentFigure
    % Row height
    RowHeight
  end
  
  properties
    %UIPanel that contains the jide pane.
    PanelContainer;
    %Jide PropertyPane, contains property table and adds sorting controls.
    Pane;
    %Actual Jide Property Table.
    Table;
    %Jide property table model.
    Model;
    %Structure or cell that contains current "edited" properties.
    PropertyData = [];%Original property data.
    %Updated (edited) Property Data.
    NewPropertyData = [];
    %Add save button.
    ShowSave = true;
    %Context objects to unregister,nx2 cell array [javatype contextobj].
    ContextObjects
    %Current user level.
    UserLevel = 'advanced';
    %List of property names to disable.
    DisabledProperties = {};
    %List of property names to hide.
    HiddenProperties = {}; % When creating the java controls for properties, these properties are never used.
    %List of visible properties.
    VisibleProperties = {}; % Of the java controls create, show only these.
  end
  
  methods
    function obj = EGrid(varargin)
      %Constructor of generic control. Will call Instantiate.
      obj = obj@EControl(varargin{:});
      if nargin>0 & isscal(varargin{1}) & ishandle(varargin{1})
        parentfig = varargin{1};
        varargin = varargin(2:end);
      end
      set(obj, varargin{:});
    end
    
    function obj = Instantiate(obj, parent)
      %Initialize jide control on a panel.
      if nargin < 2
        parent = figure;
      end
      
      obj.PanelContainer = uipanel(parent, ...
        'Units', 'normalized', ...
        'Position', [0 0 1 1], ...
        'Tag', 'eGrid', ...
        'UserData', obj);
      
      %Initialize JIDE.
      com.mathworks.mwswing.MJUtilities.initJIDE;
      %com.jidesoft.grid.CellEditorManager.registerEditor(javaclass('cellstr',1), com.jidesoft.grid.StringArrayCellEditor);
      %com.jidesoft.grid.CellEditorManager.registerEditor(javaclass('char',1), com.jidesoft.grid.MultilineStringCellEditor, com.jidesoft.grid.MultilineStringCellEditor.CONTEXT);
      
      %com.jidesoft.grid.CellRendererManager.registerEditor(javaclass('char',1), com.jidesoft.grid.FileCellEditor);
      
      %com.jidesoft.grid.CellRendererManager.registerRenderer(javaclass('char',1), com.jidesoft.grid.MultilineStringCellRenderer, com.jidesoft.grid.MultilineStringCellEditor.CONTEXT);
      
      %Create the table and pane.
      obj.Table = handle(evrijavaobjectedt('com.jidesoft.grid.PropertyTable'), 'CallbackProperties');  % property grid (without table model)
      obj.Pane = evrijavaobjectedt('com.jidesoft.grid.PropertyPane', obj.Table);  % property pane (with icons at top and help panel at bottom)
      
      pixelpos = getpixelposition(obj.PanelContainer);
      [control,container] = javacomponent(obj.Pane, [2 2 pixelpos(3)-6 pixelpos(4)-6], obj.PanelContainer); %#ok<ASGLU>
      set(container, 'Units', 'normalized');
      %set(obj.Table, 'KeyPressedCallback', @EGrid.OnKeyPressed);
    end
    
    function delete(obj)
      %Unregister Renderer and Editor objects because they're global
      %objects. This should save a little memory.
      myobjs = obj.ContextObjects;
      for i = 1:size(myobjs,1)
        try
          com.jidesoft.grid.CellEditorManager.unregisterEditor(myobjs{i,1},myobjs{i,2});
          com.jidesoft.grid.CellRendererManager.unregisterRenderer(myobjs{i,1},myobjs{i,2});
        end
      end
      %Try to delete manually so object doesn't get orphaned.
      if ishandle(obj.PanelContainer)
        delete(obj.PanelContainer)
      end
      drawnow
    end
    
    function ctrl = get.Control(obj)
      ctrl = obj.PanelContainer;
    end
    
    function obj = set.ParentFigure(obj,newparent)
      %N0t sure if this is correct way of doing re-parenting but seems to
      %work. May avoid doing this for now however.
      set(obj.PanelContainer,'Parent',newparent);
      pixelpos = getpixelposition(obj.PanelContainer);
      javacomponent(obj.Pane, [0 0 pixelpos(3) pixelpos(4)], obj.PanelContainer);
    end
    
    function ctrl = get.ParentFigure(obj)
      ctrl = ancestor(obj.PanelContainer,'figure');
    end
    
    function obj = set.UserLevel(obj,newlevel)
      %Only updategrid if changing level, can be slow for large lists
      %otherwise.
      if ~strcmp(obj.UserLevel,newlevel)
        obj.UserLevel = newlevel;
        obj = UpdateGrid(obj);%Rebuild grid with new level.
      end
    end
    
    function mylevel = get.UserLevel(obj)
      mylevel = obj.UserLevel;
    end
    
    function obj = set.ShowSave(obj,myval)
      obj.ShowSave = myval;
      obj = UpdateGrid(obj);
    end
    
    function obj = set.DisabledProperties(obj,myval)
      obj.DisabledProperties = myval;
      UpdateDisabled(obj)
    end
    
    function obj = set.HiddenProperties(obj,myval)
      if isempty(obj.HiddenProperties) && isempty(myval)
        return
      else
        obj.HiddenProperties = myval;
      end
    end
    
    function obj = set.PropertyData(obj,mystruct)
      %Setter method for main data structure.
      obj.PropertyData = mystruct;
      obj = CopyPropertyData(obj);
      obj = UpdateGrid(obj);
    end
    
    function obj = set.NewPropertyData(obj,mystruct)
      %Setter method for main data structure.
      obj.NewPropertyData = mystruct;
      %No update of grid, this is updated property data coming from the
      %grid controls.
    end
    
    function self = set.Properties(self, myprops)
      % Set properties structure.
      self.BoundItem = [];
      
      if ~isempty(self.Model)
        set(self.Model, 'PropertyChangeCallback', []);  % clear callback
      end
      
      % create JIDE properties
      toolbar = myprops.HasCategory();
      description = myprops.HasDescription();
      self.Fields = JidePropertyGridField.empty(0,1);
      for k = 1 : numel(myprops)
        self.Fields(k) = JidePropertyGridField(myprops(k));
      end
      
      % create JIDE table model
      list = self.Fields.GetTableModel();
      model = com.jidesoft.grid.PropertyTableModel(list);
      %model = handle(com.jidesoft.grid.PropertyTableModel(list), 'CallbackProperties');
      %model.setMiscCategoryName('Miscellaneous');  % caption for uncategorized properties
      %model.expandAll();
      self.Model = model;
      
      % set JIDE table model to property table
      self.Table.setModel(model);
      %self.Pane.setShowToolBar(toolbar);
      %if toolbar
      %  self.Pane.setOrder(0);
      %else
      %  self.Pane.setOrder(1);
      %end
      %self.Pane.setShowDescription(description);
      
      % wire property change event hook
      %set(model, 'PropertyChangeCallback', @EGrid.OnPropertyChange);
    end
    
    function obj = CopyPropertyData(obj)
      %Make a copy of PropertyData.
      obj.NewPropertyData = obj.PropertyData;
    end
    
    function obj = ResetGrid(obj)
      %Reset grid back to orginal data and rebuild the grid.
      obj.PropertyData = obj.PropertyData;
    end
    
    function obj = AddContextObj(obj,jtype,cntxt)
      %Add context and java class... so we can unregister it on delete.
      obj.ContextObjects = [obj.ContextObjects; {jtype cntxt}];
    end
    
    function obj = HideProperty(obj,propname)
      %Hide a property in grid list.
      
      %Check for it first.
      if ~ismember(propname,fieldnames(obj.PropertyData))
        warning('EVRI:EgridNoProp','Property to hide not found.')
        return
      end
      
      if ~ismember(propname,obj.HiddenProperties)
        obj.HiddenProperties = [obj.HiddenProperties; {propname}];
      end
      obj = UpdateGrid(obj);
    end
    
    function obj = UnHideProperty(obj,propname)
      %UnHide a property in grid list.
      hprops = obj.HiddenProperties;
      hprops = hprops(~ismember(hprops,propname));
      obj.HiddenProperties = hprops;
      obj = UpdateGrid(obj);
    end
    
    function obj = DisableProperty(obj,propname)
      %Disable a property in grid list.
      
      %Check for it first.
      if ~ismember(propname,fieldnames(obj.PropertyData))
        warning('EVRI:EgridNoProp','Property to hide not found.')
        return
      end
      
      if ~ismember(propname,obj.DisabledProperties)
        obj.DisabledProperties = [obj.DisabledProperties; {propname}];
      end
      UpdateDisabled(obj)
      
    end
    
    function obj = set.RowHeight(obj,newheight)
      %Set table row height.
      obj.Table.setRowHeight(newheight)
    end
    
    function ht = get.RowHeight(obj)
      %Get table row height.
      ht = double(obj.Table.getRowHeight);
    end
    
    function obj = EnableProperty(obj,propname)
      %Enable property in grid list.
      dprops = obj.DisabledProperties;
      dprops = dprops(~ismember(dprops,propname));
      obj.DisabledProperties = dprops;
      
    end
    
    function obj = UpdateGrid(obj)
      %Update grid using current PropertyData.
      
      %TODO: Make switch for using different gridlist function. Might use
      %this to make simple (native) grid controls, withough custom panels.
      mylist = gridlist(obj);
      
      if isempty(mylist)
        return
      end
      %Grab model.
      model = handle(com.jidesoft.grid.PropertyTableModel(mylist), 'CallbackProperties');
      model.setMiscCategoryName('Other');
      model.expandAll();
      obj.Model = model;
      
      %Set JIDE table model to property table.
      obj.Table.setModel(model);
      obj.Pane.setShowToolBar(1);
      %if toolbar
      obj.Pane.setOrder(0);
      %else
      %    obj.Pane.setOrder(1);
      %end
      obj.Pane.setShowDescription(1);
      
      % wire property change event hook
      %set(model, 'PropertyChangeCallback', @EGrid.OnPropertyChange);
      
    end
    
    function UpdateDisabled(obj)
      %Update disabled properties.
      dprops = obj.DisabledProperties;
      m = obj.Model;
      if isempty(m)
        return
      end
      allprops = m.getProperties;
      allprops = allprops.toArray;
      
      for i = 1:length(allprops)
        if strcmp(class(allprops(i)),'com.jidesoft.grid.DefaultProperty')
          if ismember(char(allprops(i).getName),dprops)
            allprops(i).setEditable(false)
          else
            allprops(i).setEditable(true)
          end
        end
      end
    end
    
    function SetVisible(obj)
      %Set visible properties.
      
      dprops = obj.VisibleProperties;
      m = obj.Model;
      
      if isempty(m) || isempty(dprops)
        return
      end
      
      m.setFiltersApplied(false);
      allprops = m.getOriginalProperties;
      allprops = allprops.toArray;
      
      for i = 1:length(allprops)
        if strcmp(class(allprops(i)),'com.jidesoft.grid.DefaultProperty')
          if ismember(char(allprops(i).getName),dprops)
            allprops(i).setHidden(false)
          else
            allprops(i).setHidden(true)
          end
        end
      end
      m.setFiltersApplied(true);
      m.expandAll;
    end
    
    function UpdateVisible(obj,visible_val)
      %Make visible props list based on "enable" value.
      
      if nargin<2 || isempty(visible_val)
        %Find "enable" option default in options.
        visible_val = GetEnableDefault(obj);
      end
      
      if isempty(visible_val)
        return
      end
      
      mydefs = obj.NewPropertyData.definitions();
      defsnames = {mydefs.name};
      underscore_location = strfind(defsnames,'_');
      defs2hide = zeros(1,length(defsnames));
      for i = 1:length(underscore_location)
        if isempty(underscore_location{i})
          %Should not hide this def becuase it doesn't have an "_" so
          %it's not related to the enable pool.
          continue
        else
          %If this is an underscore location then see if mydef name is in
          %the name. If not then we hide it.
          if ~any(strfind(defsnames{i},visible_val)==1)
            defs2hide(i) = 1;
          end
        end
      end
      visprops = defsnames(~logical(defs2hide));
      obj.VisibleProperties = visprops;
      obj.SetVisible;
    end
    
    function enable_default_val = GetEnableDefault(obj)
      %Pull default enable value out of options. 
      % There should only be one enable options per structure. 
      
      opts = obj.NewPropertyData;
      enable_default_val = [];
      if ~isempty(opts) && isfield(opts,'definitions')
        mydefs = opts.definitions();
        defsdt = {mydefs.datatype};
        enable_location = find(ismember(defsdt,'enable'));
        if ~isempty(enable_location)
          enable_default_val = opts.(mydefs(enable_location).name);
        end
      end
      
    end
    
  end
  
  methods (Static)
    
    function OnKeyPressed(obj, event)
      %Key press on grid.
      %This function can be used for traditional grids if/when implemented.
      key = char(event.getKeyText(event.getKeyCode()));
      switch key
        case ''
      end
    end
    
    function OnPropertyChange(obj, event)
      % Fired when a property value in a property grid has changed.
      % This function is declared static because object methods cannot be
      % directly used with the @ operator. Even though the anonymous
      % function construct @(obj,evt) self.OnPropertyChange(obj,evt);
      % could be feasible, it leads to a memory leak.
      
      %This function can be used for traditional grids if/when implemented.
    end
  end
  
end
