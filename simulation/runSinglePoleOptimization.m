function optimization = runSinglePoleOptimization(cfg, pulses)
names = fieldnames(pulses);
optimization = struct();

for p = 1:numel(names)
    pulseName = names{p};
    txPulse = pulses.(pulseName);

    for m = 1:numel(cfg.Mlist)
        M = cfg.Mlist(m);
        ebAtTarget = nan(size(cfg.singlePoleBw));

        for b = 1:numel(cfg.singlePoleBw)
            [B, A] = singlePoleImpulseInvariance(cfg.singlePoleBw(b), cfg.SpS);
            berCurve = zeros(size(cfg.EbN0dB));

            for k = 1:numel(cfg.EbN0dB)
                out = simulatePamAwgn(M, cfg.numBitsOptimization, cfg.EbN0dB(k), ...
                    cfg.SpS, txPulse, B, A);
                berCurve(k) = out.ber;
            end

            ebAtTarget(b) = interpEbN0AtBer(cfg.EbN0dB, berCurve, cfg.berTarget);
            optimization.(pulseName).M(m).ber(b, :) = berCurve;
        end

        matchedTheory = theoreticalPamBer(M, cfg.EbN0dB);
        matchedEb = interpEbN0AtBer(cfg.EbN0dB, matchedTheory, cfg.berTarget);
        [bestEb, bestIdx] = min(ebAtTarget);
        bestBw = cfg.singlePoleBw(bestIdx);

        optimization.(pulseName).M(m).order = M;
        optimization.(pulseName).M(m).bandwidth = cfg.singlePoleBw;
        optimization.(pulseName).M(m).EbN0AtTarget = ebAtTarget;
        optimization.(pulseName).M(m).bestBandwidth = bestBw;
        optimization.(pulseName).M(m).bestEbN0 = bestEb;
        optimization.(pulseName).M(m).matchedEbN0 = matchedEb;
        optimization.(pulseName).M(m).penaltydB = bestEb - matchedEb;

        fig = figure('Name', sprintf('Single-pole BW - %s M%d', pulseName, M), ...
            'Color', 'w');
        plot(cfg.singlePoleBw, ebAtTarget, 'o-', 'LineWidth', 1.3);
        hold on; grid on;
        yline(matchedEb, '--', 'Matched filter theory');
        xline(bestBw, ':', sprintf('opt %.3g R_s', bestBw));
        xlabel('Single-pole -3 dB bandwidth / R_s');
        ylabel(sprintf('E_b/N_0 at BER = %.0e [dB]', cfg.berTarget));
        title(sprintf('%s, PAM-%d: single-pole bandwidth optimization', pulseName, M));
        saveas(fig, fullfile(cfg.resultsDir, ...
            sprintf('single_pole_bw_%s_M%d.png', pulseName, M)));

        if M == 4
            [Bbest, Abest] = singlePoleImpulseInvariance(bestBw, cfg.SpS);
            plotEyeExamples(cfg, txPulse, Bbest, M, bestEb, ...
                sprintf('singlepole_%s_M%d_best', pulseName, M), Abest);
        end
    end
end
end
