function [out,msg,loc] = testpeakdefs(peakdef)
%TESTPEAKDEFS Checks peak parameters in a peak definition structure.
%  TESTPEAKDEFS checks the consistency of the peak definitions
%  in a peak definition structure and is useful for checking the
%  initial guess for (peakdef). This function examines each
%  record of a peak definition structure (peakdef) and determines:
%  1) if the lower bounds are lower than the initial guess
%      (any parameters lower than the lower bounds is an error),
%  2) if the upper bounds are higher than the initial guess
%      (any parameters higher than the upper bounds is an error), and
%  3) if the number of parameters in each peak definition are
%     consistent with the corresponding peak function (.fun field).
%
%  INPUT:
%    peakdef = a multi-record peak definition structure array.
%              where each record is a peak definition.
%
%  OUTPUS:
%    out = output status code:
%        0 = no problems discovered.
%       -1 = problem encountered.
%    msg = error message (last error detected).
%    loc = location of detected problems. This is a two-column matrix
%          with column one corresponding to a peak with an inconsistent
%          definition, and column two corresponding to the inconsistent
%          parameter definition (e.g. a paramter is < its lower bound).
%          If column two has a zero, this means that there is a peak
%          definition with an inaccurate number of parameters for the
%          specific peak shape (e.g. for Gaussian there are 3 parameters).
%
%I/O: [out,msg,loc] = testpeakdefs(peakdef);

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NBG 6/05

%need to check if peaks overlap perfectly - don't want that

out    = 0;
msg    = '';
loc    = [];

%Check Bounds
for i1=1:length(peakdef)
  if any(peakdef(i1).param<peakdef(i1).lb)
    i2  = find(peakdef(i1).param<peakdef(i1).lb);
    msg = ['Peakdef(',int2str(i1),') param less than lower bounds', ...
           ' for parameter ',int2str(i2),' .'];
    out = -1;
    loc = [loc; i1 i2];
  end
  if any(peakdef(i1).param>peakdef(i1).ub)
    i2  = find(peakdef(i1).param>peakdef(i1).ub);
    msg = ['Peakdef(',int2str(i1),') param greater than upper bounds', ...
           ' for parameter ',int2str(i2),' .'];
    out = -1;
    loc = [loc; i1 i2];
  end
end

%Check number of parameters for each peak function
for i1=1:length(peakdef)
  if ~isempty(peakdef(i1).fun)
    switch lower(peakdef(i1).fun)
    case {'gaussian','lorentzian'}
      if length(peakdef(i1).param)~=3
        msg = ['Peakdef(',int2str(i1),').param must have 3 elements.'];
        loc = [loc; i1 0];
      end
      if length(peakdef(i1).lb)~=3
        msg = ['Peakdef(',int2str(i1),').lb must have 3 elements.'];
        loc = [loc; i1 0];
      end
      if length(peakdef(i1).ub)~=3
        msg = ['Peakdef(',int2str(i1),').ub must have 3 elements.'];
        loc = [loc; i1 0];
      end
    case {'pvoigt1','pvoigt2','gaussianskew'}
      if length(peakdef(i1).param)~=4
        msg = ['Peakdef(',int2str(i1),').param must have 4 elements.'];
        loc = [loc; i1 0];
      end
      if length(peakdef(i1).lb)~=4
        msg = ['Peakdef(',int2str(i1),').lb must have 4 elements.'];
        loc = [loc; i1 0];
      end
      if length(peakdef(i1).ub)~=4
        msg = ['Peakdef(',int2str(i1),').ub must have 4 elements.'];
        loc = [loc; i1 0];
      end
    end
  end
end
