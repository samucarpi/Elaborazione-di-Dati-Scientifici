function [purint,purspec,fighandle]=purity(dso,ncomp,options);
%PURITY Self-modeling mixture analysis method based on purity of variables or spectra.
%The data set can be reproduced by: purint*purspec
%[purint,purspec]=purity(data,ncomp,options)
%
%INPUTS
%       data: matrix for analysis of single file OR
%       cell for analysis of one or more slabs, e.g. conventional and 2nd derivative
%       ncomp: number of components to resolve
%
%
%OPTIONAL INPUT: options structure with one or more of the following fields
%   display: ['off'|{'on'}]             display to command window
%   plot:    ['off'|{'on'}]             plotting of results
%   axistype: {2x1} [char]
%               Mode 1: [{continuous}|'discrete'|'bar']
%               Mode 2: [{continuous}|'discrete'|'bar']
%                                       defines plots. if emtpy the values
%                                       of the (future) DSO field will be
%                                       used. In case they are not defined,
%                                       above the 'continuous' defaults
%                                       will be used.
%   select:[{[]},[1 2]]                 if empty, pure rows/columns will be selected from
%                                       last slab, otherwise, the numbers identify from
%                                       which slab(s) the pure rows/columns are selected
%   offset: [3 10]                      default noise correction factor the two slabs
%   offset_row2col:  3                  scalar value row2col offset, default is offset(1)
%   mode:  ['rows',{'cols'},'row2col']  determines if pure rows, cols are selected.
%                                       row2col is row-to-column solution
%   algorithm: 'purityengine'           defines algorithm used
%   interactive: ['on',{'off'},         defines interactivity; 'on','cursor','inactivate',
%   'cursor','inactivate','reactivate'] 'reactivate' are used for higher level calls for
%                                       interactivity, 'off' is used for demos
%                                       and command mode applications.
%   resolve:    ['off'|{'on'}]
%
%OUTPUT:
%   purint = resolved contributions('concentrations');
%   purspec = resolved pure component spectra
%   model   = standard model structure, used for prediction (same pure variables on other data set)
%             and add components to the model.
%I/O: [purint,purspec] = purity(data,ncomp,options);
%I/O: [model] = purity(data,ncomp);
%I/O: [purint,purspec] = purity(data,ncomp,model);
%I/O: [model] = purity(data,model);
%
%See also: CORRSPECGUI, PURITYENGINE

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%ww
%rsk 12/20/04 Remove interactive check at beginning of plot_purity_spectra.

if nargin == 0; analysis purity; return; end
if ischar(dso);
  options=define_options;
  if nargout==0;
    evriio(mfilename,dso,options);
  else;
    purint = evriio(mfilename,dso,options);
  end;
  return
end;


%EVALUATE ARUGMENTS

flag_apply_model=0;%NEW_MODEL
switch nargin
  case 2;
    if ~ismodel(ncomp);%check for model NOT used as argument
      options=purity('options');
    else;%NEW_MODEL
      %options=[];%NEW_MODEL
      %options.fighandle=[];%NEW_MODEL
      options=purity('options');%NEW_MODEL
      %         options.mode='cols';%NEW_MODEL
      %         options.select=[];%NEW_MODEL
      %         options.offset=0;%NEW_MODEL
      %         options.offset_row2col=[];%NEW_MODEL
      %         options.plot='off'  ;%NEW_MODEL
      %         options.returnfig='off';
      data.arg.model=ncomp;
      flag_apply_model=1;%NEW_MODEL

    end;%NEW_MODEL
    %end;
end;

fighandle=[];
%Get main figure.
if ismodel(options)
  %Deal with model being passed as options with a figure.
  fighandle = options.detail.options.fighandle;
elseif isempty(options.fighandle)|~ishandle(options.fighandle)
  %Parent figure wasn't passed in so look for one. Retain old behavior.
  fighandle = findobj('tag','purity_main_fig');
  for i = 1:length(fighandle)
    if isempty(getappdata(fighandle(i),'parent'))
      %Find a figure that doesn't have a parent. Assume the first one found
      %is the correct figure. This is to retain legacy behavior and won't
      %work with mulitple calls from command line purity.
      fighandle = fighandle(i);
      continue
    else
      fighandle = [];
    end
  end
else
  fighandle = options.fighandle;
end
  %PUT DATA IN CELL(S) AND DETERMINE DIMENSIONS;

if ~isa(dso,'dataset');dso=dataset(dso);end;

%TAKE CARE OF INCLUDE

%^index1=setdiff([dso.include{1}(1):dso.include{1}(end)],dso.include{1});
%^index2=setdiff([dso.include{2}(1):dso.include{2}(end)],dso.include{2});

dim3=size(dso.data,3);
for i=1:dim3;
  data.data{i}=dso.data(:,:,i);
%^  data.data{i}(index1,:)=0;
%^  data.data{i}(:,index2)=0;  
end;
data.axisscale{1}=dso.axisscale{1};
data.axisscale{2}=dso.axisscale{2};
data.include{1}=dso.include{1};
data.include{2}=dso.include{2};
  
data.type = dso.type;
if strcmp(dso.type,'image')
  data.imagesize = dso.imagesize;
end
data.arg.ncells=length(data.data);

%FOR MODEL, TRANSFER OPTIONS AND ARGUMENTS TO PROPER VARIABLES

data.arg.flag_model=0;
if nargin==3;
  if ismodel(options);
    %data.arg.flag_model=1;
    data.model=options;
  elseif ismodel(ncomp);%NEW_MODEL
    data.arg.model=ncomp;
    flag_apply_model=1;%NEW_MODEL

  end;
else;
  if ismodel(ncomp);
    data.arg.flag_model=1;
    data.arg.model=ncomp;
    ncomp=0;
    flag_apply_model=1;%NEW_MODEL
  end;
end;

%INITIALIZE

if isfield(data,'model');%get options from model and clear options in model.
  options=data.model.detail.options;
  rmfield(data.model.detail,'options');
else;
  data.model.detail.purvarindex=[];
  data.model.detail.slab=[];
  data.model.detail.diag=[];
  data.model.detail.inactivate=[];
  data.model.detail.window_der=1;
  data.model.detail.base=[];
end;
%if ~isfield(data.model.detail,'cursor_index');%NEW_MAX
data.model.detail.cursor_index=[];
%end;

%FOR PURE ROWS AND MODE2 SELECTION THE DATA IS TRANSPOSED;

if strcmp(lower(options.mode),'rows')|strcmp(lower(options.mode),'row2col');
  %if strcmp(lower(options.mode),'rows')|...
  %       (strcmp(lower(options.mode),'row2col')&strcmp(options.interactive,'off'));
  for i=1:data.arg.ncells;
    data.data{i}=data.data{i}';
  end;
  temp=data.axisscale{1};
  data.axisscale{1}=data.axisscale{2};
  data.axisscale{2}=temp;
  temp=data.include{1};
  data.include{1}=data.include{2};
  data.include{2}=temp;
end;

[nrows,ncols]=size(data.data{1});

if isempty(data.model.detail.inactivate);
  data.model.detail.inactivate=logical(zeros(1,ncols));
end;

%GIVE PROPER VALUES TO EMPTY OPTIONS

if isempty(data.axisscale{1});data.axisscale{1}=[1:nrows];end;
if isempty(data.axisscale{2});data.axisscale{2}=[1:ncols];end;
if isempty(options.select);options.select=data.arg.ncells;end;
if isempty(options.offset_row2col);options.offset_row2col=options.offset(1);;end;

%UNTIL NOW WE USE OPTIONS, HERE WE WILL PUT OPTIONS IN STRUCTURE DATA

data.detail.options = reconopts(options,purity('options'));
%keyboard
%clear options;
%Keep options for handling vargout. All saved options will be in data
%variable.

%FLAG_REPLOT DETERMINES IF CALCULATIONS NEED TO BE MADE OR JUST A RE_PLOT,
%FOR EXAMPLE WHEN CURSOR CHANGES, DISCRETE OR BAR PLOTS.

if strcmp(options.plot,'replot');
  data.detail.options.plot='on';
  flag_replot=1;
else
  flag_replot=0;
end;

%CHECK VALIDITY OPTIONS

data=check_options(data);

%INITIALIZE

data.arg.noise_correction=[];
data.arg.ncomp=ncomp;

%STATISTICS


for i=1:data.arg.ncells;
  data.arg.mean_data{i}=mean(data.data{i});
  data.arg.length_data{i}=sqrt(mean(data.data{i}.*data.data{i}));
  [nrows(i),ncols(i)]=size(data.data{i});
end;

%CREATE ERROR MESSAGE OF NOT ALL NROWS ARE EQUAL

if ~any(nrows==nrows(1));
  error('All data slabs should have same number of rows');
end;
nrows=nrows(1);

%CHANGE INACTIVATION ARRAY

if strcmp(data.detail.options.interactive,'inactivate')|...
    strcmp(data.detail.options.interactive,'reactivate');
  if strcmp(data.detail.options.interactive(1),'i');
    n=1;
  else;
    n=0;
  end;
  f=fighandle;
  figure(f);%set to proper object
  xlim=zoom_test;%test if zoomed.
  if isempty(xlim);
    c=get(fighandle,'userdata');
    c=data.axisscale{2}(c);
    xlim=[c c];
  end;


  %THESE STATEMENTS TAKE CARE THAT RE_ACTIVATING CAN BE DONE WITHOUT
  %ZOOMING

  if strcmp(data.detail.options.interactive,'reactivate');
    h=get(gcf,'children');
    for i=1:length(h);
      if strcmp(get(h(i),'type'),'axes')
        if strcmp(data.type,'image')
          %TODO: Add zoom functionality.
          xlim=[c c];
        else
          xlim=get(h(i),'Xlim');
        end
      end;
    end;
  end;

  if ~isempty(xlim);
    inactivate2add=zeros(1,ncols(1));
    index=findindx(data.axisscale{2},xlim);
    index=sort(index);
    inactivate2add(index(1):index(2))=1;

    if ~isempty(data.model.detail.inactivate);
      data.model.detail.inactivate(logical(inactivate2add))=n;
    else
      data.model.detail.inactivate=inactivate2add;
    end;
  end;
  
  data.detail.options.interactive ='on';
  
end;

%DETERMINE PURE VARIABLES

%if strcmp(data.detail.options.resolve,'off');
%if ~isempty(options.fighandle);%NEW_MODEL
if ~flag_apply_model;
  if ~flag_replot;
    [data fighandle]=calculate_purity(data,fighandle,options);
    if ishandle(fighandle);setappdata(fighandle,'arguments',data.arg);end;
  else;
    data.arg=getappdata(fighandle,'arguments');
    if evriio('mia') & strcmp(data.type,'image') & ~strcmp(data.detail.options.mode,'cols') & exist('plot_purity_image_spectra.m', 'file')
      [data fighandle]=plot_purity_image_spectra(data,fighandle,options);
    else
      [data fighandle]=plot_purity_spectra(data,fighandle,options);
    end
    setappdata(fighandle,'arguments',data.arg);
  end;
end;%NEW_MODEL

%RESOLVE, DISPLAY, PLOT ACCORDING TO OPTIONS

data=resolve_master(data,options);

%OUTPUT ARGUMENTS

data.arg.datasource={getdatasource(dso)};

%Deal with nargout plus figure. Subtract 1 from nargout if return figure
%option is on.
if strcmp(options.returnfig,'on') & nargout > 0
  nout = nargout-1;
else
  nout = nargout;
end

%APPLY MODEL%NEW_MODEL


%data.arg.purint_applied_model=dso.data/data.arg.purspec;
if flag_apply_model;
  %^$if size(data.arg.model.loads{2},1)~=size(dso.data,2);
  if size(data.arg.model.loads{2},1)~=size(dso.data(:,dso.includ{2}),2);
    error('unequal # of variables in data and model, cannot calculate contributions');
    data.arg.purint=[];
    data.arg.purspec=data.arg.model.loads{2}';
  else;
    data.arg.sort_index=[];%to avoid problems with output_arguments
    %data.arg.model.loads{1}=dso.data/data.arg.model.loads{2}';
    %^data.arg.purint=dso.data/data.arg.model.loads{2}';
    %^data.arg.purspec=data.arg.model.loads{2}';
    data.arg.purint=dso.data(:,dso.includ{2})/data.arg.model.loads{2}';%^$
    data.arg.purspec=data.arg.model.loads{2}';%^$
    %plot(data.arg.model.loads{1});
  end;
end;


[purint,purspec]=output_arguments(data,nout,dso);
if ~isempty(data.model.detail.cursor_index)&ishandle(fighandle);
  set(fighandle,'userdata',data.model.detail.cursor_index);%ww
end;
if strcmp(options.returnfig,'on') & isempty(purspec)
  purspec = fighandle;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data=resolve_purity(data);

%INITIALIZATIONS

[nrows,ncols]=size(data.data{1});
npurvar=length(data.model.detail.purvarindex);
pure_variables=zeros(nrows,npurvar);

%GET PURE VARIABLE INTENSITIES

% for i=1:data.arg.ncells;
%     index=(data.model.detail.slab==i);
%     if any(index);
%         pure_variables(:,index)=...
%             data.data{i}(:,data.model.detail.purvarindex(index));
%     end;
% end;

pure_variables=data.model.detail.base;
%e(data.include{1},:)%^$

%CALCULATE PURSPEC AND PURINT

%^data.arg.purspec=get_purspec(data.data{1},pure_variables);
%^purspec contains all variables!
%%%%%data.arg.purspec=get_purspec(data.data{1}(data.include{1},:),...
%%%%%    pure_variables(data.include{1},:));%^$
% if cond(pure_variables)>1e+15;
%     error('singularities');
%     return;
% end;
if strcmp(lower(data.detail.options.mode),'row2col')|...
        strcmp(lower(data.detail.options.mode),'rows');%data is transposed!
  
  data.arg.purspec=get_purspec(data.data{1}(data.include{1},:),...
  pure_variables(data.include{1},:));%^$
  data.arg.purint=data.arg.purspec';
  %^data.arg.purspec=get_purspec(data.data{1}',data.arg.purint);
  data.arg.purspec=get_purspec(data.data{1}(data.include{1},data.include{2})',...
      data.arg.purint(data.include{2},:));%^$
  
  temp=data.arg.purspec;%^$
  data.arg.purspec=zeros(npurvar,nrows);%^$
  data.arg.purspec(:,data.include{1})=temp;%^$
  
  
  tsi=abs(sum(data.arg.purspec,2));
  data.arg.purspec=diag(1./tsi)*data.arg.purspec;
  data.arg.purint=data.arg.purint*diag(tsi);
else;%'regular' resolve of pure variables
  data.arg.purspec=get_purspec(data.data{1}(data.include{1},data.include{2}),...
  pure_variables(data.include{1},:));%^$
  tsi=abs(sum(data.arg.purspec,2));
  data.arg.purspec=diag(1./tsi)*data.arg.purspec;
  %^data.arg.purint=get_purint(data.data{1},data.arg.purspec);
  data.arg.purint=get_purint(data.data{1}(:,data.include{2}),...
      data.arg.purspec);%^$
  %fill excluded purspec with zeros%^$
  temp=data.arg.purspec;
  data.arg.purspec=zeros(npurvar,ncols);
  data.arg.purspec(:,data.include{2})=temp;
  clear temp;
end;

%CALCULATE CORRELATIONS BETWEEN PURE VARIABLES AND PURINT

if strcmp(lower(data.detail.options.mode),'row2col')|strcmp(lower(data.detail.options.mode),'rows');
  c=corrcoef([pure_variables,data.arg.purspec']);
else;
  c=corrcoef([pure_variables(data.include{1},:),data.arg.purint(data.include{1},:)]);
end;
data.arg.corr_purint=diag(c(npurvar+1:end,1:npurvar));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data, fighandle]=plot_purity_spectra(data,fighandle,options);

%PREPARE INCLUDE PLOT ARRAY

[x2plot,x2plot_lim,index_exclude]=x2plot_incl(data,2);%^$

%PLOT LENGTH AND PURITY SPECTRA

npurvar=length(data.model.detail.purvarindex);

%TAKE CARE OF EFFECTS OF TRANSPOSING FILE (OPTIONS.MODE=ROWS)

if isempty(fighandle);
  %   if strcmp(data.detail.options.interactive,'on');
  fighandle = figure('tag', 'purity_main_fig', 'integerhandl', 'off', 'NumberTitle','off','name','Purity Model Builder');
  %   else
  %     figure(fighandle);
  %   end;
end

%Store main figure handle in options structure in model.
data.detail.options.fighandle = fighandle;

figure(fighandle);%set to proper object

%SEE IF USER HAS MOVED CURSOR;

if isempty(data.model.detail.cursor_index);
  data.model.detail.cursor_index=data.arg.max_index;
end;

%CHANGE WHEN DATA HAS BEEN TRANSPOSED

if strcmp(lower(data.detail.options.mode),'rows')|strcmp(lower(data.detail.options.mode),'row2col');
  %Change axis type when transposed.
  temp=data.detail.options.axistype{1};
  data.detail.options.axistype{1}=data.detail.options.axistype{2};
  data.detail.options.axistype{2}=temp;
end;

%PLOT IF DESIRED

%NEW NEW
if strcmp(data.detail.options.interactive,'cursor');%synchronize zoom
  %If two axes on figure and in cursor mode then synchronize the zoom on
  %the other axis.
  h=get(gcf,'Children');
  length_h=length(h);
  xlim=zeros(length_h,2);
  index=0;
  for j=1:length_h;
    if strcmp(get(h(j),'type'),'axes');
      index=index+1;
      xlim(index,:)=get(h(j),'Xlim');
    end;
  end;
  xlim((index+1):end,:)=[];
  xlim=[max(xlim(:,1)) min(xlim(:,2))];
end;
%NEW NEW



%if strcmp(lower(data.detail.options.plot{1}),'on');
if strcmp(lower(data.detail.options.plot),'on');
  x=data.axisscale{2};
    for k=1:2;
  for i=1:data.arg.ncells;
      if k==1;
        y=data.arg.lengthspectrum{i};
        %disp(['length ',num2str(durbin_watson(y))]);
        %temp=y.*(~data.model.detail.inactivate)*-inf;
        temp=y.*(~data.model.detail.inactivate);
        %[max_y,q(i)]=max(y(logical(~data.model.detail.inactivate)));%NEW_MAX
        [max_y,q(i)]=max(temp);%NEW_MAX
        label_string='length';
      else;
        y=data.arg.purityspectrum{i};
        y(index_exclude)=-inf;%^$
        %disp(['purity ',num2str(durbin_watson(y))]);
        %max_y=max(y(logical(~data.model.detail.inactivate)));
        %[max_y,q(i)]=max(y(logical(~data.model.detail.inactivate)));%NEW_MAX
        temp=y.*(~data.model.detail.inactivate);
        [max_y,q(i)]=max(temp);%NEW_MAX
        label_string='purity';
      end;

      %%%max_new
      %data.model.detail.cursor_index(1)=q(1);%MAXNEW2005
      if (i==2)&(length(data.model.detail.cursor_index)==1);
        data.model.detail.cursor_index(2)=q(2);
      end;
      %%%MAX_NEW


      if i==data.arg.sort_index;c='r-';else;c='k-';end;%symbols for cursor
      if data.arg.ncells==1;n=2;else;n=4;end;

      subplot(n,1,(i-1)*2+k);

      %if strcmp(data.detail.options.plot{2}(1),'c');%take care of inactivate

      data.model.detail.inactivate=logical(data.model.detail.inactivate);
      y2=zeros(1,length(y));
      y2(data.model.detail.inactivate)=y(data.model.detail.inactivate);
      y2(~data.model.detail.inactivate)=NaN;

      if strcmp(data.detail.options.axistype{2},'continuous');%take care of inactivate
        %^plot(x,y,x,y2,'r');
        plot(x2plot,y,x2plot,y2,'r');%^$
        setxdir(x2plot(data.include{2}));
      elseif strcmp(data.detail.options.axistype{2},'bar');;
        %^plotms(x,y);%bar plot
        plotms(x2plot,y);%bar plot%^$
        hold on;
        %^plotms(x,y2,'r');
        plotms(x2plot,y2,'r');%^$
        hold off;

      else;
        %^plot(x,y,'*',x,y2,'r*');setxdir;%^
        plot(x2plot,y,'*',x2plot,y2,'r*');setxdir;%^$

      end;
      hold on;%length spectrum
      x_cursor=x(data.model.detail.cursor_index(i));

      y_cursor=1.1*max_y;
      hhh=plot([x_cursor x_cursor],[0 y_cursor],c,x_cursor,y_cursor,[c(1),'*']);
      if ismac
        set(hhh,'EraseMode','normal')
      else
        set(hhh,'EraseMode','xor')
      end
      ylabel(label_string);
      
      if (i==2)&(k==1);title(['cursor @ ',num2str(x_cursor)]);end;

      if ((i-1)*2+k)>2
        %Set derivate background color to light yellow. Visual cue
        %for user.
        set(gca, 'color',[1 1 .8])
      end

      if (i==1)&(k==1)&strcmp(data.detail.options.interactive,'off');
        title('click mouse/press key to continue');
      end;

      tick_out;
      if ~((k==2)&(i==data.arg.ncells))no_ticklabels;end;
      if ~isempty(data.model.detail.slab);
        if ~isempty(data.model.detail.slab==i);
          purvar_mark_index=...%indicate previously selected pure variables
            (data.model.detail.purvarindex(data.model.detail.slab==i));
          %plot(data.axisscale{2}(purvar_mark_index),...
          %data.arg.lengthspectrum{i}(purvar_mark_index),'go');
          %^plot(x(purvar_mark_index),y(purvar_mark_index),'go');
          plot(x2plot(purvar_mark_index),y(purvar_mark_index),'go');%^$

        end;
      end;
      axis('tight');v=axis;%axis([v(1) v(2) v(3) 1.01*y_cursor]);
      %^axis([v(1) v(2) 0 1.01*y_cursor]);
      axis([x2plot_lim 0 1.01*y_cursor]);%^$

      %NEW NEW NEW NEW
      if strcmp(data.detail.options.interactive,'cursor');
        %axis([xlim v(3) 1.01*y_cursor]);
        axis([xlim 0 1.01*y_cursor]);
      end;

      %NEW NEW NEW NEW

      hold off
      if (i==1)&(k==1);

        title_string=...
          (['offset: ',num2str(data.detail.options.offset(1:data.arg.ncells))]);
        if strcmp(data.detail.options.mode,'cols');
          add2string=[', ',num2str(npurvar),' pure variable(s) selected'];
        else;
          add2string=[', ',num2str(npurvar),' pure spectra selected'];
        end;
        
        add2string=[add2string,', cursor @ ',num2str(x_cursor)];
        
        title_string=[title_string,add2string];
        if any(data.model.detail.window_der~=1);%derivative spectra present
          w=data.model.detail.window_der(end);
          title_string=[title_string,', window derivative: ',num2str(w)];

        end;
        title(title_string);
        %LIST AXISTYPE

        fignumber([data.detail.options.axistype{1}(1),data.detail.options.axistype{2}(1)],[.1 .1],12);

      end;
    end;
  end;

end;

if strcmp(data.detail.options.interactive,'off');

  %NEWNEWNEW
  %if strcmp(data.detail.options.plot{1},'on');%NEW
  waitforbuttonpress;%OLD
  %else;
  %close;
  %end;%NEW
  data.model.detail.cursor_index=[];
elseif strcmp(data.detail.options.interactive,'cursor');
  data=get_cursor(data);
  data.detail.options.interactive='on';
  %if strcmp(data.detail.options.plot{1},'on');%NEW
  if strcmp(data.detail.options.plot,'on');%NEW
    data=plot_purity_spectra(data,fighandle,options);%old
  end;%NEW
end;

%REVERSE OF CHANGES TO TAKE CARE OF EFFECTS OF TRANSPOSING FILE (OPTIONS.MODE=ROWS)

if strcmp(lower(data.detail.options.mode),'rows')|strcmp(lower(data.detail.options.mode),'row2col');
  %data.detail.options.plot{2}=fliplr(data.detail.options.plot{2});
  temp=data.detail.options.axistype{1};
  data.detail.options.axistype{1}=data.detail.options.axistype{2};
  data.detail.options.axistype{2}=temp;
end;

% fset(gcf,'HandleVisibility','callback');
%data.model.detail.cursor_index=q;%NEWMAX
data.arg.max_index=q;
%disp(584);disp(data.arg.max_index);
%if length(q)==1;data.model.detail.cursor_index(2)=-1;end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%function [data, fighandle]=plot_purity_image_spectra(data,fighandle,options);

%Resides in MIA_Toolbox.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data=plot_resolved(data,options);

%INITIALIZATIONS

[x2plot1,x2plot_lim1,index_exclude1]=x2plot_incl(data,1);%^$
[x2plot2,x2plot_lim2,index_exclude2]=x2plot_incl(data,2);%^$

if strcmp(lower(data.detail.options.mode),'row2col')|...
        strcmp(lower(data.detail.options.mode),'rows');
    temp1=x2plot1;
    temp2=x2plot_lim1;
    temp3=index_exclude1;
    x2plot1=x2plot2;
    x2plot_lim1=x2plot_lim2;
    index_exclude1=index_exclude2;
    x2plot2=temp1;
    x2plot_lim2=temp2;
    index_exclude2=temp3;
end;
    
    
    
        



if strcmp(lower(data.detail.options.mode),'row2col')|strcmp(lower(data.detail.options.mode),'rows');
  x1=data.axisscale{1};
  x2=data.axisscale{2};
else;
  x1=data.axisscale{2};
  x2=data.axisscale{1};
end

%PLOT SPECTRA

%if strcmp(data.detail.options.plot{2}(1),'c');
if strcmp(data.detail.options.axistype{2},'continuous');
  c='b@';%continuous spectra
elseif strcmp(data.detail.options.axistype{2},'bar');
  c='b|';%stickplots
else;
  c='b*@';%discrete
end;


%if strcmp(lower(data.detail.options.mode),'row2col')|strcmp(lower(data.detail.options.mode),'rows');
title4(num2str(data.arg.corr_purint),'Resolved spectra');

set(options.fighandle,'Visible','off')%Make main figure invisible.

resloveh = figure;

%^plot4(x1,data.arg.purspec,c,[],options,resloveh);
plot4(x2plot2,data.arg.purspec,c,[],options,resloveh);%^$

if ishandle(resloveh)
  close(resloveh);
end

if strcmp(data.detail.options.axistype{1},'continuous');
  c='b@';%continuous spectra
elseif strcmp(data.detail.options.axistype{1},'bar');
  c='b|';%stickplots
else;
  c='b*@';%discrete
end;

title4(num2str(data.arg.corr_purint),'Resolved contributions');

resloveh2 = figure;

%Add images size data so purint is plotted as image if dso is type image
%and miatoolbox is installed.
if strcmp(data.type,'image') & evriio('mia')
  imagesize = data.imagesize;
else
  imagesize = [];
end

%^plot4(x2,data.arg.purint,c,[],options,resloveh2,imagesize);
y2plot=NaN(size(data.arg.purint));

if strcmp(data.detail.options.mode,'cols');%OK
    y2plot(data.include{1},:)=data.arg.purint(data.include{1},:);
    x2plot=x2plot1;
end;

if strcmp(data.detail.options.mode,'rows');
    y2plot(data.include{2},:)=data.arg.purint(data.include{2},:);
    x2plot=x2plot1;
end;

if strcmp(data.detail.options.mode,'row2col');
    y2plot(data.include{2},:)=data.arg.purint(data.include{2},:);
    x2plot=x2plot1;
end;

%plot4(x2plot1,data.arg.purint,c,[],options,resloveh2,imagesize);
plot4(x2plot,y2plot,c,[],options,resloveh2,imagesize);%^$

if ishandle(resloveh2)
  close(resloveh2);
end

set(options.fighandle,'Visible','on')%Make main figure invisible.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plotms (varlist,spec,c);

%function plotms (varlist,spec);

%plots a mass spectrum.
if nargin==2;c='b';end;
lengthspec=length(spec);
y0=zeros(1,lengthspec);
plot(reshape([varlist;varlist;varlist],1,3*lengthspec),...
  reshape([y0;spec;y0],1,3*lengthspec),c);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function zero (x)
%function zero (x);
%draws a line at y=0 in a plot. x is the x array of a plot;
%No argument needed

if ~nargin;a=axis;x=a(1:2);end;
hold on; plot([min(x), max(x)], [0, 0], 'k'); hold off


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function purint=get_purint(data,purspec);
%calculate purint
%purint=get_purint(data,purspec);
purint=data/purspec;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function purspec=get_purspec(data,purint);
%calculate purspec
%purspec=get_purspec(data,purint);
purspec=purint\data;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data=tresolve(data);
%function data=tresolve(data);
%calculates pure variables from contributions estimated from pure spectra according to:
%J.M. Phalp, A.W. Payne, W. Windig,
%The resolution of mixtures using data from automated probe mass spectrometry,
%Anal. Chim. Act, 318, 1995, 43-53.

%INITIALIZE

[nrows,ncols]=size(data.data{1});
npur=size(data.arg.purint,2);
purvarindex=[];
[nrows_incl,ncols_incl]=size(data.data{1}(data.include{1},data.include{2}));%^$

%STATISTICS;

%^std_data=std(data.data{1},1,2);%*sqrt(nrows-1)/sqrt(nrows);
std_data=std(data.data{1}(data.include{1},data.include{2}),1,2);%^$
std_data=std_data+(std_data==0);
%^mean_data=mean(data.data{1},2);
mean_data=mean(data.data{1}(data.include{1},data.include{2}),2);%^$

offset_weight=mean_data./(mean_data+(data.detail.options.offset_row2col/100)*max(mean_data));
%^std_data_matrix=repmat(std_data,1,ncols);
%^mean_data_matrix=repmat(mean_data,1,ncols);
std_data_matrix=repmat(std_data,1,ncols_incl);%^$
mean_data_matrix=repmat(mean_data,1,ncols_incl);%^$

%^data_standardized=(data.data{1}-mean_data_matrix)./std_data_matrix;
data_standardized=(data.data{1}(data.include{1},data.include{2})-mean_data_matrix)./std_data_matrix;%^$
%^offset_weight_matrix=repmat(offset_weight,1,ncols);%offset_weight(ones(1,nspec),:);
offset_weight_matrix=repmat(offset_weight,1,ncols_incl);%^$
data_standardized2=data_standardized.*offset_weight_matrix;

%^std_purint=std(data.arg.purint,1,1);%*sqrt(nrows-1)/sqrt(nrows);
std_purint=std(data.arg.purint(data.include{2},:),1,1);%^$
%^mean_purint=mean(data.arg.purint,1);
mean_purint=mean(data.arg.purint(data.include{2},:),1);%^$
%^std_purint_matrix=repmat(std_purint,ncols,1);
std_purint_matrix=repmat(std_purint,ncols_incl,1);%^$
%^mean_purint_matrix=repmat(mean_purint,ncols,1);
mean_purint_matrix=repmat(mean_purint,ncols_incl,1);%^$
%^purint_standardized=(data.arg.purint-mean_purint_matrix)./std_purint_matrix;%^$
purint_standardized=(data.arg.purint(data.include{2},:)...
    -mean_purint_matrix)./std_purint_matrix;%^$

%^corr_matrix=data_standardized2/sqrt(ncols)*purint_standardized/sqrt(ncols);
corr_matrix=data_standardized2/sqrt(ncols_incl)*...
    purint_standardized/sqrt(ncols_incl);%^$
max_corr_matrix=max(corr_matrix);

%TRANSFER PURE SPECTRA SELECTION INFO

data.arg.purspecindex=data.model.detail.purvarindex;

%for i=1:npur
%    index=find(corr_matrix(:,i)==max_corr_matrix(i));
%    data.model.detail.purvarindex(i)=index(1);
%end;

[dummy,index_sort]=sort(corr_matrix);
corr_row=index_sort(end,:);

index_double=find(diff(corr_row)==0);
% index=0;
% while ~isempty(index_double);
%     index=index+1;
%     corr_row=index_sort(end-index,:);
%     index_double=find(diff(corr_row)==0);
%     if(cond(data.data{1}(:,corr_row)))>10000;
%         index_double=1;
%     end;
%
% end;

done=0;
index=-1;
while ~done;
  index=index+1;
  corr_row=index_sort(max(1,end-index),:);
  index_double=find(diff(corr_row)==0);
  %    c_test=cond(data.data{1}(:,corr_row))>10000;
  c_test=cond(data.data{1}(corr_row,:))>10000;
  if isempty(index_double)&~c_test
    done=1;
  end;

end;

%convert to variable indices in whole data set;

array=data.include{1};corr_row=array(corr_row);%^


data.model.detail.purvarindex=corr_row;
%disp(cond(data.data{1}(:,data.model.detail.purvarindex)));




%k%eyboard

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function setxdir(x)
%SETXDIR sets correct Xdir
%argument x determined direction. For simple plot, no arguments needed.

if nargin;
  if x(1)<x(2);set(gca,'Xdir','Normal');else;set(gca,'Xdir','Reverse');end;
  return;
end;


h=get(gca,'Children');
for i=1:length(h);
  if strcmp(get(h(i),'Type'),'line');
    x=get(h(i),'Xdata');
    if length(x)>1;
      if x(1)<x(2);set(gca,'Xdir','Normal');else;set(gca,'Xdir','Reverse');end;
      break;
    end;

  end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tick_out(flag);
%TICK_OUT plots tickmarks outwards
%tick_out(flag)
%flag optional, default is 0;
%flag 0 gives ticks out
%flag 1 gives no ticks

if ~nargin;flag=0;end;
if flag;
  set(gca,'Ticklength',[0 0]);
else;
  set(gca,'TickDir','out');
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function no_ticklabels(flag_xy);
%NO_TICKLABELS takes away ticklabels
%flag_y is an optional argument:
%0 clears x labels
%1 clears y labels
%2 clears x and y labels
%default is 0;

if ~nargin;flag_xy=0;end;
if (flag_xy==0)|(flag_xy==2);set(gca,'xTicklabel',[]);end;
if (flag_xy==1)|(flag_xy==2);set(gca,'yTicklabel',[]);end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data=list_diagnostics(data);

npurvar=length(data.model.detail.purvarindex);

disp(' ');
disp(datestr(now));
disp(' ');
disp('options:');
disp(data.detail.options);

disp('diagnostics:');
if strcmp(lower(data.detail.options.mode),'cols');
  disp(' column(index)   slab   purity  length');
else;
  disp('    row(index)   slab   purity  length');
end;

for i=1:npurvar;
  l{i}=sprintf('%10.2f(%1.0f)\t%4.0f\t%5.1f\t%5.1f',...
    data.axisscale{2}(data.model.detail.purvarindex(i)),...
    data.model.detail.purvarindex(i),...
    data.model.detail.slab(i),...
    100*data.model.detail.diag(i+1,1)/data.model.detail.diag(2,1),...
    100*data.model.detail.diag(i+1,2)/data.model.detail.diag(2,2));
end;
disp(str2mat(l));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [purint,purspec]=output_arguments(data,n_arg,dso);

if strcmp(data.detail.options.mode,'cols')|...
        strcmp(data.detail.options.mode,'row2col');
    index1=data.include{1};
    index2=data.include{2};
else;
    index1=data.include{2};
    index2=data.include{1};
end;

[nrows,ncols,nslabs]=size(dso);
purint=[];
purspec=[];
if n_arg==2;
  purint=data.arg.purint;
  purspec=data.arg.purspec;
elseif n_arg==1;
  purint=modelstruct('purity');
  purint.datasource=data.arg.datasource;
  purint.date=date;
  purint.time=clock;
  purint.loads{1,1}=data.arg.purint;
  if isempty(data.arg.purspec);%^$
      purint.loads{2,1}=[];
  else;
      purint.loads{2,1}=data.arg.purspec(:,index2)';%^$
  end;
  
  purint=copydsfields(dso,purint);

  if ~isempty(purint.loads{1,1});
      datarec=purint.loads{1}(index1,:)*purint.loads{2}';%^$
      datadif=dso.data(index1,index2,1)-datarec;%^$
      rsqd=sqrt(sum((datadif(:)).^2)/...
          sum(sum(dso.data(index1,index2,1).^2)));
      purint.detail.rrssq=rsqd;
  end;



  %CALCULATE SSQRESIDUALS
   if ~isempty(purint.loads{1,1});
    data_rec=purint.loads{1,1}*(purint.loads{2,1})';
    if strcmp(data.detail.options.mode,'row2col')|strcmp(data.detail.options.mode,'rows');
      dif=(data.data{1}(dso.includ{2},:))'-data_rec;%^$
    else;
      dif=data.data{1}(:,dso.includ{2})-data_rec;
    end;
    purint.detail.res{1}=dif;
    dif_squared=dif.^2;
    purint.ssqresiduals{1,1}=sum(dif_squared,2);
    purint.ssqresiduals{2,1}=sum(dif_squared(dso.include{1},:),1);

    for j=1:size(purint.loads{1},2);
      sig(j) = sum(sum((purint.loads{1}(dso.include{1},j)*purint.loads{2}(:,j)').^2));
    end;
    sig = normaliz(sig,[],1);  %normalize to 100%
    uncap = sum(sum(purint.detail.res{1}.^2))./sum(sum(mncn(dso.data(dso.include{1},dso.include{2})).^2));
    if uncap>=1;  %happens with really bad fits (e.g. poor constraints or badly processed data)
      uncap = sum(sum(purint.detail.res{1}.^2))./sum(sum(dso.data(dso.include{1},dso.include{2}).^2));
    end;
    if uncap>=1;
      uncap = 0;
    end;
    purint.detail.ssq = [[1:size(purint.loads{1},2)]' sig'*100 (1-uncap)*sig'*100 cumsum((1-uncap)*sig')*100];


  else;
    purint.ssqresiduals{1,1}=[];
    purint.ssqresiduals{2,1}=[];
  end;
 
%  purint.detail.includ=dso.includ';
%  purint.detail.label=dso.label;
%  purint.detail.labelname=dso.labelname;
%  purint.detail.axisscale=dso.axisscale;
%  purint.detail.axisscalename=dso.axisscalename;
%  purint.detail.title=dso.title;
%  purint.detail.class=dso.class;
%  purint.detail.classname=dso.classname;
%  purint.detail.preprocessing{1}=[];
  purint.detail.options=data.detail.options;
  %%



  if strcmp(data.detail.options.mode,'cols');
    purint.detail.purvarindex=data.model.detail.purvarindex;
  elseif strcmp(data.detail.options.mode,'rows');
    purint.detail.purspecindex=data.model.detail.purvarindex;
  else;
    purint.detail.purvarindex=data.model.detail.purvarindex;
    try
      purint.detail.purspecindex=data.arg.purspecindex;
    catch
      purint.detail.purspecindex=[];
    end;

  end;
  purint.detail.cursor_index=data.model.detail.cursor_index;
  purint.detail.slab=data.model.detail.slab;
  purint.detail.diag=data.model.detail.diag;
  purint.detail.cursor_select=data.arg.sort_index;
  purint.detail.inactivate=data.model.detail.inactivate;
  purint.detail.inactivate=data.model.detail.inactivate;
  purint.detail.window_der=data.model.detail.window_der;
  purint.detail.base=data.model.detail.base;


end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data=check_options(data);

%just in case people gave data.detail.options.plot='on' (or 'off');
%if ~iscell(data.detail.options.plot);data.detail.options.plot=num2cell(data.detail.options.plot,2);end;
%if length(data.detail.options.plot)==1;data.detail.options.plot{2}='cc';end;

if ~ismember(data.detail.options.display,{'off','on'});
  error('Unrecognized value for OPTIONS.DISPLAY - see ''purity help''');
end;
if ~ismember(data.detail.options.plot,{'off','on','replot'});
  error('Unrecognized value for OPTIONS.PLOT - see ''purity help''');
end;
if ~ismember(data.detail.options.axistype{1},{'continuous','discrete','bar'});
  error('Unrecognized value for OPTIONS.AXISTYPE{1} - see ''purity help''');
end;
if ~ismember(data.detail.options.axistype{2},{'continuous','discrete','bar'});
  error('Unrecognized value for OPTIONS.AXISTYPE{1} - see ''purity help''');
end;

%if ~ismember(data.detail.options.plot{2},{'cc','cd','dc','dd'});
%  error('Unrecognized value for OPTIONS.PLOT{2} - see ''purity help''');
%end;
if ~ismember(data.detail.options.mode,{'rows','cols','row2col'});
  error('Unrecognized value for OPTIONS.MODE - see ''purity help''');
end;
if ~ismember(data.detail.options.resolve,{'off','on'});
  error('Unrecognized value for OPTIONS.RESOLVE - see ''purity help''');
end;
if ~isempty(data.detail.options.select);
  if ~isreal(data.detail.options.select)|any(data.detail.options.select>data.arg.ncells)|...
      any(data.detail.options.select<0);
    error('Unrecognized value for OPTIONS.SELECT - see ''purity help''');
  end;
end;
if ~isreal(data.detail.options.offset);
  error('Unrecognized value for OPTIONS.OFFSET - see ''purity help''');
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data=resolve_master(data,options);

%if data.arg.ncomp==0;

data.arg.purint=[];
data.arg.purspec=[];
if isempty(data.model.detail.purvarindex);return;end;


if strcmp(lower(data.detail.options.resolve),'on')|...
    strcmp(lower(data.detail.options.mode),'row2col');
  %(strcmp(lower(data.detail.options.interactive),'off')));
  data=resolve_purity(data);

  %PLOT IF SO DESIRED

  if strcmp(lower(data.detail.options.plot),'on');
    data=plot_resolved(data,options);
  end;

  %DISPLAY IF SO DESIRED

  if strcmp(lower(data.detail.options.display),'on');
    data=list_diagnostics(data);
  end;
end;

if strcmp(lower(data.detail.options.resolve),'on')&...
        strcmp(lower(data.detail.options.mode),'row2col');
  data=tresolve(data);

  %REVERSE TRANSPOSE TO RESOLVE BASED ON PURE VARIABLES AND OTHER THINGS

  for i=1:data.arg.ncells;
    data.data{i}=data.data{i}';
  end;
  data.model.detail.base=data.data{1}(:,data.model.detail.purvarindex);
  temp=data.axisscale{1};
  data.axisscale{1}=data.axisscale{2};
  data.axisscale{2}=temp;
  temp=data.include{1};%^$
  data.include{1}=data.include{2};%^$
  data.include{2}=temp;
  
  


  %RESOLVE BASED ON THE PURE VARIABLES CALCULATED BY TRESOLVE

  data.detail.options.mode='cols';%'trick' function
  data=resolve_purity(data);
  %data.detail.options.mode='row2col';

  %PLOT IF SO DESIRED

  %if strcmp(lower(data.detail.options.plot{1}),'on');
  if strcmp(lower(data.detail.options.plot),'on');
    data=plot_resolved(data,options);
  end;

  %DISPLAY IF SO DESIRED

  if strcmp(lower(data.detail.options.display),'on');
    disp(' ');
    disp('column(index))');
    for i=1:length(data.model.detail.purvarindex);
      l=sprintf('%10.2f(%1.0f)',...
        data.axisscale{2}(data.model.detail.purvarindex(i)),...
        data.model.detail.purvarindex(i));
      disp(l);
    end;
  end;

  data.detail.options.mode='row2col';%reset to original.

  %%%NEW%%%

  for i=1:data.arg.ncells;
    data.data{i}=data.data{i}';
  end;
  %data.model.detail.base=data.data{1}(:,data.model.detail.purspecindex);
  data.model.detail.base=data.data{1}(:,data.arg.purspecindex);
  temp=data.axisscale{1};
  data.axisscale{1}=data.axisscale{2};
  data.axisscale{2}=temp;

  %%%NEW%%%

end;

if strcmp(data.detail.options.interactive,'off');close;end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function options=define_options;

options = [];
options.display='on';
% options.plot{1}='on';
% options.plot{2}='cc';
options.plot='on';
options.axistype{1}='continuous';
options.axistype{2}='continuous';

options.select=[];
options.offset=[3 10];
options.offset_row2col=[3];
options.mode='cols';
options.algorithm='purityengine';
%disp('temp change purity2 line 857');

%options.algorithm='simplismaengine';
options.interactive='off';
options.resolve='on';
options.returnfig = 'off';
options.fighandle = '';
options.demo = 0;
options.definitions = optiondefs;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data, fighandle]=calculate_purity(data,fighandle,options);

%INITIALIZATIONS

[nrows,ncols]=size(data.data{1});
 [x2plot,x2plot_lim,index_exclude]=x2plot_incl(data,2);%^$

for k=1:(data.arg.ncomp+1);
  for i=1:data.arg.ncells;

    if (nrows>1000)|(ncols>1000);
      h=waitbar(0,'Calculating Purity Index...');
%^       [pure_index,data.arg.purityspectrum{i},data.arg.lengthspectrum{i}]=...
%^         feval(data.detail.options.algorithm,data.data{i},data.model.detail.base,...
%^         data.detail.options.offset(i),h);
        base=data.model.detail.base;
        if ~isempty(base);base=data.model.detail.base(data.include{1},:);end
        [pure_index,data.arg.purityspectrum{i},data.arg.lengthspectrum{i}]=...%^$
        feval(data.detail.options.algorithm,data.data{i}(data.include{1},:),...
        base,...
        data.detail.options.offset(i),h);
      close (h);
    else;
      %^[pure_index,data.arg.purityspectrum{i},data.arg.lengthspectrum{i}]=...
        %^feval(data.detail.options.algorithm,data.data{i},data.model.detail.base,...
        %^data.detail.options.offset(i));
        base=data.model.detail.base;
        if ~isempty(base);base=data.model.detail.base(data.include{1},:);end
        [pure_index,data.arg.purityspectrum{i},data.arg.lengthspectrum{i}]=...%^$
        feval(data.detail.options.algorithm,data.data{i}(data.include{1},:),...
        base,...
        data.detail.options.offset(i));
    end;
    %re-callculate pure_index to include inactivate
    %^max_value(i)=max(data.arg.purityspectrum{i}(~data.model.detail.inactivate));
    %^pure_index=find(data.arg.purityspectrum{i}==max_value(i));
    q=data.arg.purityspectrum{i};%^$
    q(index_exclude)=-Inf;%^$
    [max_value(i),pure_index]=max(q(~data.model.detail.inactivate));%^$
    

    pure_index=pure_index(1);

    %data.model.detail.diag=[data.model.detail.diag;...
    %        [sum(data.arg.purityspectrum{i})^2 sum(data.arg.lengthspectrum{i})^2]];

    index=size(data.model.detail.base,2)+1;
    data.model.detail.diag(index,[2*i-1 2*i])=...
        [sum(data.arg.purityspectrum{i}(data.include{2}))^2 ...
        sum(data.arg.lengthspectrum{i}(data.include{2}))^2];
        %^$
      %^[sum(data.arg.purityspectrum{i})^2 sum(data.arg.lengthspectrum{i})^2];
    %disp(data.model.detail.diag);
    data.model.detail.diag(index,[2*i-1 2*i])=...
      [durbin_watson(data.arg.purityspectrum{i}(data.include{2})) ...
      durbin_watson(data.arg.lengthspectrum{i}(data.include{2}))];


    %disp(data.model.detail.diag)
    %data.model.detail.diag

    data.arg.max_index(i)=pure_index(end);%index for pure variables
    %disp(1170);disp(data.arg.max_index);
    %data.model.detail.diag=[data.model.detail.diag;...
    %       [sum(data.arg.purityspectrum{i})^2 sum(data.arg.lengthspectrum{i})^2]];
  end;

  %DETERMINE PURE VARIABLE; MAX IN ALL PURITY SPECTRA

  array=max_value;
  array2=zeros(size(array));
  array2(data.detail.options.select)=array(data.detail.options.select);
  [dummy,sort_index]=sort(array2);
  data.arg.sort_index=sort_index(end);
  %disp(data.arg.sort_index)

  %PLOT  AND PURITY SPECTRA

  if strcmp(data.detail.options.plot,'on');%NEW
    if evriio('mia') & strcmp(data.type,'image') & ~strcmp(data.detail.options.mode,'cols') & exist('plot_purity_image_spectra.m', 'file')
      [data fighandle]=plot_purity_image_spectra(data,fighandle,options);
    else
      [data fighandle]=plot_purity_spectra(data,fighandle,options);%OLD
    end
  end;%NES

  %STORE INDICES OF PURE VARIABLES AND FROM WHICH SLAB THEY WERE SELECTED

  data.model.detail.purvarindex=...
    [data.model.detail.purvarindex data.arg.max_index(data.arg.sort_index)];
  data.model.detail.slab=[data.model.detail.slab data.arg.sort_index];

  data.model.detail.base=...
    [data.model.detail.base data.data{data.model.detail.slab(end)}(:,data.model.detail.purvarindex(end))];

end;

%DELETE LAST PURE VARIABLE

data.model.detail.purvarindex(end)=[];
data.model.detail.slab(end)=[];
data.model.detail.base(:,end)=[];




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data=get_cursor(data,useimg);

%INITIALIZATIONS
[nrows,ncols]=size(data.data);
data.model.detail.cursor_index=data.arg.max_index;

if nargin < 2
  %Using image location.
  useimg = 0;
end

%GET CURSOR INFO
[x,y,data.arg.button]=ginput(1);
%rbbox;

if useimg
  %Remap the index out of image to normal.
  x = round(x);
  y = round(y);
  xindx = round(sub2ind(data.imagesize,y,x));
  data.model.detail.cursor_index(1)=xindx;
  return
end

if isempty(data.arg.button)
  %prevents silly warnings
  data.arg.button=0;
end;

set(gcf,'Units','Normalized');
c=get(gcf,'Currentpoint');%shows in which plot (top bottom) I click
c2=get(gca,'Currentpoint');

d = abs(data.axisscale{2}-x);%find index of closest varlist element
index=find(d==min(d));%index of cursor/rbbox initial
d=abs(data.axisscale{2}-c2(1));%find index of closest varlist element
index2=find(d==min(d));%index of cursor/rbbox finish

if (index==index2);
  data.arg.cursor2_index=0;
else;
  data.arg.cursor2_index=index2;
end;

if c(2)>.5;
  data.model.detail.cursor_index(1)=index(1);
  data.arg.sort_index=1;%makes moved cursor red
else;
  data.model.detail.cursor_index(min(data.arg.ncells,2))=index(1);
  data.arg.sort_index=2;%makes moved cursor red
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function xlim=zoom_test;
h=get(gcf,'children');
xlim_array=[];
xlim_test=[-inf inf];
for i=1:length(h);
  if strcmp(get(h(i),'type'),'axes');
    xlim=get(h(i),'Xlim');
    %cursorindex_test=get(h(i),'Xdata');%%%%%
    %if length(cursorindex_test)==1;cursor_index=cursor_index_test;end;
    xlim_array=[xlim_array;xlim];
    if diff(xlim)<diff(xlim_test);
      xlim_test=xlim;
    end;
  end;
end;
xlim_array2=[xlim_array(end,:);xlim_array(1:end-1,:)];

if all(xlim_array(:)==xlim_array2(:));
  xlim=[];
else;
  xlim=xlim_test;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function index=findindx(array,r);
%function index=findindx(array,r);
%%finds the index of the array element that is closest to r;

%
lengthr=length(r);
index=zeros(1,lengthr);
for i=1:lengthr;
  dif=abs(array-r(i));index2=find(dif==min(dif));index(i)=index2(1);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function fignumber(string1,offset, fontsize);
%creates figure number with text string and offset (rel to x-axis (and y-axis))
%fignumber(string,offset, fontsize);
%default offset .2, .2
%default fontsize 16

if nargin<3;fontsize=16;end;
if nargin==1;offset=[.2 .2];end;
if length(offset)==1;offset(2)=0;end;
v=axis;

if strcmp(get(gca,'Xdir'),'normal');
  %h=text(v(1)+offset*(v(1)-v(2)),v(4),string1);
  h=text(v(1)+offset(1)*(v(1)-v(2)),v(4)+offset(2)*(v(4)-v(3)),string1);
else;
  x=v(2)-offset*(v(1)-v(2));
  %y=v(4);
  y=v(4)+offset(2)*(v(4)-v(3));
  h=text(x(1),y(1),string1);
end;

set(h,'Fontsize',fontsize);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data=make_base(data);

if isempty(data.model.detail.purvarindex);
  data.model.detail.base=[];
else;

  %    data.model.detail.base=[];
  %     for i=1:data.arg.ncells;
  %         add2base=data.data{i}...
  %             (:,data.model.detail.purvarindex(data.model.detail.slab==i));
  %         if ~isempty(add2base);
  %             data.model.detail.base=[data.model.detail.base add2base];
  %         end;
  %     end;
  %npurvar=size(data.model.detail.purvarindex);
  %data.model.detail.base=data.data{1}(:,data.model.detail.purvarindex);
  % for i=1:npurvar;
  %     if data.model.detail.window_der(i)~=1;
  %       data.model.detail.base(:,i)=-savgol(data.model.detail.base(:,i)



end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ax,h]=subtitle(text,options)
%Centers a title over a group of subplots.
%Returns a handle to the title and the handle to an axis.
% [ax,h]=subtitle(text)
%           returns handles to both the axis and the title.
% ax=subtitle(text)
%           returns a handle to the axis only.


ax=axes('Units','Normal','Position',[.075 .075 .85 .85],'Visible','off');
set(get(ax,'Title'),'Visible','on')
title(text);

%Deal with nargout plus figure. Subtract 1 from nargout if return figure
%option is on.
if strcmp(options.returnfig,'on') & nargout > 0
  nout = nargout-1;
else
  nout = nargout;
end

if (nout < 2)
  return
end
h=get(ax,'Title');


function plot4 (x,y, linetype, flagsave, options, fig, imagesize)
%
%plot4 (x,y, linetype, flagsave) makes 4 plots at a time of the separate
%rows or columns in x and y. The linetype is the same as in the plot
%function, with two one additions:
%1) linetype | results in bargraphs.
%2) the addition of the @ character in linetype results in effects to
%accomadate plots of spectra:
%       a) the original order of x is preserved in the plot (ascending
%          or descending) to so that, for example, wavenumbers can be
%          plotted in descending order.
%       b) a line is drawn at y=0;
%If a - sign is typed, the spectrum counter will be reset so that instead
% of spectrum n, n+1, n+2 and n+3, the spectra n-2, n-1, n and n+1 will
% be plotted.
%Typing q will result in quit.
%The title is by default the sequence number. If the function title4
%is used prior to plot4, the string defined by title4 will be added
%to the title; The fourth, optional, argument, with a value one
%results in printing the plots by issuing the print -dwin command.
%Also see title4

global PLOT4_STRING SUBTITLE_STRING;

%INITIALIZATIONS

titlestring=PLOT4_STRING;clear global PLOT4_STRING;
flagmultistring=0;
if size(titlestring,1)>1;flagmultistring=1;end;
flagxdir=0;

%Figure
if nargin < 6
  fig = gcf;
end

figure(fig)%make fig gcf so gcf commands work properly below.

%Image data
if nargin < 7
  imagesize = [];
end

%Add "next" button.
pctb = uitoolbar(fig);
uipushtool(pctb,'TooltipString','Next','ClickedCallback','close(get(get(gcbo,''parent''),''parent''))','cdata',gettbicons('FrwdArrow'));

[m, n]= size (x);j=0;
if nargin == 1;  [m, n] = size (x); y = x; x = 1: m; linetype = '-';end;
if nargin == 2; linetype = '-';
  [m, n] = size (x);
  if isstr (y); linetype = y; y = x; x = 1: m;
  else;
    [p, q] = size (y);
    if (p + q) == 2;
      linetype = '-'; y = x; x = 1: m; flagsave = 1;
    end;
  end;
end;
if nargin == 3;
  if isstr (y); linetype = y; y = x; x = 1 : m; flagsave = 1; end;
  if ~isstr (linetype); linetype = '-'; flagsave = 1; end;
end;

%EXTRACT PROPER INFORMATION OUT OF LINETYPE

if any(linetype=='@');
  flagxdir=1;
  linetype=linetype(linetype~='@');
  if isempty(linetype);linetype='-';end;
else
  flagdirx=0;
end;

l = length (linetype); color2 = 'k';
if l > 1; color2 = linetype (:, (linetype ~= '|')); end;

[x,y]=lineup(x,y);maxplot=size(y,2);
if size(x,2)==1;flag1x=1;else;flag1x=0;;end;
drawnow;
set(gcf,'name','Resolved Data');
done1=0;done2=0;i=0;
while ~done1;
  done2=0;
  j=0;
  if ~ishandle(fig)
    %Bug fix, create new figure to plot on.
    %This will occur if more than 4 Pure Vars have been selected.
    fig = figure('name','Resolved Data');
    %Add "next" button.
    pctb = uitoolbar(fig);
    uipushtool(pctb,'TooltipString','Next','ClickedCallback','close','cdata',gettbicons('FrwdArrow'));
  end
  subplot(221);cla;set(gca,'Visible','off');
  subplot(222);cla;set(gca,'Visible','off');
  subplot(223);cla;set(gca,'Visible','off');
  subplot(224);cla;set(gca,'Visible','off');

  while ~done2;
    j=j+1;
    i=i+1;
    if flag1x
      ix=1;
    else
      ix=i;
    end
    
    if ~any(linetype=='|');
      minx=min(x(:,ix));maxx=max(x(:,ix));
      subplot(2,2,j);
      if ~isempty(imagesize)
        imagesc(reshape(y(:,i),imagesize(1),imagesize(2)));
        cax = caxis;
        caxis([0 cax(2)]);
        axis image;
        colormap hot;
      else
        if flagxdir;
          plot ([minx maxx],[0,0],'k',x(:,ix),y(:,i),linetype);
          set(gca,'Xdir',vardir(x));
          myaxis(x(:,ix),y(:,i),options);
        else;
          plot (x(:,ix),y(:,i),linetype);
        end;
      end;

      if flagmultistring;
        title_string=[num2str(i),'/',num2str(maxplot)];
        title(title_string);
        xlabel(titlestring(i,:));
      else;
        title_string=[num2str(i),'/',num2str(maxplot)];
        title(title_string);
        xlabel(titlestring);
      end;
    else
      subplot(2,2,j);[temp1,temp2]=lbar(x(:,ix),y(:,i),options);
      plot (temp1, temp2, color2);
      myaxis(x(:,ix),y(:,i),options);
      if flagmultistring;
        xlabel(titlestring(i,:));
      else
        title([num2str(i),'/',num2str(maxplot)]);
        xlabel(titlestring);
      end;
      if flagxdir;set(gca,'Xdir',vardir(x));end;
    end
    if ~isempty(SUBTITLE_STRING);subtitle(SUBTITLE_STRING,options);end;
    if i==maxplot
      done1=1;
      done2=1;
    end;
    if j==4
      done2=1;
    end
  end;

  if ~exist ('flagsave'); flagsave = 0; end;
  if flagsave == 1;
    print -dwin;
  else;
    try;
      %[a,b,c]=ginput(1);
      if options.demo
        waitforbuttonpress;
        close(fig);
      else
        uiwait(fig);
      end
      a = 0;
      b = 0;
      c = 0;
    catch

      return;
    end;%wwginput
    if isempty(a);a=0;end;
    if isempty(b);b=0;end;
    if isempty(c);c=0;end;
    
    if c==45;
      i=i-6;
      if i<0;
        i=0;
      end;
    end;
    
    if c==113;
      break;
    end;
  
  end;

end;
%%%%%%%close
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [xl,yl]=lineup(x,y);
%function [xl,yl]=lineup(x,y);
%lineup matrices so that they have the same # of rows.
%If x and y are (row or column) arrays columns will result


[nrowx,ncolx]=size(x);
[nrowy,ncoly]=size(y);
if nrowx==1;x=x';temp=nrowx;nrowx=ncolx;ncolx=temp;end;
if nrowy==1;y=y';temp=nrowy;nrowy=ncoly;ncoly=temp;end;
if (nrowx==nrowy)&(ncolx==ncoly);yl=y;xl=x;end;
if nrowx==nrowy;xl=x;yl=y;return;end;
if nrowx==ncoly;xl=x;yl=y';return;end
if ncolx==nrowy;xl=x';yl=y;return;end;
if ncolx==ncoly;xl=x';yl=y';return;end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function  v = myaxis(x, y, options);
%
%function v = myaxis (x, y)
%sets the axis function for plotting spectra,
%so that the x values cover the whole x-axis, and so that the
%minimum value on the y-axis is zero, or min (y) . The maximum of
%the y-axis is 1.1 * max (y). If the outputargument is used, the function
%only returns the values, and does not set the axes.

%if nargout==1;if (any(any(imag(y))));return;end;end;

if nargin==2;
  if (any(any(imag(y))));v=[0 1 0 1];return;end;
end;


if nargin==0;
  %     a=axis;x=a(1:2);y=a(3:4);
  h=get(gca,'Children');
  minx=inf;
  maxx=-inf;
  miny=inf;
  maxy=-inf;
  for i=1:length(h);
    if strcmp(get(h(i),'type'),'line');
      x=get(h(i),'Xdata');
      if min(x)<minx;minx=min(x);end;
      if max(x)>maxx;maxx=max(x);end;
      y=get(h(i),'Ydata');
      if min(y)<miny;miny=min(y);end;
      if max(y)>maxy;maxy=max(y);end;
    end;
  end;
  x=[minx maxx];y=[miny maxy];
end;
[m, n] = size (y);
v(1)=min(x);v(2)=max(x);
temp = min (min (y));
maxmaxy = max (max (y));
v(4)=maxmaxy+.1*abs(maxmaxy);
v (3) = min (0, temp);
v=nan20(v);
if v(3) < 0; v (3) = v (3) - (.1 *abs(maxmaxy)); end
if v(1)==v(2);v(1)=v(1)-1;v(2)=v(2)+1;end;
if v(3)==v(4);v(3)=v(3)-1;v(4)=v(4)+1;end;

%Deal with nargout plus figure. Subtract 1 from nargout if return figure
%option is on.
if strcmp(options.returnfig,'on') & nargout > 0
  nout = nargout-1;
else
  nout = nargout;
end

if nout==0;axis(v);end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [xo,yo] = lbar(x,y, options)
%function [xo,yo] = lbar(x,y)
%is an adaptation of the function bar,
%with the difference that the bars are lines.
%lbar(y) draws a bar graph of the elements of vector y.
%lbar(x,y) draws a bar graph of the elements in vector y at
%the locations specified in x.
%[xx,yy] = bar(x,y) does not draw a graph, but returns vectors
%x and y such that plot(xx,yy) is the bar chart.

n = length(x);
if nargin == 1
  y = x;
  x = 1:n;
end
x = x(:);
y = y(:);
nn = 3*n;
yy = zeros(nn+1,1);
xx = yy;
yy(2:3:nn) = y;
%yy(3:3:nn) = y;
delta = (max(x) - min(x)) / (n-1);
t = x(:)' - 0.5*delta;
xx(1:3:nn) = x;
xx(2:3:nn) = x;
xx(3:3:nn) = x;
xx(nn+1) = xx(nn);

%Deal with nargout plus figure. Subtract 1 from nargout if return figure
%option is on.
if strcmp(options.returnfig,'on') & nargout > 0
  nout = nargout-1;
else
  nout = nargout;
end

if nout == 0
  plot(xx,yy,'k')
  axy = axis;axis;
  if axy(1)==x(1);axy(1)=axy(1)-1;end;
  if axy(2)==x(length(x));axy(2)=axy(2)+1;end;
  hold on; plot([axy(1) axy(2)],[0 0],'k'); hold off;
else
  xo = xx;
  yo = yy;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function direction=vardir(varlist);
%function direction=vardir(varlist);
%results in the value 'normal ' when varlist is ascending and in 'reverse'
%when varlist is descending;

%TAKE OUT NAN's

array=isnan(varlist);
varlist(array)=[];
if varlist(1)<=varlist(2);direction='normal ';else;direction='reverse';end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function y=nan20(x);
%function y=nan20(x)
%returns substitutes NaN's for 0's
if ~(any(any(isnan(x))));y=x;return;end
[nrow,ncol]=size(x); p=nrow*ncol;
xreshape=reshape(x,1,p); n=1:p;
l=~isnan(xreshape);
a=n(l);b=xreshape(l);
y=zeros(1,p);
y(a)=b;
y=reshape(y,nrow,ncol);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function title4(string1,string2);
%function title4(string);
%plots a title in plot4 and plotc4.
global PLOT4_STRING SUBTITLE_STRING

SUBTTITLE_STRING=[];

if size(string1,1)>1;
  PLOT4_STRING=string1;
else
  PLOT4_STRING=[string1,' '];
end;

if nargin==2;SUBTITLE_STRING=string2;end;


%--------------------------
function out = optiondefs

defs = {

%name               tab           datatype        valid                                             userlevel       description
'display'           'Display'     'select'        {'on' 'off'}                                      'intermediate'  '[ {''off''} | ''on''] display to command window.';
'plot'              'Display'     'select'        {'on' 'off'}                                      'novice'        '[ {''off''} | ''on''] plotting of results.';
'axistype'          'Display'     'cell(select)'  {'continuous' 'discrete' 'bar'}                   'intermediate'  'Mode 1/2: [{continuous}|''discrete''|''bar''] defines plots. if emtpy the values of the (future) DSO field will be used. In case they are not defined, above the ''continuous'' defaults will be used.' ;
'select'            'Set-Up'      'mode'          'float(1:inf)'                                    'intermediate'  '[{[]},[1 2]] if empty, pure rows/columns will be selected from last slab, otherwise, the numbers identify from which slab(s) the pure rows/columns are selected';
'offset'            'Set-Up'      'mode'          'float(1:inf)'                                    'intermediate'  '[3 10] default noise correction factor the two slabs.';
'offset_row2col'    'Set-Up'      'double'        'int(1:inf)'                                      'advanced'      'scalar value row2col offset, default is offset(1).';
'mode'              'Set-Up'      'char'          {'rows' 'cols' 'row2col'}                         'advanced'      'Determines if pure rows, cols are selected. Row2col is row-to-column solution.';
'algorithm'         'Set-Up'      'char'          {'purityengine'}                                  'advanced'      'Defines algorithm used.';
'interactive'       'Set-Up'      'select'        {'on' 'off' 'cursor' 'interactive' 'reactivate'}  'advanced'      'Defines interactivity; ''on'',''cursor'',''inactivate'',''reactivate'' are used for higher level calls for interactivity, ''off'' is used for demos and command mode applications.';
'resolve'           'Set-Up'      'select'        {'on' 'off'}                                      'advanced'      'Empty.'
};

out = makesubops(defs);

%----------------------------------
function h=plot_labels(x,y,labels)
%PLOT_LABELS plots labels, strings, text
%use:plot_labels(x,y,labels);
%x-y scatter plot with text in labels as data points.
%if labels are not given, sequence numbers are used
%h is handle of text function used

if nargin==2;labels=num2str([1:length(y)]');end
%example: plot_labels(x,y,);

h=plot(x,y);
set(h,'Linestyle','none')
h=text(x,y,labels);
set(h,'HorizontalAlignment','Center','VerticalAlignment','Middle','color',[1 1 1],'backgroundcolor',[0 0 0],'fontsize',7);

%-----------------------------------
function [x2plot,x2plot_lim,index_exclude]=x2plot_incl(data,dim);%^$

n=length(data.axisscale{dim});%^$
%x2plot_lim=sort(data.axisscale{dim}([1 end]));%^$

index_exclude=setdiff([1:n],data.include{dim});%^$
x2plot=data.axisscale{dim};%^$
x2plot(index_exclude)=NaN;%^$

ax=find(~isnan(x2plot));
x2plot_lim=sort(x2plot(ax([1 end])));
