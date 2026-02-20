%% Function Description
% This function compute the weights of all edges in the Hybrid TMS graph.
%
% Input      :  u - current control actions
%               k_hex - thermal conductivity of all hexadecane nodes
%               vTMS - struct of all required Hybrid TMS Variables
% 
% Return     :  K - Weight Vector, weights of all graph edges

%% References
% The weights of the Hybrid TMS graph is nothing but the inverse of the
% thermal resistance between all connected nodes of the graph. Recall that
% thermal resistance is defined as qR = T, whereas the typical formulation
% for the system equations is M*dT/dt = Ax (assuming no disurbances). In
% this case, q = M*dT/dt, T = x. Therefore, A is the inverse of R. The weight
% vector K is a column vector composed of the fundamental numbers used to
% compute A, and are the same units are A. Therefore, the K vector is
% nothing but the inverse of the thermal resistance between connected nodes.
 
%% Definitions
% HFH: High Frequency Heater, device that creates lots of heat very quickly
% HX : Heat Exchanger, device using forced water convection to transfer heat
% TES: Thermal energy storage, device filled with PCM to store lots of energy
% PCM: Phase change material, material that has a large latent heat
% Chiller: device that continuosly keeps fluid at a set temperature
% Hybrid TMS: The overall system that is modeled in this function

%% Technical Function Information
% The weight vector is ordered in a particular way. If you look at the code
% below, there are 13 weight categories, and the weight vector must conform
% to this order. For the categories describing the TES Module control
% volumes, these are vectors. For the categories describing non-hybrid TMS
% weights, these are scalars.

%% General Function Information
% Original Author(s): Demetrius Gulewicz (dgulewic@purdue.edu)
%
% Created: Fall 2023
% Last Modified: 09/10/24
%
% Version: MATLAB R2023b
% Dependencies: varModel
%
% notes:
%
function K = compute_weight_vector(u,k_hex,vTMS)
    k_hex = reshape(k_hex,[vTMS.nx,vTMS.nh]);

    % horizontal conduction resistance of hexadecane for every control volume containing hexadecane [W/K]
    r_hex_composite_h = (vTMS.dx_h)./(2*k_hex*vTMS.dh_h*vTMS.b);

    % inverse of vertical conduction resistance of hexadecane for every control volume containing hexadecane [W/K]
    inv_r_hex_composite_v = (2*k_hex*vTMS.dx_h*vTMS.b)./(vTMS.dh_h);

    % inverse of vertical convection resistance of every water control volume interface [W/K]
    inv_r_water_v = vTMS.alpha_TES*vTMS.dx*vTMS.b;

    % mass flow rate through Tank, HX, HFH
    mp = sum(u);

    % inverse of thermal resistance between HFH solid and fluid [W/K]
    r1 = vTMS.hA_cp;

    % inverse of thermal resistance between HX solid and fluid [W/K]
    r2 = vTMS.hA_hx;

    % nominal inverse of horizontal thermal resistance of aluminum node to aluminum node [W/K]
    r3 = vTMS.inv_r_al_al_h;

    % inverse of horizontal conduction resistance from composite node to composite node [W/K]
    r4 = vTMS.W*((vTMS.r_al_composite_h + r_hex_composite_h(1:end-1,:) + r_hex_composite_h(2:end,:)).^(-1));

    % inverse of vertical thermal resistance from water node to aluminum node [W/K]
    r5 = ((1/(2*vTMS.inv_r_al_al_v2)) + (1./inv_r_water_v)).^(-1);

    % inverse of vertical thermal resistance from aluminum node to composite node [W/K]
    r6 = ((1/(2*vTMS.inv_r_al_al_v2)) + ((inv_r_hex_composite_v(:,1) + vTMS.inv_r_al_composite_v).^(-1))).^(-1);

    % inverse of vertical thermal resistance from composite node to composite node [W/K]
    r7 = ((vTMS.inv_r_al_composite_v + inv_r_hex_composite_v(:,1:end-1)).^(-1) + (vTMS.inv_r_al_composite_v + inv_r_hex_composite_v(:,2:end)).^(-1)).^(-1);

    % inverse of mass transfer resistance between tank and HFH [W/K]
    r8 = mp*vTMS.cp_water;

    % inverse of mass transfer resistance between HFH and HX [W/K]
    r9 = mp*vTMS.cp_water;

    % inverse of mass transfer resistance between HX and Tank [W/K]
    r10 = u(1)*vTMS.cp_water;

    % inverse of mass transfer resistance between HX and TES [W/K]
    r11 = u(2:end)*vTMS.cp_water;

    % inverse of mass transfer resistance between TES and Tank [W/K]
    r12 = u(2:end)*vTMS.cp_water;

    % inverse of mass transfer resistance between TES and TES [W/K]
    r13 = (u(2:end).*vTMS.cp_water.*vTMS.rTES_water_vector)';

    % Build Weight Matrix
    K = [r1; r2; r3; r4(:); r5; r6(:); r7(:); r8; r9; r10; r11; r12; r13(:)];
end