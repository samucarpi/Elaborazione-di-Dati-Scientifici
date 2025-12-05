function out = anovadoe( x , y , column_ID, options)
%ANOVADOE Function to perform ANOVA for 2^k factorial model X, Y data.
%   Performs ANOVA for the model described by the submitted X data relative
%   to the Y data.  Each column of X is design in a specific way to allow
%   the calculation of an effect due to the specific main effect or
%   interaction used to design each specific column.
%
%   The main output is a statistical test of the significance of each term (eg.,
%   column) of the X matrix, a test of the overall model, and a test for
%   lack-of-fit.  There are additional statistical values supplied that
%   support the above test metrics that might be used to construct a
%   typical ANOVA table if desired.
%
%   In addition, the coefficients for each level in each factor and each
%   interaction term level are reported.
%   The ANOVA decomposition is also returned as columns (univariate y) or
%   matrices (multivariate y)
%
%   If the y input is a matrix, no statistical testing is done, but only
%   coefficients are calculated for each column of Y.
%
% INPUTS:
%   x         = matrix describing the settings of each X variable (cols)
%               for each sample (row). Typically this would be a 2^k DOE
%               design matrix. The origin/identity of each column is
%               described in the 'column_ID' var.
%   y         = the experimental Y value determined for each experiment/row
%               of X. See outputs regarding behvior when y is a matrix.
%
% OPTIONAL INPUTS:
%   column_ID = a cell array of numerical values which describes the
%               multiplicative origin of each column of X. If x is a
%               DOE dataset object, this input can be omitted (the
%               information will be included in the dataset object)
%               If omitted, each column of X is assumed to be a unique
%               (non-interation) factor.
%      *   The number of columns in x must = number of cells in column_ID.
%      **  If an intercept is to be explicitly included as a column of
%          'ones' in the x matrix (as in a regression), then that column
%          must be represented as a '0' in column_ID.  A DOE design does
%          not typically have an explicit intercept.
%      *** Further, the numbers in column_ID must be in increasing order by
%          single digits, 2 digits, 3 digits, etc.  (and obviously must
%          match the x  matrix).
%      Examples: 
%         column_ID = {[1] [2] [1 2]};  
%       Indicates how columns were derived. Multiple numbers indicate
%       interaction and which original columns were used to calculate
%       design vars.  Here, 1 and 2 are independent columns, but column 3
%       is a dependent column derived from the product of 1 and 2.  Column
%       3 will be used to calculate the interaction of factors 1 and 2.
%       The term [1 2] must appear after the term [1].  Further, a term [1
%       2 3] must appear after a term [1 2], which must likewise appear
%       after a term [1].
%         column_ID = {[1] [2] [1 2] [1 3] [2 3] [1 2 3]};
%
%       If you include an interaction term e.g. [1 2 3] in a model, all
%       subterms encompassed by the highest order term must also be
%       included. So subterms [1] [2] [1 2] [1 3] [2 3] all be included.
%
%   options  = Options structure with one or more of the following fields.
%              Options can be passed in place of column_ID.
%
%          display : [{'off'}| 'on' ] governs output to the command window.
%   nocenterpoints : [ 'off' |{'on'}] governs automatic filtering of center
%                     points. If a design contains additional added center
%                     points, these are typically removed before
%                     calculating the factor effects. However, some other
%                     packages do not do this filtering and the only way to
%                     match their results is to disable the filtering by
%                     setting this option to 'off'. Note that filtering can
%                     only be done if the input x is a DOE DataSet object.
%
% OUTPUTS:
%   out = a structure containing the sum of squares, mean square values,
%         F-test values, F-critical values, and p-values for each
%         column/treatment, for the model as a whole, for overall residual
%         error, and for lack-of-fit and pure error (if replication was
%         present). The ASCA-related coefficients for each factor and 
%         interaction term are reported in coeffs sub-field. 
%         The ANOVA decomposition columns or matrices are returned in the 
%         decomp sub-field. coeffs and decomp are used in ASCA function.
%         NOTE: if y input is a matrix, only the coefficients for each
%         factor are reported. No additional tests are performed.
%
%I/O: out = anovadoe(x, y);
%I/O: out = anovadoe(x, y, column_ID, options);
%I/O: out = anovadoe(x, y, options);
%
%See also: ANOVA1W, ANOVA2W

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%TODO: add function I/O error trapping
if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  options.display = 'off';
  options.nocenterpoints = 'on';
  if nargout==0; evriio(mfilename,x,options); else; out = evriio(mfilename,x,options); end
  return; 
end

if nargin<2
end
switch nargin
  case 1
    error('Inputs x, y are required')
  case 2
    %  (x,y)
    options = [];
    column_ID = [];
  case 3
    %  (x,y,column_ID)
    %  (x,y,options)
    if isstruct(column_ID)
      %user passed options as column_ID
      options = column_ID;
      column_ID = [];
    else
      options = [];
    end      
  case 4
    % (x,y,column_ID,options)
end
options = reconopts(options,mfilename);

%check for DataSet object
if ~isdataset(x) & ~isdataset(y)
  x = doescale(x);
  originaldso  = struct('label',{{[];[]}},'include',{{1:size(x,1) 1:size(x,2)}},'name','','userdata',[]);
  originalydso = struct('label',{{[];[]}},'include',{{1:size(y,1) 1:size(y,2)}},'name','','userdata',[]);

else
  if ~isdataset(x)
    x = dataset(x);
  end
  if ~isdataset(y)
    y = dataset(y);
  end
  
  if length(x.include{1})~=length(y.include{1}) | any(x.include{1}~=y.include{1})
    %include fields do not match, do intersection
    incl = intersect(x.include{1},y.include{1});
    x.include{1} = incl;
    y.include{1} = incl;
    if strcmpi(options.display,'on')
      disp('Included samples in x and y did not match, using intersection.')
    end
  end
  
  originaldso = x;
  originalydso = y;
  
  %extract data from x and y for initial calculation.
  x.data = doescale(x.data);
  x = x.data.include;
  y = y.data.include;
end

%make sure there are column labels
if isempty(originaldso.label{2})
  originaldso.label{2} = [repmat('Factor ',size(x,2),1) char('0'+(1:size(x,2)))'];
end

%===Factor (X-Column) Sum of Squares & DoF===========

num_cols = size(x,2);

ssq_treat    = zeros(1,num_cols);
dof_treat    = zeros(1,num_cols);

if isempty(column_ID)
  %user passed empty OR didn't pass it at all...
  if isfieldcheck(originaldso.userdata,'userdata.DOE.col_ID')
    column_ID = originaldso.userdata.DOE.col_ID(originaldso.include{2});
  else
    column_ID = num2cell(1:num_cols,1);
  end
end
if length(column_ID)~=num_cols
  error('Columns of x must correspond exactly to length of column_ID')
end

%get order of all column_IDs
col_coef_order = cellfun('length',column_ID)';

%error check for col_coef_order monotonically increasing
if any(diff(col_coef_order)<0)
  error('Interactions must be sorted in increasing order [1] before [1 2], etc')
end
if any(col_coef_order>4)
  error('Interactions greater than 4-factor are not supported')
end

%look for zero-order (intercept) terms (must do this AFTER the "increasing
%order" test above since the zero-order term will look like a problem
%otherwise)
%is col made of main effects or 2way or 3way interaction, or intercept?...note
%column_ID array must be serially increasing....[1] before [1 3] before
%[1 2 3]... x columns must be ordered as they are in column_ID
oneway_ind = find(col_coef_order==1);  %local all one-way entries
oneway     = [column_ID{oneway_ind}];  %get the values therein
zero_order = oneway_ind(oneway==0);    %locate any "zeros" in the one-way entries
if ~isempty(zero_order);
  col_coef_order(zero_order) = 0;      %re-assign the corresponding order as zero
end

%set aside original x and y for later
x_orig = x;
y_orig = y;

%Filter center point runs out of x and y matrix
%Center point runs in 2^k factorials are only used for residual error calc
%and/or testing for quadratic curvature...they aren't used in the calculation
%of effects
if strcmpi(options.nocenterpoints,'on') & isfieldcheck(originaldso.userdata,'userdata.DOE.options.centerpoints')
  cp = originaldso.userdata.DOE.options.centerpoints;
  rows  = find(all((x==0),2));
  if ~isempty(rows) & cp>0
    rows = rows(1:min(end,cp));% only remove as many as were specified in "centerpoints" option
    x(rows,:) = [];
    y(rows,:)   = [];
  end
end

ny = size(y,2);
if ny==1
  mysq = (sum(y)^2)/size(x,1);
  
  for i = 1:num_cols
    % for the purposes of ANOVA model significance evaluation
    % which tests whether terms account for variance ABOUT the avgY value,
    % an intercept column is assigned the SSq value of the avgY^2
    %...the intercept is directly related to the avgY values by
    % b0 = avgY - b1*avgX
    
    if col_coef_order(i)==1    %main effects===============
      [b,z,j] = unique(x(:,i));
      for ii = 1:max(j)
        t = y(j==ii);
        num_reps = length(t);
        t = (sum(t)^2)/num_reps;
        ssq_treat(i) = ssq_treat(i) + t; %this is formal summation step in textbook formula
      end
      
    elseif col_coef_order(i)==2  %2-way interactions==============
      [b,z,j] = unique(x(:,column_ID{i}),'rows');
      
      for iii = 1:max(j)
        t2 = y(j==iii);
        num_reps = length(t2);
        t2 = (sum(t2)^2)/num_reps;
        ssq_treat(i) = ssq_treat(i) + t2; %this is formal summation step in textbook formula
      end
      
    elseif col_coef_order(i)==3     %3-way interactions=================================
      [b,z,j] = unique(x(:,column_ID{i}),'rows');
      
      for iii = 1:max(j)
        t2 = y(j==iii);
        num_reps = length(t2);
        t2 = (sum(t2)^2)/num_reps;
        ssq_treat(i) = ssq_treat(i) + t2; %this is formal summation step in textbook formula
      end
      
    elseif col_coef_order(i)==4     %4-way interactions=================================
      [b,z,j] = unique(x(:,column_ID{i}),'rows');
      
      for iii = 1:max(j)
        t2 = y(j==iii);
        num_reps = length(t2);
        t2 = (sum(t2)^2)/num_reps;
        ssq_treat(i) = ssq_treat(i) + t2; %this is formal summation step in textbook formula
      end
    end
    
    
    %DoF Calculations
    if col_coef_order(i)==0  %intercept
      dof_treat(i) = max(j);
    elseif col_coef_order(i)==1    %main effects
      dof_treat(i) = max(j) - 1;
    else  %n-way interactions
      dof_treat(i) = prod(dof_treat(column_ID{i}));
    end
    
    clear j t2 b z
  end
  
  
  %Finalize Sum of Square Calculation for Treatments
  for ii = 1:num_cols
    switch col_coef_order(ii)
      case 1  %main effect=============
        ssq_treat(ii) = ssq_treat(ii) - mysq;
        
        
      case 2  %2-factor interaction=============
        ind = column_ID{ii};
        total = sum(ssq_treat(ind));  %find sum of main effects SSq
        ssq_treat(ii) = ssq_treat(ii) - mysq - total;
        
        
      case 3  %3-factor interaction=============
        ind = column_ID{ii};
        
        comb = num2cell(nchoosek(column_ID{ii}, 2),2); %find 2way combos, should be only 3
        ind2 = zeros(1,length(comb));
        for k=1:length(column_ID);    %loop to find indices of pertinent 2way columns
          for j=1:length(comb);
            if length(column_ID{k})==length(comb{j}) & all(column_ID{k}==comb{j})
              ind2(j) = k;
              break;
            end
          end
        end
        if any(ind2==0)
          error('Some 2-way interactions needed by a 3-way term are missing. All related 2-way interactions are required.');
        end
        total = sum(ssq_treat(ind)) + sum(ssq_treat(ind2));  %find sum of main effects and 2-way interaction SSq
        ssq_treat(ii) = ssq_treat(ii) - mysq - total;
        
        
      case 4  %4-factor interaction=============
        ind = column_ID{ii};
        
        comb = num2cell(nchoosek(column_ID{ii}, 2),2); %find 2way combos, should be only 6
        ind2 = zeros(1,length(comb));
        for k=1:length(column_ID);    %loop to find indices of pertinent 2way columns
          for j=1:length(comb);
            if length(column_ID{k})==length(comb{j}) & all(column_ID{k}==comb{j})
              ind2(j) = k;
              break;
            end
          end
        end
        if any(ind2==0)
          error('Some 2-way interactions needed by a 4-way term are missing. All related 2-way interactions are required.');
        end
        
        comb3 = num2cell(nchoosek(column_ID{ii}, 3),2); %find 2way combos, should be only 4
        ind3 = zeros(1,length(comb3));
        for k=1:length(column_ID);    %loop to find indices of pertinent 3way columns
          for j=1:length(comb3);
            if length(column_ID{k})==length(comb3{j}) & all(column_ID{k}==comb3{j})
              ind3(j) = k;
              break;
            end
          end
        end
        if any(ind3==0)
          error('Some 3-way interactions needed by a 4-way term are missing. All related 3-way interactions are required.');
        end
        total = sum(ssq_treat(ind)) + sum(ssq_treat(ind2)) + sum(ssq_treat(ind3));  %find sum of main effects,2-way, and 3-way interaction SSq
        ssq_treat(ii) = ssq_treat(ii) - mysq - total;
    end
  end
  
  
  %===Total Sum of Squares===========
  ssq_total = y_orig'*y_orig - (sum(y_orig)^2)/size(x_orig,1);
  %Note: use of x_orig and y_orig hereafter which INCLUDES any potential
  %centerpoints....centerpts were exluded from SS_treatment calc's above
  
  %===Total DoF============================
  dof_total = size(x_orig,1) - 1;
  % subtract one due to the implicit calculation of the avgY in the ANOVA
  % model
  
  
  %===DoF Error
  dof_error = max(0,size(x_orig,1)-1-sum(dof_treat));
  
  
  %===Error Sum of Squares & DoF===========
  ssq_error = max(0,ssq_total - sum(ssq_treat));
  mean_sq_error = ssq_error/dof_error;
  
  
  %===Calculation of Mean Square values, F-values, and p-values===========
  mean_sq = ssq_treat./dof_treat;
  if dof_error > 0 & all(dof_treat > 0) & ssq_error > 0
    F = mean_sq/(ssq_error/dof_error);
    for i = 1:num_cols
      F_crit(i) = ftest(0.05, dof_treat(i), dof_error);
      p(i) = ftest(F(i), dof_treat(i), dof_error, 2);
    end
  else
    %if no replicates, error dof=0, assign empty
    F      = [];
    F_crit = [];
    p      = [];
  end
  
  %===Calculation of Lack of Fit===========
  [b,z,j] = unique(x_orig,'rows');
  %don't calc LofF if # coef to be calc'd = # unique exptl pts...no d.ofF. left for LofF test
  dof_lackfit = size(b,1) - (num_cols+1);  %Lackfit DofF= # unique exptl pts - # coef cald'd
  %Note: add one to num_cols due to implicit calc of avgY...which is formally
  %one of the '# of coefficients cal'd'
  baddof = true;  %unless we find otherwise
  if dof_error > 0  &&  dof_lackfit>0  &&  dof_error>dof_lackfit   %opt out if dof_error=0..no replicates at all
    dof_pureerror = dof_error - dof_lackfit;
    ssq_pureerror=0;
    for i = 1:max(j)  %calc pure error SSq; loop through all unique experimental points but...
      t = y_orig(j==i);
      num_reps = length(t);
      if num_reps >1     %...only work on those exptl pts with replicate
        t = sum(t.^2) - (mean(t)^2)*num_reps;
        ssq_pureerror = ssq_pureerror + t;
      end
    end
    ssq_lackfit = ssq_error - ssq_pureerror;
    
    if ssq_pureerror>0
      %==F-Test===
      mean_sq_lackfit = ssq_lackfit/dof_lackfit;
      F_lackfit       = (ssq_lackfit/dof_lackfit)/(ssq_pureerror/dof_pureerror);
      F_crit_lackfit  = ftest(0.05, dof_lackfit, dof_pureerror);
      p_lackfit       = ftest(F_lackfit, dof_lackfit, dof_pureerror, 2);
      baddof = false;
    end
  end
  if baddof
    %empty out all these values (not enough DOF to calculate)
    [ssq_lackfit, ssq_pureerror, dof_lackfit, dof_pureerror, p_lackfit, ...
      mean_sq_lackfit, F_lackfit, F_crit_lackfit] = deal([]);
  end
  
  
  %===Overall Model Calculations===========
  ssq_model = sum(ssq_treat);
  dof_model = sum(dof_treat);
  mean_sq_model = ssq_model/dof_model;
  
  %F-Test for entire model
  %Note: this test assumes no lack of fit!  All residual deg. of Freed. used
  %for MSE
  if dof_error > 0 & dof_model > 0 & ssq_error > 0 & ssq_model>0
    F_model = (ssq_model/dof_model)/(ssq_error/dof_error);
    F_crit_model = ftest(0.05, dof_model, dof_error);
    p_model = ftest(F_model, dof_model, dof_error, 2);
  else
    F_model = [];  %assign nothing if no replicates for error estimate, dof_error=0
    F_crit_model = [];
    p_model = [];
  end
  
end


%===Calculate ASCA-related coeffs for each term===
[out] = getasca(x,y,originaldso, column_ID);

if ny==1
out.ssq.model     = ssq_model;
out.ssq.factors   = ssq_treat;
out.ssq.error     = ssq_error;
out.ssq.total     = ssq_total;
out.ssq.lackfit   = ssq_lackfit;
out.ssq.pureerror = ssq_pureerror;

out.dof.model     = dof_model;
out.dof.factors   = dof_treat;
out.dof.error     = dof_error;
out.dof.total     = dof_total;
out.dof.lackfit   = dof_lackfit;
out.dof.pureerror = dof_pureerror;

out.mean_sq.model   = mean_sq_model;
out.mean_sq.factors = mean_sq;
out.mean_sq.error   = mean_sq_error;
out.mean_sq.lackfit = mean_sq_lackfit;

out.F.model        = F_model;
out.F.crit_model   = F_crit_model;
out.F.factors      = F;
out.F.crit_factors = F_crit;
out.F.lackfit      = F_lackfit;
out.F.crit_lackfit = F_crit_lackfit;

out.p.model        = p_model;
out.p.factors      = p;
out.p.lackfit      = p_lackfit;

out.table = txttable(out,originaldso,originalydso);

if strcmpi(options.display,'on')
  disp(out.table);
end
end
end

%--------------------------------------------------------------
function txt = txttable(temp,originaldso,originalydso)

num_cols = length(originaldso.include{2});

%create text-version of the table
if isempty(temp.F.factors)
  temp.F.factors = nan(1,num_cols);
  temp.F.model = nan;
  temp.p.factors = temp.F.factors;
  temp.p.model = nan;
end

%header for columns
header = '       SSQ       DOF      Mean Sq           F        Sig.  ';
header = [header;repmat('-',1,length(header))];
%create numeric table for model and factors
mres = [...
  [temp.ssq.model temp.dof.model temp.mean_sq.model temp.F.model temp.p.model]' ...
  [temp.ssq.factors' temp.dof.factors' temp.mean_sq.factors' temp.F.factors' temp.p.factors']'...
  ];
%convert to numbers and add rows for Error and Total
tbl = [...
  sprintf('  %12.3f   %3i   %12.3f    %9.3f     %0.3f\n',mres) ...
  sprintf('  %12.3f   %3i   %12.3f  \n',[temp.ssq.error temp.dof.error temp.mean_sq.error]) ...
  sprintf('  %12.3f   %3i   \n',[temp.ssq.total temp.dof.total])...
  ];
tbl = str2cell(tbl);
tbl = [tbl(1);{' '};tbl(2:num_cols+1);{' '};tbl(num_cols+2:end)];

%row labels (MUST match number of rows created in tbl + header above)
xlbl = originaldso.label{2};
xlbl = xlbl(originaldso.include{2},:);

tbllbl = char([{
  'Source';
  repmat('-',1,max(size(xlbl,2),8));
  'Model'
  ' '};
  str2cell(xlbl);
  {' '
  'Error';
  'Total'}]);

tbl = strrep(tbl,'NaN','n/a');

%concatenate for output
lbl = originalydso.label{2};
if isempty(lbl);
  lbl = ['Response'];
else
  lbl = lbl(originalydso.include{2},:);
end
txt = {' '
  ['ANOVA results for DOE ' originaldso.name ' on ' lbl]
  ' '
  [tbllbl char([{header};tbl])]
  };

if temp.dof.error==0
  txt = [txt; 
    ' '
    'Error degrees of freedom are zero - significance cannot be calculated.'
    'Exclude one or more factors and re-calculate.'
    ];
elseif temp.ssq.error==0
  txt = [txt; 
    ' '
    'Error sum of squares is zero - significance cannot be calculated.'
    ];
end


txt = char(txt);
end

%--------------------------------------------------------------------------
function [out] = getasca(x,y,originaldso, column_ID)
%===Calculate ASCA-related coeffs for each term===
coeffs = [];
coeffnames = {};
dvall = [];
sourcecol = [];
labels = originaldso.label{2}(originaldso.include{2},:);
fdvs = {};       % The Factor design matrices, (nsamp,nlevelsF)
fcoeffs = {};    % means for each level minus global avg. (nlevelsF,ny)

% Get the model matrix in sum-coding
[dmat, fdvxs, icols] = sumencode(x, column_ID);

% Get the ANOVA model parameters by least-squares regression
theta = pinv(dmat'*dmat)*(dmat'*y);

matrices = cell(1, length(fdvxs)+1);
% matrices, effects or interactions as nsamples x nvars
for ij = 1:length(fdvxs);
  matrices{ij+1} = fdvxs{ij}*theta(icols{ij}+1,:);
end
matrices{1} = ones(size(dmat,1),1)*theta(1,:);

for j=1:size(x,2)
  %for each factor/term...
  [u,ui,uj] = unique(x(:,j));
  % uj is index of levels in order of appearance, 1 - nlevels
  fdv  = class2logical(uj); 
  fdv = fdv.data;
  
  flbl = strtrim(labels(j,:));
  for k=1:length(u);
    coeffnames{end+1,1} = sprintf('%s = %i',flbl, originaldso.data(ui(k),j));
  end
  sourcecol = [sourcecol ones(1,size(fdv,2))*j];  % sourcecol are the cols of x which contrib to each coeff
  dvall = [dvall fdv];
  fcoeffs{j} = theta(icols{j}+1,:);
end
  
maxsourcecols = max(sourcecol);
designmats=cell(1,maxsourcecols);
designmatscols = cell(1,maxsourcecols);
coeffwts=cell(1,maxsourcecols);
yresiduals = y;

for kk=1:length(fdvxs)
  yresiduals = yresiduals - matrices{kk+1};
end
yresiduals  = yresiduals - matrices{1};

for kk=1:maxsourcecols
  designmatscols{kk} = sourcecol==kk;
  designmats{kk} = dvall(:,sourcecol==kk);
end

% Type III sum of squares
[effects, type3ssq] = gettype3ssq(theta, matrices, dmat, y, yresiduals, icols);

out = [];
out.coeffs.factors = theta;      % the regression parameters
out.coeffs.names   = ['Constant';coeffnames];
out.coeffs.matrices = matrices;       % includes mean
out.coeffs.residuals = yresiduals;

out.decomp.designmats = designmats;
out.decomp.designmatscols = designmatscols;
out.decomp.coeffwts = coeffwts;
out.decomp.coeffswtd = coeffs;
out.decomp.coeffswtdnames   = coeffnames;

out.effects  = effects;
out.type3ssq = type3ssq;
end

%--------------------------------------------------------------------------
function [dmat, fdvxs, icols] = sumencode(x, column_ID)
% Convert a factor matrix into a sum coded matrix (1's, 0's, and -1's)
% Inputs:
%     x : DOE matrix
% column_ID : cell array entries indicate the Factor, or factors involved
%             in the corresponding column of x
% Outputs:
%  dmat : the full sum coded model matrix
% fdvxs : sum coded sub-matrix for factor or interaction
% icols : contains the columns used for each fdvxs term
%
% Note: dmat is the column-wise concatenation of the fdvxs, with a column
% of 1's inserted as first column.

dmat = repmat(1,size(x,1),1);
icolcur = 0;
icols = {};
fdvxs = {};
for j=1:size(x,2)
  order = length(column_ID{j});
  if order==1
    %for each factor/term...
    [u,ui,uj] = unique(x(:,j));
    % uj is index of levels in order of appearance, 1 - nlevels
    fdv  = class2logical(uj);
%     fdvs{j} = fdv;
    fdv = fdv.data;
    fdvx = sumcoding(fdv);
    fdvxs{j} = fdvx;
  elseif order==2
    colids = column_ID{j};
    fdv1 = fdvxs{colids(1)};  % Design matrix for main effect 1
    fdv2 = fdvxs{colids(2)};  % Design matrix for main effect 2
    [m,n1] = size(fdv1);
    n2 = size(fdv2,2);
    fdv12 = nan(m,n1*n2);
    for i1 = 1:n1
      for i2 = 1:n2
        ii = (i1-1)*n2+i2; % Use row-major, same as fcoeffs.
        % so theta will be ordered ab 11, 12, 21, 22, 31, 32
        %         ii = (i2-1)*n1+i1;  % Use column-major: i1 varies most rapidly
        %         % so theta will be ordered: ab 11, 21, 31, 12, 22, 32
        fdv12(:,ii) = fdv1(:,i1).*fdv2(:,i2);
      end
    end
    fdvxs{j} = fdv12;
  elseif order==3
    colids = column_ID{j};
    fdv1 = fdvxs{colids(1)};  % Design matrix for main effect 1
    fdv2 = fdvxs{colids(2)};  % Design matrix for main effect 2
    fdv3 = fdvxs{colids(3)};  % Design matrix for main effect 2
    [m,n1] = size(fdv1);
    n2 = size(fdv2,2);
    n3 = size(fdv3,2);
    fdv123 = nan(m,n1*n2*n3);
    for i1 = 1:n1
      for i2 = 1:n2
        for i3 = 1:n3 
          ii = (i1-1)*n2*n3+(i2-1)*n3+i3; % Use row-major, same as fcoeffs.
        % so theta will be ordered ab 11, 12, 21, 22, 31, 32
        %         ii = (i2-1)*n1+i1;  % Use column-major: i1 varies most rapidly
        %         % so theta will be ordered: ab 11, 21, 31, 12, 22, 32
        fdv123(:,ii) = fdv1(:,i1).*fdv2(:,i2).*fdv3(:,i3);
        end
      end
    end
    fdvxs{j} = fdv123;
  end
  
  dmat = [dmat fdvxs{j}];
  icols{j} = icolcur + [1:size(fdvxs{j},2)];
  icolcur  = icolcur + size(fdvxs{j},2);
end
end

%--------------------------------------------------------------------------
function res = sumcoding(fdv)
% Convert a class logical matrix (m,n) into the corresponding sum coded 
% array (m, n-1)
ncol = size(fdv,2);
iflag = fdv(:,ncol);
res = double(fdv(:,1:(ncol-1)));
res(iflag,:) = -1;
end

%--------------------------------------------------------------------------
function SS = type3ss(dmat, Li, theta)
% type III SSQ
LB = Li*theta;
BL = LB';
mat = BL*pinv(Li*pinv(dmat'*dmat)*(Li'))*LB;
SS  = sum(diag(mat));

% Li are not square so can't use inv
% Also, pinv(a*b) != pinv(b)*pinv(a)
end

%--------------------------------------------------------------------------
function [effects, type3ssqs] = gettype3ssq(theta, matrices, dmat, y, yresiduals, icols)
% Outputs:
% type3ssqs : Type III sum of squares per factor and interaction
%   effects : As a percentage of total sum of squares

yminusmean = y - matrices{1};
totalssq   = sum(sum(yminusmean.^2));  % excluding the mean term

neffects  = length(icols)+1;  % includes the global mean
type3ssqs = nan(1, neffects+1);
effects   = nan(1, neffects+1);

Ldiag   = diag(ones(1,size(theta,1)));
L = cell(1,neffects);
L{1}    = Ldiag(1,:);
for ii=2:neffects
  L{ii} = Ldiag(icols{ii-1}+1,:);
end

for ii=1:neffects
  type3ssqs(ii) = type3ss(dmat, L{ii}, theta);
  effects(ii)   = type3ssqs(ii);
end
% and residual term:
type3ssqs(neffects+1) = sum(sum(yresiduals.^2));
effects(neffects+1)   = type3ssqs(neffects+1);
% Ignore global mean. It has no variance
effects(1)            = 0;
effects               = effects/sum(effects) *100;
end
