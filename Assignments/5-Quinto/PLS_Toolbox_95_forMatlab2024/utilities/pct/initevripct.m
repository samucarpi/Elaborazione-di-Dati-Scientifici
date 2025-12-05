function [hasgcp] = initevripct(timeoutminutes)
% Purpose: Run a PLS_Toolbox initialization function on each parallel pool 
% Matlab instance, if the Parallel Computing Toolbox (PCT) is installed.
% It is necessary to do this in order to avoid errors when parfor loops
% (or other parallel usage) using PLS_Toolbox code are first used. 
% Insert "initevripct" call before such calls to parfor. Once the worker
% pool has been initialized subsequent calls to initevripct take negligible
% execution time.
%
% This function should be called before any PCT workers are used to execute
% PLS_Toolbox code. 
% 
% INPUTS:
%  timeoutminutes  = [{60*12}] Number of minutes for parpool idle timeout
%
% OUTPUTS:
%  hasgcp = Boolean indicating whether PCT is available or not
%
%I/O: hasgcp = initevripct(timeoutminutes);   % Start parallel pool
%
% See also: prepevriio.m

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin>0
  timeoutminutes = max(timeoutminutes,30); % use 30 min instead of neg val
  idletimeout = timeoutminutes;
else
  idletimeout = 60*12;    % 12 hour default idle timeout
end
haspct = license('test', 'distrib_computing_toolbox');
hasgcp = haspct & exist('gcp', 'file');

if hasgcp
  try
    if isempty(gcp('nocreate'))  % parpool is not running
      mutex = evrimutex;
      mutex.forceclearlock;      % ensure lock file is clear
      
      pool = gcp;                % Start parpool if it is not already running
      if ~isempty(pool)
        pool.IdleTimeout = idletimeout;  % number of minutes  (PCT default was 30)
        pctRunOnAll('prepevriio'); % Execute function "prepevriio" on each PCT
        disp(sprintf('PLS_Toolbox initialization completed for %d workers and desktop client', pool.NumWorkers))
      else
        % parpool did not start. Check Parallel Computint Toolbox
        % prefrences, valid license, etc
        hasgcp = false;
        return;
      end
    end
  catch err
    disp(sprintf('initevripct: error when starting pool (%s)', err.getReport))
    hasgcp = false;
  end
end