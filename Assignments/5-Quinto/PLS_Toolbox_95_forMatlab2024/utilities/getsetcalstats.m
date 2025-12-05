function [ success ] = getsetcalstats(modl,handles,maxlv)
% GETRMSEC extracts the RMSEC values from several models and updates the
% main model.

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

vld_mdls = {'PLS','PCR','NPLS','MLR','PLSDA'};
[cvmode,cvlv,cvsplit,cviter] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
if nargin>2
  cvlv = maxlv;% fix for low rank data
end
try
cvlv = min([maxlv, modl.datasource{1}.include_size]);
end
try
  % Initilizations (get model, options, X-Block & Y-Block)
  if isempty(modl)
    modl = analysis('getobjdata','model',handles);
  end
  
  if ismember(modl.modeltype,vld_mdls)
    opts = modl.detail.options;
    if strcmpi(modl.modeltype,'LWR')
      npts = modl.detail.npts;
    end
    
    if isfield(opts,'rawmodel') % rawmodel field must be removed
      opts=rmfield(opts,'rawmodel');
    end
    
    xb_cal = analysis('getobjdata','xblock',handles);
    if isempty(xb_cal)
      xb_cal = modl.datasource{1};
      if isempty(xb_cal) | ~(isa(xb_cal,'dataset')) % no X-Block? can't calc RMSEC.
        success=false;
        return;
      end
    end
    
    yb_cal = analysis('getobjdata','yblock',handles);
    if isempty(yb_cal) & length(modl.datasource)>1
      yb_cal = modl.datasource{2}; %if empty, don't use it.
      if ~(isa(yb_cal,'dataset'))
         yb_cal=[];
      end
        
      if isempty(yb_cal) & strcmpi(modl.modeltype,'PLSDA')
        %no y-block, check for modelgroups from user selecting items to group
         modelgroups = getappdata(findobj(handles.analysis,'tag','choosegrps'),'modelgroups');
         if ~isempty(modelgroups)
           yb_cal = modelgroups;
         else
           yb_cal = {};  %no groups, no y, use classes as-is
         end
      end
    end
    
    % Figure out which models need to be built to calclate the values
    tocalc = true(1,cvlv);
    for i=1:size(modl.detail.rmsec,2)
      for j=1:size(modl.detail.rmsec,1)
        if ~(isempty(modl.detail.rmsec(j,i))) & ~(isnan(modl.detail.rmsec(j,i)))
          tocalc(i) = false;
        end
      end
    end
    
    % Build models & get rmsec values, & other related values (etc)
    for i = 1:cvlv  
      if ~(tocalc(i))
        continue;
      else
        if isempty(yb_cal) % for models without yblock?
          lil_m = feval(lower(modl.modeltype),xb_cal,i,opts);
        else
          if strcmpi(modl.modeltype,'LWR') % to handle LWR
            lil_m = feval(lower(modl.modeltype),xb_cal,yb_cal,i,npts,opts);
          else % to handle PLS, PCR, MLR, NPLS, PLSDA
            if strcmpi(modl.modeltype,'ANN') % to handle ANN
              opts.nhid1 = i;
            end
            lil_m = feval(lower(modl.modeltype),xb_cal,yb_cal,i,opts);
          end
        end
        % Get the RMSEC from the intermediate models
        if strcmpi(modl.modeltype,'PLSDA')
          vals = size(modl.detail.rmsec,1);
        elseif isempty(yb_cal)
          vals = 1;
        else
          vals = length(yb_cal.include{2});%size(yb_cal,2);
        end
        if (size(lil_m.detail.rmsec,2)>=i) & size(lil_m.detail.r2c,2)>=i & size(lil_m.detail.bias,2)>=i
        for j = 1:vals
          if ~(isempty(lil_m.detail.rmsec(j,i))) & ~(isnan(lil_m.detail.rmsec(j,i)))
            modl.detail.rmsec(j,i) = lil_m.detail.rmsec(j,i);
            modl.detail.r2c(j,i) = lil_m.detail.r2c(j,i);% Also grab r2c
            modl.detail.bias(j,i) = lil_m.detail.bias(j,i);
          end
        end
        end
      end
    end
    
    % Output results back
    success = true;
    analysis('setobjdata','model',handles,modl);
  end
catch
  success = false;
end
end

