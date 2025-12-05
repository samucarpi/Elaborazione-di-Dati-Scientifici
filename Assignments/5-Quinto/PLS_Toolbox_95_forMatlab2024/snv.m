function [x,mns,sds] = snv(x,mns,sds);
%SNV Standard normal variate scaling.
%  Scales rows of the input (x) to be mean zero
%  and unit standard deviation. This is the same
%  as autoscaling the transpose of (x).
%  INPUT:
%        x = the data to be scaled (class "double" or "dataset").
%
%  OPTIONAL INPUTS:
%      options = options structure passed to function "auto" when
%            performing SNV scaling. See auto.m for available options.
%            (not valid for undo operation)
%      mns = vector of means
%      sds = vector of standard deviations
%
%  OUTPUTS:
%    xcorr = the scaled data [(xcorr) will be class dataset if (x) is], 
%      mns = vector of means, and
%      sds = vector of standard deviations for each row.
%
%  To rescale or "undo" SNV, inputs are (xcorr), (mns), and (sds) from
%  previous SNV call. Output will be original (x).
%
%I/O: [xcorr,mns,sds] = snv(x,options);       %perform snv scaling
%I/O: x = snv(xcorr,mns,sds);         %undo snv scaling
%I/O: snv demo
%
%See also: AUTO, NORMALIZ, PREPROCESS

%Copyright Eigenvector Research, Inc 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% Initial coding 11/26/01 - JMS
% JMS 12/21/01 -modified default prepro structure call to use validate
% JMS 1/3/02 -rewrote to use mdauto and rescale
% JMS 2/4/02 -fixed dataset includ{2} bug
% jms 3/19/02 -revised calls to preprocess
% jms 8/6/02 -removed mdauto call
% jms 8/7/02 -revised 'default' preprocessing structure calls
% jms 10/04/02 -removed undo from preprocessing strcuture

if nargin == 0; x = 'io'; end

if isa(x,'char');
  switch x
  case 'default'
    % create preprocess structure to call SNV
    x = snvset('default');
    return
  otherwise
    varargin{1} = x;
    options = auto('options');
    if nargout==0; clear x; evriio(mfilename,varargin{1},options); else; x = evriio(mfilename,varargin{1},options); end
    return;   
  end
end

if isa(x,'dataset');
  isds  = 1;
  data  = x.data;
  ivars = x.includ{2};
else
  isds  = 0;
  data  = x;
  ivars = 1:size(x,2);
end

if nargin < 3;   %do
  
  if nargin==2;
    opts = mns;
  else
    opts = [];
  end
  opts = reconopts(opts,'snv');
  [data,mns,sds] = auto(data(:,ivars)',opts);
  data = data';
  
else  %undo
  
  data = rescale(data(:,ivars)',mns,sds);
  data = data';
  
end

if isds;
  x.data = x.data*nan;
  x.data(:,ivars) = data;
else
  x = data;
end

