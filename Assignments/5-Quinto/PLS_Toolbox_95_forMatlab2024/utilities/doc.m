function doc(topic)
%DOC Overload of the Matlab DOC function to trap calls for EVRI products.
% Later versions of Matlab do not permit add-on product to access their
% HTML pages through the DOC command. This function is a wrapper/overload
% of the Matlab DOC function which will identify when the user is asking
% for help on an Eigenvector Research, Inc. product and use our own help
% system in place of the Mathworks DOC function. If the user is asking for
% help on a Matlab function, the standard DOC function is called.
%
%I/O: doc topic

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

persistent evridirs

evrifunction = false;

if nargin<1
  topic = '';
else
  file = which(topic);
  
  if isempty(evridirs)
    %identify top-level EVRI product folders
    evridirs = which('evrirelease','-all');
    for j=1:length(evridirs);
      evridirs{j} = fileparts(evridirs{j});
    end
  end
  
  %look to see if the requested function is in any of those folders
  
  for j=1:length(evridirs)
    if ~isempty(findstr(file,evridirs{j}))
      evrifunction = true;
      break;
    end
  end
end

%call appropriate help
if evrifunction
  success = evrihelp(topic);
  if ~success
    helpwin(topic);
  end
else
  docs = which('doc.m','-all');
  docdir = fileparts(docs{2});
  mydir = pwd;
  cd(docdir)
  try
    if isempty(topic)
      doc
    else
      doc(topic)
    end
  catch
    cd(mydir)
    rethrow(lasterror)
  end
  cd(mydir)
end
