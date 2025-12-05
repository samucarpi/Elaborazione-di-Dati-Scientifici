function [ssq_table,column_headers,column_format,row_header_name] = getssqtable(modl,maxpc,tabletype,wrapheaders,usehtml)
%EVRIMODEL/GETSSQTABLE - Get SSQ table for given model type.
%  INPUTS:
%    modl      - model object
%    maxpc     - maximum number of pc/lv to use in table (min([size(rawmodl.detail.ssq,1); maxpc])
%    tabletype - [ {'raw'} | 'text' | 'table' | 'cell'] type/format of table
%                returned. Type 'raw' returns 3 outputs of data, headers,
%                and column format. The 'text' type has header and values
%                in a text cell array. The 'table' type returns information
%                in a MATLAB table object. 
%    wrapheaders - [] Wrap header to specific width (in characters). 
%    usehtml   - [{true}|flase] Format headers to use HTML (for old style
%                uitable column rendering).
%
%  OUTPUTS:
%    ssq_table - table data as 'raw' numeric data with header and format
%                infor in additional outputs (below), 'text' format with
%                data and headers in cell array of text, and 'table' format
%                with data in a MATLAB table object.
%    column_headers  - Column header information, cell array of text.
%    column_format   - Format information for data, cell array of text.
%    row_header_name - Name of row column (PC/LV), text (NOT USED). 
%
%
%I/O: [ssq_table,column_headers,column_format,row_header_name] = getssqtable(modl,maxpc,tabletype)
%I/O: ssq_table = getssqtable(modl)
%I/O: ssq_table = model.ssqtable
%
%See also: ANALYSISTYPES, SSQSETUP

% TODO:
%   Maybe add optional "Status" column, most _guifcn use this. 
%
% NOTES:
%  Most SSQ table column headers defined in _guifcn files. Move to here to
%  consolidate.
%
%  There is some duplicated functionality below in the switch case
%  statement. Refactor at some point. 
%
% FIXME:
%   Q Figure out how to manage "current" column. 
%   A This will be done in _guifcn because information required is in GUI.
%   
%   Q Move header info into model? 
%   A Yes, reformat SSQ information into substruct:
%       model.ssq.xblock_variance_pc 
%       model.ssq.xblock_variance_cum
%
%   Q Maybe leave some SSQ code in _guifcn when it's really unique like ANN?
%   A Ended up moving ANN ssq table code to this function. 


ssq_table       = [];
column_headers  = [];
column_format   = [];
row_header_name = 'PC';%Not used

if nargin<2 
  maxpc = [];
end

if nargin<3
  if nargout>1
    tabletype = 'raw';
  else
    tabletype = 'table';
  end
end
if nargin<4
  wrapheaders = [];
end

if nargin<5
  usehtml = false;
end

if isempty(maxpc)
  %Pull from subsref code.
  S.type = '.';
  S.subs = 'pcs';
  maxpc = subsref(modl,S);
end

[ssq_table, column_headers, column_format] = gettabeldata(modl,maxpc);
if ~isempty(wrapheaders) && ~strcmpi(tabletype,'text')
  %Wrapp headers for better fit in tables with narrow data fields. 
  column_headers = wrapheadertxt(column_headers,wrapheaders,true);
end


switch tabletype
  case 'table'
    ssq_table = cell2table(ssq_table,"VariableNames",column_headers);
  case 'text'
    ssq_table = [column_headers;ssq_table];
    ssq_table =cell2str(ssq_table,'    ');
  case 'cell'
    ssq_table = [column_headers;ssq_table];
end

end

% --------------------------------------------------------------------
function [tbldata, column_headers, column_format] = gettabeldata(modl,maxpc)
%Get raw ssq data.
%
%FIXME: column_format probably not needed anymore if we get rid of java
%table.
%FIXME: row_header_name, name of index number on left, isn't used but is an
%input to ssqsetup.m. 

tbldata = {};
column_headers = {};
column_format = {};
modl_type = lower(modl.content.modeltype);


%TODO: Move this info to property in model.
getrmsec = false;
if ismember(modl_type,{'pca' 'pls' 'pcr' 'mlr' 'lregda' 'cls' 'lwr' 'npls' 'pls'})
  %Add RMSEC/V columns to SSQ table for these models based on existing code
  %in reg_guifcn and pca_guifcn.
  getrmsec = true;
end

%Get/create main SSQ table
switch modl_type
  case {'cluster' 'knn' 'lregda' 'mlr' 'svm' 'svmda' 'tsne' 'umap' 'xgb' 'xgbda'}
    %No SSQ Table
    return
  case {'ann' 'annda' 'anndl' 'anndlda'}
    %Get options and settings.
    opts     = modl.content.detail.options;
    if ismember(modl_type,{'ann' 'annda'})
      numnodes = opts.nhid1;
    else
      %anndl
      numnodes = getanndlnhidone(modl);
    end

    try
      myfmt = '%0.5g';
      ev = ploteigen(modl); %search Eigenvalues plot for information to include
      toadd = find(~cellfun('isempty',regexp(str2cell(ev.label{2}),'^RMSEC ')));%Get SEC and SECV
      toadd = [toadd; find(~cellfun('isempty',regexp(str2cell(ev.label{2}),'^RMSECV')))];%Get SEP
      toadd = [toadd; find(~cellfun('isempty',regexp(str2cell(ev.label{2}),'^RMSEP')))];%Get SEP
    catch
      %errors during ploteigen should NOT keep the rest of the code from
      %running (would cause serious issues in GUI status)
      %HOWEVER: we are NOT resetting the lasterror value because we want to be
      %able to catch the error during unit testing, so no lasterror(le) here!
      ev = [];
      toadd = [];
    end

    if ~isempty(toadd)
      for addind = 1:length(toadd);
        addfld = toadd(addind);
        val    = ev.data(:,addfld);
        tbldata(:,addind) = num2cell(val);

        column_headers{addind} = ev.label{2}(addfld,:);
        column_format{addind} = myfmt;
      end
    else
      %Grab rmsec directly from model.
      tbldata(numnodes,1) = num2cell(modl.detail.rmsec(end));
      column_headers{1} = 'RMSEC Level';
      column_format{1} = myfmt;
    end
  case {'asca' 'mlsca'}
    %Create data.
    termlbls = str2cell(modl.content.detail.label{2,2,1});
    modincd  = modl.content.detail.includ{2,2};
    % Alternative to avoid empty termlbls:
    if isempty(termlbls) | length(termlbls)<max(modincd)
      termlbls = modl.content.detail.effectnames(2:(length(modincd)+1));
    else
      termlbls = termlbls(modincd);
    end

    if strcmpi(modl_type,'mlsca')
      termlbls{end+1} = 'Within';
    end

    for i = 1:length(termlbls)
      tbldata{i,1} = termlbls{i};
      tbldata{i,2} = size(modl.content.submodel{i}.content.loads{1},2);
      thisssq = modl.content.submodel{i}.content.detail.ssq;
      if ~isempty(thisssq)
      tbldata{i,3} = sum(thisssq(:,2));
      end
      tbldata{i,4} = modl.content.detail.effects(i+1);
      if isfieldcheck('modl.detail.pvalues',modl) &  length(modl.content.detail.pvalues)>=i
        tbldata{i,5} = modl.content.detail.pvalues(i);
      end
    end

    mncnfct = modl.content.detail.effects(1);
    if ~isempty(mncnfct)
      tbldata{i+1,1} = 'Mean';
      tbldata{i+1,4} = mncnfct;
    end

    if strcmpi(modl_type,'asca')
      %Residuals are in MLSCA error so only calculate for ASCA.
      rsdls = modl.content.detail.effects(end);
      if ~isempty(rsdls)
        tbldata{i+2,1} = 'Residuals';
        tbldata{i+2,4} = rsdls;
      end
    end

    if strcmpi(modl_type,'asca')
      column_headers = {'Term' 'PCs' 'Cum Eigen Val' 'Effect'};
      column_format = {'%s' '%i' '%6.2f' '%6.2f'};
      if isfieldcheck('modl.detail.pvalues',modl) &  length(modl.content.detail.pvalues)>=i
        column_headers{end+1} = 'P-value';
        column_format{end+1} = '%5.4f';
      end
    else
      column_headers = {'Term' 'PCs' 'Cum Eigen Val' 'Effect'};
      column_format = {'%s' '%i' '%6.2f' '%6.2f'};
    end
  case 'cls'
      column_headers = {'Fit (%Model)' 'Fit (%X)' 'Fit Cumulative (%X)'};
      row_header_name = 'PC';
      column_format = {'%6.2f' '%6.2f' '%6.2f'};
      tbldata = getssqfield(modl,maxpc);
  case 'lwr'
      column_headers = {'% Variance This LV' '% Variance Cumulative'};
      column_format = {'%6.2f' '%6.2f'};
      row_header_name = 'LV';
      tbldata = getssqfield(modl,maxpc);
      tbldata = tbldata(:,[1 2]);
  case {'mcr' 'purity' 'als_sit'}
    column_headers = {'Fit (%Model)' 'Fit (%X)' 'Fit Cumulative (%X)'};
    row_header_name = 'PC';
    column_format = {'%6.2f' '%6.2f' '%6.2f'};
    tbldata = getssqfield(modl,maxpc);
  case {'npls' 'pls' 'plsda' 'lda' 'pcr'}
    row_header_name = 'LV';
    column_format = {'%6.2f' '%6.2f' '%6.2f' '%6.2f'};
    if strcmpi(modl_type,'pcr')
      row_header_name = 'PC';
      column_headers = {'X-Block PC' 'X-BLock Cumulative' 'Y-Block PC' 'y-Block Cumulative' };
    elseif strcmpi(modl_type, 'lda')
      column_headers = {'Eigenvalue' 'X-Block LV' 'X-BLock Cumulative'};
      column_format = {'%6.2f' '%6.2f' '%6.2f'};
    else
      column_headers = {'X-Block LV' 'X-BLock Cumulative' 'Y-Block LV' 'Y-Block Cumulative LV'};
    end
    tbldata = getssqfield(modl,maxpc);

    try
      ev = ploteigen(modl); %search Eigenvalues plot for information to include
      myfmt = '%2.3f';
    catch
      %errors during ploteigen should NOT keep the rest of the code from
      %running (would cause serious issues in GUI status)
      %HOWEVER: we are NOT resetting the lasterror value because we want to be
      %able to catch the error during unit testing, so no lasterror(le) here!
      ev = [];
      toadd = [];
    end

    if ~isempty(ev)
      if ismember(modl_type,{'plsda' 'lda'})
        toadd = find(~cellfun('isempty',regexp(str2cell(ev.label{2}),'^CV Classification Error')));
        if ~isempty(toadd) & ( length(toadd)<=3 | length(toadd)>6 )
          %one or two classes OR >5 classes - show average only
          toadd = toadd(end);  %ONLY the average
          ev.label{2}{toadd} = 'CV Class Err Ave';  %use this label instead of DSO label
          if ~strcmpi(modl_type, 'lda')
            nsamp = length(modl.content.detail.includ{1});  %note: used this instead of datasource because this accounts for only MODELED samples if groups used
            samps = (ev.data(:,toadd)*nsamp);
            ev = [ev floor(nsamp-samps)];
            ev.label{2}{size(ev,2)} = 'Est. Samp. Correct';
            toadd = [toadd size(ev,2)];
          end
        elseif ~isempty(toadd)
          %multi-class...
          toadd = toadd(1:end-1);  %all but the last (average)
          for j=toadd(:)'
            ev.label{2}{j} = regexprep(ev.label{2}(j,:),'CV Classification Error','CV Class Err');
          end
        end
      else
        %other methods - add RMSECV
        myfmt = '%0.5g';
        toadd = find(~cellfun('isempty',regexp(str2cell(ev.label{2}),'^RMSECV')));
        getrmsec = false;%Not sure if this works in all cases but causes issue with pls2 (adds CV column but it's not correct average).
      end
    end

    if ~isempty(toadd) & ~isempty(ev)
      for addind = 1:length(toadd)
        addfld = toadd(addind);
        rng1 = 1:min(size(ev,1), maxpc);
        val    = ev.data(rng1,addfld);
        tbldata(rng1,end+1) = num2cell(val);

        column_headers{end+1} = ev.label{2}(addfld,:);
        column_format{end+1} = myfmt;
      end
    %     end
    %     elseif ismember(modl_type,{'plsda'})
    %       %Grab rmsec directly from model.
    %       tbldata(numnodes,1) = num2cell(modl.content.detail.rmsec(end));
    %       column_headers{1} = 'RMSEC Level';
    %       column_format{1} = myfmt;
    end
  case {'parafac' 'parafac2'}
    column_headers = {'Fit(% X)' 'Fit(% Model)' 'Unique Fit(% X)' 'Unique Fit(% Model)'};
    row_header_name = 'Comp';
    column_format = {'%6.2f' '%6.2f' '%6.2f' '%6.2f' ''};
    tbldata = num2cell(modl.content.detail.ssq.percomponent.data(:,[2 3 5 6]));
  case 'simca'
    column_headers = {'Total Samples' 'Modeled Class(es)'};
    row_header_name = 'Sub-Model';
    column_format = {'%5i' '%s'};

    classset = modl.content.detail.options.classset;
    tbldata = {};
    for j=1:length(modl.content.submodel);
      classes = num2str(unique(modl.content.submodel{j}.content.detail.class{1,1,classset}(modl.content.submodel{j}.content.detail.includ{1})));
      tbldata{j,1} = length(modl.content.submodel{j}.content.detail.includ{1});
      tbldata{j,2} = classes;
    end
  case ''
    %From _gui
  otherwise
    %PCA, MPCA, BATCHMATURITY
    column_headers = {'Eigenvalue of Cov(X)' '% Variance This PC' '% Variance Cumulative'};
    column_format = {'%4.2e' '%6.2f' '%6.2f'};
    tbldata = getssqfield(modl,maxpc);
end

%Get rmsec
try %No fatal error if this doesn't work.
  if getrmsec
    [tbldata, column_headers,column_format] = getrmsefield(modl,tbldata,column_headers,column_format);
  end
end

end

% --------------------------------------------------------------------
function tbldata = getssqfield(modl,maxpc)
%Get data from ssq field. Lots of models use this field but not all.

if strcmpi(lower(modl.content.modeltype),'batchmaturity')
  tbldata = modl.content.submodelpca.content.detail.ssq;
else
  tbldata = modl.content.detail.ssq;
end
tbldata = tbldata(1:maxpc,:);
tbldata = num2cell(tbldata);
tbldata = tbldata(:,2:end);
end

% --------------------------------------------------------------------
function [tbldata, column_headers,column_format] = getrmsefield(modl,tbldata,column_headers,column_format)
%Get data from ssq field. Lots of models use this field but not all.
%Get rmsec
try %No fatal error if this doesn't work.
  for addfld = {'rmsec' 'rmsecv'}
    if isfield(modl.content.detail,addfld{:}) & ~isempty(modl.content.detail.(addfld{:}))
      val = modl.content.detail.(addfld{:});
      m = min(size(tbldata,1),length(val));

      %add new column before that one
      tbldata(1:m,end+1) = num2cell(val(1:m)');
      %add header
      column_headers{end+1} = upper(addfld{:});
      %add format
      column_format{end+1} = '% 8.4g';
    end
  end
end
end

% --------------------------------------------------------------------
function [column_headers] = wrapheadertxt(column_headers,wraplength,usehtml)
%Wrap header text. Used to better fit in table columns.

temptxt = {};
for i = 1:length(column_headers)
  thistxt = textwrap(column_headers(i),wraplength);
  if usehtml
    mylinebreak = '<br>';
  else
    mylinebreak = '\n';
  end
  thistxt = sprintf(['%s' mylinebreak],thistxt{:});
  
  if usehtml
    thistxt = ['<html>' thistxt(1:end-4) '</html>'];
  else
    %Remove last char.
    thistxt = thistxt(1:end-1);
  end
  temptxt{i} = thistxt;
end
column_headers = temptxt;
end

% --------------------------------------------------------------------
function test
%Expected columns in SSQ table for given modle. These columns used to be
%defined in _guifcn:
%  ann_guifcn
%  anndl_guifcn
%  asca_guifcn
%  batchmaturity_guifcn
%  cls_guifcn
%  cluster_guifcn
%  knn_guifcn
%  lreg_guifcn
%  lwr_guifcn
%  mcr_guifcn
%  mpca_guifcn
%  npls_guifcn
%  parafac_guifcn
%  pca_guifcn
%  plsda_guifcn
%  purity_guifcn
%  reg_guifcn
%  simca_guifcn
%  svm_guifcn
%  tsne_guifcn
%  umap_guifcn
%  xgb_guifcn

methods = analysistypes;
%method_guifcns = unique(methods(:,3));
method_types = unique(methods(:,1));
for i = 1:length(method_types)

  if strcmp(method_types,'xgb')
    continue
  end

  disp(method_types{i})
  mm = getdemomodel(method_types{i});
  if isempty(mm) || isstruct(mm)&&isfield(mm,'dist')
    continue
  end
  [ssqtbl] = getssqtable(mm);
  % [ssqtbl,clbls,clfmt] = getssqtable(mm,3);
  % [ssqtbl] = getssqtable(mm,3,'table');
  % [ssqtbl] = getssqtable(mm,3,'text');
end

%PCA
model = getdemomodel('pca');
[ssqtbl,clbls,clfmt] = getssqtable(model,3);
[ssqtbl,clbls,clfmt] = getssqtable(model,3,'cell',true)
end





