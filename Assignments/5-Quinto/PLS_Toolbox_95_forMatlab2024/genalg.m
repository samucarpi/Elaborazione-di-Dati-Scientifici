function varargout = genalg(action,varargin)
%GENALG Genetic Algorithm for Variable Selection.
%  This function presents a GUI used to design Genetic Algorithm (GA) runs
%  for predictive variable selection with  MLR or PLS regression models.
%  Two optional inputs are (xdat) a matrix of of predictor variables and
%  (ydat) a matrix of predicted variables. If not supplied, the user can
%  manually load data from the workspace using the File menu.
%
%  After loading data, the GUI consists of various settings to modify the
%  behavior of the algorithm. Once the settings are complete, the GA run
%  can be started by clicking "Execute". Note that the settings, which can
%  be saved, is a structure that is the same as the (options) structure
%  in GASELCTR.
%
%  Results can be viewed using the "Fit vs. Var" and "Frequency" buttons
%  and saved from the File menu. The saved results are a structure
%  containing the settings used for the analysis. The fitness of the final
%  members of the population are given in field "rmsecv" and the variables
%  included in each of these members are given as rows in the field "icol".
%  A 1 means a variable was included, and a 0 means that it was not
%  included.
%
%I/O: genalg(xdat,ydat)
%
%See also: CALIBSEL, FULLSEARCH, GASELCTR, GENALGPLOT, IPLS, SRATIO, VIP

%Copyright (c) Eigenvector Research, Inc. 1995
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Modified 2/95, 1/97, 2/97 NBG
%Modified 4/30/98 BMW
% 10/27/00, nbg change in main loop to check if pop(i,:) is all zeros
% 2/23/01, jms added action "save" which extracts values but doesn't close
%   -added tag on figure and brings it to front in case of manual control/call
%   -added replicate cycling
%   -added plot button (calls genalgplots)
%   -added change of "execute" to "repeat" after first cycle (to do runs again appending to end)
% 6/01 jms rewrote to new figure format
% 8/28/01 jms fixed frequency plot bug when only one model was returned
% 10/31/01 jms fixed replicate count reset bug on resume
% 12/05/01 jms fixed # lvs slider for even numbers
% 3/21/03 jms allowed load of logical y-blocks
%  -added better support of loading non-dataset yblock with dataset xblock
% 6/23/03 added reference spectrum to frequency plot
%  -added full preprocessing support
% 10/13/03 fixed preprocessing and datasource bugs in LoadSetings
% 02/03/06 rsk add preprocess logic.

if nargin<1 | ~isstr(action);
  
  fig     = openfig('genalggui','new','invisible');
  figbrowser('addmenu',fig); %add figbrowser link
  handles = guihandles(fig);
  guidata(fig,handles);
  
  options = [];
  if nargin>0
    %Scan for options input.
    if isstruct(action)
      options = action;
    else
      if nargin>1
        for i = 1:length(varargin)
          if isstruct(varargin{i})
            options = varargin{i};
          end
        end
      end
    end
  end
  
  if isempty(options)
    options = genalg('options');
  end
  options = reconopts(options,mfilename);
  setappdata(fig,'guioptions',options);
  
  genalg('initialize',fig,[],handles);
  
  if nargin > 1;    %old version of call
    %function [ffit,gpop] = genalg(xdat,ydat,outfit,outpop,action);
    setappdata(handles.gawindow,'autoloadxdata',action);
    setappdata(handles.gawindow,'autoloadxname',inputname(1));
    setappdata(handles.gawindow,'autoloadydata',varargin{1});
    setappdata(handles.gawindow,'autoloadyname',inputname(2));
    
    genalg('autoload',fig,[],handles);                  %reinitialize window
    
    if nargout > 0;
      varargout = {fig};
    end
    
  else
    %normal (new) version of call, see if they wanted the figure number
    if nargin==1
      %only one item? can't load it
      erdlgpls('Unable to load only a single block. Both X and Y must be loaded simultaneously. Input ignored.','Single Block Load Error');
    end
    if nargout == 1;
      varargout = {fig};
    end
  end
  
else
  
  if ismember(action,evriio([],'validtopics'));
    options = [];
    options.show_figure_on_start = 'yes';
    if nargout==0; evriio(mfilename,action,options); else; varargout{1} = evriio(mfilename,action,options); end
    return;
  end
  
  if nargin <2;
    h       = gcf;
  else
    h       = varargin{1};
    %h should be a figure.
    h = ancestor(h,'figure');
  end
  
  if nargin < 4;
    handles = guidata(h);
  else
    handles = varargin{3};
  end
  
  if ~isfield(handles,'gawindow');    %not genalg window?
    h       = genalg;                 %make one
    handles = guidata(gcf);
  end
  
  
  if checkmlversion('>','8.3')
    %Use set groot instead of figure() to preserve visible off.
    set(groot,'CurrentFigure',handles.gawindow)
  else
    myvis = get(handles.gawindow,'visible');
    figure(handles.gawindow);
    set(handles.gawindow,'visible',myvis);
    drawnow
  end
  
  modl    = getappdata(handles.gawindow,'modl');
  xdat    = getappdata(handles.gawindow,'xblock');
  ydat    = getappdata(handles.gawindow,'yblock');
  dsfieldsincl    = getappdata(handles.gawindow,'dsfieldsincl');
  
  if ~isempty(xdat);
    [mx,nx] = size(xdat);
    [my,ny] = size(ydat);
  else
    mx = 0; nx = 0;
    my = 0; ny = 0;
  end
  
  switch action
    case 'initialize'
      
      set(handles.gawindow,'closerequestfcn','genalg(''quit'',gcf)');
      
      %First time through flag. Use to set visible on start of gui.
      firstflag = 0;
      
      %Only adjust size once.
      if isempty(getappdata(handles.gawindow,'update_fontsize'))
        %set font sizes
        fs = getdefaultfontsize('normal');
        %find all objects with font sizes
        allh = allchild(handles.gawindow);
        hasfont = isprop(allh,'fontsize');
        allh = allh(hasfont);
        set(allh,'fontunits','points','fontsize',fs);
        
        %look for extent problem (with typical subject)
        crh = findobj(handles.gawindow,'string','Crossover:');
        crex = get(crh,'extent');
        crpo = get(crh,'position');
        scladd = max((crex(3)./crpo(3))-1,0.05);
        
        %rescale
        scl = fs/10+scladd;
        remapfig([0 0 1 1],[0 0 scl scl],h);
        pos = get(handles.gawindow,'position');
        pos(1:2) = pos(1:2)-pos(3:4)*(1-scl)/2;
        pos(3:4) = pos(3:4)*scl;
        set(handles.gawindow,'position',pos);
        positionmanager(handles.gawindow,'onscreen');
        setappdata(handles.gawindow,'update_fontsize',1)
        firstflag = 1;
      end
      
      %Define default values for all variables
      opts=gaselctr('options');
      
      if isempty(xdat) | isempty(ydat);     %no data, take a guess at certain things
        maxw = 50;
        mlvs = 25;
        maxs = 20;
        vals = round(sqrt(20));
      else      %we do have data, set appropriate controls
        maxw = round(min([nx/2,50]));
        mlvs = min([mx,nx,25]);
        maxs = min([20,mx]);
        vals = round(sqrt(mx));
      end
      
      %Define preprocessing
      if isempty(getappdata(handles.gawindow,'preprocessing'))
        %If appdata is totaly empty (no cells) then load GASELCTR opts.
        %GASELCTR has autoscale as default for both x and y.
        %Need to expand to full pp struct from keyword becuase pp is
        %displayed in GUI.
        setappdata(handles.gawindow,'preprocessing',{preprocess('default',opts.preprocessing{1}) preprocess('default',opts.preprocessing{2})});
      end
      
      %Define population size slider sli_ps
      set(handles.populationsizemin,'string','16')
      set(handles.populationsizemax,'string','256')
      set(handles.populationsize,'value',opts.popsize,'min',str2num(get(handles.populationsizemin,'string')),...
        'max',str2num(get(handles.populationsizemax,'string')));
      set(handles.populationsizetext,'string',num2str(opts.popsize));
      
      %Define window width slider sli_ww
      set(handles.windowwidthmin,'String','1');
      set(handles.windowwidthmax,'String',num2str(maxw));
      set(handles.windowwidth,'Value',opts.windowwidth,'min',str2num(get(handles.windowwidthmin,'string')),...
        'max',maxw)
      set(handles.windowwidthtext,'String',num2str(opts.windowwidth));
      
      %Define fraction terms in initial population slider
      set(handles.initialtermsmin,'String','10');
      set(handles.initialtermsmax,'String','50');
      set(handles.initialterms,'Value',opts.initialterms,'min',str2num(get(handles.initialtermsmin,'string')),...
        'max',str2num(get(handles.initialtermsmax,'string')))
      set(handles.initialtermstext,'String',num2str(opts.initialterms));
      
      %Define target min and max edit boxes
      set(handles.targetmin,'string',num2str(opts.target(1)))
      set(handles.targetmax,'string',num2str(opts.target(2)))
      set(handles.targetpercent,'value',opts.targetpct)
      
      %Define penalty slope slider
      set(handles.penaltyslopemin,'string','0')
      set(handles.penaltyslopemax,'string','0.1')
      set(handles.penaltyslope,'value',opts.penaltyslope,'min',str2num(get(handles.penaltyslopemin,'string')),...
        'max',str2num(get(handles.penaltyslopemax,'string')));
      set(handles.penaltyslopetext,'string',opts.penaltyslope);
      
      %Define maximum generations slider sli_mg
      set(handles.maxgenerationsmin,'String','1');
      set(handles.maxgenerationsmax,'String','200');
      set(handles.maxgenerations,'Value',opts.maxgenerations,'min',str2num(get(handles.maxgenerationsmin,'string')),...
        'max',str2num(get(handles.maxgenerationsmax,'string')));
      set(handles.maxgenerationstext,'String',num2str(opts.maxgenerations));
      
      %Define convergence criteria slider
      set(handles.convergencemin,'String','1');
      set(handles.convergencemax,'String','100');
      set(handles.convergence,'Value',opts.convergence,'min',str2num(get(handles.convergencemin,'string')),...
        'max',str2num(get(handles.convergencemax,'string')))
      set(handles.convergencetext,'String',num2str(opts.convergence));
      
      %Define mutation rate slider sli_mr
      set(handles.mutationratemin,'String','0.001');
      set(handles.mutationratemax,'String','0.01');
      set(handles.mutationrate,'Value',opts.mutationrate,'min',str2num(get(handles.mutationratemin,'string')),...
        'max',str2num(get(handles.mutationratemax,'string')))
      set(handles.mutationratetext,'String',num2str(opts.mutationrate));
      
      %Define crossover choice radio buttons
      set(handles.single,'value',opts.crossover==1,'visible','on');
      set(handles.double,'value',opts.crossover==2,'visible','on');
      setappdata(handles.gawindow,'crossover',opts.crossover);
      
      %Define Regression method
      set(handles.mlr,'value',strcmp(lower(opts.algorithm),'mlr'))
      set(handles.pls,'value',~strcmp(lower(opts.algorithm),'mlr'))
      
      %Define # of latent variables slider
      lvs         = min([mlvs,opts.ncomp]);
      set(handles.lvsmin,'String','1');
      set(handles.lvsmax,'String',num2str(mlvs));
      set(handles.lvs,'Value',lvs,'min',1,...
        'max',mlvs,'sliderstep',[1/(mlvs-1) 2/(mlvs-1)])
      set(handles.lvstext,'String',num2str(lvs));
      
      %Define Cross-val setting
      set(handles.random,'value',strcmp(opts.cv,'rnd'));
      set(handles.contiguous,'value',~strcmp(opts.cv,'rnd'));
      
      %Define slider for cross-validation split
      vals = min([opts.split,vals]);
      set(handles.subsetsmin,'String','2');
      set(handles.subsetsmax,'String',num2str(maxs));
      set(handles.subsets,'Value',vals,'min',2,...
        'max',maxs,'sliderstep',[1/(maxs-1) 2/(maxs-1)]);
      set(handles.subsetstext,'String',num2str(vals));
      
      %Define slider for the cross-validation iterations
      maxi = 10;
      set(handles.iterationsmin,'String','1');
      set(handles.iterationsmax,'String',num2str(maxi));
      set(handles.iterations,'Value',opts.iter,'min',str2num(get(handles.iterationsmin,'string')),...
        'max',maxi,'sliderstep',[1/(maxi-1) 2/(maxi-1)]);
      set(handles.iterationstext,'string',num2str(opts.iter));
      
      %Define replicates editbox
      set(handles.replicates,'string',num2str(opts.reps));
      
      genalg('activate',h);       %update enable and visible statuses
      guioptions = getappdata(h,'guioptions');
      
      if firstflag & strcmpi(guioptions.show_figure_on_start,'yes')
        %If starting for first time then make visible after controls are
        %set. 
        set(h,'visible','on');
      end
    case 'activate'
      
      %visiblility    (some may be turned back OFF in a moment)
      set([handles.populationsize handles.populationsizemin handles.populationsizemax],'Visible','On');
      set([handles.maxgenerations handles.maxgenerationsmin handles.maxgenerationsmax],'Visible','On');
      set([handles.mutationrate handles.mutationratemin handles.mutationratemax]      ,'Visible','On');
      set([handles.windowwidth handles.windowwidthmin handles.windowwidthmax]         ,'Visible','On');
      set([handles.convergence handles.convergencemin handles.convergencemax]         ,'Visible','On');
      set([handles.initialterms handles.initialtermsmin handles.initialtermsmax]      ,'Visible','On');
      set([handles.lvs handles.lvsmin handles.lvsmax]                                 ,'Visible','On');
      set([handles.subsets handles.subsetsmin handles.subsetsmax]                     ,'Visible','On');
      set([handles.iterations handles.iterationsmin handles.iterationsmax]            ,'Visible','On');
      set([handles.penaltyslope handles.penaltyslopemin handles.penaltyslopemax]      ,'Visible','On');
      set(handles.replicates                                                          ,'Visible','on');
      set([handles.targetmin handles.targetmax handles.targetpercent]                 ,'Visible','On');
      
      %menu
      set([handles.GAfile handles.tools],'enable','on');
      
      if isempty(xdat) | isempty(ydat);     %no data, turn off certain things
        %enable/disable
        set(handles.tools,'enable','off'); %disable "preprocess" menu (called "tools" by handle)
        set([handles.single handles.double handles.mlr handles.pls handles.random handles.contiguous...
          handles.populationsize handles.maxgenerations handles.mutationrate ...
          handles.windowwidth handles.convergence handles.initialterms ...
          handles.lvs handles.subsets handles.iterations handles.penaltyslope handles.replicates],...
          'enable','off');
        set([handles.targetmin handles.targetmax handles.targetpercent]               ,'Enable','Off');
        
        set([handles.single handles.double handles.mlr handles.pls handles.random handles.contiguous],...
          'Visible','On');
        
        %buttons
        set(handles.execute,'String','Execute','Visible','on','enable','off');
        set(handles.stop  ,'Visible','Off','Enable','Off','String','Pause');    %make stop invisible
        set(handles.resume,'Visible','off','Enable','off');
        set([handles.plotfit handles.plotfreq],'Visible','on','Enable','off');
        
        %menus
        set([handles.clear handles.cleardata handles.savesettings],'enable','off');
        set([handles.saveresults handles.savebest handles.clearresults],'enable','off');
        set(handles.loadsettings,'enable','off');
        set(handles.loadnewy,'enable','off');
        
      else      %have data,
        
        %enable/disable
        set(handles.tools,'enable','on'); %enable "preprocess" menu (called "tools" by handle)
        set([handles.single handles.double handles.mlr handles.pls handles.random handles.contiguous...
          handles.populationsize handles.maxgenerations handles.mutationrate ...
          handles.windowwidth handles.convergence handles.initialterms ...
          handles.lvs handles.subsets handles.iterations handles.penaltyslope handles.replicates],...
          'enable','on');
        
        if get(handles.pls,'Value')
          set([handles.lvs handles.lvstext handles.lvsmin handles.lvsmax handles.lvslabel],'Enable','on');
        else
          set([handles.lvs handles.lvstext handles.lvsmin handles.lvsmax handles.lvslabel],'Enable','off');
        end
        
        if get(handles.penaltyslope,'value') == 0;
          set([handles.targetmin handles.targetmax handles.targetpercent]                 ,'Enable','Off');
        else
          set([handles.targetmin handles.targetmax handles.targetpercent]                 ,'Enable','On');
        end
        
        %buttons
        set(handles.stop,'Visible','Off','Enable','Off','String','Pause');    %make stop invisible
        
        %menus
        set([handles.cleardata handles.savesettings handles.clear],'enable','on');
        set(handles.loadsettings,'enable','on');
        set(handles.loadnewy,'enable','on');
        
        if isempty(getappdata(handles.gawindow,'ffit')) & isempty(getappdata(handles.gawindow,'resumeinfo'));    %no results
          
          %radio button visibility
          set([handles.single handles.double handles.mlr handles.pls handles.random handles.contiguous],...
            'Visible','On');
          
          %buttons
          set(handles.execute,'String','Execute','Visible','on','enable','on');      %Yes to execute
          set(handles.resume,'Visible','off','Enable','off');                        %no to resume
          set([handles.plotfit handles.plotfreq],'Visible','on','Enable','off');
          
          %menus
          set([handles.saveresults handles.savebest handles.clearresults],'enable','off');
          
        else  %we have data AND results
          
          if isempty(getappdata(handles.gawindow,'control_mode'))
            %visiblility
            set([handles.populationsize handles.populationsizemin handles.populationsizemax],'Visible','Off');
            set([handles.windowwidth handles.windowwidthmin handles.windowwidthmax]         ,'Visible','Off');
            set([handles.initialterms handles.initialtermsmin handles.initialtermsmax]      ,'Visible','Off');
            if get(handles.pls,'Value')
              set([handles.lvs handles.lvsmin handles.lvsmax]                               ,'Visible','On');
            else
              set([handles.lvs handles.lvsmin handles.lvsmax]                               ,'Visible','Off');
            end
          end
          %buttons
          set(handles.execute,'String','Repeat');
          if isempty(getappdata(handles.gawindow,'resumeinfo'));    %no resume info?
            set(handles.execute,'Visible','on','enable','on');      %Yes to execute
            set(handles.resume,'Visible','off','Enable','off');     %no to resume
          else  %we're in a paused state
            set(handles.execute,'Visible','off','enable','off');      %no to execute
            set(handles.resume,'Visible','On','Enable','On');         %yes to resume
          end
          if ~isempty(getappdata(handles.gawindow,'ffit'))
            %buttons
            set([handles.plotfit handles.plotfreq],'Visible','on','Enable','on');
            %menus
            set([handles.saveresults handles.savebest handles.clearresults],'enable','on');
          else      %don't have finished data yet (only resumeinfo)
            set([handles.plotfit handles.plotfreq],'Visible','on','Enable','off');
            %menus
            set([handles.saveresults handles.savebest],'enable','off');
            set([handles.clearresults],'enable','on');
          end
          
        end
      end
      
      %update status box
      
      pre = getappdata(handles.gawindow,'preprocessing');
      if isempty(xdat) | isempty(ydat);
        status = {'Data: none','','Results: none',''};
      else
        if ~isempty(xdat);
          sz = size(xdat);
          status{1} = ['X-Block: ' modl.datasource{1}.name ' (' ...
            sprintf('%ix',sz(1:end-1)) sprintf('%i',sz(end)) ')'];
          switch length(pre{1})
            case 0
              status{1} = [status{1} ' [Pre: none]'];
            case 1
              status{1} = [status{1} ' [Pre: ' pre{1}.description ']'];
            otherwise
              status{1} = [status{1} ' [Pre: ' pre{1}(1).description ',...]'];
          end
        else
          status{1} = 'X-Block: none';
        end
        
        if ~isempty(ydat);
          sz = size(ydat);
          status{2} = ['Y-Block: ' modl.datasource{2}.name ' (' ...
            sprintf('%ix',sz(1:end-1)) sprintf('%i',sz(end)) ')'];
          switch length(pre{2})
            case 0
              status{2} = [status{2} ' [Pre: none]'];
            case 1
              status{2} = [status{2} ' [Pre: ' pre{2}.description ']'];
            otherwise
              status{2} = [status{2} ' [Pre: ' pre{2}(1).description ',...]'];
          end
        else
          status{2} = 'Y-Block: none';
        end
        
        if isfield(modl,'rmsecv') & ~isempty(modl.rmsecv)
          status{3} = [sprintf('Results: %i models',length(modl.rmsecv))];
          status{4} = [sprintf('         with %i to %i variables',...
            min(sum(modl.icol,2)),max(sum(modl.icol,2)))];
        else
          status{3} = 'Results: none';
          status{4} = '';
        end
      end
      set(handles.statusbox,'string',status)
      
    case {'autoload','loaddata','loadnewy'}
      
      if donotclear(handles); return; end
      
      %load x-block
      switch action
        case 'loaddata'
          [xdat,xname] = lddlgpls('doubdataset','cal X-block');
          if isempty(xdat); return; end
        case 'autoload'
          xdat  = getappdata(handles.gawindow,'autoloadxdata');
          xname = getappdata(handles.gawindow,'autoloadxname');
        otherwise
          xname  = modl.datasource{1}.name;            %get xname from existing model info
      end
      
      %load y-block
      switch action
        case 'autoload'
          ydat  = getappdata(handles.gawindow,'autoloadydata');
          yname = getappdata(handles.gawindow,'autoloadyname');
        otherwise
          if ~isempty(xdat);
            [ydat,yname] = lddlgpls({'double','dataset','logical'},'cal Y-block');
            if isempty(ydat); return; end
          end
      end
      
      if isa(xdat,'dataset') & ~isa(ydat,'dataset'); ydat = dataset(ydat); end
      
      %check for mismatch of includ fields
      if isa(xdat,'dataset') & isa(ydat,'dataset');  %both are datasets? check includ fields for sample mismatch
        if length(xdat.includ{1}) ~= length(ydat.includ{1}) | any(xdat.includ{1} ~= ydat.includ{1});
          %evrimsgbox({'Include fields of X- and Y-blocks do not match','Using intersection'},'Load Data','warn','modal');
          includ = intersect(xdat.includ{1},ydat.includ{1});
          xdat.includ{1} = includ;
          ydat.includ{1} = includ;
        end
      end
      
      modl = genalg('updatemodel',h);   %initialize/update model
      
      %extract data from datasets (if necessary)
      [datasource{1:2}] = getdatasource(xdat,ydat);
      modl.datasource = datasource;
      if isa(xdat,'dataset');
        if ndims(xdat.data)>2 | iscell(xdat.data);
          erdlgpls('X-block data must be an array and cannot be batch', ...
            'Error on Load Data!')
          return
        end
        incl = xdat.includ;
        
        % Get DSO fields for 'included' subset of data and save to a model
        % Use a PLS model, though the modeltype is not significant.
        xdattemp=xdat(incl{:});
        tmodel = modelstruct('PLS');
        dsfieldsincl = copydsfields(xdattemp, tmodel);
        
        xdat = xdat.data(incl{:});      %extract relevent data
      end
      if isa(ydat,'dataset');
        if ndims(ydat.data)>2 | iscell(ydat.data);
          erdlgpls('Y-block data must be vector or array and cannot be batch', ...
            'Error on Load Data!')
          return
        end
        incl = ydat.includ;
        ydat = ydat.data(incl{:});      %extract relevent data
      end
      
      %test other aspects of data for potential errors
      if size(xdat,1)~=size(ydat,1)
        erdlgpls('number of samples in X and Y must be equal', ...
          'Error on Load Data!')
        return
      elseif size(xdat,1)==1|size(xdat,2)==1
        erdlgpls('X-block must be a matrix','Error on Load Data!')
        return
        %       elseif any(any(isinf(xdat)))|any(any(isnan(xdat)))
        %         erdlgpls('X-block contains "inf" or "NaN" unable to analyze', ...
        %           'Error on Load Data!')
        %         return
      elseif mdcheck(ydat)
        erdlgpls('Y-block contains "inf" or "NaN" unable to analyze', ...
          'Error on Load Data!')
        return
      end
      
      if mdcheck(xdat);
        evrimsgbox({'Missing Data Found - Replacing with "best guess"','Results may be affected by this action.'},'Warning: Replacing Missing Data','warn','modal');
        [flag,missmap,xdat] = mdcheck(xdat);
      end
      
      setappdata(handles.gawindow,'xblock',xdat);     %xblock data
      setappdata(handles.gawindow,'yblock',ydat);     %yblock data
      setappdata(handles.gawindow,'modl',modl);       %model info
      setappdata(handles.gawindow,'dsfieldsincl',dsfieldsincl);       %orig DSO info
      
      modl = genalg('clearsettings_int',h);
      
      if isempty(modl.datasource{1}.name); modl.datasource{1}.name = xname; end
      if isempty(modl.datasource{2}.name); modl.datasource{2}.name = yname; end
      modl.datasource{1}.size = size(xdat);
      modl.datasource{2}.size = size(ydat);
      
      setappdata(handles.gawindow,'modl',modl);
      
      genalg('initialize',h);                  %reinitialize window
      
      modl = genalg('updatemodel',h);
      genalg('activate',h);
      
    case 'saveresults'
      modl = genalg('updatemodel',h);
      svdlgpls(modl,'GenAlg Results')
      setappdata(handles.saveresults,'timestamp',modl.time)
      
    case 'savebest'
      [what,where] = sort(modl.rmsecv);
      best         = modl.icol(where(1),:);
      
      switch get(gcbo,'tag')
        case 'bestasdataset'
          mydata              = dataset(xdat);
          % Add the DSO fields which were 'included' in orig DSO
          if ~isempty(dsfieldsincl) & (isa(dsfieldsincl, 'dataset') | ismodel(dsfieldsincl))
            mydata            = copydsfields(dsfieldsincl, mydata);
          end
          mydata.author       = 'genalg';
          mydata.description  = ['GenAlg Best Variables from ' mydata.name];
          mydata.name         = [mydata.name '_GenAlg'];
          mydata.includ{2}    = find(best);
        case 'bestasmatrix'
          mydata              = xdat(:,logical(best));
      end
      
      svdlgpls(mydata,'GenAlg Best Variables')
      
    case 'savesettings'
      modl = genalg('updatemodel',h);
      sets.modeltype = 'GENALG Settings';
      sets.info = 'Genetic Algorithm Settings';
      for k = fieldnames(modl.detail.options)';
        sets = setfield(sets,k{1},getfield(modl.detail.options,k{1}));
      end
      sets.datasource = modl.datasource;
      
      svdlgpls(sets,'GenAlg Settings')
      
    case 'loadsettings'
      if donotclear(handles); return; end
      
      [newmodl,newmodlname] = lddlgpls('struct','GenAlg Model');
      
      if ~isempty(newmodl)
        if ~ismodel(newmodl) | ~any(ismember(lower(newmodl.modeltype),{'genalg settings','genalg'}))
          erdlgpls('Not a Genetic Algorithm Settings structure or model', ...
            'Error on Load Settings!')
        else
          if isfield(newmodl,'datasource')   %for backwards compatibility
            badvars = (newmodl.datasource{1}.size(2) ~= size(xdat,2));
          else
            badvars = 0;
          end
          if badvars
            erdlgpls(['Warning! Number of variables do not match. Some variable-number based settings were not loaded.'], ...
              'Warning on Load Settings')
          end
          
          setappdata(handles.gawindow,'resumeinfo',[]);   %resume from pause status
          setappdata(handles.gawindow,'ffit',[]);         %assembled fit results
          setappdata(handles.gawindow,'gpop',[]);         %assembled populations
          
          modl.detail.options = newmodl;   %temporarily move this into modl
          set(handles.populationsize,'value',modl.detail.options.popsize);
          genalg('actpopulationsize',h)
          
          if ~badvars
            set(handles.windowwidth,'value',modl.detail.options.windowwidth);
            genalg('actwindowwidth',h)
          end
          
          set(handles.initialterms,'value',modl.detail.options.initialterms);
          genalg('actpopulationsize',h)
          
          if ~badvars | modl.detail.options.targetpct
            set(handles.targetmin,'string',num2str(modl.detail.options.target(1)))
            set(handles.targetmax,'string',num2str(modl.detail.options.target(2)))
            set(handles.targetpercent,'value',modl.detail.options.targetpct);
            genalg('acttargmin',h)
          end
          
          set(handles.penaltyslope,'value',modl.detail.options.penaltyslope);   %target min,max & penalty
          genalg('actpenalty',h)
          
          set(handles.maxgenerations,'value',modl.detail.options.maxgenerations);
          genalg('actmaxgenerations',h)
          
          set(handles.convergence,'value',modl.detail.options.convergence);
          genalg('actconvergence',h)
          
          set(handles.mutationrate,'value',modl.detail.options.mutationrate);
          genalg('actmutationrate',h)
          
          if modl.detail.options.crossover == 1;
            genalg('single',h)
          else
            genalg('double',h)
          end
          
          if ~badvars
            set(handles.lvs,'value',modl.detail.options.ncomp);
            genalg('actlvs',h)
          end
          
          if strcmp(modl.detail.options.algorithm,'pls');
            genalg('pls',h);
          else
            genalg('mlr',h);
          end
          
          if strcmp(modl.detail.options.cv,'random');
            genalg('random',h);
          else
            genalg('contiguous',h);
          end
          
          if ~badvars
            set(handles.subsets,'value',modl.detail.options.split);   %splits
            genalg('actsubsets',h);
          end
          
          setappdata(handles.gawindow,'preprocessing',modl.detail.options.preprocessing);
          
          set(handles.iterations,'value',modl.detail.options.iter);
          genalg('actiterations',h);
          
          set(handles.replicates,'string',num2str(modl.detail.options.reps));
          genalg('actreplicates',h);
          
          modl = genalg('updatemodel',h);
          genalg('activate',h);
          
        end
      end
      
    case 'cleardata'
      
      if donotclear(handles); return; end
      
      setappdata(handles.gawindow,'xblock',[]);     %xblock data
      setappdata(handles.gawindow,'yblock',[]);     %yblock data
      
      modl = genalg('clearsettings_int',h);
      
      modl.datasource = {getdatasource getdatasource};
      setappdata(handles.gawindow,'modl',modl);
      modl = genalg('updatemodel',h);
      
      %Reset preprocessing to gaselctr.
      opts=gaselctr('options');
      setappdata(handles.gawindow,'preprocessing',{preprocess('default',opts.preprocessing{1}) preprocess('default',opts.preprocessing{2})});
      
      genalg('initialize',h);                  %reinitialize window
      
    case {'clearresults','clearsettings','clearsettings_int'}
      
      %clearsettings_int is used internally and does not ask if data
      %  should be cleared
      if ~strcmp(action,'clearsettings_int');
        if donotclear(handles); return; end
      end
      
      setappdata(handles.gawindow,'resumeinfo',[]);   %resume from pause status
      setappdata(handles.gawindow,'ffit',[]);         %assembled fit results
      setappdata(handles.gawindow,'gpop',[]);         %assembled populations
      modl = genalg('updatemodel',h);
      
      rsltsplot = getappdata(handles.gawindow,'GAResultsPlot');
      if ~isempty(rsltsplot) & ishandle(rsltsplot);
        close(rsltsplot);
      end
      
      if ~strcmp(action,'clearresults');
        genalg('initialize',h);                  %reinitialize settings
        modl = genalg('updatemodel',h);
      end
      genalg('activate',h);
      
      if nargout == 1;
        varargout = {modl};
      end
      
    case 'updatemodel'
      
      if isempty(modl)
        modl = modelstruct('genalg');
      end
      
      rmsecv      = getappdata(handles.gawindow,'ffit');   %ffit
      icol        = getappdata(handles.gawindow,'gpop');   %gpop
      
      if  ~isempty(rmsecv) & ...
          (any(size(rmsecv) ~= size(modl.rmsecv)) ...
          | any(size(icol) ~= size(modl.icol))...
          | any(rmsecv ~= modl.rmsecv));   %has data changed?
        modl.date        = date;    %date
        modl.time        = clock;   %time
      end
      modl.rmsecv      = rmsecv;  %fit
      modl.icol        = icol;    %pop
      modl.detail.avefit   = getappdata(handles.gawindow,'cavfit');
      modl.detail.bestfit  = getappdata(handles.gawindow,'cbfit');
      
      
      modl.detail.options.popsize       = round(get(handles.populationsize,'value'));
      modl.detail.options.windowwidth   = round(get(handles.windowwidth,'value'));
      modl.detail.options.initialterms  = get(handles.initialterms,'value');
      modl.detail.options.target        = [str2num(get(handles.targetmin,'string')) str2num(get(handles.targetmax,'string'))];    %target min,max
      modl.detail.options.penaltyslope  = get(handles.penaltyslope,'value');   %target penalty
      modl.detail.options.targetpct     = get(handles.targetpercent,'value');
      modl.detail.options.maxgenerations= round(get(handles.maxgenerations,'value'));
      modl.detail.options.convergence   = get(handles.convergence,'value');
      modl.detail.options.mutationrate  = get(handles.mutationrate,'value');
      modl.detail.options.crossover     = get(handles.single,'value') + get(handles.double,'value')*2;
      if get(handles.pls,'value');
        modl.detail.options.algorithm  = 'pls';
      else
        modl.detail.options.algorithm  = 'mlr';
      end
      modl.detail.options.ncomp           = round(get(handles.lvs,'value'));
      modl.detail.options.preprocessing   = getappdata(handles.gawindow,'preprocessing');   %mean centering
      modl.detail.options.preapply        = strcmp(get(handles.preapply,'checked'),'on');
      if get(handles.random,'value');
        modl.detail.options.cv          = 'rnd';       %random or contiguous
      else
        modl.detail.options.cv          = 'con';   %random or contiguous
      end
      modl.detail.options.split         = round(get(handles.subsets,'value'));   %splits
      modl.detail.options.iter          = round(get(handles.iterations,'value'));
      modl.detail.options.reps          = str2num(get(handles.replicates,'string'));
      
      %save model to window
      if ishandle(handles.gawindow);    %window still exists? save modl
        setappdata(handles.gawindow,'modl',modl);
      end
      if nargout == 1;
        varargout = {modl};
      end
      
    case {'garun','resum'}
      
      if isempty(getappdata(handles.gawindow,'control_mode'))
        %make these invisible
        set([handles.populationsize handles.populationsizemin handles.populationsizemax],'Visible','Off');
        set([handles.maxgenerations handles.maxgenerationsmin handles.maxgenerationsmax],'Visible','Off');
        set([handles.mutationrate handles.mutationratemin handles.mutationratemax]      ,'Visible','Off');
        set([handles.windowwidth handles.windowwidthmin handles.windowwidthmax]         ,'Visible','Off');
        set([handles.convergence handles.convergencemin handles.convergencemax]         ,'Visible','Off');
        set([handles.initialterms handles.initialtermsmin handles.initialtermsmax]      ,'Visible','Off');
        set([handles.lvs handles.lvsmin handles.lvsmax]                                 ,'Visible','Off');
        set([handles.subsets handles.subsetsmin handles.subsetsmax]                     ,'Visible','Off');
        set([handles.iterations handles.iterationsmin handles.iterationsmax]            ,'Visible','Off');
        set([handles.penaltyslope handles.penaltyslopemin handles.penaltyslopemax]      ,'Visible','Off');
        
        %disable these
        set([handles.targetmin handles.targetmax handles.targetpercent]                 ,'Enable','Off');
        set(handles.replicates,'enable','off');
        
        for i = [handles.single handles.double handles.mlr handles.pls handles.random handles.contiguous]
          if get(i,'Value') == 0
            set(i,'Visible','Off');
          end
        end
      end
      
      myopts = modl.detail.options;
      set(handles.execute,'Visible','Off');
      set(handles.resume,'Visible','Off');                         %turn off resume button
      set(handles.stop,'Visible','On','Enable','On','UserData',0);
      
      set([handles.GAfile handles.tools],'enable','off');
      
      set([handles.plotfit handles.plotfreq],'Enable','off');                  %turn off plot button
      
      if ~isfield(myopts,'plots')
        gasopts = gaselctr('options');
        myopts.plots = gasopts.plots;
      end
      
      if ~strcmp(myopts.plots,'off') & (isempty(getappdata(handles.gawindow,'GAResultsPlot')) ...
          | ~ishandle(getappdata(handles.gawindow,'GAResultsPlot')));
        
        resultsfig = figure('Name','GA for Variable Selection Results',...
          'units','normalized',...
          'Pos',[0.4863    0.4753    0.4688    0.4167],...
          'Resize','On',...
          'tag','GAResultsPlot',...
          'NumberTitle','Off');
        
        setappdata(handles.gawindow,'GAResultsPlot',resultsfig);
      end
      
      genalg('updatemodel',handles.gawindow);  %make sure stored model reflects current control status
      
      drawnow
      switch action
        case 'garun'
          set(handles.replicates,'userdata',0);              %Set replicate count
          gaselctr(handles.gawindow,'gogas');
        case 'resum'
          gaselctr(handles.gawindow,'resum');
      end
      
      modl = genalg('updatemodel',h);      %update model
      genalg('activate',h);                %update buttons/controls
      
      ftag = get(ancestor(varargin{1},'figure'),'tag');
      if strcmpi(ftag,'gawindow')
        ph = getappdata(handles.gawindow,'analysis_parent');
        if ~isempty(ph)
          %Tell panel to update model results if needed.
          variableselectiongui('vsexecute_Callback',findobj(ph,'tag','vsexecute'), [], [], 1)
        end
      end
      
    case 'stop'
      
      waspaused = get(handles.stop,'userdata');
      set(handles.stop,'Enable','On','UserData',waspaused+1,'String','Pausing...');
      
      lasttime = getappdata(handles.stop,'stillrunning');           %get last update ("still running!") time
      if waspaused>3 | (now-lasttime)>(60)/60/60/24;  %not apparently running?
        modl = genalg('updatemodel',h);      %update model
        genalg('activate',h);                %update buttons/controls
        if ishandle(getappdata(handles.stop,'resultsfig'))
          close(getappdata(handles.stop,'resultsfig'));  %force gaselctr to stop if it DOES respond again
        end
      end
      
    case 'plotfreq'
      gpop = getappdata(handles.gawindow,'gpop');     %assembled populations
      
      figure
      if size(gpop,1)==1;
        bar(gpop);
      else
        bar(mean(gpop));
      end
      ylabel('Frequency of Inclusion')
      if get(handles.windowwidth,'value') > 1
        xlabel('Window number')
        title('Frequency of Window Usage in Models')
      else
        xlabel('Variable number')
        title('Frequency of Variable Usage in Models')
      end
      
      spectrum = xdat;
      %give mean spectrum if it isn't already
      if size(spectrum,1) ~= 1 & size(spectrum,2) ~= 1;
        spectrum = mean(spectrum);
      end;
      xaxis = 1:length(spectrum);
      ax = axis;
      hold on
      scalingfactor = 1.02; %Determine how big the spectrum should be relative to the points
      h = plot(xaxis,(spectrum-min(spectrum))/max(spectrum-min(spectrum))*(ax(4)*scalingfactor),'r');
      set(h,'linewidth',2,'color',[.8 0 0]);
      hold off
      yscale;
      
      
    case 'plotfit'
      modl = genalg('updatemodel',h);      %update model
      xdat = getappdata(handles.gawindow,'xblock');
      genalgplot(modl,xdat)                %do plot
      
    case 'quit'
      if donotclear(handles); return; end
      
      rsltsplot = getappdata(handles.gawindow,'GAResultsPlot');
      if ~isempty(rsltsplot) & ishandle(rsltsplot);
        close(rsltsplot);
      end
      delete(handles.gawindow);
      
      browse reactivate  %bring browse to front if it already exists
      
    case 'actpenalty'
      penalty = get(handles.penaltyslope,'value');
      set(handles.penaltyslopetext,'String',num2str(penalty));
      if penalty == 0;
        set(handles.targetpercent,'enable','off');
        set(handles.targetmin,'enable','off');
        set(handles.targetmax,'enable','off');
      else
        set(handles.targetpercent,'enable','on');
        set(handles.targetmin,'enable','on');
        set(handles.targetmax,'enable','on');
      end
      
    case {'acttargmin','acttargmax','acttargpct'}
      low  = str2num(get(handles.targetmin,'string'));
      high = str2num(get(handles.targetmax,'string'));
      if isempty(low)  | ~isfinite(low);  low  = 0;   end
      if isempty(high) | ~isfinite(high); high = 100; end
      if low>high;
        temp = low;
        low  = high;
        high = temp;
      end
      if get(handles.targetpercent,'value');
        if low  < 0;   low  = 0;   end
        if low  > 100; low  = 100; end
        if high < 0;   high = 0;   end
        if high > 100; high = 100; end
      else
        if low  < 1;   low  = 1;   end
        if low  > nx;  low  = nx;  end
        if high < 1;   high = 1;   end
        if high > nx;  high = nx;  end
      end
      set(handles.targetmin,'string',num2str(low));
      set(handles.targetmax,'string',num2str(high));
      
    case 'actreplicates'
      reps = get(handles.replicates,'string');
      reps = str2num(reps);
      if isempty(reps) | ~isfinite(reps); reps = 1; end
      if reps<1; reps = 1; end;
      set(handles.replicates,'string',num2str(reps));
    case {'act21','actpopulationsize'}
      ps  = 4*round(get(handles.populationsize,'Val')/4);
      set(handles.populationsizetext,'String',num2str(ps));
    case {'act31','actmaxgenerations'}
      mg  = round(get(handles.maxgenerations,'Val'));
      set(handles.maxgenerationstext,'String',num2str(mg));
    case {'act41','actmutationrate'}
      mr = 1e-3*round(get(handles.mutationrate,'Val')/1e-3);
      set(handles.mutationratetext,'String',num2str(mr));
    case {'act51','actwindowwidth'}
      ww = round(get(handles.windowwidth,'Val'));
      set(handles.windowwidthtext,'String',num2str(ww));
      ph = getappdata(handles.gawindow,'analysis_parent');
      if ~isempty(ph) & ishandle(ph)
        %Update panel.
        set(findobj(ph,'tag','gawindowwidth'),'value',ww);
        set(findobj(ph,'tag','gawindowwidthtext'),'string',num2str(ww));
      end
    case {'act61','actconvergence'}
      cc = round(get(handles.convergence,'Val'));
      set(handles.convergencetext,'String',num2str(cc));
    case {'act71','actinitialterms'}
      ft = round(get(handles.initialterms,'Val'));
      set(handles.initialtermstext,'String',num2str(ft));
    case 'single'
      set(handles.single,'Value',1);
      set(handles.double,'Value',0);
      setappdata(handles.gawindow,'crossover',1);
    case 'double'
      set(handles.single,'Value',0);
      set(handles.double,'Value',1);
      setappdata(handles.gawindow,'crossover',2);
    case 'mlr'
      set(handles.mlr,'Value',1);
      set(handles.pls,'Value',0);
      set([handles.lvs handles.lvstext handles.lvsmin handles.lvsmax handles.lvslabel],'Enable','off');
    case 'pls'
      set(handles.mlr,'Value',0);
      set(handles.pls,'Value',1);
      set([handles.lvs handles.lvstext handles.lvsmin handles.lvsmax handles.lvslabel],'Enable','on');
    case {'act101','actlvs'}
      lvs = round(get(handles.lvs,'Val'));
      set(handles.lvstext,'String',num2str(lvs));
      ph = getappdata(handles.gawindow,'analysis_parent');
      if ~isempty(ph) & ishandle(ph)
        %Update panel.
        set(findobj(ph,'tag','galvs'),'value',lvs);
        set(findobj(ph,'tag','galvstext'),'string',num2str(lvs));
      end
    case 'random'
      set(handles.random,'Value',1);
      set(handles.contiguous,'Value',0);
      set(handles.iterations,'enable','on');
    case 'contiguous'
      set(handles.random,'Value',0);
      set(handles.contiguous,'Value',1);
      set(handles.iterations,'enable','on');  %NOTE: iterations IS used with GA contiguous block!
    case {'act121','actsubsets'}
      if nargin>3 & ~isempty(varargin{2})
        cvs = round(varargin{2});
        if ~isempty(cvs) & isnumeric(cvs) & isfinite(cvs)
          set(handles.subsets,'Val',cvs);
        else
          return;
        end        
      else
        cvs = round(get(handles.subsets,'Val'));
      end
      set(handles.subsetstext,'String',num2str(cvs));
      ph = getappdata(handles.gawindow,'analysis_parent');
      if ~isempty(ph) & ishandle(ph)
        %Update panel.
        set(findobj(ph,'tag','gasubsets'),'value',cvs);
        set(findobj(ph,'tag','gasubsetstext'),'string',num2str(cvs));
      end
    case {'act131','actiterations'}
      if nargin>3 & ~isempty(varargin{2})
        cvi = round(varargin{2});
        if ~isempty(cvi) & isnumeric(cvi) & isfinite(cvi)
          set(handles.iterations,'Val',cvi)
        else
          return;
        end
      else
        cvi = round(get(handles.iterations,'Val'));
      end
      set(handles.iterationstext,'String',num2str(cvi));
    case 'preproxblk'
      prepro = getappdata(handles.gawindow,'preprocessing');
      if ~iscell(prepro) | length(prepro)<2;
        prepro = {[] []};
      end
      if length(varargin)==2
        prepro{1} = preprocess('validate',varargin{2});
      else
        prepro{1} = preprocess(prepro{1},xdat,ydat);
      end
      setappdata(handles.gawindow,'preprocessing',prepro);
      genalg('activate',h);       %update enable and visible statuses
    case 'preproyblk'
      prepro = getappdata(handles.gawindow,'preprocessing');
      if ~iscell(prepro) | length(prepro)<2;
        prepro = {[] []};
      end
      if length(varargin)==2
        prepro{2} = preprocess('validate',varargin{2});
      else
        prepro{2} = preprocess(prepro{2},ydat);
      end
      setappdata(handles.gawindow,'preprocessing',prepro);
      genalg('activate',h);       %update enable and visible statuses
      
    case 'preapply'
      %umtoggle(handles.preapply);
      str = get(handles.preapply,'checked');
      if strcmp(str,'on')
        newstr = 'off';
      else
        newstr = 'on';
      end
      set(handles.preapply,'checked',newstr)
      
      if strcmp(get(handles.preapply,'checked'),'on')
        warned = getappdata(handles.gawindow,'preapplywarning');
        if isempty(warned) | ~warned
          evrimsgbox({['The "Apply Before Analysis" option will make Genetic Analysis faster by '...
            'calculating preprocessing prior to variable selection. It may, however, '...
            'reduce the accuracy of determined fit values. When using this feature '...
            'you should only consider fit values relative to each other.']
            ' '
            ['After analysis, '...
            'you may want to repeat the cross-validation with only the selected '...
            'variables to get accurate cross-validation results.']},'Apply Before Analysis Warning','warn','modal');
        end
        setappdata(handles.gawindow,'preapplywarning',1);
      end
      
    case 'drop'
      % show results
      if length(varargin)>3
        tmp = varargin{4};
        if ~isempty(tmp) & ismodel(tmp) & strcmpi(tmp.modeltype, 'genalg')
          genalgplot(tmp)
        end
      end
      
    otherwise
      erdlgpls([action ' not yet defined'],'Error on callback')
  end
  
end

%--------------------------------------------------------------------------------------------------
function abort = donotclear(handles);
% general function which returns 0 if results have been saved (or do not exist)
% and 1 if the results HAVEN'T been saved and the user says to cancel the operation
%  can be called like:
%  if donotclear(handles); return; end


modl    = getappdata(handles.gawindow,'modl');
abort   = 0;

if ~isempty(getappdata(handles.gawindow,'control_mode'))
  %Window being controled by Analysis select vars. Don't prompt.
  return
end

if (isempty(modl) | ~isfield(modl,'time') | isempty(modl.time)) ...
    & isempty(getappdata(handles.gawindow,'resumeinfo'));   %no model, no resume, no point in bothering
  return
end

if ~isempty(getappdata(handles.gawindow,'resumeinfo')) ...
    | isempty(getappdata(handles.saveresults,'timestamp')) ...
    | any(getappdata(handles.saveresults,'timestamp')~=modl.time);   %results not saved
  myans = evriquestdlg('Warning! This will erase current unsaved results. Continue?', ...
    'Warning: Unsaved results','OK','Cancel','OK');
  switch myans
    case {'Cancel'}
      abort = 1;
  end
end

