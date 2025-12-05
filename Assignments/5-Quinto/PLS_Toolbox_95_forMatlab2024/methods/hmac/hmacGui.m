classdef hmacGui
  %HMACGUI Interface to build Hmac models in Modelselectorgui.
  % This interface is available from the Modelselectorgui, but can also be
  % called from the command line. Build hierarchical models using the Hmac
  % function. Hierarchical Model Builder canvas gets populated by the
  % resulting model.
  %
  %  OUTPUT:
  %       hmacGui  = object of this class.
  %
  %I/O: [hmacgui]         = hmacGui();                    % instantiate object of this class.
  %I/O: [model]           = getappdata(hmacgui.fig,'model');   % get calibrated hierarchical model
  %
  %See also: HMACCVGUI, AUTOCLASSIFER, MERGELEASTSEPARABLE, GETMISCLASSIFICATION, GETPAIRMISCLASSIFICATION, MODELSELECTOR, CROSSVAL, PLSDA

  % Copyright © Eigenvector Research, Inc. 2022
  % Licensee shall not re-compile, translate or convert "M-files" contained
  %  in PLS_Toolbox for use with any software other than MATLAB®, without
  %  written permission from Eigenvector Research, Inc.


  properties
    fig     % Gui for hierarchical model classifier
    model   % Calibrated hierachical classification model
  end

  methods
    function obj = hmacGui()
      % Class constructor
      obj.model = [];
      % Initialize interface
      obj = obj.createGui();
    end
    function obj = createGui(obj)
      % Open in center of screen
      sz = get(0,'ScreenSize');
      width = 410;
      height = 282;
      x = mean(sz([1 3]));
      y = mean(sz([2 4]));
      obj.fig = uifigure('Visible', 'off');
      set(obj.fig,'Position',[x - width/2 y - height/2 width height]);
      set(obj.fig,'Name','Automatic Classifier Settings')

      % Put in panel for settings
      p = uipanel(obj.fig,'Position',[56 73 301 200]);

      % Assemble grid
      g = uigridlayout(p);
      set(g,'RowHeight',{'1x', '1x', '1x', '1x', '1x' '1x'});

      %--------------------------------------------
        % XBlock
      %--------------------------------------------

      % Create XBlock label
      xlbl = uilabel(g,'HorizontalAlignment','center');
      set(xlbl,'Text','XBlock');

      % Create XBlock Load button
      loadxbtn = uibutton(g, 'push');
      set(loadxbtn,'ButtonPushedFcn', {@obj.loadx_Callback obj.fig});
      set(loadxbtn,'Text','Load');
      set(loadxbtn,'Tooltip','Load in a Dataset or matrix')
      set(loadxbtn,'Tag','loadxbtn');

      %--------------------------------------------
        % Classes
      %--------------------------------------------

      % Create Classes label
      clbl = uilabel(g,'HorizontalAlignment','center');
      set(clbl,'Text','Classes');

      % Create Load Classes button
      loadybtn = uibutton(g, 'push');
      set(loadybtn,'ButtonPushedFcn', {@obj.loady_Callback obj.fig});
      set(loadybtn,'Text','Load');
      set(loadybtn,'Tooltip','Load in a Dataset or matrix');
      set(loadybtn,'Tag','loadybtn');

      %--------------------------------------------
        % Class Set
      %--------------------------------------------

      % Create Classset label
      cslbl = uilabel(g,'HorizontalAlignment','center');
      set(cslbl,'Text','Class Set');

      % Create Classset field
      csfld = uidropdown(g);
      set(csfld,'Items',{'1'});
      set(csfld,'Enable','off')  % will be editable once X is loaded and is dataset
      set(csfld,'ValueChangedFcn',{@obj.loadcls_Callback obj.fig});
      set(csfld,'Tag','csfld');

      %--------------------------------------------
        % Cross-Validation
      %--------------------------------------------

      % Create Cross-Validation label
      cvlbl = uilabel(g,'HorizontalAlignment','center');
      set(cvlbl,'Text','Cross-Validation');

      % Create Cross-Validation button
      loadcvobtn = uibutton(g, 'push');
      set(loadcvobtn,'ButtonPushedFcn', {@obj.loadcvopts_Callback obj.fig});
      set(loadcvobtn,'Text','Set');
      set(loadcvobtn,'Tooltip','Open Cross-Validation Settings (Venetian Blinds is default)');
      set(loadcvobtn,'Enable','off'); % will be editable once X is loaded
      set(loadcvobtn,'Tag','loadcvobtn');

      %--------------------------------------------
        % Preprocessing
      %--------------------------------------------

      % Create Preprocessing label
      pplbl = uilabel(g,'HorizontalAlignment','center');
      set(pplbl,'Text','Preprocessing');

      % Creating Preprocessing button
      loadppbtn = uibutton(g, 'push');
      set(loadppbtn,'ButtonPushedFcn', {@obj.loadpp_Callback obj.fig});
      set(loadppbtn,'Text','Set');
      set(loadppbtn,'Tag','loadppbtn');
      pp = Hmac().getOptions.cvopts.preprocessing{1};
      setappdata(obj.fig,'ppoptions',pp);
      desc = arrayfun(@(a) a.keyword,pp,'UniformOutput',false);
      set(loadppbtn,'Tooltip',['Open Preprocessing Settings';'Default:';desc]);

      % Create Output Filter label
      oflbl = uilabel(g,'HorizontalAlignment','center');
      set(oflbl,'Text','Set Output Filter')

      % Create Output Filter dropdown
      ofdrpwn = uidropdown(g);
      set(ofdrpwn,'Items',{'Model' 'String'});
      set(ofdrpwn,'ValueChangedFcn',{@obj.outputfilter_Callback obj.fig});
      setappdata(obj.fig,'outputfilter','model');

      
      %--------------------------------------------
        % Action buttons
      %--------------------------------------------

      % Create Cancel button
      cclbtn = uibutton(obj.fig,'push','Position',[305 5 100 23]);
      set(cclbtn,'Text','Cancel')
      set(cclbtn,'ButtonPushedFcn',{@obj.cancel_Callback obj.fig})
      set(cclbtn,'Tag','cclbtn');

      % Create Calibrate button
      calclbtn = uibutton(obj.fig,'push','Position',[204 5 100 23]);
      set(calclbtn,'Text','Calibrate')
      set(calclbtn,'ButtonPushedFcn',{@obj.calibrate_Callback obj.fig});
      set(calclbtn,'Tag','calclbtn');

      % Create Help button
      hlpbtn = uibutton(obj.fig,'push','Position',[5 5 100 23]);
      set(hlpbtn,'Text','Help');
      set(hlpbtn,'ButtonPushedFcn', {@obj.help_Callback obj.fig});
      set(hlpbtn,'Tag','helpbtn');

      % Turn on visibility
      set(obj.fig,'Visible','on')
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = loadx_Callback(varargin)
      % Load XBlock and color button
      obj = varargin{1};
      fig = varargin{4};
      [rawdata,name, ~] = lddlgpls({'dataset' 'double'}, 'Load XBLOCK Data');
      drawnow;
      figure(fig)
      if ~isempty(rawdata)
        setappdata(fig,'x',rawdata)
        set(varargin{2},'BackgroundColor',[0.5647 0.9333 0.5647]);
        set(varargin{2},'Tooltip',name);
        if isdataset(rawdata)
          if ~isempty(rawdata.class{1,1})
            % Classes detected in XBlock, color in Classes button
            yclassbtn = findobj(fig,'Tag','loadybtn');
            set(yclassbtn,'BackgroundColor',[0.5647 0.9333 0.5647]);
            set(yclassbtn,'Tooltip',['Classes detected in ' name ' data, switch between class sets by editing the ''Class Set'' dropdown menu. Alternatively, load in a dataset or matrix here.']);
            % Classset dropdown
            dropdwn = findobj(fig,'Tag','csfld');
            nclasses = size(rawdata.class,2);
            % Insert classsets as items in classsets dropdown menu
            %either insert classname or just use a number to indicate index
            %of classset
            for i=1:nclasses
              itmsData{i} = i;
              if ~isempty(rawdata.classname{1,i})
                itms{i} = rawdata.classname{1,i};
              else
                itms{i} = ['Class Set ' num2str(i)];
              end
            end
            itms{end+1} = 'Select Class Group';
            itmsData{end+1} = 'Select Class Group';
            setappdata(fig,'classset',1);
            set(dropdwn,'Items',itms);
            set(dropdwn,'ItemsData',itmsData);
            set(dropdwn,'Enable','on');
          end
        end
        % turn on cv button
        loadcvobtn = findall(fig,'Tag','loadcvobtn');
        set(loadcvobtn,'Enable','on');
      end
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = loady_Callback(varargin)
      % Load YBlock and color button
      fig = varargin{4};
      drawnow;
      [rawdata,name, ~] = lddlgpls({'dataset' 'double'}, 'Load YBLOCK Data');

      figure(fig)
      if ~isempty(rawdata)
        setappdata(fig,'y',rawdata)
        set(varargin{2},'BackgroundColor',[0.5647 0.9333 0.5647])
        set(varargin{2},'Tooltip',name);
      end
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = loadcls_Callback(varargin)
      % Set Classset field and save information
      fig = varargin{4};
      val = get(varargin{2},'Value');
      cls = getappdata(fig,'classset');
      if ~isequal(val,'Select Class Group')
        % user select specific classset index
        setappdata(fig,'classset',val);
        % override the y to be empty to use classset index in xblock
        setappdata(fig,'y',[]);
      else
        % spawn plsdagui to create class grouping
        x = getappdata(fig,'x');
        [groups, ~, dso] = plsdagui(x, [], cls, '');
        % perform following if user actually provided a grouping
        if ~isequal(groups,0)
          if ~isempty(dso)
            % use this as new data and indicate the new groupings as the
            % classset to be used.
            setappdata(fig,'x',dso);
            % add class grouping to dropdown menu
            itms = get(varargin{2},'Items');
            itmsdata =  get(varargin{2},'ItemsData');
            itms{end} = dso.classname{1,end};
            newcls = num2str(length(itms));
            itmsdata{end} = newcls;
            itms{end+1} = 'Select Class Group';
            itmsdata{end+1} = 'Select Class Group';
            set(varargin{2},'Items',itms);
            set(varargin{2},'Itemsdata',itmsdata);
            set(varargin{2},'Value',itmsdata{end-1});
            setappdata(fig,'classset',newcls);
          else
            % map the groupings
            [class,nonzero] = class2logical(x,groups,1); %create y-block from x
            %           if ~isempty(class) && isempty(groups) && size(class,2)==1 && length(nonzero)<size(class,1)
            %             groups = {0 class.class{2}};
            %             [class,~] = class2logical(varargin{1},groups,options.classset); %create y-block from x
            %           end
            %           if ~isempty(class)
            %             class.include{1} = x.include{1};
            %           end
            % add to dropdown menu
            x.class{1,end+1} = logical2class(class.data);
            setappdata(fig,'x',x);
            itms = get(varargin{2},'Items');
            itmsdata =  get(varargin{2},'ItemsData');
            itms{end} = 'Custom grouping';
            newcls = num2str(length(itms));
            itmsdata{end} = newcls;
            itms{end+1} = 'Select Class Group';
            itmsdata{end+1} = 'Select Class Group';
            set(varargin{2},'Items',itms);
            set(varargin{2},'Itemsdata',itmsdata);
            set(varargin{2},'Value',itmsdata{end-1});
            setappdata(fig,'classset',str2num(newcls));
          end
        else
          % user did not provide a grouping, reset to last class set
          itmsdata = get(varargin{2},'ItemsData');
          set(varargin{2},'Value',itmsdata{cls});
        end
      end
      drawnow;
      figure(fig)
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = loadcvopts_Callback(varargin)
      % if open, just bring it to front
      figs = findall(groot,'type','figure');
      cvloc = arrayfun(@(x) isequal(x.Tag,'HmacCV'),figs);
      if any(cvloc)
        figure(figs(find(cvloc)));
        return;
      end
      
      % Load in Cross-Validation settings and save information
      obj = varargin{1};
      fig = varargin{4};
      x = getappdata(fig,'x');
      cvoptions = getappdata(fig','cvoptions');
      hmaccvgui = hmacCvGui(x,mfilename,cvoptions);
      cvhandle = hmaccvgui.fig;
      % wait until cv settings are completed or gui is closed
      waitfor(cvhandle,'UserData',1)
      if ishandle(cvhandle)
        cvi = getappdata(cvhandle,'cvi');
        maxlvs = getappdata(cvhandle,'maxlvs');
        method = getappdata(cvhandle,'method');
        cvoptions.cvi = cvi;
        cvoptions.maxlvs = maxlvs;
        cvoptions.method = method;
        setappdata(fig,'cvoptions',cvoptions);
        delete(cvhandle);
        set(varargin{2},'BackgroundColor',[0.5647 0.9333 0.5647]);
        set(varargin{2},'Tooltip',method);
      end
      if ishandle(fig)
        drawnow;
        figure(fig)
      end
    end

    %--------------------------------------------------------------------------------------------------------

    function [fig] = loadpp_Callback(varargin)
      % Load in Preprocessing settings and save information
      fig = varargin{4};
      x = getappdata(fig,'x');
      % if preprocessing was specified already, open up Preprocess window
      % with that preprocessing setup
      ppoptions = getappdata(fig,'ppoptions');
      if ~isempty(x)
        [~, pp] = preprocess(x,ppoptions);
      else
        pp = preprocess(x,ppoptions);
      end
      setappdata(fig,'ppoptions',pp);
      if ~isempty(pp)
        set(varargin{2},'BackgroundColor',[0.5647 0.9333 0.5647]);
        set(varargin{2},'Tooltip',arrayfun(@(a) a.keyword,pp,'UniformOutput',false));
      else
        % no preprocessing? revert to default settings
        set(varargin{2},'BackgroundColor',[1 1 1]);
        set(varargin{2},'Tooltip','Open Preprocessing Settings');
      end
      drawnow;
      figure(fig);
    end

    %--------------------------------------------------------------------------------------------------------

    function [] = cancel_Callback(varargin)
      % Close window
      fig = varargin{4};
      % if Hmac CV Gui is still open, kill it as well
      h = findall(groot,'Type','Figure','Name','Cross-Validation Settings');
      if ~isempty(h)
        delete(h);
      end
      delete(fig);
    end

    %--------------------------------------------------------------------------------------------------------

    function [obj] = calibrate_Callback(varargin)
      % Perform classification with Hmac object, save finished model
      fig = varargin{4};

      x          = getappdata(fig,'x');
      y          = getappdata(fig,'y');
      cvoptions  = getappdata(fig,'cvoptions');
      ppoptions  = getappdata(fig,'ppoptions');
      classset   = getappdata(fig,'classset');
      outputfilter = getappdata(fig,'outputfilter');

      % instantiate hmac object
      hmac = Hmac();

      if ~isempty(x)
        hmac.setX(x);
      else
        set(varargin{2},'Enable','on')
        uiresume;
        uialert(fig,'XBlock data is missing','Missing Data');
        figure(fig)
        return
      end

      options = hmac.getOptions();
      if ~isempty(classset)
        if ~isnumeric(classset)
          classset = str2double(classset);
        end
        options.classset = classset;
      end

      if ~isempty(cvoptions)
        options.cvi = cvoptions.cvi;
        options.maxlvs = cvoptions.maxlvs;
      end

      if ~isempty(ppoptions)
        options.cvopts.preprocessing{1} = ppoptions;
      end

      options.outputfilter = outputfilter;


      icon = gettbicons('image_tree');
      d = uiprogressdlg(fig,'Message','Calibrating Model','Indeterminate','on','Icon',icon,'Cancelable','on','CancelText','Close to Cancel');
      % set the options
      % pass progressdlg to add cancel ability
      options.prog = d;
      hmac.setOptions(options);

      % if y is set, Hmac will use it and override any class set
      % information
      if ~isempty(y)
        hmac.setY(y);
      end
      
      try
        % try to build model and upload to canvas
        hmac = hmac.calibrate;
        close(d);
        setappdata(fig,'model',hmac.model);
        obj.model = hmac.model;
        set(fig,'UserData',1);
        modelselectorgui(hmac.model);
        set(fig,'Visible','off');
      catch E
        % cancel requested? just turn off progressdlg and leave window open
        if d.CancelRequested
          close(d);
          set(varargin{2},'Enable','on');
        else
          close(d);
          uialert(fig,E.message,'Calibration Error');
          figure(fig);
          uiresume;
        end
      end
    end

    %--------------------------------------------------------------------------------------------------------

    function [a] = help_Callback(varargin)
      % open web link to wiki url
      a = web('https://www.wiki.eigenvector.com/index.php?title=Hierarchical_Model_Builder#Automatic_Hierarchical_Model_Classification','-browser');
    end

    %--------------------------------------------------------------------------------------------------------

    function [obj] = outputfilter_Callback(varargin)
      obj = varargin{1};
      drpdwn = varargin{2};
      fig = varargin{4};
      setappdata(fig,'outputfilter',lower(drpdwn.Value));
    end
  end
end

%--------------------------------------------------------------------------------------------------------
function [y] = logical2class(x)
  % help function to convert a logical matrix of classes to a 1xn vector of
  % classes
  % this is used when a class grouping is created and the matrix is created
  % by class2logical, but the matrix needs to be mapped back to a vector of
  % classes in order to be stored in the x.class field
  y = nan(size(x,1),1);
  for i=1:length(y)
    cls = find(x(i,:)==1);
    if isempty(cls)
      y(i) = 0;
    else
      y(i) = cls;
    end
  end
end

%--------------------------------------------------------------------------------------------------------

