function varargout = exportmodelamo(model,filename,xblock,yblock)
%EXPORTMODELAMO Export model to Unscrambler ASCII-MOD (AMO) File.
% Exports a PCA or PLS model to the text ASCII-MOD file format. There are
% some approximations that are mode due to differences in how PLS_Toolbox
% and Unscrambler handle things like cross-validation and some statistics,
% but the output file is a close approximation of the expected file format.
%
% This exporter does not allow preprocessing other than Mean-Centering,
% Autoscaling, or none. It also does not allow PLS2 (multi-column
% y-blocks).
%
% Note that if the model was not built using "full" block details
% (options.blockdetails = 'full' in PCA or PLS), the calibration x and y
% blocks should be passed in as inputs.
%
%INPUTS:
%   model    = standard PLS or PCA model.
%   filename = output filename (empty = prompt user for name)
%OPTIONAL INPUTS:
%   xblock   = calibration x-block data (required if model was built
%               without full block details)
%   yblock   = calibration y-block data
%
%I/O: exportmodelamo(model,filename,xblock,yblock)
%
%See Also: EXPORTMODELREGVEC, REGCON, SAVEMODELAS

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0; model = 'io'; end
if ischar(model)
  options = [];
  if nargout>0; varargout = {evriio(mfilename,model,options)}; else; evriio(mfilename,model,options); end
  return;
end

%test for valid file
if ~ismodel(model)
  error('Input is not a recognized model')
end

switch model.modeltype
  case 'PCA'
    method = 'PCA';
    nblocks = 1;
    
  case 'PLS'
    if length(model.detail.includ{2,2})>1
      %method = 'PLS2';
      error('PLS2 (multi-column y-block) models cannot be exported to this format');
    else
      method = 'PLS1';
    end
    nblocks = 2;
    if ~ismember(lower(model.detail.options.algorithm),{'nip' 'sim' 'dspls'})
      error('PLS algorithm "%s" is not supported by this export format.',model.detail.options.algorithm)
    end
    
  otherwise
    error('Only PCA or PLS models can be exported to this format');
end

%reconcile include fields with input data
include = model.detail.includ;
if nargin>2 & ~isempty(xblock)
  if isdataset(xblock)
    xblock.include{1} = include{1,1};
    xblock.include{2} = include{2,1};
    xblock = xblock.data.include;
  else
    if size(xblock,1)~=length(include{1,1})
      xblock = xblock(include{1,1},:);
    end
    if size(xblock,2)~=length(include{2,1})
      xblock = xblock(:,include{2,1});
    end
  end
elseif ~isempty(model.detail.data{1});
  xblock = model.detail.data{1};
  xblock.include{1} = include{1,1};
  xblock.include{2} = include{2,1};
  xblock = xblock.data.include;
else
  error('To export this file format, you must build it with the "block details" option set to ''full'' or pass the x-block in as an input.')
end

if nblocks==2
  if nargin>3 & ~isempty(yblock)
    if isdataset(yblock)
      yblock.include{1} = include{1,1};  %X-block samples includ!!
      yblock.include{2} = include{2,2};
      yblock = yblock.data.include;
    else
      if size(yblock,1)~=length(include{1,1})
        yblock = yblock(include{1,1},:);  %X-block samples includ!!
      end
      if size(yblock,2)~=length(include{2,2})
        yblock = yblock(:,include{2,2});
      end
    end
  else
    yblock = model.detail.data{2};
    yblock.include{1} = include{1,1};    %X-block samples includ!!
    yblock.include{2} = include{2,2};
    yblock = yblock.data.include;
  end
else
  yblock = [];
end


%get filename and open output file
if nargin<2 | isempty(filename)
  [filename,pth] = evriuiputfile({'*.AMO' 'ASCII-MOD File (*.AMO)';'*.*' 'All Files'},'Export to AMO file...',[defaultmodelname(model) '.AMO']);
  if isnumeric(filename)
    return;
  end
  filename = fullfile(pth,filename);
end


%- - - - - - - - - - - - - - - - - - - -
%gather information
xsamps  = model.datasource{1}.include_size(1);
xvars   = model.datasource{1}.include_size(2);
ncomp = size(model.loads{1,1},2);
if nblocks==1
  yvars = 0;
else
  yvars = model.datasource{2}.include_size(2);
end
if ~isempty(model.detail.cv)
  cv = 'CROSS';
  if ischar(model.detail.cv) & strcmpi(model.detail.cv,'loo')
    splits = xsamps;
  else
    splits = model.detail.split;
  end
else
  cv = 'NONE';
  splits = 0;
end

%get and check preprocessing info
ppx = model.detail.preprocessing{1};
if nblocks==2
  ppy = model.detail.preprocessing{2};
else
  ppy = [];
end
if ~isempty(ppx) & (length(ppx)>1 | ~ismember(lower(ppx.keyword),{'mean center','autoscale'}))
  error('Only models using Autoscaling, Mean Centering or no preprocessing can be exported to this format');
end
if isempty(ppx)
  ppx = {zeros(1,xvars) ones(1,xvars)};
elseif strcmpi(ppx.keyword,'Mean Center')
  ppx = {ppx.out{1} ones(1,xvars)};
elseif strcmpi(ppx.keyword,'Autoscale')
  ppx = ppx.out;
end
if ~isempty(ppy) & (length(ppy)>1 | ~ismember(lower(ppy.keyword),{'mean center','autoscale'}))
  error('Only models using Autoscaling, Mean Centering or no preprocessing can be exported to this format');
end
if isempty(ppy)
  ppy = {0 1};
elseif strcmpi(ppy.keyword,'Mean Center')
  ppy = {ppy.out{1} 1};
elseif strcmpi(ppy.keyword,'Autoscale')
  ppy = ppy.out;
else
  error('Only models using Autoscaling, Mean Centering or no preprocessing can be exported to this format');
end
centering = 'YES';  %just always say this

%identify which items we need
switch model.modeltype
  case 'PCA'
    matrices = {
      'xWeight'         %X-weights
      'xCent'           %Model center X
      'ResXValTot'      %Total residual Xvariance, validation
      'ResXCalVar'      %X-variables residual variance, calibration
      'ResXValVar'      %X-variables residual variance, validation
      'ResXCalSamp'     %Residual Sample X-variance, calibration
      'Pax'             %Variance for Xloadings?
      'Wax'             %Loading weights
      'SquSum'          %Square sums
      'TaiCalSDev'      %Calibration Scores Standard dev?
      'xCalMean'        %X calibration mean?
      'xCalSDev'        %X calibration standard dev?
      'xCal'            %X calibration?
      'Tai'             %Scores?
      };
    
  case 'PLS'
    
    matrices = {
      'B'               %Regression coefficients (in original units)
      'B0'              %Regression intercept (in original units)
      'xWeight'         %X-weights
      'yWeight'         %Y-weights
      'xCent'           %Model center X
      'yCent'           %Model center Y
      'ResXValTot'      %Total residual Xvariance, validation
      'ResXCalVar'      %X-variables residual variance, calibration
      'ResXValVar'      %X-variables residual variance, validation
      'ResYValVar'
      'ResXCalSamp'     %Residual Sample X-variance, calibration
      'Pax'             %Variance for Xloadings?
      'Wax'             %Loading weights
      'Qay'             %Y-loadings
      'SquSum'          %Square sums
      'HiCalMean'       %Mean leverage of calibr. Samples
      'ExtraVal'        %Extra validation
      'RMSECal'         %RMSEC
      'TaiCalSDev'      %Calibration Scores Standard dev
      'xCalMean'        %X calibration mean
      'xCalSDev'        %X calibration standard dev
      'xCal'            %X calibration
      'yCalMean'        %Y calibration mean
      'yCalSDev'        %Y calibration standard dev
      'yCal'            %Y calibration
      'Tai'             %Scores?
      };
end

%- - - - - - - - - - - - - - - - - - - -
%start calculating matrices
for j=1:length(matrices)
  switch matrices{j}
    case 'B'               %Regression vector
      [val,junk] = regcon(model);
      %         val = [nan(ncomp-1,size(val,2));val];
      val = repmat(val,ncomp,1);
      
    case 'B0'               %Regression intercept
      [junk,val] = regcon(model);
      %         val = [nan(ncomp-1,size(val,2));val];
      val = repmat(val,ncomp,1);
      
    case 'xWeight'         %X-weights
      val = ppx{2};
      
    case 'yWeight'        %Y-weights
      val = ppy{2};
      
    case 'xCent'           %Model center X
      val = ppx{1};
      
    case 'yCent'
      val = ppy{1};
      
    case 'ResXCalVar'      %X-variables residual variance, calibration
      %This is the Q after each PC has been removed (last is just the Q we
      %usually store, the others are just the SSQ(tp) for each component
      %added to the Q, serially)
      ssqr = model.ssqresiduals{2}';
      T = model.loads{1}(include{1},:);
      P = model.loads{2}';
      val = [diag(sum(T.^2))*(P.^2);ssqr']/xsamps;  %Qs for each component
      val = flipud(cumsum(flipud(val)));  %cumsum to get aggregated Qs
      
    case 'ResXValTot'      %Total residual Xvariance, validation
      %NOTE: duplicating what we did above. HOWVER, this is NOT exactly
      %what is supposed to be done. This is really expecting the cumulative
      %Q for cross-validation (or validation). But since we calculate
      %RMSECV differently than Unscrambler, we can't use our calculations
      %to get the same thing
      ssqr = model.ssqresiduals{2}';
      T = model.loads{1}(include{1},:);
      P = model.loads{2}';
      val = [diag(sum(T.^2))*(P.^2);ssqr']/xsamps;
      val = flipud(cumsum(flipud(val)));
      val = mean(val,2);
      
    case 'ResXValVar'      %X-variables residual variance, validation
      %NOTE: see note above for ResXValTot
      ssqr = model.ssqresiduals{2}';
      T = model.loads{1}(include{1},:);
      P = model.loads{2}';
      val = [diag(sum(T.^2))*(P.^2);ssqr']/xsamps;
      val = flipud(cumsum(flipud(val)));
      
    case 'ResXCalSamp'     %Residual Sample X-variance, calibration
      ssqr = model.ssqresiduals{1}(include{1})';
      T = model.loads{1}(include{1},:);
      val = [(T.^2) ssqr']'/xvars;
      val = flipud(cumsum(flipud(val)));
      
    case 'Pax'             %Xloadings
      val = model.loads{2}';
      
    case 'Wax'             %Loading weights
      val = model.loads{2}';
      
    case 'SquSum'          %Square sums
      %SquSumT, SquSumW, SquSumP, SquSumQ, MinTai, MaxTai
      val = [
        model.detail.ssq(1:ncomp,2)'*xsamps;
        ones(1,ncomp)
        ones(1,ncomp)
        zeros(1,ncomp)
        min(model.loads{1})
        max(model.loads{1})
        ];
      
    case 'TaiCalSDev'      %Calibration Scores Standard dev
      val = std(model.loads{1})';
      
    case 'Tai'             %Scores?
      val = model.loads{1}(model.detail.includ{1},:)';
      
    case 'xCalMean'        %X calibration mean?
      val = mean(xblock);
      
    case 'xCalSDev'        %X calibration standard dev?
      val = std(xblock);
      
    case 'xCal'            %X calibration?
      val = xblock;
      
    case 'yCalMean'        %X calibration mean?
      val = mean(yblock);
      
    case 'yCalSDev'        %X calibration standard dev?
      val = std(yblock);
      
    case 'yCal'            %X calibration?
      val = yblock;
      
    case 'ResYValVar'      %Y-variables residual variance, validation
      val = [var(yblock) model.detail.rmsecv(1:ncomp).^2]';
      
    case 'HiCalMean'       %Mean leverage of calibr. Samples (!!!)
      val = ones(ncomp,1)*mean(model.detail.leverage(include{1}));
      
    case 'ExtraVal'        %Extra validation (!!!)
      %     RMSEP,      SEP,     Bias,    Slope,   Offset,     Corr,  SEPcorr,  ICM-Slope, ICM-Offset
      se  = model.detail.rmsecv(1:ncomp)';
      fit = [];
      for nc = 1:ncomp;
        fit(nc,1:2) = polyfit(yblock,squeeze(model.detail.cvpred(include{1,1},:,nc)),1);
      end
      cc = corrcoef([squeeze(model.detail.cvpred(include{1,1},:,1:ncomp)) yblock]);
      %     RMSEP,  SEP,      Bias,                    Slope,   Offset,     Corr,            SEPcorr,  ICM-Slope, ICM-Offset
      val = [ se     se  model.detail.cvbias(1:ncomp)'  fit                 cc(1:end-1,end)  nan(ncomp,3)];
      
    case 'RMSECal'         %RMSEC
      val = model.detail.rmsec(1:ncomp)';
      
    case 'Qay'             %Y-loadings
      val = model.loads{2,2}';
      
    otherwise
      error('Unrecognized matrix "%s"',matrices{j})
      
  end
  if ~isempty(val)
    toshow.(matrices{j}) = val;
  end
end
matrices = fieldnames(toshow);  %get new list (based on the non-empty ones we found)

try
  %- - - - - - - - - - - - - - - - - - - -
  %start writing header
  [fid,msg] = fopen(filename,'w');
  if fid<0;
    error(msg);
  end
  
  fprintf(fid,'TYPE=FULL\n');
  fprintf(fid,'VERSION=1\n');
  fprintf(fid,'MODELNAME=%s\n',uniquename(model));
  fprintf(fid,'MODELDATE=%s\n',datestr(model.time,31));
  fprintf(fid,'CREATOR=%s\n',model.author);
  fprintf(fid,'METHOD=%s\n',method);
  fprintf(fid,'CALDATA=%s\n',model.datasource{1}.uniqueid);          %File of data source
  fprintf(fid,'SAMPLES=%i\n',xsamps);        %Number of X samples
  fprintf(fid,'XVARS=%i\n',xvars);         %Number of X variables used when making the model
  
  fprintf(fid,'XTOTVARS=%i\n',xvars);         %could be used to indicate number of INCLUDED variables but we're pre-excluding
  fprintf(fid,'XKEEPOUTS=""\n');              %could be used to show excluded vars
  fprintf(fid,'SELECTEDXVARS="1-%i"\n',xvars);  %could be used to indicate included vars, but we aren't bothering
  
  fprintf(fid,'YVARS=%i\n',yvars);           %Number of Y variables used when making the model
  fprintf(fid,'VALIDATION=%s\n',cv);  %Type of validation used (NONE,LEVCORR,TESTSET,CROSS)
  fprintf(fid,'COMPONENTS=%i\n',ncomp);      %Number of components present in the ASCII-MOD file
  fprintf(fid,'SUGGESTED=%i\n',choosecomp(model));       %Suggested number of components to use (may not be on the ASCIIMOD file)
  fprintf(fid,'CENTERING=%s\n',centering);     %Was centering used?
  fprintf(fid,'CALSAMPLES=%i\n',model.datasource{1}.include_size(1));     %Number of calibration samples
  fprintf(fid,'TESTSAMPLES=%i\n',0);     %Number of test samples
  
  fprintf(fid,'NUMCVS=%i\n',splits);         %Number of Cross Validation Segments
  
  fprintf(fid,'NUMPRETREATVARS=%i\n',xvars);         %Number of X variables pretreated
  
  fprintf(fid,'NUMTRANS=0\n');
  fprintf(fid,'NUMINSTRPAR=0\n');
  
  %print list of matrices to file
  fprintf(fid,'MATRICES=%i\n',length(matrices));
  fprintf(fid,'"%s"\n',matrices{:});
  
  if length(model.datasource)>1;
    %add YvarNames
    fprintf(fid,'%%YvarNames\n');
    lbls = getlables(model,2);
    fprintf(fid,'%s\n',lbls{:});
  end
  
  %add XvarNames
  fprintf(fid,'%%XvarNames\n');
  lbls = getlables(model,1);
  fprintf(fid,'%s\n',lbls{:});
  
  %store the actual matrices
  for j=1:length(matrices)
    printvals(fid,matrices{j},toshow.(matrices{j}));
  end
  
catch
  le = lasterror;
  fclose(fid);
  rethrow(le);
end

fclose(fid);


%-----------------------------------------------------
function printvals(fid,field,vals)

%display header
fprintf(fid,'%%% -22s %i      %i\n',field,size(vals));
fmt = '%8.8E';
for row=1:size(vals,1);
  %display each row
  v = vals(row,:);
  mex = ceil(log10(abs(v))+eps);
  mex(v==0) = 0;
  str = sprintf(' %-8.7fE%03i ',[v./10.^(mex);mex]);
  str = regexprep(str,'E0','E+');
  str = regexprep(str,' -0',' -');
  str = regexprep(str,'NaN     ENaN','            m');
  fprintf(fid,'%s',wrap80(str));
end

%------------------------------------------------------
function outstr = wrap80(str)

outstr = {};
while ~isempty(str) & ~all(str==32)
  pos = max(find(str(1:min(80,end))==32));
  outstr{end+1} = str(1:pos-1);
  str = str(pos:end);
end
outstr = sprintf('% -80s\n',outstr{:});

%------------------------------------------------------
function   lbls = getlables(model,block)

include = model.detail.includ;
if ~isempty(model.detail.label{2,block})
  lbls = str2cell(model.detail.label{2,block}(include{2,block},:));
  lbls = sprintf('"%s"\n',lbls{:});
elseif ~isempty(model.detail.axisscale{2,block})
  lbls = model.detail.axisscale{2,block}(include{2,block});
  lbls = sprintf('"%g"\n',lbls);
else
  lbls = include{2,block};
  lbls = sprintf('"%i"\n',lbls);
end
lbls = str2cell(lbls);
lbls = sprintf('% -17s \n',lbls{:});
lf = find(lbls==10);
lf(4:4:end) = [];  %keep every 4th linefeed
lbls(lf)=32;
lbls = strtrim(str2cell(lbls));
