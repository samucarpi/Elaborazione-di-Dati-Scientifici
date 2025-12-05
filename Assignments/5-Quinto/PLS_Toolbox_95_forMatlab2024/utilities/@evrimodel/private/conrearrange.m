function con = conrearrange(con,model)
%CONREARRANGE Adjusts contributions matrices to match original data.
% Rearranges the contributions according to the model-stored unmap
% information, and contributions details.
%
%     con = vector or matrix of contributions.
%   model = model for which the contributions were calculated.
%
% The variable unmap information and contribution method inforation is
% derrived from the model:
%  matchvarsmap = vector describing how the variables were re-arranged (if
%           at all, empty = no rearrangement was done.) 
%  contributions = [ {'passed'} | 'used' | 'full' ] Governs detail of
%           returned T^2 and Q contributions. Return contributions for:
%        'passed' = only the variables passed by the client in the order
%            passed. This mode allows the client to easily map
%            contributions back to passed data and is the preferred mode.
%        'used'   = all variables used by the model including even
%           variables which client did not provide. Variable order is that
%           used by model and may not match the order passed by the client.
%        'full'   = all variables used or excluded by the model,
%           including even variables which client did not provide. Variable
%           order is that used by model and may not match the order passed
%           by the client.
%
%I/O: con = conrearrange(con,model)

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS

if strcmpi(model.contributions,'used')
  %USED here - do NOTHING
  return
end

%PASSED and FULL here - map in non-included variables
temp = ones(1,model.content.datasource{1}.size(2))*nan;
temp(model.content.detail.includ{2}) = 1:length(model.content.detail.includ{2});
con = matchvars(con,temp);
con(isnan(con)) = 0;

if strcmpi(model.contributions,'passed');
  %PASSED only here - readjust for original order of user-passed vars
  if ~isempty(model.matchvarsmap)
    con = matchvars(con,model.matchvarsmap);
    con(isnan(con)) = 0;
  end
end
