function out = clipboard_image(mode,img,options)
%CLIPBOARD_IMAGE Copy and paste images to/from the system clipboard.
%  This function will only write 1 or 3 slabs of an image.
%
%  INPUTS:
%    mode - ['copy'|'paste'] Set or get current clipboard.
%    img  - [numeric or DSO] Image data to paste to clipboard.
%
%  OUTPUTs:
%    out - Image DSO of image data found on clipboard.
%
%  OPTIONS:
%    usescale - [{'yes'}|'no'] Use scaletouint8 to scale image data before
%               export.
%  EXAMPLE:
%    load smbread
%    clipboard_image('copy',bread.imagedata(:,:,1));%Single slab.
%    clipboard_image('copy',bread.imagedata(:,:,1:3));%Three slabs.
%
%I/O: clipboard_image('copy',img,options)
%I/O: out = clipboard_image('paste',[],options)
%
%See also: EDITDS, MIAGUI

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%RSK 7/2009

%NOTE: Bob led me to editmenufcn where they use a builtin java object
%(com.mathworks.hg.util.load ) that replaced evriImageWriter.
%
%   cb = java.awt.Toolkit.getDefaultToolkit.getSystemClipboard;
%   cb.setContents(com.mathworks.hg.util.ImageSelection(im_obj),[]);

if nargin<1; mode = 'io'; end

if any(strcmp(mode,evriio([],'validtopics')));
  options = [];
  options.usescale = 'yes';
  if nargout==0; evriio(mfilename,mode,options); else; out = evriio(mfilename,mode,options); end
  return;
end

if nargin<3
  options = clipboard_image('options');
else
  options = reconopts(options,mfilename);
end

switch mode
  case 'copy'
    %Copy data to system clipboard.
    try
      
      %Pull data from dataset.
      if isdataset(img)
        if strcmp(img.type,'image')
          img = img.imagedata;
        else
          img = img.data;
        end
      end
      
      if strcmpi(options.usescale,'yes')
        img = scaleint8(img);
      end
      
      %Keep commented out reference to old custom java clipboard object.
      %Does't work at all on Mac but may in future.
      %writerobj = evriImageWriter;
      
      %Create java image and send to clipboard.
      if ndims(img)<4
        if ismac
          writeimageonmac(img)
        else
          img = im2java(img);
          cb = java.awt.Toolkit.getDefaultToolkit.getSystemClipboard;
          cb.setContents(com.mathworks.hg.util.ImageSelection(img),[])
          %writerobj.setClipboard(img)
        end
      end
      
    catch
      error(['Can''t write image to clipboard.' lasterr]);
    end
  case 'paste'
    %Paste data from system clipboard.
    try
      myToolKit = java.awt.Toolkit.getDefaultToolkit;
      sysClipboard = myToolKit.getDefaultToolkit.getSystemClipboard();
      
      % get the contents on the clipboard in a Transferable object
      clipboardContents = sysClipboard.getContents([]);
      
      %Make sure content on clipboard is falls under a format supported by
      %the imageFlavor Flavor.
      if clipboardContents.isDataFlavorSupported(java.awt.datatransfer.DataFlavor.imageFlavor)
        %convert the Transferable object to an Image object
        image = clipboardContents.getTransferData(java.awt.datatransfer.DataFlavor.imageFlavor);
      else
        evriwarndlg('Can''t find image data on clipboard.','No Image Warning')
        data = [];
        return
      end
      out = createimage(image);
      if evriio('mia')
        out = createimage(image);
      else
        out = dataset(double(image));
      end
      %data = image.getData.getDataBuffer.getData;
      %data = reshape(data,image.getWidth,image.getHeight);
    catch
      evrierrordlg({'Can''t read image data on clipboard.','Image Read Error',lasterr})
      out = [];
    end
    
  otherwise
    error('Unrecognized clipboard mode.')
end

%---------------------------------------------
function out = createimage(javaImage)
%Creat a numeric image from java image.
%  Example from:
%  http://www.mathworks.com/support/solutions/en/data/1-2WPAYR/?solution=1-2WPAYR

H=javaImage.getHeight;
W=javaImage.getWidth;

out = zeros([H,W,3],'uint8');
pixelsData = reshape(typecast(javaImage.getData.getDataStorage,'uint32'),W,H).';
out(:,:,3) = bitshift(bitand(pixelsData,256^1-1),-8*0);
out(:,:,2) = bitshift(bitand(pixelsData,256^2-1),-8*1);
out(:,:,1) = bitshift(bitand(pixelsData,256^3-1),-8*2);

%---------------------------------------------
function sx = scaleint8(x)

wnstate = warning;
try
  warning off
  sz = size(x);
  if length(sz)>2;
    x = reshape(x,prod(sz(1:end-1)),sz(end));
  end
  m       = size(x,1);
  minx    = min(x);
  rangx   = max(x) - minx;
  rangx(rangx==0) = 1;
  sx      = uint8(255*(x - minx(ones(m,1),:))./rangx(ones(m,1),:));
  if length(sz)>2;
    sx = reshape(sx,sz);
  end
catch
  sx = [];
end
warning(wnstate);

%---------------------------------------------
function writeimageonmac(x)
%Write to temp file on Mac then Apple Script the image to the clipboard.

tmpname = fullfile(tempdir,'evriclipboardimage.jpg');
imwrite(x,tmpname);
system(['osascript -e ''set the clipboard to (read ("' tmpname '") as JPEG picture)''']);
