function [DSOout,model] = polytransform_browse(varargin)
%POLYTRANSFORM Helper function for using polytransform in browse.
% Pass arguments to browse after prompting for data (if needed) and always
% ask for options.
%
%I/O: [DSOout,model] = polytransform_browse()
%
%See also: POLYTRANSFORM

%Copyright Eigenvector Research 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

DSOout = [];
model = [];

if nargin==2
  %Passing data and model so do direct call.
  [DSOout,model] = polytransform(varargin);
end

if nargin==0; 
  varargin{1} = lddlgpls({'dataset','double'},'Choose Data to Transform');
  if isempty(varargin{1});
    return
  end
end

if ndims(varargin{1})>2
  error('Polytransform is not available for multiway data')
end

options = optionsgui('polytransform');

if isempty(options)
  %User cancel.
  return
end

[DSOout,model] = polytransform(varargin{1},options);


