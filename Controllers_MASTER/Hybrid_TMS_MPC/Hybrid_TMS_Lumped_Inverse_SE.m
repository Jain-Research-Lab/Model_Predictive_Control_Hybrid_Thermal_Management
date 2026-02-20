%% Function Description
% This function compute the states estimated for an MPC given ground truth
% measurements from a simulated model. This simulates an ideal estimator 
% with respect to SOC.
%
% Input      :  x0_SIM - current control actions
%               vTMS_SIM - thermal conductivity of all hexadecane nodes
%               vTMS_MPC - struct of all required Hybrid TMS Variables
% 
% Return     :  x0_MPC - Weight Vector, weights of all graph edges

%% General Function Information
% Original Author(s): Demetrius Gulewicz (dgulewic@purdue.edu)
%
% Created: Spring 2025
% Last Modified: 01/12/25
%
% Version: MATLAB R2023b

function x0_MPC = Hybrid_TMS_Lumped_Inverse_SE(x0_SIM, y0_SIM, vTMS_SIM, vTMS_MPC)
    % initialize MPC state vector
    x0_MPC = zeros(vTMS_MPC.ns,1);

    % transport states that are the same
    x0_MPC(1:vTMS_SIM.nTMS) = x0_SIM(1:vTMS_SIM.nTMS);

    % estimate fluid temperature
    idx_w_SIM = round((vTMS_SIM.n_hex_start - vTMS_SIM.nTMS - 1) / 2) + vTMS_SIM.nTMS;
    idx_w_MPC = round((vTMS_MPC.n_hex_start - vTMS_MPC.nTMS - 1) / 2) + vTMS_MPC.nTMS;
    x0_MPC(vTMS_SIM.nTMS+1:idx_w_MPC) = mean(reshape(x0_SIM(vTMS_SIM.nTMS+1:idx_w_SIM),[],2),2);

    % estimate metal temperature
    x0_MPC(idx_w_MPC+1:vTMS_MPC.n_hex_start-1) = mean(reshape(x0_SIM(idx_w_SIM+1:vTMS_SIM.n_hex_start-1),[],2),2);

    % estimate SOC
    SOC_SIM = compute_SOC(x0_SIM(vTMS_SIM.n_hex_start:end), vTMS_SIM);
    SOC_H_BAR = mean(reshape(SOC_SIM,2,[]),1);
    SOC_SQ = reshape(SOC_H_BAR,vTMS_MPC.dnx*vTMS_MPC.nm,[])';
    SOC_MPC = mean(reshape(SOC_SQ(:),2,[]),1)';
    n = length(SOC_MPC);

    options = optimset('Display','on');

    for i = 1:n
        y0_MPC = SOC_MPC(i);
        x0_TES = fzero(@compute_SOC_res,vTMS_SIM.T_hex_melt(1),options,y0_MPC,vTMS_MPC);
        x0_MPC(vTMS_MPC.n_hex_start+i-1) = x0_TES;
    end

    function res = compute_SOC_res(x, SOC_ref, vTMS)
        y = compute_SOC(x, vTMS);
        res = SOC_ref - y(1);
    end

    function SOC = compute_SOC(T, vTMS_SIM)
        q1 = vTMS_SIM.cp_hex_solid_vec.*(T-vTMS_SIM.T_hex_melt_vec);
        q2 = ((vTMS_SIM.cp_hex_liquid_vec - vTMS_SIM.cp_hex_solid_vec)./vTMS_SIM.alphaT).*log((1 + exp(vTMS_SIM.alphaT.*(T-vTMS_SIM.T_hex_melt_vec)))/2);
        q3 = (vTMS_SIM.e_hex_latent_vec./2).*tanh((vTMS_SIM.alphaT./2).*(T-vTMS_SIM.T_hex_melt_vec));
        q = (q1 + q2 + q3) .* vTMS_SIM.f .* vTMS_SIM.rho_hex_vec + vTMS_SIM.cp_al.*(T-vTMS_SIM.T_hex_melt_vec) .* (1 - vTMS_SIM.f) .* vTMS_SIM.rho_al;
        SOC = ((q - vTMS_SIM.qmax) ./ (vTMS_SIM.qmin - vTMS_SIM.qmax));
    end
end