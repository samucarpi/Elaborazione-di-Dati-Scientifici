function c = evricopyobj(h,p)
%EVRICOPYOBJ Overload of copyobj for 2014b and newer that copies callbacks.
% New behavior of 14b+ is to not copy callback so we need to manually do
% it. This is run once in getplspref.
%
%I/O: c = evricopyobj(h,p)
%
%See also: GETPLSPREF, COPYOBJ

%Copyright © Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.

c = copyobj(h,p);

if checkmlversion('>=','8.4')
  %Need to manually copy over Callbacks. Do in subfunction so can
  %recursively call.
  if length(h)==1 & length(p)>1
    %Spoof vector of p.
    copycallbacks(repmat(h,[1 length(c)]),c)
  elseif length(h)==length(c);
    copycallbacks(h,c);
  else
    error('Something not working in COPYOBJ overload.')
  end
end

%------------------------------------------------------
function copycallbacks(h,c)
%copyobj call above will error if lengths are bad.

for i = 1:length(h)
  myctrl_h = h(i);
  myctrl_c = c(i);
  mychild_h = allchild(myctrl_h);
  if ~isempty(mychild_h)
    %Recursive.
    mychild_c = allchild(myctrl_c);
    copycallbacks(mychild_h,mychild_c)
  end
  if isprop(myctrl_c,'Callback')
    set(myctrl_c,'Callback',get(myctrl_h,'Callback'));
  end
end
    
  
