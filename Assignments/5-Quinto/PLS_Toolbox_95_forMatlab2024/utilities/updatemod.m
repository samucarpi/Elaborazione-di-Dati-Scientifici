function a = updatemod(a,b)
%UPDATEMOD Update model structure to be compatible with the current version.
% INPUT(S):
%    modl = the model to be updated (modl).
%    data = the original data if the model was created by a PLS_Toolbox
%           version before 2.0.1c (this data must also be supplied).
%  
% OUTPUT:
%   umodl = an updated model (umodl).
%
%I/O: umodl = updatemod(modl);        %update post-v2.0.1c model
%I/O: umodl = updatemod(modl,data);   %update pre-v2.0.1c model
%
%See also: ANALYSIS, EVRIMODEL, PCA, PCR, PLS

%Copyright Eigenvector Research 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS
%jms 3/19/02 -revised calls to preprocess
%jms 3/20/02 -modified 'nip' and 'sim' updates to be 'pls' modeltype
%jms 8/28/02 -combined updatemod with updatemod3
%rsk 03/29/06 -populate 'type' field in datasource as "data".

if nargin==0; a = 'io'; end

if ischar(a)    %Help, Demo, Options
  varargin{1} = a;
  options = [];
  if nargout==0; clear a; evriio(mfilename,varargin{1},options); else; a = evriio(mfilename,varargin{1},options); end
  return; 
  
end

a = evrimodel(a);
