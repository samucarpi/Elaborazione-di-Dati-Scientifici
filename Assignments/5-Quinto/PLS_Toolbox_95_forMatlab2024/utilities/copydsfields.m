function to = copydsfields(from,to,modes,block,append)
%COPYDSFIELDS Copies informational fields between datasets and/or models.
%  Copies specific fields from one dataset object to another, one model
%  to another, or between datasets and models. Fields copied:
%    "label", "class", "classlookup", "title", "axisscale", "includ"
%  as well as the associated "<field>name" fields (e.g. classname).
%
%  INPUTS:
%     from = dataset or model from which fields should be copied, and
%       to = dataset or model to which fields should be copied.
%
%  OPTIONAL INPUTS:
%    modes = modes (dims) which should be copied {default: all modes}.
%            (modes) can be a cell of {[from_modes] [to_modes]} to allow
%            cross-mode copying. if empty, default behavior is used.
%    block = data block of model from/to which information should be copied
%            Default: block 1. Can also be a cell of {[from_block]
%            [to_block]} to allow cross-block copying. This setting has no
%            effect with two DataSet objects. If empty, default behavior is
%            used.
%    append = boolean flag indicating: true = all sets should be appended
%             to the first empty set location in the (to) object or false =
%             all sets should be copied over into the exact corresponding
%             set number of the (to) object. Default is false.
%
%  OUTPUT:
%      to  = the updated dataset or model
%
%Examples:  
%  modl = copydsfields(mydataset,modl,1,{1 2});
%     Copies all fields for mode 1 (samples) from mydataset into  block 2
%     of modl. All sets are copied. 
%  ds2 = copydsfields(ds1,ds2,2);
%     Copies all fields for mode 2 (variables) from dataset 1 to dataset 2.
%     All sets are copied.
%
%I/O: to = copydsfields(from,to,modes,block);
%
%See also: COPYCVFIELDS, DATASET/DATASET, DATASET/RMSET, MODELSTRUCT, PCA, PCR, PLS

% (c) Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 3/14/02 initial coding
%jms 3/20/02 fixed includ field copy bug (only copied last mode of includ field)
%nbg 8/02 changed help
%rsk 02/12/04 Add copy all sets for DSO to DSO as default behavior
%rsk 02/12/04 Add set checking for existance in "from" DSO
%rsk 02/12/04 Change Input description, cross mode description was backwards

if nargin == 0; from = 'io'; end
varargin{1} = from;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; to = evriio(mfilename,varargin{1},options); end
  return;
end
if nargin <2;
  to = [];
%   error(['At least two inputs required - see ''help ' mfilename ''''])
end

%figure out what we've got as inputs
if isa(from,'dataset');
  vartype{1} = 0;
elseif ismodel(from);
  vartype{1} = 1;
else
  error('Input ''from'' must be either a dataset or a model structure');
end
if isa(to,'dataset');
  vartype{2} = 0;
elseif ismodel(to);
  vartype{2} = 1;
elseif isempty(to);
  vartype{2} = 2;   %non-model basic structure
else
  error('Input ''to'' must be either a dataset or a model structure');
end

%defaults for modes and blocks (if not supplied)
if nargin <3 | isempty(modes);
  if vartype{1};
    modes = 1:size(from.detail.label,1);
  else
    modes = 1:ndims(from.data);
  end
end
if nargin <4 | isempty(block);
  block = 1;
  %All sets = default for DSO to DSO.
  allSets = true;
else
  allSets = false;
end
if nargin < 5 | isempty(append)
  append = false;
end

%Make modes a cell and expand into two items if not already
if ~isa(modes,'cell');
  modes = {modes};
end
if length(modes) == 1;
  modes{2} = modes{1};
end
if length(modes) > 2;
  error('Modes should contain only two elements')
end
if length(modes{1}) ~= length(modes{2})
  error('To modes and From modes must be paired-up (equal in length)')
end

%Make block a cell and expand into two items if not already
if ~isa(block,'cell');
  block = {block};
end
if length(block) == 1;
  if vartype{2}==0 & vartype{1}>0;
    block{2} = 1;
  elseif vartype{2}>0 & vartype{1}==0;
    block = {1 block{1}};
  else %two models or two datasets
    block{2} = block{1};    %same block to same block or same set to same set
  end
end
if length(block) > 2;
  error('Block should contain only two elements')
end
if length(block{1}) ~= 1 | length(block{2}) ~= 1;
  error('To block and From block must be scalar indicies')
end

%validate modes and blocks
if vartype{2}==1;    %To model
  if block{2} > size(to.detail.label,2);
    error('To Model does not allow requested block')
  end
elseif vartype{2}==0   %To dataset
  if max(modes{2})>ndims(to.data);
    error('To Dataset does not allow requested mode(s)')
  end
end
if vartype{1}==1;    %From model
  if max(modes{1})>size(from.detail.label,1);
    error('From Model does not contain requested mode(s)')
  end
  if block{1} > size(from.detail.label,2);
    error('From Model does not contain requested block')
  end
else              %From dataset
  if max(modes{1})>ndims(from.data);
    error('From Dataset does not contain requested mode(s)')
  end

  for ind = 1:length(modes{2});
    %Test for existence of fields in from dataset.
    if length(from.label(modes{1}(ind),:)) < block{1}
      error('From Dataset does not contain requested label set')
    end
    if length(from.axisscale(modes{1}(ind),:)) < block{1}
      error('From Dataset does not contain requested axisscale set')
    end
    if length(from.title(modes{1}(ind),:)) < block{1}
      error('From Dataset does not contain requested title set')
    end
    if length(from.class(modes{1}(ind),:)) < block{1}
      error('From Dataset does not contain requested class set')
    end
    if length(from.classlookup(modes{1}(ind),:)) < block{1}
      error('From Dataset does not contain requested classlookup set')
    end
    %can't test sets vs requested From Block so just do it
    %on the fly giving an error of any field doesn't have
    %the selected set
  end

  %can't test sets vs requested From Block so just do it on the fly giving an error of any field doesn't have the selected set
end

if vartype{2} == 2
  to = struct('modeltype','DataSetInfo','datasource',[],'detail',struct('imageaxisscale',{{}},'imageaxisscalename',{{}}));
  %NOTE: most fields will automatically be added to .detail as needed, but
  %both imageaxisscale and imageaxisscalename are examined before the
  %contents are copied over (in case another block is higher dimensional)
  %so we MUST have those two fields pre-populated, albeit empty
  to.datasource = {getdatasource};
end

%- Make the Move -
switch vartype{1}
  case 0
    switch vartype{2}
      %----------------------------------------
      case 0    %From a dataset to a dataset

        to.name   = from.name;
        to.author = from.author;
        for ind = 1:length(modes{2});
          if allSets == 1
            %Default behavior = copy all sets for given field/mode in dataset.
            setoffset = findlastempty(to.label(modes{2}(ind),:),append);
            for b_ind = 1:length(from.label(ind,:))
              to.label{modes{2}(ind),b_ind+setoffset}     = char(from.label{modes{1}(ind),b_ind});
              to.labelname{modes{2}(ind),b_ind+setoffset} = char(from.labelname{modes{1}(ind),b_ind});
            end

            setoffset = findlastempty(to.axisscale(modes{2}(ind),:),append);
            for b_ind = 1:length(from.axisscale(ind,:))
              to.axisscale{modes{2}(ind),b_ind+setoffset}     =      from.axisscale{modes{1}(ind),b_ind};
              to.axisscalename{modes{2}(ind),b_ind+setoffset} = char(from.axisscalename{modes{1}(ind),b_ind});
              to.axistype{modes{2}(ind),b_ind+setoffset}      = char(from.axistype{modes{1}(ind),b_ind});
            end

            setoffset = findlastempty(to.title(modes{2}(ind),:),append);
            for b_ind = 1:length(from.title(ind,:))
              to.title{modes{2}(ind),b_ind+setoffset}         = char(from.title{modes{1}(ind),b_ind});
              to.titlename{modes{2}(ind),b_ind+setoffset}     = char(from.titlename{modes{1}(ind),b_ind});
            end

            setoffset = findlastempty(to.class(modes{2}(ind),:),append);
            for b_ind = 1:length(from.class(ind,:))
              to.class{modes{2}(ind),b_ind+setoffset}         =      from.class{modes{1}(ind),b_ind};
              to.classname{modes{2}(ind),b_ind+setoffset}     = char(from.classname{modes{1}(ind),b_ind});
            end
            
            for b_ind = 1:length(from.class(ind,:))
              to.classlookup{modes{2}(ind),b_ind+setoffset}         =      from.classlookup{modes{1}(ind),b_ind};            
            end
            
          else

            to.label{modes{2}(ind),block{2}}         = char(from.label{modes{1}(ind),block{1}});
            to.labelname{modes{2}(ind),block{2}}     = char(from.labelname{modes{1}(ind),block{1}});
            to.axisscale{modes{2}(ind),block{2}}     =      from.axisscale{modes{1}(ind),block{1}};
            to.axisscalename{modes{2}(ind),block{2}} = char(from.axisscalename{modes{1}(ind),block{1}});
            to.axistype{modes{2}(ind),block{2}}      = char(from.axistype{modes{1}(ind),block{1}});
            to.title{modes{2}(ind),block{2}}         = char(from.title{modes{1}(ind),block{1}});
            to.titlename{modes{2}(ind),block{2}}     = char(from.titlename{modes{1}(ind),block{1}});
            to.class{modes{2}(ind),block{2}}         =      from.class{modes{1}(ind),block{1}};
            to.classlookup{modes{2}(ind),block{2}}   =      from.classlookup{modes{1}(ind),block{1}};
            to.classname{modes{2}(ind),block{2}}     = char(from.classname{modes{1}(ind),block{1}});

          end
        end
        if block{2} == 1 & block{1} == 1;
          for ind = 1:length(modes{2});
            to.includ{modes{2}(ind),block{2}} = from.includ{modes{1}(ind),block{1}};
          end
        else
          warning('EVRI:CopydsfieldsNoIncludeSets','Dataset Includ field does not permit sets, Includ field not modified');
        end;
        if strcmpi(from.type,'image') & ismember(from.imagemode,modes{1})
          %is image and we are copy from the image mode
          to.type = 'image';
          fromimindex = (modes{1}==from.imagemode);
          to.imagemode = modes{2}(fromimindex);
          to.imagesize = from.imagesize;
          to.imageaxisscale = from.imageaxisscale;
          to.imageaxisscalename = from.imageaxisscalename;
        end
          
        %----------------------------------------
      case {1,2}    %From a dataset to a model

        if append
          error('APPEND flag is not supported in copying from dataset to model')
        end
        to.datasource{block{2}} = getdatasource(from);
        for ind = 1:length(modes{2});

          %copy all sets for given field/mode in dataset.
          if vartype{2}==1;
            to.detail.label(modes{2}(ind),block{2},:) = repmat({''},1,size(to.detail.label,3));
          end
          for b_ind = 1:length(from.label(ind,:))
            to.detail.label{modes{2}(ind),    block{2},b_ind}     = char(from.label{modes{1}(ind),b_ind});
            to.detail.labelname{modes{2}(ind),block{2},b_ind}     = char(from.labelname{modes{1}(ind),b_ind});
          end

          if vartype{2}==1;
            to.detail.axisscale(modes{2}(ind),block{2},:) = cell(1,size(to.detail.axisscale,3));
          end
          for b_ind = 1:length(from.axisscale(ind,:))
            to.detail.axisscale{modes{2}(ind),    block{2},b_ind} =      from.axisscale{modes{1}(ind),b_ind};
            to.detail.axisscalename{modes{2}(ind),block{2},b_ind} = char(from.axisscalename{modes{1}(ind),b_ind});
            to.detail.axistype{modes{2}(ind),block{2},b_ind}      = char(from.axistype{modes{1}(ind),b_ind});
          end

          if vartype{2}==1;
            to.detail.title(modes{2}(ind),block{2},:) = repmat({''},1,size(to.detail.title,3));
          end
          for b_ind = 1:length(from.title(ind,:))
            to.detail.title{modes{2}(ind),    block{2},b_ind}     = char(from.title{modes{1}(ind),b_ind});
            to.detail.titlename{modes{2}(ind),block{2},b_ind}     = char(from.titlename{modes{1}(ind),b_ind});
          end

          if vartype{2}==1;
            to.detail.class(modes{2}(ind),block{2},:) = cell(1,size(to.detail.class,3));
          end
          for b_ind = 1:length(from.class(ind,:))
            to.detail.class{modes{2}(ind),    block{2},b_ind}     =      from.class{modes{1}(ind),b_ind};
            to.detail.classname{modes{2}(ind),block{2},b_ind}     = char(from.classname{modes{1}(ind),b_ind});
          end
          
          if vartype{2}==1;
            to.detail.classlookup(modes{2}(ind),block{2},:) = cell(1,size(to.detail.classlookup,3));
          end
          for b_ind = 1:length(from.class(ind,:))
            to.detail.classlookup{modes{2}(ind),block{2},b_ind}   =      from.classlookup{modes{1}(ind),b_ind};
          end
          
          if block{1}==1;
            to.detail.includ{modes{2}(ind),block{2},1}        = from.include{modes{1}(ind),block{1}};
          end

        end
        
        if strcmpi(from.type,'image') & ismember(from.imagemode,modes{1})
          %is image and we are copy from the image mode
          %NOTE: getdatasource already grabbed type image, imagesize, and
          %imagemode
          to.detail.imageaxisscale(1:end,block{2}) = cell(size(to.detail.imageaxisscale,1),1);
          to.detail.imageaxisscale(1:length(from.imageaxisscale),block{2}) = from.imageaxisscale;
          to.detail.imageaxisscalename(1:end,block{2}) = repmat({''},size(to.detail.imageaxisscalename,1),1);
          to.detail.imageaxisscalename(1:length(from.imageaxisscalename),block{2}) = from.imageaxisscalename;
        end


        %----------------------------------------
    end
  case 1
    switch vartype{2}
      %----------------------------------------
      case 0    %From a model to a dataset
        
%         if strcmpi(from.modeltype, 'caltransfer')
%           % need to extract info from block 2
%           block = {2 2};
%         end
        to.name   = from.datasource{block{1}}.name;
        to.author = from.datasource{block{1}}.author;
        for ind = 1:length(modes{2});
          %copy all sets for given field/mode in dataset.
          setoffset = findlastempty(to.label(modes{2}(ind),:),append);
          for b_ind = 1:size(from.detail.label,3)
            to.label{modes{2}(ind),    b_ind+setoffset}     = char(from.detail.label{modes{1}(ind),block{1},b_ind});
            to.labelname{modes{2}(ind),b_ind+setoffset}     = char(from.detail.labelname{modes{1}(ind),block{1},b_ind});
          end

          setoffset = findlastempty(to.axisscale(modes{2}(ind),:),append);
          for b_ind = 1:size(from.detail.axisscale,3)
            to.axisscale{modes{2}(ind),    b_ind+setoffset} =      from.detail.axisscale{modes{1}(ind),block{1},b_ind};
            to.axisscalename{modes{2}(ind),b_ind+setoffset} = char(from.detail.axisscalename{modes{1}(ind),block{1},b_ind});
            to.axistype{modes{2}(ind),b_ind+setoffset}      = char(from.detail.axistype{modes{1}(ind),block{1},b_ind});
          end

          setoffset = findlastempty(to.title(modes{2}(ind),:),append);
          for b_ind = 1:size(from.detail.title,3)
            to.title{modes{2}(ind),    b_ind+setoffset}     = char(from.detail.title{modes{1}(ind),block{1},b_ind});
            to.titlename{modes{2}(ind),b_ind+setoffset}     = char(from.detail.titlename{modes{1}(ind),block{1},b_ind});
          end

          setoffset = findlastempty(to.class(modes{2}(ind),:),append);
          for b_ind = 1:size(from.detail.class,3)
            to.class{modes{2}(ind),    b_ind+setoffset}     =      from.detail.class{modes{1}(ind),block{1},b_ind};
            to.classname{modes{2}(ind),b_ind+setoffset}     = char(from.detail.classname{modes{1}(ind),block{1},b_ind});
          end
          
          for b_ind = 1:size(from.detail.classlookup,3)
            lookup = from.detail.classlookup{modes{1}(ind),block{1},b_ind};
            if isempty(lookup); continue; end  %skip if empty
            to.classlookup{modes{2}(ind), b_ind+setoffset}  =      lookup;
          end
          
          if block{2}==1;
            to.include{modes{2}(ind),block{2},1} = from.detail.includ{modes{1}(ind),block{1}};
          end

        end
        
        if strcmpi(from.datasource{block{1}}.type,'image') & ismember(from.datasource{block{1}}.imagemode,modes{1})
          %is image and we are copy from the image mode
          to.type = 'image';
          fromimindex = (modes{1}==from.datasource{block{1}}.imagemode);
          to.imagemode = modes{2}(fromimindex);
          to.imagesize = from.datasource{block{1}}.imagesize;
          nimmodes = length(to.imagesize);
          to.imageaxisscale = from.detail.imageaxisscale(1:nimmodes,block{1});
          to.imageaxisscalename = from.detail.imageaxisscalename(1:nimmodes,block{1});
        end
        

        %----------------------------------------
      case {1,2}    %From a model to a model

        if append
          error('APPEND flag is not supported in copying from model to model')
        end
        to.datasource{block{2}} = from.datasource{block{1}};
        for ind = 1:length(modes{2});
          for b_ind = 1:size(from.detail.label,3)
            to.detail.label{modes{2}(ind),    block{2},b_ind}     = char(from.detail.label{modes{1}(ind),    block{1},b_ind});
            to.detail.labelname{modes{2}(ind),block{2},b_ind}     = char(from.detail.labelname{modes{1}(ind),block{1},b_ind});
          end

          for b_ind = 1:size(from.detail.axisscale,3)
            to.detail.axisscale{modes{2}(ind),    block{2},b_ind}     =     (from.detail.axisscale{modes{1}(ind),    block{1},b_ind});
            to.detail.axisscalename{modes{2}(ind),block{2},b_ind}     = char(from.detail.axisscalename{modes{1}(ind),block{1},b_ind});
            to.detail.axistype{modes{2}(ind),block{2},b_ind}          = char(from.detail.axistype{modes{1}(ind),block{1},b_ind});
          end

          for b_ind = 1:size(from.detail.title,3)
            to.detail.title{modes{2}(ind),    block{2},b_ind}     = char(from.detail.title{modes{1}(ind),    block{1},b_ind});
            to.detail.titlename{modes{2}(ind),block{2},b_ind}     = char(from.detail.titlename{modes{1}(ind),block{1},b_ind});
          end

          for b_ind = 1:size(from.detail.class,3)
            to.detail.class{modes{2}(ind),    block{2},b_ind}     =     (from.detail.class{modes{1}(ind),    block{1},b_ind});
            to.detail.classname{modes{2}(ind),block{2},b_ind}     = char(from.detail.classname{modes{1}(ind),block{1},b_ind});
          end
          
          for b_ind = 1:size(from.detail.class,3)
            to.detail.classlookup{modes{2}(ind),block{2},b_ind}   =     (from.detail.classlookup{modes{1}(ind),    block{1},b_ind});
          end
          to.detail.includ{modes{2}(ind),block{2}}        = from.detail.includ{modes{1}(ind),block{1}};
        end

        if strcmpi(from.datasource{block{1}}.type,'image') & ismember(from.datasource{block{1}}.imagemode,modes{1})
          nimmodes = length(to.datasource{block{2}}.imagesize);
          to.detail.imageaxisscale(1:end,block{2}) = cell(size(to.detail.imageaxisscale,1),1);
          to.detail.imageaxisscale(1:nimmodes,block{2}) = from.detail.imageaxisscale(1:nimmodes,block{1});
          to.detail.imageaxisscalename(1:end,block{2}) = repmat({''},size(to.detail.imageaxisscalename,1),1);
          to.detail.imageaxisscalename(1:length(from.imageaxisscalename),block{2}) = from.detail.imageaxisscalename(1:length(from.imageaxisscalename),block{1});
        end
        %----------------------------------------
    end
end


%--------------------------------------------------------------
function setoffset = findlastempty(sets,append)

setoffset = 0;
switch append
  case true
    setoffset = size(sets,2)+1;
    while setoffset>1 & isempty(sets{setoffset-1})
      setoffset = setoffset-1;
    end
    setoffset = setoffset-1;  %reduce by 1 because caller expects OFFSET not actual set #
end
