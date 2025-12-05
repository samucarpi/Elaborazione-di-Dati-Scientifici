function [prex,prepar] = npreprocess(x,settings,oldval,undo,options);
%NPREPROCESS Preprocessing of multi-way arrays.
%  NPREPROCESS is used for three different purposes:
%  1) for centering and scaling multi-way arrays in which case the parameters
%      (offsets and scales) are first calculated and then applied to the data,
%  2) for preprocessing another data set according to (1), and
%  3) for transforming preprocessed data back (undo preprocessing).
%
%  INPUTS:
%          x = data array, and
%   settings = a two-row matrix (class "double") indicating  which modes 
%              to center and scale. The matrix is: settings = [cent; scal]. E.g.
%        settings(1,:) = [1 0 1] => center across mode one and three, and
%        settings(2,:) = [1 1 0] => scale to unit (mean square/variance) within mode one and two.
% 
%  OPTIONAL INPUTS:
%     prepar = contains earlier defined mean and scale parameters,
%              this data is required for applying or undoing preprocessing,
%       undo = when set to 1 this flag tells to undo/transform back, and
%    options = a structure array with the following fields:
%          name: 'options', identifies the structure as an options structure,
%       display: [ {'on'} | 'off' ], governs level of display,
%      iterproc: [ 'on' | {'off'} ],
%    scalefirst: [ {'on'} | 'off' ], and
%        usemse: Defines how to scale, 0: standard deviation, {1}: by root
%                mean square, 2: Square root of mean (similar to pareto).
%                In multi-way analysis, scaling by mean squares is usually
%                preferred to standard deviation.s
%
%  OUTPUTS:
%       prex = the preprocessed data, and
%     prepar = a structure containing the necessary parameters to pre-
%              and post-process other arrays.
%
%Example: To apply preprocessing with options
%     [prex,prepar] = npreprocess(x,settings,[],0,options); 
%
%I/O: [prex,prepar] = npreprocess(x,settings);             % Center and scale data w/ required inputs
%I/O: [prex,prepar] = npreprocess(x,prepar,undo,options);  % Center and scale with options
%I/O: prex = npreprocess(x,prepar);                        % Preprocess new data according to above
%I/O: prex = npreprocess(x,prepar,1);                      % Undo preprocessing
%I/O: npreprocess demo
%I/O: myoptions = npreprocess('options');                  % Generate default options
%
%See also: AUTO, MNCN, POLYTRANSFORM, PREPROCESS, RESCALE, SCALE

%Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rb February, 2001
%rb November, 2001, changed I/O and help completely
%rb, Dec, 2001, DSO-enabled
%rb, Aug, 2002, evriio-enabled
%rb, Aug, 2003, fixed error in scale of RSM scaling (taking the mean)
%               Changed so the even though only the first modes are
%               defined, the latter will be defined (no cent, no scale)
%               automatically. Likewise, having too many modes will 
%               just ignore the later ones. These changes are useful when
%               defining preprocessing e.g. in GUIs where the order of the
%               array might not be known
%rb, Aug, 2003, Changed I/O so that settings are not needed in apply and
%               undo mode (as it is given in prepar). Old notation still
%               works.
%rb, Oct, 2003, Changed convergence criterion
%rb, Jun, 2004, Fixed error in apply mode
%rb, Jun, 2004, Fixed error in estimate of mean when only missing elements in one column
%rb, Feb, 2005, Speeded up calculation of means for large arrays
%rb, Jan, 2008, Added a warning for inconsistent use of scale/centering

% TODO
% Build in verbal output that states whether convergence in terms of
% centeredness and scaling was achieved

% Generate standard options
standardoptions = struct('name','options','display','on','iterproc','off','scalefirst','on','usemse','on');

if nargin == 0; 
  x = 'io'; 
end

if ischar(x)
    options = standardoptions;
    if nargout==0; 
      clear varargout; 
      evriio(mfilename,x,options); 
    else; 
      prex = evriio(mfilename,x,options); 
    end
    return; 
end

if isdataset(x)% Then it's a SDO
  Xsdo = x;
  inc=x.includ;            
  x = x.data(inc{:});
end


if isstr(x) 
  if nargout == 0      
    switch lower(x)
      case {'oldval','undo','options','prepar','background'}
        helptext(x);
        return
      case 'demo'
        error(' No demo is currently available for NPREPROCESS')
        return
    end
  end
end


IterConvCrit = 1e-8;
IterMax = 20;
optdefinedelsewhere = 0;


% Accommodate if settings are left out (e.g. during apply) so that prepar
% will be the second input rather than the third.
numberofinputs = nargin;
settingsaregiven=0;
if nargin==2
  undo = 0;
end
if nargin==3&~isstruct(settings)
  if isstruct(oldval)
    undo=0;
  end
end
if isstruct(settings) % Then shift everything to the 'right'
  settingsaregiven=1;
  if nargin==4
    numberofinputs = numberofinputs +1;
    options = undo;
    undo    = oldval;
    oldval  = settings;
    settings = oldval.settings;
    optdefinedelsewhere = 1;
  elseif nargin==3
    undo    = oldval;
    oldval  = settings;
    settings = oldval.settings;
  elseif nargin==2   % npreprocess(x,prepar);
    oldval  = settings;
    settings = oldval.settings;
    options = oldval.options;
    optdefinedelsewhere = 1;
  end
end

% To handle options when IO is [prex,prepar] = npreprocess(x,[m;s],opt);
if nargin>2 & isstruct(oldval) % Options are provided in the third input
  if ~isfield(oldval,'options')
    options = oldval;
    oldval=[];
    optdefinedelsewhere = 1;
  end
end

% TO handle options when I/0 is [prex,prepar] = npreprocess(x,[m;s],0,opt);
if nargin>3 & isstruct(undo) % Options are provided in the third input
  if ~isfield(undo,'options')
    options = undo;
    undo=0;
    optdefinedelsewhere = 1;
  end
end


if numberofinputs<5 & ~optdefinedelsewhere % options not given
  screen = 1;
  iterproc = 'off';
  scalefirst = 'on';
  usemse = 'on';
else
  if isfield(options,'iterproc')
    iterproc = options.iterproc;
  else
    iterproc = standardoptions.iterproc;
  end
  if isfield(options,'scalefirst')
    scalefirst = options.scalefirst;
  else
    scalefirst = standardoptions.scalefirst;
  end
  if isfield(options,'display')
    screen = options.display;
  else
    screen = standardoptions.displayf;
  end
  if isfield(options,'usemse')
    usemse = options.usemse;
  else
    usemse = standardoptions.usemse;
  end
end
options = struct('display',screen,'iterproc',iterproc,'scalefirst',scalefirst,'usemse',usemse);


if strcmp(lower(iterproc),'on') & screen(1)==1
  screen = 2; % If iterative it is appropriate to skip some of the text
end

% if nargin<4
%   undo=0;
% end
% if undo==1
%   undo = -1;
% elseif undo ==0
%   undo = 1;
if undo==1
  undo = -1;
else
  undo = 1;
% else
%   error('NPREPROCESS requires input undo to be either 0 (ordinary centering/scaling) or 1 (undo preproc). Type <help npreprocess>')
end


% Chk input
mwasize = size(x);
order = length(mwasize);
if nargin<2
  error(' NPREPROCESS requires at least 2 inputs')
else
  centmode = settings(1,:);
  if size(settings,1)==2
    scalmode = settings(2,:);
  else
    scalmode = zeros(size(centmode));
    warning('EVRI:NpreproScalingDefault','Scaling not set, will default to no scaling. Check that you have two rows - one for centering and one for scaling')
  end
end


% Adjust settings to the order to allow 'incorrect' number of modes without
% crashing
if length(centmode)>order
  centmode = centmode(1:order);
elseif length(centmode)<order
  centmode = [centmode zeros(1,order-length(centmode))];
end
if length(scalmode)>order
  scalmode = scalmode(1:order);
elseif length(scalmode)<order
  scalmode = [scalmode zeros(1,order-length(scalmode))];
end  
  
% if length(centmode)~=order|length(scalmode)~=order
%   error(' NPREPROCESS requires the (two) rows in settings to have same length as the number of modes. Type <help npreprocess>')
% end

if nargin<3&~settingsaregiven
  oldval = [];
end

% Check if parameters must be estimated or are already given 
% (and given consistently)
FindParam = 1;
if nargin<3
  if settingsaregiven
    FindParam = 0;
  else
    FindParam = 1;
  end
elseif isstruct(oldval)
  %  try
  %     if iscell(oldval.means)
  %       mx = oldval.means{1};
  %     else
  %       mx = oldval.means;
  %     end
  %     if iscell(oldval.scales)
  %       scx = oldval.scales{1};
  %     else
  %       scx = oldval.scales;
  %     end
  mx = oldval.means;  
  if iscell(mx{1})
    mx = mx{1};
  end
  scx = oldval.scales;
  if iscell(scx{1})
    scx = scx{1};
  end
  
  for i = 1:order
    if length(length(mx{i}))>0&length(mx{i})==prod(mwasize)/mwasize(i);
      if centmode(i)==0
        error([' Offset in mode ',num2str(i),' given but settings not appropriate'])
      else
        FindParam = 0;
        if strcmp(lower(screen),'on')|any(screen(1)==[1:2])
          disp([' Offset in mode ',num2str(i),' given']),
        end
      end
    end
    if length(scx{i})==mwasize(i);
      if scalmode(i)==0
        error([' scales in mode ',num2str(i),' given but settings not appropriate'])
      else
        FindParam = 0;
        if strcmp(lower(screen),'on')|any(screen(1)==[1:2])
          disp([' Scales in mode ',num2str(i),' given']),
        end
      end
    end
  end   
%   catch
%     FindParam = 1;
%   end
end


% Check for missing
if any(isinf(x(:)))
  i = find(isinf(x));
  x(i)=NaN;
end
Miss = 0;
MissId = 0;
if any(~isfinite(x(:)))
  MissId = ~isfinite(x);
  Miss = 1;
end

if strcmp(lower(screen),'on')|any(screen(1)==[1:2])
  disp(' ')
  if strcmp(lower(iterproc),'on')|iterproc(1)==1
    disp(' Iterative processing')
  else
    disp(' Non-iterative processing')
  end
  if FindParam
    disp(' Appropriate scale and mean parameters will be determined')
  end
  if undo == -1
    disp(' Data will be postprocessed with given parameters')
  end
  if (strcmp(lower(usemse),'on')|usemse(1)==1) & any(scalmode)
    disp(' Root mean square scaling used for scaling')
  elseif (strcmp(lower(usemse),'std')|strcmp(lower(usemse),'off')|usemse(1)==0) & any(scalmode)
    disp(' Standard deviation used for scaling')
  elseif (strcmp(lower(usemse),'sqrt')|usemse(1)==2) & any(scalmode)
    disp(' Square root mean scale used for scaling')
  end
  if Miss
    disp(' Missing data will be handled')
  else
    disp(' No missing data')
  end
  disp(' ')
end

% If offset and scale is not to be found (isstruct(oldval)) then x should
% be changed if it was a DSO. Then samples that are not included should
% also be preprocessed
if exist('Xsdo')==1  %Then it's a SDO
    x = Xsdo;
    Xsdo = x;
    inc=x.includ;
    inc{1}=1:size(x,1);
    x = x.data(inc{:});
end


%%%%%%  FIND OFFSET AND SCALE PARAMETERS AND PREPROCESS%%%%%%%
if ~isstruct(oldval)
  DoIt = 1;
  Iter = 0;
  while DoIt
    
    % Find error for convergence-check if iterative
    if strcmp(lower(iterproc),'on')|iterproc(1)==1
      Iter = Iter + 1;
      x_old = x;
    end
    
    if FindParam
      mx = cell(1,order);
      scx = cell(1,order);
      if strcmp(lower(scalefirst),'on')|scalefirst(1)==1
        [x,scx] = findscales(x,scalmode,mwasize,order,usemse,scx,undo,screen);
      end
      [x,mx] = findmeans(x,centmode,mwasize,order,mx,undo,screen);
      if strcmp(lower(scalefirst),'off')|scalefirst(1)==0
        [x,scx] = findscales(x,scalmode,mwasize,order,usemse,scx,undo,screen);
      end
    end
    
    if strcmp(lower(iterproc),'on')|iterproc(1)==1 % Repeat
      
      % Save each set of paramters
      MX{Iter} = mx;
      SX{Iter} = scx;
      
      % Find error for convergence check if iterative
      if strcmp(lower(iterproc),'on')|iterproc(1)==1
        if Miss
          ssx = sum((x_old(MissId)-x(MissId)).^2);
          ssx_old= sum(x_old(MissId).^2);
        else
          ssx = sum((x(:)-x_old(:)).^2);
          ssx_old= sum(x_old(:).^2);
        end
      end
      if (ssx/ssx_old)<IterConvCrit|Iter >= IterMax
        DoIt = 0;
      end
    else
      DoIt = 0; % Stop iterating
    end
    if DoIt== 0 & screen
      if Iter==IterMax
        disp([' Iterative preprocessing did not converge completely in ',num2str(IterMax),' iterations'])
        if IterMax>15 & ~Miss
          disp(' Possibly, convergence cannot be expected even by allowing more iterations')
        end
      else
        if (strcmp(lower(screen),'on')|any(screen(1)==[1:2]))|(length(iterproc)==1&iterproc(1)==1)
          disp([' Iterative preprocessing converged (',num2str(Iter),' it.)'])
        elseif strcmp(lower(screen),'on')|any(screen(1)==[1:2])
          disp([' Preprocessing performed'])
        end
      end
    end
  end   
  
  % Output
  prex = x;
  if strcmp(lower(iterproc),'on')|iterproc(1)==1
    prepar.means = MX;
    prepar.scales = SX;
  else
    prepar.means = mx;
    prepar.scales = scx;
  end
  if strcmp(lower(scalefirst),'on')|scalefirst(1)==1
    prepar.order = 'Scale first';
  else
    prepar.order = 'Center first';
  end
  prepar.settings = settings;
  prepar.options = options;
  
  
  %%%%%%  PREPROCESS WITH GIVEN OFFSET AND SCALE PARAMETERS %%%%%%%
  
elseif isstruct(oldval) & undo == 1
  
  if strcmp(lower(oldval.options.iterproc),'on')|oldval.options.iterproc(1)==1
    iterproc = 1;
  else
    iterproc = 0;
  end
  
  if ~iterproc
    NumberOfIter = 1;
  else
    NumberOfIter  = length(oldval.means);
  end
  
  for i = 1:NumberOfIter
    if ~iterproc
      means = oldval.means;
      scales = oldval.scales;
    else
      means = oldval.means{i};
      scales = oldval.scales{i};
    end
    
    if strcmp(lower(scalefirst),'on')|scalefirst(1)==1
      for j = 1:order
        if ~isempty(scales{j});
          x = scalex(x,scales{j},j,mwasize,order,undo,screen);
        end
      end
    end
    for j = 1:order
      if ~isempty(means{j})
        x = centerx(x,means{j},j,mwasize,order,undo,screen);
      end
    end
    if strcmp(lower(scalefirst),'off')|scalefirst(1)==0 % scale last
      for j = 1:order
        if ~isempty(scales{j});
          x = scalex(x,scales{j},j,mwasize,order,undo,screen);
        end
      end
    end
  end
  % Output
  prex = x;   
  prepar = oldval;
  
  %%%%%%  PREPROCESS WITH GIVEN OFFSET AND SCALE PARAMETERS %%%%%%%
  
  
elseif isstruct(oldval) & undo == -1   
  if strcmp(lower(oldval.options.iterproc),'on')|oldval.options.iterproc(1)==1
    iterproc = 1;
  else
    iterproc = 0;
  end
  
  if ~iterproc
    NumberOfIter = 1;
  else
    NumberOfIter  = length(oldval.means);
  end
  
  for i = NumberOfIter:-1:1  % Go backwards
    if ~iterproc
      means = oldval.means;
      scales = oldval.scales;
    else
      means = oldval.means{i};
      scales = oldval.scales{i};
    end
    
    if strcmp(lower(scalefirst),'off')|scalefirst(1)==0 % Back-scale first if scaling was performed first
      for j = order:-1:1
        if ~isempty(scales{j});
          x = scalex(x,scales{j},j,mwasize,order,undo,screen);
        end
      end
    end
    
    for j = order:-1:1
      if ~isempty(means{j})
        x = centerx(x,means{j},j,mwasize,order,undo,screen);
      end
    end
    if strcmp(lower(scalefirst),'on')|scalefirst(1)==1 % scale last otherwise
      for j = order:-1:1
        if ~isempty(scales{j});
          x = scalex(x,scales{j},j,mwasize,order,undo,screen);
        end
      end
    end
  end
  % Output
  prex = x;   
  prepar = oldval;
  
  
else
  error(' Unexpected error. Please try to reproduce the error and forward description to rb@kvl.dk')
end

if exist('Xsdo')==1  %Then it's a SDO
  Xsdo.data(inc{:}) = prex;
  prex = Xsdo;
end


%%%%%%%%%%  END OF MAIN PROGRAM %%%%%%%%%%%%%%

function [x,scx] = findscales(x,scalmode,mwasize,order,usemse,scx,undo,screen)

for i = 1:length(mwasize);
  if scalmode(i)
    X = permute(x,[i 1:i-1 i+1:order]);
    if strcmp(lower(usemse),'on')|usemse(1)==1  %MSE
      try
        s = [];
        for j = 1:size(X,1)
          s = [s sum(X(j,isfinite(X(j,:))).^2)];
        end
      catch
        s = sum(X(:,:)'.^2);
      end
      %s = s/size(X,1);
      s = s/length(X(j,:));
      s = sqrt(s);
    elseif strcmp(lower(usemse),'std')|strcmp(lower(usemse),'off')|usemse(1)==0  % STD
      try
        s = [];
        for j = 1:size(X,1)
          s = [s std(X(j,isfinite(X(j,:)))')];
        end
      catch
          s = std(X(:,:)');
      end
    elseif strcmp(lower(usemse),'sqrt')|usemse(1)==2  % STD
        try
            s = [];
            for j = 1:size(X,1)
                xt=X(j,isfinite(X(j,:)))';
                out = sqrt(abs(mean(xt)));
                s = [s out];
            end
      catch
        s = std(X(:,:)');
        end
    end
    scx{i} = s;
    x = scalex(x,s,i,mwasize,order,undo,screen);
  end
end


function [x,mx] = findmeans(x,centmode,mwasize,order,mx,undo,screen)

for i = 1:length(mwasize);
  if centmode(i)
    X = permute(x,[i 1:i-1 i+1:order]);
    m = mean(X(:,:));
    if any(isnan(m(:)))|any(isinf(m(:)))
      m = repmat(0,1,prod(mwasize)/mwasize(i));
      for j = 1:prod(mwasize)/mwasize(i)
        try
          xx = X(isfinite(X(:,j)),j);
          if length(xx)>0
            m(j) = mean(xx);
          end
        catch
          m(j) = 0;
        end
      end
    end
    x = centerx(x,m,i,mwasize,order,undo,screen);
    if min(size(m))>1
      m = reshape(m,mwasize([1:i-1 i+1:end]));
    end
    mx{i} = m;
  end
end

function prex = scalex(x,scales,mode,mwasize,order,undo,screen);
if strcmp(lower(screen),'on')|any(screen(1)==[1:2]) ,
  disp([' Scaling mode ',num2str(mode)]),
end
X = permute(x,[mode 1:mode-1 mode+1:order]);
for i = 1:size(X,1)
  X(i,:) = X(i,:)*scales(i)^(-undo);
end
prex = ipermute(X,[mode 1:mode-1 mode+1:order]);


function prex = centerx(x,means,mode,mwasize,order,undo,screen);
if strcmp(lower(screen),'on')|any(screen(1)==[1:2]) ,
  disp([' Centering mode ',num2str(mode)]),
end
X = permute(x,[mode 1:mode-1 mode+1:order]);
means = means(:);
for i = 1:prod(mwasize)/mwasize(mode)
  X(:,i) = X(:,i)-undo*means(i);
end
prex = ipermute(X,[mode 1:mode-1 mode+1:order]);









function helpstr = helptext(in);

helpstr = { ...
    'oldval',[' DEFINITON oldval',sprintf('\n'),... 
      ' ',sprintf('\n'),...
      'The input oldval is used for inputting the old values used for centering and scaling ',sprintf('\n'),...
      'new data according to an old preprocessing. This, oldval holds the offsets and scales.',sprintf('\n'),...
      'The structure is ',sprintf('\n'),...
      ' ',sprintf('\n'),...
      '    oldval.means   - old mean-values',sprintf('\n'),...
      '    oldval.scales  - old scale-values',sprintf('\n'),...
      ' ',sprintf('\n'),...
      'It is also possible to simply input the second output prepar which is holding these',sprintf('\n'),...
      'parameters. This is advised because additional settings of the preprocessing are ',sprintf('\n'),...
      'then also followed.'];...
    'undo',[' DEFINITION undo',sprintf('\n'),... 
      ' ',sprintf('\n'),...
      'The input undo is used for the situation where you want to bring back preprocessed',sprintf('\n'),... 
      'data to the original domain. E.g. add the mean-values that were subtracted or scale',sprintf('\n'),... 
      'a predicted value back to the raw data domain.',sprintf('\n'),... 
      ' ',sprintf('\n'),... 
      ' if undo = 0 normal preprocessing is performed (default)',sprintf('\n'),...
      ' if undo = 1 inverse (post-)processing is performed. This scales preprocessed data ',sprintf('\n'),...
      '             back to original domain'];...
    'options',[' DEFINITION options',sprintf('\n'),... 
      ' ',sprintf('\n'),...
      'The input options defines a number of extra features',sprintf('\n'),...
      'options is a structure with the following fields:',sprintf('\n'),...
      ' ',sprintf('\n'),...
      '       screen : Default 1. Show intermediate output on screen. If 0 no output',sprintf('\n'),...
      '     iterproc : Default 0. If 1 => Iterative preprocessing used',sprintf('\n'),...
      '   scalefirst : Default 1. If set to 1 => Scale, then center, if 2 => Center, then scale',sprintf('\n'),...
      '       usemse : Default 1. If 1 => Use RMSE for scaling, if 0 => use standard deviation for scaling',sprintf('\n'),...
      ' ',sprintf('\n'),...
      ' You can generate a default set of options by typing',sprintf('\n'),...
      ' ',sprintf('\n'),...
      ' myoptions = npreprocess(''options'');'];...
    'prepar',[' DEFINITION prepar',sprintf('\n'),... 
      ' ',sprintf('\n'),...
      'Structure containing the necessary parameters to pre and post-process other arrays.',sprintf('\n'),... 
      ' ',sprintf('\n'),... 
      '      means : Cell vector holding the mean-values for i''th mode in i''th cell',sprintf('\n'),... 
      '              (in case of iterative preprocessing, a cell of several such is given)',sprintf('\n'),...
      '     scales : Cell vector holding the scale-values for i''th mode in i''th cell',sprintf('\n'),... 
      '              (in case of iterative preprocessing, a cell of several such is given)',sprintf('\n'),... 
      '      order : String defining the order of scaling and centering',sprintf('\n'),... 
      ' definition : Structure holding the used settings'];...
    'background',[' BACKGROUND FOR NPREPROCESS',sprintf('\n'),... 
      ' ',sprintf('\n'),...
      'For convenience this m-file does not use iterative preprocessing, ',sprintf('\n'),...
      'which is necessary for some combinations of scaling and centering',sprintf('\n'),...
      'to converge. Instead, the algorithm first standardizes the modes ',sprintf('\n'),...
      'successively and afterwards centers. The prior standardization ',sprintf('\n'),...
      'ensures that the individual variables are on similar scale ',sprintf('\n'),...
      '(this might be slightly disturbed upon centering - unlike ',sprintf('\n'),...
      'for two-way data). The default scaling is by RMS (root mean ',sprintf('\n'),...
      'squares) rather than STD (standard deviations). This is ',sprintf('\n'),...
      'appropriate for multi-way data where it leads to more desirable ',sprintf('\n'),...
      'properties of the preprocessed array. STD can be forced in the  ',sprintf('\n'),...
      'options input. Missing data are handled if set to NaN or Inf, ',sprintf('\n'),...
      'but note that preprocessing is not optimal when there are ',sprintf('\n'),...
      'missing data. Rather, the centering and scaling should be ',sprintf('\n'),...
      'performed as part of the modeling.']};

helpwin(helpstr,in,'NPREPROCESS help');



