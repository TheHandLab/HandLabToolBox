% create amplitude-modulated white noise stimulus
% USAGE: amnoise = bl_amnoise(sampfreq, dur, modfreq [, moddepth] [, phase])');
% sampfreq in Hz (e.g., 44100, 22050, 11025)
% duration in s
% modfreq in Hz
% moddepth as a proportion (0-1, default=0.8)
% phase in degrees (0-360, default=0)
function amnoise=bl_amnoise(sampfreq, dur, modfreq, moddepth, phase)
if nargin<3 || nargin>5 || isempty(sampfreq) || isempty(dur) || isempty(modfreq)
 usage('bl_amnoise(sampfreq, dur, modfreq [, moddepth] [, phase])');
end
if nargin==3 moddepth=0.8; phase=0; end
if nargin==4 phase=0; end
if isempty(moddepth) moddepth=0.8; end
if isempty(phase) phase=0; end
% random noise from -1 to +1, shaped with depth-modulated sinusoid
amnoise=2.*rand(round(sampfreq.*dur),1)-1;										% random noise
amnoise=amnoise.*(((((sind([1:round(sampfreq.*dur)]'.*modfreq.*360./sampfreq+phase))+1)./2).*moddepth)+(1-moddepth));	% sinusoid

