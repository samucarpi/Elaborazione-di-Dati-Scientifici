function calprops = getcalprops(obj)
%GETCALPROPS Return calibration properties based on embedded evriscript object.

%Copyright (c) Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


calprops = {};  %default is empty
if length(obj)==1 & ~isempty(obj.calibrate) & ~iscalibrated_private(obj)
  %if already calibrated, do NOT list calprops (we don't want to write
  %them here after we're calibrated!) otherwise, get list of required
  %properties from script and use those as the list of properties we can
  %assign.
  
  if isempty(obj.calibrate.calprops)
    %generate cal props
    scr = obj.calibrate.script;
    if ~isempty(scr) & ~isempty(scr.step_mode)
      calprops = [scr.step_required scr.step_optional 'options'];
    end
  else
    %use what we've stored before
    calprops = obj.calibrate.calprops;
  end
end
