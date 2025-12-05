function mylist = gridlist(obj,nopts,nlist)
%GRIDLIST Make Java ArrayList list for Jide DefaultProperty items from options structure.
% Make renderer and editor controls from options structure. Use custom
% renderer/editor via custom EVRI Java class.
%
% INPUTS:
%   obj   = EGrid object.
%
% For recursive calls use additional inputs:
%   nopts = spoofed options structure.
%   nlist = com.jidesoft.grid.DefaultProperty parent.
%
%I/O: mylist = gridlist(obj);%Normal call.
%I/O: mylist = gridlist(obj,nopts,nlist)%Recursive call.
%
%See also: @EControl, @EGrid, OPTIONSEDITOR, OPTIONSGUI, PREFOBJCB, PREFOBJPLACE

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


%TODO: Fix rules for focus change and value changes. Get a lot of focused gained
%      but no changes to value. Property grid by default trys to make focus
%      the control but since we're doing custom renderer this gets messed
%      up. This seems to only happen on Mac.
%TODO: Could change save icon to include check-mark for when default is
%      saved and or matches the existing default.
%TODO: Figure out how to enable save buttons on nested options. And or
%      fully enable nested itmes.

com.mathworks.mwswing.MJUtilities.initJIDE;
import com.jidesoft.grid.*

myopts = obj.NewPropertyData;
if ~isfield(myopts,'definitions')
  mylist = [];
  return
end

iscellvalue  = false;%If true then this is a cell data type and needs to be parsed in callback.

if nargin>2 & ~isempty(myopts)
  %Spoofing options for nested field.
  myopts = nopts;
else
  nopts = [];
end

if strcmp(getappdata(0,'debug'),'on');
  dbstop if all error
end

mydefs = myopts.definitions();
mylist = java.util.ArrayList;

if nargin>2 & ~isempty(nlist)
  %Spoofing list for nested field. nlist should be a
  %com.jidesoft.grid.DefaultProperty.
  mylist = nlist;
  iscellvalue  = true;%If true then this is a cell data type and needs to be parsed in callback.
else
  nlist = [];
end

mylevel = obj.UserLevel;
myenblfcn = [];%Keep enable function 

for i = 1:length(mydefs)
  %Test if we should hide this option.
  if ~isempty(obj.HiddenProperties) && ismember(mydefs(i).name,obj.HiddenProperties)
    continue
  end
  
  %Test user level.
  if strcmp(mylevel,'novice') && ~strcmp(mydefs(i).userlevel,'novice')
    continue
  elseif strcmp(mylevel,'intermediate') && strcmp(mydefs(i).userlevel,'advanced')
    continue
  end
  
  try
    myval        = getsubstruct(myopts, mydefs(i).name);
  catch
    %Option in definitions but missing in struct (probably).
    continue
  end
  field        = com.jidesoft.grid.DefaultProperty;
  myvalid      = mydefs(i).valid;
  myrctrls     = [];%Render controls added after text field but before save button.
  myectrls     = [];%Editor controls added after text field but before save button.
  endable_edit = true;%If true then allow direct edit of control, otherwise must be a loaded item.
  parentctrl   = false;%If true then don't place a save button on this since it has children.
  context      = EditorContext(['evri_prop_control_' mydefs(i).name]);
  
  %Get custom cell editor and renderer with just a panel.
  mycelleditor   = evrijavaobjectedt('CustomPanelCellEditor');
  mycellrenderer = evrijavaobjectedt('CustomPanelCellEditor');
  
  %Almost everything uses a textfield to render. Overwrite this if using
  %other control.
  render_ctrl = makeCtrl('javax.swing.JTextField', '','');
  edit_ctrl   = [];
  noedit      = 0;%Flag for if text field can be editable.
  
  renderval   = '';%If we need to clear the option value we need to save a copy so the renderer can use it.
 
%  % Debug command if looking for particular property name.
%   if strcmp(mydefs(i).name,'axisautoinvert')
%     1;
%   end
  
  %*** Filter on select item here?


  mydt = mydefs(i).datatype;
  switch mydt
    case {'select' 'boolean' 'enable'}
      %Encode boolean and select.
      if ismember(mydt,{'select' 'enable'})
        
        if ~ischar(myvalid{1})
          %Infer data type from first cell.
          myvalid = cellfun(@num2str,myvalid,'UniformOutput', false);
          myval = num2str(myval);
        end
        
        %Need to get unique values (without changing order).
        [junk,ia,ic] = unique(myvalid);
        myvalid = myvalid(sort(ia));
      
      end
 
      if strcmp(mydt,'boolean')
        myvalid = {'Yes (1)' 'No (0)'};
        if islogical(myval) | isnumeric(myval)
          if myval
            myval = 'Yes (1)';
          else
            myval = 'No (0)';
          end
        end
      end
      
      if isnumeric(myval)
        javatype = getjavaclass('int32');
      else
        javatype = getjavaclass('char');
      end
      
      %Make editor control
      edit_ctrl = makeCtrl('javax.swing.JComboBox',myvalid,'','',myval);
      expd_ctrl = makeCtrl('javax.swing.JButton','','Expand ComboBox','Expand_Down_Arrow');
      
      myrctrls = [myrctrls {expd_ctrl}];

    case {'vector', 'matrix', 'dataset', 'preprocesing', 'directory' 'struct'}
      %Will make string describing what's loaded.
      javatype = getjavaclass('char');
      renderval = myval;
      myval = '';%Value is handled with options in click callback.
      %Make editor controls.
      %Load button.
      mybtn    = makeCtrl('javax.swing.JButton','','Click to edit value.','open_dots');
      btnh     = handle(mybtn,'CallbackProperties');
      set(btnh,'MouseClickedCallback', {@propEditClick,field,i,mydefs,render_ctrl,mybtn,'load',iscellvalue,obj});
      myectrls = [myectrls {mybtn}];
      %Clear button.
      mybtn2    = makeCtrl('javax.swing.JButton','','Click to edit value.','close_icon');
      btnh2     = handle(mybtn2,'CallbackProperties');
      set(btnh2,'MouseClickedCallback', {@propEditClick,field,i,mydefs,render_ctrl,mybtn,'clear',iscellvalue,obj});
      myectrls = [myectrls {mybtn2}];
      
      %Make non-functional renderer.
      mybtn3 = makeCtrl('javax.swing.JButton','','Click to edit value.','open_dots');
      myrctrls = [myrctrls {mybtn3}];
      
      mybtn4= makeCtrl('javax.swing.JButton','','Click to edit value.','close_icon');
      myrctrls = [myrctrls {mybtn4}];
      
      noedit = 1;
    case 'double'
      javatype = getjavaclass('double');
      myval = getsubstruct(myopts, mydefs(i).name);
    case {'char' 'mode' 'vector_inline'}
      %Mode data == (e.g. '3 4 6').
      if isnumeric(myval)
        myval = num2str(myval);
      end
      javatype = getjavaclass('char');
      field.setValue(myval);
    case {'cell(char)' 'cell(double)' 'cell(vector)' 'cell(select)' 'cell(struct)'}
      %Make nested field for cell array.
      field.setCategory(mydefs(i).tab);
      field.setDisplayName(mydefs(i).name);
      field.setName(mydefs(i).name);  % JIDE automatically uses a hierarchical naming scheme
      field.setDescription(mydefs(i).description);
      field.setEditable(false);
      
      numcells = length(myval);%Number of cells to create.
      if numcells==0
        %Probably don't have cell data type in options.
        error('Expecting cell data type in options structure.')
      end
      [dummy,rem] = strtok(mydt,'()');
      dtype = strtok(rem,'()'); %Cell datatype.
      row = mydefs(i);
      tempopts = [];
      for j = 1:numcells
        %Build temporary options structure to call gridlist recursively.
        tempopts = setfield(tempopts,[mydefs(i).name '_Mode' num2str(j)],myval{j});
        tempopts.definitions(j) = row;
        tempopts.definitions(j).name = [mydefs(i).name '_Mode' num2str(j)];
        tempopts.definitions(j).datatype = dtype;
        tempopts.definitions(j).valid = myvalid;
      end
      field = gridlist(obj,tempopts,field);
      myval = '';
      parentctrl = true;
    %case 'struct'
      
    otherwise
      field.setType(getjavaclass('double'))
      field.setValue(myopts.(mydefs{i,1}))
  end
  
  %Register cell editor/renderer as rederer.
  CellRendererManager.registerRenderer(javatype, mycellrenderer, context);
  
  %Register same cell editor/renderer as editor.
  CellEditorManager.registerEditor(javatype, mycelleditor, context);
  
  %Add context so we can unregister when object is destroyed.
  obj.AddContextObj(javatype,context);
  
  drawnow
  
  %Add current value to renderer.
  if isempty(renderval)
    renderval = myval;
  end
  setVal(render_ctrl, renderval, noedit)
  
  %Get editor/renderer underlying panel.
  ep = mycelleditor.getPanel;
  rp = mycellrenderer.getPanel;
  drawnow
  
  %Set layout and add main control to editor panel.
  rp.setLayout(javax.swing.BoxLayout(rp, javax.swing.BoxLayout.X_AXIS));
  rp.add(render_ctrl);
  rp.add(javax.swing.Box.createHorizontalGlue());
  
  if isempty(edit_ctrl)
    edit_ctrl = makeCtrl('javax.swing.JTextField','','Click to edit value.','');
  end
  
  edit_ctrlh = handle(edit_ctrl,'CallbackProperties');
  if strcmp(class(edit_ctrl),'javax.swing.JComboBox')
    set(edit_ctrlh,'ActionPerformedCallback',{@propEditCallback,field,i,mydefs,render_ctrl,iscellvalue,obj});
  else
    %Doesn't work because if you can get into state where you can edit
    %anything like when typing a number 0-1 the . is invalid until number
    %comes.
    %set(edit_ctrlh,'KeyTypedCallback',{@propEditCallback,i,mydefs,render_ctrl,obj});
    
    %Can't reset focus to correct control after losing it.
    %set(edit_ctrlh,'FocusLostCallback',{@propEditCallback,i,mydefs,render_ctrl,obj});
    
    %Same as keytyped.
    %set(edit_ctrlh,'CaretUpdateCallback',{@propEditCallback,i,mydefs,render_ctrl,obj});
    
    %Don't understand how to use this.
    %doch = handle(edit_ctrl.getDocument,'CallbackProperties');
    %set(doch,'ChangedUpdateCallback',{@propEditCallback2,i,mydefs,render_ctrl,obj})
    
    %Seems to be run only after carriage return key is pressed.
    %set(edit_ctrlh,'ActionPerformedCallback',{@propEditCallback,i,mydefs,render_ctrl,obj});
    
    set(edit_ctrlh,'FocusLostCallback',{@propEditCallback,field,i,mydefs,render_ctrl,iscellvalue,obj});
  end

  %Disable control if called for.
  if noedit
    set(edit_ctrlh,'Editable',0);
  end
  setVal(edit_ctrl, renderval, noedit);
   
  %Set layout and add main control to editor panel.
  ep.setLayout(javax.swing.BoxLayout(ep, javax.swing.BoxLayout.X_AXIS));
  ep.add(edit_ctrl);
  ep.add(javax.swing.Box.createHorizontalGlue());
  
%   %Add extra render controls.
%   for j = 1:length(myrctrls)
%     rp.add(myrctrls{j});
%   end
  
  %Add extra editor controls.
  for j = 1:length(myectrls)
    ep.add(myectrls{j});
  end
  
  %Add save button if wanted.
  if obj.ShowSave & ~parentctrl & isempty(strfind(mydefs(i).name,'.')) & isfield(myopts,'functionname')
    %Add editor save button.
    sbtn = makeCtrl('javax.swing.JButton','','Save as default value for this option.','save_16');
    sbtnh = handle(sbtn,'CallbackProperties');
    set(sbtnh, 'MouseClickedCallback', {@propEditClick,field,i,mydefs,edit_ctrl,sbtnh,'save',iscellvalue,obj});
    ep.add(sbtnh);
    
    %Add renderer save button so it shows up when not editing.
%     sbtn2 = makeCtrl('javax.swing.JButton','','Save as default value for this option.','save_16');
%     rp.add(sbtn2);
  end
  
  %This doesn't seem to do anything.
  %field.setCellEditor(mycelleditor);
  
  field.setType(javatype)
  field.setEditorContext(context);
  field.setValue(myval)
  
  field.setCategory(mydefs(i).tab);
  field.setDisplayName(mydefs(i).name);
  field.setName(mydefs(i).name);  % JIDE automatically uses a hierarchical naming scheme
  mydesc = mydefs(i).description;
  if iscell(mydesc)
    mydesc = cell2str(mydesc);
  end
  field.setDescription(mydesc);
  %set(field,'PropertyChangeCallback',{@propEditCallback2,i,mydefs,render_ctrl,obj})
  %field.setEditable(1);
  if ~isempty(nlist)
    mylist.addChild(field);
  else
    mylist.add(field);
  end
end

%--------------------------------
function propEditCallback(varargin)
%Edit callback, check values and update options.

editctrl    = varargin{1};
mouse_event = varargin{2};
myfield     = varargin{3};
myidx       = varargin{4};
mydefs      = varargin{5};
renderctrl  = varargin{6};
lbl_java    = varargin{7};
iscellvalue = varargin{8};
myobj       = varargin{end};

myfig       = myobj.ParentFigure;

mydef = mydefs(myidx);

oldval = char(renderctrl.getText);

newval     = [];%Actual value (same datatype as control).
newval_str = '';%Value in data type for display.
noedit     = false;%If true then should not edit this value directly, use load button or other control.
hideprops = [];%If datatype is select then properties may need to be hidden.

myerr = '';

if ~isempty(strfind(class(editctrl),'javax.swing.JComboBox'))
  newval = editctrl.getSelectedItem;
  newval_str = num2str(newval);
  switch mydef.datatype
    case 'boolean'
      if strcmp(newval,'Yes (1)')
        newval = true;
      else
        newval = false;
      end
    case {'select' 'enable'}
      %Need to infer datatype from first cell of valid.
      if iscell(mydef.valid) & isnumeric(mydef.valid{1})
        if isempty(newval)
          newval = [];
        else
          newval = str2num(newval);
        end
      end
      
      %If enable, need to add all other options to hidden list. Looks for
      %"_" in name to determine members to hide.
      if strcmp(mydef.datatype,'enable')
        myobj.UpdateVisible(newval)
        
%         defsnames = {mydefs.name};
%         underscore_location = strfind(defsnames,'_');
%         defs2hide = zeros(1,length(defsnames));
%         for i = 1:length(underscore_location)
%           if isempty(underscore_location{i})
%             %Should not hide this def becuase it doesn't have an "_" so
%             %it's not related to the enable pool.
%             continue
%           else
%             %If this is an underscore location then see if mydef name is in
%             %the name. If not then we hide it.
%             if ~any(strfind(defsnames{i},newval)==1)
%               defs2hide(i) = 1;
%             end
%           end
%         end
%         hideprops = defsnames(logical(defs2hide));
%         myobj.HiddenProperties = hideprops;
%         myobj.UpdateHidden;
      end
      
  end
else
  %Check val.
  newval = char(editctrl.getText);
  myerr = '';
  switch mydef.datatype
    case {'double' 'mode' 'vector_inline'}
      if isempty(newval)
        %If pass empty to str2num get empty back.
        newval = [];
      else
        %If pass bad val to str2num get empty back, need to error.
        thisval = double(str2num(newval));
        if isempty(thisval)
          myerr = 'Invalid character in option, must be numeric.';
        end
        newval = thisval;
      end
      
      if strcmp(mydef.datatype,'double') & isempty(myerr) & sum(size(newval))>2
        myerr = 'Option value must be a single value.';
        newval = oldval;
      end
      
      if isempty(myerr) & ~prefobjcb('isvalid',newval,mydef,[])
        myerr = ['Option value for ''' mydef.name ''' not valid. Check help for accepted range of values for this field.'];
      end
      
      if ~isempty(myerr)
        erdlgpls(myerr,'Invalid Setting')
        newval = oldval;
        newval_str = num2str(oldval);
        editctrl.setText(newval_str);%Reset editor to old value.
        %Save laste error row to appdata so we can highlight it later.
        %Can't seem to highlight in this code.
        t = myobj.Table;
        lr = t.getEditingRow;
        setappdata(myfig,'LastErrRow',t.getEditingRow)
      else
        newval_str = num2str(newval);
      end
    case {'vector', 'matrix', 'dataset', 'preprocesing', 'directory' 'struct'}
      noedit = true;
    otherwise
      %Character array.
      newval_str = newval;
  end
end


%Try to set focus back to control.
if ~isempty(myerr)
  t = myobj.Table;
  t.setRowSelectionInterval(1,t.getRowIndex(myfield))
else
  if noedit
    %Maybe update save button icon if value is already the default.
    
  else
    %What do we do when this is a nested field. Most nested are button click
    %situations. Intercepot button click above and only set renderer.
    
    %Set renderer value to new value.
    renderctrl.setText(newval_str)
    %Update options structure with new value.
    myopts = myobj.NewPropertyData;
    myopts = setsubstruct(myopts, mydef.name, {}, newval);
    myobj.NewPropertyData = myopts;
  end
end

%Need repaint to update renderer.
mypane = myobj.Pane;
mypane.repaint;

%--------------------------------
function propEditClick(varargin)
%Click on edit property button.

editctrl    = varargin{1};
mouse_event = varargin{2};
myfield     = varargin{3};
myidx       = varargin{4};
mydefs      = varargin{5};
renderctrl  = varargin{6};
lbl_java    = varargin{7};
mycmd       = varargin{8};
iscellvalue = varargin{9};
myobj       = varargin{end};

myfig       = myobj.ParentFigure;
mydef       = mydefs(myidx);

myopts      = myobj.NewPropertyData;

if iscellvalue
  oname = mydef.name(1:regexp(mydef.name,'_Mode\d*')-1); %Name.
  omode = str2num(mydef.name(regexp(mydef.name,'_Mode\d*')+5:end));%Mode.
else
  oname = mydef.name;
  omode = 1;
end

rawdata = [];
usercancel  = 0;%Did user cancel action.

switch mycmd
  case 'save'
    %Save current option as default.
    if ~isfield(myopts,'functionname')
      erdlgpls('Cannot save as default (no associated function name)');
      return
    end
    setplspref(myopts.functionname,mydef.name,getsubstruct(myopts,oname));
    return
  case 'clear'
    rawdata = [];
  case 'load'
    if strfind(mydef.valid,'loadfcn')
      %Userdefined function for loading and validating data.
      fcn = deblank(mydef.valid);
      fcn = fcn(strfind(fcn,'=')+1:end);
      x = findfield(myopts,mydef.name);
      try
        set(myfig,'pointer','watch','visible','off')
        rawdata = feval(fcn,x);
        set(myfig,'pointer','arrow','visible','on')
      catch
        set(myfig,'pointer','arrow','visible','on')
        dlgans = evriquestdlg(['Unable to run custom load function. Try loading from workspace or file?'],'Load Problem');
        if strcmp(dlgans,'Yes')
          dlgsetting = {'*'};
          [rawdata,name,location] = lddlgpls(dlgsetting,'Load Options Field Data');
        end
      end
      if isempty(rawdata)
        usercancel = 1;
      end
    elseif strcmp(mydef.datatype,'preprocessing') | strfind(mydef.name,'preprocessing')==1
      pp = myopts.preprocessing;
      if iscell(pp)
        pp = pp{omode};
      end
      [rawdata,usercancel] = preprocess(pp);
      usercancel = ~usercancel;
    elseif strcmp(mydef.datatype,'directory')
      x = findfield(myopts,mydef.name);
      rawdata = uigetdir(x,mydef.name);
      if isnumeric(rawdata)
        usercancel  = 1;
      end
    elseif strfind(mydef.valid,'custom')
      %Use a custom loading method.
      switch mydef.name
        case 'baseline_options'
          %NOTE: This is not used currently. There's a bug where the
          %preprocessing main window gets focus back and doesn't allow
          %options editor to regain focus. Works if you step through the
          %code but not without breakpoint. 
          
          %Grab frequency, range, and order. Put them into PP struct for
          %baseline then open baselineset.m
          bspp = baselineset('default');
          bspp.userdata.order = myopts.order;
          bspp.userdata.range = myopts.baseline_range;
          %Figure out if being called from preprocess.
          mydbstack = dbstack;
          baseppfig = [];
          if ismember('preprocess',{mydbstack.name})
            baseppfig = findobj(allchild(0),'tag','preprocess','type','figure');
            baseppfig = baseppfig(end);
          end
          
          if ~isempty(baseppfig) && ishandle(baseppfig)
            %Do graphical selection.
            newbspp = feval(bspp.settingsgui, bspp, baseppfig);
            drawnow;pause(.05)
            figure(myfig);
            myopts = myobj.NewPropertyData;
            myopts.order = newbspp.userdata.order;
            myopts.baseline_range = newbspp.userdata.range;
            myobj.NewPropertyData = myopts;
            
%             m = myobj.Model;
%             p = m.findProperty('order');
%             m.setValueAt
            %myobj.UpdateGrid;
            
            drawnow
            myobj.UpdateVisible;

          end
          return
      end
    else
      switch mydef.datatype
        case 'dataset'
          dlgsetting = {'*'};
        otherwise
          dlgsetting = {'*'};
      end
      [rawdata,name,location] = lddlgpls(dlgsetting,'Load Options Field Data');
      if strcmp(mydef.datatype,'dataset') & ~isempty(rawdata) & ~isdataset(rawdata)
        rawdata = dataset(rawdata);
      end
      if isempty(rawdata)
        usercancel  = 1;
      end
    end
end

if ~usercancel
  if ~prefobjcb('isvalid',rawdata,mydef,[])
    erdlgpls(['Option value for ''' mydef.name ''' not valid. Check help for accepted range of values for this field.'],'Invalid Setting')
    return
  end
  %Set renderer value to new value.
  setVal(renderctrl, rawdata, 1);
  if strcmp(class(editctrl),'javahandle_withcallbacks.javax.swing.JButton')
    tcomp = editctrl.getParent.getComponents;
    tcomp = tcomp(1);
    setVal(tcomp, rawdata, 1);
  else
    setVal(editctrl, rawdata, 1);
  end
  if iscellvalue
    %Update options structure with new value.
    myopts = myobj.NewPropertyData;
    thisval = myopts.(oname);
    thisval{omode} = rawdata;
    myopts = setsubstruct(myopts, oname, {}, thisval);
    myobj.NewPropertyData = myopts;
  else
    %Update options structure with new value.
    myopts = myobj.NewPropertyData;
    myopts = setsubstruct(myopts, mydef.name, {}, rawdata);
    myobj.NewPropertyData = myopts;
  end
end

%--------------------------------
function [ctrl, ctrlh] = makeCtrl(myctrl, myval, tt, icon, thisval)
%Make java control.
% myctrl  = name of java control.
% myval   = initial value/s for control.
% tt      = Tool tip.
% icon    = name if browse icon (see browseicons).
% thisval = value for combo box to be set to.

ctrl = evrijavaobjectedt(myctrl,myval);
ctrl.setBorder(javax.swing.BorderFactory.createEmptyBorder())
ctrl.setToolTipText(tt);

switch myctrl
  case 'javax.swing.JComboBox'
    ctrl.setPreferredSize(java.awt.Dimension(400,12));
    if ~isempty(thisval)
      ctrl.setSelectedItem(thisval)
    end
  case 'javax.swing.JTextField'
    
  case 'javax.swing.JButton'
    ctrl.setPreferredSize(java.awt.Dimension(16,15));
    ctrl.setMaximumSize(java.awt.Dimension(16,15));
    if ~isempty(icon)
      myico = javax.swing.ImageIcon(im2java(browseicons(icon)));
      ctrl.setIcon(myico)
    end
end

%--------------------------------
function setVal(myctrl, myval, noedit)
%Set a value on a control.

mycls = class(myctrl);
sz = size(myval);

if noedit
  if isempty(myval)
    sizestr = '(empty)';
  else
    sizestr = sprintf('%ix',sz);
    sizestr = [sizestr(1:end-1) ' ' class(myval)];
  end
  myctrl.setText(sizestr);
  return
end

if isa(myctrl,'javax.swing.JTextField')
  switch class(myval)
    case 'char'
      myctrl.setText(myval);
    case 'cell'
      
    case 'struct'
      
    case 'double'
      if isscal(myval)
        myctrl.setText(num2str(myval));
      else
        
      end
    otherwise

  end
end

%--------------------------------------------------------------------
function out = findfield(opts,name)
%Get a value from options.
%If cell value, do parsing.
if regexp(name,'Mode\d*')
  oname = name(1:regexp(name,'_Mode\d*')-1); %Name
  omode = str2num(name(regexp(name,'_Mode\d*')+5:end)); %Integer
  out = getsubstruct(opts,oname,{omode});
  out = out{:};
else
  out = getsubstruct(opts,name);
end

%--------------------------------------------------------------------
function out = getjavaclass(ctype)
%Get java class instance.
%Bassed on javaclass by Levente Hunyadi.
%TODO: Make this a standalone function if we start needing it elsewhere.

switch ctype
  case 'logical'
    cname = 'java.lang.Boolean';
  case 'char'  
    cname = 'java.lang.Character';
  case {'int8','uint8'}  
    cname = 'java.lang.Byte';
  case {'int16','uint16'} 
    cname = 'java.lang.Short';
  case {'int32','uint32'} 
    cname = 'java.lang.Integer';
  case {'int64','uint64'}
    cname = 'java.lang.Long';
  case 'single'
    cname = 'java.lang.Float';
  case 'double'
    cname = 'java.lang.Double';
  case 'cellstr'
    cname = 'java.lang.String';
end

out = java.lang.Class.forName(cname, true, java.lang.Thread.currentThread.getContextClassLoader);

%--------------------------------------------------------------------
function updatehidden(myobj,mydefs,newval)
%Update hidden props based on selected value (newval) of "enable" type option.

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
    if ~any(strfind(defsnames{i},newval)==1)
      defs2hide(i) = 1;
    end
  end
end
hideprops = defsnames(logical(defs2hide));
myobj.HiddenProperties = hideprops;
myobj.UpdateHidden;

%--------------------------------------------------------------------
function test
%Code for getting object.
f = allchild(0);
h = guihandles(f);
g = h.eGrid;
eg = get(g,'UserData');
eg.PropertyData;
eg.NewPropertyData;

