%% Function Description
% This is a discretization function that directly solves for x(t0+dt) given
% states, control actions, and disturbances at t=t0.
% 
% Input      :  x - current states
%               u - current control actions
%               d - current disturbances
%               vTMS - struct of all required Hybrid TMS Variables
% 
% Return     :  Mi - Inverse of mass matrix
%               A - State matrix
%               d - disturbance vector

%% References
% This system takes the form of x_dot(t) = Ax(t)+B, where:
% x_dot: state derivatives n by 1
% x    : all the states, n by 1
% A    : State matrix, n by n
% B    : constant disturbance matrix n by 1
%
% Note: n is by definition the number of states
%
% This function makes use of graph theory to compute the state
% matrix. Matlab has some good documentation of how graph theory works. Some
% details can be found at the following links:
% https://www.mathworks.com/help/matlab/math/directed-and-undirected-graphs.html
% https://www.mathworks.com/help/matlab/ref/digraph.html
% https://www.mathworks.com/help/matlab/ref/graph.html
%
% The formulation used here to compute A, -I*(K.*It) is basically the
% weighted laplacian of the Hybrid TMS. The weighted Laplacian is nothing
% but the state matrix, if one is careful to define I and It properly.
%
% A  - State matrix, as conventionally defined [W/K]
% I  - System Directed Incidense Matrix [unitless]
% It - Transpose of System Undirected Incidense Matrix [unitless]
% K  - Weight Vector, weights of all graph edges [W/K]
% M  - Mass (capacitance) vector [J/K]
%
% For more information on the Laplacian, see this answer:
% https://www.quora.com/Whats-the-intuition-behind-a-Laplacian-matrix-Im-not-so-much-interested-in-mathematical-details-or-technical-applications-Im-trying-to-grasp-what-a-laplacian-matrix-actually-represents-and-what-aspects-of-a-graph-it-makes-accessible/answer/Muni-Sreenivas-Pydi

%% General Function Information
% Original Author(s):  Darin Lin
%                      Henry Lewis
%                      Austin Nash
%                      Michael Shanks (shanks5@purdue.edu)
%
% Revision Author(s):  Demetrius Gulewicz (dgulewic@purdue.edu)
%
% Created: Summer 2021
% Last Modified: 09/10/24
%
% Version: MATLAB R2023a
% Dependencies: compute_hex_properties.m
%               compute_weight_vector.m
%               varModel.m

%% Definitions
% HFH: High Frequency Heater, device that creates lots of heat very quickly
% HX : Heat Exchanger, device using forced water convection to transfer heat
% TES: Thermal energy storage, device filled with PCM to store lots of energy
% PCM: Phase change material, material that has a large latent heat
% Chiller: air-water VCC that continuosly keeps water at a set temperature
% Hybrid TMS: The overall system that is modeled in this function

%% Technical Function Information
% States:
% Ttf          = x(1);            % Tank temperature [K]
% Tcpw         = x(2);            % Cold plate wall temperature [K]
% Tcpf         = x(3);            % Cold plate fluid temperature [K]
% Thxw         = x(4);            % Heat exchanger wall temperature [K]
% Thxf         = x(5);            % Heat exchanger fluid temperature [K]
% Tmf          = x(5+varTMS.nx);  % Module fluid exit temperature [K]
%
% Controls Actions:
% mTES         = u(2:end)         % TES Module mass flow rate [kg/s]
% mp           = u(1) + u(2:end)  % Mass flow rate through HX, Pump, Tank [kg/s]
% mBYP         = u(1)             % Bypass mass flow rate (kg/s)
%
% Disturbances
% Qcp          = d(1);            % Heat Input from HFH [W]
% Tcf          = d(2);            % Chiller Water Temperature [K]
% inv_r_HX                        % HX inverse of thermal resistance [W/K]

function [Mi, A, d] = Hybrid_TMS_Model_SS(x,u,d,vTMS)
%% Compute Material Properties
[k_hex,cp_hex] = compute_hex_properties(x(vTMS.n_hex_start:end), vTMS);

%% Compute Mass Matrix [J/K]
Mi = [vTMS.Minv(1:vTMS.n_hex_start-1); 1./(vTMS.mcp_al_composite + (vTMS.m_hex_composite_vec.*cp_hex)); 0];

%% Compute Weight Vector [W/K]
K = compute_weight_vector(u,k_hex,vTMS);

%% Compute State Matrix [W/K]
A = -vTMS.I*(K.*vTMS.It);
A(4,4) = A(4,4) - vTMS.inv_r_HX;

%% Set Heat Rate Disturbances [W]
d = [0; d(1); 0; vTMS.inv_r_HX*d(2); vTMS.d(5:end)];

end