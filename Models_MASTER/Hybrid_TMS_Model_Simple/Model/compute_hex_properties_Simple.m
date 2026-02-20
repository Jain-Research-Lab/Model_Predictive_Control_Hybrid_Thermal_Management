%% Function Description
% This function approximates the melt fraction as a sigmoid function. From
% this, the thermal conductivity of hexadecane can be computed by the rule
% of mixture (a common method used in materials science, esepcially for
% material properties). The effective specific heat is by computed via a bell-shaped
% curve so that the function is continuous everywhere. The phase change is
% modeled as a massive jump in the specific heat for a narrow temperature
% range. More details may be found in the paper published by JRL named:
% Numerical Validation of Effective Specific Heat Functions for Simulating
% Melting Dynamics in Latent Heat Thermal Energy Storage Modules
% 
% Parameters :  T - temperature vector (K)
%               vTMS - struct of all required Hybrid TMS Variables
% 
% Return     :  k_hex - thermal conductivity of all hexadecane nodes
%               cp_hex - specific heat of all hexadecane nodes

%% General Function Information
% Original Author(s): Darin Lin
%                     Henry Lewis
%                     Brendan Gillis
%                     Michael Shanks (shanks5@purdue.edu)
%
% Revision Author(s): Demetrius Gulewicz (dgulewic@purdue.edu)
%
% Created: Fall 2021
% Last Modified: 01/10/25
%
% Version: MATLAB R2023a
% Dependencies: varModel

%% Definitions
% mf     - melt fraction of hexadecane, 0 = solid, 1 = liquid

%% Technical Function Information
% T: The temperature are ordered as follows:
% Temperature left to right, bottom to top;
% Left: water inlet side of TES Module
% Right: water outlet side of TES Module
% Bottom: the edges closest to the water in the TES Modules
% Top: the edges furthest from the water in the TES Modules

function [k_hex,cp_hex,mf] = compute_hex_properties_Simple(T,vTMS)
%% Phase Change Function Parameters
alphaT = vTMS.alphaT;

%% Compute Exponent for Sigmoid Function
a = alphaT.*(T-vTMS.T_hex_melt_vec);

%% Melt fraction
mf = 1 ./ (1 + exp(-a));

%% Thermal Conductivity
k_hex = mf.*vTMS.k_hex_liquid_vec + (1-mf).*vTMS.k_hex_solid_vec;

%% Specific heat
cp_hex = vTMS.cp_hex_solid_vec + ((vTMS.cp_hex_liquid_vec-vTMS.cp_hex_solid_vec).*mf) + (alphaT*vTMS.e_hex_latent_vec) ./ (2 + exp(-a) + exp(a));
        
end