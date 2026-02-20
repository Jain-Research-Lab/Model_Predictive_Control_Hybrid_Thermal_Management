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

function x0_MPC = Hybrid_TMS_Lumped_Inverse_SE_Simple(x0_SIM, y0_SIM, vTMS_SIM, vTMS_MPC)
    % initialize MPC state vector
    x0_MPC = zeros(vTMS_MPC.ns,1);

    % transport states that are the same
    x0_MPC(1:vTMS_SIM.nTMS) = x0_SIM(1:vTMS_SIM.nTMS);

    % estimate fluid temperature
    idx_w_end = round((vTMS_SIM.n_hex_start - vTMS_SIM.nTMS - 1) / 2) + vTMS_SIM.nTMS;
    x0_MPC(vTMS_SIM.nTMS+1) = mean(x0_SIM(vTMS_SIM.nTMS+1:idx_w_end));

    % estimate metal temperature
    x0_MPC(vTMS_SIM.nTMS+2) = mean(x0_SIM(idx_w_end+1:vTMS_SIM.n_hex_start-1));

    % estimate SOC
    options = optimset('Display','on');
    y0_MPC = mean(y0_SIM(1:vTMS_SIM.nm));
    x0_TES = fzero(@compute_SOC_res,vTMS_SIM.T_hex_melt(1),options,x0_MPC,y0_MPC,vTMS_MPC);
    x0_MPC(end) = x0_TES;

    function res = compute_SOC_res(x, x0_MPC, SOC_ref, vTMS)
        x0_MPC(end) = x;
        y = outputs_Simple(x0_MPC, [0;0], vTMS);
        res = SOC_ref - y(1);
    end
end