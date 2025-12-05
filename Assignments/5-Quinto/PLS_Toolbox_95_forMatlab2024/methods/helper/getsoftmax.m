function [y] = getsoftmax(x)
% Apply softmax to rows of x to convert each row's entries to values in
% range [0,1] and having row entries summing to 1.
% For each row, the column with the largest x entry gets the largest value
% in the corresponding output y row.
% Softmax uses natural exponentiation to base "e".
%
% INPUTS:
%        x  = row vector or matrix
% OUTPUTS:
%        y  = row vector or matrix

% [x] = useotherbase(x, 10);
maxbound = 100; % limit to avoid overflow when exponentiated
maxx = max(x,[],2);
ibound = maxx > maxbound;
maxx = repmat(maxx, 1, size(x,2));
%x(ibound,:) = x(ibound,:)./maxx(ibound,:) *maxbound;
x = x - maxx;
exp_1 = exp(x);
sum_exp_1 = sum(exp_1,2);

ny = size(x,2);
if ny > 1
  sum_exp_1 = sum(exp_1,2)*ones(1,ny);
end
y = exp_1./sum_exp_1;
end

%--------------------------------------------------------------------------
function [x] = useotherbase(x, b)
% To use base b (>0), multiply x by log(b)
% b > 1 results in larger output for the largest input x value relative to
%   other x values.
% b = 1; % do not apply since 1 is inappropriate as a base
% b < 1 has the undesirable, inverse effect to b>1 where largest input x
%   value gets smallest output value, so not appropriate for conversion of
%   input to a probability

if b>eps
  logb = log(b);
  if b<1 | b> 1
    x = x*logb;
  end
end
end