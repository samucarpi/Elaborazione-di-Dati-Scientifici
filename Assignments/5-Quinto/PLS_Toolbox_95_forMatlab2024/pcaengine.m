function [ssq,datarank,loads,scores,msg,varssq] = pcaengine(data,ncomp,options);
%PCAENGINE Principal Components Analysis computational engine.
%  This function is intended primarily for use as the engine behind
%  other more full featured PCA programs. The only required input is the
%  data matrix (data).
%
%  Optional inputs include the number of principal components desired in
%  the output (ncomp), and a structure containing optional inputs
%  (options). If the number of components (ncomp) is not specified, the
%  routine will return components up to the rank of the data (datarank).
%
%  Outputs are the variance or sum-of-squares captured table (ssq),
%  mathematical rank of the data (datarank), principal component loadings
%  (loads), principal component scores (scores), and a text variable
%  containing any warning messages (msg).
%  Note that column 2 of (ssq) are the eigenvalues of data'*data/(M-1).
%
%  To enhance speed the routine is written so that only the specified
%  outputs are computed. 
%
%  OPTIONAL INPUT:
%   options = structure variable used to govern the routine with the following fields:
%       display: [ 'off' | {'on'} ]      governs level of display to command window.
%     algorithm: [{'regular'} | 'big']   decomposition method
%
%I/O: [ssq,datarank,loads,scores,msg] = pcaengine(data,ncomp,options);
%I/O: pcaengine demo
%
%See also: ANALYSIS, ESTIMATEFACTORS, EVOLVFA, EWFA, PARAFAC, PCA, SUBGROUPCL

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%by BMW 5/15/02, debugged 5/16/02 BMW
%added big data support 5/16/02
%JMS added auto algorithm selection 5/17/02
%BMW 8/02 fixed n > m score scale bug
%JMS 2/4/03 fixed bug when large (>200 vars) row vector is analyzed
%JMS 5/21/03 convert non-doubles to doubles before calculating
%JMS 6/3/03 added test for mean of absolute zero (don't show warning)
%NBG 4/26/05 added a line in the help re: 1/(M-1).

%standard I/O interpreter
if nargin == 0; data = 'io'; end
if ischar(data);
  
  options = [];
  options.name = 'options';
  options.display = 'on';
  options.algorithm = 'regular';
  
  if nargout==0; 
    clear ssq; 
    evriio(mfilename,data,options); 
  else 
    ssq = evriio(mfilename,data,options); 
  end
  return 
end

switch nargin
  case 1
    % (data)
    ncomp   = [];
    options = [];
  case 2
    % (data,ncomp)
    % (data,options)
    if isa(ncomp,'struct');
      options = ncomp;
      ncomp   = [];
    else
      options = [];
    end
  case 3
    % (data,ncomp,options)
    % (data,options,ncomp)
    if isa(ncomp,'struct');   %should cause an error but we're going to be nice and invert for them
      temp    = ncomp;
      ncomp   = options;
      options = temp;
    end
end

%convert to double if not already
if isa(data,'dataset');
  error('DataSet object not supported');
end
if ~isa(data,'double');
  data = double(data);
end

options = reconopts(options,'pcaengine',0);
options.algorithm = lower(options.algorithm);
if ~ismember(options.algorithm,{'regular','big','auto'});
  error('Unrecognized value for OPTIONS.ALGORITHM - see ''pcaengine help''');
end

% Check data size and for missing data
[m,n] = size(data);
if mdcheck(data)   
  error('Input (data) can not contain ''NaN'' or ''inf''')
end                             

if strcmp(options.algorithm,'auto') & nargout <= 2     %auto algorithm and only want ssq info?
  options.algorithm = 'regular';   %do regular decomp only
end

% Check ncomp
if isempty(ncomp);
  oldncomp = 0;
  ncomp = min([n m]);
  if strcmp(options.algorithm,'auto')     %auto algorithm = automatic choice
    options.algorithm = 'regular';        %ncomp not specified? we must use regular decomposition
  end
else
  oldncomp = ncomp;
  if ncomp > min([n m])
    ncomp = min([n m]);
  end
  if strcmp(options.algorithm,'auto')     %auto algorithm = automatic choice
    if min([n m]) < 300 | ncomp > min([n m])*.015;     %decide based on size of matrix and # of PCs requested
      options.algorithm = 'regular';
    else
      options.algorithm = 'big';
    end    
  end
end

% Perform decomp in most efficient way
if nargout <= 2
  switch lower(options.algorithm)
    case 'regular'
      if m >= n
        s = svd(data);
      else
        s = svd(data');
      end
    case 'big'
      s = svds(data,ncomp);
  end
  if m>1;
    s = s.^2/(m-1);
  else
    s = s.^2;
  end
  datarank = length(find(s>(max([m n]) * s(1) * eps)));
  s = s(1:datarank);
  if m>1;
    temp = (m-1)*s*100/sum(sum(abs(data).^2));
  else
    temp = m*s*100/sum(sum(abs(data).^2));
  end
  ssq  = [[1:datarank]' s temp cumsum(temp)];
else
  scores = [];  %pre-define so imaginary test works even when scores not calculated
  if max([m n]) < 200 | m==1;  %JMS 1/4/03
    switch lower(options.algorithm)
      case 'regular'
        [scores,s,loads] = svd(data,0);
      case 'big'
        [scores,s,loads] = svds(data,ncomp);
    end
    if m>1;
      s2 = diag(s).^2/(m-1);
    else
      s2 = diag(s).^2;
    end
    datarank = length(find(s2>(max(size(data)) * s2(1) * eps)));
    s2 = s2(1:datarank);
    if m>1;
      temp = (m-1)*s2*100/sum(sum(abs(data).^2));
    else
      temp = (m)*s2*100/sum(sum(abs(data).^2));
    end
    ssq  = [[1:datarank]' s2 temp cumsum(temp)];
    loads = loads(:,1:min([datarank ncomp]));
    if nargout > 3
      scores = scores*s;
      scores = scores(:,1:min([datarank ncomp]));
    end
  else
    if n < m
      cov = (data'*data)/(m-1);
      switch lower(options.algorithm)
        case 'regular'
          [u,s,loads] = svd(cov);
        case 'big'
          [u,s,loads] = svds(cov,ncomp);
      end
      s = diag(s);
      datarank = length(find(s>(max(size(cov)) * s(1) * eps)));
      s = s(1:datarank);
      temp = s*100/sum(abs(diag(cov)));
      ssq  = [[1:datarank]' s temp cumsum(temp)];
      s = s(1:min([datarank ncomp]));
      loads = loads(:,1:min([datarank ncomp]));
      if nargout > 3
        scores = data*loads;
      end
    else
      cov = (data*data')/(m-1);
      switch lower(options.algorithm)
        case 'regular'
          [scores,s,v] = svd(cov);
        case 'big'
          [scores,s,v] = svds(cov,ncomp);
      end
      s = diag(s);
      datarank = length(find(s>(max(size(cov)) * s(1) * eps)));
      s = s(1:datarank);
      temp = s*100/sum(abs(diag(cov)));
      ssq  = [[1:datarank]' s temp cumsum(temp)];
      s = s(1:min([datarank ncomp]));
      loads = data'*v(:,1:min([datarank ncomp]));
      for i = 1:min([datarank ncomp])
        loads(:,i) = loads(:,i)/norm(loads(:,i));
      end
      if nargout > 3
        scores = data*loads;
        %scores = scores(:,1:min([datarank ncomp]))*diag(sqrt(s));
      end
    end
  end
  if isreal(loads) & isreal(scores)
    signflip = sign(sum(loads.^3));
    signflip(signflip==0) = 1;
    loads = loads*diag(signflip);
    if nargout > 3
      scores = scores*diag(signflip);
    end
  end
end
% Check for changes to ncomp
if datarank < oldncomp
  msg = strvcat(['Rank of data less than number of PCs specified (' int2str(oldncomp) ').'],...
    ['Resetting number of PCs to be equal to data rank (' int2str(datarank) ').']);
  if strcmp(lower(options.display),'on')
    disp('  ')
    disp(msg)
  end
else
  msg = [];
end
% Check for mean centering
ssqtot = sum(sum(abs(data).^2));
mns    = mean(data);
ssqmns = mns*mns';
if nargout > 5
  varssq = ssq(1:datarank,[1 3 4]);
end
if ssqmns~=0 & (ssqtot/ssqmns<1e10)
  msg2 = strvcat('Warning: Data do not appear to be mean centered.',...
    'Variance captured table should be read as sum of',...
    'squares captured.'); 
  if strcmp(lower(options.display),'on')
    disp('   ')
    disp(msg2)
  end
  if isempty(msg)
    msg = msg2;
  else
    msg = strvcat(msg,'  ',msg2);
  end
  
  %correct ssq for degrees of freedom error
  ssq(:,2) = ssq(:,2)*(m-1)/m;
  
  if nargout > 5  % Calculate actual variance captured
    data = mncn(data);
    mcssqtot = sum(sum(data.^2));
    nscores = data*loads;
    temp = (100*sum(nscores.^2)/mcssqtot)';
    varssq = [[1:ncomp]' temp cumsum(temp)];
  end
end

% display variance captured table
if strcmp(lower(options.display),'on')
  ssqtable(ssq(1:min([20 n m datarank]),:));
end
