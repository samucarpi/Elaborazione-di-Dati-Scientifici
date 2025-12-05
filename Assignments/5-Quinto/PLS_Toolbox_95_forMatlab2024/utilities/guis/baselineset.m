function pp = baselineset(varargin);
%BASELINESET GUI to choose baseline settings for Preprocess
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied or p is 'default', default structure is returned
% without GUI.
%
%I/O:   p = wlsbaselineset(p)
% (or)  p = wlsbaselineset('default')
%
%See also: PREPROCESS, BASELINE

%Copyright Eigenvector Research 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 10/07

%-------------------------------------------------------
%generate default preprocessing structure and return
if nargin==0 || (~isstruct(varargin{1}) && strcmp(varargin{1},'default'))
  pp = [];
  pp.description = 'Baseline (Specified points)';
  pp.calibrate = { '[data,out{1}] = baseline(data,userdata.range,userdata);' };
  pp.apply = { '[data,out{1}] = baseline(data,userdata.range,userdata);' };
  pp.undo = { '[data] = baseline(data,out{1},userdata);' };
  pp.out = {};
  pp.settingsgui = 'baselineset';
  pp.settingsonadd = 1;
  pp.usesdataset = 1;
  pp.caloutputs = 0;
  pp.keyword = 'simple baseline';
  pp.category = 'Filtering';
  pp.tooltip = 'Simple region-based baseline removal.';
  pp.userdata = baseline('options');
  pp.userdata.range = [];
  return
end

%-------------------------------------------------------
%callback to superimpose baseline on current plot
if ischar(varargin{1}) 
  
  switch varargin{1}
    case 'plotcommand_callback'
      %find data and superimpose baseline (first spectrum only)
      fig = varargin{2};

      data = findobj(allchild(gca),'userdata','data');
      xdata = get(data,'xdata');
      if iscell(xdata)
        xdata = xdata{1};
      end
      ydata = get(data,'ydata');
      if iscell(ydata)
        ydata = ydata{1};
      end
      ydata = ydata(1,:);
      range = getselection(fig);
      if ~isempty(range)
        %range = range{2};
      else
        range = [];
      end
      if isempty(range)
        range = 1:length(xdata);
      end
      order = getappdata(fig,'order');

      %calculate baseline and show
      wrn = warning('off');
      fit = polyfit(xdata(range),ydata(range),order);
      warning(wrn);
      hold on
      blh = plot(xdata,polyval(fit,xdata),':');
      legendname(blh,'Baseline')
      hold off

      title(['Baseline Order: ' num2str(order)]);

      uiresume  %force update of order and baseline in watching loop (below)

      return
      
    case 'range_dialog'
      %User input range/s.
      fig = varargin{2};
      data = findobj(allchild(gca),'userdata','data');
      xdata = get(data,'xdata');
      if iscell(xdata)
        xdata = xdata{1};
      end
      cur_range = getselection(fig);
      cur_range = xdata(cur_range);
      cur_range = encode(cur_range,[]);
      cur_range = strrep(cur_range,'[','');
      cur_range = strtrim(strrep(cur_range,']',''));
      %Get ranges from dialog box.
      [range,OK] = evricommentdlg({['Enter range using colon notation (e.g. 1:50 90:160)']},'Enter Range',cur_range);
      if ~OK
        return
      end
      
      myidx = find(ismember(xdata,str2num(range)));
      myidx = unique(myidx);
      
      [dso,myid]= plotgui('getobjdata',fig);
      dso.include{2} = myidx;
      plotgui('setobjdata',fig,dso,'include')
      
%       
%       myprops = myid.properties;
%       if iscell(myprops.selection)
%         myprops.selection{2} = myidx;
%       else
%         myprops.selection = myidx;
%       end
%       updatepropshareddata(myid,'update',myprops)
%       
      
      % % % % %  mydataset.includ{plotby} = selection{plotby}(:); setobjdata(targfig,mydataset,'include');
      
      return
    case 'close'
      %done - close figure
      fig = varargin{2};

      ppfig = getappdata(fig,'ppfig');
      set(ppfig,'visible','on');
      drawnow
      close(fig);
      return;

  end
end

%-------------------------------------------------------
% Main entry for showing plot and selecting values

%pp passed in varargin
pp = varargin{1};

ppfig = gcbf;
if nargin>1 && ishandle(varargin{2})
  %Sepcial call handing pp fig as input.
  ppfig = varargin{2};
end

%show user a plot and have them select a range to view
if ~isempty(ppfig)  %(can ONLY be called from preprocess)
  set(ppfig,'visible','off');  %hide preprocess
  try
    %get data from preprocess
    mydata = preprocess('getdataset',ppfig);

    %get current settings from pp
    range = pp.userdata.range;
    order = pp.userdata.order;
    
    if islogical(range) || all(range==1 | range==0)
      %convert range logical vector into indices
      range = find(range);
    end
      
    if max(range)>size(mydata,2)
      erdlgpls('Range window larger than data. Clearing current selection.','Baseline Range Error');
      range = [];
    end
      
    if ~isempty(mydata);
      %Make range the include field. 
      mydata.include{2} = range;
      
      %do plot of data and wait for user to click "continue"
      c.cont = {'style','pushbutton','string','Continue','callback','baselineset(''close'',getappdata(gcbf,''target''));'};

      fig = figure('numbertitle','off','name','Select Baseline Regions');
      setappdata(fig,'order',order);
      setappdata(fig,'ppfig',ppfig);
      toolbar(fig,'',{
        'selectx'      'selectonly' 'plotgui(''makeselection'',gcbf);plotgui(''menuselection'',''EditExcludeUnselected'')'   'enable' 'Choose baseline points.'    'off'   'push'
        'selectxplus'  'selectadd'  'plotgui(''makeselection'',gcbf);plotgui(''menuselection'',''EditIncludeSelection'')'    'enable' 'Add to baseline points.'          'off'   'push'
        'selectxminus' 'selectsub'  'plotgui(''makeselection'',gcbf);plotgui(''menuselection'',''EditExcludeSelection'')'    'enable' 'Subtract from baseline points.'   'off'   'push'
        'diaglog_box_number' 'dialog_range' 'baselineset(''range_dialog'',gcbf);'  'enable' 'Input baseline points.' 'on'   'push'
        'WinDerDecrease' 'orderdown' 'setappdata(gcbf,''order'',max(0,getappdata(gcbf,''order'')-1));plotgui(''update'')'  'enable' 'Decrease baseline order' 'on'   'push'
        'WinDerIncrease' 'orderup' 'setappdata(gcbf,''order'',min(8,getappdata(gcbf,''order'')+1));plotgui(''update'')'  'enable' 'Increase baseline order' 'off'   'push'
        'ok' 'continue'  'baselineset(''close'',gcbf);'  'enable' 'Continue' 'on' 'push'
        });

      h = plotgui('update','figure',fig,mydata,'plotby',0,'axismenuvalues',{1 2},'uicontrol',c,'noinclude',1,'noload',1,...
        'validplotby',[0 1],'selectionmode','xs','plotcommand','baselineset(''plotcommand_callback'',targfig)',...
        'viewexcludeddata',1,'pgtoolbar',0);
      plotgui('setselection',h,{[],range});

      %give instructions
      evritip('baselinesetinstructions',['Use figure toolbar to:' 10 '  * select baseline points' 10 '  * change baseline order' 10 'then click check mark to continue.'],1);
      
      %now wait while user does selections/etc.
      while ishandle(h);
        uiwait(h);
        if ishandle(h);
          %figure still there? then this was a selection or other uiresume
          %get current settings and continue waiting for figure to
          %disappear.
          range = getselection(fig);
          if ~isempty(range)
            %range = range{2};
          end
          order = getappdata(fig,'order');
        end
      end
    end

    %make range a valid vector
    if isempty(range);
      range = 1:size(mydata,2);
    else
      range = range(:)';
    end

    %convert vector range into logical-style vector and store in pp
    pp.userdata.range = zeros(1,size(mydata,2));
    pp.userdata.range(range) = 1;
    
    %store order in pp
    pp.userdata.order = order;
    if ~isempty(strfind(lower(pp.description),'specified points'))
    pp.description = sprintf('Baseline (Specified points, order=%g points=%g regions=%g)',pp.userdata.order,sum(pp.userdata.range),sum(diff([0 pp.userdata.range])==1));
    else
    pp.description = sprintf('Baseline (Automatic Weighted Least Squares, order=%g points=%g regions=%g)',pp.userdata.order,sum(pp.userdata.range),sum(diff([0 pp.userdata.range])==1));
    end
  catch
    %errors here are considered "cancel"
  end
  
  if nargin<2
    %make preprocess visible again
    set(0,'currentfigure',ppfig);
  end
  drawnow;
  set(ppfig,'visible','on');
  drawnow;
end

%------------------------------------------------------
function   range = getselection(fig)
%Get excluded data as selection.

[dso,myid]= plotgui('getobjdata',fig);
%range = myid.properties.selection;
%myexcld = 1:size(dso,2);
%myexcld(dso.include{2}) = [];
range = dso.include{2};


