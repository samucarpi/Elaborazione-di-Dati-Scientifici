function varargout = subsasgn(obj,sub,val,varargin)
%SHAREDDATA/SUBSASGN Subscript assignment reference for shareddata

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

switch sub(1).type
  case ['(' ')']
    %pre-index into object array
    if length(sub)>1;
      %doing sub-scripting? The odd thing about this is that we don't have
      %to actually save these changes because the object handle will
      %automatically be updated!
      subsasgn(obj(sub(1).subs{:}),sub(2:end),val);
    else
      %just replaceing one object with another or building an array
      obj(sub(1).subs{:}) = val; %shareddata(subsref(double(obj),sub(1)));
    end
    
  case '.'
    switch sub(1).subs
      case 'object'
        subobj = getshareddata(obj,'private');
        keyword = {};  %unknown assignment keyword

        le = [];
        try
          if length(sub)>1
            %indexing more? use subssgn
            keyword{1} = sub(2).subs;  %and store the sub-field name for use as a keyword
            if ~ischar(keyword{1}); keyword = {}; end  %unless it isn't a string
            subobj = subsasgn(subobj,sub(2:end),val);
          else
            %direct assignment
            subobj = val;
          end
        catch
          le = lasterror;
        end
       
        setshareddata(obj,subobj,keyword{:});
        
        if ~isempty(le);
          %if error was thrown during assignment, throw it AFTER
          %re-assigning the shared data object (or else we'll lose it
          %because we used "private" shared data extraction)
          rethrow(le);
        end
        
      case 'links'
        error(['Use obj.links.add(' ') or obj.links.remove(' ') calls to modify links'])
        
      case {'properties' 'propertiesquiet'}
        
        newprops = [];
        if length(sub)>=2 & ~strcmp(sub(2).type,'.')
          %indexing is not .field??
          error('Must supply property name to modify')
        end
        if length(sub)<2
          %no field.. check for structure array as input
          if ~isstruct(val)
            error('Must supply property name to modify')
          end
          newprops = val;
        elseif ismember(lower(sub(2).subs),{'timestamp' 'removeaction'})
          error('Unable to modify this property directly')
        end

        keyword = {};
        if length(sub)>1
          %if property field given...
          if length(sub)>2
            %indexing more? use subssgn
            subobj = getshareddata(obj,'all');
            subobj = subobj.properties.(sub(2).subs);
            val = subsasgn(subobj,sub(3:end),val);
          end
          newprops.(sub(2).subs) = val;
          if strcmp(sub(2).subs,'selection')
            keyword = {'selection'};
          end
        end
        
        if ~strcmp(sub(1).subs,'propertiesquiet')
          updatepropshareddata(obj,'update',newprops,keyword{:})
        else
          updatepropshareddata(obj,'update',newprops,'quiet')
        end
        
      otherwise
        error('Invalid property for shared data');
        
    end
    
  otherwise
    error('Invalid subscripting for shared data object')

end

if nargout>0
  varargout = {obj};
end
