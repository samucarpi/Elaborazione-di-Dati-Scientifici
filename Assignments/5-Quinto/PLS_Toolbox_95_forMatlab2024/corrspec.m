function [purintx,purinty,purspecx,purspecy,maps]=corrspec(xspec,yspec,ncomp,options)
%CORRSPEC Resolves correlation spectroscopy maps.
%
% INPUTS
%       xspec : (2-way array class "double" or "dataset") x-matrix for
%               dispersion matrix.
%       yspec : (2-way array class "double" or "dataset") y-matrix for
%               dispersion matrix.
%       The third argument is one of the following:
%       ncomp : scalar, function will calculate first n resolved pure
%               components.
%       index : n x 2 matrix, each row indicates the x and y
%               pure variable indices to calculate the purity solution. For
%               example: [435 249; 24 400]
%               If empty, the initial matrices will be calculated.
%       model : a model created by corrspec or corrspecgui. The model is
%               used to calculate estimated xspec from yspec and vice
%               versa. One of the arguments xspec and yspec can be empty.
%     options : See below.
%
% OPTIONAL INPUT options structure with one or more of the following fields
%       plots_spectra   : ['off'|{'on'}] governs level of plotting for spectra.
%       plots_maps      : ['off'|{'on'}] governs level of plotting for maps.
%       offset          : noise correction factor. One element defines offset for
%                         both x and y, two elements separately for x and y.
%       inactivate      : [ ] logical matrix of indices not to be used in purity
%                         calculation.
%       dispersion      : [1] See max (below).
%       max             : [3] If not given, only weight matrix
%                         will be calculated, otherwise select one of
%                         the options below:
%
%                 1: synchronous correlation
%                 2: asynchronous correlation
%                 3: synchronous covariance
%                 4: asynchronous covariance
%                 5: purity about origin
%                 6: purity about mean
%
% OUTPUT:
%     purintx  = resolved x contributions('concentrations').
%     purinty  = resolved y contributions('concentrations').
%     purspecx = resolved x pure component spectra.
%     purspecy = resolved y pure component spectra.
%     maps     = cell with ncomp resolved dispersion matrixes, each with
%                size: size(yspec,2)*size(xspec,2)
%
%     model    = standard model structure, used for prediction (same pure
%                variables on other data set) and add components to the
%                model.
%                the series of correlation maps resulting from the
%                sequential elimination of components is stored in the
%                field detail.matrix. See function corrspecengine for
%                detailed description of matrix.
%                the series of resolved correlation maps is stored in field
%                detail.maps.
%                once a model has been calculated it can be used to predict
%                x spectra from y spectra and vice versa.
%
%I/O: model = corrspec(xspec,yspec,ncomp,options);
%I/O: [purintx,purinty,purspecx,purspecy,maps] = corrspec(xspec,yspec,index,options);
%I/O: [purintx,purinty,purspecx,purspecy,maps] = corrspec(xspec,yspec,model,options);
%
%See also: CORRSPECENGINE, CORRSPECGUI, DISPMAT

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%ww  09/28/06

%if nargin == 0; analysis corrspecgui; return; end
if nargin == 0; xspec = 'io'; end

if ischar(xspec);

  options = [];
  options.name            = 'options';
  options.plots_spectra   = 'on';     %Governs plots to make
  options.plots_maps      = 'on';     %Governs plots to make
  options.offset          = 3;
  options.inactivate      = [];       %indices not to use
  options.dispersion      = 1;    %SVD algorithm
  options.max             = 5;    %SVD algorithm

  if nargout==0
    evriio(mfilename,xspec,options);
  else
    purintx = evriio(mfilename,xspec,options);
  end
  return;
end;

%Check for minimum number of inputs.
if nargin==1
  %If only one spectra given then make y = x.
  yspec = xspec;
end

%Check number of components.
% if nargin<3||(~isempty(ncomp)&&length(ncomp)==1&&ncomp==0)
%   %WW CHECK
%   ncomp = [];
% end

if nargin<3;ncomp = [];end;

if ~isempty(ncomp)
  if length(ncomp)==1;
    try
      if ncomp==0;ncomp = [];end;
    catch
    end;
  end;
end


%TODO: Finish model call.
%I/O: [purintx,purinty,purspecx,purspecy,maps] =
%corrspec(xspec,yspec,model,options);

%Deal with options.
if nargin<4
  options = corrspec('options');
else
  %Fill in any missing options.
  options = reconopts(options,corrspec('options'),0);
end

%Get offsets.
if isscal(options.offset)
  options.offset = [options.offset options.offset];
end

%if one of xspec of yspec is dataset object, other will be made into one.WW
if ~isdataset(yspec)&(~isempty(yspec));%WWW
  [nrows,ncols]=size(yspec);
  yspec=dataset(yspec);
  yspec.axisscale{1}=[1:nrows];
  yspec.axisscale{2}=[1:ncols];
elseif isempty(yspec);
  yspec=dataset([]);
end;

if ~isdataset(xspec)&(~isempty(xspec));%WWW
  [nrows,ncols]=size(xspec);
  xspec=dataset(xspec);
  xspec.axisscale{1}=[1:nrows];
  xspec.axisscale{2}=[1:ncols];
elseif isempty(xspec);
  xspec=dataset([]);
end;

%get common include{1};

if ~ismodel(ncomp);%WWW
  [x_include1_common,y_include1_common] = corrspecutilities('get_include_common',xspec,yspec);
else
  x_include1_common=xspec.include{1};
  y_include1_common=yspec.include{1};
end;

%Pull raw data out.
if isdataset(xspec)
  %xdata = xspec.data
  xdata = xspec.data(x_include1_common,xspec.include{2});%WW
else
  xdata = xspec;
end

if isdataset(yspec)
  %ydata = yspec.data;
  ydata = yspec.data(y_include1_common,yspec.include{2});
else
  ydata = yspec;
end

%Give warning when row dimension of xdata and ydata are not equal.
if ~ismodel(ncomp);%make exception for prediction
  if size(xdata,1)~=size(ydata,1)
    error('Row dimensions for xspec and yspec are not equal.')
  end
else
  if ~isempty(xdata);
    if size(xdata,2)~=size(ncomp.loads{2},2);
      error('Row dimensions for xspec and model are not equal.');
    end
  end
  if ~isempty(ydata);
    if size(ydata,2)~=size(ncomp.loads{4},2);
      error('Row dimensions for yspec and model are not equal.');
    end
  end
end

%Get axis scale if exists. Create unit axis scale if doesn't exist.
axis_x1 = [];
axis_x2 = [];
% if isdataset(xspec)
%   axis_x1 = xspec.axisscale{1};
%   axis_x2 = xspec.axisscale{2};
% end
% if isempty(axis_x1)
%   axis_x1 = 1:size(xdata,1);
% end
% if isempty(axis_x2)
%   axis_x2 = 1:size(xdata,2);
% end
if isdataset(xspec)
  axis_x1 = xspec.axisscale{1}(x_include1_common);%WW
  axis_x2 = xspec.axisscale{2}(xspec.include{2});%WW
end
if isempty(axis_x1)
  axis_x1 = 1:size(xdata,1);
end
if isempty(axis_x2)
  axis_x2 = 1:size(xdata,2);
end


axis_y1 = [];
axis_y2 = [];
% if isdataset(yspec)
%   axis_y1 = yspec.axisscale{1};
%   axis_y2 = yspec.axisscale{2};
% end
% if isempty(axis_y1)
%   axis_y1 = 1:size(ydata,1);
% end
% if isempty(axis_y2)
%   axis_y2 = 1:size(ydata,2);
% end
if isdataset(yspec)
  axis_y1 = yspec.axisscale{1}(y_include1_common);%WW
  axis_y2 = yspec.axisscale{2}(yspec.include{2});%WW
end
if isempty(axis_y1)
  axis_y1 = 1:size(ydata,1);
end
if isempty(axis_y2)
  axis_y2 = 1:size(ydata,2);
end

%USE A MODEL AND PREDICT

if ismodel(ncomp);
  model=ncomp;
  maps=[];%model fields not calculated
  matrix=[];%model fields not calculated

  if isempty(xspec);xspec.data=[];end;
  if isempty(yspec);yspec.data=[];end;
  %[purspecx,purspecy,...
  %  purintx,purinty]=...
  %  predictxy2(model.loads{1},model.loads{2},...
  %  model.loads{3},model.loads{4},xspec.data,yspec.data);
  [purspecx,purspecy,purintx,purinty]=predictxy2(model.loads{1},...%WW
    model.loads{2},model.loads{3},model.loads{4},...
    xspec.data(x_include1_common,xspec.include{2}),...
    yspec.data(y_include1_common,yspec.include{2}));

else
  %Determine call to corrspecengine.
  if isempty(ncomp);%for purvarindex [];
    %ncomp is empty.
    varindx = [];
    cormatrix = corrspecengine(xdata,ydata,varindx,options.offset,[options.dispersion options.max]);
    matrix{1}=cormatrix;
    purintx=[];%^^^^^^^^^^^
    purspecx=[];%^^^^^^^^^^^^
    purinty=[];%^^^^^^^^^^^^
    purspecy=[];%^^^^^^^^^
    maps=[];%^^^^^^^^^
    dmap=[];
    dispmat_reconstructed=[];%model fields not calculated
    sum_matrix=[];%model fields not calculated

  elseif isscal(ncomp)
    %ncomp is number of components to calculate.
    for i=1:ncomp+1;
      if i == 1
        varindx = [];
      else
        m = max(max(cormatrix{3}));
        [r,c] = find(cormatrix{3}==m);
        varindx = [varindx; [c(1) r(1)]];
      end
      cormatrix = corrspecengine(xdata,ydata,varindx,options.offset,[options.dispersion options.max]);
      matrix{i}=cormatrix;
      if strcmp(options.plots_maps,'on');

        %PLOT DISP MATRIX

        matrix2plot=cormatrix{2};
        matrix2plot(matrix2plot<0)=0;
        plot_corr(axis_x2,axis_y2,matrix2plot,copper(64),0,3);
        %            plot_corr(axis_x2,axis_y2,matrix2plot,hot,0,3);
        hold on

        %ADD CURSOR

        m=max(max(cormatrix{3}));
        [r,c]=find(cormatrix{3}==m);
        purvar_index2=[c(1) r(1)];
        h=vline(axis_x2(purvar_index2(1)),'k');
        set(h,'zdata',repmat(matrix2plot(purvar_index2(2),purvar_index2(1)),1,2));
        set(h,'EraseMode','xor');
        h=hline(axis_y2(purvar_index2(2)),'k');
        set(h,'EraseMode','xor');
        set(h,'zdata',repmat(matrix2plot(purvar_index2(2),purvar_index2(1)),1,2));
        axis square;
        hold off

        waitforbuttonpress
        %close;
      end;
    end
  else
    %Index given, ncomp is list of pure variables indices to calculate.
    varindx = ncomp;
    cormatrix = corrspecengine(xdata,ydata,varindx,options.offset,[options.dispersion options.max]);
    matrix{1}=cormatrix;
  end;

  if ~isempty(ncomp);%^^^^^^^^^^^^^^^^^^^^^^


    %Pass plot settings to resolve spec fucntion.
    ropts.plots = options.plots_spectra;
    %Get resolved contributions and spectra
    [purintx,purinty,purspecx,purspecy] = resolve_spectra_2d_cor(varindx(:,1),varindx(:,2),...
      xdata,ydata,axis_x2,axis_y2,axis_x1,ropts);

    %Get resolved contributions maps.
    copts.offsetx    = options.offset(1);
    copts.offsety    = options.offset(end);
    copts.dispersion = options.dispersion;
    dmap=dispmat(xdata,ydata,copts);%needed for plotting in function dispt

    %Get correlation maps.
    ropts.zlim1=0;
    ropts.nlevel=3;
    ropts.clrmap='copper';
    ropts.offset=options.offset;
    ropts.dispersion = options.dispersion;

    [maps,dispmat_reconstructed,sum_matrix]=...
      resolve_maps_2d_cor(purintx,purinty,purspecx,purspecy,axis_x2,axis_y2,dmap,ropts);
  end;%^^^^^^^^^^^^^^^^^^^^^^^
end;

%TODO: Check model input. Make sure prediction won't cause error here.
if nargout == 1
  if ismodel(ncomp);
    %Output is prediction.
    buffer=purintx;
    purintx = [];
    purintx.loads{1,1} = buffer;
    purintx.loads{2,1} = purspecx;
    purintx.loads{1,2} = purinty;
    purintx.loads{2,2} = purspecy;
  else
    %Output model.
    mod = modelstruct('corrspec');
    mod.date = date;
    mod.time = clock;
    mod.loads{1,1} = purintx;
    mod.loads{2,1} = purspecx;
    mod.loads{1,2} = purinty;
    mod.loads{2,2} = purspecy;

    %Other model outputs here.

    [datasource{1:2}] = getdatasource(xspec,yspec);
    mod.datasource = datasource;
    mod.detail.options = options;
    mod.detail.maps = maps;
    mod.detail.matrix=matrix;
    mod.detail.purvarindex=varindx;
    mod.detail.dispmat=dmap;
    mod.detail.dispmat_reconstructed=dispmat_reconstructed;
    mod.detail.sum_matrix=sum_matrix;
    mod.detail.axisscale{1,1}=xspec.axisscale{1};
    mod.detail.axisscale{2,1}=xspec.axisscale{2};
    mod.detail.axisscale{1,2}=yspec.axisscale{1};
    mod.detail.axisscale{2,2}=yspec.axisscale{2};

    purintx = mod;
  end
end

%---------------------------------------------------------
function [purspecx_predicted,purspecy_predicted,...
  purintx_predicted,purinty_predicted]=...
  predictxy2(purintx,purspecx,purinty,purspecy,datax2,datay2);

if isempty(datax2);
  purspecy_predicted=[];
  purinty_predicted=[];
else;
  [purspecy_predicted,purinty_predicted]=...
    predictx(purintx,purspecx,purinty,purspecy,datax2,1);
end;

if isempty(datay2);
  purspecx_predicted=[];
  purintx_predicted=[];
else;
  [purspecx_predicted,purintx_predicted]=...
    predictx(purintx,purspecx,purinty,purspecy,datay2,2);
end;

%---------------------------------------------------------
function [purspec_pred,purint_pred]=predictx(purintx,purspecx,purinty,purspecy,data2pr,option);
%function datapr =predictx(purintx,purspecx,purinty,purspecy,data2pr,option);
%predicts x or y data in data2pr into y or x in datapr.
%if data2pr is x data, option should be 1
%if data2pr is y data, option should be 2
%the objects in datapr are in rows;

[nrow,ncol]=size(data2pr);
ncolx=size(purspecx,2);
ncoly=size(purspecy,2);
nspec=size(purintx,1);

%respf=std(purintx)./std(purinty);
respf=diag(purinty\purintx);
lx=sqrt(sum(purintx.*purintx));
ly=sqrt(sum(purinty.*purinty));
respf=lx./ly;
respfmatrix=diag(respf);

if option==1;
  datapr=zeros(nrow,ncolx);
  model1=purspecx;
  model2=purspecy;
  respfmatrix=inv(respfmatrix);
else
  datapr=zeros(nrow,ncoly);
  model1=purspecy;
  model2=purspecx;
end;

purint_pred=data2pr/model1;
purint_pred=purint_pred*respfmatrix;
purspec_pred=purint_pred*model2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




