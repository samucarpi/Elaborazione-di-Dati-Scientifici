function varargout = plotscoreslimits(fig, handles, varargin)
%PLOTSCORESLIMITS Display relevant limits on a scores plot.
% Used by plotscores to display limits on a PlotGUI figure.
% There are two different forms of the PLOTSCORESLIMITS call. In the first,
%  the inputs are the model from which a plot was constructed (model), the
%  confidence limits to show on the plot (limits) and a vector of indices
%  (indices) containing the factor number plotted on each axes ([x y]) of the
%  current plot. For any axes which does not have a limit assocaited with
%  it (when plotting against a sample index, for example), use an index
%  value of zero (0) in the appropriate place of indices vector. To view
%  limits for Q-residuals and/or Hotellings T^2s for a model containing "n"
%  factors, values of n+1 for Q-residuals and n+2 for T^2
%  values should be used in the indices vector.
% The second form of the function call has inputs of (fig) the handle of
%  the target plot figure and (handles) a structure containing the field
%  "modl" which contains a standard model structure with the model data
%  used on the plot. This form of the function is to be used as a callback
%  from a plotscores figure.
%
% Example: Given a model with only four factors, the following command
%  would plot the 95 and 99% confidence limits for a plot of Q-residuals
%  vs. the scores of the second factor:
%      plotscoreslimits(model,[95 99],[2 5]);
%
%I/O: plotscoreslimits(model,limitsvalue,indicies)
%I/O: plotscoreslimits(fig,handles)
%
%See also: PLOTSCORES

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 2/2003 added option to show fit statistics on Figure (1:1 context menu)
% JMS 3/10/03 fixed R^2 bug (reported R instead of R^2)
% JMS 3/24/03 fixed scores limits bug - calc mean from included points only
%jms 3/24/03 number of components in model from LOADS not SCORES
% jms 4/24/03 # of latent variables to fitinfo menu (and box)
% jms 5/8/03 mods to handle axismenuindex as cell
% jms 6/23/03 allow multiple confidence limits
% jms 9/29/03 adapted to allow use from non-callback (non-plotgui) plots
% jms 2/3/04 handle RMSEC/CV when y column is > 9
% jms 3/31/04 various additional comments
%      -added support for PLSDA thresholds
%JMS 4/1/04 Expect model as appdata, not in handles structure
%jms 4/22/04 Test for invalid handle
% -better logic to remove old fitinfoaxes
%jms 5/4/04 Allow display on log scales
%jms 7/13/04 Attach regression context menu to AXES
%jms 8/23/04 re-attach regression conext menu to 1:1 line (in addition to
%   axes)
%jms 4/12/05 Fix scores limits to match T^2 limits
%  -Fix PCR scores limit bug
%jms 7/12/05 do PCR scores limits like PCA scores limits

if nargin<2
  error('Insufficient inputs');
end

if checkmlversion('<','7')
  legendfield = 'tag';
else
  legendfield = 'displayname';
end

centerscores  ='yes';

if ischar(fig)
  switch fig
    case 'getmodel'
      [varargout{1:2}] = getmodel(handles);
      return;
      
    case 'addtextmenuitems'
      %add current axes items to context menu
      mycontext = handles;
      items = varargin{1};      

      %delete old items
      delete(allchild(mycontext));

      sep = 'off';  %separator for above Adjust Axes item (off unless there are other items on menu)
      if ~isempty(items);        
        %add new items
        set(mycontext,'visible','on');
        for j=1:length(items);
          if ~isempty(items{j})
            uimenu(mycontext,'label',items{j},'userdata',j);
          end
        end
        uimenu(mycontext,'label','Show on figure','tag','showonfig','separator','on','callback','plotscoreslimits(''showonfig'',get(gcbo,''parent''));','userdata','donotshow');
        uimenu(mycontext,'label','Select items to show','tag','selectitems','separator','off','callback','plotscoreslimits(''selectitems'',get(gcbo,''parent''));','userdata','donotshow');
        sep = 'on';
      end
      uimenu(mycontext,'label','Adjust Axes','tag','initaxes_adjust','separator',sep,'callback','adjustaxislimitsgui(gcbf)','userdata','donotshow')
      %xy=get(0,'PointerLocation');
      %set(mycontext,'Position',[0.5 0.5]);
      drawnow;
      return

    case 'selectitems'
      %allow user to select which items can be shown
      list = {
        '1:1'     '1:1 line'
        'fit'     'Fit (regression) line' 
        'r^2'     'R^2 (plotted)' 
        };
      list = [list;modelstatssummary('list')];
      hidden = getfield(plotscores('options'),'hiddenstats');
      if ~iscell(hidden)
        hidden = {'r^2' 'r2y' 'q2y'};
      end
      [sel,ok] = listdlg('ListString',list(:,2),'InitialValue',find(~ismember(list(:,1),hidden)),'PromptString','Show which statistics?');
      if ok
        hidden = list(setdiff(1:size(list,1),sel));
        setplspref('plotscores','hiddenstats',hidden);
      end
      myfig = gcbf;
      if isempty(myfig) && ishandle(handles)
        myfig = ancestor(handles,'figure');
      end
      plotgui('update','figure',myfig)
      return;
       
    case 'showonfig'
      %input "handles" is actually handle of context menu
      h = get(handles,'children');
      h = setdiff(h,findobj(handles,'userdata','donotshow'));  %remove "showonfig" label
      if length(h)>1
        ind = get(h,'userdata');
        empty = cellfun('isempty',ind);
        ind(empty) = {length(h)+1};  %just in case some items don't have numbers
        [junk,order] = sort([ind{:}]);
        h = h(order);
      end
      hlbls = get(h,'label');
      
      myfig = gcbf;
      if isempty(myfig) && ishandle(handles)
        myfig = ancestor(handles,'figure');
      end
      
      if ~(isempty(hlbls)) && ~isempty(myfig)
        modelstatssummary('showonfig',hlbls,myfig)
      end
      return

    case 'hideonfig'
      texth = findobj('uicontextmenu',handles);
      if ~isempty(texth);
        for j = 1:length(texth);
          texth(j) = get(texth(j),'parent');   %locate parent axes of the text object
        end
        delete(unique(texth));      %delete the parent axes (not just the text object)
      end
      return

    otherwise
      error('Unrecognized input - see ''help plotscoreslimits''');

  end
end

if isstruct(fig);
  varargin = {handles varargin{:}};
  handles = fig;
  fig = gcf;
end

%get model and test (if any) from handles structure
% (NOTE: handles MIGHT be a model itself if called from command line)
[modl,test] = getmodel(handles);

if strcmp(getappdata(fig,'figuretype'),'PlotGUI')
  %call from plotgui figure
  ind         = getappdata(fig,'axismenuindex');
  lbls        = getappdata(fig,'axismenuvalues');
  showlimits  = getappdata(fig,'showlimits');
  limitsvalue = getappdata(fig,'limitsvalue');
  showerrorbars = getappdata(fig,'showerrorbars');
  if isempty(showerrorbars)
    %nothing set in appdata? look for checkbox...
    useritems = getappdata(fig,'useritems'); 
    ebcb = strmatch('showerrorbars',get(useritems,'tag'));
    if ~isempty(ebcb)
      showerrorbars = get(useritems(min(ebcb)),'value');
    else
      showerrorbars = getfield(analysis('options'),'showerrorbars');
    end
  end
else
  %call from regular figure
  if length(varargin)<2;
    error('limits value and plotted types must be supplied when used from command line')
  end
  showlimits  = 1;
  showerrorbars = 1;
  limitsvalue = varargin{1};
  ind         = varargin{2};
  if length(ind)<3;
    ind(3) = 0;
  end
  lbls        = {[] {[]} []};
end

temp = [];
if iscell(ind);
  for j=1:length(ind);
    if length(ind{j})==1;
      temp(j) = ind{j};
    else
      temp(j) = nan;
    end
  end
  ind = temp;
end

if ~iscell(lbls{2}); lbls{2} = {lbls{2}}; end;

%diagonal 1:1 line needed?
if strcmp(lbls{1},{'Image of'}) | ~isempty(findobj(allchild(gca),'userdata','data','type','image'))
  return;
end

setappdata(gca,'dpcontextitems',{});
if (~isempty(modl) & length(modl.datasource)>1) | (any(strncmp(lbls{1},{'Y Measured','Y CV Predicted','Y Predicted'},10)) ...
    & ind(3) == 0);

  for lblind = 1:length(lbls{2});
    needsdp(lblind) = any(strncmp(lbls{2}{lblind},{'Y Measured','Y CV Predicted','Y Predicted'},10));
  end

  if all(needsdp);
    %add stats as needed
    
    %get list of hidden items
    hidden = getfield(plotscores('options'),'hiddenstats');
    if ~iscell(hidden)
      hidden = {};
    end

    %find out if we need a 1:1 line
    if (any(strncmp(lbls{1},{'Y Measured','Y CV Predicted','Y Predicted'},10)) & ind(3) == 0) & ~ismember('1:1',hidden)
      h = dp;
      legendname(h,'1:1');
      uistack(h,'bottom');
    else
      h = [];
    end
    
    mycontext = findobj(fig,'tag','dplinemenu');
    if isempty(mycontext); mycontext = uicontextmenu('tag','dplinemenu'); end
    if ~isempty(h); 
      set(h,'uicontextmenu',mycontext); 
    end
    set(gca,'uicontextmenu',mycontext);
    delete(allchild(mycontext));  %remove previous menu entries
    
    %locate which y-columns are being used for the X and Y axes selections
    yindx(1) = yindexextract(lbls{1});
    yindx(2) = yindx(1);
    for lblind = 1:length(lbls{2})
      temp = yindexextract(lbls{2}{lblind});
      if temp~=yindx(2);
        yindx(2) = temp;    %mutliple, take first
        break
      end
    end

    contextitems = modelstatssummary(modl,test,yindx,struct('hidden',{hidden}));

    if length(lbls{2})==1 & ~any(yindx==0);  %1 y-item selected and x-axis isn't "index" of some sort

      dathand = findobj(allchild(get(fig,'currentaxes')),'userdata','data');
      if ~isempty(dathand);
        %add R^2
        dathand = dathand(1);
        xd  = get(dathand,'xdata');
        yd  = get(dathand,'ydata');
        if ~ismember('r^2',hidden)
          R2  = r2calc(xd,yd);
          contextitems{end+1} = sprintf('R^2 (plotted) = %0.3f',R2);
        end

        if ~ismember('fit',hidden)
          %add regression (fit) line
          use = isfinite(xd) & isfinite(yd);
          if length(unique(xd(use)))>1
            fit = polyfit(xd(use),yd(use),1);
            h = abline(fit(1),fit(2));
            fitlbl = sprintf('Fit (slope = %4.4f)', fit(1));
            legendname(h, fitlbl);
            uistack(h,'bottom');
          end
        end
        
      end
    end

    if isempty(contextitems)
      contextitems{end+1} = '';        
    end
    setappdata(gca,'dpcontextitems',contextitems);  %store items in context menu
    
    %add REAL menu item
    set(mycontext,'callback','plotscoreslimits(''addtextmenuitems'',gcbo,getappdata(gca,''dpcontextitems''));');
    
    %add to image context menu (if density image)
    density = findobj(get(gca,'children'),'tag','density');
    if ~isempty(density)
      dcm = get(density,'uicontextmenu');
      if ~isempty(dcm)
        dcm_reg = findobj(dcm,'tag','regstatsmenu');
        if isempty(dcm_reg);
          rsm = uimenu(dcm,'tag','regstatsmenu','separator','on','label','Model Results');
          uimenu(rsm,'tag','junk','label','Nothing to display...');
          set(dcm,'callback',[get(dcm,'callback') ';plotscoreslimits(''addtextmenuitems'',findobj(gcbo,''tag'',''regstatsmenu''),getappdata(gca,''dpcontextitems''));']);
        end
      end
    end
    
    %check if fit info was being shown before
    fitinfoaxes = findobj(fig,'tag','fitinfoaxes');
    if ~isempty(fitinfoaxes);
      ca = get(fig,'currentaxes');  %store the data axis (to make it current after we do this)
      fitinfo = findobj(fitinfoaxes,'tag','fitinfo');
      if ~isempty(fitinfo);
        pos = get(max(double(fitinfo)),'position');      %get position of current fitinfo
        delete(fitinfoaxes);                     %delete all fit info items
        plotscoreslimits('addtextmenuitems',mycontext,getappdata(gca,'dpcontextitems'));  %update menu items
        plotscoreslimits('showonfig',mycontext); %create new updated items (based on current info)
        fitinfo = findobj(fig,'tag','fitinfo');  %get new fitinfo handle
        set(fitinfo,'position',pos)              %reposition fitinfo box to last location
        set(fig,'currentaxes',ca);               %restore focus to actual data axes
      end
    end

    %display disappearing message that right-click information is available
    if false % isempty(findobj(fitinfoaxes,'tag','fitinfo')) & isempty(getappdata(gca,'pslrightclick'))
      ax = axis;
      th = text(ax(1),ax(3),' Right-Click axis for info','fontsize',9,'color',[.9 0 0],'verticalalignment','bottom');
      delobj_timer(['rct' num2str(th)],th,3)
      setappdata(gca,'pslrightclick',true);   %flag that we've already shown the right-click notice
    end
  end
else
  %refresh any fitinfoaxes (left over from old plot)
  delete(findobj(fig,'tag','fitinfoaxes'));
end

%show error bars?
if showerrorbars
  %start by getting data
  data = findobj(allchild(gca),'userdata','data');
  y = get(data,'ydata')';
  x = get(data,'xdata')';
  
  try
    bar_err = {[] []};
    for mode = 1:2;
      %get label(s) for this mode
      onelbl = lbls{mode};
      if iscell(onelbl)
        if length(onelbl)>1
          continue;  %more than one item?? skip this mode
        end
        onelbl = onelbl{1};
      end
      if  any(strncmp(onelbl,{'Y Predicted' 'Y Residual'},10));
        %add estimation error bars if either predicted values or residuals
        
        %get error for model
        if isempty(test) | length(x)>test.datasource{1}.size(1)
          %if no test OR the x data seems to be including more than just the test
          %data. We need to get est errors for the calibration data.
          if isfieldcheck(modl,'modl.detail.esterror.pred')
            err = modl.detail.esterror.pred;
          else
            err = [];
          end
          if isempty(err)
            err = ils_esterror(modl);
          end
        else
          err = [];
        end
        %get test-block est error (if present)
        if ~isempty(test)
          %currently test is always shown if it is there, so always add these
          %values if you can
          if isfieldcheck(test,'test.detail.esterror.pred')
            err_t = test.detail.esterror.pred;
          else
            err_t = [];
          end
          if isempty(err_t)
            err_t = ils_esterror(modl,test);
          end
          err = [err; err_t];
        end
        
        if ~isempty(err)
          %choose correct column of y (based on string label)
          [j,n] = strtok(onelbl,' ');
          [j,n] = strtok(n,' ');
          n     = strtok(n,' ');
          n     = str2double(n);
          incllu(modl.detail.includ{2,2}) = 1:length(modl.detail.includ{2,2});
          err   = err(:,incllu(n));
          
          %if it appears we'll succeede...
          if size(err,1)==size(y,1)
            %store the error to try plotting
            bar_err{mode} = err;
          end
        else
          bar_err = {[] []};
        end
      end
    end
    if ~isempty(bar_err{1}) | ~isempty(bar_err{2})     
      %plot the error bars
      hold on
      h = errorbars(x,y,bar_err{1},bar_err{2},0,0);
      set(h,'handlevisibility','off','color',[.5 .5 .5]);

      %adjust axis scale if needed
      erry = get(h,'ydata'); 
      errx = get(h,'xdata');
      if iscell(erry)
        erry = [erry{:}];
      end
      if iscell(errx)
        errx = [errx{:}];
      end
      ax = axis;
      axis([min(ax(1),min(errx)) max(ax(2),max(errx)) min(ax(3),min(erry)) max(ax(4),max(erry))])
      
      %add legend
      set(plot([0 0],[nan nan],'k'),legendfield,'Estimated Error')
      hold off
      
      %see if they changed the confidence limit from the last value
      oldcl = getappdata(fig,'errbarconflimit');
      if ~isempty(oldcl) & (length(oldcl)~=length(limitsvalue) | any(oldcl~=limitsvalue))
        %warn them that this has no effect on estimated error values
        evritip('errorbar_nocl','Note: Confidence limit value does not modify estimated error values.',1);
      end
      setappdata(fig,'errbarconflimit',limitsvalue);  %note last value used

    else
      setappdata(fig,'errbarconflimit',[]);  %reset test for change of confidence limit (avoid trigger on re-showing of error bars)
    end
  catch
    %some error - skip the error bars now
  end
else
  setappdata(fig,'errbarconflimit',[]);  %reset test for change of confidence limit (avoid trigger on re-showing of error bars)
end

% %ASCA class consolidation
% if strcmpi(modl.modeltype,'asca')
%   if viewclasses & isfinite(ind(2))
%     data = plotgui('getdataset',fig);
%     loc = strmatch('Sub-model',data.classname(2,:));
%     submodel = data.class{2,loc};
%     if viewclassset~=submodel(ind(2))
%     clsname = modl.detail.classname(1,2,viewclassset);
%     submodel(ind(2))
%     viewclassset
%       plotgui('update','figure',fig,'viewclassset',submodel(ind(2)))
%     end
%   end
% end

%skip limits various reasons
if ~iscell(lbls{2}) ...
    | isempty(modl) ... %no model
    | ind(3)~=0 ... 
    | ~showlimits;
  %something on z-axis or showlimits turned off? no limits
elseif strcmp(lower(modl.modeltype),'simca')
  %SIMCA models have special limits for reduced Q and T^2
  axlim = axis;
  adjaxis = false;
  dov = false;
  doh = false;
  if any(strncmp(lbls{1},{'T^2 (Reduce' 'Q (Reduced)'},11))
    dov = true;
    if axlim(2)<1
      axlim(2) = 1.05;
      adjaxis = true;
    end
  end
  if length(lbls{2})==1 & any(strncmp(lbls{2}{1},{'T^2 (Reduce' 'Q (Reduced)'},11))
    doh = true;
    if axlim(4)<1
      axlim(4) = 1.05;
      adjaxis = true;
    end
  end
  if adjaxis
    axis(axlim);
  end
  if doh
    h = hline(1,'b--');
    legendname(h,'Confidence Limit')
    uistack(h,'bottom');
  end
  if dov
    h = vline(1,'b--');
    legendname(h,'Confidence Limit')
    uistack(h,'bottom');
  end

  oldcl = getappdata(fig,'simcaconflimit');
  if ~isempty(oldcl) & (length(oldcl)~=length(limitsvalue) | any(oldcl~=limitsvalue))
    evritip('simca_nocl','Note: Confidence limit value does not modify reduced T^2 or Q confidence limits. Rebuild model with new limits set in options to make this change.',1);
  end
  setappdata(fig,'simcaconflimit',limitsvalue);  %note last value used
    
else

  %get some info from the model
  if ismember(lower(modl.modeltype),{'mlr' 'cls' 'svm' 'asca'});
    n = 0;
  elseif strcmpi(modl.modeltype,'batchmaturity')
    n = size(modl.submodelpca.loads{2,1},2);
  else
    n   = size(modl.loads{2,1},2);    %Components kept
  end
  m   = length(modl.detail.includ{1,1});      %number of samples
  nv  = length(modl.detail.includ{2,1});      %number of variables

  %check for change of conf. limits with BM model
  if strcmpi(modl.modeltype,'batchmaturity')
    oldcl = getappdata(fig,'bmconflimit');
    if ~isempty(oldcl) & (length(oldcl)~=length(limitsvalue) | any(oldcl~=limitsvalue))
      %check if this is an analysis window-based plot
      %       myid = plotgui('getlink',fig);
      %       if strcmpi(get(myid.source,'tag'),'analysis')
      %         %reset confidence limit
      %         setappdata(fig,'bmconflimit',[]);  %reset value so we don't repeat this...
      %         anh = evrigui(myid.source);
      %         opts = anh.getOptions;
      %         opts.cl = limitsvalue(1)/100;
      %         anh.setOptions(opts);
      % %         anh.clearModel;
      %         anh.calibrate;
      %         return;
      %       end
      %warn them that this has no effect on estimated error values
      evritip('bm_nocl','Note: Confidence limit value does not modify batch maturity confidence limits. Rebuild model with new limits to make this change.',1);
    end
    setappdata(fig,'bmconflimit',limitsvalue);  %note last value used
  end
  
  %cycle through each limits value
  limitsvalues = [0 -sort(-limitsvalue)];
  colororder = get(gca,'colororder');
  for limitsvalueindex = 1:length(limitsvalues);
    limitsvalue = limitsvalues(limitsvalueindex);
    colorindex  = mod(length(limitsvalues)-limitsvalueindex,size(colororder,1))+1;
    thiscolor   = colororder(colorindex,:);

    clrs = {
      struct('name','Red','line',[1 .2 .2],'face',[1 .8 .8]);
      struct('name','Green','line',[.2 1 .2],'face',[.8 1 .8]);
      struct('name','Blue','line',[.2 .2 1],'face',[.8 .8 1]);
      struct('name','Gray','line',[.5 .5 .5],'face',[.8 .8 .8]);
    };

    h   = axis;

    xlog = strcmp(get(gca,'xscale'),'log');
    ylog = strcmp(get(gca,'yscale'),'log');

    %-------------------------------------------
    % Decipher y-axis selection
    ylbl    = [num2str(limitsvalue) '% Confidence Level'];  %default label for legend
    ytype   = 'none';

    if ind(2)>n
      [ytype,lm2low,lm2high,ylbl] = getlimit(modl,limitsvalue,m,n,nv,lbls{2}{1},ytype,ylbl);
      if strcmp(ytype,'single') & ~ylog; h(3) = 0; end
     
    elseif limitsvalue==0  %trigger for model-based limits - don't try to interpret below
      ytype = 'none';
      
    elseif ind(2)<=n & ind(2)>0        % PC#
      if ~strcmpi(modl.modeltype,'BATCHMATURITY')
        %any other factor-based model
          ytype = 'pcdouble';
          scrs = modl.loads{1,1}(modl.detail.includ{1,1},ind(2));
          [scrs,mn] = mncn(scrs);
          vspc = ind(1)<=n & ind(1)>0;
          if vspc
            k = 2;
          else
            k = 1;
          end
%           switch lower(modl.modeltype)
%           case 'pca'
%             switch lower(centerscores)
%             case 'no'
%               lm  = sqrt(modl.detail.ssq(ind(2),2) * tsqlim(m,min(n,k),limitsvalue));
%             case 'yes'
%               lm  = std(scrs)*sqrt(tsqlim(m,min(n,k),limitsvalue));
%             end
%           case 'pcr'
%             switch lower(centerscores)
%             case 'no'
%               lm  = sqrt(modl.detail.pcassq(ind(2),2) * tsqlim(m,min(n,k),limitsvalue));
%             case 'yes'
%               lm  = std(scrs)*sqrt(tsqlim(m,min(n,k),limitsvalue));
%             end
%           otherwise
            lm    = std(scrs)*sqrt(tsqlim(m,min(n,k),limitsvalue));
%           end
          lm2high = mn+lm;
          lm2low  = mn-lm;
      else
        %BATCHMATURITY model...
        %1) get exiting x-axis we will plot against
        lmx     = get(findobj(allchild(gca),'userdata','data'),'xdata');

        %2) get corresponding BM
        BM = modl.submodelreg.pred{2};
        if ~isempty(test)
          BMT = test.submodelreg.pred{2};
          if length(lmx)==length(BM)+length(BMT)
            % [cal;test]
            BM = [BM; BMT];
          elseif length(lmx)==length(BMT)
            % [test] (only)
            BM = BMT;
          else
            % [cal] (only)
            %(As of this coding, this isn't actually supported, but in case
            %we do support it later, this will handle it correctly... in
            %fact, we don't have to do anything!!)
          end
        end
        %3) lookup BM in modl.limits.bm
        inds = findindx(modl.limits.bm,BM);
        %4) use BM to index into modl.limits.low and .high (using row corresponding to PC# (n here)
        lm2high = modl.limits.high(ind(2),inds);
        lm2low  = modl.limits.low(ind(2),inds);
        
        if length(lmx)~=length(lm2high)
          %make sure it matches (handles odd errors where the model doesn't
          %match the x-axis)
          return
        end
        
        if isempty(lmx);
          ytype = 'none';
        else
          ytype = 'doublevector';
        end
      end
    end

    %-------------------------------------------
    % Decipher x-axis selection
    xlbl   = [num2str(limitsvalue) '% Confidence Level'];   %default label for legend
    xtype = 'none';
    lm1high = [];
    lm1low  = [];
    if ind(1)>n
      
      [xtype,lm1low,lm1high,xlbl] = getlimit(modl,limitsvalue,m,n,nv,lbls{1},xtype,xlbl);
      if strcmp(xtype,'single') & ~xlog; h(1) = 0; end

    elseif limitsvalue==0  %trigger for model-based limits - don't try to interpret below
      xtype = 'none';  

    elseif ind(1)<=n & ind(1)>0                   
      % x = pc#
      if ~strcmpi(modl.modeltype,'BATCHMATURITY')
        %any other factor-based model
        xtype = 'pcdouble';
        scrs = modl.loads{1,1}(modl.detail.includ{1,1},ind(1));
        [scrs,mn] = mncn(scrs);
        vspc = ind(2)<=n & ind(2)>0;
        if vspc
          k = 2;
        else
          k = 1;
        end
%         switch lower(modl.modeltype)
%         case 'pca'
%           switch lower(centerscores)
%           case 'no'
%             lm  = sqrt(modl.detail.ssq(ind(1),2) * tsqlim(m,min(n,k),limitsvalue));
%           case 'yes'
%             lm  = std(scrs)*sqrt(tsqlim(m,min(n,k),limitsvalue));
%           end
%         case 'pcr'
%           switch lower(centerscores)
%           case 'no'
%             lm  = sqrt(modl.detail.pcassq(ind(1),2) * tsqlim(m,min(n,k),limitsvalue));
%           case 'yes'
%             lm  = std(scrs)*sqrt(tsqlim(m,min(n,k),limitsvalue));
%           end
%         otherwise
          lm    = std(scrs)*sqrt(tsqlim(m,min(n,k),limitsvalue));
%         end
        lm1high = mn+lm;
        lm1low  = mn-lm;
      else
        %BATCHMATURITY model...
        %NOT supported for x-axis set to scores
        xtype = 'none';
        ytype = 'none';
      end
    end
    
    if isempty(lm1low)
      lm1low = -lm1high;
    end

    %both doubles? then this is an ellipse
    if strcmp(xtype,'pcdouble') & strcmp(ytype,'pcdouble')
      xtype = 'ellipse';
      ytype = 'none';
    end
    if strcmp(ytype,'doublevector') & ~strcmp(xtype,'none');
      ytype = 'none'; %DISABLE double vector if x-type isn't 'none'
    end

    %adjust axes limits
    switch xtype
      case 'single'
        h(2) = max(h(2),1.05*max(lm1high));
      case {'ellipse' 'pcdouble' 'double' 'doublevector'}
        delta = abs(max(lm1high) - min(lm1low));
        h(1) = min(h(1),lm1low-delta*0.05);
        h(2) = max(h(2),lm1high+delta*0.05);
        switch xtype
          case 'ellipse'
            delta = abs(max(lm2high - lm2low));
            h(3) = min(h(3),min(lm2low)-delta*0.05);
            h(4) = max(h(4),max(lm2high)+delta*0.05);
        end
    end
    switch ytype
      case 'single'
        h(4) = max(h(4),1.05*max(lm2high));
      case {'pcdouble' 'double' 'doublevector'}
        delta = abs(max(lm2high - lm2low));
        h(3) = min(h(3),min(lm2low)-delta*0.05);
        h(4) = max(h(4),max(lm2high)+delta*0.05);
    end
    
    h = h+[-((h(2)-h(1))==0)*.5 ((h(2)-h(1))==0)*.5 -((h(4)-h(3))==0)*.5 ((h(4)-h(3))==0)*.5];          %force h to be valid (no equal start/end values)
    axis(h)

    switch xtype
      case 'ellipse'
        mn1 = (lm1high+lm1low)/2;
        lm1 = lm1high-mn1;
        mn2 = (lm2high+lm2low)/2;
        lm2 = lm2high-mn2;
        xhandle = ellps([mn1 mn2],[lm1 lm2],'--g');
        set(xhandle,legendfield,xlbl,'color',thiscolor);
      case 'single'
        xhandle = vline(lm1high,'--g');
        set(xhandle,legendfield,xlbl,'color',thiscolor);
      case {'double' 'pcdouble'}
        xhandle = vline(lm1high,'--g');
        set(xhandle,legendfield,xlbl,'color',thiscolor);
        xhandle(2) = vline(lm1low,'--g');
        set(xhandle(2),legendfield,xlbl,'color',thiscolor,'handlevisibility','off');
      case 'doublevector'
        %not defined...
      otherwise
        xlbl = '';
    end
    if strcmp(ylbl,xlbl)
      %do not show object in legend if the label is the same as the x
      vis = 'off';
    else
      vis = 'on';
    end
    limhhigh = [];
    limhlow  = [];
    switch ytype
      case 'single'
        limhhigh = hline(lm2high,'--g');
        limhlow  = [];
        set(limhhigh,legendfield,ylbl,'color',thiscolor,'handlevisibility',vis);
      case {'doublevector' 'double' 'pcdouble'}
        
        if ismember(ytype,{'double','pcdouble'}) & (length(limitsvalues)>2 | (length(limitsvalues)==2 & limitsvalues(1)~=0))
          %standard old limits because we've got multiple to show.
          limhhigh = hline(lm2high,'--g');
          limhlow  = hline(lm2low,'--g');
          set(limhhigh,legendfield,ylbl,'color',thiscolor,'handlevisibility',vis);
          set(limhlow,legendfield,ylbl,'color',thiscolor,'handlevisibility','off');
        else
          %single limit or doublevector type - use area/line with color
          %options
          
          washeld = ishold;
          if ~washeld; hold on; end
          
          if ismember(ytype,{'double','pcdouble'})
            
            lmx = h(1:2);
            lm2high = lm2high([1 1]);
            lm2low  = lm2low([1 1]);
            showlines = 'on';
            showfill  = 'off';
          else
            %sort lmx into increaseing order (and match up limits vectors)
            bad = ~isfinite(lmx);
            if any(bad)
              lmx = lmx(~bad);
              lm2high = lm2high(~bad);
              lm2low  = lm2low(~bad);
            end
            [lmx,order] = sort(lmx);
            lm2high = lm2high(order);
            lm2low = lm2low(order);
            showlines = 'off';
            showfill  = 'on';
          end
          
          
          %look for context menu for patch
          pcm = findobj(get(gca,'parent'),'tag','clpatchmenu');
          %         if ~isempty(pcm)
          %           delete(pcm)
          %           pcm = [];
          %         end
          
          if isempty(pcm)
            %add context menu and sub-menus
            pcm = uicontextmenu('tag','clpatchmenu','callback',@clpatchmenu);
            uimenu(pcm,'tag','clpatchshowlines','label','Show Lines','callback',@clpatchshowlines,'checked',showlines);
            uimenu(pcm,'tag','clpatchshowfill','label','Show Fill','callback',@clpatchshowfill,'checked',showfill);
            cm = uimenu(pcm,'tag','clpatchcolor','label','Color');
            %add color menus
            for j=1:size(clrs,1);
              uimenu(cm,'tag',['clpatchcolor' clrs{j}.name],'label',clrs{j}.name,'userdata',clrs{j},'callback',@clpatchcolor);
            end
          else
            showlines = get(findobj(pcm,'tag','clpatchshowlines'),'checked');
            showfill  = get(findobj(pcm,'tag','clpatchshowfill'),'checked');
          end
          
          %do patch first...
          myclr = getappdata(pcm,'colors');
          if isempty(myclr)
            myclr = clrs{3};
            setappdata(pcm,'colors',myclr);
          end
          clr  = myclr.face;
          lclr = myclr.line;
          limhpatch = patch([lmx fliplr(lmx)],[lm2high fliplr(lm2low)],clr);
          set(limhpatch,'zData',get(limhpatch,'yData')*0-1,'FaceColor',clr,'EdgeColor',clr)
          legendname(limhpatch,ylbl);
          uistack(limhpatch,'bottom');
          set(limhpatch,'handlevisibility',vis);
          if strcmp(showfill,'off')
            set(limhpatch,'visible','off','handlevisibility','off');
          end
          
          %then do lines (but make them invisible until user asks for them)
          limhhigh = plotmonotonic(lmx,lm2high);
          limhlow  = plotmonotonic(lmx,lm2low);
          ls = '--';
          linewidth = .5;
          if strcmp(showlines,'on') & strcmp(showfill,'off')
            hvis = 'on';
          else
            hvis = 'off';
          end
          set(limhhigh,'linestyle',ls,legendfield,ylbl,'color',lclr,'handlevisibility',hvis,'linewidth',linewidth,'visible',showlines);
          set(limhlow,'linestyle',ls,legendfield,ylbl,'color',lclr,'handlevisibility','off','linewidth',linewidth,'visible',showlines);
          setappdata(limhhigh,'hvis','on');  %when visibile this handle is shown in legend
          setappdata(limhlow,'hvis','off');  %even when visible, this handle is NEVER shown in legend
          
          %add context menu to object and record current handles
          handles = getappdata(pcm,'lines');
          setappdata(pcm,'lines',[handles(ishandle(handles)) limhhigh limhlow]);
          handles = getappdata(pcm,'patches');
          setappdata(pcm,'patches',[handles(ishandle(handles)) limhpatch]);
          set([limhhigh limhlow limhpatch],'uicontextmenu',pcm);
          
          if ~washeld; hold off; end
          break;   %BREAK out of limits loop
        end
    end
    
  end
end


%threshold limits needed (plsda model)?
if ~isempty(modl) & strcmpi(modl.modeltype,'plsda') & ind(3)==0 & isfieldcheck('modl.detail.threshold',modl);
  %x-axis thresholds?
  if any(strncmp(lbls{1},{'Y Predicted','Y CV Predic'},10))
    yindx = yindexextract(lbls{1});
    yindxincl = find(modl.detail.includ{2,2}==yindx);  %locate which y we're looking at
    if ~isempty(yindxincl) & length(modl.detail.threshold)>= yindxincl;
      threshold = modl.detail.threshold(yindxincl);
      h = vline(threshold,'r--');
      set(h,legendfield,['Discrim Y ' num2str(yindx)]);
    end
  end
  %y-axis thresholds?
  if length(lbls{2})==1
    if any(strncmp(lbls{2}{1},{'Y Predicted','Y CV Predic'},10))
      yindx = yindexextract(lbls{2}{1});
      yindxincl = find(modl.detail.includ{2,2}==yindx);  %locate which y we're looking at
      if ~isempty(yindxincl) & length(modl.detail.threshold)>= yindxincl;
        threshold = modl.detail.threshold(yindxincl);
        h = hline(threshold,'r--');
        set(h,legendfield,['Discrim Y ' num2str(yindx)]);
      end
    end
  end
end

%residuals get a zero line
if any(strncmp(lbls{1},{'Y Residual','Y CV Resid','Y Stdnt Re'},10));
  h=vline('g--');
  set(h,legendfield,'Zero');
end

%some get hline
needshline = 1;     %assume we need it unless we can find a y-seleciton which DOESN'T need it
for lblind = 1:length(lbls{2});
  needshline = needshline & any(strncmp(lbls{2}{lblind},{'Y Residual','Y CV Resid','Y Stdnt Re'},10));
end
if needshline; h=hline('g--'); set(h,legendfield,'Zero'); end

%----------------------------------
function yindx = yindexextract(lbls)
%figure out which y is selected for a given y statistic

switch lower(lbls(1:min(end,10)))
  case {'y measured'}
    yindx = str2num(strtok(lbls(12:end),' '));
  case {'y predicte'}
    yindx = str2num(strtok(lbls(13:end),' '));
  case {'y cv predi'}
    yindx = str2num(strtok(lbls(16:end),' '));
  otherwise
    yindx = 0;
end

%----------------------------------
function [modl,test] = getmodel(handles,recursive)

if nargin<2
  recursive = false;
end

modl = []; test = [];
if ~isempty(handles);
  if ishandle(handles);
    %model
    myid = searchshareddata(handles,'query','model',1);
    if ~isempty(myid)
      %got shared data.
      modl = myid.object;
    elseif isempty(modl)
      %check for appdata in this figure
      modl = getappdata(handles,'modl');
      if isempty(modl)
        %or this appdata field
        modl = getappdata(handles,'model');
      end
    end
    
    %prediction
    myid = searchshareddata(handles,'query','prediction',1);
    if ~isempty(myid)
      %got shared data.
      test = myid.object;
    elseif isempty(test)
      %check for appdata in this figure
      test = getappdata(handles,'test');
    end
  elseif ismodel(handles)  %handles IS the model!
    modl = handles;
  end
end

if ~recursive & isempty(modl);
  [data,datasource] = plotgui('getdataset',handles);
  if isshareddata(datasource)
    [modl,test] = getmodel(datasource.source,true);
  end
end

%------------------------------------------
function [type,lm2low,lm2high,legendlbl] = getlimit(modl,limitsvalue,m,n,nv,lbl,type,legendlbl)

lbl = lower(lbl);
lm2low  = [];
lm2high = [];
if ~isempty(findstr(lbl,'q residuals reduced')) | ~isempty(findstr(lbl,'hotelling t^2 reduced'))
  if limitsvalue>0
    type = 'single';
    lm2high = 1;
    legendlbl = 'Reduced Statistic Threshold';
  end
elseif findstr(lbl,'q residuals') | findstr(lbl,'msr')
  type = 'single';
  if limitsvalue==0
    if isfieldcheck(modl,'modl.detail.reslim') & iscell(modl.detail.reslim) & ~isempty(modl.detail.reslim)
      lm2high = modl.detail.reslim{1};
      legendlbl = 'Model-specific Q Limit';
    else
      type = 'none';
    end
  elseif isfieldcheck(modl,'modl.detail.reseig')
    lm2high  = residuallimit(modl.detail.reseig, limitsvalue/100);
  elseif strcmpi(modl.modeltype,'batchmaturity')
    lm2high  = residuallimit(modl.submodelpca.detail.reseig, limitsvalue/100);
  else
    lm2high = nan;
  end
  if findstr(lbl,'msr')
    lm2high = sqrt(lm2high);
  end
elseif findstr(lbl,'hotelling t^2')
  type = 'single';
  if limitsvalue==0
    if isfieldcheck(modl,'modl.detail.tsqlim') & iscell(modl.detail.tsqlim) & ~isempty(modl.detail.tsqlim)
      lm2high = modl.detail.tsqlim{1};
      legendlbl = 'Model-specific T^2 Limit';
    else
      type = 'none';
    end
  elseif n>0
    lm2high  = tsqlim(m,n,limitsvalue);
  else
    lm2high  = tsqlim(m,nv,limitsvalue);
  end
  if strcmpi(modl.modeltype,'CLS')
    lm2high = NaN;  % do not show until a meaningful limit is implemented
  end
elseif limitsvalue==0
  return
elseif findstr(lbl,'leverage')
  type = 'single';
  if strcmpi(modl.modeltype,'MLR') % use the calculation for MLR models
    lm2high = 2*nv/m;   % nv is number of variables
    legendlbl = '(2nv/m) Limit';  % special label for legend  
  else % use the standard leverage calculation.
  lm2high = 3*n/m;   % n is number of components
  legendlbl = '(3LV/m) Limit';  %special label for legend
  end
elseif findstr(lbl,'stdnt residual')
  type = 'double';
  lm2high = 3;
  lm2low  = -3;
  legendlbl = '+/-3 Limit';  %special label for legend
elseif findstr(lbl,'score distance')
  type = 'single';
  lm2high = 1;
  legendlbl = 'Max Score Distance Limit';  %special label for legend
end

if isempty(lm2high) & isempty(lm2low)
  type = 'none';
end

%---------------------------------------------------------
function clpatchshowlines(varargin)
h = varargin{1};
pcm = get(h,'parent');
ph = getappdata(pcm,'patches');
lh = getappdata(pcm,'lines');
if strcmp(get(lh(1),'visible'),'on')
  ch = 'off';
  set(ph,'visible','on','handlevisibility','on');
  set(lh,'handlevisibility','off');
else
  ch = 'on';
end
set(h,'checked',ch)
set(lh,'visible',ch);

%---------------------------------------------------------
function clpatchshowfill(varargin)
h = varargin{1};
pcm = get(h,'parent');
ph = getappdata(pcm,'patches');
lh = getappdata(pcm,'lines');
if strcmp(get(ph,'visible'),'on')
  ch = 'off';
  set(lh,'visible','on');
  for j=1:length(lh); %update legend to show lines which need be shown
    set(lh(j),'handlevisibility',getappdata(lh(j),'hvis'));
  end
else
  ch = 'on';
  set(lh,'handlevisibility','off');  %NEVER show lines in legend when patch is visible
end
set(h,'checked',ch)
set(ph,'visible',ch,'handlevisibility',ch);

%---------------------------------------------------------
function clpatchcolor(varargin)
h = varargin{1};
pcm = get(get(h,'parent'),'parent');
lh = getappdata(pcm,'lines');
ph = getappdata(pcm,'patches');

%get this menu's color basis
clr = get(h,'userdata');
setappdata(pcm,'colors',clr);

%set colors
set(lh,'color',clr.line);
set(ph,'facecolor',clr.face,'edgecolor',clr.face);

%---------------------------------------------------------
function clpatchmenu(varargin)
h = varargin{1};

%update check on show lines
lh = getappdata(h,'lines');
mh = findobj(h,'tag','clpatchshowlines');
set(mh,'checked',get(lh(1),'visible'));

%update check on show fill
lh = getappdata(h,'patches');
mh = findobj(h,'tag','clpatchshowfill');
set(mh,'checked',get(lh(1),'visible'));

%update check on color
clr = getappdata(h,'colors');
ch = findobj(h,'tag','clpatchcolor');
set(get(ch,'children'),'checked','off');  %uncheck all...
if isstruct(clr)
  set(findobj(ch,'tag',['clpatchcolor' clr.name]),'checked','on');
end



