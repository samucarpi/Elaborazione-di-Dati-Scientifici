classdef EVGraph<EControl
  %EVGraph - Graph control based on MXGraph.
  %
  %
  %I/O: EVGraph(panel_handle,);
  %
  %See also: @EControl, EGrid
  
  %Copyright Eigenvector Research, Inc. 2014
  %Licensee shall not re-compile, translate or convert "M-files" contained
  % in PLS_Toolbox for use with any software other than MATLAB®, without
  % written permission from Eigenvector Research, Inc.
  
  %Github Page (main repository):
  %https://github.com/jgraph/jgraphx
  
  %Javascript doc but has good documentation and list of methods:
  %http://jgraph.github.io/mxgraph/docs/js-api/files/view/mxGraph-js.html
  
  %General overview:
  %http://www.informit.com/articles/article.aspx?p=431106
  
  properties (Dependent)
    % Virtual fields.
    
    % Matlab uicontrol that holds the java control. In this case it's the
    % uipanel.
    Control;%Needed by EControl.
    % Parent figure.
    ParentFigure
    %Graph model.
    GraphModel;
  end
  
  properties
    %UIPanel that contains the jide pane.
    PanelContainer;
    %Java Panel parent of graph.
    PanelGraphParent;
    %Scrollpane of graph.
    GraphComponent;
    GraphComponentHandle;
    %Base java control (JComponent abstract).
    GraphControl;
    GraphControlHandle;
    %Actual graph.
    Graph;
    %Function to call with subfunction key.
    ExternalFunction = '';
    %Object name (string) to call static method with subfunction key (.ExternalFunction must be empty).
    ExternalObject = '';
    %Highlight cell on dragging item over it. Only called if
    %ExternalFunction and ExternalObject are emtpy.
    HighlightOnDrag = 1;
    %Add drag drop callbacks.
    AddDragDrop = 1;
    %Add click callbacks.
    AddClickCallback = 1;
    %Add mouse motion callback (for tooltip).
    AddMouseMove = 0;
    %Use HTML Label Rendering.
    UseHTML = 1;
    %Use tooltips.
    UseToolTips = 1;
    %Lock edges so they can't be draged.
    LockEdges = 1;
    %Cell tooltip, nx2 cell arraay of cellid and tooltip. NOT USED YET
    CellToolTip = [];
    %Current tooltip. This is a hack to show tooltip via jlable rather than
    %overloading the java class.
    CurrentToolTip = '';
  end
  
  properties (Access = private)
    TTBoxHandle = []; %ToolTip box handle. This is a hack for displaying tooltips.
    MouseLastMoveTime = now; %Last time the mouse was moved. Used to manage mouse motion callback frequency.
    MouseMotionDelay = .1; %Seconds delay between callback (frequency based on MouseLastMoveTime);
  end
    
  methods
    function obj = EVGraph(varargin)
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
      import javax.swing.*;
      if nargin < 2
        parent = figure;
      end
      %Make parent Matlab UI Panel.
      obj.PanelContainer = uipanel(parent, ...
        'Units', 'normalized', ...
        'Position', [0 0 1 1], ...
        'Tag', 'eGrid');%, ...
        %'UserData', obj);
      %Make parent java panel.
      %jp = evrijavaobjectedt('javax.swing.JPanel',java.awt.BorderLayout);%Parent java JPanel to graph.
      %obj.PanelGraphParent = jp;
      %Make Graph.
      graph = evrijavaobjectedt('evrimxGraph');
      obj.Graph = graph;
      %Make scroll pane for graph.
      gc = evrijavaobjectedt('com.mxgraph.swing.mxGraphComponent',graph);%Scroll panel for graph.
      obj.GraphComponent = gc;
      gch = handle(gc,'callbackproperties');
      %Get base component.
      obj.GraphComponentHandle = gch;

      
      
%       gcc = evrijavamethodedt('getGraphControl',gc);
%       gcch = handle(gcc,'CallbackProperties');
%       
%       %Add click callbacks to main component. Only way to get click event
%       %that I've found.
%       if obj.AddClickCallback
%         %set(obj.GraphComponentHandle,'MouseClickedCallback',{@EVGraph.MouseClickedCallback obj})
%         set(gcch,'MouseMovedCallback','disp(''dsfgsd'')')
%       else
%         set(obj.GraphComponentHandle,'MouseClickedCallback',[])
%       end
%       
      
      
      
      %Add graph scroll panel to java panel.
      %jp.add(gc);
      pixelpos = getpixelposition(obj.PanelContainer);
      
      [control,container] = javacomponent(gc, [2 2 pixelpos(3)-6 pixelpos(4)-6], obj.PanelContainer);
      set(container, 'Units', 'normalized');
      
      %Add xml style sheet.
      obj = SetDefaultStyles(obj);
      
      UpdateGraph(obj)
    end
    
    function delete(obj)
      %Delete object.
      
      %Remove all cells.
      g = obj.Graph;
      if isempty(g)
        return
      end
      m = obj.GraphModel;
      if ~isempty(m)
        m.clear;
        %g.removeCells(g.getChildCells(g.getDefaultParent, true, true));
        drawnow;pause(.1);
      end
      %Try to delete manually so object doesn't get orphaned.
%       if ishandle(obj.PanelContainer)
%         delete(obj.PanelContainer)
%       end
      drawnow
    end
    
    function ctrl = get.Control(obj)
      ctrl = obj.PanelContainer;
    end
    
    function obj = set.ParentFigure(obj,newparent)
      %Change parent figure.
      set(obj.PanelContainer,'Parent',newparent);
    end
    
    function ctrl = get.ParentFigure(obj)
      ctrl = ancestor(obj.PanelContainer,'figure');
    end
    
    function m = get.GraphModel(obj)
      m = obj.Graph.getModel; 
    end
    
    function obj = set.ExternalFunction(obj,fh)
      obj.ExternalFunction = fh;
    end
    
    function fh = get.ExternalFunction(obj)
      fh = obj.ExternalFunction;
    end
    
    function obj = set.AddDragDrop(obj,val)
      obj.AddDragDrop = val;
      UpdateGraph(obj)
    end
    
    function obj = set.AddClickCallback(obj,val)
      obj.AddClickCallback = val;
      UpdateGraph(obj)
    end
    
    function obj = set.AddMouseMove(obj,val)
      obj.AddMouseMove = val;
      UpdateGraph(obj)
    end
    
    function obj = set.UseHTML(obj,val)
      obj.UseHTML = val;
      UpdateGraph(obj)
    end
    
    function obj = set.UseToolTips(obj,val)
      obj.UseToolTips = val;
      UpdateGraph(obj)
    end
    
    function obj = set.LockEdges(obj,val)
      obj.LockEdges = val;
      UpdateGraph(obj)
    end
    
    function SetGraphPosition(obj,newpos)
      %Set position of graph.
      set(obj.PanelContainer,'Position',newpos);
    end
    
    function mypos = GetGraphPosition(obj)
      %Set position of graph.
      mypos = get(obj.PanelContainer,'Position');
    end
    
    function obj = AddVertex(obj,vstruct)
      %Add Vertext to graph with struct.
      g = obj.Graph;
      
      g.getModel.beginUpdate;

      parent = javaObjectEDT(g.getDefaultParent);%Root cell.
        
      for i = 1:length(vstruct)
        thisstruct = EVGraph.getDefaultVertex(vstruct(i));%Validate structure.
        if ~isempty(thisstruct.Parent)
          thisparent = GetCell(obj,thisstruct.Parent);
        else
          thisparent = parent;
        end
        thisvertex = javaObjectEDT(g.insertVertex(thisparent, thisstruct.Tag, thisstruct.Label, ...
          thisstruct.Position(1), thisstruct.Position(2), thisstruct.Position(3),thisstruct.Position(4),...
          thisstruct.Style));
      end
      g.getModel.endUpdate;
      g.refresh;
    end
    
    function obj = AddEdge(obj,estruct)
      %Add Edge to graph.
      g = obj.Graph;
      m = obj.GraphModel;
      m.beginUpdate;
      parent = javaObjectEDT(g.getDefaultParent);%Root cell.
      for i = 1:length(estruct)
        thisstruct = EVGraph.getDefaultEdge(estruct(i));%Validate edge.
        sourcev = thisstruct.Source;
        if ischar(sourcev)
          %Look up source.
          sourcev = m.getCell(sourcev);
        end
        
        targetv = thisstruct.Target;
        if ischar(targetv)
          %Look up target.
          targetv = m.getCell(targetv);
        end
        
        thisedge = javaObjectEDT(g.insertEdge(parent, thisstruct.Tag, thisstruct.Label, ...
          sourcev, targetv,thisstruct.Style));
      end
      m.endUpdate;
      g.refresh;
    end
    
    function obj = GroupCells(obj,parent,celllist)
      %Add a list of cells to a parent.
      %  parent = string of parent name.
      %  celllist = cell array of string names.
      
      mycells = GetCells(obj);
      parentvertex = GetCell(obj,parent);
      if isempty(parentvertex)
        return
      end
      addcells = [];
      for i = 1:length(celllist);
        thiscell = GetCell(obj,celllist{i});
        if ~isempty(thiscell)
          addcells{end+1} = thiscell;
        end
      end
      
      if isempty(addcells)
        return
      end
      
      addcells_java = javaArray('com.mxgraph.model.mxCell',length(addcells));
      for i = 1:length(addcells)
        addcells_java(i) = addcells{i};
      end

      %Make single item array for parent.
      pp = javaArray('com.mxgraph.model.mxCell',1);
      pp(1) = parentvertex;
      
      %Get Graph, select children to add then add selection.
      g = obj.Graph;
      %Can't seem to manually add cells to a group using:
      %    g.groupCells(parentvertex,5,addcells_java)
      %  so using the selection method.
      g.setSelectionCells(addcells_java);
      g.groupCells(parentvertex)
      g.refresh;
      
    end
    
    function mycells = GetCells(obj)
      %Get a cell array of cells
      persistent storedcells oldhash
      
      mycells = {};
      mc = obj.GraphModel.getCells;
      if ~isempty(oldhash) & ~isempty(storedcells) & oldhash==mc.hashCode
        mycells = storedcells;
        return
      end
      oldhash = mc.hashCode;
      vals = mc.elements;
      keys = mc.keys;
      while vals.hasMoreElements
        mycells{end+1,1} = keys.next;
        mycells{end,2}   = vals.next;
      end
      storedcells = mycells;
    end
    
    function myvertex = GetCell(obj,name)
      %Get a sing cell.
      myvertex = [];
      mycells = GetCells(obj);
      pidx = ismember(mycells(:,1),name);
      pidx = find(pidx);
      if isempty(pidx)
        %warning('EVRI:EVGraphMissingCellName',['Cell: ' name ' cannot be located. Check name of cell.']);
      else
        pidx = pidx(1);%Make sure we take just one value if case there's duplicate.
        myvertex = mycells{pidx,2};
      end
    end
    
    function SetCellPosition(obj,name,cpos)
      %Set cell position.
      mycell = obj.GetCell(name);
      cgeom  = mycell.getGeometry;
      cgeom.setX(cpos(1));
      cgeom.setY(cpos(2));
      cgeom.setWidth(cpos(3));
      cgeom.setHeight(cpos(4));
      mycell.setGeometry(cgeom);
      obj.Graph.refresh
    end
    
    function mypos = GetCellPosition(obj,name)
      mycell = obj.GetCell(name);
      cgeom  = mycell.getGeometry;
      mypos = [cgeom.getX cgeom.getY cgeom.getWidth cgeom.getHeight];
    end
    
    function stylelist = GetStyleList(obj)
      %Get a cell array of cells
      stylelist = {};
      stylesheet = obj.Graph.getStylesheet;
      ss = stylesheet.getStyles;%Hash table.
      vals = ss.elements;
      keys = ss.keys;
      while vals.hasMoreElements
        stylelist{end+1,1} = char(keys.next);
        stylelist{end,2}   = char(vals.next);
      end
    end
    
    function SetStyle(obj,cellnames,newstyle)
      %Set new style on a cell.      
      if ~iscell(cellnames)
        %Make sure list of names is a cell array so we can loop on it.
        cellnames = {cellnames};
      end
      
      for i = 1:length(cellnames)
        thiscell = GetCell(obj,cellnames{i});
        if ~isempty(thiscell)
          obj.GraphModel.setStyle(thiscell,newstyle);
        end
      end
    end
    
    function obj = SetDefaultStyles(obj)
      %Set default styles. Get xml defaults from file then add any
      %additional custom styles.
      
      g = obj.Graph;
      stylesheet = g.getStylesheet;
      
      %Add default styles from xml file.
      doc   = com.mxgraph.util.mxUtils.loadDocument(which('EVRIGraphStyles.xml'));
      codec = com.mxgraph.io.mxCodec;
      codec.decode(doc.getDocumentElement,g.getStylesheet);
      
      %Add custom styles.
      gc = javaObject('com.mxgraph.util.mxConstants');
      
      %Example custom icon based on image.
      style = java.util.Hashtable;
      style.put(gc.STYLE_SHAPE, gc.SHAPE_IMAGE);
      style.put(gc.STYLE_IMAGE, ['file:' which('21px_workspace_browser_icon.png')]);
      style.put(gc.STYLE_VERTICAL_LABEL_POSITION, gc.ALIGN_BOTTOM);
      
      stylesheet.putCellStyle('WorkspaceLambdaImage', style);%Use unique name as first input.   
      
    end
    
    function obj = ChangeLayout(obj,newlayoutkey,parentcell)
      %Change layout engine for graph. 
      % These don't really work well as far as I can tell.
      % http://forum.jgraph.com/questions/4740/applying-a-fastorganic-layout
      g = obj.Graph;
      
      if nargin<2 | isempty(newlayoutkey)
        newlayoutkey = 'fastorganic';
      end
      
      if nargin<3 | isempty(parentcell)
        parentcell = g.getDefaultParent;
      else
        parentcell = obj.GetCell(parentcell);
      end
      
      
      switch lower(newlayoutkey)
        case 'fastorganic'
          mylayout = com.mxgraph.layout.mxFastOrganicLayout(g);
        case 'edgelabel'
          mylayout = com.mxgraph.layout.mxEdgeLabelLayout(g);
        case 'paralleledge'
          mylayout = com.mxgraph.layout.mxParallelEdgeLayout(g);
        case 'organic'
          mylayout = com.mxgraph.layout.mxOrganicLayout(g);
        case 'verticalhierarchical'
          mylayout = com.mxgraph.layout.mxHierarchicalLayout(g);
        case 'horizontalhierarchical'
          mylayout = com.mxgraph.layout.mxHierarchicalLayout(g,javax.swing.JLabel.JLabel.WEST);
        case 'verticaltree'
          mylayout = com.mxgraph.layout.mxCompactTreeLayout(g,false);
        case 'horizontaltree'
          mylayout = com.mxgraph.layout.mxCompactTreeLayout(g, true);
        case 'paralleledges'
          mylayout = com.mxgraph.layout.mxParallelEdgeLayout(g);
        case 'placeedgelabels'
          mylayout = com.mxgraph.layout.mxEdgeLabelLayout(g);
        case 'horizontalstacklayout'
          mylayout = com.mxgraph.layout.mxStackLayout(g);
        case 'verticalstacklayout'
          mylayout = com.mxgraph.layout.mxStackLayout(g,false);
      end
      
      g.setCollapseToPreferredSize(false)
      g.getModel.beginUpdate;
      mylayout.execute(parentcell);
      g.getModel.endUpdate;
      
      g.refresh;
    end
    
    function obj = ClearGraph(obj)
      %Clear all cells from graph.
      obj.GraphModel.clear;
    end
    
    function myvis = GetVisible(obj,cellnames)
      %Get visibility of cells.
      myvis = [];
      if ~iscell(cellnames)
        %Make sure list of names is a cell array so we can loop on it.
        cellnames = {cellnames};
      end
      
      for i = 1:length(cellnames);
        thiscell = GetCell(obj,cellnames{i});
        if ~isempty(thiscell)
          myvis = [myvis thiscell.isVisible];
        end
      end
    end
    
    function SetVisible(obj,cellnames,val)
      %Set visibility of cells.
      if ~iscell(cellnames)
        %Make sure list of names is a cell array so we can loop on it.
        cellnames = {cellnames};
      end
      
      for i = 1:length(cellnames);
        thiscell = GetCell(obj,cellnames{i});
        if ~isempty(thiscell)
          obj.GraphModel.setVisible(thiscell,val);
        end
      end
    end
    
    function mytooltip = SetToolTip(obj,cellnames)%NOT USED YET
      %Get tool tips for given cellids. Input 'cellnames' is nx1 cell
      %array of cellids.
      
      if ~iscell(cellnames)
        %Make sure list of names is a cell array so we can loop on it.
        cellnames = {cellnames};
      end
      mytooltip = {};
      for i = 1:length(cellnames)
        thiscell = GetCell(obj,cellnames{i});
        if ~isempty(thiscell)
          %Look up cell in TT list.
          myidx = ismember(cellnames{i},ttlist(:,1));
          if myidx
            %Get cell tooltip.
            mytooltip{end+1} = ttlist(myidx,2);
          else
            %Note found so empty.
            mytooltip{end+1} = '';
          end
        end
      end
    end
    
    function GetToolTip(obj,cellnames)%NOT USED YET
      %Set tooltip list for cells. Input 'cellnames' is nx2 with first
      %column is cellid and second column is tooltip.
      if ~iscell(cellnames)
        %Make sure list of names is a cell array so we can loop on it.
        cellnames = {cellnames};
      end
      ttlist = obj.CellToolTip;
      for i = 1:length(cellnames)
        thiscell = GetCell(obj,cellnames{i});
        if ~isempty(thiscell)
          %Look up cell in TT list.
          myidx = ismember(cellnames{i},ttlist(:,1));
          if myidx
            %Update current cell tooltip.
            ttlist(myidx,2) = val;
          else
            %Add cell to tooltip
            ttlist(end+1,1) = cellnames{i};
            ttlist(end,2)   = val;
          end
        end
      end
      obj.CellToolTip = ttlist;
    end
    
    function UpdateGraph(obj)
      %Update graph based on property settings.
      g = obj.Graph;
      gcc = evrijavamethodedt('getGraphControl',obj.GraphComponent);
      gcch = handle(gcc,'CallbackProperties');
%       
%       %Add click callbacks to main component. Only way to get click event
%       %that I've found.
%       if obj.AddClickCallback
%         %set(obj.GraphComponentHandle,'MouseClickedCallback',{@EVGraph.MouseClickedCallback obj})
%         set(obj.GraphComponentHandle,'MouseClickedCallback','disp(''dsfgsd'')')
%       else
%         set(obj.GraphComponentHandle,'MouseClickedCallback',[])
%       end
      
      if obj.AddMouseMove
        set(gcch,'MouseMovedCallback',{@EVGraph.MouseMovedCallback,obj})
      else
        set(gcch,'MouseMovedCallback',[])
      end
      
      if obj.AddClickCallback
        set(gcch,'MouseClickedCallback',{@EVGraph.MouseClickedCallback obj})
      else
        set(gcch,'MouseClickedCallback',[])
      end
      
      if obj.AddDragDrop
        %Set workspace tree drag/drop.
        graphdnd = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
        graphdnd = handle(graphdnd,'CallbackProperties');
        set(graphdnd,'DropCallback',{@EVGraph.DropCallback,obj,'drop'});
        %set(graphdnd,'DragEnterCallback',{obj.GraphHandlerFunction,obj,'dragenter'});
        set(graphdnd,'DragOverCallback',{@EVGraph.DragOverCallback,obj,'dragover'});
        %set(graphdnd,'DragExitCallback',{obj.GraphHandlerFunction,obj,'dragexit'});
        evrijavamethodedt('setDropTarget',obj.GraphComponent,graphdnd);
      else
        evrijavamethodedt('setDropTarget',obj.GraphComponent,[]);
      end
      
      if obj.UseHTML
        obj.Graph.setHtmlLabels(true);
      else
        obj.Graph.setHtmlLabels(true);
      end
      
      if obj.UseToolTips
        %This will show the cell value as a tooltip. There is no way to
        %change tooltip without modifying java class.
        obj.GraphComponent.setToolTips(true);
      else
        obj.GraphComponent.setToolTips(false);
      end
      
      if obj.LockEdges
        leset = true;
      else
        leset = false;
      end
      %Lock edges so they can't be dragged.
      obj.Graph.setCellsBendable(leset)
      obj.Graph.setCellsDisconnectable(leset)
      obj.Graph.setAllowDanglingEdges(leset)
      obj.Graph.setCellsMovable(leset);
      obj.Graph.setCellsEditable(leset);
      obj.Graph.setCellsResizable(leset)
      
      obj.Graph.refresh
      
    end
    
  end

  
  methods (Static)
 
    function MouseClickedCallback(jobj, event, varargin)
      %Click on graph.
      mygraph = varargin{1};
      if ~isempty(mygraph.ExternalFunction)
        feval(mygraph.ExternalFunction,'clickCallbackFcn',jobj,event,varargin{:})
      elseif ~isempty(mygraph.ExternalObject)
        feval([mygraph.ExternalObject '.clickCallbackFcn'],jobj,event,varargin{:})
      end
    end
    
    function DropCallback(jobj,event,varargin)
      %Drop on graph.
      mygraph = varargin{1};
      if ~isempty(mygraph.ExternalFunction)
        feval(mygraph.ExternalFunction,'dropCallbackFcn',jobj,event,varargin{:})
      elseif ~isempty(mygraph.ExternalObject)
        feval([mygraph.ExternalObject '.dropCallbackFcn'],jobj,event,varargin{:})
      end
    end
    
    function DragOverCallback(jobj,event,varargin)
      %Drag on graph.
      mygraph = varargin{1};
      if ~isempty(mygraph.ExternalFunction)
        feval(mygraph.ExternalFunction,'dragOverCallbackFcn',jobj,event,varargin{:})
      elseif ~isempty(mygraph.ExternalObject)
        feval([mygraph.ExternalObject '.dragOverCallbackFcn'],jobj,event,varargin{:})
      end
      
      if mygraph.HighlightOnDrag
        %Select and highlight cell when something is dragged over it.
        mycell = mygraph.GraphComponent.getCellAt(event.getLocation.getX,event.getLocation.getY);
        if isempty(mycell)
          return
        end
        %myid = char(mycell.getId);
        if mycell.isVertex
          mygraph.Graph.setSelectionCell(mycell)
        else
          %Dragging over something else.
        end
      end
      
    end
    
    
    function MouseMovedCallback(jobj,event,varargin)
      %Mouse enter
      
      persistent onesecond
      
      if isempty(onesecond)
        %Make 
        onesecond = 1.157407407407407e-05;%datenum([0 0 0 0 0 1]) one second.
      end
      
      mygraph = varargin{1};
      if ~mygraph.isvalid
        %Graph might be in process of being deleted.
        return
      end
      
      if (now - mygraph.MouseLastMoveTime)<onesecond*mygraph.MouseMotionDelay
        %Stop here since we don't want to run the code below at too high of
        %frequency and cause a pileup in execution. Adjust
        %.MouseMotionDelay property to tune this.
        return
      end
      mygraph.MouseLastMoveTime = now;
      
      mygraph = varargin{1};
      if ~isempty(mygraph.ExternalFunction)
        feval(mygraph.ExternalFunction,'mouseMoveCallbackFcn',jobj,event,varargin{:})
      elseif ~isempty(mygraph.ExternalObject)
        feval([mygraph.ExternalObject '.mouseMoveCallbackFcn'],jobj,event,varargin{:})
      end
    end
    
    function OnKeyPressed(jobj, event,varargin)
      %Key press on graph
      mygraph = varargin{1};
      if ~isempty(mygraph.ExternalFunction)
        feval(mygraph.ExternalFunction,'dragOverCallbackFcn',jobj,event,varargin{:})
      end
    end
    
    function dprops = getDefaultEdge(varargin)
      %Get a valid edge structure.
      p = inputParser;
      p.KeepUnmatched = true;
      
      %Get defaults.
      addParamValue(p,'Tag','',@ischar);
      addParamValue(p,'Label','',@ischar);
      addParamValue(p,'Style','')
      addParamValue(p,'Source','')
      addParamValue(p,'Target','')
      addParamValue(p,'Callback','');
      
      parse(p,varargin{:});
      dprops = p.Results;
      %Add unmatched fields if any;
      for i = fieldnames(p.Unmatched)'
        dprops.(i{:}) = p.Unmatched.(i{:});
      end
    end
    
    function dprops = getDefaultVertex(varargin)
      %Get a valid vertex structure.
      p = inputParser;
      p.KeepUnmatched = true;
      
      %Check defaults.
      addParamValue(p,'Position',[10 10 100 100],@isnumeric);
      addParamValue(p,'Tag','',@ischar);
      addParamValue(p,'Label','',@ischar);
      addParamValue(p,'Style','');
      addParamValue(p,'Callback','');
      addParamValue(p,'Parent','');
      
      parse(p,varargin{:});
      dprops = p.Results;
      
      %Add unmatched fields if any;
      for i = fieldnames(p.Unmatched)'
        dprops.(i{:}) = p.Unmatched.(i{:});
      end
    end

    function dprops = showStyles(varargin)
      %Show default styles. There's some kind of error when scrolling
      %horizontally but this shows all current styles. Pass main graph as
      %only argument. Use the following code:
      %
      % f = figure;
      % mygraph = EVGraph(f);
      % mygraph.ClearGraph
      % mygraph.showStyles(mygraph)
      
      mygraph = varargin{1};
      stylelist = GetStyleList(mygraph);
      gridlen = ceil(sqrt(size(stylelist,1)));
      
      myleft = 10;
      mytop = 10;
      mywdth = 200;
      myheight = 100;
      myidx = 1;
      
      for i = 1:gridlen %row
        for j = 1:gridlen %col
          if myidx>size(stylelist,1)
            break
          end
          if j==1
            myleft = 10;
          end
          mygraph.AddVertex(struct('Label',stylelist{myidx,1},'Position',[myleft mytop mywdth myheight],'Style',stylelist{myidx,1}));
          myidx = myidx+1;
          myleft = myleft + mywdth + 20;
        end
        mytop = mytop+myheight+20;
      end
    end
    
    
    function test
      
      f = mygraph.ParentFigure;
      delete(mygraph)
      close(f)
      clear mygraph
      
      f = figure;
      mygraph = EVGraph(f);
      
      mygraph.AddVertex(struct('Tag','xblock','Label','X','Position',[20 30 100 35],'Style','WorkspaceLambdaImage'));
      
      mygraph.AddVertex(struct('Tag','xblock','Label','X','Position',[20 30 100 35],'Style','data_loaded'));
      mygraph.AddVertex(struct('Tag','yblock','Label','Y','Position',[20 80 100 35],'Style','model_loaded'));
      mygraph.AddVertex(struct('Tag','model','Label','Model','Position',[180 55 100 36],'Style','model_clicked'));
      mygraph.AddVertex(struct('Tag','clutter','Label','Clutter','Position',[170 10 80 24],'Style','block_unclicked'));
      mygraph.AddEdge(struct('Tag','X2Model','Label','','Source','xblock','Target','model','Style','evriEdge'));
      mygraph.AddEdge(struct('Tag','Y2Model','Label','','Source','yblock','Target','model','Style','evriEdge'));
      mygraph.AddEdge(struct('Tag','Clutter2Model','Label','','Source','clutter','Target','X2Model','Style',...
        'edgeStyle=elbowEdgeStyle;exitX=0;exitY=.5;exitPerimeter=.5;entryX=.5;entryY=0;strokeWidth=2;endArrow=none;rounded=0'));
      
      v5 = mygraph.AddVertex(struct('Tag','blockParent','Label','Calibration Data','Position',[250 70 200 60],'Style','evriSwimLane'));
      mygraph.AddVertex(struct('Parent','blockParent','Tag','test11','Label','X1','Position',[20 0 100 35],'Style','block_clicked'));
      mygraph.AddVertex(struct('Parent','blockParent','Tag','test12','Label','X2','Position',[20 0 100 35],'Style','block_clicked'));
      mygraph.AddVertex(struct('Parent','blockParent','Tag','test13','Label','X3','Position',[20 0 100 35],'Style','block_clicked'));
      
      htmltxt = ['<html><b>My Vertex</b><hr noshade size=''3''><div align=''left''>Section 1:<br/>Left</div><hr noshade size=''1''>' ...
        '<div align=''center''>Secton 2:<br>Center<br></div><hr noshade size=''1''><div align=''right''>Section 3:<br/>Right</div>'... 
        '<hr noshade size=''1''><table cellspacing=0 cellpadding=2><tr><td><b>Column 1</b></td><td><b>Column 2</b></td></tr><tr><td>'...
        '<i>Key 1</i></td><td>Value 1</td></tr><tr><td><i>Key 2</i></td><td>Value 2</td></tr></table></html>'];
      
      mygraph.AddVertex(struct('Tag','testHTML','Label',htmltxt,'Position',[100 100 100 250],'Style','data_loaded'));  
        
      GroupCells(mygraph,'blockParent',{'xblock' 'yblock'})
      
      mygraph.ChangeLayout('edgelabel');
      
      
      
      %Change geometry of edge elbow via elbow (control point, way point).
      m = mygraph.GraphModel;
      geom = m.getGeometry(m.getCell('X2Model'));

      geom_copy = geom.clone;
      
      
      geom = m.getGeometry(m.getCell('X2Model'));
      geom2 = geom.clone;
      mypts = geom2.getPoints;
      mypts.clear;
      newpoint = com.mxgraph.util.mxPoint(100,100);
      mypts.add(newpoint)
      geom2.setPoints(mypts)
      m.setGeometry(m.getCell('X2Model'),geom2)
      
      newpoint = com.mxgraph.util.mxPoint(100,100);
      
      
    end
    
  end
  
end
