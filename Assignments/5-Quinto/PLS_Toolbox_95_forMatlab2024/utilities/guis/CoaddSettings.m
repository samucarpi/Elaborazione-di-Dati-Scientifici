classdef CoaddSettings < handle
  %COADDSETTINGS GUI for Coadd Settings
% See also: coadd

%Copyright Eigenvector Research, Inc. 2022
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
  
  properties (Access = public)
    settings %stores the settings from the GUI
    fig %the figure that gets created
  end
  
  
  properties (Access = protected)
    coaddsettings matlab.ui.Figure
    okButton, cancelButton matlab.ui.control.Button
    binSizeEditField matlab.ui.control.NumericEditField
    binSizeText, dimText, actionText, coaddsetLabel, ClassDropDownLabel matlab.ui.control.Label
    mode, action, ClassDropDown matlab.ui.control.DropDown
    UseClassCheckBox matlab.ui.control.CheckBox
    data
    classList
  end
  
  methods
    function obj = CoaddSettings(data)
      % Create coaddsettings and hide until all components are created
      obj.data = data;

      obj.coaddsettings = uifigure('Visible', 'off');
      obj.coaddsettings.Position = [520 649 359 193];
      obj.coaddsettings.Name = 'Coadd Settings';
      obj.coaddsettings.Resize = 'off';
      %obj.coaddsettings.HandleVisibility = 'callback';
      obj.coaddsettings.Tag = 'coaddsettings';
      %obj.coaddsettings.WindowStyle = 'modal';
       
      % Create binsize
      obj.binSizeEditField = uieditfield(obj.coaddsettings, 'numeric');
      obj.binSizeEditField.Tag = 'binsize';
      if checkmlversion('>=', '9.5')
        obj.binSizeEditField.Tooltip = 'Number of items to bin into a single value';
      end
      obj.binSizeEditField.Position = [120 138 126 21];
      obj.binSizeEditField.Value = 2;
      
      % Create binsizetext
      obj.binSizeText = uilabel(obj.coaddsettings);
      obj.binSizeText.Tag = 'binsizetext';
      %obj.binSizeText.WordWrap = 'on';
      obj.binSizeText.Position = [18 133 96 23];
      obj.binSizeText.Text = 'Bin Size:';
      
      % Create dimtext
      obj.dimText = uilabel(obj.coaddsettings);
      obj.dimText.Tag = 'dimtext';
      obj.dimText.BackgroundColor = [0.9412 0.9412 0.9412];
      %obj.dimText.WordWrap = 'on';
      obj.dimText.Position = [18 77 96 23];
      obj.dimText.Text = 'Dim/Mode:';
      
      % Create actiontext
      obj.actionText = uilabel(obj.coaddsettings);
      obj.actionText.Tag = 'actiontext';
      %obj.actionText.WordWrap = 'on';
      obj.actionText.Position = [18 51 96 23];
      obj.actionText.Text = 'Action:';
      
      str = {'Rows', 'Columns'};
      if ndims(data)>2
        str = str2cell(sprintf('Mode %i\n',[1:ndims(data)]));
      end
      if isdataset(data) & strcmp(data.type,'image')
        imgmode = data.imagemode;
        if imgmode<=length(str)
          str{imgmode} = 'Pixels';
        end
      end
      
      % Create mode
      obj.mode = uidropdown(obj.coaddsettings,...
        'ValueChangedFcn',@(src,event) getClassSets(obj));
      obj.mode.Items = str;
      obj.mode.Tag = 'mode';
      if checkmlversion('>', '9.5')
        obj.mode.Tooltip = 'Mode of data to coadd';
      end
      obj.mode.BackgroundColor = [1 1 1];
      obj.mode.Position = [120 79 126 24];
      obj.mode.Value = str{1};
      obj.mode.ItemsData = 1:length(str);
      
      % Create action
      obj.action = uidropdown(obj.coaddsettings);
      obj.action.Items = {'Sum', 'Mean', 'Product', 'Variance',...
        'Std Dev'};
      obj.action.Tag = 'action';
      if checkmlversion('>', '9.5')
        obj.action.Tooltip = 'Numerical calculation to use';
      end
      obj.action.BackgroundColor = [1 1 1];
      obj.action.Position = [120 51 126 24];
      obj.action.Value = 'Sum';
      
      % Create okbtn
      obj.okButton = uibutton(obj.coaddsettings, 'push',...
        'ButtonPushedFcn', @(btn,event) getSettingsClose(obj,btn));
      obj.okButton.Tag = 'okbtn';
      obj.okButton.Position = [34 14 110 27];
      obj.okButton.Text = 'OK';
      
      % Create cancelbtn
      obj.cancelButton = uibutton(obj.coaddsettings, 'push',...
        'ButtonPushedFcn', @(btn,event) getSettingsClose(obj, btn));
      obj.cancelButton.Tag = 'cancelbtn';      
      obj.cancelButton.Position = [155 14 110 27];
      obj.cancelButton.Text = 'Cancel';
      
      % Create coaddsetlabel
      obj.coaddsetLabel = uilabel(obj.coaddsettings);
      obj.coaddsetLabel.Tag = 'headerlabel';
      %obj.coaddsetLabel.WordWrap = 'on';
      obj.coaddsetLabel.FontWeight = 'bold';
      obj.coaddsetLabel.Position = [34 164 220 22];
      obj.coaddsetLabel.Text = 'Coadd Settings';
      
      % Create ClassDropDownLabel
      obj.ClassDropDownLabel = uilabel(obj.coaddsettings);
      obj.ClassDropDownLabel.Tag = 'classdropdownlabel';
      obj.ClassDropDownLabel.BackgroundColor = [0.9412 0.9412 0.9412];
      obj.ClassDropDownLabel.Enable = 'off';
      obj.ClassDropDownLabel.Position = [72 105 42 22];
      obj.ClassDropDownLabel.Text = 'Class:';
      
      
      % Create UseClassCheckBox
      obj.UseClassCheckBox = uicheckbox(obj.coaddsettings,'Value', 0,...
        'ValueChangedFcn',@(src,event) UseClassCheckBoxValueChanged(obj));
      obj.UseClassCheckBox.Text = 'Use Class';
      obj.UseClassCheckBox.Position = [264 105 81 22];
      obj.UseClassCheckBox.Enable = 'on';
      
      % Create ClassDropDown
      obj.ClassDropDown = uidropdown(obj.coaddsettings);
      obj.ClassDropDown.Tag = 'classdropdown';
      obj.ClassDropDown.Enable = 'off';
      obj.ClassDropDown.BackgroundColor = [1 1 1];
      obj.ClassDropDown.Position = [120 106 126 24];
      obj.getClassSets();
      
      set([obj.actionText obj.dimText obj.binSizeText obj.ClassDropDownLabel ...
        obj.coaddsetLabel],'HorizontalAlignment','right',...
        'VerticalAlignment','top');
      
      set([obj.binSizeEditField obj.binSizeText obj.dimText obj.actionText ...
        obj.mode obj.action obj.okButton obj.cancelButton obj.coaddsetLabel ...
        obj.ClassDropDownLabel obj.UseClassCheckBox],'FontSize', 13);
      
      obj.coaddsettings.Visible = 'on';
      obj.fig = obj.coaddsettings;
    end
    %-----------------------------------------------
    function obj = UseClassCheckBoxValueChanged(obj)
      %notify(obj,'ValueChanged');
      if obj.UseClassCheckBox.Value
        binEn = 'off';
        classEn = 'on';
      else
        binEn = 'on';
        classEn = 'off';
      end
      set([obj.binSizeEditField obj.binSizeText],'Enable', binEn);
      set([obj.ClassDropDown obj.ClassDropDownLabel],'Enable', classEn);
    end
    %-----------------------------------------------
    function obj = getClassSets(obj)
      if strcmp(obj.data.type,'image') %turn off ability use classes if an image
        set([obj.ClassDropDown obj.ClassDropDownLabel obj.UseClassCheckBox],...
          'Enable', 'off');
        if checkmlversion('>', '9.5')
          set([obj.ClassDropDown obj.UseClassCheckBox obj.ClassDropDownLabel],...
            'Tooltip', 'Cannot bin by class information for images');
        end
        return;
      end
      emptyTest = isempty(obj.data.class{obj.mode.Value,1});
      if emptyTest
        set([obj.ClassDropDown obj.ClassDropDownLabel obj.UseClassCheckBox],...
          'Enable', 'off');
        obj.UseClassCheckBox.Value = 0;
        set([obj.binSizeEditField obj.binSizeText],'Enable', 'on');
        if checkmlversion('>', '9.5')
          set([obj.ClassDropDown obj.UseClassCheckBox],...
            'Tooltip', 'No class sets for this dim/mode');
        end
        return;
      end
      classsets = obj.data.classname(obj.mode.Value,:);
      for j=find(cellfun('isempty',classsets))
        classsets{j} = sprintf('Class Set %i',j);
      end
      obj.classList = classsets;
      obj.UseClassCheckBox.Enable = 'on';
      if checkmlversion('>', '9.5')
        obj.ClassDropDown.Tooltip = '';
        obj.UseClassCheckBox.Tooltip = '';
      end
      obj.ClassDropDown.Items = obj.classList;
      obj.ClassDropDown.ItemsData = 1:length(classsets);
      obj.ClassDropDown.Value = 1;
      
    end
    %-----------------------------------------------
    function obj = getSettingsClose(obj, btn)      
      obj.settings = struct();      
      if strcmp(btn.Text, 'OK')
        obj.settings.OK = 1;
      elseif strcmp(btn.Text, 'Cancel')
        obj.settings.OK = 0;
        close(obj.coaddsettings);
        return;        
      end
      if obj.UseClassCheckBox.Value
        obj.settings.binsize = [];
        obj.settings.classSet = obj.ClassDropDown.Value;
        obj.settings.ClassSetName = ...
          obj.ClassDropDown.Items{obj.ClassDropDown.Value};
      else
        obj.settings.classSet = [];
        obj.settings.classSet = [];
        obj.settings.binsize = obj.binSizeEditField.Value;
      end
      obj.settings.mode = obj.mode.Value;
      obj.settings.action = obj.action.Value;
      close(obj.coaddsettings);
    end    
  end
end