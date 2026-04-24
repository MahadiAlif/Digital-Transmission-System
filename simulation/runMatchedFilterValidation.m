function validation = runMatchedFilterValidation(cfg, pulses)
names = fieldnames(pulses);
validation = struct();

for p = 1:numel(names)
    pulseName = names{p};
    txPulse = pulses.(pulseName);
    rxPulse = fliplr(txPulse);

    fig = figure('Name', ['Matched filter BER - ' pulseName], 'Color', 'w');
    hold on; grid on;

    for m = 1:numel(cfg.Mlist)
        M = cfg.Mlist(m);
        simBer = zeros(size(cfg.EbN0dB));
        simSer = zeros(size(cfg.EbN0dB));

        for k = 1:numel(cfg.EbN0dB)
            out = simulatePamAwgn(M, cfg.numBitsValidation, cfg.EbN0dB(k), ...
                cfg.SpS, txPulse, rxPulse);
            simBer(k) = out.ber;
            simSer(k) = out.ser;
        end

        theoryBer = theoreticalPamBer(M, cfg.EbN0dB);
        validation.(pulseName).M(m).order = M;
        validation.(pulseName).M(m).EbN0dB = cfg.EbN0dB;
        validation.(pulseName).M(m).ber = simBer;
        validation.(pulseName).M(m).ser = simSer;
        validation.(pulseName).M(m).theoryBer = theoryBer;

        figure(fig);
        semilogy(cfg.EbN0dB, simBer, 'o-', 'LineWidth', 1.2, ...
            'DisplayName', sprintf('M=%d sim', M));
        semilogy(cfg.EbN0dB, theoryBer, '--', 'LineWidth', 1.0, ...
            'DisplayName', sprintf('M=%d theory', M));

        if M == 4
            eyeEbN0 = interpEbN0AtBer(cfg.EbN0dB, theoryBer, cfg.berTarget);
            plotEyeExamples(cfg, txPulse, rxPulse, M, eyeEbN0, ...
                ['matched_' pulseName '_M4']);
        end
    end

    xlabel('E_b/N_0 [dB]');
    ylabel('BER');
    title(['Matched filter validation - ' pulseName]);
    ylim([1e-5 1]);
    legend('Location', 'southwest');
    saveas(fig, fullfile(cfg.resultsDir, ['ber_matched_' pulseName '.png']));
end
end
