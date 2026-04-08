function pulses = buildTxPulses(cfg)
pulses = struct();
pulses.NRZ = ones(1, cfg.SpS);
pulses.NRZ = pulses.NRZ / sqrt(sum(pulses.NRZ.^2));
pulses.SRRC = srrcFrequencySampling(cfg.srrcBeta, cfg.srrcSpan, cfg.SpS);
end
