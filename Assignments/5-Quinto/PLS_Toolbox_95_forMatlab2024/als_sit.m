function [model,x] = als_sit(x,ncomp,options)
%ALS_SIT Alternating least squares with shift invariant tri-linearity
%  ALS_SIT employs an MCR-like model to employ a tri-linearity constraint
%  to factors that may shift (e.g., GC/LC elution profiles). See: 
%    Schneide, P.-A., Bro, R., Gallagher, N., "Shift-invariant tri-linearity
%   (SIT) - A new model for resolving untargeted GC-MS data," J Chemom (2023).
%    Schneide, P.-A., Bro, R., Gallagher, N., "Soft shift-invariant
%   tri-linearity: modelling shifts and shape changes in gas-chromatography 
%   coupled mass spectrometry," [in progress] (2023).
%  It can also be use for non-shifting profiles:
%    Tauler, R., Marques, I., Casassas, E., J Chemom, 12(1), 55–75 (1998),
%
%  The convention for ALS_SIT is that samples are in the last mode and the
%  shifting profiles are in the first mode. E.g. if the samples for 
%  input (x) Mode 1, and the shifting mode is Mode 2, the call to ALS_SIT is
%     model = als_sit(permute(x,[2,3,1]),ncomp);
% 
%  INPUTS:
%         x = multi-way array to be decomposed
%             If (x) is an IxJxK array (all K slabs have similar size) then
%               this is similar to an input for PARAFAC.
%             If the K slabs have different size then (x) is input as a cell
%               array e.g., x{1} = x1; x{2} = x2; (note the curly brackets).
%               Mode 1 of the X{k} can shift and/or have different dimensions
%               [i.e., size(x{k},1)] can vary, but Mode dimension 
%               [size(x{k},2] is the same for all x{k}, k=1,...,K.
%     ncomp = the number of components to estimate
% 
%  OPTIONAL INPUTS:
%   options = structure array with the following fields:
%     display       = [ 'off' | {'on'} ]     governs level of display to command window
%     plots         = [ 'none' | {'final'} ] governs level of plotting
%     waitbar       = [ 'off' | {'on'} ]     governs use of waitbar
%     ittol         = [ {1e-6} ];  relative change in model residuals
%     ittolabs      = [ {1e-6} ];  absolute change in model residuals
%     itmax         = [ {100} ];   maximum number of iterations
%     timemax       = [ {3600} ];  maximum time for iterations (s)
%     sitconstraint = []; 1xncomp, factors to be constrained with SIT {default=all}
%                         Valid entries include 0, 1, 2 described as:
%                      0: (or "NaN") does not employ tri-linearity,
%                      1: employs soft trilinearity (not shift invariant) see: 
%                          Tauler, R., Marques, I., Casassas, E., "Multivariate curve 
%                          resolution applied to three-way trilinear data: Study of a
%                          spectrofluorimetric acid–base titration of salicylic acid at
%                          three excitation wavelengths," J Chemom, 12(1), 55–75 (1998),
%                      2: employs SIST when options.shiftmap.ncomp ~= 1 or
%                         SIT when options.shiftmap.ncomp ==1.
%     shiftmap = SHIFTMAP options, structure array with the following fields:
%                        (see SHIFTMAPfor a complete listing)
%             ncomp = 0.95 {default} scalar number of PCs, K, for PCA of the
%                         amplitude spectra in SIST or SIT.
%                         If 0<ncomp<1 then this is fraction variance captured,
%                         if ncomp>1 this is the number of PCs, or
%                         if ncomp==1, then the algoritm is SIT.
%                        Note that (ncomp) can be a 1xK vector allowing a
%                        different number of PCs for each of the K factors.
%                        (ncomp) is not used for factors w/ sitconstraint = 0.
%          options.als = ALS options, structure array with the following fields:
%                        (see ALS for a complete listing)
%             itmax = 2 {default} maximum number of iterations in the alternating
%                       constrained least squares algorithm.
% 
%  OUTPUT:
%     model         = standard model object, or
%     pred          = standard prediction object.            
%                      model.sitsmodel has the following fields (see SHIFTMAP):
%                      p = NpxK loadings: p = Pb for SITS.
%                     a0 = standard phase spectrum. 
%                      t = MxK scores: Tb for SIST.
%     xo            = bi-linear form of input(x) used w/in ALS_SIT.
% 
%I/O: model   = als_sit(x,ncomp);                 % identifies model with default options (calibration step)
%I/O: model   = als_sit(x,ncomp,options);         % identifies model (calibration step)
%I/O: options = als_sit('options');               % returns a default options structure
%I/O: pred    = als_sit(xnew,model);              % find scores for new samples given old model
%I/O: als_sit demo
%  
%%See also: ALS, MCR, PARAFAC, PARAFAC2, SHIFTMAP, TLD, TUCKER, UNFOLDM

%% Set options
if nargin==0; x = 'io'; end
if ischar(x)
  options = [];
  options.name          = 'options';
  options.display       = 'on';    %[ 'off' | {'on'} ]      %governs level of display to command window,
  options.plots         = 'final'; %'none' | {'final'} ]    %governs level of plotting,
  options.waitbar       = 'on';  %[ 'off' | {'on'} ] %governs use of waitbar,
  options.ittol         = 1e-6;  %relative change in model residuals
  options.ittolabs      = 1e-6;  %absolute change in model residuals
  options.itmax         = 100;   %maximum number of iterations
  options.timemax       = 3600;  %maximum time in seconds
  options.sitconstraint = [];    %factors to be constrained with SIT {default=all}
  options.preprocessing = {[]};
  options.stopcrit      = zeros(1,4);
  options.confidencelimit = 0.95;
  options.shiftmap      = shiftmap('options');

  options.als           = als('options');
  options.als.display   = 'off';
  options.als.plots     = 'none';
  options.als.itmax     = 2;

  % options.definitions: @optiondefs;
  options.functionname  = 'als_sit';

  if nargout==0; evriio(mfilename,x,options); 
  else;  model = evriio(mfilename,x,options); end
  return
end
%NOTE:
%  Constraints not used yet
%   options.constraints   = cell(3,1); ??
%   for ii=1:3
%     options.constraints{ii} = constrainfit('options');
%   end
%  Preprocessing not used yet (apply to 3-way? not 2-way?)
%  model apply not working yet
%  plotscores uses plotscores_mcr and doesn't work yet

if nargin<3
  options               = als_sit('options');
else
  options               = reconopts(options,'als_sit');
end
if options.als.itmax<2
  options.als.itmax     = 2;
end
if isempty(options.preprocessing)
  options.preprocessing = {[]};
end
if ~isa(options.preprocessing,'cell')
  options.preprocessing = {options.preprocessing};
end
if strcmp(options.waitbar,'on')
  options.waitbar       = true;
end

%% Initialize
predictmode             = false;  % check I/O for model (predictmode)
if ismodel(ncomp)
  predictmode           = true;
  model                 = ncomp; % model = prediction, ncomp is model
  model.modeltype       = [model.modeltype,'_pred'];
  options.als.itmax     = 1;
else
  % Apply preprocessing N-way preprocessing here ??
  % if ~isempty(options.preprocessing{1});
  %   [z,options.preprocessing{1}] = preprocess('calibrate',options.preprocessing{1},z);
  model                 = evrimodel('als_sit');
  model.detail.preprocessing = options.preprocessing;
end

% check input (x) and create 3-way array (z) of included
if isdataset(x)
  if iscell(x.data)
    model.sitmodel.length1  = zeros(1,size(x.data,1));
    for i1=1:length(model.sitmodel.length1)
      model.sitmodel.length1(i1)  = size(x.data{i1},1);
    end
    tmp                 = rmset(x,'axisscale',1,1);
    x                   = dataset(cell2array(x.data));
    x.include{3}        = tmp.include{1};
    x                   = permute(copydsfields(tmp,permute(x,[3 2 1]),1),[3 2 1]);
    x                   = copydsfields(tmp,x,2);
    if ~predictmode
      x.include{2}      = tmp.include{2};
    else
      x.include{2}      = ncomp.detail.include{2};
    end
    z                   = x.data.include; %all rows w/in each cell are included
  else
    model.sitmodel.length1  = ones(1,size(x,3))*size(x,1);
    z                   = x.data.include;  %extract included 3-way data
  end
elseif iscell(x)                           %all rows w/in each cell are included
  tmp                   = size(x{1});
  x                     = dataset(reshape(cell2array(x),[tmp size(x,1)]));
  model.sitmodel.length1    = ones(1,size(x,3))*tmp(1);
  z                     = x.data;
end
mx                      = size(x); %x is 3-way here

if ~predictmode
  if isempty(options.shiftmap.np)||options.shiftmap.np<max(model.sitmodel.length1)
    options.shiftmap.np = 2.^nextpow2(max(model.sitmodel.length1));
  end
  if isempty(options.sitconstraint)
    options.sitconstraint = ones(1,ncomp)*2; %default is SIT
  else
    if length(options.sitconstraint)~=ncomp
      error('options.sitconstraint must be a vector of length (ncomp).')
    end
    options.sitconstraint(options.sitconstraint>2) = 2;
  end
  if isempty(options.shiftmap.ncomp)
    shiftmapncomp       = ones(1,ncomp); %vector version of options.shiftmap.ncomp
  elseif isscalar(options.shiftmap.ncomp)
    shiftmapncomp       = options.shiftmap.ncomp(ones(1,ncomp));
  else
    if length(options.shiftmap.ncomp)~=ncomp
      error('When (options.shiftmap.ncomp) is a vector is must be size 1xncomp');
    end
    shiftmapncomp       = options.shiftmap.ncomp;
  end
  model.sitmodel.p      = cell(1,ncomp);
  model.sitmodel.t      = cell(1,ncomp);
  % for i2=find(options.sitconstraint>0)
  %   model.sitmodel.p{i2}  = NaN(mx(1),shiftmapncomp(i2));
  %   model.sitmodel.t{i2}  = NaN(mx(3),shiftmapncomp(i2));
  % end
  model.sitmodel.a0     = cell(1,ncomp);
  model.sitmodel.include  = x.include;
end
model.datasource        = {getdatasource(x)};

tmp                     = repmat(x.include{1}(:),1,length(x.include{3})) + ...
                          repmat((x.include{3}-1)*size(x,1),length(x.include{1}),1);
x                       = reshape(permute(x,[1 3 2]),[mx(1)*mx(3) mx(2)]);
x.include{1}            = tmp(:)';
x.axisscale{1}          = repmat(1:mx(1),1,mx(3));
x.axisscalename{1}      = 'Mode 1';
tmp                     = repmat(1:mx(3),mx(1),1);
x.class{1}              = tmp(:)';
x.classname{1}          = 'Sample Number';
model                   = copydsfields(x,model,1,{1 1}); %copy only mode one labels, etc.
model.detail.axisscale{2} = x.axisscale{2};
model.detail.axisscalename{2} = x.axisscalename{2};

model.sitmodel.info     = char('p is a 1xncomp cell array where each cell is a ', ...
                          'set of PCA loadings [SHIFTMAP Input (p)]', ...
                          ['a0 is a 1xncomp cell array where each cell is a ' ...
                          'standard phase spectrum used in SITS [SHIFTMAP Input (a0)].']);
m                       = size(z);
z                       = reshape(permute(z,[1 3 2]),[m(1)*m(3) m(2)]);
waitbarhandle           = [];

if predictmode % Prediction
  options               = ncomp.detail.options;
  model.loads{1}        = als(z,ncomp.loads{2}',options.als);
  for i2=find(options.sitconstraint==0)   %MCR Factors
    model.sitmodel.t{i2}  = reshape(model.loads{1}(:,i2),[m(1) m(3)])'*ncomp.sitmodel.p{i2};
  end
  for i2=find(model.detail.options.sitconstraint==1)  % Soft Tri-Linearity (Tauler)
    model.sitmodel.t{i2}  = reshape(model.loads{1}(:,i2),[m(1) m(3)])'*ncomp.sitmodel.p{i2};
    t                     = ncomp.sitmodel.p{i2}*model.sitmodel.t{i2}';
    model.loads{1}(:,i2)  = t(:);
  end
  for i2=find(model.detail.options.sitconstraint==2)  % SIT and SIT Softly
    options.shiftmap.algorithm  = 'sist'; % SIST for slab scores and a0
    options.shiftmap.ncomp      = ncomp.detail.options.shiftmap.ncomp(i2);
    [~,~,~,xsit,~,~,model.sitmodel.t{i2}] = shiftmap(reshape(model.loads{1}(:,i2),[m(1) m(3)]), ...
                                  model.sitmodel.p{i2},model.sitmodel.a0{i2},options.shiftmap);
    model.loads{1}(:,i2)  = xsit(:);
  end

  % Pred Stats
  rese                  = (z-model.loads{1}*ncomp.loads{2}').^2;
  model.ssqresiduals{1,1}  = sum(rese,2);
  model.ssqresiduals{2,1}  = sum(rese,1);
  
  model.date            = date;
  model.time            = clock;

else           % Calibration
  % initialize ALS
  [~,tmp]               = exteriorpts(z,ncomp,struct('distmeasure','Mahalanobis'));
  model.loads{1}        = NaN(size(x,1),ncomp);
  model.loads{1}(x.include{1},:)  = tmp{1};

  model.loads{2}        = zeros(size(z,2),ncomp);
  alsoptions            = options.als;
  alsoptions.itmax      = 1;
  options.stopcrit      = zeros(1,4);    % rel change abs change iterations seconds];
  rabs0                 = norm(z,"fro"); % absolute change
  options.timemax       = options.timemax/86400; % change sec to days (works with datenum)
    
  strtt                 = datenum(datetime("now")); %now;
  % waitbarhandle         = [];
  while options.stopcrit(3)<options.itmax
    if options.waitbar && isempty(waitbarhandle)
      waitbarhandle     = waitbar(options.stopcrit(4)/options.timemax,'Calculating ALS SIT...');
    end
    [model.loads{1}(x.include{1},:),tmp] = als(z,model.loads{1}(x.include{1},:),options.als);
    model.loads{1}(x.include{1},:)  = als(z,tmp,alsoptions); %force C as last estimate
    model.loads{2}                  = tmp';
    for i2=find(options.sitconstraint==1)  % Soft Tri-Linearity (Tauler)
      [~,~,model.sitmodel.p{i2}(model.sitmodel.include{1},:), ...
           model.sitmodel.t{i2}(model.sitmodel.include{3},:)] = pcaengine( ...
                           reshape(model.loads{1}(x.include{1},i2),[m(1) m(3)])', ...
                           shiftmapncomp(i2),struct('display','off'));
     t                  = model.sitmodel.p{i2}*model.sitmodel.t{i2}(model.sitmodel.include{3},:)';
      model.loads{1}(x.include{1},i2) = t(:);
    end                                    % Soft Tri-Linearity (Tauler)
    for i2=find(options.sitconstraint==2 | options.sitconstraint==3)  % SIST
      options.shiftmap.algorithm  = 'sist';
      options.shiftmap.ncomp      = shiftmapncomp(i2); %
      [~,~,~,xsit,model.sitmodel.p{i2},model.sitmodel.a0{i2}] = ...
            shiftmap(reshape(model.loads{1}(x.include{1},i2),[m(1) m(3)]),options.shiftmap);
      model.loads{1}(x.include{1},i2) = xsit(:);
    end                                     % SIST

    rese                = z-model.loads{1}(x.include{1},:)*model.loads{2}';
    rabs                = norm(rese,"fro");
    options.stopcrit(2) = rabs0-rabs;                 %abs change
    options.stopcrit(1) = options.stopcrit(2)/rabs0;  %rel change
    options.stopcrit(3) = options.stopcrit(3)+1;      %iterations
    options.stopcrit(4) = now-strtt;                  %elapsed time
    if options.waitbar && ~isempty(waitbarhandle)
      waitbar(max(options.stopcrit(3:4)./[options.itmax options.timemax]),waitbarhandle)
    end

    if options.stopcrit(4)>options.timemax  || ...
       options.stopcrit(2)<options.ittolabs || ...
       options.stopcrit(1)<options.ittol
      break
    end
    rabs0               = rabs;
  end %while it<itmax
  options.stopcrit(4)   = options.stopcrit(4)*86400; %change to seconds (from days)
  options.shiftmap.ncomp      = shiftmapncomp;
  model.detail.options        = options;
  % Finishing Steps, and predictions for excluded scores
  iexc1                 = setdiff(1:size(x,1),x.include{1});
  iexc3                 = setdiff(1:mx(3),model.sitmodel.include{3});
  z                     = x.data(iexc1,x.include{2});
  model.loads{1}(iexc1,:)     = als(z,model.loads{2}',options.als);

  for i2=find(options.sitconstraint==0)   %Finishing Step for MCR
    [~,~,model.sitmodel.p{i2}(model.sitmodel.include{1},:), ...
         model.sitmodel.t{i2}(model.sitmodel.include{3},:)] = pcaengine( ...
                           reshape(model.loads{1}(x.include{1},i2),[m(1) m(3)])', ...
                           1,struct('display','off'));
    if ~isempty(iexc1)
      model.sitmodel.t{i2}(iexc3,:)  = reshape(model.loads{1}(iexc1,i2),[m(1) length(iexc3)])'*model.sitmodel.p{i2};
    end
  end                                     %Finishing Step for MCR

  for i2=find(options.sitconstraint==1)   %Finishing Step for ST
    model.sitmodel.t{i2}(iexc3,:)  = reshape(model.loads{1}(iexc1,i2),[m(1) length(iexc3)])'*model.sitmodel.p{i2};
    if ~isempty(iexc1)
      t                 = model.sitmodel.p{i2}*model.sitmodel.t{i2}(iexc3,:)';
      model.loads{1}(iexc1,i2)     = t(:);
    end
  end                                     %Finishing Step for ST

  for i2=find(options.sitconstraint==2)   %Finishing Step for SIT
    options.shiftmap.algorithm  = 'sist'; % SIT Softly for slab scores and a0
    options.shiftmap.ncomp      = shiftmapncomp(i2);
    [~,~,~,xsit,~,model.sitmodel.a0{i2},model.sitmodel.t{i2}(model.sitmodel.include{3},:)] = ...
          shiftmap(reshape(model.loads{1}(x.include{1},i2),[m(1) m(3)]),options.shiftmap);
    model.loads{1}(x.include{1},i2) = xsit(:);

    if ~isempty(iexc1)
      [~,~,~,xsit,~,~,model.sitmodel.t{i2}(iexc3,:)] = ...
            shiftmap(reshape(model.loads{1}(iexc1,i2),[m(1) length(iexc3)]), ...
            model.sitmodel.p{i2},model.sitmodel.a0{i2},options.shiftmap);
      model.loads{1}(iexc1,i2)  = xsit(:);
    end
  end                                     %Finishing Step for SIT

  %% Model Stats and Details
  model.date            = date;
  model.time            = clock;
  model.detail.data{1}  = x;
  model.info            = {'Bilinear scores are in cell 1 of the loads field.';
                           'modl.sitmodel.include are the input(x) include fields'};

  model.detail.include{2}     = x.include{2};
  [model.detail.reslim{1,1}]  = residuallimit(rese,options.confidencelimit);
  uncap                 = norm(rese'*rese,"fro")/norm(z'*z,"fro"); %used for ssq
  rese                  = rese.^2;
  model.ssqresiduals{1,1}     = NaN(size(x,1),1);
  model.ssqresiduals{2,1}     = NaN(size(x,2),1);
  model.ssqresiduals{1,1}(x.include{1},:) = sum(rese,2);
  model.ssqresiduals{2,1}                 = sum(rese,1);
  rese                  = z-model.loads{1}(iexc1,:)*model.loads{2}';
  model.ssqresiduals{1,1}(iexc1,:) = sum(rese.^2,2);

  if length(model.detail.includ{1,1})>ncomp %(model.detail.includ{1,1}
    model.detail.tsqlim{1,1} = tsqlim(length(x.include{1}),ncomp,options.confidencelimit*100);
  else
    model.detail.tsqlim{1,1} = 0;
  end

  %calculate SSQ table SWAG % signal by factor
  for i1=1:size(model.loads{1},2)
    tmp                 = model.loads{1}(x.include{1},i1)*model.loads{2}(:,i1)';
    sig(i1)             = norm(tmp'*tmp,"fro");
  end
  sig                   = normaliz(sig,[],1);  %normalize to 100%
  if uncap>=1
    uncap = 0;
  end
  model.detail.ssq      = [(1:ncomp)' sig'*100 (1-uncap)*sig'*100 cumsum((1-uncap)*sig')*100];

  switch options.display
  case 'on'
    ssqtable(model)
  end
end %if predictmode

if ~isempty(waitbarhandle)
  close(waitbarhandle)
end

end %als_sit
