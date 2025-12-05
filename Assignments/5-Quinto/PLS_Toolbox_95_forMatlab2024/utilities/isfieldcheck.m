function sfield = isfieldcheck(subfields, strct)
%ISFIELDCHECK Utility for checking each field level in a nested structure array.
% Checks for presence of field matching each level of a submitted string
% delimited by "." from left to right. Returns true if all nested fields
% exist. Returns false otherwise. Also returns false if invalid information
% is passed. NOTE! Unlike the Matlab function ISFIELD, the fieldname input
% to ISFIELDCHECK must contain an initial '.' or place-holder variable
% name: 'myvar.firstfield.subfield.etc'.
%
% INPUT:
%     strct     = a structure to check for a given field
%     subfields = the string deliniating the field to look for
% OUTPUT:
%     sfield = a boolean value indicating the presence of the specified
%              fields.
%
% EXAMPLE:
%    isfieldcheck(modl,'.detail.rmsecv')
%
%I/O: sfield = isfieldcheck(strct, subfields)
%
%See also: GETSUBSTRUCT, SETSUBSTRUCT

%Copyright Eigenvector Research 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 01/14/2004
%jms 04/2004 -changed performance with non-structures (return false, like "isfield" does)

if nargin==2 && isstr(strct);
  %reverse order
  temp = subfields;
  subfields = strct;
  strct = temp;
end
if ~isstr(subfields)
  error('Input (subfields) must be a string');
end
if ~isstruct(strct);
  sfield = false;
  return
end
if isempty(subfields)
  sfield = false;
  return
end

% handle unusual inputs
if isempty(strfind(subfields,'.')) 
  %missing .? return false no matter what (do not allow simple "isfield"
  %style calls because of ambiguity in what the user really wanted. "s1"
  %should NOT be the same as "var.s1" because "s1.s2" is NOT the same as
  %"var.s1.s2" !
  sfield = false;
  return
end
if subfields(1)=='.'
  %initial character is .? assume whatever.___
  subfields = ['whatever' subfields];
end
  
if length(subfields) > 1 && subfields(end) ~= '.'

	% Parse fields into character array.
  L1 = regexp(subfields,'\.','split');
	
	%Step through, testing for field at each level. If field is not present then set
	%sfield to 0 and break. Otherwise finish loop and set sfield to 1.
	for i = 2:length(L1)
      if isfield(strct,L1{i})
        %grab that sub-field for next level's tests
        strct = strct(1).(L1{i});
      else
        %not found exit now
        sfield = false;
        return
      end
      
	end 
	
	sfield = true; %got here because we found all fields, exit with true
  
else
  sfield = false;
end
