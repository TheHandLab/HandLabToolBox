% create tone stimulus
% USAGE: tone = bl_tone(freq, sampfreq, dur, [amp])
% freq = frequency of tone in Hz
% sampfreq = sample frequency in Hz (e.g., 44100, 22050, 11025Hz)
% dur = duration in s
% amp = relative amplitude (0-1), default = 1
function tone=hl_tone(freq, sampfreq, dur, amp)
if nargin<3 || nargin>4 || isempty(freq) || isempty(sampfreq) || isempty(dur)
 usage('bl_tone(freq, sampfreq, dur, amp)');				% incorrect input
end
if nargin==3 amp=1; end										% default amplitude
if nargin==4
 if isempty(amp) amp=1; end									% default amplitude
end
tone=sind([0:round(sampfreq.*dur)-1]'.*(freq.*360./sampfreq)).*hl_envelope(sampfreq, dur).*amp;%create tone