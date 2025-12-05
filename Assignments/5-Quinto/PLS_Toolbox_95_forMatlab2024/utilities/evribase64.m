%EVRIBASE64 Base64 encode/decode object
% Encodes and decodes double from base64 encoding

%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

classdef evribase64
  
  properties (Constant, Access = private)
    charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  end
  
  methods
    
    function this = evribase64
      %constructor
    end
    
    function delete(this)
      %destructor
    end
    
  end
  
  methods  (Static = true)
    
    function str = encode(in,precision)
      %BASE64ENCODE Encode a vector as a base-64 encoded string.
      % optional input precision is the specified numeric precision for
      % encoding of the string. Valid precisions are:
      %  8 = uint8
      %  32 = single precision floating point
      %  64 = double precision floating point (default)
      %
      %I/O: str = base64decode(in,precision)
      
      if nargin<2
        precision = 64;
      end
      
      %vectorize by rows
      in = in(:);
      
      %encode in binary
      switch precision
        case {1}
          en = logical(in)';
        case {8}
          en = dec2bin(in);
          en = (en=='1');
          en = [false(size(en,1),8-size(en,2)) en]';  %pad leading to get 8 bits
        case {32 64}
          en = evribase64.float2bin(in,precision);          
      end
            
      %reshape to 6 bits per
      bin = en(:)';
      bin = [bin false(1,6-mod(length(bin),6))];  %pad trailing chars to be interval of 6 characters
      bin = reshape(bin,6,length(bin)./6);
      
      %convert back to decimal and encode as character
      dec = (2.^(5:-1:0))*bin;
      str = evribase64.charset(dec+1);
      
    end
    
    %- - - - - - - - - - - - - - - - - - - - - -
    function out=decode(str,precision,endian)
      %BASE64DECODE Decode a base-64 encoded vector.
      % optional input precision is the specified numeric precision for
      % decoding of the string. Valid precisions are:
      %  1 = binary
      %  8 = uint8
      %  32 = single precision floating point
      %  64 = double precision floating point (default)
      % additional input endian allows for decoding of big or small endian
      % encoding using the string 'b' or 's' (default = 'b')
      %
      %I/O: out = base64decode(str,binary)
      
      if nargin<2
        precision = 64;
      end
      if nargin<3
        endian = 'b';
      end
      
      str(str==' ') = [];  %drop spaces
      
      %create translation string
      trans = 0;
      trans(evribase64.charset) = 0:63;
      trans = dec2bin(trans)';
      trans = trans=='1';   %get BINARY form
      
      %check for bad characters
      if any(str>size(trans,2))
        error('Input string contains illegal base64 characters')
      end
      
      %translate into binary by indexing into translation matrix
      bin = trans(:,str);
      bin = bin(:);
      if precision>1
        bin = bin(1:floor(length(bin)/8)*8);   %cut off unneeded bits at end
        bin = reshape(bin,8,length(bin)/8);   %reshape for projection
      end
      
      switch precision
        case {1}
          %keep as binary
          out = bin;
        case 8
          %convert to decimal
          pwr = 2.^(7:-1:0);
          out = pwr*bin;
        case {32 64}
          out = evribase64.bin2float(bin,precision,endian);
        otherwise
          error('Unrecognized precision option')
      end
      
    end
    
    %   end
    %     %----------------------------------------------------------
    %   methods (Static = true, Access = private)
    
    %- - - - - - - - - - - - - - - - - - - - - -
    function out = float2bin(in,precision)
      %BIN2FLOAT converts a binary array into floating point
      %I/O: out = bin2float(in,precision)
      
      if nargin<2
        precision = 64;
      end

      f = evribase64.getfloatprop(precision);
      
      in   = in(:)';
      in   = double(in);
      nval = length(in);
      sg   = sign(in);
      in   = abs(in);
      po   = floor(log(in)/log(2));
      fl   = in./(2.^po)-1;

      po(sg==0) = -f.bias;
      fl(sg==0) = 0;
      
      sgbin = sg==-1;
      pobin = diff([zeros(1,nval); diag(f.epwr)*floor((1./f.epwr')*(po+f.bias))])~=0;
      flbin = diff([zeros(1,nval); diag(f.fpwr)*floor((1./f.fpwr')*fl)])~=0;

      out = [sgbin;pobin;flbin];
      
    end
    
    %- - - - - - - - - - - - - - - - - - - - - -
    function out = bin2float(in,precision,endian)
      %BIN2FLOAT converts a binary array into floating point
      %I/O: out = bin2float(in,precision)
      
      if nargin<2
        precision = 64;
      end
      if nargin<3
        endian = 'b';
      end
      
      if ~islogical(in)
        %input wasn't binary already
        in = dec2bin(in)'=='1';
      end

      f = evribase64.getfloatprop(precision);
      
      if mod(numel(in),(8*f.nbytes))
        %can't get enough values? return empty
        out = [];
        return
      end
      
      if strcmpi(endian,'l')
        in  = fliplr(reshape(in,[8 f.nbytes numel(in)/(8*f.nbytes)]));
        in = in(:,:);
      end
      in  = reshape(in,8*f.nbytes,numel(in)/(8*f.nbytes));

      %get power and fraction and combine into floating point
      po = f.epwr*in(2:f.ebits+1,:);
      fr = (f.fpwr*in(f.ebits+2:end,:));
      out = (1-in(1,:)*2) .* (1+fr) .* 2.^(po-f.bias);
      out(po==0 & fr==0) = 0;  %items where power and fraction are zero = 0
      
    end
    
    %- - - - - - - - -    
    function f = getfloatprop(precision)
      %defines float conversion properties
      
      switch precision
        case 32
          f.nbytes = 4;
          f.ebits = 8;
          f.epwr = 2.^(7:-1:0);
          f.fpwr = 2.^(-(1:23));
          f.bias = 127;
          
        case 64
          f.nbytes = 8;
          f.ebits = 11;
          f.epwr = 2.^(10:-1:0);
          f.fpwr = 2.^(-(1:52));
          f.bias = 1023;
          
        otherwise
          error('Invalid option for precision')
      end

    end
    
  end  %private methods
  
end
