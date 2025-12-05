function disp(obj,redisplayname)
%EVRIMODEL/DISP overload for object.

%Copyright (c) Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


%get preferences
desc = getplspref('evrimodel','desc');
contents = getplspref('evrimodel','contents');
if isempty(desc)
  desc = false;
end
if isempty(contents)
  contents = true;
end

%check if we can re-display if they change settings
if nargin<2
  redisplayname = '';
end

%add controls to output
if iscalibrated(obj)
  s = '(';
  if desc
    s = [s 'Desc. ON/<a href="matlab: setplspref(''evrimodel'',''desc'',0);disp(''** Model Description Display Off'');' redisplayname '">[off]</a>'];
  else
    s = [s 'Desc. OFF/<a href="matlab: setplspref(''evrimodel'',''desc'',1);disp(''** Model Description Display ON'');' redisplayname '">[on]</a>'];
  end
  s = [s '  '];
  if contents
    s = [s 'Contents ON/<a href="matlab: setplspref(''evrimodel'',''contents'',0);disp(''** Model Contents Display Off'');' redisplayname '">[off]</a>'];
  else
    s = [s 'Contents OFF/<a href="matlab: setplspref(''evrimodel'',''contents'',1);disp(''** Model Contents Display ON'');' redisplayname '">[on]</a>'];
  end
  s = [s ')'];
else
  s = '(Not Calibrated)';
end

%top line...
type = obj.content.modeltype;
if ~isprediction(obj)
  if isempty(type)
    disp(sprintf('  EVRIModel Object %s',s))
  else   
    disp(sprintf('  %s Model Object %s',type,s))
  end
else
  disp(sprintf('  %s Prediction Object %s',type,s))
end

%and display contents
if ~iscalibrated(obj)
  %NOT calibrated - special display
  if cancalibrate(obj)
    disp('    Use ".calibrate" method to build model');
    calprops = getcalprops(obj);
    for j=1:length(calprops);
      temp.(calprops{j}) = obj.calibrate.script.(calprops{j});
    end
    if isfieldcheck(temp,'s.options.plots')
      temp.plots = temp.options.plots;
    end
    if isfieldcheck(temp,'s.options.display')
      temp.display = temp.options.display;
    end
    disp(temp);
  else
    disp(sprintf('    See "%s" function to calibrate',lower(obj.content.modeltype)))
  end

else
  %model is calibrated, show its info
  if desc
    %if showing description...
    if ~isempty(obj.content.modeltype)
      %use modlrder for models with a type
      d = modlrder(obj);
      while isempty(strtrim(d{end})); d = d(1:end-1); end
      disp(sprintf('    %s\n',d{:}));
    else
      %otherwise show generic no-type info
      disp('    No Model Type Specified (.modeltype)');
      disp('    See ".validmodeltypes" for list of valid model types');
    end
  elseif contents
    %if not showing description, but we ARE showing contents, add a spacer
    disp(' ');
  end
  
  %always add these items to list (even when contents are off)
  if isempty(obj.content.modeltype)
    %no model type? fake contents
    temp = [];
    temp.modeltype = '';
    temp.validmodeltypes = template;
  else
    %got a modeltype
    if contents
      %if showing contents
      temp = obj.content;
    else
      temp = [];
    end
    temp.uniqueid = subsref(obj,substruct('.','uniqueid'));
    temp.plots   = obj.plots;
    temp.display = obj.display;
    temp.matchvars = obj.matchvars;
    temp.contributions = obj.contributions;
    temp.reducedstats = obj.reducedstats;
  end
  
  %show contents
  disp(temp)
  if contents
    %if showing contents
    vf = virtualfields(obj);
    vf = [vf(:,1);{'qcon' 'tcon' 'ncomp'}'];
    vf = sort(vf);
    if ~isempty(obj.content.modeltype)
      disp(['     Other Fields = ' sprintf('%s, ',vf{1:end-1}) vf{end}])
      disp( '    Detail Fields = Can be accessed directly without .detail ')
    end
  end
end
