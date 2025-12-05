function newlbl = getheaderlabel(oldlbl)
%GETHEADERLABEL Adds HTML break into string so looks better when displayed
%in SSQ table.

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

oldlbl = strtrim(oldlbl);
newlbl = oldlbl;
try
  strpos = strfind(oldlbl,' ');
  if ~isempty(strpos)
    %Found spaces. Get spaces less than 12 but greater than 4 because that's
    %roughly what fits best in header column.
    shortpos = strpos(strpos<12);
    shortpos = shortpos(shortpos>4);
    if ~isempty(shortpos)
      newlbl = [oldlbl(1:shortpos(end)-1) '<br>' oldlbl(shortpos(end)+1:end)];
    else
      %See if there's a space char within reason. Might not look great but
      %shold be more legible.
      shortpos = strpos(strpos>12);
      shortpos = shortpos(shortpos<25);
      if ~isempty(strpos)
        newlbl = [oldlbl(1:shortpos(1)-1) '<br>' oldlbl(shortpos(1)+1:end)];
      end
    end
  end
catch
  %Don't make a lable a fatal error. Just use original label.
  newlbl = oldlbl;
end
