function varargout = clsti(varargin)
%CLSTI Temperature Interpolated Classical Least Squares
%  CLSTI interpolates a test temperature from a give set of pure spectra
%  INPUTS:
%        To build a model:
%        files  = cell array of filenames to import and use to build CLTI
%                 model, or
%        DataSets = cell array of DataSet Objects of pure component spectra
%                   with corresponding pure temperatures in axisscale{1,1}
%        
%        To predict:
%        x = DataSet Object of test spectra with temperatures in
%        axisscale{1,1}, or;
%        temps = DataSet Object or vector of temperatures for test spectra               
%        model = CLSTI model object
%
%  OUTPUT:
%     model = standard model structure containing the CLSTI model (See MODELSTRUCT)
%      pred = structure array with predictions
%
%I/O: model = clsti(files);         %builds CLSTI model (calibration step)
%I/O: model = clsti(files,options); %builds CLSTI model (calibration step)
%I/O: pred  = clsti(x,temps,model);%makes predictions with a new data and temperatures
%I/O: pred  = clsti(x,temps,model,options);%makes predictions with a new data and temperatures
%
%See also: CLS, PCR, PLS

%Copyright Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Start Input
if nargin==0  % LAUNCH GUI
  analysis clsti
  return
end
if ischar(varargin{1}) %Help, Demo, Options
  options = [];
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'final';  %Governs plots to make
  options.preprocessing = {[] []};  %See preprocess
  options.blockdetails  = 'standard';  %level of details
  options.definitions   = @optiondefs;
  
  if nargout==0
    if strcmp(varargin{1},'builder')
      clsti_gui;
    else
      evriio(mfilename,varargin{1},options); 
    end
  else
    varargout{1} = evriio(mfilename,varargin{1},options); 
  end
  return;
  
end

%A) Check Options Input
predictionMode = 0;    %default is calibrate mode

%NOTE: the following code will always leave varargin{3} empty because we
%infer this value from the y-block. (ncomp isn't an input option for cls)
switch nargin
  case 1 %one input
    % (filenames)   calibrate
    varargin = {varargin{1},[],[],[]};
  case 2  %two inputs
    % (x,model)     predict, temps assummed to be in x.axisscale{1,1}
    % (filenames,options)   calibrate
    if ismodel(varargin{2})
      %model
      varargin = {varargin{1},[],[],varargin{2}};
    elseif isa(varargin{2},'struct')
      %options
      varargin = {varargin{1},[],varargin{2},[]};
    end
    
  case 3  %three inputs
    % (x,temps,model)    predict
    % (x,model,options)   predict, temps assummed to be in x.axisscale{1,1}
    
    if ismodel(varargin{2});
      % (x,model,options)
      varargin = {varargin{1},[],varargin{3},varargin{2}};
    else
      % (x,temps,model)
      varargin = {varargin{1},varargin{2},[],varargin{3}};
    end
    
  case 4   %four inputs
    % (x,temps,model,options)
    varargin = {varargin{1},varargin{2},varargin{4},varargin{3}};
    
  otherwise
    evrierrordlg('Unrecognized input format');
    return;
    
end
%At this point, varargin will be 4 elements:
%  {x, temps, options, model}
% where temps, options, and model can all be empty

options = reconopts(varargin{3},clsti('options'));


if iscell(varargin{1})
  %passed cell array for definition files
  predictionMode = 0;
  myPureCompDSOs = cell(1,length(varargin{1}));
  myPureCompNames = cell(1,length(varargin{1}));
  
  for i = 1:length(varargin{1})
    myCellInput = varargin{1};
    if ischar(myCellInput{i})
      %check file type to decide how to read it
      [FilePath,FileName,FileExt] = fileparts(myCellInput{i});
      %read file in as a table
      switch FileExt
        case {'.xlsx', '.xls'}
          d_table = readtable(myCellInput{i},'NumHeaderLines',0);
        case {'.csv', '.txt'}
          delToUse = ',';
          d_table = readtable(myCellInput{i}, 'Delimiter', delToUse, 'FileType', 'text', 'NumHeaderLines', 0);
        otherwise
          evrierrordlg('Incorrect file type provided. Definition file must be .XLSX, .CSV, or .TXT.','Unsupported File Type');
          varargout{1} = [];
          return;
      end
      
      if size(d_table,1) < 2
        evrierrordlg('Each pure component must have at least two included samples.','Calibration Error');
        varargout{1} = [];
        return;
      end
      
      %get the variable names from the table
      d_cols = d_table.Properties.VariableNames;
      
      filenames = insertBefore(d_table.(d_cols{1}),d_table.(d_cols{1}),FilePath);
      try
        myDSO = autoimport(filenames);
      catch
        evrierrordlg('Error during importing. Check CLSTI data file.','Data Import Error');
        varargout{1} = [];
        return;
      end
      
      currentAxisscale = myDSO.axisscale(1);
      currentAxisscaleName = myDSO.axisscalename(1);
      
      myDSO.axisscale{1,1} =  d_table.(d_cols{2});
      myDSO.axisscalename{1,1} =  'Temperature';
      for j = 1:length(currentAxisscale)
        myDSO.axisscale{1,j+1} = currentAxisscale{1,j};
        myDSO.axisscalename{1,j+1} = currentAxisscaleName{1,j};
      end
      myPureCompDSOs{i} = myDSO;
      myPureCompNames{i} = d_cols{1};
      
    elseif isdataset(myCellInput{i})
      %passed a DSO with pure component spectra as data and temps in
      %axisscale{1,1}
      
      thisDSO = myCellInput{i};
      if length(thisDSO.include{1}) < 2
        evrierrordlg('Each pure component must have at least two included samples.','Calibration Error');
        varargout{1} = [];
        return;
      end
      myPureCompDSOs{i} = thisDSO;
      thisPureName = thisDSO.labelname{1};
      if ~isempty(thisPureName)
        myPureCompNames{i} = thisPureName;
      else
        myPureCompNames{i} = ['Pure Component ' num2str(i)];
      end
    else
      evrierrordlg('Incorrect inputs for building a CLSTI model.');
      varargout{1} = [];
      return
    end
  end
    
  model = evrimodel('clsti');
  myDSO = myPureCompDSOs{1};
  nvars  = length(myDSO.axisscale{2,1});
  s_randData= dataset(rand(4,nvars));
  s_randData.include{2} = myDSO.include{2};
  %need this so the model thinks it's calibrated and thus can be
  %applied
  model.datasource{1} = getdatasource(s_randData);
  model.date = date;
  model.time = clock;
  model.detail.axisscale{2,1} = myDSO.axisscale{2,1};
  model.detail.clsti.refData =  myPureCompDSOs;
  model.detail.clsti.componentNames = myPureCompNames;
  model.detail.options = options;
  model.include{2} = myDSO.include{2};
  
  varargout{1} = model;
end

if ismodel(varargin{4})
  %have a model
  predictionMode = 1;
  newX = varargin{1};
  model = varargin{4};
  if isempty(varargin{2})
    %no temps, assume in axisscale{1,1}
    newT = newX.axisscale{1,1};
  else
    newT = varargin{2};
    if ~isdataset(newT)
      newT = dataset(newT);
    end
    if isscalar(newT)
      newT = repmat(newT,size(newX,1),1);
    elseif isempty(newT)
      %empty test temp so try and grab from test DSO
      newT = newX.axisscale{1,1};
    else
      if ~isvector(newT.data)
        evrierrordlg(['Input Temps must be a vector of temps. Input has ',int2str(size(newT.data),2),' columns.'])
        return;
      end
      if size(newX.data,1)~=size(newT.data,1)
        evrierrordlg('Number of samples in X and Y must be equal.')
        return;
      end
      i  = intersect(newX.includ{1},newT.includ{1});
      if ( length(i)~=length(newX.includ{1,1}) | length(i)~=length(newT.includ{1,1}) )
        if (strcmpi(options.display,'on')|options.display==1)
          disp('Warning: Number of samples included in X and Temps not equal.')
          disp('Using intersection of included samples.')
        end
        newX.includ{1,1} = i;
        newT.includ{1,1} = i;
      end
    end
  end
end
    
if predictionMode
  if ~strcmpi(model.modeltype,'clsti');
    error('Not a valid clsti model type');
  end
  try
    [preds,model,loads, qcon, q, t2,estError,scores] = clsti_apply(newX,newT,model,options);
  catch
    le = lasterror;
    le.message = ['Unable to apply clsti model to new data.' 10 le.message];
    rethrow(le)
  end
  
  model.modeltype = [model.modeltype '_PRED'];
  model.datasource{1} = getdatasource(newX);
  if ~isdataset(newT)
    if isrow(newT)
      newT = newT';
    end
    newT = dataset(newT);
  end
  newT = copydsfields(newX,newT,1);
  model.datasource{2} = getdatasource(newT);
  model.detail.data{2} = newT;
  model.includ{1,1} = newX.includ{1,1};
  
  model.loads{2} = loads;
  model.pred{2} = preds;
  model.tsqs{1,1} = t2;
  model.ssqresiduals{1,1} = q;
  model.detail.res{1} = qcon;
  model.loads{1} = scores;
  model.detail.esterror = estError;
  
  %Update time and date.
  model.date = date;
  model.time = clock;
  
  varargout{1} = model;
end


function [preds,model,loads, qcon, q, t2, estError,scores] = clsti_apply(newX,newT,model,options)

if size(newX.data,2)~=model.datasource{1}.size(1,2)
  error('Variables included in data do not match variables expected by model');
elseif length(newX.include{2,1})~=length(model.detail.includ{2,1}) | any(newX.include{2,1} ~= model.detail.includ{2,1})
  missing = setdiff(model.detail.includ{2,1},newX.include{2,1});
  newX.data(:,missing) = nan;  %replace expected but missing data with NaN's to force replacement
  newX.include{2,1} = model.detail.includ{2,1};
end

if mdcheck(newX.data(:,newX.include{2,1}))
  if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess" from existing model. Results may be affected by this action.'); end
  newX = replacevars(model,newX);
end

pureCompDSO = model.detail.clsti.refData{1};
if isdataset(newX)
  newX = newX.data;
end
if isdataset(newT)
  newT = newT.data;
end
s = newX;
incl = model.include{2}';

clsModel = evrimodel('cls');
clsModel.options.algorithm = 'ls';
clsModel.options.blockdetails = 'all';
sDSO = dataset(rand(length(model.detail.clsti.refData),size(pureCompDSO,2)));
sDSO.axisscale{2} = pureCompDSO.axisscale{2};
sDSO.include{2} = incl;

clsModel.x = sDSO;
clsModel = clsModel.calibrate;
myLoads = clsModel.loads{2};

%Original interpolation code from Jeremy
%var.t is pure component temps
%var.temperature is newT
%var.s is pure component spectra
% test_forLo = find(var.t<=var.temperature);
% test_forHi = find(var.t>=var.temperature);
% 
% lo=max([1 test_forLo]);
% hi=min([length(var.t) test_forHi]);
% if lo==hi
%   var.spectrum=var.s(lo,:)';
% else
%   var.spectrum=interp1(var.t(lo:hi),var.s(lo:hi,:),var.temperature)';
% end

preds = zeros(size(s,1),length(model.detail.clsti.refData));
loads = cell(1,size(s,1));
qcon = zeros(size(s,1),length(incl));
t2 = zeros(size(s,1),1);
q = zeros(size(s,1),1);
estError = zeros(size(s,1),length(model.detail.clsti.refData));

for i = 1:size(s,1)
  
  for j = 1:length(model.detail.clsti.refData)
    pureDSO= model.detail.clsti.refData{j};
    pureData = pureDSO.data;
    pureTemps = pureDSO.axisscale{1,1};
    pureDataToUse = pureData(pureDSO.include{1},:);
    pureTempsToUse = pureTemps(pureDSO.include{1});
     
    test_forLo = find(pureTempsToUse<=newT(i));
    test_forHi = find(pureTempsToUse>=newT(i));
    
    lo=max([1 test_forLo]);
    hi=min([length(pureTempsToUse) test_forHi]);
    if lo==hi
      spectrum=pureDataToUse(lo,:)';
    else
      spectrum=interp1(pureTempsToUse(lo:hi),pureDataToUse(lo:hi,:),newT(i))';
    end
    myLoads(:,j) = spectrum(incl);
  end
  clsModel.loads{2} = myLoads;
  %use function call so we can set the options
  predObj = cls(newX(i,:),clsModel, clsModel.detail.options);
  %predObj = clsModel.apply(newX(i,:));
  
  
  preds(i,:) = predObj.prediction;
  loads{i} = myLoads;
  qcon(i,:) = predObj.qcon;
  t2(i,:) = predObj.t2;
  q(i,:) = predObj.q;
  scores(i,:) = predObj.scores;
  
  estError(i,:) = clstiEstError(myLoads',q(i));
  
end


function estError = clstiEstError(myLoads,q)
ncomp = size(myLoads,1);
diagTerm = diag(inv(myLoads*myLoads'));
estError = sqrt(q./(size(myLoads,2)-ncomp) * diagTerm);

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
'preprocessing'          'Standard'       'cell(vector)'  ''                               'novice'        'Preprocessing structures. Cell 1 is preprocessing for X block, Cell 2 is preprocessing for Y block.';
'blockdetails'           'Standard'       'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = keeps only y-block, ''all'' keeps both x- and y- blocks.';
};

out = makesubops(defs);