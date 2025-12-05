function modelviewcb(number)
%MODELVIEWCB Internal utility function for modelviewer.

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% The numbers are arranged such that all starting with e.g. 2
% refer to plot number 2 in modelviewer

% rb, June 2004, fixed bug in PF2 scatter plot spawn
% jms 11/10/04 -jms added variable labels to spawned loadings plots
% rb, Jan 2006, Modified the spawned loading plot in PARAFAC2 (changed the
% colors)

switch number
    case 1
        m = get(gcbf,'userdata');
        currentmode = getappdata(gca,'mode');
        if ~isempty(currentmode);
            m{3} = currentmode;
        end
        figure,
        L = dataset([m{1}.loads{m{3}}]);
        if ~isa(m{2},'dataset');
            m{2}=dataset(m{2});
        end,
        if isfield(m{1}.detail.options,'samplemodex')
            samplemodex = m{1}.detail.options.samplemodex;
        elseif isfield(m{1}.detail.options,'samplemode')
            samplemodex = m{1}.detail.options.samplemode;
        else
            samplemodex = 1;
        end
        
        L = dataset([m{1}.loads{m{3}}]);
        if isempty(m{2}) | (isa(m{2},'dataset') & isempty(m{2}.data))  %no data? get info from model
            L = copydsfields(m{1},L,{m{3} 1});
        else
            if m{3}~=samplemodex
                exclud = delsamps([1:size(m{2}.data,m{3})]',m{1}.detail.includ{m{3}}');
                try
                    L = copydsfields(delsamps(m{2},exclud,m{3},2),L,{m{3} 1});
                catch
                    L = copydsfields(m{2},L,{m{3} 1});
                end
                if isempty(L.axisscale{1});
                    L.axisscale{1} = 1:size(L.data,1);
                end
                if isempty(L.axisscalename{1});
                    L.axisscalename{1} = 'Variable';
                end
            else
                try
                    L = copydsfields(m{2},L,{m{3} 1});
                catch
                    try
                    id=m{1}.detail.includ{m{3}};
                    L = copydsfields(m{2},L(id,:),{m{3} 1});
                    end
                end
            end
        end
        
        L.axisscale{2}=[1:size(m{1}.loads{m{3}},2)]';
        L.axisscalename{2} = 'Component number';
        plotgui(L,'linestyle','-','axismenuvalues',{0 1:size(L.data,2)});
        
    case 11
        if strcmp(get(gcbf,'selectiontype'),'normal'),
            modelviewertool(1,nextmode);
        end
        
    case 2
        m = get(gcbf,'userdata');
        currentmode = getappdata(gca,'mode');
        if ~isempty(currentmode);
            m{3} = currentmode;
        end
        figure,
        L = dataset([m{1}.ssqresiduals{m{3}}]);
        if isempty(m{2}) | (isa(m{2},'dataset') & isempty(m{2}.data))  %no data? get info from model
            L = copydsfields(m{1},L,{m{3} 1});
        else
            if ~isa(m{2},'dataset');
                m{2}=dataset(m{2});
            end,
            try
                exclud = delsamps([1:size(m{2}.data,m{3})]',m{1}.detail.includ{m{3}}');
                L = copydsfields(delsamps(m{2},exclud,m{3},2),L,{m{3} 1});
            catch
                try
                    L = copydsfields(m{2},L,{m{3} 1});
                end
            end
        end
        L.labelname{2} = m{1}.detail.labelname{m{3}};
        L.title{2} = 'Sum squared residuals';
        %     plotgui(L,'plottype','bar','plotcommand','axis tight','axismenuvalues',{0 1:size(m{1}.loads{m{3}},2)});
        model = m{1};
        mode  = m{3};
        ssq = model.ssqresiduals{mode};
        if model.detail.options.samplemode==mode % exclude soft-deleted samples
            inc = model.detail.includ{mode};
            try
                ssq=ssq(inc);
            end
        end
        bar(ssq)
        if length(model.detail.reslim.lim95)>=mode
            hline(model.detail.reslim.lim95(mode),'-g')
        end
        if length(model.detail.reslim.lim99)>=mode
            hline(model.detail.reslim.lim99(mode),'-r')
        end
        h = axis;h(2) = length(model.ssqresiduals{mode})+.5;axis(h); % Fix. Don't know why, but the scale is wrong if not set specifically
        
    case  21
        if strcmp(get(gcbf,'selectiontype'),'normal'),
            modelviewertool(2,nextmode);
        end
        
    case 3
        m = get(gcbf,'userdata');
        currentmode = getappdata(gca,'mode');
        if ~isempty(currentmode);
            m{3} = currentmode;
        end
        data=get(findobj(gcbf,'tag','influence'),'userdata');
        L = dataset(data);
        if isfield(m{1}.detail.options,'samplemodex')
            samplemodex = m{1}.detail.options.samplemodex;
        elseif isfield(m{1}.detail.options,'samplemode')
            samplemodex = m{1}.detail.options.samplemode;
        else
            samplemodex = 1;
        end
        if isempty(m{2}) | (isa(m{2},'dataset') & isempty(m{2}.data))  %no data? get info from model
            L = copydsfields(m{1},L,{m{3} 1});
        else
            if m{3}~=samplemodex& isa(m{2},'dataset')
                exclud = delsamps([1:size(m{2}.data,m{3})]',m{1}.detail.includ{m{3}}');
                L = copydsfields(delsamps(m{2},exclud,m{3},2),L,{m{3} 1});
            else
                try
                    L = copydsfields(m{2},L,{m{3} 1});
                catch
                    if ~(isa(L,'dataset'))
                        L = dataset(L);
                    end
                end
            end
        end
        L.labelname{2} = m{1}.detail.labelname{m{3}};
        L.label{2}={'Hotelling T2','sum-squared residuals'};
        L.title{2} = 'Diagnostics';
        figure,
        plotgui(L,'axismenuvalues',{1,2});
        
    case  31
        if strcmp(get(gcbf,'selectiontype'),'normal')
            modelviewertool(3,nextmode);
        end
        
    case 4
        data=get(gca,'userdata');
        data = dataset(data);
        data.label{2}={'Target';'Ideally non-zero core elements';'Ideally zero core elements'};
        figure;
        %plotgui(data,'axismenuvalues',{[-1] [-1 -2 -3] [-1]},'plotcommand','modelviewcb(100)');
        plotgui(data,'plotby',2,'validplotby',2,'axismenuvalues',{[0] [1 2 3] [0]},'AxisMenuEnable',[0 0 0],'plotcommand','modelviewcb(100)');
        
        
    case 5
        m = get(gcbf,'userdata');
        currentmode = getappdata(gca,'mode');
        if ~isempty(currentmode);
            m{3} = currentmode;
        end
        f=get(findobj(gcbf,'tag','scatter'),'userdata');
        if isfield(m{1}.detail.options,'samplemodex')
            samplemodex = m{1}.detail.options.samplemodex;
        elseif isfield(m{1}.detail.options,'samplemode')
            samplemodex = m{1}.detail.options.samplemode;
        else
            samplemodex = 1;
        end
        
        if isstruct(m{1}.loads{m{3}}) % If it's PARAFAC2
            P = m{1}.loads{m{3}}.P{1};
            H = m{1}.loads{m{3}}.H;
            L = dataset(P*H);
        else
            L = dataset([m{1}.loads{m{3}}]);
        end
        
        
        if isempty(m{2}) | (isa(m{2},'dataset') & isempty(m{2}.data))  %no data? get info from model
            L = copydsfields(m{1},L,{m{3} 1});
        else
            if m{3}~=samplemodex & isa(m{2},'dataset')
                exclud = delsamps([1:size(m{2}.data,m{3})]',m{1}.detail.includ{m{3}}');
                L = copydsfields(delsamps(m{2},exclud,m{3},2),L,{m{3} 1});
            else
                try
                    L = copydsfields(m{2},L,{m{3} 1});
                catch
                    try
                        L = L(m{1}.detail.includ{m{3}},:);
                        L = copydsfields(m{2},L,{m{3} 1});
                    catch
                    if ~(isa(L,'dataset'))
                        L = dataset(L);
                    end
                    end
                end
            end
        end
        try
            if currentmode==samplemodex
                L.include{1}= m{1}.detail.include{samplemodex};
            end
        end

        %L.axisscale{2}=[1:size(m{1}.loads{m{3}},2)]'; %crashes for PF2
        L.axisscale{2}=[1:size(L,2)]'; %crashes for PF2
        L.axisscalename{2} = 'Component number';
        if iscell(f)
            if length(f)>1
                f=f{1};
            end
        end
        if length(f)~=2
            f=[1 2];
        end
        figure,
        plotgui(L,'axismenuvalues',{f(1),f(2)},'viewaxislines',[1 1 1]);
        
    case  51
        if strcmp(get(gcbf,'selectiontype'),'normal')
            model = get(gcbf,'userdata');
            myax = findobj(gcbf,'tag','scatter');
            currentmode = getappdata(myax,'mode');
            if ~isempty(currentmode);
                model{3} = currentmode;
            end
            X     = model{2};
            mode  = model{3};
            model = model{1};
            f=get(findobj(gcbf,'tag','scatter'),'userdata');
            if iscell(f);
                if length(f{1})==2
                    f=f{1};
                elseif length(f)>1&length(f{2})==2
                    f=f{2};
                else
                    f = [1 2];
                end
            end
            
            ncomp = size(model.loads{mode},2);
            if ncomp == 1;
                f = [1 1];
            else
                f(2) = f(2)+1;
                if f(2)>ncomp;
                    f(1) = f(1)+1;
                    if f(1)>ncomp-1;
                        f(1) = 1;
                    end
                    f(2) = f(1)+1;
                end
            end
            set(myax,'userdata',f);
            modelviewertool(5,mode);
        end
        
    case  52
        if strcmp(get(gcbf,'selectiontype'),'normal')
            info=modelviewertool(5,nextmode);
        end
        
    case  161
        if strcmp(get(gcbf,'selectiontype'),'normal')
            info=modelviewertool(16,nextmode);
        end
        
    case 6
        dat=get(findobj(gcbf,'tag','histres'),'ydata');
        dut=get(findobj(gcbf,'tag','histres'),'xdata');
        figure,
        bar(dut(1,:),dat(2,:),'histc');
        
    case 7

    case 8
        f = get(gca,'userdata');
        m = get(gcbf,'userdata');
        currentmode = getappdata(gca,'mode');
        if ~isempty(currentmode);
            m{3} = currentmode;
        end
        if ~isa(m{2},'dataset');
            m{2}=dataset(m{2});
        end,
        inc = m{2}.includ;
        if isfield(m{1}.detail.options,'samplemodex')
            samplemodex = m{1}.detail.options.samplemodex;
        elseif isfield(m{1}.detail.options,'samplemode')
            samplemodex = m{1}.detail.options.samplemode;
        else
            samplemodex = 1;
        end
        inc{samplemodex}=[1:size(m{2}.data,samplemodex)]';
        try
            x = dataset(m{2}.data(inc{:})-datahat(m{1}));
        catch % Seems to work for outliers removed throughout 
            xhat = datahat(m{1});
            inc2 = m{1}.detail.include;
            xhat = xhat(inc2{:});
            % It may be that it is only the samplemode that should have its
            % include field used
            x = dataset(m{2}.data(inc{:})-xhat);
        end
        data = m{2};
        for i=1:length(size(m{2}.data))
            exclud = delsamps([1:size(data.data,i)]',data.includ{i}');
            if length(exclud)>0&i~=samplemodex
                data = delsamps(data,exclud,i,2);
            end
        end
        %x = copydsfields(data,x,{m{3} 1});
        x = copydsfields(data,x);
        figure,
        plotgui(x,'plotby',samplemodex);

    case 822
        f = get(gca,'userdata');
        m = get(gcbf,'userdata');
        currentmode = getappdata(gca,'mode');
        if ~isempty(currentmode);
            m{3} = currentmode;
        end
        if ~isa(m{2},'dataset');
            m{2}=dataset(m{2});
        end,
        inc = m{2}.includ;
        if isfield(m{1}.detail.options,'samplemodex')
            samplemodex = m{1}.detail.options.samplemodex;
        elseif isfield(m{1}.detail.options,'samplemode')
            samplemodex = m{1}.detail.options.samplemode;
        else
            samplemodex = 1;
        end
        inc{samplemodex}=[1:size(m{2}.data,samplemodex)]';
        try
            x = dataset(m{2}.data(inc{:})-datahat(m{1}));
        catch % Seems to work for outliers removed throughout 
            xhat = datahat(m{1});
            inc2 = m{1}.detail.include;
            xhat = xhat(inc2{:});
            % It may be that it is only the samplemode that should have its
            % include field used
            x = dataset(m{2}.data(inc{:})-xhat);
        end
        data = m{2};
        for i=1:length(size(m{2}.data))
            exclud = delsamps([1:size(data.data,i)]',data.includ{i}');
            if length(exclud)>0&i~=samplemodex
                data = delsamps(data,exclud,i,2);
            end
        end
        %Average over all but first and last mode
        x = squeeze(mean(x.data,2));
         for i=3:length(size(x))-1
             x = squeeze(mean(x,2));
         end
         x = dataset(x);
         whos
        x = copydsfields(data,x,{1 1});
        x = copydsfields(data,x,{length(size(data)) 2});
        figure,
        plotgui(x,'plotby',samplemodex);
        
    case  81
        if strcmp(get(gcbf,'selectiontype'),'normal')
            model = get(gcbf,'userdata');
            currentmode={};
            try
                currentmode = getappdata(findobj(gcbf,'tag','resdata'),'mode');
            end
            if ~isempty(currentmode);
                model{3} = currentmode;
            end
            f=get(findobj(gcbf,'tag','resdata'),'userdata');
            if iscell(f);
                f=f{1};
            end,
            set(findobj(gcbf,'tag','resdata'),'userdata',[f+1]);
            X = model{2};
            mode = model{3};
            model = model{1};
            modelviewertool(8,mode);
        end
        
    case 9
        f = get(gca,'userdata');
        m = get(gcbf,'userdata');
        figure,
        if isfield(m{1}.detail.options,'samplemodex')
            samplemodex = m{1}.detail.options.samplemodex;
        elseif isfield(m{1}.detail.options,'samplemode')
            samplemodex = m{1}.detail.options.samplemode;
        else
            samplemodex = 1;
        end
        if length(m)>3
            hat = m{4};
        else
            hat = 0;
        end
        % Prepare data if not immediately appropriate
        if hat==1
            if isa(m{2},'dataset') % Then it's a SDO
                inc=m{2}.includ;
                x = m{2}.data(inc{:});
            else
                x = m{2};
            end
            try
                samplemodex = m{1}.detail.options.samplemode;
            catch
                samplemodex = 1;
            end
            dim23 = [1:samplemodex-1 samplemodex+1:length(size(x))];
            x = permute(x,[samplemodex dim23]);
            xhat  = datahat(m{1});
            xhat = permute(xhat,[samplemodex dim23]);
            xhat(isnan(x))=NaN;
            plotgui(xhat,'plotby',samplemodex);
        else % Plot raw data
            plotgui(m{2},'plotby',samplemodex);
        end
        
    case  91
        if strcmp(get(gcbf,'selectiontype'),'normal')
            model = get(gcbf,'userdata');
            currentmode = getappdata(gca,'mode');
            if ~isempty(currentmode);
                model{3} = currentmode;
            end
            modelviewertool(9,model{3});
        end
        
    case  92
        zlabel(1,'Visible','off');
        if strcmp(get(gcbf,'selectiontype'),'normal')
            thisgcf=gcbf;
            model = get(thisgcf,'userdata');
            thisgca=findobj(gcbf,'tag','rawdata');
            f=get(thisgca,'userdata');
            if iscell(f);
                f=f{1};
            end,
            set(thisgca,'userdata',[f+1]);
            X = model{2};
            model = model{1};
            modelviewertool(9,',num2str(mode),');
        end
        
    case 10
        m = get(gcbf,'userdata');
        figure,
        plotgui(m{1}.detail.ssq.percomponent,'plottype','bar','axismenuvalues',{0 ,[2 5]},'plotcommand','axis tight');
        
    case 1111
        model = get(gcbf,'userdata');
        model = model{1};
        figure
        coreanal(model.loads{end},'plot');
        
        
    case 1112
        model = get(gcbf,'userdata');
        model = model{1};
        figure
        axis off
        result=coreanal(model.loads{end},'list');
        text(.1,.5,result,'interpreter','none')
        
        
    case 100
        %Utility for corcondia plot
        delete(findobj(get(gca,'children'),'tag',' '));
        set(findobj(get(gca,'children'),'tag','selection'),'linestyle','none','markersize',10,'marker','o','linewidth',2,'color',[1 0 1]);
        dattags = findobj(get(gca,'children'),'userdata','data');
        if length(dattags)==3
          set(dattags(3),'marker','none','linestyle','--','color',[0 0 1]);
          set(dattags(2),'marker','o','linestyle','none','markersize',6,'linewidth',3,'color',[1 0 0]);
          set(dattags(1),'marker','x','linestyle','none','markersize',6,'linewidth',4,'color',[0 1 0]);
        end
        set(gca,'yticklabel',[],'xticklabel',[]);
        
        
    case 12
        m = get(gcbf,'userdata');
        currentmode = getappdata(gca,'mode');
        if ~isempty(currentmode);
            m{3} = currentmode;
        end
        %f=get(findobj('tag','scatter'),'userdata');
        f=get(gca,'userdata');
        if iscell(f)
            f=f{1};
        end
        figure,
        %dataset([m{1}.loads{m{3},1} m{1}.loads{m{3},2}]);
        L = dataset([m{1}.loads{1,1} m{1}.loads{1,2}]);
        if ~isa(m{2},'dataset');
            m{2}=dataset(m{2});
        end,
        
        if isfield(m{1}.detail.options,'samplemodex')
            samplemodex = m{1}.detail.options.samplemodex;
        elseif isfield(m{1}.detail.options,'samplemode')
            samplemodex = m{1}.detail.options.samplemode;
        else
            samplemodex = 1;
        end
        
        if m{3}~=samplemodex
            exclud = delsamps([1:size(m{2}.data,1)]',m{1}.detail.includ{1,1}');
            L = copydsfields(delsamps(m{2},exclud,1,2),L,{1 1});
        else
            L = copydsfields(m{2},L,{1 1});
        end
        
        L.axisscale{2}=[[1:size(m{1}.loads{m{3}},2)]';[1:size(m{1}.loads{m{3}},2)]'];
        L.axisscalename{2} = 'Component number';
        ll=cell(1);
        for i=1:size(m{1}.loads{m{3}},2);
            ll{i}=['T score:',num2str(i)];
        end
        for i=1:size(m{1}.loads{m{3}},2);
            ll{i+size(m{1}.loads{m{3}},2)}=['Y score:',num2str(i)];
        end
        L.label{2} = ll;
        ff=f(1)+size(L.data,2)/2;
        plotgui(L,'axismenuvalues',{f(1),ff});
        
        
    case  121
        if strcmp(get(gcbf,'selectiontype'),'normal')
            model = get(gcbf,'userdata');
            currentmode = getappdata(gca,'mode');
            if ~isempty(currentmode);
                model{3} = currentmode;
            end
            %f=get(findobj(gcbf,'tag','scatter'),'userdata');
            f=get(gca,'userdata');
            if iscell(f);
                f=f{1};
            end,
            %set(findobj(gcbf,'tag','scatter'),'userdata',[f+1]);
            set(gca,'userdata',[f+1]);
            X = model{2};
            mode = model{3};
            model = model{1};
            modelviewertool(12,mode);
        end
        
        
    case 13
        m = get(gcbf,'userdata');
        %model = get(gcbf,'userdata');
        model = m{1};
        %f=get(findobj(gcbf,'tag','scatter'),'userdata');
        if ~isa(m{2},'dataset');
            m{2}=dataset(m{2});
        end,
        figure,
        L = dataset([model.detail.data{2}.data model.pred{2}]);
        exclud = delsamps([1:size(m{2}.data,1)]',m{1}.detail.includ{1,1}');
        %L = copydsfields(delsamps(m{2},exclud,1,2),L,{1 1});
        L = copydsfields(m{2},L,{1 1});
        
        if size(model.detail.data{2}.data,2)<2
            L.label{2} = {'Y-reference',['Predicted (',model.description{3},'.)']};
        else
            for i = 1:size(model.detail.data{2}.data,2)
                txt{i} = ['Y-reference ',num2str(i)];
            end
            for i = 1:size(model.detail.data{2}.data,2)
                txt{i+size(model.detail.data{2}.data,2)} = ['Predicted ',num2str(i),' (',model.description{3},'.)'];
            end
            L.label{2} = txt;
        end
        plotgui(L,'axismenuvalues',{1,size(model.detail.data{2}.data,2)+1});
        
        
    case 141
        
        % Load data
        m     = get(gcbf,'userdata');
        if ~isa(m{2},'dataset');
            m{2}=dataset(m{2});
        end,
        set(gcbf,'userdata',m);
        X     = m{2};
        model = m{1};
        
        loading = model.loads{1};
        figure
        
        col=colormap('lines');
        if size(model.loads{1}.H,2)>64 % If more than 64 colors, col is not big enough
            col = rand(model.loads{1}.H,2,3);
        end

        for i=1:length(loading.P)
            lo = loading.P{i}*loading.H;
            % Do the actual plotting
            for f=1:size(lo,2)
                plot(lo(:,f),'LineWidth',2,'color',col(f,:));
                hold on
            end
        end
        hold off
        set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
        axis tight,drawnow;grid off
        t=title('First mode loadings');
        
        
    case 151
        
        % Load data
        m     = get(gcbf,'userdata');
        if ~isa(m{2},'dataset');
            m{2}=dataset(m{2});
        end,
        set(gcbf,'userdata',m);
        X     = m{2};
        model = m{1};
        
        loading = model.loads{1};
        lastload = model.loads{end};
        figure
        col=colormap('lines');
        if size(model.loads{1}.H,2)>64 % If more than 64 colors, col is not big enough
            col = rand(model.loads{1}.H,2,3);
        end

        for i=1:length(loading.P)
            lo = loading.P{i}*loading.H;
            for j=1:size(lastload,2)
                lo(:,j)=lo(:,j)*lastload(i,j);
            end
            % Do the actual plotting
            for f=1:size(lo,2)
                plot(lo(:,f),'LineWidth',2,'color',col(f,:));
                hold on
            end
        end
        hold off
        set(gca,'Xticklabel',[]);set(gca,'Yticklabel',[]);
        axis tight,drawnow;grid off
        t=title('First mode loadings scaled by last mode loadings');
        
    case 16
        m = get(gcbf,'userdata');
        model = m{1};
        qual = model.detail.validation;
        splithalf(qual);
end
