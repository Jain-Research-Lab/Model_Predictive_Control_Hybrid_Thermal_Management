%% Function Description
% This is a discretization function that directly solves for x(t0+dt) given
% states, control actions, and disturbances at t=t0.
% 
% Input      :  x - current states
%               u - current control actions
%               d - current disturbances
%               vTMS - struct of all required Hybrid TMS Variables
% 
% Return     :  x - states after dt interval

%% General Function Information
% Original Author(s):  Darin Lin
%                      Henry Lewis
%                      Austin Nash
%                      Michael Shanks (shanks5@purdue.edu)
%
% Revision Author(s):  Demetrius Gulewicz (dgulewic@purdue.edu)
%
% Created: Summer 2021
% Revised: Summer 2023
%
% Version: MATLAB R2022b
% Dependencies: compute_hex_properties
%               compute_weight_vector
%               varModel

function [xn, Sx, Su] = Hybrid_TMS_Model_ODE(t,x,u,d,vTMS,opts)
%% get next state
[~,xN] = ode23tb(@Hybrid_TMS_Model_fun,t,x,opts,u,d,vTMS);
xn = xN(end,:)';

%% Get approximate forward sensitivities
[~,Sx,Su] = Hybrid_TMS_Model_EXPM(x,u,d,vTMS,vTMS.E);

%% ODE function handle
    function dx = Hybrid_TMS_Model_fun(t,x,u,d,vTMS)
    %% State Space Matrix
    [Mi, A, d] = Hybrid_TMS_Model_SS(x,u,d,vTMS);
    
    %% Compute State Derivatives
    dx = Mi(1:end-1).*(A*x+d);
    
    end
end