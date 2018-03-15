% create series of tone stimuli of increasing frequency within an octave
% USAGE: octave_tones = bl_octave(basefreq, sampfreq, dur [, tones] [, amp])
% basefreq = frequency of first tone in series (e.g., 440Hz = middle C)
% sampfreq = sampling frequency in Hz (e.g., 44100, 22050, 11025, 8000)
% dur = duration of tones in s
% tones = number of tones in the series (first = base freq), default = 12
% amp = amplitude of tones, default = 1
function octave_tones = bl_octave(basefreq, sampfreq, dur, tones, amp)
if nargin<3 || nargin>5 || isempty(basefreq) || isempty(sampfreq) || isempty(dur)
 usage('octave_tones = bl_octave(basefreq, sampfreq, dur [, tones] [, amp])');	% incorrect input
end
if nargin==3 tones=12; amp=1; end						% default tones and amplitude
if nargin==4 amp=1; end								% default amplitude
if isempty(tones) tones=12; end							% default tones
if isempty(amp) amp=1; end							% default amplitude
octave_tones = zeros(sampfreq.*dur,tones);					% variable for output
for n=1:tones
 octave_tones(:,n) = bl_tone(basefreq.*2.^((n-1)/tones), sampfreq, dur).*amp;	% create this tone
end