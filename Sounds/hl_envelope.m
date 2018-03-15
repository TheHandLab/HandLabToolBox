% create a trapezoidal envelope to multiply with an auditory stimulus
% bl_envelope(sampfreq, dur [, rise] [, fall])
% sampfreq in Hz (e.g., 44100, 22050, 11025Hz)
% duration in s
% rise time in ms (default = 10)
% fall time in ms (default = rise time)
function envelope = hl_envelope(sampfreq, dur, rise, fall)
if nargin<2 || nargin>4
 usage('hl_envelope(sampfreq, dur [, rise] [, fall])');
end
if isempty(sampfreq) error('hl_envelope: 1st argument (sampfreq in Hz) required'); end
if isempty(dur)      error('hl_envelope: 2nd argument (duration in s) required'); end
if nargin==2 rise = 10; fall = 10; end
if nargin==3
 if isempty(rise) rise = 10; end
 fall=rise;
end
if nargin==4
 if isempty(rise)
  if isempty(fall) rise=10; fall=rise;
  else rise=fall;
  end
 elseif isempty(fall) fall=rise;
 end
end
envelope 		= ones(round(sampfreq.*dur),1);				% envelope
ramp_on	 		= 1:round(sampfreq./(1000./rise));			% rise ramp
envelope(ramp_on)	= (1000./rise).*ramp_on./sampfreq; 			% rise
ramp_off		= 1:round(sampfreq./(1000./fall));			% fall ramp
envelope(round(sampfreq.*dur)-ramp_off+1) = (1000./fall).*ramp_off./sampfreq;	% fall
envelope 		= 0.95.*envelope;					% prevent clipping