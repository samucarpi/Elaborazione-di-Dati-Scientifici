function [varargout]=fullsearch(varargin)
%FULLSEARCH Exhaustive Search Algorithm for small problems.
%  FULLSEARCH selects the (Nx_sub) variables in the M by Nx matrix
%  (X) that minimizes (fun). This can be used for variable selection.
%  Note: FULLSEARCH should only be used for small problems because
%  FULLSEARCH will make Nx!/Nx_sub!/(Nx-Nx_sub)! evaluations of
%  the objective function.
%
%  INPUTS:
%    fun    = objective function name (char string or inline object) that
%             has a scalar output (fval). It is called using the following:
%              fval = feval(fun,X,P1,P2,...);
%    X      = M by Nx matrix of predictor variables X to be searched.
%    Nx_sub = a scalar of number of X variables to use. Nx_sub should be < Nx.
%    P1, P2, ... = additional parameters used by (fun).
%  OUTPUTS:
%    desgn  = M by Nx matrix (class logical) with 1's where a variable was used and
%             0's otherwise.
%    fval   = corresponding value of the objective function sorted in ascending order.
%
%Example: find which 2 of 3 variables minimize inline function g
%  x = [0:10]';
%  x = [x x.^2 randn(11,1)*10];
%  y = x*[1 1 0]';
%  g = inline('sum((y-x*(x\y)).^2)');
%  [d,fv] = fullsearch(g,x,2,y);
%
%Example: optimize based on cross-validation, in this case the function
%  call is "min(sum(crossval(x,y,''pcr'',{''con'' 3},1,0)))" which
%  sums the press (the first output from CROSSVAL) from a 1 factor PCR
%  model using contiguous block cross-validation. Plotting and display
%  has been turned off in the CROSSVAL function. See INLINE.
%
%  load plsdata
%  x = xblock1.data;
%  y = yblock1.data;
%  g = inline('min(sum(getfield(crossval(x,y,''pcr'',{''con'' 3},1,0,0),''press'')))','x','y');
%  [d,fv] = fullsearch(g,x,2,y); %takes a while if Nx_sub is > 2
%
%I/O: [desgn,fval] = fullsearch(fun,X,Nx_sub,P1,P2, ...);  %exahaustive search engine
%I/O: fullsearch demo
%
%See also: CALIBSEL, CROSSVAL, GENALG

%Copyright Eigenvector Research, Inc. 1997
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%nbg 8/12/02 changed line 59 evriio(mfilename,varargin{1}); to evriio(mfilename,varargin{1},[]);
%nbg 2/13/02 commented out line 97:  %varargout{1}   = zeros(numevals,nx);

if nargin == 0; varargin{1} = 'io'; end

%Check I/O:
if ischar(varargin{1})
  if nargout==0 %Help, Demo
    evriio(mfilename,varargin{1},[]);
    return
  end
  if nargout>0
    switch lower(varargin{1})
    case evriio([],'validtopics');
      options = [];
      varargout{1} = evriio(mfilename,varargin{1},options);
      return
    otherwise %assume it is a function name
      if nargin<3
        error('FULLSEARCH requires 3 inputs.')
      end
      fun      = varargin{1};
      x        = varargin{2};
      nxsub    = varargin{3};
      if nargin>3
        varargin = varargin(4:end);
      else
        varargin = {};
      end
      
      [mx,nx]  = size(x);
      
      if prod(size(nxsub))>1
        error('Input (Nx_sub) must be scalar.')
      elseif nxsub>nx
        error('Input (Nx_sub) must be < Nx.')
      end
      %End check I/O.
      
      numevals = prod(nxsub+1:nx)/prod(1:nx-nxsub);    % Nx!/Nx_sub!/(Nx-Nx_sub)!
      if numevals>100
        hwait  = waitbar(0,sprintf('Estimated time remaining %0.2g mins',0.5*numevals/60));
      else
        hwait  = waitbar(0,'Calculating.');
      end      
      varargout{1}   = (factdes(nx)+1)/2;%factdes(nx);     % (2^nx) by nx
      varargout{1}   = varargout{1}(find(sum(varargout{1},2)==nxsub),:);  % numevals by nx
      %varargout{1}   = zeros(numevals,nx);
      varargout{2}   = inf*ones(numevals,1);

      t0       = clock;
      if isempty(varargin)
        for ii=1:numevals %eval the objective function for each set
          varargout{2}(ii) = feval(fun,x(:,find(varargout{1}(ii,:))));
          if ii/10-floor(ii/10)==0
            waitbar(ii/numevals,hwait,sprintf('Estimated time remaining %0.2g mins', ...
              etime(clock,t0)/60*(numevals/ii-1)))
          end
        end
      else
        for ii=1:numevals %eval the objective function for each set
          varargout{2}(ii) = feval(fun,x(:,find(varargout{1}(ii,:))),varargin{:});
          if ii/10-floor(ii/10)==0
            waitbar(ii/numevals,hwait,sprintf('Estimated time remaining %0.2g mins', ...
              etime(clock,t0)/60*(numevals/ii-1)))
          end
        end
      end
      
      [varargout{2},ii]  = sort(varargout{2});
      varargout{1}   = varargout{1}(ii,:);
      close(hwait)
    end
  end
elseif isa(varargin{1},'inline')
  if nargin<3
    error('FULLSEARCH requires 3 inputs.')
  end
  fun      = varargin{1};
  x        = varargin{2};
  nxsub    = varargin{3};
  if nargin>3
    varargin = varargin(4:end);
  else
    varargin = {};
  end
  
  [mx,nx]  = size(x);
  
  if prod(size(nxsub))>1
    error('Input (Nx_sub) must be scalar.')
  elseif nxsub>nx
    error('Input (Nx_sub) must be < Nx.')
  end
  %End check I/O.
      
  numevals = prod(nxsub+1:nx)/prod(1:nx-nxsub);    % Nx!/Nx_sub!/(Nx-Nx_sub)!
  if numevals>100
    hwait  = waitbar(0,sprintf('Estimated time remaining %0.2g mins',0.5*numevals/60));
  else
    hwait  = waitbar(0,'Calculating.');
  end  
  varargout{1}   = (factdes(nx)+1)/2;                                       % (2^nx) by nx
  varargout{1}   = varargout{1}(find(sum(varargout{1},2)==nxsub),:);  % numevals by nx
  varargout{2}   = inf*ones(numevals,1);

  t0       = clock;
  if isempty(varargin)
    for ii=1:numevals %eval the objective function for each set
      varargout{2}(ii) = fun(x(:,find(varargout{1}(ii,:))));
      if ii/10-floor(ii/10)==0
        waitbar(ii/numevals,hwait,sprintf('Estimated time remaining %0.2g mins', ...
          etime(clock,t0)/60*(numevals/ii-1)))
      end
    end
  else
    for ii=1:numevals %eval the objective function for each set
      varargout{2}(ii) = fun(x(:,find(varargout{1}(ii,:))),varargin{:});
      if ii/10-floor(ii/10)==0
        waitbar(ii/numevals,hwait,sprintf('Estimated time remaining %0.2g mins', ...
          etime(clock,t0)/60*(numevals/ii-1)))
      end
    end
  end
  
  [varargout{2},ii]  = sort(varargout{2});
  varargout{1}   = varargout{1}(ii,:);
  close(hwait)
else
  error('Input (fun) must be a character string or inline object.')
end
if nargout>0, varargout{1} = logical(varargout{1}); end
