function [y_hat,D]= savgol(y,width,order,deriv,options)
%SAVGOL Savitzky-Golay smoothing and differentiation.
%  Inputs are the matrix of ROW vectors to be smoothed (y),
%  and the optional variables specifying the number of points in
%  filter (width), the order of the polynomial (order), and the
%  derivative (deriv).
%
%  The outputs are the matrix of smoothed and differentiated ROW
%  vectors (y_hat) and the matrix of coefficients (D) which can
%  be used to create a new smoothed/differentiated matrix,
%  i.e. y_hat = y*D.
%
%  If number of points, polynomial order and derivative are not
%  specified, they are set to 15, 2 and 0, respectively.
%
%  OPTIONAL INPUT:
%    options = structure with the following fields:
%     useexcluded: [{'true'} | 'false'] Governs how excluded data is handled
%                  by the algorithm. If 'true', excluded data is used when
%                  handling data on the edges of the excluded region (unusual
%                  excluded data may influence nearby non- excluded points).
%                  When 'false', excluded data is never used and edges of
%                  excluded regions are handled like edges of the spectrum
%                  (may introduce edge artifacts for some derivatives).
%           tails: ['traditional' | {'polyinterp'}, 'weighted'] Governs how
%                  edges of data and excluded regions are handled.
%                  'traditional' is an older approach and isn't recommended.
%                  'polyinterp' and 'weighted' provide smoother edge
%                  transitions.
%              wt: [ {''} | '1/d' | [1xwidth] ] allows for weighted least-
%                  squares when fitting the polynomials.
%                  '' (empty) provides usual (unweighted) least-squares.
%                  '1/d' weights by the inverse distance from the window
%                    center, or
%                  a 1 by width vector with values 0<wt<=1 allows for
%                    custom weighting.
%            mode: [ 1 | {2} ] Use rows or columns.
%
%Example: if (y) is a 5 by 100 matrix then savgol(y,11,3,1) gives a 
%  5 by 100 matrix of first-derivative row vectors resulting from an
%  11-point cubic Savitzky-Golay smooth of each row of (y).
%
%See: A. Savitzky, M.J.E. Golay, "Smoothing and Differentiation of Data by
%     Simplified Least Squares Procedures," Anal. Chem. 36(8), 1627-1639 (1964).
%
%I/O: [y_hat,D] = savgol(y,width,order,deriv,options);
%I/O: savgol demo
%
%See also: BASELINE, BASELINEW, DERESOLV, LINE_FILTER, MSCORR, POLYINTERP, SAVGOLCV, STDFIR, TESTROBUSTNESS, WLSBASELINE

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% Sijmen de Jong Unilever Research Laboratorium Vlaardingen Feb 1993
% Modified by Barry M. Wise 5/94
%         ***   Further modified, 1998-03, Martin Andersson
%         ***   Adjusting the calcn. of the bulk data.
%         ***   Based on calcn. of a sparse derivative matrix (D)
% JMS 10/07/02 -added basic dataset support
%   -added test for width too big
% JMS 12/02 -added "useexcluded" support (= don't use polyinterp w/excluded)
% JMS 1/20/03 -made "so few variables" a hard error
% JMS 3/2/04 -made "useexcluded" default as 'true'
% NBG 2/11/08 modified 'polyinterp' so that output D is correct
%             removed some extraneous code for option.tails = 'fast'
% NBG 5/11 added .weighted and .wt

if nargin == 0; y = 'io'; end
if ischar(y);
  options = [];
  options.useexcluded = 'true';
  options.tails = 'polyinterp';
  options.wt    = ''; %'1/d';
  options.mode  = 2;  %[ 1 | {2} ]run down the rows
  if nargout==0; clear y_hat; evriio(mfilename,y,options);
  else; y_hat = evriio(mfilename,y,options); end
  return;
end

if nargin<5;
  options = [];
end
options = reconopts(options,mfilename);

switch options.mode
case 2
  %do nothing
case 1
  y   = y';
otherwise
  %there should be an error here
end
[m,n] = size(y);

if n<6;
  error('Unable to operate on so few variables')
end

% set default values: 15-point quadratic smooth
if nargin<4
  deriv= 0;
end
if nargin<3
  order= 2;
end
if nargin<2
  width=min(15,floor(n/2));
end

% In case of input error(s) set to reasonable values
w = max( 3, width+1-mod(width,2) );
if w ~= width
  width = w;
end
w = min( width, floor(n/2)-1+mod(floor(n/2),2) );
o = min([max(0,round(order)),9,w-1]);
d = min(max(0,round(deriv)),o);

%Set weights.
if isempty(options.wt) | strcmpi(options.wt,'none');
  options.wt = '';
elseif strcmpi(options.wt,'1/d')
  p = (w-1)/2;
  options.wt = 1./([p:-1:1, 1, 1:p]);
elseif isa(options.wt,'double');
  if isvec(options.wt) & length(options.wt)==w
    if ~all(options.wt<=1)
      error('options.wt must all be 0<options.wt<=1')
    end
  else
    error('number of elements in options.wt must equal (width)')
  end
end

%convert non-double data to double (required for this function)
if isdataset(y)
  origclass = class(y.data);
  if ~isa(y.data,'double')
    y.data = double(y.data);
  end
else
  origclass = class(y);
  if ~isa(y,'double')
    y = double(y);
  end
end

if isa(y,'dataset') &  n~=length(y.includ{2}) & strcmpi(options.useexcluded,'false');
  %dataset with excluded variables, use polyinterp
  x          = 1:n;
  [y_hat,D]      = polyinterp(x,y,x,w,o,d);
  wasdataset = 0;   %don't try reinserting into dataset, polyinterp does it for us
else
    
  if isa(y,'dataset')
    %look for missing values, but ONLY those within "w/2" points of an
    %included point.
    [flag,missmap] = mdcheck(y);
    ismissing = find(any(missmap,1));
    if ~isempty(ismissing)
      nearest = interp1([-1e15 y.include{2} 1e15],[-1e15 y.include{2} 1e15],ismissing,'nearest');
      nearest = abs(nearest-ismissing);
      flag = any(nearest<=(w-1)/2);   %only missing values within a window's width of included values trigger use of polyinterp
    end
    
    %Store DSO for later
    wasdataset = 1;
    origy      = y;
    y          = y.data;
  else
    flag = mdcheck(y);  %if not a DSO, then any missing values trigger the polyinterp call
    wasdataset = 0;
  end
  
  if flag;
    %missing data? use polyinterp
    x     = 1:n;
    [y_hat,D] = polyinterp(x,y,x,w,o,d);
  else
    %fast case! do fast SavGol fit
    %------------------
    
    p = (w-1)/2;
    % Calculate design matrix and pseudo inverse
    x       = ((-p:p)'*ones(1,1+o)).^(ones(w,1)*(0:o));
    if isempty(options.wt)
      weights = x\eye(w);
    else
      weights = (diag(options.wt)*x)\diag(options.wt);
    end
    % Smoothing and derivative for bulk of the data
    coeff   = prod(1:d);
    D       = spdiags(ones(n,1)*weights(d+1,:)*coeff,p:-1:-p,n,n);
    
    % Smoothing and derivative for tails
    switch lower(options.tails)
    case {'fast' 'traditional'}
      coeff = prod(ones(d,1)*(1:o+1-d)+(0:d-1)'*ones(1,o+1-d,1),1); %old code
      w1    = diag(coeff)*weights(d+1:o+1,:);
      D(1:w,1:p+1)     = (x(1:p+1,1:1+o-d)*w1)';
      D(n-w+1:n,n-p:n) = (x(p+1:w,1:1+o-d)*w1)';
    case 'polyinterp'
      for i1=1:p
        wl = -(i1-1):p;
        s  = length(wl);
        x  = (wl'*ones(1,1+o)).^(ones(s,1)*(0:o));
        if isempty(options.wt)
          weights = x\eye(s);
        else
          weights = (diag(options.wt(end-s+1:end))*x)\diag(options.wt(end-s+1:end));
        end
        D(1:s,i1) = (weights(d+1,:)*coeff)';
        wl = -p:(i1-1);
        x  = (wl'*ones(1,1+o)).^(ones(s,1)*(0:o));
        if isempty(options.wt)
          weights = x\eye(s);
        else
          weights = (diag(options.wt(1:s))*x)\diag(options.wt(1:s));
        end
        D(end-s+1:end,end-i1+1) = (weights(d+1,:)*coeff)';
      end
    case 'weighted'
      if isempty(options.wt)
        options.wt = 1;  %allows for faster in-loop calculations (skip "if")
      end

      for i1=1:p
        wl  = (-p:p)+(p-i1+1);
        x   = (wl'*ones(1,1+o)).^(ones(w,1)*(0:o));
        wt  = ones(1,w);
        wt(p+i1:w) = 1./(1:p-i1+2);
        wt         = wt.*options.wt;   
        weights   = (diag(wt)*x)\diag(wt);
        D(1:w,i1) = (weights(d+1,:)*coeff)';
        wl  = (-p:p)+i1-p-1;
        x   = (wl'*ones(1,1+o)).^(ones(w,1)*(0:o));
        wt  = ones(1,w);
        wt(1:p-i1+2) = fliplr(1./(1:p-i1+2));
        wt           = wt.*options.wt;
        weights      = (diag(wt)*x)\diag(wt);
        D(end-w+1:end,end-i1+1) = (weights(d+1,:)*coeff)';
      end
      
%      temp = D*0;
%      temp(origy.include{2},:) = D(origy.include{2},:);
%      D    = temp;

    end
    
    % Operate on y using the filtering/derivative matrix, D
    y_hat=y*D;
    
  end
end

if ~strcmp(origclass,'double')
  %re-cast back as original class if not "double"
  y_hat = feval(origclass,y_hat);
end

if wasdataset       %replace modified data back into original dataset and return
  origy.data = y_hat;
  y_hat      = origy;
end

switch options.mode
case 2
  %do nothing
case 1
  y_hat = y_hat';
end
