function mm = minimizemodel(model)
%MINIMIZEMODEL Shrinks model by removing non-critical information.
% Models contain both the information necessary to apply that model to new
% data and also the results calculated with the model was built (such as
% scores, cross-validation results, Hotellings T^2, sum squared residuals
% from the calibration samples.) Although this additional calibration
% sample information is necessary to review the model results, they are not
% necessary to apply the model to new data.
%
% MINIMIZEMODEL attempts to compress a model by removing the fields which
% are not strictly necessary to apply the model. Such compression will
% prevent the direct comparison of new sample results to calibration sample
% results, but the model will still be functional for on-line use, for
% example.
%
% The extent of compression varies greatly between model types and will
% generally be more effective on models built from large numbers of samples
% and fewer variables as compared to models built from large numbers of
% variables and fewer samples.
%
% If no outputs are requested, the sizes of all model fields with more than
% 100 bytes in size are returned.
%
%INPUTS:
%  model = standard model structure to compress
%OUTPUTS:
%     mm = minimized model
%
%I/O: mm = minimizemodel(model) %compress model
%I/O: minimizemodel(model)      %display size information only
%
%See also: COMPRESSMODEL, MODELSTRUCT

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  model = 'io';
end
if ischar(model)
  options = [];
  if nargout==0; evriio(mfilename,model,options); else; mm = evriio(mfilename,model,options); end
  return
end

if nargout==0
  %no outputs? just show user how big everything is
  modelsizes(model);
  return;
end

mm = model;

blank = modelstruct(mm.modeltype);

%clear out MOST of y-block (except keep columns and userdata for some model
%types which require that info, like classification models)
if isfield(mm.detail,'data') & size(mm.detail.data,2)>1;
  mm.detail.data{2} = mm.detail.data{2}(1,:);  %drop all but first sample
end
%clear out scores from .loads field
if isfield(mm,'loads');
  for j=1:size(mm.loads,2);
    if j==1;
      continue;  %TEMP: Do NOT clear out X scores - this disables some limits calculations and other things!
    end
    mm.loads{1,j} = [];
  end
end

%clear these fields from the top-level of a model
toblank = {'classification' 'ssqresiduals' 'tsqs' 'pred'};
for j=1:length(toblank)
  if isfield(mm,toblank{j});
    mm.(toblank{j}) = blank.(toblank{j});
  end
end

%clear these fields from the detail-level of a model
toblank = {'class' 'axisscale' 'res' 'predprobability' 'leverage' 'cvi' 'cvpred' 'cvclassification' 'selratio'};
for j=1:length(toblank)
  if isfield(mm.detail,toblank{j});
    mm.detail.(toblank{j}) = blank.detail.(toblank{j});
  end
end

%------------------------------
function modelsizes(model)

list = getsizes(model);
list(ismember({list.name},{'detail'})) = [];
[junk,order] = sort(-[list.bytes]);
list = list(order);
disp(sprintf('% 12s  %s (%s)','bytes','field','class'))
for j=1:length(list);
  if list(j).bytes<100; continue; end
  disp(sprintf('% 12i  .%s (%s)',list(j).bytes,list(j).name,list(j).class))
end

list = getsizes(model.detail);
[junk,order] = sort(-[list.bytes]);
list = list(order);
for j=1:length(list);
  if list(j).bytes<100; continue; end
  disp(sprintf('% 12i  .detail.%s  (%s)',list(j).bytes,list(j).name,list(j).class))
end


%------------------------------------------
function MMMSz = getsizes(MMM)

explode(MMM,struct('model','no'));
MMMSz = whos;
MMMSz(ismember({MMMSz.name},{'MMM'})) = [];

