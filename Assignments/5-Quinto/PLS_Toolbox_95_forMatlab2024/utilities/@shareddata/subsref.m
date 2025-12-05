function varargout = subsref(obj,sub,varargin)
%SHAREDDATA/SUBSREF Subscript reference for shareddata

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

switch sub(1).type
  case '()'
    %pre-index into object array
    out = obj(sub(1).subs{:}); %shareddata(subsref(double(obj),sub(1)));
    
  case '.'
    
    if length(obj)>1
      %handle arrays
      for j=1:length(obj);
        varargout{j} = subsref(obj(j),sub);
      end
      return
    else
      %single object    
      switch sub(1).subs
        case 'id'
          %indexing into field
          out = obj.id;

        case 'object'
          data = getshareddata(obj,'all');
          if isempty(data)
            out = data;
          else
            out = data.object;
          end
          
        case 'links'
          data = getshareddata(obj,'all');
          if length(sub)>1 & strcmp(sub(2).type,'.')
            if isempty(data)
              error('cannot change links on empty shared data object')
            end
            if length(sub)<3 | ~strcmp(sub(3).type,'()')
              error('add or remove links actions require input of source handle')
            end
            switch sub(2).subs
              case 'add'
                cmd = sub(3).subs;
                linkshareddata(obj,'add',cmd{1:end});
              case 'remove'
                cmd = sub(3).subs;
                linkshareddata(obj,'remove',cmd{1:end});
            end
            sub = sub(1); %dump all other sub indexing
            varargout = {};
            return
          else
            %only one sub index OR indexing isn't '.'
            if isempty(data)
              out = data;
            else
              out = data.links;
            end
          end

        case 'properties'
          data = getshareddata(obj,'all');
          if isempty(data)
            out = data;
          else
            out = data.properties;
          end
          %apply any . field indexing we found (and return empty if property
          %not defined)
          if length(sub)>1 && strcmp(sub(2).type,'.')
            if isfield(out,sub(2).subs)
              out = out.(sub(2).subs);
            else
              out = [];
            end
            sub = sub([1 3:end]);
          end


        case 'source'
          out = getshareddata(obj,'handle');

        case 'siblings'
          out = getshareddata(obj,'list');
          if ~isempty(out);
            out([out{:,1}]==obj,:) = [];
          end

        otherwise
          %check for additional input parameters (as (...) input)
          args = {};
          if length(sub)==2
            if strcmp(sub(2).type,'()')
              args = sub(2).subs;
            else
              error('Unsupported method call format');
            end
          elseif length(sub)>2
            error('Unsupported method call format');
          end

          %call method
          if nargout==0
            feval(sub(1).subs,obj,args{:});
          else
            out = feval(sub(1).subs,obj,args{:});
          end

      end
    end
    
  otherwise
    error('Invalid indexing into Shared Data object');

end

if length(sub)>1
  if nargout>0;
    nout = nargout;
  else
    nout = 1;
  end
  for j=2:length(sub)-1;
    out = subsref(out,sub(j));
  end
  [varargout{1:nout}] = subsref(out,sub(end));
else
  varargout = {out};
end
