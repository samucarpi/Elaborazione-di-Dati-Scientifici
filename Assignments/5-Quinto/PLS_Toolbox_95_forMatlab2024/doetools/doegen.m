function [doe,msg] = doegen(type,factors,scales,levels,options)
%DOEGEN Generate a Design of Experiments (DOE) DataSet object.
% Creates a Design of Experiements of a specified type with named factors
% designed with a specified number of levels and coding of those levels at
% specified values or categorical names.
%
% Designs can be a mix of numerical and categorical factors. The type of
% factor is defined by the (scales) input which specifies either the
% minimum and maximum values to use (numerical factor), the exact numerical
% values to be used (numerical factor), or the names of the categories
% (categorical factor).
%
% Some design types have a specific number of levels which they allow. If
% one or more categorical factors requires a different number of levels
% than the design allows, the design is calculated without these
% categorical factor(s) and then replicated for all levels of the
% factor(s). This may increase the number of required samples beyond what
% is expected but provides full resolution of categorical factors in
% designs which would otherwise be incompatible with them.
%
% INPUTS:
%      type = Type of design to create:
%              'full' = full factorial
%              '2' or '1/2' = 1/2 factorial     (2-level)
%              '4' or '1/4' = 1/4 factorial     (2-level)
%              '8' or '1/8' = 1/8 factorial     (2-level)
%              '16' or '1/16' = 1/16 factorial  (2-level)
%              'face' = Face-centered Central Composite (3-level)
%              'sphere' = Sperical Central Composite    (5-level)
%              'box'    = Box-Behnken Design (3-level)
% OPTIONAL INPUTS:
%   factors = Cell array indicating the name(s) of the factors. The number
%             of strings indicates the total number of factors in the
%             design. If factors is omitted, "levels" or (scales) must be
%             supplied (see below) and simple strings will be provided for
%             each factor's name.
%    scales = Cell array containing either double vectors (for numerical
%             factors) or cell arrays of strings (for categorical factors).
%             * Numerical factors: the doubles indicate the minimum and
%               maximum values for each factor's levels (if only two values
%               are in a given cell) or the specific level values (if more
%               than two values are in the cell). If only two values are
%               supplied, the number of levels to use must be passed in the
%               (levels) input.  
%             * Categorical factors: number of strings in the cell array
%               defines the number of levels for the given factor.
%             Example:
%               {  [5 8 9 10]  [ 100 200 ]  {'treat A'  'treat B'} } 
% 
%               Defines scaling for three factors. The first two are
%               numerical factors: one with four specific levels (equal to 5
%               8 9 10), one with a min/max of 100 and 200, and a third
%               categorical factor with the labels indicated for the two
%               categories. If using a full-factorial design and the second
%               factor should have more than two levels, the (levels) input
%               must be provided (see below.)
%             If scales is omitted, "levels" must be supplied (see below).
%
%    levels = Vector specifying the number of levels to use for each factor
%               in a full-factorial design. This can either be supplied in
%               place of the (scales) input, or along with (scales) when
%               scales is only the minimum and maximum values for each
%               factor.
%             If (scales) is not provided, this defines the total number of
%               numeric factors and number of levels for each factor.
%             If scales is provided as min/max values, then levels defines
%               how many levels to have in each factor between those
%               min/max values. This vector must be equal in length to the
%               total number of factors (including both numeric and
%               categorical factors) even though the values defined here
%               for categorical factors will not be used. 
%               For example, if (scales) defines three factors: 
%                 {  [5 8 9 10]  [ 100 200 ]  {'treat A'  'treat B'} } 
%               then factors 1 and 3 are unambiguiously defined as having 4
%               and 2 levels, respectively. If the (levels) input is not
%               provided, it will be assumed that factor 2 should have only
%               two levels. If factor 2 should have more levels, for example,
%               3 levels at 100 150 and 200, the levels input needs to be
%               defined as:
%                 [ 4 3 2]
%             Notice that this input can be completely dropped if the
%             (scales) input specifically defines the number and values of
%             all factor levels. However, it must be supplied if no scales
%             are supplied.
%
%   options = Options structure with one or more of the following fields:
%
%        interactions: [1] Specify what type interactions to include in the
%                      final DOE as a scalar numerical value indicating the
%                      highest number of interacting factors to include (A
%                      value of 1 (one) indicates no interactions) or as a
%                      cell array of numerical vectors indicating which
%                      column(s) should be combined an in what way(s) to
%                      create the interaction terms. 
%                      Example:  { [1] [2] [3] [1 3] }
%           randomize: [ 'no' | {'yes'} ] Specify whether to reorder the
%                      output design to a randomized order. Whether or not
%                      this randomize option is used, a randomized
%                      axisscale is created in the output which can be used
%                      to reorder the experiments. In addition, an
%                      "original order" axisscale is also created to allow
%                      re-ordering to the original unrandomized DOE order.
%        centerpoints: [0] Number of additional center points to add to the
%                      design. Note that center points are calculated for
%                      all numerical factors (whether or not they had a
%                      center point to begin with) and these points are
%                      replicated for all combinations of categorical
%                      factors. Thus, the total number of center points
%                      added will be the product of the number requested
%                      times the number of combinations of categorical
%                      variables in the design.
%  response_variables: [{}] Cell array of strings naming one or more
%                      reponse variables to add to a run sheet.
%          replicates: [0] Number of replicates.
%
%
% OUTPUTS:
%    doe = Design of Experiments DataSet object containing classes, labels,
%          and additional userdata information on the design.
%    msg = If requested as an output, design errors (such as incompatible
%          settings between design type and number of levels or factor
%          types) are squelched and returned in this string. When an error
%          is discovered, the (doe) output will be empty. Errors in input
%          format or general usage are still thrown as standard errors.
%    
% EXAMPLES:
%  Create a face-centered central composite design with one categorical
%  factor named 'Processor' with categories 'J' and 'K', and two numeric
%  factors, one named 'ethylene %' at evenly spaced levels between 1 and 5
%  and one named 'butene %' at the specific levels 0, 4, and 6.
%     doe = doegen('face',{'Processor' 'ethylene %' 'butene %'},{{'J' 'K'} [1 5] [0 4 6] });
%
%  Create a 1/2 fractional factorial (3-1) screening design with the same
%  factors except the butene is screened at only 0 and 6%.
%     doe = doegen('1/2',{'Processor' 'ethylene %' 'butene %'},{{'J' 'K'} [1 5] [0 6] });
%
%  Create a full-factorial design with the same factors but with specific
%  levels for all factors. Note that ethylene % scales are given as min/max
%  values of 1 and 5 but the (levels) input specifies that it should be
%  evaluated at 4 levels. The other two factors are specifically defined at
%  2 and 3 levels both by their (scales) input as well as the (levels)
%  input:
%     doe = doegen('full',{'Processor' 'ethylene %' 'butene %'},{{'J' 'K'} [1 5] [0 3 6] },[2 4 3]);
%
%I/O: [doe,msg] = doegen(type,factors,scales,levels,options)
%I/O: [doe,msg] = doegen(type,factors,levels)
%I/O: [doe,msg] = doegen(type,scales)
%I/O: [doe,msg] = doegen(type,levels)
%
%See also: BOXBEHNKEN, CCDFACE, CCDSPHERE, DISTSLCT, DOEGEN, DOESCALE, DOE_ANOVA, DOPTIMAL, FACTDES, FFACDES1, STDSSLCT

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  doegui;
  return
end

if nargin==1
  options = [];
  options.randomize = 'yes';
  options.interactions = 1;
  options.centerpoints = 0;
  options.response_variables = {};
  options.replicates = 0;
  if nargout==0;evriio(mfilename,type,options);else; doe = evriio(mfilename,type,options);end
  return;
end

doe = [];
msg = '';
if nargin<2
  error('Incorrect number of inputs')
end
switch nargin
  case {2,3}
    % (type,scales)
    % (type,levels)
    % (type,scales,levels)
    % (type,scales,options)
    % (type,levels,options)
    % (type,factors,scales)
    % (type,factors,levels)
    options = [];
    levels  = [];
    if nargin==2
      scales = factors;
      factors = {};
    else  %3 inputs
      if isstruct(scales)
        % (type,scales,options)
        % (type,levels,options)
        %the difference between these two is handled below
        options = scales;
        scales = factors;
        factors = {};
      elseif iscell(factors) & ~all(cellfun(@(i) ischar(i),factors))
        % (type,scales,levels)
        levels = scales;
        scales = factors;
        factors = {};
      end
    end
  case 4
    % (type,factors,scales,levels)
    % (type,factors,scales,options)
    if iscell(factors) & ~all(cellfun(@(i) ischar(i),factors))
      % (type,scales,levels,options)
      options = levels;
      levels = scales;
      scales = factors;
      factors = {};
    else
      if isstruct(levels)
        options = levels;
        levels = [];
      else
        options = [];
      end
    end
  case 5
    % (type,factors,scales,levels,options)
    %do nothing.
end
options = reconopts(options,mfilename);

%if (scales) is numeric and (levels) is empty, assume scales is levels and
%that scales should be populated with default values
if isempty(levels) & ~isempty(scales) & isnumeric(scales)
  %assume scales is levels and that scales should be simple count up
  levels = scales;
  scales = {};
  for j=1:length(levels);
    scales{j} = 0:levels(j)-1;
  end
end

%check format of factors
if isempty(factors)
  for j=1:length(scales)
    factors{j} = char('A'+j-1);
  end
elseif ~iscell(factors) | ~all(cellfun('isclass', factors, 'char'))
  error('Factors must be a cell array of strings naming the factors');
end
nfacts = length(factors);

%Check the scales
if isempty(scales)
  %empty indicates use default scaling for all
  scales = repmat({[0 1]},1,nfacts);
elseif length(scales)~=nfacts
  error('Number of entries in "scales" must be equal to the number of factor labels');
end

%Identify categorial factors and 
iscategorical = cellfun('isclass',scales,'cell');

%Check for cell arrays of NUMERICAL values (not categorical) This is a
%convenience feature so that users can just use cells for EVERYTHING and
%we'll recognize categorical vs. non based on the CONTENT of the cells:
%   { { 1 5 }  { 100 200 } { 'cat A' 'cat B'} }
% = { [ 1 5 ]  [ 100 200 ] { 'cat A' 'cat B'} }
for item=find(iscategorical)
  isachar = cellfun('isclass',scales{item},'char');
  if any(isachar) & ~all(isachar)
    error('Scales for factor %i is an invalid mix of character and non-character values',item);
  end
  if any(~isachar)
    iscategorical(item)=false;
    try
      scales{item} = [scales{item}{:}];
    catch
      error('Unable to interpret scales for factor %i. Incompatible numeric values found.',item);
    end
  end
end

%Get implied # of levels (based on length of scales
impliedlevels = [];
for i = 1:length(scales)
  impliedlevels = [impliedlevels length(scales{i})];
end

%- - - - - - - - - - - - - - - - - - - - -
%Get number of fixed levels for the given design
if isnumeric(type)
  type = num2str(type);
end
%translate some names
switch lower(type)
  case 'box'
    type = 'boxbehnken';
  case 'ccdface'
    type = 'face';
  case {'ccdsphere' 'spherical'}
    type = 'sphere';
end
%determine number of allowed levels for categorical variables
switch lower(type)
  case {'2' '4' '8' '16' '1/2' '1/4' '1/8' '1/16'}
    allowlevel = 2;      
  case 'full'
    allowlevel = 0;   %all levels are OK
  otherwise
    allowlevel = inf;  %none allowed
end
if options.centerpoints>0
  %if adding centerpoints, set aside all categorical factors
  allowlevel = inf;
end

%set aside any categorical factors which do not have the correct number of
%levels allowed by this design
if allowlevel>0
  setaside = (iscategorical & impliedlevels~=allowlevel);
else  %allowlevel of zero indicates ALL are allowed
  setaside = false(1,nfacts);
end
numaside = sum(double(setaside));
if all(setaside)
  type = 'full';  %MUST use full-factorial if all factors are categorical set-aside factors
  setaside = false(1,nfacts);
  numaside = 0;
  if options.centerpoints>0
    msg = 'Cannot add centerpoints to design when all factors are categorical';
    if nargout>1; return; end
    error(msg);
  end
end

%- - - - - - - - - - - - - - - - - - - - -
%get coded design based on type
desc = ''; 
switch lower(type)
  %--------------------------------
  case {'full'}    
    %get levels needed (reconcile against scales)
    if isempty(levels);
      levels = impliedlevels;
    elseif length(levels)~=nfacts
      error('Number of levels supplied must equal number of factors in design');
    else
      %user passed levels - overwrite any values unambiguiously defined by scales input
      tocopy = (iscategorical | impliedlevels~=2);  %categorical or non-two-level items
      levels(tocopy) = impliedlevels(tocopy); 
    end
    
    %create actual design
    desgn = factdes(nfacts-numaside,levels(~setaside));
    doename = 'Full Factorial Design';
    type = 'full';
    alias_ID = {};
    
    %--------------------------------
  case {'2' '4' '8' '16' '1/2' '1/4' '1/8' '1/16'}
    %Fractional Factorial Designs
    %convert number to fractional factorial number needed for FFACDES1
    ff = str2num(type);
    if ff<1
      ff = 1/ff;
    end
    ff = round(log10(ff)/log10(2));

    if any(impliedlevels(~setaside)~=2)
      msg = sprintf('Numeric factors can only have 2 levels when using fractional factorial designs. Choose a different design or change scaling to define two levels.');
      if nargout>1; return; end
      error(msg);
    end
    
    try
      [desgn, col_ID, alias_ID, res] = ffacdes1(nfacts-numaside,ff,struct('display','off'));
    catch
      msg = sprintf('Unable to create a %i factor 1/%i (%i-%i) Fractional Factorial design',nfacts-numaside,2^ff,nfacts-numaside,ff);
      if nargout>1; return; end
      error(msg);
    end
    
    doename = sprintf('1/%i Factorial Design',2^ff);
    type = sprintf('1/%i',2^ff);
    desc = res;
        
    %--------------------------------
  case 'face'
    
    if any(impliedlevels(~setaside)~=3 & impliedlevels(~setaside)~=2)
      msg = sprintf('Numeric factors can only have 3 levels when using face-centered central composite designs. Choose a different design or change scaling.');
      if nargout>1; return; end
      error(msg);
    end  

    desgn = ccdface(nfacts-numaside);
    doename = 'Face-Centered Central Composite Design';
    type = 'face';
    alias_ID = {};
    
    %--------------------------------
  case 'sphere'
    if any(impliedlevels(~setaside)~=2 & impliedlevels(~setaside)~=2)
      msg = sprintf('Numeric factors can only have 2 levels when using spherical central composite designs. Choose a different design or change scaling.');
      if nargout>1; return; end
      error(msg);
    end
    
    desgn = ccdsphere(nfacts-numaside);
    doename = 'Spherical Central Composite Design';
    type = 'sphere';
    alias_ID = {};

    %--------------------------------
  case {'boxbehnken'}
    if any(impliedlevels(~setaside)~=3 & impliedlevels(~setaside)~=2)
      msg = sprintf('Numeric factors can only have 3 levels when using Box-Behnken central composite designs. Choose a different design or change scaling.');
      if nargout>1; return; end
      error(msg);
    end
    
    desgn = boxbehnken(nfacts-numaside);
    doename = 'Box-Behnken Design';
    type = 'boxbehnken';
    alias_ID = {};
    
    %--------------------------------
  otherwise
    error('Unrecognized design type "%s"',type);

end

%add centerpoints if desired
if options.centerpoints>0
  desgn = [desgn; zeros(options.centerpoints,size(desgn,2))];
end

%find samples which are centerpoints (prior to adding set-aside categorical
%factors)
iscenterpoint = all(desgn==0,2);

%replicate design for all categorical factors with non-allowed # of
%levels
if numaside>0
  %calculate full factorial design for the left-out categorical factors and
  %then replicate design for each of those combinations
  adddesgn = factdes(numaside,impliedlevels(setaside));
  lu = ones(size(desgn,1),1)*(1:size(adddesgn,1));
  
  %replicate basic design rows as needed andb combine in appropriate column
  newdesgn = zeros(size(desgn,1)*size(adddesgn,1),nfacts);
  newdesgn(:,~setaside) = repmat(desgn,size(adddesgn,1),1);
  newdesgn(:,setaside)  = adddesgn(lu,:);
  desgn = newdesgn;
  
  %replicate iscenterpoint too
  iscenterpoint = repmat(iscenterpoint,size(adddesgn,1),1);

end

%- - - - - - - - - - - - - - - - - - - - -
%Handle scaling and categorical factors

%Set aside information on categorical factors, fill in placeholder info
cats = {};
for j=find(iscategorical)
  cats(end+1,1:2) = {j scales{j}};
  scales{j} = 1:length(scales{j});  %set scaling
  expected = length(unique(desgn(:,j)));
  if expected~=length(scales{j});
    error('Categorical factor "%s" does not have the correct number of labels (expected %i)',factors{j},expected);
  end
end

%fill in basic min/max scaling for empty scales
noscale = cellfun('isempty',scales);
if any(noscale)
  [scales{noscale}] = deal([0 1]);
end
%handle scaling for numerical factors
try
  desgn = doescale(desgn,scales);
catch
  %problem? see if the user is expecting a nice output
  if nargout>1; 
    msg = lasterror;
    msg = msg.message;
    msg = msg(min(find(msg==10))+1:end);  %drop "error in" part of error
    return; 
  end
  rethrow(lasterror);
end

%- - - - - - - - - - - - - - - - - - - - -
%Create replicates if needed.
if options.replicates>0
  reps = ones(options.replicates,1)*[1:size(desgn,1)];
  desgn = desgn(reps(:),:);
  iscenterpoint = iscenterpoint(reps(:),:);
end

%- - - - - - - - - - - - - - - - - - - - -
%create DSO
doe = dataset(desgn);
doe.author = 'DOEGEN';
doe.name   = doename;
doe.description = desc;

%add labels for columns
doe.labelname{2} = 'Factors';
doe.label{2} = factors;

%add sample axisscales for design and random orders
doe.axisscalename{1,1} = 'Design Order';
sampord = 1:size(doe,1);
doe.axisscale{1,1} = sampord;

doe.axisscalename{1,2} = 'Run Order';
doe.axisscale{1,2} = shuffle((1:size(doe,1))')';

%add column classes for categorical vs. numeric
doe.classlookup{2,1} = {1 'Numeric'; 2 'Categorical'};
doe.classname{2,1} = 'Factor Type';
doe.class{2,1} = double(iscategorical)+1;

%Add classes for categorical factors
if ~isempty(cats)
  for cl=1:size(cats,1);
    [col,strs] = deal(cats{cl,:});
    doe.classname{1,cl}   = strtrim(doe.label{2}(col,:));
    doe.classlookup{1,cl} = [num2cell(1:length(strs))' strs(:)];
    doe.class{1,cl}       = doe.data(:,col);
  end
end

%create labels for samples
lbls = str2cell(sprintf('Sample %i\n',1:size(doe,1)));
lbls(iscenterpoint) = str2cell(sprintf('Center Point %i\n',1:sum(double(iscenterpoint))));
doe.label{1} = lbls;
doe.labelname{1} = 'Samples';

%create classes for samples
useset = min(find(cellfun('isempty',doe.class(1,:))));  %find empty set
if isempty(useset)
  %no empty sets? add one
  useset = size(doe.class,2)+1;
end
doe.classname{1,useset} = 'Sample Type';
doe.classlookup{1,useset} = {1 'Sample'; 2 'Center Point'};
doe.class{1,useset} = double(iscenterpoint)+1;

%- - - - - - - - - - - - - - - - - - - - -
%add interactions
inter = options.interactions;
if (isnumeric(inter) & inter>1) | (iscell(inter) & (any(cellfun('size',inter,2)>1) | length(inter)<nfacts))
  %is this a numeric interactions (and >1 is requested) or do we have any
  %interactions OR are there DROPPED columns (user asked to remove some
  %columns)?
  [doe,col_ID] = doeinteractions(doe,inter);
else
  %get generic col_ID
  col_ID = num2cell(1:nfacts);
end

%- - - - - - - - - - - - - - - - - - - - -
%randomize if asked to
if strcmp(options.randomize,'yes')
  [junk,order] = sort(doe.axisscale{1,2});
  doe = doe(order,:);
end

%- - - - - - - - - - - - - - - - - - - - -
%assemble DOE userdata information 
userdata = [];
userdata.type = lower(type);
userdata.factors = factors;
userdata.options = options;
userdata.alias_ID = alias_ID;
userdata.col_ID   = col_ID;

doe.userdata.DOE = userdata;  %add to DSO
