function [newu,newy,settings] = wrtpulse(u,y,n,delay)
%WRTPULSE Create input/output matrices for dynamic model identification.
%  This function rewrites vectors of system inputs and output so that
%  they may be used with PLS and other modeling routines to obtain
%  finite impulse response (FIR) and ARX models.
%  If the inputs (u and y) are DataSet objects then so are the outputs
%  (newu and newy).
%
%  If no inputs are provided or an empty data matrix is provided, WRTPULSE
%  will provide step-by-step loading of each input and the results will be
%  written to the workspace. These results will include a model structure
%  (settings) that can be used to reproduce the same decomposition on new
%  data if passed in as (u) or (n).
%
%  INPUTS:
%    u    = a M by N matrix of input vectors where the each input
%           is a column vector.
%    y    = the corresponding output vector.
%    n    = a 1 by N row vector with the number of coefficients to use for each input
%           [each element of (n) is the number of past periods to consider for
%           each input].
%   delay = a 1 by N row vector of containing the number of time units of delay
%           for each input.
%
%  OUTPUTS:
%    newu = a matrix of lagged input variables.
%    newy = the corresponding output vector.
%
%I/O: [newu,newy,settings] = wrtpulse(u,y,n,delay);
%I/O: [newu,newy] = wrtpulse(u,y,settings);
%I/O: [newu,newy,settings] = wrtpulse;       %interactive mode
%I/O: [newu,newy] = wrtpulse(settings);      %interactive mode w/default settings
%I/O: wrtpulse demo
%
%See also: AUTOCOR, CROSSCOR, FIR2SS, PLSPULSM

% Copyright Eigenvector Research, Inc. 1991
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified BMW 2/94

if nargin == 0; u = []; end
if ischar(u);
  options = [];
  if nargout==0; clear newu; evriio(mfilename,u,options); else; newu = evriio(mfilename,u,options); end
  return;
end

settings = [];
switch nargin
  case 0
    % ()
    u = [];
  case 1
    % (settings)
    if isstruct(u)
      settings = u;
      u = [];
    else
      error('When used with a single input, that input must be a settings structure for interactive analysis.');
    end
  case 2
    error('When u and y are supplied, a settings structure or n and delay must be supplied.');
  case 3
    % (u,y,settings)
    if isstruct(n)
      settings = n;
      n = settings.n;
      delay = settings.delay;
      settings = [];
    else
      error('When used with three inputs, the inputs must be u, y, and a settings structure.');
    end
  case 4
    % (u,y,n,delay)
    %do nothing
  otherwise
    error('Unrecognized input format');
end

if isempty(u)
  %Flag for using dialog boxes to enter data.
  autosave = (nargout == 0);
  [newu,newy,settings] = wrtpulsegui(settings,autosave);
  if nargout==0;
    clear newu
  end
  return
end

xdflag = 0; ydflag = 0;
if isa(u,'dataset')
  [mu,nu] = size(u.data);
  if mu ~= length(u.includ{1})
    error('Excluded Samples not allowed')
  end
  org_u = u;
  u = u.data(:,u.includ{2});
  xdflag = 1;
end
if isa(y,'dataset')
  org_y = y;
  y = y.data(:,y.includ{2});
  ydflag = 1;
end

[mu,nu] = size(u);
[my,ny] = size(y);
if length(n) ~= nu
  error('Past periods (n) must equal number of included columns of input (u) : %i',nu)
end
if numel(delay)>1 & length(delay)~=nu
  error('Delays (delay) must be a scalar or equal number of included columns of input (u) : %i',nu)
end
%  Check to see that matrices are of consistant dimensions
if nu > mu
  error('the input u is supposed to be colmn vectors')
end
if ny ~= 1
  error('the output y is supposed to be a colmn vector')
end
if mu ~= my
  error('There must be an equal number of points in the input and output vectors')
end
%  Find maximum number of terms for all inputs
a = max(n+delay);
if numel(delay)==1
  %expand into scalar
  delay = ones(1,nu).*delay;
end

%  Write out file using maximum number of terms
for i = 1:nu
  [temp,newy] = writein2(u(:,i),y,a);
  %   Delete proper number of columns according to delay and # of coeffs
  temp = temp(:,delay(:,i)+1:n(:,i)+delay(:,i));
  %  Construct total matrix from each input part
  if i == 1
    newu = temp;
  else
    newu = [newu temp];
  end
end
if xdflag == 1
  newu = dataset(newu);
  newu.name = [org_u.name ' shifted '];
  newu.author = org_u.author;
  newu.labelname{1} = org_u.labelname{1};
  newu.labelname{2} = org_u.labelname{2};
  newu.description = strvcat(org_u.description,'Set up for FIR Modelling');
  newu.title{1} = org_u.title{1};
  newu.title{2} = org_u.title{2};
  for i = 1:length(n);
    s = int2str([-delay(i):-1:-delay(i)-n(i)+1]');
    var = org_u.label{2}(org_u.includ{2}(i),:);
    lbl = [var(ones(size(s,1),1),:) s];
    if i == 1
      albl = lbl;
    else
      albl = strvcat(albl,lbl);
    end
  end
  newu.label{2}=albl;
end
if ydflag == 1
  newy = dataset(newy);
  newy.name = [org_y.name ' shifted '];
  newy.author = org_y.author;
  newy.labelname{1} = org_y.labelname{1};
  newy.labelname{2} = org_y.labelname{2};
  newy.description = strvcat(org_y.description,'Set up for FIR Modelling');
  newy.title{1} = org_y.title{1};
  newy.title{2} = org_y.title{2};
  newy.label{2} = org_y.label{2};
end

settings = getsettings(n,delay);

%---------------------------------------------------------
function [u2,y2] = writein2(u,y,n);
[m,n2] = size(u);
newm = m-n+1;
u2 = zeros(newm,n);
for i = 1:n
  u2(:,i) = u(n-i+1:m-i+1,:);
end
y2 = y(n:m,:);

%---------------------------------------------------------
function savetoworkspace(value,name)

vars = evalin('base','who');
newname = name;
index = 0;
while ismember(newname,vars)
  index = index+1;
  newname = sprintf('%s_%02i',name,index);
end

assignin('base',newname,value)

%---------------------------------------------------------
function settings = getsettings(n,delay)

settings = struct('modeltype','WRTPULSE','n',n,'delay',delay);

%---------------------------------------------------------
function [newu,newy,newsettings] = wrtpulsegui(settings,autosave)
newu = [];
newy = [];
newsettings = [];

%see if user passed in settings for n and delay (e.g. from previous run)
if isempty(settings)
  n = [];
  delay = [];
else
  n = settings.n;
  delay = settings.delay;
end

repeat = true;
while repeat
  %keep asking for valid data until we get some that works
  [u,uname] = lddlgpls({'double','dataset'},'Select Input Vector or Matrix (u)');
  if isempty(u);return;end
  [y,yname] = lddlgpls({'double','dataset'},'Select Process Output Vector (y)');
  if isempty(y);return;end
  
  if isdataset(u);
    nu = length(u.include{2});
  else
    nu = size(u,2);
  end
  prompt={sprintf('Enter number of past periods (n) to consider for each input (%i values required: 4,2,3... ):',nu),...
    sprintf('Enter delays (delay) corresponding to each input (%i values required: e.g. 4,2,3...):',nu)};
  name='Past Periods and Delay Inputs';
  numlines=1;
  options.Resize='on';
  options.WindowStyle='normal';
  
  answer=inputdlg(prompt,name,numlines,{num2str(n) num2str(delay)},options);
  if isempty(answer)
    return
  end
  n = str2num(answer{1});
  delay = str2num(answer{2});
  
  try
    [newu,newy] = wrtpulse(u,y,n,delay);
    repeat = false;
  catch
    erdlgpls(lasterr,'Lag Calculation Failed');
  end
  
end

newsettings = getsettings(n,delay);

if autosave
  %successful, save results
  evrimsgbox('Lag Calculation Successful. Saving variables...','Lag Successful','help','modal');
  savetoworkspace(newu,[uname '_lagged']);
  savetoworkspace(newy,[yname '_lagged']);
  
  if isempty(settings);
    %if settings were not passed in, write them to the workspace too
    savetoworkspace(newsettings,[uname '_lagged_settings']);
  end
end

