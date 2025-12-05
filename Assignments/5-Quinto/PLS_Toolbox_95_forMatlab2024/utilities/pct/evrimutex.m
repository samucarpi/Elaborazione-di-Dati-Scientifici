classdef evrimutex
  % A Mutex lock to protect access to a shared resource
  % The lock is based on a specific file which contains a single integer
  % value. A client using this mutex can only acquire the lock when
  % this file value = 0.
  % Each instance of this Mutex gets an "almost" unique ID, a randomly
  % picked integer value from the range 1 to 2^32-1.
  % The mutex lock file is called 'evrimutexfile.dat' and is created in the
  % 'tempdir' folder (see Matlab 'tempdir' command).
  
  %Copyright Eigenvector Research, Inc. 1991
  %Licensee shall not re-compile, translate or convert "M-files" contained
  % in PLS_Toolbox for use with any software other than MATLAB®, without
  % written permission from Eigenvector Research, Inc.
  
  properties
    wid      = 0;
    inttype;
    havelock = false;
    filename;
  end
  
  methods
    %----------------------------------------------------------------------
    % class constructor
    function obj = evrimutex()
      inttype      = 'uint32';
      obj.inttype  = inttype;
      obj.wid = randi(intmax(inttype)-1,1,1, inttype); % a nearly unique ID
      
      filename = 'evrimutexfile.dat';
      obj.filename = fullfile(tempdir, filename);
    end
    
    %----------------------------------------------------------------------
    function [obj] = getlock(obj)
      % Get the lock if it is free. (If it is not free, try nattempt times)
      % Effect:
      %     Set havelock = true if got the lock (set Data(1) = 1)
      %     Set havelock = false if lock was unavailable (Data(1) ~=1)
      
      % Create the lock file if it is not already there.
      if ~exist(obj.filename, 'file')
        [f, msg] = fopen(obj.filename, 'wb');
        if f ~= -1
          fwrite(f, zeros(1,1), obj.inttype);
          fclose(f);
        else
          error('PLS_Toolbox:getlock:cannotOpenFile', ...
            'Cannot open file "%s": %s.', obj.filename, msg);
        end
      end
      
      % Memory map the file.
      m = memmapfile(obj.filename, 'Writable', true, 'Format', obj.inttype);
      
      pausetime = 0.5; % seconds
      nattempt  = 60;  % some workers will have to wait. Try for 30 sec
      iattempt  = 0;
      while iattempt < nattempt
        iattempt = iattempt+1;
        % Wait until the lock is available, meaning the first byte is not zero.
        cl = clock; cmin = cl(5); csec = cl(6);
        if m.Data(1) ~= 0
          pause(pausetime);  % it is locked, so wait and try again
        else
          m.Data(1) = obj.wid; % Got the lock, setting non-zero
          pause(0.05)
          if m.Data(1) == obj.wid;  % verify lock successfully set for this worker
            obj.havelock = true;
            %             disp(sprintf('getlock[%d]:   got correct lock, set value = %d, T:min:sec = %2.4f, %2.4f', obj.wid, obj.wid, cmin, csec))
            break;
          else
            % disp(sprintf('getlock[%d]: BAD lock at attempt(%d), T:min:sec = %2.4f, %2.4f', wid, iattempt, cmin, csec))
          end
        end
      end
    end
    
    %----------------------------------------------------------------------
    function [obj, lvalue] = releaselock(obj)
      % Release the lock. This mutex instance can only release the lock if
      % it had acquired the lock.
      
      % Create the lock file if it is not already there.
      if ~exist(obj.filename, 'file')
        [f, msg] = fopen(obj.filename, 'wb');
        if f ~= -1
          fwrite(f, zeros(1,1), obj.inttype);
          fclose(f);
        else
          error('PLS_Toolbox:getlock:cannotOpenFile', ...
            'Cannot open file "%s": %s.', obj.filename, msg);
        end
      end
      
      % Memory map the file.
      m = memmapfile(obj.filename, 'Writable', true, 'Format', obj.inttype);
      
      lvalue = m.Data(1);
      cl = clock; cmin = cl(5); csec = cl(6);
      if m.Data(1)==obj.wid
        m.Data(1) = 0;
        %         disp(sprintf('evrirellock[%d]: released lock: %d, min:sec = %2.4f, %2.4f', obj.wid, lvalue, cmin, csec))
      else
        % lock value indicates lock set by different worker. Do not release it.
        %         disp(sprintf('***evrirellock[%d]: ERROR releasing lock: %d, min:sec = %2.4f, %2.4f. Current lvalue = %d', obj.wid, obj.wid, cmin, csec, lvalue))
      end
      obj.havelock = false;
      obj.wid      = 0;
    end
    
    %----------------------------------------------------------------------
    function [lvalue] = showlock(obj)
      % Show the lock value.
      %
      % Return:  lvalue, the lock value
      
      % Check that the lock file already exists.
      if ~exist(obj.filename, 'file')
        error('PLS_Toolbox:showlock:nonExistantFile',  'Non-existant file "%s".', obj.filename);
      end
      
      % Memory map the file.
      m = memmapfile(obj.filename, 'Writable', true, 'Format', obj.inttype);
      
      lvalue =  m.Data(1);   % Got the lock value
      % disp(sprintf('showlock: value = %d', lvalue))
    end
    
    %----------------------------------------------------------------------
    function [obj, lvalue] = forceclearlock(obj)
      % Unlock the lock, regardless of who has it.
      
      % Check that the lock file already exists.
      if exist(obj.filename, 'file')
        
        % Memory map the file.
        m = memmapfile(obj.filename, 'Writable', true, 'Format', obj.inttype);
        
        m.Data(1) = 0;         % Release the lock value
        lvalue = m.Data(1);
        %  disp(sprintf('forceclearlock: value was = %d', lvalue))
        
        obj.havelock = false;
        obj.wid      = 0;
      end
    end
    
    %----------------------------------------------------------------------
    function [wid] = getuid(obj)
      wid = obj.wid;
    end
  end
end