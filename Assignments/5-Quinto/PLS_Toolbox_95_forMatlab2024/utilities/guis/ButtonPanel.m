classdef ButtonPanel<EControl
  %BUTTONPANEL - Equation Panel of jbuttons.
  %
  %  Button list is cell array with following columns:
  %    Tag          - Tag name for button.
  %    Text         - Text to show on button.
  %    Image        - Image for button if no text.
  %    Width        - Width of button (pixels).
  %    Height       - Height of button (pixels).
  %    type         - [{'button'} 'label'] Type of control to use.
  %    Callback     - Name of function to call with click callback.
  %                   Function will be called as 'ButtonPanelCallback' sub
  %                   function obj and button index as input.
  %                   Example:
  %                   myfcn('ButtonPanelCallback', tag, button_handle, java_obj, ButtonPanel_Object)
  %
  %    Example:      name         text  image W  H  Type      Callback
  %      mylist = { 'button_x'    'X'   ''    20 20 button    'myfcn';
  %                 'button_eq'   '='   ''    20 20 label     'myfcn';
  %                 'button_a'    'A'   ''    20 20 button    'myfcn';
  %                 'button_plus' '+'   ''    20 20 label     'myfcn';
  %                 'button_b'    'B'   ''    20 20 button    'myfcn';}
  %
  %I/O: ButtonPanel(panel_handle,'ButtonList',mylist);
  %
  %See also: @EControl, GRIDLIST, OPTIONSEDITOR
  
  %Copyright Eigenvector Research, Inc. 2014
  %Licensee shall not re-compile, translate or convert "M-files" contained
  % in PLS_Toolbox for use with any software other than MATLAB®, without
  % written permission from Eigenvector Research, Inc.
  
  
  %TODO: Add per control font size.
  
  properties (Dependent)
    % Virtual fields.
    
    % Matlab uicontrol that holds the java control. In this case it's the
    % uipanel.
    Control;%Needed by EControl.
    % Current buttons listed in panel.
    Buttons;
    % Parent figure.
    ParentFigure
    
  end
  
  properties
    %UIPanel that contains the java pane.
    PanelContainer;
    
    %Local button parent panel.
    LocalButtonPanel
    
    %Scroll pane for buttons.
    ButtonPanelScrollPane
    ButtonPanelScrollPaneHandle
    
    %Button list.
    ButtonList = [];
    
    %Handles to java buttons.
    ButtonHandleList = [];
    
    %Font size for buttons.
    FontSize = getdefaultfontsize;
  end
  
  methods
    function obj = ButtonPanel(varargin)
      %Constructor of generic control. Will call Instantiate.
      obj = obj@EControl(varargin{:});
      if nargin>0 & isscal(varargin{1}) & ishandle(varargin{1})
        parentfig = varargin{1};
        varargin = varargin(2:end);
      end
      if ~isempty(varargin)
        set(obj, varargin{:});
      end
    end
    function obj = Instantiate(obj, parent)
      %Initialize jide control on a panel.
      if nargin < 2
        parent = figure;
        set(parent,'DeleteFcn',{@ButtonPanel.deletefcn,obj})
      end
      
      %Parent Matlab UI Panel.
      obj.PanelContainer = uipanel(parent, ...
        'Units', 'pixels', ...
        'Position', [1 1 7 7], ...
        'Tag', 'buttonPanel');
      
      %Base java panel for java buttons.
      bp = javaObjectEDT('javax.swing.JPanel');
      bp.setLayout(javax.swing.BoxLayout(bp,javax.swing.BoxLayout.X_AXIS))
      pixelpos = getpixelposition(obj.PanelContainer);
      %Make scroll pane (window) for base java panel.
      [sp, sph] = javacomponent('javax.swing.JScrollPane', [2 2 pixelpos(3)-6 pixelpos(4)-6], obj.PanelContainer);
      set(sph, 'Units', 'normalized');
      obj.ButtonPanelScrollPane = sp;
      obj.ButtonPanelScrollPaneHandle = sph;
      %Make it the view port of base panel.
      sp.setViewportView(bp)
      %Save to object.
      obj.LocalButtonPanel = bp;
    end
    
    function delete(obj,varargin)
      %Do a manual delete of the objects. Seems to be helpful in preventing
      %memory leak issues.
      obj = RemoveButtons(obj);
      %Try to delete manually so object doesn't get orphaned.
      if ishandle(obj.PanelContainer)
        delete(obj.PanelContainer)
      end
    end
    
    function ctrl = get.Control(obj)
      ctrl = obj.PanelContainer;
    end
    
    function obj = set.ParentFigure(obj,newparent)
      %NOt sure if this is correct way of doing re-parenting but seems to
      %work. May avoid doing this for now however.
      set(obj.PanelContainer,'Parent',newparent);
      pixelpos = getpixelposition(obj.PanelContainer);
      javacomponent(obj.Pane, [0 0 pixelpos(3) pixelpos(4)], obj.PanelContainer);
    end
    
    function ctrl = get.ParentFigure(obj)
      ctrl = ancestor(obj.PanelContainer,'figure');
    end
    
    function obj = set.ButtonList(obj,myval)
      obj.ButtonList = myval;
      obj = MakeButtons(obj);
    end
    
    function obj = MakeButtons(obj)
      %Make buttons if there's a list.
      mylist = obj.ButtonList;
      
      %Clear old buttons.
      obj = RemoveButtons(obj);
      if ~isempty(mylist)
        bp = obj.LocalButtonPanel;
        for i = 1:size(mylist,1)
          if strcmp(mylist{i,6},'label')
            ctrl = evrijavaobjectedt('javax.swing.JLabel',mylist{i,2},javax.swing.SwingConstants.CENTER);
          else
            %See commented code at end of this function for attempts to
            %customize buttons that did not work in case there's motivation
            %to try again.
            ctrl = evrijavaobjectedt('javax.swing.JButton',mylist{i,2});
            ctrl.setToolTipText(mylist{i,2})
            ctrl.setMargin(java.awt.Insets(2, 2, 2, 2));
          end
          
          %Set image.
          if ~isempty(mylist{i,3})
            %NOT IMPLEMENTED
          end
          
          %Set min size.
          if ~isempty(mylist{i,4}) & ~isempty(mylist{i,5})
            ctrl.setPreferredSize(java.awt.Dimension(mylist{i,4}, mylist{i,5}));
            ctrl.setMinimumSize(java.awt.Dimension(mylist{i,4}, mylist{i,5}));
            ctrl.setMaximumSize(java.awt.Dimension(mylist{i,4}, mylist{i,5}));
          end

          %Set Font.
          if ~isempty(obj.FontSize)
            f = ctrl.getFont;
            f = f.deriveFont(obj.FontSize);
            ctrl.setFont(f);
          end
          
          %Set callback.
          btnh = [];
          if ~isempty(mylist{i,6}) & strcmp(mylist{i,6},'button')
            btnh = handle(ctrl,'callbackproperties');
            if strcmp(class(mylist{i,6}),'function_handle')
              %set(btnh,'ActionPerformedCallback',{mylist{i,6},mylist{i,1},btnh,ctrl,obj})
              set(btnh,'MouseClickedCallback',{mylist{i,6},mylist{i,1},btnh,ctrl,obj})
            else
              %Need to clear these callbacks on delete otherwise will cause
              %memory leak.
              %set(btnh,'ActionPerformedCallback',{@ButtonPanel.EvalFunction,obj,mylist{i,1},btnh,mylist{i,7}})
              set(btnh,'MouseClickedCallback',{@ButtonPanel.EvalFunction,obj,mylist{i,1},btnh,mylist{i,7}})
            end
          end
          bp.add(ctrl);
          if ~isempty(btnh)
            obj.ButtonHandleList = [obj.ButtonHandleList {btnh}];
          end
        end
        bp.revalidate;
        bp.repaint;
      end
    end
    
    function obj = RemoveButtons(obj)
      %Safely remove all buttons from panel. Need to clear action performed
      %callback if using the EvalFunction static function otherwise will
      %cause memory leak.
      bh = obj.ButtonHandleList;
      for i = 1:length(bh)
        thisbh = bh{i};
        %set(thisbh,'ActionPerformedCallback',[]);
        set(thisbh,'MouseClickedCallback',[]);
      end
      %Now remove all buttons.
      bp = obj.LocalButtonPanel;
      bp.removeAll;%Remove all buttons.
      obj.ButtonHandleList = [];
      
    end
    
    function btn = GetButton(obj,indx)
      %Get a java button using index.
      bp = obj.LocalButtonPanel;
      cmps = bp.getComponents;
      if indx>length(cmps)
        btn = [];
      else
        btn = cmps(indx);
      end
    end
    
    function BoldSingleButton(obj,indx)
      %Bold a single button while setting other buttons to plain.
      
      bp = obj.LocalButtonPanel;
      cmps = bp.getComponents;
      bcount = 1;
      for i = 1:length(cmps)
        if strcmp(class(cmps(i)),'javax.swing.JButton')
          f1 = cmps(i).getFont;
          if bcount == indx
            f2 = f1.deriveFont(f1.BOLD,f1.getSize);
          else
            f2 = f1.deriveFont(f1.PLAIN,f1.getSize);
          end
          cmps(i).setFont(f2);
          bcount = bcount+1;
        end
      end
    end
  end
  
  methods (Static)
    
    function obj = EvalFunction(obj,event,varargin)
      %Evaluate a function stored by button.
      %Varargin{1} = ButtonPanel Object
      %Varargin{2} = Button ID name (tag).
      %Varargin{3} = Handled java button.
      %obj = raw java button.
      feval(varargin{end},'ButtonPanelCallback',varargin{1},varargin{2},varargin{3},obj);
    end
    
    function deletefcn(obj,event,varargin)
      delete(varargin{1})
    end
    
    function pnl = test
      pnl = ButtonPanel;
      mylist = { 'button_x'     'X' '' 50 50 'button' 'myfcn';
        'button_eq'   '=' '' 30 50 'label'  'myfcn';
        'button_a'    'Solvent Type' '' 50 50 'button' 'myfcn';
        'button_plus' '+' '' 30 50 'label'  'myfcn';
        'button_b'    'B Is a Test Button' '' 50 50 'button' 'myfcn'};
      
      pnl.ButtonList = mylist;
      
    end
  end
  
end


%Failed attempts to customize buttons.

%ctrl = evrijavaobjectedt('org.jdesktop.swingx.JXTextArea',mylist{i,2});
%ctrl.setForeground(java.awt.Color.BLACK)
%ctrl.setLineWrap(true)
%javax.swing.UIManager.put('Button.background', java.awt.Color.PINK)
%pp = new PinstripePainter(Colors.Gray.alpha(0.2),45)
%ctrl.setContentAreaFilled(false)
%mypainter = evrijavaobjectedt('org.jdesktop.swingx.painter.PinstripePainter',java.awt.Color(.1,.1,1,.5))
%             clrArray = javaArray ('java.awt.Color',2);
%             clrArray(1) = java.awt.Color(.1,.1,1,.5);
%             clrArray(2) = java.awt.Color(.1,.1,.1,.5);
%
%             fltArray = javaArray ('java.lang.Float',2)
%             fltArray(1) = 0;
%             fltArray(2) = 1;
%             gradpainter = evrijavaobjectedt('java.awt.LinearGradientPaint',0,0,100,100,[0 1],clrArray)
%             mypainter = evrijavaobjectedt('org.jdesktop.swingx.painter.MattePainter',gradpainter)
%             ctrl.setBackgroundPainter(mypainter)
%             ctrl.setForegroundPainter(mypainter)
%ctrl.setBackground(java.awt.SystemColor.control)

%           originalLnF = javax.swing.UIManager.getLookAndFeel;  %class
%           if ismac
%             newLnF = 'javax.swing.plaf.metal.MetalLookAndFeel';  %string
%           else
%             newLnF = originalLnF;
%           end
%
%           javax.swing.UIManager.setLookAndFeel(newLnF);
%           javax.swing.UIManager.setLookAndFeel(javax.swing.UIManager.getSystemLookAndFeelClassName)
