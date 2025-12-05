function val = subsref(varargin)
%EVRIADDON/SUBSREF Retrieve fields of EVRIADDON objects.
% Generic indexing for evriaddon objects. Any method or entry point (as
% defined in evriaddon_connections) can be retrieved using a generic form
% of SUBSREF calls:
%   obj = evriaddon;
%   obj.product_name    %call the specified "product_name" method
%   obj.entrypoint      %retrieve entry point "entrypoitn"
% Alternatively, this can be called from the instancing of an evriaddon
% object by simply passing the product, method or entry point name as the
% sole input to an evriaddon call (see EVRIADDON/EVRIADDON)

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = varargin{1};
m   = methods(obj);
S   = varargin{2};
if ~strcmp(S(1).type,'.')
  error('Invalid indexing for EVRIAddOn object');
end

conn = evriaddon_connection;

switch S(1).subs
  case conn.entrypoints
    %return function handle list from all products' evriaddon_connection objects
    val = {};
    index = [];
    p = products(obj);
    key = S(1).subs;
    for j=1:length(p);
      item = feval(['addon_' p{j}],obj);
      fns = item.(key);
      val = [val fns];
      index = [index ones(1,length(fns)).*item.priority];
    end
    [what,priority] = sort(index);
    val = val(priority);

  case m
    val = feval(S(1).subs,obj);
    
  otherwise
    switch ['addon_' S(1).subs]

      case m
        %return evriaddon_connection object from given product's method
        val = feval(['addon_' S(1).subs],obj);

      otherwise
        error(['"' S(1).subs '" is not a valid EVRIAddOn product or connection']);
    end
end

%Apply sub-indexing on whatever is left in input line (if anything else
%passed)
if length(S)>1;
  val = subsref(val,S(2:end));
end
