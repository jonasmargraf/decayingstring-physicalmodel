%% Physical model of a decaying guitar string.

% Lucas Weidinger
% Christoph Karnop
% Jonas Margraf

% Contact: jonasjmargraf@gmail.com

% /////////////////////////////////////////////////////////////////////////

clc
clearvars
close all

% Initialize variables:

% string length
L = 1.2;
% sampling frequency
fs = 44100;
% time sampling interval
T = 1 / 44100;
% propagation velocity
c = 255;
% spatial sampling interval
X = c * T;
% length of delay line
m = round(L / X);
% gain scaling factor applied
g = 0.98;
% output signal length in seconds
outputLength = 4;

% Now we generate our excitation signal:

% excitation point
p = round(0.6 * m);
% excitation amplitude
a = 0.2;
% index vector
x = linspace(1,m,m);
% initialize excitation vector
e = zeros(1,m);
% calculate excitation signal according to equation 7 on the PDF
e(1:p) = (a/p) .* x(1:p);
e(p+1:end) = (a / (L-p)) .* x(p+1:end) - p + a;

% Initialize delay lines and set excitation signal as initial state
delayLine1 = e;
delayLine2 = e;

% Initialize output vector
output = zeros(fs*outputLength, 1);

% /////////////////////////////////////////////////////////////////////////

% a) Generate 24th order FIR lowpass filter with cutoff frequency at 5000 Hz

filterOrder = 24;
% fir1() expects cutoff frequency between 0-1, where 1 is Nyquist frequency
cutoffFrequency = 5000 / (fs/2);
filt = fir1(filterOrder, cutoffFrequency);

% initialize a filter buffer that stores the last N = filterOrder+1 samples
filterBuffer = zeros(1, length(filt));
filterOutput = 0;
gainOutput = 0;

figure, hold off

for i = 1:fs*outputLength
    
    % animated plotting of delay lines
    if mod(i, 147) == 1
        animatedPlot1 = plot(delayLine1);
        hold on
        animatedPlot2 = plot(delayLine2);
        hold off
        xlim([1 208]);
        ylim([-max(abs(e)) max(abs(e))]);
        pause(0.0167);
        delete(animatedPlot1);
        delete(animatedPlot2);
    end
    
    % multiply samples in filter buffer with FIR coefficients,
    % then sum them and pass sum result to filter output
    filterOutput = sum(filterBuffer .* filt);
    % shift filter buffer
    filterBuffer = circshift(filterBuffer, [0, 1]);
    
    % pass filter output to system output at current sample position
    output(i) = filterOutput;

    % pass last sample of delay line 1 into filter buffer
    filterBuffer(1) = delayLine1(end);
    
    % pass first sample of delay line 2 into gain stage and scale with g
    gainOutput = delayLine2(1) * g;
    
    % shift delay line 1 by +1
    delayLine1 = circshift(delayLine1, [0, 1]);
    
    % shift delay line 2 by -1
    delayLine2 = circshift(delayLine2, [0, -1]);
    
    % invert filter output, pass into last sample of delay line 2
    delayLine2(end) = -filterOutput;
        
    % invert gain stage, pass into first sample of delay line 1
    delayLine1(1) = -gainOutput;
    
end

% normalize output
output = output ./ max(abs(output));
% play output
soundsc(output, 44100);
% write output to wav file
% audiowrite('lossy.wav', output, fs);

% plot amplitude spectrum
figure;
semilogx(   linspace(0, fs/2, length(output)), ...
            20*log10(abs(fft(output) / max(abs(fft(output))))));
grid on;
Ticks = [20 30 40 80 100 200 400 600 1000 2000 5000 10000 20000];
set(gca, 'XTickMode', 'manual', 'XTick', Ticks, 'xlim', [20,5000], 'ylim', [-80,0]); 
xlabel('Frequency [Hz]')
ylabel('dBfs')
title('Magnitude Spectrum')