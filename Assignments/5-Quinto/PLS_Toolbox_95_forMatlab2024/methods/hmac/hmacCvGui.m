classdef hmacCvGui
  %HMACCVGUI Cross Validation interface for Hmac models.
  % Interface to specify cross validation settings for each model node
  % created by Hmac. 
  %
  % INPUTS:
  %         x = X-block (predictor block) class "double" or "dataset",
  %      file = File calling this gui (mfilename). This will control which
  %             CV methods are available.
  %
  % OPTIONAL INPUT:
  % cvoptions = Struct indicating previous cross-validation
  %             settings. The struct must have the following fields populated:
  % cvoptions.cvi = CVI cell array specifying one of the pre-defined subset methods: {method splits iterations}
  % cvoptions.maxlvs = double, Maximum number of latent variables to use,
  % cvoptions.method = char, full name of cross-validation method.
  %
  %  OUTPUT:
  %       hmacCvGui  = object of this class.
  %
  %I/O: [hmaccvgui]         = hmacCvGui(x,'hmacGui',[]);                    % instantiate object of this class.
  %I/O: [hmaccvgui]         = hmacCvGui(x,'hmacGui',cvoptions);             %populate gui with certain settings
  %I/O: [cvi]               = getappdata(hmaccvgui.fig,'cvi');              % get cvi from fig
  %
  %See also: HMACGUI, AUTOCLASSIFER, MERGELEASTSEPARABLE, GETMISCLASSIFICATION, GETPAIRMISCLASSIFICATION, MODELSELECTOR, CROSSVAL, PLSDA

  % Copyright © Eigenvector Research, Inc. 2022
  % Licensee shall not re-compile, translate or convert "M-files" contained
  %  in PLS_Toolbox for use with any software other than MATLAB®, without
  %  written permission from Eigenvector Research, Inc.

  properties
    fig     % Gui for CV
    cv      % Previous CV settings to be populated in GUI, if provided
    x       % XBlock
    file    % File calling this object (mfilename)
  end

  methods
    function obj = hmacCvGui(x,file,cvoptions)
      % Class constructor
      if isempty(cvoptions)
        obj.cv.cvi = {'vet' 10 1};
        obj.cv.maxlvs = 6;
        obj.cv.method = 'venetian blinds';
      else
        obj.cv.cvi = cvoptions.cvi;
        obj.cv.maxlvs = cvoptions.maxlvs;
        obj.cv.method = cvoptions.method;
      end
      obj.x = x;
      obj.file = file;
      % Initialize interface
      obj = obj.createGui();
    end
    function obj = createGui(obj)

      % Create UIFigure and hide until all components are created
      obj.fig = uifigure('Visible', 'off');
      set(obj.fig,'Position',[100 100 640 480]);
      set(obj.fig,'Name','Cross-Validation Settings');
      set(obj.fig,'Tag','HmacCV');

      % Initial Crossval settings. Set these up for resetting purposes
      lastcvoptions.method = obj.cv.method;
      lastcvoptions.cvi = obj.cv.cvi;
      lastcvoptions.maxlvs = obj.cv.maxlvs;
      setappdata(obj.fig,'lastcvoptions',lastcvoptions);
      setappdata(obj.fig,'cvi',obj.cv.cvi);
      setappdata(obj.fig,'maxlvs',obj.cv.maxlvs);

      %--------------------------------------------
        % Cross-Val Method
      %--------------------------------------------

      % Create Panel for dropdown
      pnl1 = uipanel(obj.fig);
      set(pnl1,'Position',[13 392 260 76]);

      % Create DropDownLabel
      ddlbl = uilabel(pnl1);
      set(ddlbl,'HorizontalAlignment','right');
      set(ddlbl,'Position',[3 32 101 22]);
      set(ddlbl,'Text','Cross-Val Method');

      % Create DropDown
      dd = uidropdown(pnl1);
      set(dd,'Position',[65 11 139 22]);
      set(dd,'Tag','methoddropdown');
      % add to this switch statement to show allowed cv methods
      switch obj.file
        case 'hmacGui'
          % not allowing 'none' or 'custom' here
          methods = {'leave one out' 'venetian blinds' 'contiguous blocks' 'random subsets'};
        case 'diviner_analysis_alpha'
          methods = {'leave one out' 'venetian blinds' 'contiguous blocks' 'random subsets'};
        otherwise
          evrierrordlg('Method unsupported for Cross-Validation');
          return
      end
      set(dd,'Items',methods);
      set(dd,'Value',lastcvoptions.method);
      setappdata(obj.fig,'method',lastcvoptions.method);
      set(dd,'ValueChangedFcn',{@obj.method_Callback obj.fig});

      % Create Panel for sliders
      pnl2 = uipanel(obj.fig);
      set(pnl2,'Position',[285 162 347 306]);

      %--------------------------------------------
        % Maximum Number of LVs
      %--------------------------------------------

      % Create max lvs label
      sldlbl1 = uilabel(pnl2);
      set(sldlbl1,'Position',[72 232 145 25]);
      set(sldlbl1,'Text','Maximum Number of LVs');

      % Create min lvs label
      sldminlbl1 = uilabel(pnl2);
      set(sldminlbl1,'Text','1');
      set(sldminlbl1,'Position',[40 210 34 22]);

      % Create max lvs slider
      sld1 = uislider(pnl2);
      set(sld1,'Position',[77 220 198 3]);
      set(sld1,'Tag','lvslider');
      set(sld1,'ValueChangedFcn',{@obj.sld_Callback obj.fig 'sldlblval1'});

      % Create current lvs label
      sldlblval1 = uilabel(pnl2);
      set(sldlblval1,'Position',[280 232 34 22]);
      set(sldlblval1,'Text','1');
      set(sldlblval1,'Tag','sldlblval1');

      % Create maximum label for max lvs
      sldmaxlbl1 = uilabel(pnl2);
      set(sldmaxlbl1,'Position',[303 210 34 22]);
      set(sldmaxlbl1,'Text','max');
      set(sldmaxlbl1,'Tag','sldmaxlbl1');
      
      % Add button
      sldaddbtn1 = uibutton(pnl2,'push');
      set(sldaddbtn1,'Position',[280 212 20 20]);
      set(sldaddbtn1,'Text','>');
      set(sldaddbtn1,'ButtonPushedFcn',{@obj.add_Callback obj.fig 'lvslider' 'sldlblval1'});

      % Subtract button
      sldsubbtn1 = uibutton(pnl2,'push');
      set(sldsubbtn1,'Position',[53 212 20 20])
      set(sldsubbtn1,'Text','<');
      set(sldsubbtn1,'ButtonPushedFcn',{@obj.subtract_Callback obj.fig 'lvslider' 'sldlblval1'})

      %--------------------------------------------
        % Number of splits
      %--------------------------------------------

      % Create SliderLabel
      sldlbl2 = uilabel(pnl2);
      set(sldlbl2,'Position',[71 153 95 22]);
      set(sldlbl2,'Text','Number of Splits');
      
      % Create min splits label
      sldminlbl2 = uilabel(pnl2);
      set(sldminlbl2,'Text','1');
      set(sldminlbl2,'Position',[40 133 34 22]);

      % Create Slider
      sld2 = uislider(pnl2);
      set(sld2,'Position',[77 139 198 3]);
      set(sld2,'Tag','spltslider');
      set(sld2,'ValueChangedFcn',{@obj.sld_Callback obj.fig 'sldlblval2'});

      % Create Slider label value
      sldlblval2 = uilabel(pnl2);
      set(sldlblval2,'Position',[280 153 34 22]);
      set(sldlblval2,'Text',num2str(lastcvoptions.cvi{2}));
      set(sldlblval2,'Tag','sldlblval2');

      % Create maximum label for number of splits
      sldmaxlbl2 = uilabel(pnl2);
      set(sldmaxlbl2,'Position',[303 133 34 22]);
      set(sldmaxlbl2,'Text','max');
      set(sldmaxlbl2,'Tag','sldmaxlbl2');

      % Add button
      sldaddbtn2 = uibutton(pnl2,'push');
      set(sldaddbtn2,'Position',[280 133 20 20]);
      set(sldaddbtn2,'Text','>');
      set(sldaddbtn2,'ButtonPushedFcn',{@obj.add_Callback obj.fig 'spltslider' 'sldlblval2'});

      % Subtract button
      sldsubbtn2 = uibutton(pnl2,'push');
      set(sldsubbtn2,'Position',[53 133 20 20])
      set(sldsubbtn2,'Text','<');
      set(sldsubbtn2,'ButtonPushedFcn',{@obj.subtract_Callback obj.fig 'spltslider' 'sldlblval2'})

      %--------------------------------------------
        % Samples per blind/Iter
      %--------------------------------------------

      % Create SliderLabel
      sldlbl3 = uilabel(pnl2);
      set(sldlbl3,'Position',[72 73 167 22]);
      if strcmpi(lastcvoptions.method,'venetian blinds')
        set(sldlbl3,'Text','Samples per Blind (Thickness)');
      else
        set(sldlbl3,'Text','Iterations');
      end
      set(sldlbl3,'Tag','thirdsliderlabel');  % make this changeable depending on cv method
      
      % Create min label for number of splits
      sldminlbl3 = uilabel(pnl2);
      set(sldminlbl3,'Position',[40 51 34 22]);
      set(sldminlbl3,'Text','1');

      % Create maximum label for number of splits
      sldmaxlbl2 = uilabel(pnl2);
      set(sldmaxlbl2,'Position',[303 51 34 22]);
      set(sldmaxlbl2,'Text','max');
      set(sldmaxlbl2,'Tag','sldmaxlbl3');

      % Create Slider
      sld3 = uislider(pnl2);
      set(sld3,'Position',[77 61 198 3]);
      set(sld3,'Tag','spbslider');
      set(sld3,'ValueChangedFcn',{@obj.sld_Callback obj.fig 'sldlblval3'});

      % Create current slider value label
      sldlblval3 = uilabel(pnl2);
      set(sldlblval3,'Position',[280 73 34 22]);
      set(sldlblval3,'Text',num2str(lastcvoptions.cvi{3}));
      set(sldlblval3,'Tag','sldlblval3');

      % Add button
      sldaddbtn3 = uibutton(pnl2,'push');
      set(sldaddbtn3,'Position',[280 55 20 20]);
      set(sldaddbtn3,'Text','>');
      set(sldaddbtn3,'ButtonPushedFcn',{@obj.add_Callback obj.fig 'spbslider' 'sldlblval3'});

      % Subtract button
      sldsubbtn3 = uibutton(pnl2,'push');
      set(sldsubbtn3,'Position',[53 55 20 20])
      set(sldsubbtn3,'Text','<');
      set(sldsubbtn3,'ButtonPushedFcn',{@obj.subtract_Callback obj.fig 'spbslider' 'sldlblval3'})


      %--------------------------------------------
        % Action buttons in bottom panel
         % Apply
         % Reset
         % OK
         % Close
      %--------------------------------------------


      % Create Panel3
      pnl3 = uipanel(obj.fig);
      set(pnl3,'Position',[14 12 618 65]);

      % Create GridLayout
      g3 = uigridlayout(pnl3);
      set(g3,'ColumnWidth',{'1x', '1x', '1x', '1x'});
      set(g3,'RowHeight',{'1x'});

      % Create Apply button
      applybtn = uibutton(g3, 'push');
      set(applybtn,'Text','Apply');
      set(applybtn,'Enable','off');
      set(applybtn,'Tag','applybtn');
      set(applybtn,'ButtonPushedFcn',{@obj.applybtn_Callback obj.fig});

      % Create Reset button
      resetbtn = uibutton(g3, 'push');
      set(resetbtn,'Text','Reset');
      set(resetbtn,'Enable','off');
      set(resetbtn,'Tag','resetbtn');
      set(resetbtn,'ButtonPushedFcn',{@obj.reset_Callback obj.fig});


      % Create OK button
      okbtn = uibutton(g3, 'push');
      set(okbtn,'Text','OK');
      set(okbtn,'Enable','off');
      set(okbtn,'Tag','okbtn');
      set(okbtn,'ButtonPushedFcn',{@obj.okbtn_Callback obj.fig});


      % Create Close button
      cclbtn = uibutton(g3, 'push');
      set(cclbtn,'Text','Close');
      set(cclbtn,'ButtonPushedFcn',{@obj.cancel_Callback obj.fig});


      %--------------------------------------------
        % Custom CV Panel
      %--------------------------------------------

      % Create Panel4
      pnl4 = uipanel(obj.fig);
      set(pnl4,'Position',[15 259 260 112]);

      % Create Load Custom CVI vector button
      loadbtn = uibutton(pnl4, 'push');
      set(loadbtn,'ButtonPushedFcn',{@obj.load_Callback obj.fig});
      set(loadbtn,'Position',[81 58 100 23]);
      set(loadbtn,'Text','Load...');
      set(loadbtn,'Enable','off');
      set(loadbtn,'Tag','loadbtn');

      % Create Class Set button
      selcsbtn = uibutton(pnl4, 'push');
      set(selcsbtn,'ButtonPushedFcn',{@obj.selcs_Callback obj.fig});
      set(selcsbtn,'Position',[81 15 100 23]);
      set(selcsbtn,'Text','Select Class Set...');
      set(selcsbtn,'Enable','off');
      set(selcsbtn,'Tag','selcsbtn');
      

      % Create Help button
      hlpbtn = uibutton(obj.fig, 'push');
      set(hlpbtn,'Position',[94 192 100 23]);
      set(hlpbtn,'Text','Help');
      set(hlpbtn,'ButtonPushedFcn',{@obj.help_Callback obj.fig});

      % Adjust the values on the sliders depending on information from the
      % xblock
      obj.fig = obj.adjustSliders();

      % Show the figure after all components are created
      set(obj.fig,'Visible','on');
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = adjustSliders(varargin)
      obj = varargin{1};
      fig = obj.fig;
      nsamps = size(obj.x,1);
      lastcvoptions = getappdata(fig,'lastcvoptions');
      % Get rank
      if isdataset(obj.x)
        r = rank(obj.x.data);
      else
        r = rank(obj.x);
      end
      val = min(r,20);

      % Adjust LVs slider
      sld1 = findall(fig,'Tag','lvslider');
      if r > 1
        set(sld1,'Limits',[1 val]);
        set(sld1,'MajorTicks',[]);
        
        curval = min(val,lastcvoptions.maxlvs);
      else
        %TODO: Test this
        curval = 1;
      end
      set(sld1,'MinorTicks',[]);
      set(sld1,'Value',curval);
      sld1lblval = findall(fig,'Tag','sldlblval1');
      set(sld1lblval,'Text',num2str(curval));
      setappdata(fig,'sldlblval1',curval);
      sldmaxlbl1 = findall(fig,'Tag','sldmaxlbl1');
      set(sldmaxlbl1,'Text',num2str(val));


      % Adjust splits slider
      sld2 = findall(fig,'Tag','spltslider');
      if floor(nsamps/2)>2
        smax = min(100,floor(nsamps/2));
      else
        smax = 2;
      end
      if smax > 10
        curval = lastcvoptions.cvi{2};
      else
        curval = floor(smax/2);
      end
      set(sld2,'MajorTicks',[]);
      set(sld2,'Limits',[1,smax]);
      set(sld2,'MinorTicks',[]);
      set(sld2,'Value',curval);
      sld2lblval = findall(fig,'Tag','sld2lblval');
      set(sld2lblval,'Text',num2str(curval));
      setappdata(fig,'sldlblval2',curval);
      sldmaxlbl2 = findall(fig,'Tag','sldmaxlbl2');
      set(sldmaxlbl2,'Text',num2str(smax));


      % Adjust iterations slider
      sld3 = findall(fig,'Tag','spbslider');
      set(sld3,'Limits',[1,10]);
      set(sld3,'MajorTicks',[]);
      set(sld3,'MinorTicks',[]);
      set(sld3,'Value',lastcvoptions.cvi{3});
      sld3lblval = findall(fig,'Tag','sld3lblval');
      set(sld3lblval,'Text',num2str(1));
      setappdata(fig,'sldlblval3',1);
      sldmaxlbl3 = findall(fig,'Tag','sldmaxlbl3');
      set(sldmaxlbl3,'Text',num2str(10));
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = method_Callback(varargin)
      fig = varargin{4};
      val = get(varargin{2},'Value');
      setappdata(fig,'method',val);
      if isequal(val,'custom')
        % need to enable the 'load' and 'select class set button'
        ldbtn = findall(fig,'Tag','loadbtn');
        set(ldbtn,'Enable','on');
        selcsbtn = findall(fig,'Tag','selcsbtn');
        set(selcsbtn,'Enable','on');
      else
        % turn these off
        ldbtn = findall(fig,'Tag','loadbtn');
        set(ldbtn,'Enable','off');
        selcsbtn = findall(fig,'Tag','selcsbtn');
        set(selcsbtn,'Enable','off');
      end
      
      % change label on third slider properly
      thirdsliderlabel = findall(fig,'Tag','thirdsliderlabel');
      if isequal(val,'venetian blinds')
        set(thirdsliderlabel,'Text','Samples per Blind (Thickness)');
      else
        set(thirdsliderlabel,'Text','Iterations');
      end

      % Enable Apply, Reset, and OK buttons
      applybtn = findall(fig,'Tag','applybtn');
      set(applybtn,'Enable','on');
      resetbtn = findall(fig,'Tag','resetbtn');
      set(resetbtn,'Enable','on');
      okbtn = findall(fig,'Tag','okbtn');
      set(okbtn,'Enable','on');
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = sld_Callback(varargin)
      fig = varargin{4};
      tag = varargin{5};
      % adjust the slider so it falls on integer
      set(varargin{2},'Value',double(int64(get(varargin{2},'Value'))));
      lbl = findobj(fig,'Tag',tag);
      set(lbl,'Text',num2str(get(varargin{2},'Value')));
      setappdata(fig,tag,get(varargin{2},'Value'));

      % Enable Apply, Reset, and OK buttons
      applybtn = findall(fig,'Tag','applybtn');
      set(applybtn,'Enable','on');
      resetbtn = findall(fig,'Tag','resetbtn');
      set(resetbtn,'Enable','on');
      okbtn = findall(fig,'Tag','okbtn');
      set(okbtn,'Enable','on');
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = load_Callback(varargin)
      fig = varargin{4};
      obj = varargin{1};
      [rawdata, name, ~] = lddlgpls({'dataset' 'double'}, 'Locate vector of custom cross-validation sets');
      if isdataset(rawdata)
        rawdata = rawdata.data.include;
      end
      rawdata = rawdata(:)';  %vectorize
      sizecheck = size(obj.x,1);
      if sizecheck==length(rawdata)
        setappdata(fig,'customcvi',rawdata);
        set(varargin{2},'BackgroundColor',[0.5647 0.9333 0.5647]);
        set(varargin{2},'Tooltip',name);
      else
        evriwarndlg('Custom cross-validation set length does not match X block length - cross-validation reset to last good conditions','Cross-validation reset');

      end
      
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = selcs_Callback(varargin)
      fig = varargin{4};
      obj = varargin{1};
      if isdataset(obj.x)
        classes = cell(1,size(obj.x.classname,2));
        for i=1:size(obj.x.classname,2);
          classes{1,i} = obj.x.classname{1,i};
        end
        myset = listdlg('PromptString','Select Class Set:','SelectionMode','Single','liststring',classes);
        cv = obj.x.class{1,myset};
        set(varargin{2},'BackgroundColor',[0.5647 0.9333 0.5647]);
        set(varargin{2},'Tooltip',obj.x.classname{1,myset});
        % revert color of load... button
        btn = findall(fig,'Tag','loadbtn');
        set(btn,'BackgroundColor',[0.9600 0.9600 0.9600]);
        setappdata(fig,'customcvi',cv);
      else
        evriwarndlg('No classes found in the XBlock.');
      end
    end

    %--------------------------------------------------------------------------------------------------------

    function [obj] = okbtn_Callback(varargin)
      % save settings and assign 1 to UserData to indicate completion
      fig = varargin{4};
      obj = varargin{1};
      handles = getappdata(fig);
      lastcvoptions = getappdata(fig,'lastcvoptions');
      if ~isfield(handles,'customcvi')
        translate = {
                   'none','none';
                    'loo','leave one out';
                    'vet','venetian blinds';
                    'con','contiguous blocks';
                    'rnd','random subsets';
                    'custom','custom'};
        method = translate{find(ismember(translate(:,2),handles.method)),1};
        splits = handles.sldlblval2;
        iter   = handles.sldlblval3;
        obj.cv.cvi = {method splits iter};
      else
        method = 'custom';
        obj.cv.cvi = handles.customcvi;
      end
      maxlvs = handles.sldlblval1;
      obj.cv.method = handles.method;
      obj.cv.maxlvs = maxlvs;
      set(fig,'UserData',1);
      setappdata(fig,'cvi',obj.cv.cvi);
      setappdata(fig,'maxlvs',obj.cv.maxlvs);
    end

    %--------------------------------------------------------------------------------------------------------

    function [obj] = applybtn_Callback(varargin)
      % turn off buttons, overwrite the lastcvoptions with what's currently
      % in the figure
      fig = varargin{4};
      obj = varargin{1};

      % Enable Apply, Reset, and OK buttons
      applybtn = findall(fig,'Tag','applybtn');
      set(applybtn,'Enable','off');
      resetbtn = findall(fig,'Tag','resetbtn');
      set(resetbtn,'Enable','off');
      okbtn = findall(fig,'Tag','okbtn');
      set(okbtn,'Enable','off');

      % Save new cvoptions
      handles = getappdata(fig);
      lastcvoptions = getappdata(fig,'lastcvoptions');
      translate = {
                   'none','none';
                    'loo','leave one out';
                    'vet','venetian blinds';
                    'con','contiguous blocks';
                    'rnd','random subsets'};
      method = translate{find(ismember(translate(:,2),handles.method)),1};
      lastcvoptions.maxlvs = handles.sldlblval1;
      lastcvoptions.cvi{1} = method;
      lastcvoptions.cvi{2} = handles.sldlblval2;
      lastcvoptions.cvi{3} = handles.sldlblval3;
      lastcvoptions.method = handles.method;
      setappdata(fig,'lastcvoptions',lastcvoptions);
      setappdata(fig,'sldlblval1',lastcvoptions.maxlvs);
      setappdata(fig,'sldlblval2',lastcvoptions.cvi{2});
      setappdata(fig,'sldlblval3',lastcvoptions.cvi{3});

      maxlvs = handles.sldlblval1;
      splits = handles.sldlblval2;
      iter   = handles.sldlblval3;
      obj.cv.cvi = {method splits iter};
      obj.cv.method = handles.method;
      obj.cv.maxlvs = maxlvs;
      setappdata(fig,'cvi',obj.cv.cvi);
      setappdata(fig,'maxlvs',obj.cv.maxlvs);
    end

    %--------------------------------------------------------------------------------------------------------

    function [] = cancel_Callback(varargin)
      % Close window
      fig = varargin{4};
      set(fig,'UserData',1);
    end

    %--------------------------------------------------------------------------------------------------------

    function [] = help_Callback(varargin)
      % open web link to wiki url
      evrihelp('using_cross_validation')
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = add_Callback(varargin)
      % dependent on the slider, the current label to change
      fig = varargin{4};
      slider = varargin{5};
      lbl = varargin{6};
      sliderh = findall(fig,'Tag',slider);
      lblh = findall(fig,'Tag',lbl);
      newval = get(sliderh,'Value') + 1;
      lim = get(sliderh,'Limits');
      if(newval > lim(2))
        % slider is above upper limit, don't wanna change anything here, invalid input
      else
        newlbl = num2str(newval);
        set(sliderh,'Value',newval);
        set(lblh,'Text',newlbl);
        setappdata(fig,lbl,newval);
        
        % Enable Apply, Reset, and OK buttons
        applybtn = findall(fig,'Tag','applybtn');
        set(applybtn,'Enable','on');
        resetbtn = findall(fig,'Tag','resetbtn');
        set(resetbtn,'Enable','on');
        okbtn = findall(fig,'Tag','okbtn');
        set(okbtn,'Enable','on');
      end
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = subtract_Callback(varargin)
      % dependent on the slider, the current label to change
      fig = varargin{4};
      slider = varargin{5};
      lbl = varargin{6};
      sliderh = findall(fig,'Tag',slider);
      lblh = findall(fig,'Tag',lbl);
      newval = get(sliderh,'Value') - 1;
      lim = get(sliderh,'Limits');
      if(newval < lim(1))
        % slider is below lower limit, don't wanna change anything here, invalid input
      else
        newlbl = num2str(newval);
        set(sliderh,'Value',newval);
        set(lblh,'Text',newlbl);
        setappdata(fig,lbl,newval);

        % Enable Apply, Reset, and OK buttons
        applybtn = findall(fig,'Tag','applybtn');
        set(applybtn,'Enable','on');
        resetbtn = findall(fig,'Tag','resetbtn');
        set(resetbtn,'Enable','on');
        okbtn = findall(fig,'Tag','okbtn');
        set(okbtn,'Enable','on');
      end
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = reset_Callback(varargin)
      fig = varargin{4};
      lastcvoptions = getappdata(fig,'lastcvoptions');

      % Need to reset dropdown value
      ddwn = findall(fig,'Tag','methoddropdown');
      set(ddwn,'Value',lastcvoptions.method);
      setappdata(fig,'method',lastcvoptions.method);
      
      % Need to reset the Slider labels and Slider values
      % max lvs slider
      lvslider = findall(fig,'Tag','lvslider');
      set(lvslider,'Value',lastcvoptions.maxlvs);
      %max lvs label
      sldlblval1 = findall(fig,'Tag','sldlblval1');
      set(sldlblval1,'Text',num2str(lastcvoptions.maxlvs));
      setappdata(fig,'sldlblval1',lastcvoptions.maxlvs);
      % splits slider
      spltslider = findall(fig,'Tag','spltslider');
      set(spltslider,'Value',lastcvoptions.cvi{2});
      % splits label
      sldlblval2 = findall(fig,'Tag','sldlblval2');
      set(sldlblval2,'Text',num2str(lastcvoptions.cvi{2}));
      setappdata(fig,'sldlblval2',lastcvoptions.cvi{2});
      % iter slider
      spbslider = findall(fig,'Tag','spbslider');
      set(spbslider,'Value',lastcvoptions.cvi{3});
      % iter label
      sldlblval3 = findall(fig,'Tag','sldlblval3');
      set(sldlblval3,'Text',num2str(lastcvoptions.cvi{3}));
      setappdata(fig,'sldlblval3',lastcvoptions.cvi{3});
    end
  end
end
