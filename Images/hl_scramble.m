% takes a 2 or 3D matrix as input and randomly scrambles the first two dimensions (columns x
% rows, with scrambling chunk size defined by h and w (chunks per dimension).
% returns the scrambled matrix. matrix size must be divisible by chunk size in each dimension
% suitable for images...
function scrambled = bl_scramble(input,h,w)
 if nargin<1 || nargin>3 usage ('bl_scramble(input [, h] [, w] ), default: h & w = 10 chunks, with 2 inputs, default: w=h'); end
 if (ndims(input)==2 && min(size(input))==1) || ndims(input)>3 error ('bl_scramble: input matrix must be 2D or 3D'); end
 height = size(input,1); width  = size(input,2);
 if nargin==1                           						% if no chunk dimensions requested
  if height>9	h=10;             							% height chunks = 10
  else          h=height;         							% or less
  end
  if width>9    w=10;             							% width chunks = 10
  else          w=width;          							% or less
  end
 end
 if nargin==2                           						% if only a height chunk dimension requested
  if height > 10 w = h; end             						% width chunks = height chunks
 end
 if h>height warning('too many vertical chunks: using default');   h = 10; end		% too many vertical chunks
 if w>width  warning('too many horizontal chunks: using default'); w = 10; end		% too many horizontal chunks
 if mod(height,h)~=0 error('height is not divisible by vertical chunks');  end		% not divisible integer vertical chunks
 if mod(width,w)~=0  error('width is not divisible by horizontal chunks'); end		% not divisible integer horizontal chunks
 rand('state',sum(100*clock));               						% set the generator to a random state
 chunk = [height/h width/w];            						% chunk dimensions
 scrambled = cell(h*w,1);               						% cell array of chunks
 c = 0;											% chunk counter
 for m = 1:w                            						% for each chunk along the height
  for n = 1:h                           						% and for each chunk across the width
   c=c+1;										% chunk counter
   scrambled{c} = input((n-1)*chunk(1)+1:n*chunk(1),(m-1)*chunk(2)+1:m*chunk(2),:);	% load chunks into cell array of matrices
  end
 end
 scrambled = cell2mat(reshape(scrambled(randperm(h*w)),h,w));				% randomise chunk order, resize, convert to matrix
end