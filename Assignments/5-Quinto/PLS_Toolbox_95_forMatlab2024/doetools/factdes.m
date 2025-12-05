function desgn = factdes(k,levl)
%FACTDES Full factorial design of experiments.
%  Generates a full-factorial DOE. Inputs can take two forms:
%  (A) (k) is the number of factors in the design i.e. the number of
%      columns in the output (desgn), and (levl) is the number of levels
%      (default = 2). All factors are created at the given number of
%      levels. To create a DOE with a different number of levels in each
%      factor, use form (B) of the inputs.
%  (B) (levls) can be provided as a single input containing a vector equal
%      in length to the number of factors desired and indicating the number
%      of levels for each of those factors. For example: [2 2 3]  would
%      generate a 3-factor model with two factors at 2 levels and one at 3
%      levels.
%
%  Output (desgn) is the matrix of the experimental design.
%  If levl=2 then this gives a 2^k design.
%
%I/O: desgn = factdes(k,levl)
%I/O: desgn = factdes(levls)
%
%See also: BOXBEHNKEN, CCDFACE, CCDSPHERE, DOEGEN, DOESCALE, FFACDES1

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%nbg 9/01 added "if levl==2" to speed it up
%RTB modified output to be centered around zero

if nargin == 0; k = 'io'; end
if ischar(k);
  options = [];
  
  %  NOT exposed, but setable through setplspref!
  %    algorithm : [ 'cull' | {'replicate'} ] Governs algorihm used to create
  %                 design. 'cull' is the original method which can be slow
  %                 and require lots of memory. 'replicate' loops over
  %                 factors and replicates each design for each new factor's
  %                 levels.
  options.algorithm = 'replicate';
  
  if nargout==0; evriio(mfilename,k,options); else; desgn = evriio(mfilename,k,options); end
  return;
end

options = reconopts([],mfilename);

if length(k)>1
  levl = k;
  k = length(levl);
elseif nargin<2
  levl = 2*ones(1,k); % if no levl value provided, assume 2 level...DON'T CHANGE THIS!
elseif length(levl)~=k
  if length(levl)==1
    levl = levl*ones(1,k);  %make levl a vector
  else
    error('Number of levels and length of level vector do not match')
  end
end

switch options.algorithm
  case 'cull'
    
    %original method. Slower and requires lots of memory if levels are large
    mlevl  = max(levl);
    nexp   = mlevl^k;
    
    desgn  = zeros(nexp,k);  %assure we have enough memory
    
    v = 0:nexp-1;      %vector of experiments
    v = v'*ones(1,k);  %create matrix for all factors
    for j=1:k
      %NOTE! Done in loop to avoid rounding errors assocaited with matrix
      %approaches (!?!)
      v(:,j) = v(:,j)/(mlevl.^(k-j));  %divide each column so mod+floor will give integers
    end
    desgn = floor(mod(v,mlevl));
    
    %check for factors which have more levels than we needed
    levlmat = repmat((levl-1),size(desgn,1),1);
    if ~all(levl==mlevl)
      %identify which rows we don't need (because the actual level of a factor
      %is lower than the one we built at)
      keep    = all(desgn<=levlmat,2);
      desgn   = desgn(keep,:);
      levlmat = levlmat(keep,:);
    end
    
    %adjust to zero-centered design
    desgn = round(desgn-levlmat/2);
    
  otherwise  %case 'replicate' - but all others go here
    
    %replicate method - faster and doesn't require as much memory as cull method
    desgn = zeros(prod(levl),k);  %test memory
    desgn = [];  %now, start with an empty matrix
    for f = length(levl):-1:1
      toadd = round((0:(levl(f)-1))-((levl(f)-1)/2));
      if isempty(desgn)
        desgn = toadd';
      else
        toadd = repmat(toadd,size(desgn,1),1);
        desgn = [toadd(:) repmat(desgn,levl(f),1)];
      end
    end
    
end


