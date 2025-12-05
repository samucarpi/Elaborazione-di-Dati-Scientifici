function out = fieldnames(obj)
%EVRIMODEL/FIELDNAMES Returns the valid fieldnames for a model.
% Generates a context-sensitive list of fields available for a model
% object.
%
%I/O: out = fieldnames(obj)

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%start with a basic list of methods and properties that should always be
%there no matter what the state of the model

out = {'modeltype' 'validmodeltypes' 'evrimodelversion' 'content',...  %basic properties
  'disp' 'encode' 'encodexml'...   %methods
  'cancalibrate' 'iscalibrated' 'isclassification' 'isprediction' 'isyused'}';  %read-only properties

remove = {'matchvarsmap'};  %NEVER show these fields

if ~iscalibrated(obj) & cancalibrate(obj)
  %not yet calibrated and is calibratable
  out = [out;'crossvalidate';'calibrate';subsref(obj,substruct('.','inputs'))'];  %get list provided by "inputs" (which are all valid right now)
  
else
  %calibrated OR not calibratable
  
  %get basic top-level fields
  out = [out;fieldnames(struct(obj))];
  
  if iscalibrated(obj)
    %add fields at top-level of content
    out = [out;fieldnames(obj.content)];
    
    %DISABLED NEXT CODE... useful, but kind of overwhelming!
    % %add fields at top-level of details
    % out = union(out,fieldnames(obj.content.detail));
    
    %remove calibrate
    remove{end+1,1} = ['calibrate'];
  end
  
  %get methods...
  out = [out;methods(obj)];
  
  %REMOVE these methods
  remove = [remove;{
    'calibrate'
    'downgradeinfo'
    'evrimodel'
    'fieldnames'
    'isa'
    'isfield'
    'isfieldcheck'
    'isstruct'
    'loadobj'
    'openvar'
    'subsasgn'
    'subsref'
    }];
  
  if ~iscalibrated(obj)
    %if NOT calibrated yet, remove these methods
    remove{end+1} = 'edit';
  end
  
  %Placeholder fields for methods and other burried properties (to trigger autocomplete)
  if iscalibrated(obj)
    %for models which are calibrated already...
    vfs = virtualfields(obj);
    
    use = false(1,size(vfs,1));
    for j=1:size(vfs,1);
      suse = min(find(~ismember({vfs{j,2}.type},'.')))-1;
      if suse>0;
        f = ['model' sprintf('.%s',vfs{j,2}(1:suse).subs)];
        use(j) = isfieldcheck(obj.content,f);
      else
        %just assume true
        use(j) = true;
      end
    end
    vf  = vfs(use,1);
    vf  = [{'plotloads' 'plotscores' 'ploteigen' ...  %virtual methods!
      'esterror' 'scoredistance'...
      'prediction' 'predictionlabel' 'ncomp' 'xhat'...  %more special virtual properties
      }';vf];
    out = [out;vf];
    
    if ~isprediction(obj)
      %if not a prediction object, add "apply" method
      out = [out;'apply'];
    else
      remove{end+1} = 'crossvalidate';
    end
    
  end
  
  %additional methods/properties which are ALWAYS there (calibrated or not)
  out = [out;{'uniqueid' 'validmodeltypes' 'inputs' 'info'}'];

end

%always remove these fields
remove{end+1} = 'downgradeinfo';

%remove and sort out
out = setdiff(out,remove);

