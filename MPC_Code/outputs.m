function y = outputs(x, u, vTMS)
    % get composite PCM temperatures
    T = x(vTMS.n_hex_start:end);

    % Compute Specific Enthalpy [J/m^3]
    q1 = vTMS.cp_hex_solid_vec.*(T-vTMS.T_hex_melt_vec);
    q2 = ((vTMS.cp_hex_liquid_vec - vTMS.cp_hex_solid_vec)./vTMS.alphaT).*log((1 + exp(vTMS.alphaT.*(T-vTMS.T_hex_melt_vec)))/2);
    q3 = (vTMS.e_hex_latent_vec./2).*tanh((vTMS.alphaT./2).*(T-vTMS.T_hex_melt_vec));
    q = (q1 + q2 + q3) .* vTMS.f .* vTMS.rho_hex_vec + vTMS.cp_al.*(T-vTMS.T_hex_melt_vec) .* (1 - vTMS.f) .* vTMS.rho_al;
    
    % Compute per-CV SOC
    SOC = ((q - vTMS.qmax) ./ (vTMS.qmin - vTMS.qmax));

    % Compute per-Module SOC
    SOC_reshape = (reshape(SOC,[numel(SOC)./vTMS.nm,vTMS.nm]))';
    SOC_reshape_2 = SOC_reshape(:);
    SOC_reshape_3 = reshape(SOC_reshape_2,[vTMS.nh*vTMS.dnx,vTMS.nm]);
    SOC_perM = mean(SOC_reshape_3); % SOC per module

    % TES and HX heat transfer
    PTES = 0;
    for i = 1:(length(u)-1)
        PTES = PTES + u(i+1)*vTMS.cp_water*(x(vTMS.nTMS)-x(vTMS.nTMS+(vTMS.dnx*vTMS.nms*i)));
    end
    PHX = sum(u)*vTMS.cp_water*(x(3)-x(vTMS.nTMS));

    % collect outputs
    y = [SOC_perM'; PTES; PHX];
end