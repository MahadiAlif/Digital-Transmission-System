function drawEye(y, SpS, centerSample, plotTitle)
span = 2 * SpS;
hold on; grid on;
first = centerSample - SpS;
lastStart = numel(y) - span;
starts = first:SpS:lastStart;
starts = starts(starts > 0);
starts = starts(1:min(numel(starts), 250));
t = (-SpS:SpS - 1) / SpS;
for k = 1:numel(starts)
    segment = y(starts(k):starts(k) + span - 1);
    plot(t, segment, 'Color', [0 0.25 0.75 0.12], 'HandleVisibility', 'off');
end
xline(0, ':k');
xlabel('Time / T_s');
ylabel('Amplitude');
title(plotTitle);
end
