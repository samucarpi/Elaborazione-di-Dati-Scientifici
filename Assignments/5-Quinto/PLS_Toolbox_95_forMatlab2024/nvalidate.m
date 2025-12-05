function [result,valdso,models] = nvalidate(x,ncomp,method,options)
%NVALIDATE the number PARAFAC or Tucker components
%  Used for testing the appropriate number of components in e.g.
%  a PARAFAC model. Input the data, x, and the number of components,
%  ncomp. E.g. set ncomp to [1:4] to test one- to four-component
%  models. For Tucker, e.g. choose [2 2 2;4 5 4] to check from 2 to
%  4/5 components depending on mode.
%  The third input is either 'parafac' or 'tucker'
%  An additional input allows to select additional options.
%
% Outputs are given in a struct that contains the fields
% ssq:           the sum-squared error
%     What-To-Look-For:
%        look for sudden changes as in a Scree-plot (often difficult)
%        and look for sudden increase in number of local minima (replicate
%        points for a number of components are not identical). This is
%        often a good indication that noise is being modeled.
%
% FOR PARAFAC, special plots are given:
% consistency:   The core consistency (corcondia)
%     What-To-Look-For:
%        CORCONDIA is a percentage below or equal to 100%. A value of 80-100%
%        means that the model is valid, while a value below, say 40% means that
%        the model is not valid. A value between 40 and 80% means that the model
%        is probably valid but somehow difficult to estimate, e.g., due to
%        slight misspecification or correlations. The Corcondia will mostly
%        decrease with number of components but very sharply where the correct
%        number of components are exceeded. Hence, the appropriate number of
%        components is the model with the highest number of components and a
%        valid CORCONDIA.
%
% iterations:    Number of iterations
%     What-To-Look-For:
%        A sudden increase in the number of iterations needed
%        suggests that too many components may be used (but could also
%        just be due to a difficult fitting problem). So don't pay too much
%        attention to this.
%
% splithalf:     Stability of loadings
%     What-To-Look-For:
%        A high value (close to 100%) means that when the data is split in
%        two, both sets will yield the same parameters. May give
%        meaningless results for few samples or if the underlying variables
%        are not equally distributed over samples.
%
% models:        Cell of models
%        All models are saved in a cell where element {f,r} is the r'th
%        model replicate fit with f components.
%
%I/O: result = nvalidate(x,ncomp,method,options); % validate model of x
%I/O:          nvalidate(result,x);               % Plot earlier results
%I/O:          nvalidate(x,1:3,'parafac');          % validate 1-3 comp parafac
%I/O:          nvalidate(x,[1 1 1;3 3 3],'tucker');% validate [1 1 1] to [3 3 3] comp Tucker3 models
%I/O:          nvalidate demo
%
%See also: CORCONDIA, MODELVIEWER, PARAFAC, PARAFAC2, TUCKER


%Copyright Eigenvector Research, Inc. 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; x = 'io'; end

if nargin>2
    method = lower(method);
    % Generate standard options
    if strcmp(method,'parafac')
        s2 = splithalf('options');
        s2.modeloptions = parafac('options');
        s2.plots = 'off';
        s2.waitbar = 'off';
        s2.display = 'off';    
        standardoptions = struct('name','options','display','on','plots','on','waitbar','on',...
            'numbrepeats',4,'modeloptions',parafac('options'),'splithalfoptions',s2);
    elseif strcmp(method,'tucker')
        standardoptions = struct('name','options','display','on','plots','on','waitbar','on',...
            'numbrepeats',1,'modeloptions',tucker('options'));
    elseif strcmp(method,'parafac2')
        s2 = splithalf('options');
        s2.modeloptions = parafac2('options');
        s2.plots = 'off';
        s2.waitbar = 'off';
        s2.display = 'off';    
        standardoptions = struct('name','options','display','on','plots','on','waitbar','on',...
            'numbrepeats',4,'modeloptions',parafac2('options'),'splithalfoptions',s2);
    else
        error(' Third input not correct. Must be either ''parafac'' or ''tucker''')
    end
else % Assume parafac
    s2 = splithalf('options');
    s2.modeloptions = parafac('options');
    s2.plots = 'off';
    s2.waitbar = 'off';
    s2.display = 'off';    
    standardoptions = struct('name','options','display','on','plots','on','waitbar','on',...
        'numbrepeats',4,'modeloptions',parafac('options'),'splithalfoptions',s2);
end
if ischar(x)
    options=standardoptions;
    if nargout==0;
        clear varargout;
        evriio(mfilename,x,options);
    else
        result = evriio(mfilename,x,options);
    end
    return
end

if ~isstruct(x) % Otherwise earlier results are given which should just be shown
    
    % Filter standard options for possible user-defined modifications
    try
        if ~isstruct(options.modeloptions)
            options = evriio('nvalidate','options',standardoptions);
        end
    catch
        options = evriio('nvalidate','options',standardoptions);
    end
    
    ssX   = zeros(ncomp(end),options.numbrepeats);
    Corco = zeros(ncomp(end),options.numbrepeats);
    It    = zeros(ncomp(end),options.numbrepeats);
    T3table = [];
    
    if strcmpi(options.waitbar,'on')
        if options.numbrepeats>1&strcmp(method,'parafac')
            cwait = cwaitbar([0 0],{'Component number';'Repetition'});
        else
            cwait = cwaitbar([0],{'Component number'});
        end
    end
    if strcmp(method,'parafac')
        modeloptions = evriio('parafac','options',options.modeloptions);
    else strcmp(method,'tucker')
        modeloptions = evriio('tucker','options',options.modeloptions);
    end
    modeloptions.display='off';
    modeloptions.plots='off';
    modeloptions.waitbar='off';
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% FIT PARAFAC %%%%%%%%%%%%%
    if strcmp(method,'parafac')
        FactorsOut=[];
        ssX=repmat(NaN,ncomp(end),options.numbrepeats);
        Corco=repmat(NaN,ncomp(end),options.numbrepeats);
        perc=repmat(NaN,ncomp(end),options.numbrepeats);
        It = repmat(NaN,ncomp(end),options.numbrepeats);
        for f=ncomp
            if strcmpi(options.waitbar,'on'), cwaitbar([1 f/ncomp(end)]);end
            
            if options.numbrepeats>1,
                if strcmpi(options.waitbar,'on')
                    cwaitbar([2 1/options.numbrepeats]);
                end
            end
            modeloptions.init = 1; % DTLD init
            model{f,1}=parafac(x,f,modeloptions);
            ssX(f,1)=model{f,1}.detail.ssq.residual;
            BestErr=ssX(f,1);
            Bestnumb = 1;
            Corco(f,1)=model{f,1}.detail.coreconsistency.consistency;
            It(f,1)=model{f,1}.detail.critfinal(3);
            perc(f,1)=model{f,1}.detail.ssq.perc;
            
            if options.numbrepeats>1,
                if strcmpi(options.waitbar,'on'),cwaitbar([2 1/options.numbrepeats]);end
                modeloptions.init = 4; % SVD init
                model{f,2}=parafac(x,f,modeloptions);
                ssX(f,2)=model{f,2}.detail.ssq.residual;
                Corco(f,2)=model{f,2}.detail.coreconsistency.consistency;
                It(f,2)=model{f,2}.detail.critfinal(3);
                perc(f,2)=model{f,2}.detail.ssq.perc;
                if ssX(f,2)<BestErr
                    BestErr=ssX(f,2);
                    Bestnumb = 2;
                end
            end
            
            for rep=3:options.numbrepeats
                if strcmpi(options.waitbar,'on'),cwaitbar([2 rep/options.numbrepeats]);end
                modeloptions.init = 3; % SVD init
                model{f,rep}=parafac(x,f,modeloptions);
                ssX(f,rep)=model{f,rep}.detail.ssq.residual;
                perc(f,rep)=model{f,rep}.detail.ssq.perc;
                Corco(f,rep)=model{f,rep}.detail.coreconsistency.consistency;
                It(f,rep)=model{f,rep}.detail.critfinal(3);
                if ssX(f,rep)<BestErr
                    BestErr=ssX(f,rep);
                    Bestnumb = rep;
                end
            end
            
            splitresult{f} = splithalf(x,f,options.splithalfoptions);
            splitqual(f)   = splitresult{f}.splithalf.quality;
            
        end
        if strcmpi(options.waitbar,'on'),close(cwait),end
        result.method      = 'parafac';
        result.ssq         = ssX;
        result.localmin    = (max(ssX')-min(ssX'))./mean(ssX')*100;
        result.perc        = perc;
        Corco(Corco<0)     = 0;
        result.consistency = Corco;
        result.iterations  = It;
        result.ncomp       = ncomp;
        result.options     = options;
        result.models      = model;
        result.splithalf.quality = splitqual;
        result.splithalf.details = splitresult;
        
        % Make a table with the best models and diagnostics
        valdso = repmat(nan,max(ncomp),6);
        for f=ncomp
            [a,b]=min(ssX(f,:));
            models{1,f} = model{f,b};
            valdso(f,1) = ssX(f,b);
            valdso(f,2) = model{f,b}.detail.ssq.perc;
            valdso(f,3) = model{f,b}.detail.coreconsistency.consistency;
            if valdso(f,3)<0
                valdso(f,3)=0;
            end
            valdso(f,4) = splitqual(f)*100;
            valdso(f,5) = (valdso(f,2)/100)*(valdso(f,3)/100)*(valdso(f,4)/100)*100;
        end
        valdso(:,6)=result.localmin(:);
        valdso = dataset(valdso);
        valdso.label{2}={'Residual Sum of Squares';...
            'Variance explained [%]';...
            'Core consistency';...
            'Splithalf quality';...
            'EEMizer quality';...
            'Local minima [%]'};
        valdso.axisscale{1}=1:max(ncomp);
        valdso.axisscalename{1} = 'Component number';
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%% FIT TUCKER  %%%%%%%%%%%%%
        
    elseif  strcmp(method,'tucker')
        
        if size(ncomp,2)~=ndims(x)
            error(' The number of columns in second input NCOMPS must equal the order of the array')
        end
        PossibleNumber = [min(ncomp):max(ncomp)]'*ones(1,ndims(x));
        possibleCombs = unique(nchoosek(PossibleNumber(:),ndims(x)),'rows');
        %remove useless
        f2 = [];
        for f1 = 1:size(possibleCombs,1)
            if (prod(possibleCombs(f1,:))/max(possibleCombs(f1,:)))<max(possibleCombs(f1,:)) % Check that the largest mode is larger than the product of the other
                f2 = [f2;f1];
            elseif any(possibleCombs(f1,:)>max(ncomp))  % Chk the model is desired,
                f2 = [f2;f1];
            end
        end
        possibleCombs(f2,:)=[];
        [f1,f2]=sort(sum(possibleCombs'));
        possibleCombs = [possibleCombs(f2,:) f1'];
        
        for f=1:size(possibleCombs,1)
            if strcmpi(options.waitbar,'on'), cwaitbar([1 f/size(possibleCombs,1)]);end
            tucker(x,possibleCombs(f,1:end-1),modeloptions);
            model{f,1}=tucker(x,possibleCombs(f,1:end-1),modeloptions);
            ssX(f,1)=model{f,1}.detail.ssq.residual;
            perc(f,1)=model{f,1}.detail.ssq.perc;
            It(f,1)=model{f,1}.detail.critfinal(3);
        end
        if strcmpi(options.waitbar,'on'),close(cwait),end
        result.method      = 'tucker';
        result.ssq         = ssX;
        result.perc        = perc;
        result.iterations  = It;
        result.ncomp       = possibleCombs;
        result.options     = options;
        result.models      = model;
    end
else
    % rearrange so the results input fit the notation
    result  = x;
    x       = ncomp;
    method  = result.method;
end


if strcmpi(result.options.plots,'on')|isstruct(x)
    
    if strcmp(method,'parafac')
        figure
        set(gcf,'userdata',{result.models;x});
        delta=.25/result.options.numbrepeats; % shift points a little horizontally for appearance
        set(gcf,'userdata',{result.models;x});
        subplot(3,1,1)
        for r=1:result.options.numbrepeats
            for f=result.ncomp
                gg=plot(f+(r-1)*delta,result.perc(f,r), ...
                    'MarkerEdgeColor','k','MarkerFaceColor','r', ...
                    'LineWidth',2,'Marker','o','LineStyle','none', ...
                    'MarkerSize',8);
                set(gg,'userdata',[f r]);
                callb = ...
                    ['model=get(gcf,''userdata'');f=[',num2str([f r]),'];modelviewer(model{1}{f(1),f(2)},model{2});'];
                cmenu = uicontextmenu;
                set(gg,'UIContextMenu', cmenu);
                ctxt = num2str(f);
                ctxt = ['[PARAFAC (',ctxt,')] - Press to view model'];
                uimenu(cmenu, 'Label',ctxt,'callback',callb);
                hold on
            end
        end
        axis([1-.1 result.ncomp(end)+1 0-.05*max(result.perc(:)) 1.05*max(result.perc(:)) ])
        
        set(gca,'XTick',result.ncomp(end));
        ylabel('Percentage explained','FontWeight','bold')
        title('PARAFAC TEST - Right-click circle in top plot to see models','FontWeight','bold')
        hold off
        subplot(3,1,2)
        for r=1:result.options.numbrepeats
            plot(1+(r-1)*delta:1:result.ncomp(end)+(r-1)*delta,result.consistency(:,r), ...
                'MarkerEdgeColor','k','MarkerFaceColor','r', ...
                'LineWidth',2,'Marker','o','LineStyle','none', ...
                'MarkerSize',8)
            hold on
        end
        hold off
        MinCo=min(result.consistency(:));
        try
            axis([1 result.ncomp(end)+1 max([MinCo 0]) 100 ]);
        catch
            axis([1 result.ncomp(end)+1 0 100 ]);
        end
        set(gca,'XTick',result.ncomp(end));
        ylabel('Core consistency','FontWeight','bold')
        
        subplot(3,1,3)
        for f=result.ncomp
            
            resultspl = result.splithalf.details{f}.splithalf.quality*100;
            if resultspl<10;
                resultspl=-10;
            end
            h=bar(f,resultspl,.3);
            
            spltres_f = result.splithalf.details{f};
            set(h,'userdata',spltres_f);
            %            set(h,'ButtonDownFcn',['f=get(gco,''userdata'');figure,c1 = 0;for f1=1:f.n,if f1~=f.smd,c1=c1+1;subplot(1,f.n-1,c1),plot(f.l1{f1}),hold on,plot(f.l2{f1}(:,f.idx(2,:)),''linewidth'',2),hold off,axis tight,title([''Mode '',num2str(f1)],''fontweight'',''bold''),end,end']);
            set(h,'ButtonDownFcn',['f=get(gco,''userdata'');splithalf(f);']);
            hold on
        end
        axis([1-.5 result.ncomp(end)+.5 -10 100])
        set(gca,'XTick',result.ncomp(end));
        ylabel('Splithalf quality - press bar for loads','FontWeight','bold')
        hold off
        xlabel('Number of components','FontWeight','bold')
        
        
        
    elseif  strcmp(method,'tucker')
        figure
        set(gcf,'userdata',{result.models;x});
        for f=1:size(result.ncomp,1)
            gg=plot(result.ncomp(f,end),result.perc(f), ...
                'MarkerEdgeColor',[1 .4 0],'MarkerFaceColor',[1 .4 0], ...
                'LineWidth',2,'Marker','o','LineStyle','none', ...
                'MarkerSize',6);
            set(gg,'userdata',result.ncomp(f,1:end-1));
            callb = ...
                ['model=get(gcf,''userdata'');f=',num2str(f),';modelviewer(model{1}{f},model{2});'];
            cmenu = uicontextmenu;
            set(gg,'UIContextMenu', cmenu);
            ctxt = num2str(result.ncomp(f,1:end-1));
            ctxt = ['[Tucker (',ctxt,')] - Press to view model'];
            uimenu(cmenu, 'Label',ctxt,'callback',callb);
            hold on
        end
        % Plot the good ones
        totcomps = unique(result.ncomp(:,end));
        for f=1:length(totcomps)
            tt = find(result.ncomp(:,end)==totcomps(f));
            [a,b]=max(result.perc(tt));
            gg=plot(totcomps(f),result.perc(tt(b)), ...
                'MarkerEdgeColor','k','MarkerFaceColor','g', ...
                'LineWidth',2,'Marker','o','LineStyle','none', ...
                'MarkerSize',8);
            set(gg,'userdata',result.ncomp(tt(b),1:end-1));
            callb = ...
                ['model=get(gcf,''userdata'');f=',num2str(tt(b)),';modelviewer(model{1}{f},model{2});'];
            cmenu = uicontextmenu;
            set(gg,'UIContextMenu', cmenu);
            ctxt = num2str(result.ncomp(tt(b),1:end-1));
            ctxt = ['[Tucker (',ctxt,')] - Press to view model'];
            uimenu(cmenu, 'Label',ctxt,'callback',callb);
            hold on
        end
        
        
        ylabel('Percentage explained','FontWeight','bold')
        xlabel('Total number of components','FontWeight','bold')
        title('TUCKER TEST - Right-click circle to see model','FontWeight','bold')
        hold off
        
    end
end


function fout = cwaitbar(x,name,col)
%CWAITBAR Display compound wait bar.
%   H = CWAITBAR(X,TITLE) creates and displays wait bars of
%   fractional lengths X and with one title string TITLE.
%   The handle to the compound waitbar figure is returned in H.
%   X values should be between 0 and 1.
%   Each subsequent call to cwaitbar, CWAITBAR([BAR X]),
%   extends the length of the bar BAR to the new position X.
%   The first bar is the topmost bar and is BAR = 1 which
%   corresponds to the outermost loop.
%   H = CWAITBAR(X,TITLE) where TITLE is a cellstring with same
%   number of titles as there are fractional lengths in X.
%   Suitable for showing the bars' corresponding loop indices.
%   H = CWAITBAR(X,TITLE,COLOR) where COLOR is the color of the
%   bars. COLOR is either a color code character (see PLOT) or
%   an RGB vector. The default color is red. COLOR can also be
%   a cell array with same number of elements as there are bars
%   in the cwaitbar figure.
%
%   The order of the elements in vector X and cell arrays TITLE
%   and COLOR which is consistent with the bar number BAR is:
%   The first element corresponds to the first bar at the top
%   of the figure which in turn corresponds to the outermost loop.
%
%   CWAITBAR is typically used inside nested FOR loops that
%   performs lengthy computations.
%
%      Examples:
%         cwaitbar([.3 .2 .7],'Please wait...');     %single title
%
%         h = cwaitbar([0 0 0],{'i','j','k'},{[.8 .2 .8],'b','r'});
%         for i=1:5,
%            % computations %
%            for j=1:10
%               % computations %
%               for k=1:100
%                  % computations %
%                  cwaitbar([3 k/100])
%               end
%               cwaitbar([2 j/10])
%            end
%            cwaitbar([1 i/5])
%         end
%         close(h)
%
%   See also WAITBAR.

% Based on matlab's WAITBAR. See help for WAITBAR.
% Copyright (c) 2003-11-02, B. Rasmus Anthin.
% Revision 2003-11-03 - 2003-11-06.
% GPL license.

xline = [100 0 0 100 100];
yline = [0 0 1 1 0];


switch nargin
    case 1   % waitbar(x)    update
        bar=x(1);
        x=max(0,min(100*x(2),100));
        f = findobj(allchild(0),'flat','Tag','CWaitbar');
        if ~isempty(f), f=f(1);end
        a=sort(get(f,'child'));                         %axes objects
        if isempty(f) | isempty(a),
            error('Couldn''t find waitbar handles.');
        end
        bar=length(a)+1-bar;        %first bar is the topmost bar instead
        if length(a)<bar
            error('Bar number exceeds number of available bars.')
        end
        for i=1:length(a)
            p(i)=findobj(a(i),'type','patch');
            l(i)=findobj(a(i),'type','line');
        end
        %rewind upper bars when they are full
        %   if bar==1
        %      for i=2:length(a)
        %         xpatchold=get(p(i),'xdata');
        %         xold=xpatchold(2);
        %         if xold==100
        %            set(p,'erase','normal')
        %            xpatch=[0 0 0 0];
        %            set(p(i),'xdata',xpatch,'erase','none')
        %            set(l(i),'xdata',xline)
        %         end
        %      end
        %   end
        
        a=a(bar);
        p=p(bar);
        l=l(bar);
        xpatchold=get(p,'xdata');
        xold=xpatchold(2);
        if xold>x                      %erase old patches (if bar is shorter than before)
            set(p,'erase','normal')
            %xold=0;
        end
        xold=0;
        %previously: (continue on old patch)
        xpatch=[xold x x xold];
        set(p,'xdata',xpatch,'erase','none')
        set(l,'xdata',xline)
        
    case 2   % waitbar(x,name)  initialize
        x=fliplr(max(0,min(100*x,100)));
        
        oldRootUnits = get(0,'Units');
        set(0, 'Units', 'points');
        pos = get(0,'ScreenSize');
        pointsPerPixel = 72/get(0,'ScreenPixelsPerInch');
        
        L=length(x)*.6+.4;
        width = 360 * pointsPerPixel;
        height = 75 * pointsPerPixel * L;
        pos = [pos(3)/2-width/2 pos(4)/2-height/2 width height];
        
        f = figure(...
            'Units', 'points', ...
            'Position', pos, ...
            'Resize','off', ...
            'CreateFcn','', ...
            'NumberTitle','off', ...
            'IntegerHandle','off', ...
            'MenuBar', 'none', ...
            'Tag','CWaitbar');
        colormap([]);
        
        for i=1:length(x)
            h = axes('XLim',[0 100],'YLim',[0 1]);
            if ~iscell(name)
                if i==length(x), title(name);end
            else
                if length(name)~=length(x)
                    error('There must be equally many titles as waitbars, or only one title.')
                end
                title(name{end+1-i})
            end
            set(h, ...
                'Box','on', ...
                'Position',[.05 .3/L*(2*i-1) .9 .2/L],...
                'XTickMode','manual',...
                'YTickMode','manual',...
                'XTick',[],...
                'YTick',[],...
                'XTickLabelMode','manual',...
                'XTickLabel',[],...
                'YTickLabelMode','manual',...
                'YTickLabel',[]);
            
            xpatch = [0 x(i) x(i) 0];
            ypatch = [0 0 1 1];
            
            patch(xpatch,ypatch,'r','edgec','r','erase','none')
            line(xline,yline,'color','k','erase','none');
            
        end
        set(f,'HandleVisibility','callback');
        set(0, 'Units', oldRootUnits);
        
    case 3
        if iscell(col) & length(col)~=length(x)
            error('There must be equally many colors as waitbars, or only one color.')
        end
        f=cwaitbar(x,name);
        a=get(f,'child');
        p=findobj(a,'type','patch');
        l=findobj(a,'type','line');
        if ~iscell(col)
            set(p,'facec',col,'edgec',col)
        else
            for i=1:length(col)
                set(p(i),'facec',col{i},'edgec',col{i})
            end
        end
        set(l,'xdata',xline')
end  % case
drawnow
figure(f)

if nargout==1,
    fout = f;
end


function Xn = nm(X);

Xn=X;
for i=1:size(X,2)
    Xn(:,i)=Xn(:,i)/norm(Xn(:,i));
end

Xn = Xn * diag(sign(sum(Xn.^3)));

