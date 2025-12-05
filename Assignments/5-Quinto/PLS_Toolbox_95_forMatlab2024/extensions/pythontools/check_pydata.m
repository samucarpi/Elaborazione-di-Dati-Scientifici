function [newdata] = check_pydata(data)
%CHECK_PYDATA Reshape Python data for Python methods
%   Python methods complain when data is fed in where the there is a single
%   sample, a single column, or a single numeric value. This function will
%   assume 'data' is two-way and return data in an appropriate manner.

if ndims(data)~=2
  newdata=data;
end


%if either num samples is 1 or num variables is1, Python interprets that as
%a 1D array. These methods need 2D arrays.
if (size(data,1)==1 || size(data,2)==1) && ~contains(class(data),'py.')
  %single row, or single sample? either way Python complains
  if size(data,2)==1 && size(data,1)~=1
    %reshape array to be of size [nsamples 1] instead of (nsamples,)
    newdata = py.numpy.array(data).reshape(py.int(-1),py.int(1));
  else
    %reshape array to be of size [1 nvariables] instead of (nvariables,)
    newdata = py.numpy.array(data).reshape(py.int(1),py.int(-1));
  end
else
  newdata = py.numpy.array(data);
end
end

