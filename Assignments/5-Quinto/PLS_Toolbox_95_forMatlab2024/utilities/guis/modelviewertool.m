function info=modelviewertool(plotfunction,mode);
%MODELVIEWERTOOL Unsupported utility.

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%   1 : Line plot loadings
%   2 : Bar plot residuals
%   3 : Influence plot
%   4 : Corcondia
%   5 : Scatter of all scores
%   6 : Histogram of residuals
%   7 : Normal probability plot
%   8 : Raw Residuals
%   9 : Plot of model/rawdata (assuming first mode samples)
%   10: Variance of each component
%   11: Tucker core list (only tucker)
%   12: T/U plot
%   13: Pred vs Meas plot (only NPLS)
%   14: Line plots of first mode loadings for PARAFAC2
%   15: Line plots of first mode loadings for PARAFAC2 scaled by last mode  scores
%   16: Splithalf quality
%   17: PARAFAC2 model quality
%   18: Residual plot for PARAFAC2 replacing 8 (used in PARAFAC and others)


% rb, june 2004, fixed error in influence spawning when variables were excluded
% rb, dec, 2004, replaced leverage with model.tsqs in influence plot (to avoid memory problems for large arrays)
% rb, mar, 2005, modified raw data plot to include missing data
% rb, may, 2006, fixed error in plots when samplemode ~=1 and samples deleted
% rb, ..
% rb, Jan, 2015, added PARAFAC model quality
% rb, Jan, 2017, added PARAFAC2 GCMS model quality

info = '';

fig = gcf;
if ~strcmpi(get(fig,'tag'),'ModelViewerFig')
    fig = findobj(0,'Tag','ModelViewerFig');
    fig = fig(end);
end
figure(fig);

switch plotfunction
    case 1
        npload(mode);
    case  2
        npresbar(mode);
    case  3
        npinfluence(mode);
    case  4
        npcorcondia(mode);
    case 5
        npscatter(mode);
    case  6
        nphistres(mode);
    case  7
        npnormplot(mode);
    case  8
        npresdata(mode);
    case  9
        nprawdata(mode);
    case  10
        npuniqvar(mode);
    case  11
        npcoreplot(mode);
    case  12
        nptuplot(mode);
    case  13
        nppredplot(mode);
    case  14
        nppf2load(mode);
    case  15
        nppf2load2(mode);
    case  16
        nppfqual(mode);
    case  17
        nppf2qual(mode);
    case  18
        nppf2res(mode);
    otherwise
        error(' Plot unknown')
end





%--------------------------------------------------------------
function info = npload(mode);
%NPLOAD loading plot
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

% NUMBER 1

% Load data
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{1} = ['Loadings M',num2str(mode)];
info{2} = 'Line plot of loadings in one mode. Press the axes (white background) to see loadings in another mode.';

loading=model.loads{mode};
if isstruct(loading)  % PARAFAC2 first mode
    loading = loading.P{1}*loading.H;
    pf2=1;
else
    pf2=0;
end

if isfield(model.detail.options,'samplemode')
    if model.detail.options.samplemode==mode % exclude soft-deleted samples
        inc = model.detail.includ{mode};
        loading=loading(inc,:);
    end
end

% Do the actual plotting
plot(loading,'LineWidth',2,'hittest','off');
set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
axis tight,grid off
hline('k--'); vline('k--');
t=title(info{1},'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])
if pf2
    title('Only slab 1 loadings')
end

% Add function for new small plot of next mode
%'if strcmp(get(gcf,''selectiontype''),''normal''),modelviewertool(1,',num2str(nextmode),');end'
set(gca,'ButtonDownFcn','modelviewcb(11)');

setappdata(gca,'mode',mode);

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu1');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu1');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
%cb1 = ['m = get(gcf,''userdata'');figure,L = dataset([m{1}.loads{m{3}}]);if ~isa(m{2},''dataset'');m{2}=dataset(m{2});end,m{2},L,m{3},L = copydsfields(m{2},L,{m{3} 1});L.axisscale{2}=[1:size(m{1}.loads{m{3}},2)]'';L.axisscalename{2} = ''Component number'';plotgui(L,''linestyle'',''-'',''axismenuvalues'',{0 1:size(L.data,2)});'];
if ~pf2
    item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(1)');
else
    item1 = uimenu(cmenu,'Label','Plot not available for mode 1. Use the rightmost figure of all modes instead');
end


%--------------------------------------------------------------
function info = npresbar(mode);
%NPRESBAR sumsquared residual plot
% Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

% NUMBER 2

m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{1} = ['Res. Sum Sq. M',num2str(mode)];
info{2} = 'Shows the residual sum of squares. The squared residuals are summed over all but one mode, so the result is that a residual sum of square is obtained for each entity in the mode shown. Green line is 95 confidence limit, red is 99 (not always visible). Press the axes (white background) to see loadings in another mode.';

% Do the actual plotting
ssq = model.ssqresiduals{mode};
if isfield(model.detail.options,'samplemode')
    if model.detail.options.samplemode==mode % exclude soft-deleted samples
        inc = model.detail.includ{mode};
        try
            ssq=ssq(inc);
        end
    end
end
bar(ssq,'hittest','off')

if isfieldcheck(model,'model.detail.reslim.lim95')
    % Might not be given if blockdetails = 'compact';
    if length(model.detail.reslim.lim95)>=mode
        hline(model.detail.reslim.lim95(mode),'-g')
    end
    if length(model.detail.reslim.lim99)>=mode
        hline(model.detail.reslim.lim99(mode),'-r')
    end
end
h = axis;
%h(2) = length(model.ssqresiduals{mode})+.5;axis(h); % Fix. Don't know why, but the scale is wrong if not set specifically
h(2) = length(ssq)+.5;axis(h); % Fix. Don't know why, but the scale is wrong if not set specifically

set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
grid off
t=title(info{1},'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])

% Add function for new small plot of next mode
%['if strcmp(get(gcf,''selectiontype''),''normal''),modelviewertool(2,',num2str(nextmode),');end']
set(gca,'ButtonDownFcn','modelviewcb(21)');

setappdata(gca,'mode',mode);

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu2');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu2');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(2)');

%--------------------------------------------------------------
function info = npinfluence(mode);
%NPINFLUENCE influence plot (ssq versus leverage)
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 3

% Load data
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{1} = ['Influence M',num2str(mode)];
info{2} = ['Plot of the residual sum of square versus the Hotelling T-squared values.'];

% Prepare data
loading=model.loads{mode};
if isstruct(loading) % If so, then its parafac2 mode 1
    % Do leverage on average loadings
    LL = loading.P{1}*loading.H;
    for k=2:length(loading.P)
        LL = LL+loading.P{k}*loading.H;
    end
    loading = LL;
end

if isfield(model.detail.options,'samplemodex')
    samplemodex = model.detail.options.samplemodex;
elseif isfield(model.detail.options,'samplemode')
    samplemodex = model.detail.options.samplemode;
else
    samplemodex = 1;
end

if mode == samplemodex
    
    inc = model.detail.includ{mode};
    % leverage = diag(loading*pinv(loading(inc,:)'*loading(inc,:))*loading');
    leverage = model.tsqs{mode};
    leverage = leverage(inc);
else
    % leverage = diag(loading*pinv(loading'*loading)*loading');
    leverage = model.tsqs{mode};
end
if abs(std(leverage))/norm(leverage)<100000*eps % can happen e.g. if there are only two points. It yields an error when plotting
    leverage = leverage + randn(size(leverage))/(100000*norm(leverage));
end

% Do the actual plotting
ssqresiduals = model.ssqresiduals{mode,1};
if mode == samplemodex
    try
        ssqresiduals = ssqresiduals(inc);
    end
end

if length(leverage)~=length(ssqresiduals)
  %There might be NaNs in ssqresiduals so try removing.
  ssqresiduals = ssqresiduals(~isnan(ssqresiduals));
end

plot(leverage,ssqresiduals,'bo','LineWidth',2,'hittest','off');
set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
axis tight,grid off
t=title(info{1},'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])
set(gca,'userdata',[leverage(:) ssqresiduals(:)]);
set(gca,'tag','influence')

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu3');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu3');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
%cb1 = ['m = get(gcf,''userdata'');data=get(findobj(''tag'',''influence''),''userdata'');L = dataset(data);L = copydsfields(m{2},L,{m{3} 1});L.label{2}={''Hotellings T-squared'',''sum-squared residuals''};L.title{2} = ''Diagnostics'';figure,plotgui(L,''axismenuvalues'',{1,2});'];
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(3)');
% Add function for new small plot of next mode
%['if strcmp(get(gcf,''selectiontype''),''normal''),modelviewertool(3,',num2str(nextmode),');end']
set(gca,'ButtonDownFcn','modelviewcb(31)');

setappdata(gca,'mode',mode);

%--------------------------------------------------------------
function info = npcorcondia(mode);
%NPCORCONDIA Corcondia plot
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 4

m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);

if strcmp(lower(model.modeltype),'parafac')
    if isfieldcheck(model,'model.detail.coreconsistency.consistency');
        conn2=model.detail.coreconsistency.consistency;
        if length(conn2)==1 & isnumeric(conn2);
            if conn2<0,
                conn='<0';
            else
                conn = num2str(round(conn2));
            end
            info{1} = ['Core Consistency ',conn];
        else
            info{1} = 'Core Consistency';
        end
    else
        info{1} = 'Core Consistency';
    end
elseif strcmp(lower(model.modeltype),'parafac2')
    if isfieldcheck(model,'model.detail.coreconsistency.consistency');
        conn2=model.detail.coreconsistency.consistency;
        if length(conn2)==1 & isnumeric(conn2);
            if conn2<0,
                conn='<0';
            else
                conn = num2str(round(conn2));
            end
            info{1} = ['Core Consistency ',conn];
        else
            info{1} = 'Core Consistency';
        end
    else
        info{1} = 'Core Consistency';
    end
end
info{2} = 'The core consistency plot shows the actual core elements (red & green) calculated from the PARAFAC loadings (or from a PARAFAC model inside a PARAFAC2 model). Ideally, these should follow the blue line which is simply a superdiagonal core with ones on the diagonal (might change if one dimension < number of factors). The red elements are those that should ideally be non-zero and the green one those that should be zero. The core consistency is measuring the deviation from the blue target. The core consistency should not be used alone for assessing the number of components. It merely provides an indication. Especially, for simulated data (that follow the model perfectly with random iid noise) the core consistency is known to be less reliable than for real data.';

data = [];
if isfield(model.detail,'coreconsistency')
    if isfield(model.detail.coreconsistency,'consistency')
        Consistency = model.detail.coreconsistency.consistency;
        G           = model.detail.coreconsistency.core;
        E          = model.detail.coreconsistency.detail;
    elseif isfield(model.detail.innercore.coreconsistency,'consistency')
        Consistency = model.detail.innercore.coreconsistency.consistency;
        G           = model.detail.innercore.coreconsistency.core;
        E          = model.detail.innercore.coreconsistency.detail;
    else
        E = [];
    end
    % Do the actual plotting
    data=[];
    if ~isempty(E)
        data = NaN*repmat(1,length(E.GG),3);
        data(E.bNonZero,1)=E.I(E.bNonZero);
        if length(E.bZero)>0
            data(E.bZero,1)=E.I(E.bZero);
            data(E.bZero,3)=E.GG(E.bZero);
        end
        data(E.bNonZero,2)=E.GG(E.bNonZero);
        
        %data = dataset(data);data.label{2}={'Target';'Ideally non-zero core elements';'Ideally zero core elements'};
        %plotgui(data,'axismenuvalues',{[-1] [-1 -2 -3] [-1]},'plotcommand',['delete(findobj(get(gca,''children''),''tag'',''''));set(findobj(get(gca,''children''),''tag'',''selection''),''linestyle'',''none'',''markersize'',10,''marker'',''o'',''linewidth'',2,''color'',[1 0 1]);dattags = findobj(get(gca,''children''),''tag'',''data'');set(dattags(3),''marker'',''none'',''linestyle'',''--'',''color'',[0 0 1]);set(dattags(2),''marker'',''o'',''linestyle'',''none'',''markersize'',6,''linewidth'',3,''color'',[1 0 0]);set(dattags(1),''marker'',''x'',''linestyle'',''none'',''markersize'',6,''linewidth'',4,''color'',[0 1 0]);set(gca,''yticklabel'',[],''xticklabel'',[]);'])
        
        
        plot([E.I(E.bNonZero);E.I(E.bZero)],'b--','LineWidth',1,'hittest','off')
        hold on
        plot(E.GG(E.bNonZero),'ro','LineWidth',2,'hittest','off')
        plot(length(E.bNonZero)+1:length(E.GG),E.GG(E.bZero),'gx','LineWidth',2,'hittest','off')
        hold off
    end
    set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
    axis tight,drawnow;grid off
    hline('k--'); vline('k--');
    t=title([info{1}],'color','blue');
    
    set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])
    set(gca,'userdata',data)
    setappdata(gca,'mode',mode);
    
    % SPAWN FIGURE
    cmenu = findobj(get(gca,'parent'),'tag','contextmenu4');
    if isempty(cmenu) | ~ishandle(cmenu)
        cmenu = uicontextmenu;
        set(cmenu,'tag','contextmenu4');
    else
        delete(allchild(cmenu));
    end
    set(gca,'uicontextmenu',cmenu);
    %cb1 = ['data=get(gca,''userdata'');data = dataset(data);data.label{2}={''Target'';''Ideally non-zero core elements'';''Ideally zero core elements''};figure;plotgui(data,''axismenuvalues'',{[-1] [-1 -2 -3] [-1]},''plotcommand'',[''delete(findobj(get(gca,''''children''''),''''tag'''',''''''''));set(findobj(get(gca,''''children''''),''''tag'''',''''selection''''),''''linestyle'''',''''none'''',''''markersize'''',10,''''marker'''',''''o'''',''''linewidth'''',2,''''color'''',[1 0 1]);dattags = findobj(get(gca,''''children''''),''''tag'''',''''data'''');set(dattags(3),''''marker'''',''''none'''',''''linestyle'''',''''--'''',''''color'''',[0 0 1]);set(dattags(2),''''marker'''',''''o'''',''''linestyle'''',''''none'''',''''markersize'''',6,''''linewidth'''',3,''''color'''',[1 0 0]);set(dattags(1),''''marker'''',''''x'''',''''linestyle'''',''''none'''',''''markersize'''',6,''''linewidth'''',4,''''color'''',[0 1 0]);set(gca,''''yticklabel'''',[],''''xticklabel'''',[]);''])'];
    item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(4)');
else
    axis off
    text(0,.7,'Core consistency','fontsize',8)
    text(0,.5,'not calculated','fontsize',8)
    text(0,.3,'(use CORCONDIA)','fontsize',8)
end

%--------------------------------------------------------------
function info = npscatter(mode);
%NPscatter loading scatter plots
%
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 5

myax = findobj(gcf,'tag','scatter');
if isempty(myax)
    %Must be first time through so use gca.
    myax = gca;
    set(myax,'tag','scatter')
end
axes(myax)

% Load data
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{1} = ['Scatter M',num2str(mode)];
info{2} = ['Scatter plots of pairs of loadings in each mode. Press the axes (white background) to see loadings in another mode and press red text to change pairs. Right-click in plot to spawn.'];

% Prepare data if not immediately appropriate
loading=model.loads{mode};
if isstruct(loading)  % PARAFAC2 first mode
    loading = loading.P{1}*loading.H;
end

if isfield(model.detail.options,'samplemode')
    if model.detail.options.samplemode==mode % exclude soft-deleted samples
        inc = model.detail.includ{mode};
        loading=loading(inc,:);
    end
end

% Check if prior model and use increase the factor numb (save as hidden in labels)
f = get(myax,'userdata');
if length(f)==2
    f1 = f(1);
    f2 = f(2);
    if f1>size(loading,2)|round(f1)~=f1
        f1 = 1;
    end
    if f2>size(loading,2)|round(f2)~=f2
        f2 = 2;
    end
    if f2>size(loading,2)
        f2=1;
    end
    
else
    f1 = 1;
    f2 = min(size(loading,2),2);
    if size(loading,2)==1
        f2=1;
    end
end

% Do the actual plotting
plot(loading(:,f1),loading(:,f2),'o','hittest','off');
set(myax,'tag','scatter')
% h2 = text('Parent',myax,'Units','normalized', ...
%   'ButtonDownFcn', 'modelviewcb(51)',...
%   'Color',[0 0 0],'HandleVisibility','off', ...
%   'HorizontalAlignment','center', ...
%   'Position',[1 1.2], ...
%   'Units','Normalized', ...
%   'FontSize',8, ...
%   'handlevisibility','on', ...
%   'String',['F',num2str(f1),',',num2str(f2)], ...
%   'Color','red',...
%   'FontWeight','Bold', ...
%   'VerticalAlignment','top');


set(myax,'units','pixels');
mypos = get(myax,'position');
set(myax,'units','normalized');

h2 = findobj(gcf,'tag','scatter_button');
if isempty(h2)
    h2 = uicontrol('tag','scatter_button', ...
        'Style','pushbutton',...
        'ForegroundColor','red',...
        'Units','pixels',...
        'Callback', 'modelviewcb(51)',...
        'HorizontalAlignment','center', ...
        'Position',[mypos(1)+mypos(3)+10 mypos(2)+mypos(4)+5 60 20], ...
        'FontSize',10, ...
        'String',['F',num2str(f1),',',num2str(f2)], ...
        'FontWeight','Bold');
else
    set(h2,...
        'Position',[mypos(1)+mypos(3)+10 mypos(2)+mypos(4)+5 40 20], ...
        'String',['F',num2str(f1),',',num2str(f2)]);
end

set(myax,'Xticklabel',[]);
set(myax,'Yticklabel',[]);
axis tight,grid off
ax = axis; hline('k--'); vline('k--'); axis(ax);
t=title(info{1},'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])
set(myax,'userdata',[f1 f2]);
set(myax,'tag','scatter')

% Button for picking other modes
%['if strcmp(get(gcf,''selectiontype''),''normal''),model = get(findobj(''tag'',''Fig1''),''userdata'');f=get(findobj(''tag'',''scatter''),''userdata'');if iscell(f);f=f{1};end,set(findobj(''tag'',''scatter''),''userdata'',[f+1]);X = model{2};model = model{1};modelviewertool(5,',num2str(mode),');end']


drawnow;

% Add function for new small plot of next mode
%['if strcmp(get(gcf,''selectiontype''),''normal''),info=modelviewertool(5,',num2str(nextmode),');end']
set(myax,'ButtonDownFcn','modelviewcb(52)');

setappdata(myax,'mode',mode);

% SPAWN FIGURE
cmenu = findobj(get(myax,'parent'),'tag','contextmenu5');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu5');
else
    delete(allchild(cmenu));
end
set(myax,'uicontextmenu',cmenu);
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(5)');

%--------------------------------------------------------------
function info = nphistres(mode);
%NPHISTRES histogram of residuals
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 6
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{1} = ['Res histogram'];
info{2} = ['Residual histogram useful for investigating if residuals are normally distributed'];
xhat  = datahat(model);

if isa(X,'dataset') % Then it's a SDO
    if isfieldcheck(model,'model.detail.options.samplemode');
        smpmd = model.detail.options.samplemode;
    else
        smpmd = 1;
    end
    inc=model.detail.includ;
    for i=1:length(inc)
        if i~=smpmd
            inc{i}=1:length(inc{i});
        end
    end
    %inc=X.includ;
    %if ~strcmp(model.modeltype,'PARAFAC2')
    %  inc{smpmd} = [1:size(X.data,smpmd)]';
    %end
    incX=X.include;
    X = X.data(incX{:});
    if strcmp(model.modeltype,'PARAFAC2')
        e = X-xhat;
    else
        if ndims(X)==ndims(xhat) & all(size(X)==size(xhat))
            e = X-xhat;
        else
            e = X-xhat(inc{:,1});
        end
    end
else
    if iscell(X)
        X = cell2array(X);
    end
    if ndims(X)==ndims(xhat) & all(size(X)==size(xhat));
        e = X-xhat;
    else
        inc=model.detail.includ;
        inc{1} = [1:size(X,1)]';
        X = X(inc{:,1});
        e = X-xhat;
    end
end
if isa(e,'dataset')
    e=e.data;
end

% Do the actual plotting
if length(e(:))>100
    [n,x]=hist(e(:),40);
    histres=bar(x,n,'histc','hittest','off');
else
    [n,x]=hist(e(:));
    histres=bar(x,n,'histc','hittest','off');
end

set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
axis tight;drawnow;grid off
hline('k--'); vline('k--');
t=title(info{1},'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])
set(histres,'tag','histres')
setappdata(gca,'mode',mode);

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu6');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu6');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(6)');




%--------------------------------------------------------------
function info = npnormplot(mode);
%NPNORMPLOT Normal probability plot of residuals
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 7

m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{1} = ['Residual Normal Probability'];
info{2} = ['Normal probability plot of all residuals.']; % When spawned, press the mouse on each spot, to see the position of the element in the array.'];

% Prepare data
xhat  = datahat(model);
if isa(X,'dataset') % Then it's a SDO
    
    % inc=X.includ;
    inc=model.detail.includ;
    if isfieldcheck(model,'model.detail.options.samplemode');
        smpmd = model.detail.options.samplemode;
    else
        smpmd = 1;
    end
    for i=1:length(inc)
        if i~=smpmd
            inc{i}=1:length(inc{i});
        end
    end
    
    %  if ~strcmp(model.modeltype,'PARAFAC2')
    %    inc{smpmd} = [1:size(X.data,smpmd)]';
    %  end
    
%    incX = X.include; % RB 2016 OCT
try
    incX = model.detail.includ;
    X = X.data(incX{:});
catch
    incX = X.include;
    X = X.data(incX{:});    
end
    if strcmp(model.modeltype,'PARAFAC2')
        e = X-xhat;
    else
        if ndims(X)==ndims(xhat) & all(size(X)==size(xhat))
            e = X-xhat;
        else
            e = X-xhat(inc{:,1});
        end
    end
else
    if iscell(X)
        X = cell2array(X);
    end
    e = X-xhat;
end
if isa(e,'dataset')
    e = e.data;
end
[e,b] = sort(e(:));
I = length(e);
XX = ((1:I)-1/2)/I;
YY = sqrt(2)*erfinv(2*XX-1);
YY = YY/max(abs(YY))*max(abs(e)); %normalize to match range of e
% YY = YY-e';

% Do the actual plotting. This is very memory demanding in R2014b onwards
% if there are many points (~1GB RAM per million points). Hence use random
% sub-sampling if number of points exceeds a large threshold.
thresholdcount = 1e4;
npts    = length(e);
index   = 1:npts;
shufind = shuffle(index');
nsub    = min(thresholdcount, npts);
j = plot(e(shufind(1:nsub)),YY(shufind(1:nsub)),'bo','LineWidth',2,'hittest','on');


axis tight,grid off
% hline('k--');
dp('k--');
t=title(info{1},'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'],'color','blue');
set(gca,'tag','npnormplot')
setappdata(gca,'mode',mode);
%    xlabel('Data')
%    ylabel('Quantile')
% set(gca,'userdata',{b,size(xhat)});
% set(gca,'windowbuttondownfcn','labelit(gselect(''nearest''),1)');

% SPAWN FIGURE
% cmenu = findobj(get(gca,'parent'),'tag','contextmenu7');
% if isempty(cmenu) | ~ishandle(cmenu)
%   cmenu = uicontextmenu;
%   set(cmenu,'tag','contextmenu7');
% else
%   delete(allchild(cmenu));
% end
%set(gca,'uicontextmenu',cmenu);
%cb1 = ['disp(''NORMPLOT NOT YET IMPLEMENTED IN PLOTGUI'');'];
%item1 = uimenu(cmenu,'Label','This plot in separate window','callback',cb1);

drawnow

%--------------------------------------------------------------
function info = npresdata(mode);
%NPRESDATA Plot of residual data
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 8


myax = findobj(gcf,'tag','resdata');
if isempty(myax)
    %Must be first time through so use gca.
    myax = gca;
    set(myax,'tag','resdata')
end
axes(myax)

% Load data
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{2} = 'Plots the raw residuals, sample per sample. Press the red label for increasing the sample number.';

% Prepare data if not immediately appropriate
if isa(X,'dataset') % Then it's a SDO
    if isfieldcheck(model,'model.detail.options.samplemode')
        smpmd = model.detail.options.samplemode;
    else
        smpmd = 1;
    end
    %inc=X.includ;
    inc = model.detail.include;
    %   if ~strcmp(model.modeltype,'PARAFAC2')
    %       inc{smpmd} = [1:size(X.data,smpmd)]';
    %   end
    %X = X.data(inc{:});
    %X = cell2array(X);
    xhat = datahat(model);
    if strcmp(model.modeltype,'PARAFAC2')
        x = X-xhat;
    else
        
        if size(inc,2) == 1 & inc{2,1}(end)<= size(xhat,2) & all(size(X)<= size(xhat))
            try
                x = X-xhat(inc{:});
            catch
                try
                    inc3 = inc;
                    for i=2:length(inc)
                        inc3{i}=1:size(xhat,i);
                    end
                    x=X-xhat(inc3{:});
                catch
                    x = X-xhat;
                end
            end
        else
            if ndims(X)==ndims(xhat) & all(size(X)==size(xhat));
                x = X-xhat;
            else
                for i=1:ndims(X)
                    if size(xhat,i) == size(X,i)
                        use{i}= [1:size(X,i)];
                    else
                        use{i}=inc{i,1};
                    end
                end
                use=use';
                %x = X-xhat(inc{:});
                try 
                    x = X(use{:})-xhat;
                catch
                    x=X-xhat(use{:});
                end
            end
        end
    end
elseif iscell(X)
    X = cell2array(X);
    x = X-datahat(model);
else
    x = X-datahat(model);
end
if isfieldcheck(model,'model.detail.options.samplemode');
    samplemodex = model.detail.options.samplemode;
else
    samplemodex = 1;
end
dim23 = [1:samplemodex-1 samplemodex+1:order];
x = permute(x,[samplemodex dim23]);
% Check if prior model and set the sample numb (save as hidden in labels)
f = get(myax,'userdata');
if length(f)==1
    %if f>size(model.loads{samplemodex},1)|round(f)~=f % It is only included samples
    if f>length(model.detail.include{samplemodex})|round(f)~=f
        f = 1;
    end
else
    f = 1;
end

% Do the actual plotting
if order>2&min(size(squeeze(x(f,:,:))))>1
    try
        mesh(squeeze(x(f,:,:)),'hittest','off');
    catch
        mesh(squeeze(x.data(f,:,:)),'hittest','off');
    end
    %   h2 = text('Parent',myax,'Units','normalized', ...
    %   'ButtonDownFcn', 'modelviewcb(81)',...
    %   'Color',[0 0 0],'HandleVisibility','off', ...
    %   'HorizontalAlignment','center', ...
    %   'Position',[1 1.2], ...
    %   'Units','Normalized', ...
    %   'FontSize',8, ...
    %   'handlevisibility','on', ...
    %   'String',['S',num2str(f)], ...
    %   'Color','red',...
    %   'FontWeight','Bold', ...
    %   'VerticalAlignment','top');
    %grid off
else
    try
        plot(squeeze(x(f,:,:)),'hittest','off');
    catch
        plot(squeeze(x.data(f,:,:)),'hittest','off');
    end
end
set(myax,'units','pixels');
mypos = get(myax,'position');
set(myax,'units','normalized');

h2 = findobj(gcf,'tag','resdata_button');
if isempty(h2)
    h2 = uicontrol('tag','resdata_button', ...
        'Style','pushbutton',...
        'ForegroundColor','red',...
        'Units','pixels',...
        'Callback', 'modelviewcb(81)',...
        'HorizontalAlignment','center', ...
        'Position',[mypos(1)+mypos(3)+10 mypos(2)+mypos(4)+5 40 20], ...
        'FontSize',10, ...
        'String',['S',num2str(f)], ...
        'FontWeight','Bold');
else
    set(h2,...
        'Position',[mypos(1)+mypos(3)+10 mypos(2)+mypos(4)+5 40 20], ...
        'String',['S',num2str(f)]);
end


set(myax,'Xticklabel',[]);
set(myax,'Yticklabel',[]);
set(myax,'Zticklabel',[]);
axis tight
grid off
drawnow

%set(myax,'Xticklabel',[]);set(myax,'Yticklabel',[]);set(myax,'Zticklabel',[]);
%axis tight,drawnow;
try
    set(myax,'userdata',f);
catch
    % Non-reproducible error gives a problem here sometimes. Replacing that
    % with a fix of the f variable to one
    set(myax,'userdata',1);
end
set(myax,'tag','resdata')
info{1} = 'Residuals';
title(info{1},'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'],'color','blue');


% Button for picking other samples
%['if strcmp(get(gcf,''selectiontype''),''normal''),model = get(findobj(''tag'',''Fig1''),''userdata'');f=get(findobj(''tag'',''resdata''),''userdata'');if iscell(f);f=f{1};end,set(findobj(''tag'',''resdata''),''userdata'',[f+1]);X = model{2};model = model{1};modelviewertool(8,',num2str(mode),');end']

drawnow;

% SPAWN FIGURE
cmenu = findobj(get(myax,'parent'),'tag','contextmenu8');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu8');
else
    delete(allchild(cmenu));
end
set(myax,'uicontextmenu',cmenu);
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(8)');

setappdata(myax,'mode',mode);

%--------------------------------------------------------------
function info = nprawdata(mode);
%NPRAWDATA Plot of raw data
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 9

myax = findobj(gcf,'tag','rawdata');
if isempty(myax)
    %Must be first time through so use gca.
    myax = gca;
    set(myax,'tag','rawdata')
end
axes(myax)

% Load data
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{2} = 'Plots the raw data and the model, sample per sample. Press the background of the plot to change between raw data and model and press the red label for increasing the sample number.';

% Prepare data if not immediately appropriate
if isfieldcheck(model,'model.detail.options.samplemode')
    samplemodex = model.detail.options.samplemode;
else
    samplemodex = 1;
end
if isa(X,'dataset') % Then it's a SDO
    %inc=X.includ; RB 2016 RB
    try 
        inc=model.detail.includ;
        x = X.data(inc{:});
    catch
        inc=X.includ;
        x = X.data(inc{:});
    end
elseif iscell(X)
    x = cell2array(X);
else
    x = X;
end
dim23 = [1:samplemodex-1 samplemodex+1:order];
x = permute(x,[samplemodex dim23]);
xhat  = datahat(model);
xhat = permute(xhat,[samplemodex dim23]);
try
    %xhat=xhat(inc{samplemodex},:);
    sx = size(xhat);
    inc2 = model.detail.include;
    xhat=xhat(inc2{samplemodex},:);
    xhat = reshape(xhat,[length(inc2{samplemodex}) sx(2:end)]);
end
xhat(isnan(x))=NaN;

% Check if prior model and set the sample numb (save as hidden in labels)
f = get(myax,'userdata');
if length(f)==1
    %if f>size(model.loads{samplemodex},1)||round(f)~=f
    if f>length(model.detail.include{samplemodex})||round(f)~=f
        f = 1;
    end
else
    f = 1;
end

% Check if prior model and alternate between 0/1 model/raw data (value saved as hidden in labels)
hatvalue = get(myax,'ylabel');
if strcmpi(get(hatvalue,'visible'),'off')
    hat = str2double(get(hatvalue,'string'));
else
    hat = 0; % Default is to show data
end

sampincreasermode = get(myax,'zlabel');
if strcmpi(get(sampincreasermode,'visible'),'off')
    sampmode = str2num(get(sampincreasermode,'string'));
    if length(sampmode)==1&&sampmode==1
        hat = 0;
    else
        hat = abs(hat-1);
    end
else
    hat = 0; % Default is to show data
end
m{4}=hat;
set(gcf,'userdata',m);

if ~hat && ~isempty(x);
    if order>2&&min(size(squeeze(x(f,:,:))))>1
        try
            mesh(squeeze(x(f,:,:)),'hittest','off');grid off
        catch
            mesh(squeeze(x.data(f,:,:)),'hittest','off');grid off
        end
    else
        try
            plot(squeeze(x(f,:,:)),'hittest','off');
        catch
            plot(squeeze(x.data(f,:,:)),'hittest','off');
        end
    end
    ylabel(0,'Visible','off'); %Determines if xhat or x is shown
    info{1} = 'Raw data';
else
    if order>2&&min(size(squeeze(xhat(f,:,:))))>1
        try
            mesh(squeeze(xhat(f,:,:)),'hittest','off');grid off
        catch
            mesh(squeeze(xhat.data(f,:,:)),'hittest','off');grid off
        end
    else
        try
            plot(squeeze(xhat(f,:,:)),'hittest','off');
        catch
            plot(squeeze(xhat.data(f,:,:)),'hittest','off');
        end
    end
    ylabel(1,'Visible','off'); %Determines if xhat or x is shown
    info{1} = 'Model';
end
zlabel(0,'Visible','off');
xlabel(mode,'Visible','off');
set(myax,'Xticklabel',[],'Yticklabel',[],'Zticklabel',[]);
axis tight
drawnow;
set(myax,'userdata',f);
set(myax,'tag','rawdata');%Set this again in case it's lost in plotting.
title(info{1},'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'],'color','blue');

%['if strcmp(get(gcf,''selectiontype''),''normal''),model = get(gcf,''userdata'');modelviewertool(9,model{3});end']
if ~isempty(x);
    set(myax,'ButtonDownFcn','modelviewcb(91)');
    setappdata(myax,'mode',mode);
end

% Button for picking other samples
% h2 = text('Parent',myax,'Units','normalized', ...
%   'ButtonDownFcn', 'modelviewcb(92)',...
%   'Color',[0 0 0],'HandleVisibility','off', ...
%   'HorizontalAlignment','center', ...
%   'Position',[1 1.2], ...
%   'Units','Normalized', ...
%   'FontSize',8, ...
%   'handlevisibility','on', ...
%   'String',['S',num2str(f)], ...
%   'Color','red',...
%   'FontWeight','Bold', ...
%   'VerticalAlignment','top');

set(myax,'units','pixels');
mypos = get(myax,'position');
set(myax,'units','normalized');

h2 = findobj(gcf,'tag','rawdata_button');
if isempty(h2)
    h2 = uicontrol('tag','rawdata_button', ...
        'Style','pushbutton',...
        'ForegroundColor','red',...
        'Units','pixels',...
        'Callback', 'modelviewcb(92)',...
        'HorizontalAlignment','center', ...
        'Position',[mypos(1)+mypos(3)+10 mypos(2)+mypos(4)+5 40 20], ...
        'FontSize',10, ...
        'String',['S',num2str(f)], ...
        'FontWeight','Bold');
else
    set(h2,...
        'Position',[mypos(1)+mypos(3)+10 mypos(2)+mypos(4)+5 40 20], ...
        'String',['S',num2str(f)]);
end

% SPAWN FIGURE
if ~isempty(x)
    cmenu = findobj(get(myax,'parent'),'tag','contextmenu9');
    if isempty(cmenu) || ~ishandle(cmenu)
        cmenu = uicontextmenu;
        set(cmenu,'tag','contextmenu9');
    else
        delete(allchild(cmenu));
    end
    set(myax,'uicontextmenu',cmenu);
    item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(9)');
end




%--------------------------------------------------------------
function info = npuniqvar(mode);

%NPUNIQVAR plot variance of each component

%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 10

m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{1} = ['Variation per component'];
info{2} = 'Shows the variation (sum-squares) of each component in the model. Also shows the unique variation of each component which is the part not covered by other components.';


% Do the actual plotting
bar(model.detail.ssq.percomponent.data(:,[2 5]),'hittest','off');
set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
drawnow;grid off
t=title(info{1},'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');']);

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu10');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu10');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(10)');

setappdata(gca,'mode',mode);

axis tight
drawnow;



%--------------------------------------------------------------
function info = npcoreplot(mode);
%NPCOREPLOT Core plot
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 11

m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads)-1;
info{1} = 'Core plot';
info{2} = 'The core plot shows the core elements in the Tucker model such that the size is indicative for the variance described by the corresponding set of components';

if max(size(model.loads{end}))>1
    coreanal(model.loads{end},'plot',.24);
    set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
    axis tight,drawnow;grid off
    hline('k--');
    t=title(info{1},'color','blue');
    set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])
    
    setappdata(gca,'mode',mode);
    
    % SPAWN FIGURE
    cmenu = findobj(get(gca,'parent'),'tag','contextmenu11');
    if isempty(cmenu) | ~ishandle(cmenu)
        cmenu = uicontextmenu;
        set(cmenu,'tag','contextmenu11');
    else
        delete(allchild(cmenu));
    end
    set(gca,'uicontextmenu',cmenu);
    item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(1111)');
    item2 = uimenu(cmenu,'Label','This plot in separate window as a list','callback','modelviewcb(1112)');
end

%--------------------------------------------------------------
function info = nptuplot(mode);

%NPTUPLOT plots T vs. U for PLS models

%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 12
% Load data
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = 1;
info{1} = ['T vs U plot'];
info{2} = ['Scatter plots of pairs of scores from X (T) and Y (U) mode. Press the axes (white background) to change components. Right-click in plot to spawn.'];

% Prepare data if not immediately appropriate
T=model.loads{1,1};
U=model.loads{1,2};

% Check if prior model and use increase the factor numb (save as hidden in labels)
f = get(gca,'userdata');
if length(f)==1
    f1 = f(1);
    if f1>size(model.loads{2,1},2)|round(f1)~=f1
        f1 = 1;
    end
else
    f1 = 1;
end

% Do the actual plotting
plot(T(:,f1),U(:,f1),'o','hittest','off');
set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
axis tight,drawnow;grid off
t=title([info{1},' F',num2str(f1)],'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])
set(gca,'userdata',f1);
setappdata(gca,'mode',mode);


axis tight
drawnow;


% Add function for new small plot of next mode
%['if strcmp(get(gcf,''selectiontype''),''normal''),info=modelviewertool(5,',num2str(nextmode),');end']
set(gca,'ButtonDownFcn','modelviewcb(121)');

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu12');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu12');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(12)');
setappdata(gca,'mode',mode);

%--------------------------------------------------------------
function info = nppredplot(mode);

%NPPREDPLOT Pred vs Meas plot (only NPLS)

%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

%NUMBER 13
% Load data
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = 1;
info{1} = ['Predicted vs. measured'];
info{2} = ['Predicted Y versus reference Y. Right-click in plot to spawn.'];

% Do the actual plotting

plot(model.detail.data{2}.data,model.pred{2},'o','hittest','off');
set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
axis tight,drawnow;grid off
hline('k--'); vline('k--');
t=title([info{1}],'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])

setappdata(gca,'mode',mode);

axis tight
drawnow;

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu13');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu13');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(13)');


%--------------------------------------------------------------
function info = nppf2load(mode);
%NPLOAD loading plot for first mode of PARAFAC2
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

% NUMBER 14

% Load data
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{1} = ['All loadings M1'];
info{2} = 'Line plot of loadings in mode 1 for all slabs (in PARAFAC2 there is a set of first mode loadings for each last mode slab (sample). Press the axes (white background) to see loadings in another mode.';

loading=model.loads{1};

col=colormap('lines');
if size(loading.H,2)>64 % If more than 64 colors, col is not big enough
   col = rand(loading.H,2,3);
end
for i=1:length(loading.P)
    lo = loading.P{i}*loading.H;
    % Do the actual plotting
    for f=1:size(lo,2)
        plot(lo(:,f),'LineWidth',2,'color',col(f,:),'hittest','off');
        hold on
    end
    hold on
end
hold off
set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
axis tight,drawnow;grid off
t=title(info{1},'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])

setappdata(gca,'mode',mode);

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu14');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu14');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(141)');


%--------------------------------------------------------------
function info = nppf2load2(mode);
%NPLOAD loading plot for first mode of PARAFAC2
%Copyright Eigenvector Research, Inc. 1991-2001
%rb 2001

% NUMBER 15

% Load data
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{1} = ['Scaled loadings M1'];
info{2} = 'Scaled line plot of loadings in mode 1 for all slabs (in PARAFAC2 there is a set of first mode loadings for each last mode slab (sample). This plot provides the loadings scaled by the last mode loadings which 1) helps overcome the intrinsic sign indeterminacy in PARAFAC2 and 2) helps visually in that zero-present components are not blown up to look like noise';

loading=model.loads{1};
lastloads = model.loads{end};

col=colormap('lines');
if size(loading.H,2)>64 % If more than 64 colors, col is not big enough
   col = rand(loading.H,2,3);
end
for i=1:length(loading.P)
    lo = loading.P{i}*loading.H;
    % Scale each column by the last mode loading
    for j = 1:size(lastloads,2)
        lo(:,j)=lo(:,j)*lastloads(i,j);
    end
    % Do the actual plotting
    for f=1:size(lo,2)
        plot(lo(:,f),'LineWidth',2,'color',col(f,:),'hittest','off');
        hold on
    end
end
hold off
set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
axis tight,drawnow;grid off
t=title(info{1},'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])

setappdata(gca,'mode',mode);

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu15');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu15');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(151)');

%--------------------------------------------------------------
function info = nppfqual(mode);
%NPPFqual Plot PARAFAC model quality
%Copyright Eigenvector Research, Inc. 1991-2015
%rb 2015

%NUMBER 16
myax = findobj(gcf,'tag','splith');
if isempty(myax)
    %Must be first time through so use gca.
    myax = gca;
    set(myax,'tag','splith')
end
axes(myax)

m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
data = [];
try
    qu = round(model.detail.validation.splithalf.quality*100);
    whc_one=model.detail.validation.splithalf.bestsplit;
    submodels = model.detail.validation.splitmodels.split{whc_one}.set;
catch
    qu=0;
    whc_one=1;
    submodels={model};
end
% Plot first non-sample mode
smpmode = submodels{1}.detail.options.samplemode;
modes = [1:length(submodels{1}.loads)];
modes(smpmode)=[];

% CHK if PARAFAC2 and then remove first mode

if mode==smpmode;
    mode=mode+1;
    if mode>length(submodels{1}.loads)
        mode=1;
    end
end
info{1} = ['Splithalf M',num2str(mode),': ',num2str(qu),'%'];
info{2} = 'The "Splithalf quality" plot the similarity of the loadings in a particular mode when the data is split into two. Click in the figure (white part) to advance to possible other modes. The number in the title indicates the similarity of the two splits. If close to 100%, the splithalf is perfect and confirms that the number of components is adequate. Or that the two sets are so identical (e.g. replicates) that similarity is not indicative of a valid model';
plot(submodels{1}.loads{mode},'r','linewidth',2,'hittest','off'),hold on
if (length(submodels)>1)
    plot(submodels{2}.loads{mode},'b','linewidth',1.3,'hittest','off'),hold off
else
    hold off;
end
axis tight
set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
drawnow;grid off

% Add function for new small plot of next mode
set(myax,'ButtonDownFcn','modelviewcb(161)');
setappdata(myax,'mode',mode);

t=title([info{1}],'color','blue');
set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])
set(gca,'userdata',data)
setappdata(gca,'mode',mode);

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu4');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu4');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
%cb1 = ['data=get(gca,''userdata'');data = dataset(data);data.label{2}={''Target'';''Ideally non-zero core elements'';''Ideally zero core elements''};figure;plotgui(data,''axismenuvalues'',{[-1] [-1 -2 -3] [-1]},''plotcommand'',[''delete(findobj(get(gca,''''children''''),''''tag'''',''''''''));set(findobj(get(gca,''''children''''),''''tag'''',''''selection''''),''''linestyle'''',''''none'''',''''markersize'''',10,''''marker'''',''''o'''',''''linewidth'''',2,''''color'''',[1 0 1]);dattags = findobj(get(gca,''''children''''),''''tag'''',''''data'''');set(dattags(3),''''marker'''',''''none'''',''''linestyle'''',''''--'''',''''color'''',[0 0 1]);set(dattags(2),''''marker'''',''''o'''',''''linestyle'''',''''none'''',''''markersize'''',6,''''linewidth'''',3,''''color'''',[1 0 0]);set(dattags(1),''''marker'''',''''x'''',''''linestyle'''',''''none'''',''''markersize'''',6,''''linewidth'''',4,''''color'''',[0 1 0]);set(gca,''''yticklabel'''',[],''''xticklabel'''',[]);''])'];
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(16)');


function info = nppf2qual(mode);
%NPPF2qual Plot PARAFAC2 model quality
%Copyright Eigenvector Research, Inc. 1991-2015
%rb 2016

%NUMBER 17

m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};

try
    qual = model.detail.validation.autochrome.probability_of_overfit;
    qual = qual*100;
catch
    qual = 0;
end
info{1} = ['AUTOChrome quality'];
info{2} = 'The "PARAFAC2 model quality" plot shows the probability that the model is using to many components based on some GCMS quality parameters designed by Johnsen et al., J. Chemom. 2013. If close to 100, the model has too many components';
data = [];

h = bar(qual,'hittest','off');
if qual<80
    h.FaceColor=[.2 .8 .2];
elseif qual<90
    h.FaceColor=[.9 .9 .2];
else
    h.FaceColor=[.8 .2 .2];
end

hold off
axis([.5 1.5 0 100])
set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
drawnow;grid off
t=title([info{1}],'color','blue');

set(t,'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'])
set(gca,'userdata',data)
setappdata(gca,'mode',mode);

% SPAWN FIGURE
cmenu = findobj(get(gca,'parent'),'tag','contextmenu4');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu4');
else
    delete(allchild(cmenu));
end
set(gca,'uicontextmenu',cmenu);
%cb1 = ['data=get(gca,''userdata'');data = dataset(data);data.label{2}={''Target'';''Ideally non-zero core elements'';''Ideally zero core elements''};figure;plotgui(data,''axismenuvalues'',{[-1] [-1 -2 -3] [-1]},''plotcommand'',[''delete(findobj(get(gca,''''children''''),''''tag'''',''''''''));set(findobj(get(gca,''''children''''),''''tag'''',''''selection''''),''''linestyle'''',''''none'''',''''markersize'''',10,''''marker'''',''''o'''',''''linewidth'''',2,''''color'''',[1 0 1]);dattags = findobj(get(gca,''''children''''),''''tag'''',''''data'''');set(dattags(3),''''marker'''',''''none'''',''''linestyle'''',''''--'''',''''color'''',[0 0 1]);set(dattags(2),''''marker'''',''''o'''',''''linestyle'''',''''none'''',''''markersize'''',6,''''linewidth'''',3,''''color'''',[1 0 0]);set(dattags(1),''''marker'''',''''x'''',''''linestyle'''',''''none'''',''''markersize'''',6,''''linewidth'''',4,''''color'''',[0 1 0]);set(gca,''''yticklabel'''',[],''''xticklabel'''',[]);''])'];
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(16)');



function info = nppf2res(mode);
%NPPF2RES Plot of residual data

%NUMBER 18


myax = findobj(gcf,'tag','nppf2res');
if isempty(myax)
    %Must be first time through so use gca.
    myax = gca;
    set(myax,'tag','nppf2res')
end
%axes(myax)

% Load data
m     = get(gcf,'userdata');
m{3}  = mode;
set(gcf,'userdata',m);
X     = m{2};
model = m{1};
order = length(model.loads);
info{2} = 'Plots the residuals averaged over middle modes. The y-scale goes to the size of the max raw signal to allow assess the absolute size of the residuals';
% Prepare data if not immediately appropriate
if isa(X,'dataset') % Then it's a SDO
    if isfieldcheck(model,'model.detail.options.samplemode')
        smpmd = model.detail.options.samplemode;
    else
        smpmd = 1;
    end
    inc=X.includ;
    if ~strcmp(model.modeltype,'PARAFAC2')
        inc{smpmd} = [1:size(X.data,smpmd)]';
    end
    X = X.data(inc{:});
    %X = cell2array(X);
    xhat = datahat(model);
    if strcmpi(model.modeltype,'parafac2')
        x = X-xhat;
    elseif strcmpi(model.modeltype,'parafac')
        try
            x = X-xhat;
        catch
            xhat = xhat(inc{:});
            x = X-xhat;
        end
    else
        if ndims(X)==ndims(xhat) & all(size(X)==size(xhat));
            x = X-xhat;
        else
            x = X-xhat(inc{:});
        end
    end
elseif iscell(X)
    X = cell2array(X);
    x = X-datahat(model);
else
    x = X-datahat(model);
end
% Do the actual plotting (scale according to raw data)
Datamax_value = max(X(:));
minval = -.2*max(X(:));

if strcmpi(model.modeltype,'parafac2')
    if order>2&min(size(squeeze(x(1,:,:))))>1
        for or = order-1:-1:2 % All middle modes have to be averaged out
            x = squeeze(mean(x,or));
        end
    else
        x = x(:,:);
    end
    plot(x,'hittest','off');
    axis([1 size(x,1) minval Datamax_value])
else % Assume first mode is samples
    if order>2&min(size(squeeze(x(1,:,:))))>1
        for or = order-1:-1:2 % All middle modes have to be averaged out
            x = squeeze(mean(x,or));
        end
        x = x';
    else
        x=x(:,:)';
    end
    plot(x,'hittest','off')
    try
        axis([1 size(x,1) minval Datamax_value])
    end
end

set(myax,'units','pixels');
mypos = get(myax,'position');
set(myax,'units','normalized');
set(myax,'Xticklabel',[]);
set(myax,'Yticklabel',[]);
%set(myax,'Zticklabel',[]);
%axis tight
grid off
drawnow

%set(myax,'Xticklabel',[]);set(myax,'Yticklabel',[]);set(myax,'Zticklabel',[]);
%axis tight,drawnow;
set(myax,'tag','nppf2res')
info{1} = 'Average residuals';
title(info{1},'ButtonDownFcn',['evrimsgbox(''',info{2},''',''replace'');'],'color','blue');

drawnow;

% SPAWN FIGURE
cmenu = findobj(get(myax,'parent'),'tag','contextmenu18');
if isempty(cmenu) | ~ishandle(cmenu)
    cmenu = uicontextmenu;
    set(cmenu,'tag','contextmenu18');
else
    delete(allchild(cmenu));
end
set(myax,'uicontextmenu',cmenu);
item1 = uimenu(cmenu,'Label','This plot in separate window','callback','modelviewcb(822)');
setappdata(myax,'mode',mode);
