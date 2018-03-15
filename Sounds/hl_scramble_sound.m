% soundout = bl_scramble_sound(soundin, sampfreq, dur, chunks [, type])
% soundin = 1D sound vector to scramble (can be longer than the output)
% sampfreq = sample frequency of the sound in Hz (e.g. 44100, 22050, 11025)
% dur = in s of output sound
% chunks = number of chunks to divide input into, or number of times to repeat, default = 20
% type of scrambling (default = 1)
%  1: re-order the chunks of the input, then take the first chunks until output length reached
%  2: repeatedly resample the input chunks times, and add it to the output (input should be much longer than dur)
function soundout = bl_scramble_sound(soundin, sampfreq, dur, chunks, type)
if nargin<3 || nargin>5 || isempty(soundin) || isempty(sampfreq) || isempty(dur)
 usage('bl_scramble_sound(soundin, sampfreq, dur [, chunks] [, type])');
end
if min(size(soundin))~=1 error('bl_scramble_sound: soundin must be of length n x 1'); end
if rows(soundin)==1 soundin=soundin'; end				% rearrange into a column
samples = dur.*sampfreq;						% samples in the output
if length(soundin)<samples error('bl_scramble_sound: input sound is shorter than the requested output'); end
if nargin==3 chunks=20; type=1; end					% default chunks and scramble type
if nargin==4
 if isempty(chunks) chunks=20; end					% default chunks
 type=1;								% and scramble type
end
if nargin==5
 if isempty(chunks) chunks=20; end					% default chunks
 if isempty(type) type=1; end						% and scramble type
 if type==1 && chunks>samples error('bl_scramble_sound: number of requested chunks is larger than the number of input samples'); end
end
rand('state',sum(100*clock));               				% set the generator to a random state
chunklen = round(rows(soundin)./chunks);				% length of each chunk
chunksin = round(rows(soundin)./chunklen);				% chunks of input
soundin2 = cell(chunksin,1);						% cell array of matrices for randomising
soundout = zeros(samples,1);						% variable for output
switch type								% scramble type:
case {1}								% RANDOMISED ORDER
 for n=1:chunksin-1							% for each chunk of soundin				
  soundin2{n} = soundin((n-1).*chunklen+1:n.*chunklen);			% load chunks into cell array
 end
 soundin2{chunksin} = soundin((chunksin-1).*chunklen:end);		% last chunk can be a different size
 soundout = cell2mat(soundin2(randperm(chunks)));			% randomise chunk order and take first sample
 soundout = soundout(1:samples);					% take the first samples only
case {2}								% OVERLAPPING CHUNKS
 for n=1:chunks                                       			% loop to select chunks to overlap
  start = ceil(rand.*(length(soundin)-samples+1));         		% choose random start point in input sound
  soundout = soundout+soundin(start:(start+samples-1));  		% add this stimulus chunk to stimulus
 end
 soundout = soundout.*(2./(max(soundout)-min(soundout))); 		% scale to +/-1
end