function  prepevriio
% Purpose: Execute a simple evriio call in order to get the evriio
% persistent variable "licenseinfo" initialized.
% Use to initialize each worker when using the Parallel Computing Toolbox.
% This function is intended to be run on each worker instance by
% initevripct
% See also: initevripct.m, evrimutex.m

%Copyright Eigenvector Research, Inc. 2020
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

success = false;
iattempt   = 0;
nattempts  = 1;
mutex      = evrimutex();
lvalue     = 0;

while iattempt < nattempts & ~success
  mutex = mutex.getlock();
  if mutex.havelock
    % get the evriio persistent variable "licenseinfo" initialized.
    out = evriio('-', 'options');   % ...not interested in the output
    
    % only add jars to dynamic java classpath if not already done. Test by
    % checking for the availability of ths SVM class:
    res = exist('libsvm.evri.SvmTrain2', 'class');
    if res~=8
      evrijavasetup;
    end
    success = true;
    [mutex, lvalue] = mutex.releaselock(); % NB! Release the lock for this worker
  else
    disp(sprintf('prepevriio[%d]: evrigetlock failed to get lock at iattempt %d', mutex.wid, iattempt))
  end
  iattempt = iattempt+1;
end
cl = clock; cmin = cl(5); csec = cl(6);
if ~success
  disp(sprintf('PREPEVRIIO (ID %d) failed to get lock after %d attempts, at min:sec = %2.0f:%2.4f', lvalue, iattempt, cmin, csec))
else
  disp(sprintf('PLS_Toolbox initialization succeeded (ID %d, at min:sec = %2.0f:%2.4f)', lvalue, cmin, csec))
end