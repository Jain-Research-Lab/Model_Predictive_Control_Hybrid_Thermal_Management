% Function/script description and use
% This class initializes all parameters for an MPC of the TMS Testbed
% Author(s): Demetrius Gulewicz (dgulewic@purdue.edu)
%            
% Created: 8/03/23
% Last Modified: 09/10/24
%
% Version: MATLAB R2023b
% Dependencies: varModel.m
%
%% NMPC for Hybrid TMS Class
classdef varController < handle
    %% NMPC for Hybrid TMS Properties
    properties
    % MPC INDEXES
        Npx;   % Number of future states to compute

        nx;    % number of states for 1 step in time horizon
        nu;    % number of inputs for 1 step in time horizon
        ny;    % number of outputs for 1 step in time horizon
        nd;    % number of disturbances for 1 step in time horizon

        Nx;    % number of states for all steps in time horizon
        Nu;    % number of inputs for all steps in time horizon
        Ny;    % number of outputs for all steps in time horizon

    % BOUNDS
        u_ub;           % maximum allowed total and individual flow rate
        u_lb;           % minimum allowed total and individual flow rate

        du_max;           % absoute value of max change in control action

        Tcp_ub;     % CP upper bound temp
        Tcp_lb;     % CP lower bound temp

        lb;  % lower bound on all variables
        ub;  % upper bound on all variables
        A;   % A matrix for inequality constraints
        b;   % b matrix for inequality constraints
    
    % OBJECTIVE FUNCTION WEIGHTS
        Ru;
        Rdu;  % penalties on the control inputs such that R is positive definite
        Qcp; 

        Ru_m;    % penalties on the control inputs such that R is positive definite
        Rdu_m;   % these are for move suppression of the control signals

        C;       % penalty of TES states

        epsilon; % small positive number for CP cost
        beta1;   % the single tunable parameter for CP cost
        alpha;   % low cost portion of CP cost
        beta;

    % GRADIENTS
        dydx;
        pJpu_zero; %Initialization for all gradients
        RdJ_du_m;
        accumulation_matrix;
        accumulation_vector;

    % INITIAL CONDITIONS
        u0; % Initial control actions
        U0; % Vector of initial control actions
    end

    %% NMPC for Hybrid TMS Methods
    methods
        %% Initialize NMPC Parameters
        function [varNMPC, vNMPC] = varController(varTMS)
            varNMPC = define_time_horizon(varNMPC,varTMS);
            varNMPC = define_bounds(varNMPC);
            varNMPC = define_J_matrices(varNMPC);
            varNMPC = define_dJ_matrices(varNMPC,varTMS);
            varNMPC = compute_IC_BC(varNMPC);
            vNMPC = compute_NMPC_struct(varNMPC,varTMS);
        end

        %% Set MPC Horizon
        function varNMPC = define_time_horizon(varNMPC,varTMS)
            % MPC INDEXES
            varNMPC.Npx = 25; % Number of future states to compute
            varNMPC.nu = 1 + varTMS.nmp;   % number of control actions
            varNMPC.nx = varTMS.nv + varTMS.nTMS; % number of states
            varNMPC.ny = 2 + varTMS.nm; % number of outputs
            varNMPC.nd = 3;

            varNMPC.Nx = (varNMPC.Npx+1)*varNMPC.nx;	% total number of x variables
            varNMPC.Nu = (varNMPC.Npx)*varNMPC.nu;	    % total number of u variables
        end

        %% Set J Matrices
        function varNMPC = define_J_matrices(varNMPC)
        % OBJECTIVE FUNCTION WEIGHTS [scalar version]
            varNMPC.Ru = 0.5;    % penalties on the primary flow such that R is positive definite
            varNMPC.Rdu = 0.25;  % these are for move suppression of the control signals 

        % CONTROL ACTION COST [matrix version]
            temp = ones(1,varNMPC.nu);
            varNMPC.Ru_m = temp;
            
            for i = 1:varNMPC.Npx-1
                varNMPC.Ru_m = blkdiag(varNMPC.Ru_m,temp);
            end

        % MOVE BLOCKING COST [matrix version]
            varNMPC.Rdu_m = zeros(varNMPC.Nu - varNMPC.nu,varNMPC.Nu);
            varNMPC.Rdu_m(1:varNMPC.Nu+1-varNMPC.nu:end-varNMPC.Nu) = 1;
            varNMPC.Rdu_m(1+varNMPC.nu*(varNMPC.Nu-varNMPC.nu):varNMPC.Nu+1-varNMPC.nu:end) = -1;
       
        % STATE COST [scalar version]
            varNMPC.C = 0.0000025;

        % CP Cost Function Designer
            varNMPC.epsilon = 0.3;
            varNMPC.beta1 = 1;

            varNMPC = compute_CP_cost(varNMPC);
        end

        %% Set dJ Matrices
        function varNMPC = define_dJ_matrices(varNMPC,varTMS)
        % INITIALIZATION
            varNMPC.pJpu_zero = zeros(1,varNMPC.Npx*varNMPC.nu); %Initialization for gradients
            varNMPC.accumulation_matrix = zeros(varTMS.ns,varNMPC.nu*varNMPC.Npx);
            varNMPC.accumulation_vector = zeros(varNMPC.nu*varNMPC.Npx,1);

        % Gradient of Move Blocking [matrix version]
            varNMPC.RdJ_du_m = zeros(varNMPC.Nu);
            varNMPC.RdJ_du_m(1:varNMPC.Nu+1:end) = 1;
            varNMPC.RdJ_du_m(varNMPC.nu+1:varNMPC.Nu+1:end-varNMPC.Nu) = -1;
            varNMPC.RdJ_du_m(1+varNMPC.nu*varNMPC.Nu:varNMPC.Nu+1:end) = -1;
            varNMPC.RdJ_du_m(varNMPC.nu+1+varNMPC.nu*varNMPC.Nu:varNMPC.Nu+1:end-varNMPC.nu*varNMPC.Nu) = 2;
        end

        %% Set MPC Boundaries
        function varNMPC = define_bounds(varNMPC)
        % MPC BOUNDS [vector version]
            varNMPC.u_lb = [0.001 0.001];
            varNMPC.u_ub = 0.1.*ones(1,varNMPC.nu);   % maximum allow total flow rate

            varNMPC.du_max = 0.02.*ones(varNMPC.nu,1);        % absoute value of max change in control action  

            varNMPC.Tcp_ub = 45; % CP upper bound temperature
            varNMPC.Tcp_lb = 0;  % CP lower bound temperature

        % BOUNDS [matrix version]
            ulbmat = repmat(varNMPC.u_lb,1,varNMPC.Npx);
            uubmat = repmat(varNMPC.u_ub,1,varNMPC.Npx);

            varNMPC.lb = ulbmat;
            varNMPC.ub = uubmat;

        % CONSTRAINTS [matrix version]
            % constraints that u1 + u2 <= uub and |du| < b
            max_u_A = kron(eye(varNMPC.Npx),ones(1,varNMPC.nu));
            max_du_A = -1*diag(ones(varNMPC.nu*varNMPC.Npx-varNMPC.nu,1),-varNMPC.nu)+eye(varNMPC.nu*varNMPC.Npx);
            varNMPC.A = [max_u_A; max_du_A; -max_du_A];

            max_u_b = varNMPC.u_ub(1)*ones(varNMPC.Npx,1);
            max_du_b = kron(ones(varNMPC.Npx,1),varNMPC.du_max);
            min_du_b = kron(ones(varNMPC.Npx,1),varNMPC.du_max);
            varNMPC.b = [max_u_b; max_du_b; min_du_b];
        end

        %% Calculate IC & BC
        function varNMPC = compute_IC_BC(varNMPC)                    
        % INITIAL CONDITIONS [matrix version]
            varNMPC.U0 = repmat(varNMPC.u_lb',varNMPC.Npx,1);
        end

        %% Define NMPC Struct of Essential Values
        function vNMPC = compute_NMPC_struct(varNMPC,varTMS)
            % NMPC Discretization
            vNMPC.Npx = varNMPC.Npx;
            vNMPC.nu = varNMPC.nu; % number of inputs
            vNMPC.ny = varNMPC.ny; % number of outputs
            vNMPC.ns = varTMS.ns;  % number of states
            vNMPC.nx = varTMS.nx;  % number of horizontal CV per module

            % Weights
            vNMPC.Ru_m = varNMPC.Ru_m;
            vNMPC.Rdu_m = varNMPC.Rdu_m;
            vNMPC.RdJ_du_m = varNMPC.RdJ_du_m;
            vNMPC.Ru = varNMPC.Ru;
            vNMPC.Rdu = varNMPC.Rdu;
            vNMPC.C = varNMPC.C;
            vNMPC.alpha = varNMPC.alpha;
            vNMPC.beta = varNMPC.beta;
            vNMPC.epsilon = varNMPC.epsilon;

            % Linear Constraints
            vNMPC.A = varNMPC.A;
            vNMPC.b = varNMPC.b;

            % Bounds
            vNMPC.lb = varNMPC.lb;
            vNMPC.ub = varNMPC.ub;
            vNMPC.Tcp_ub = varNMPC.Tcp_ub;

            % Initialization
            vNMPC.accumulation_matrix = varNMPC.accumulation_matrix;
            vNMPC.accumulation_vector = varNMPC.accumulation_vector;
            vNMPC.pJpu_zero = varNMPC.pJpu_zero;
        end

        %% Compute CP Cost Function Parameters
        function varNMPC = compute_CP_cost(varNMPC)
            x = sym("x",[1 1],"real");
            beta_s = sym("beta", [3 1],"real");
            alpha_s = sym("alpha",[2 1],"real");
            
            f1 = (alpha_s(1) / (varNMPC.Tcp_ub - x)) + alpha_s(2);
            f2 =  beta_s(1)*x^2 + beta_s(2)*x + beta_s(3);
             
            df1 = diff(f1,x);
            df2 = diff(f2,x);
            
            ddf1 = diff(df1,x);
            ddf2 = diff(df2,x);
            
            eqn1 = subs(f1,x,varNMPC.Tcp_lb) == 0;
            eqn2 = subs(f1,x,varNMPC.Tcp_ub-varNMPC.epsilon) == subs(f2,x,varNMPC.Tcp_ub-varNMPC.epsilon);
            eqn3 = subs(df1,x,varNMPC.Tcp_ub-varNMPC.epsilon) == subs(df2,x,varNMPC.Tcp_ub-varNMPC.epsilon);
            eqn4 = subs(ddf1,x,varNMPC.Tcp_ub-varNMPC.epsilon) == subs(ddf2,x,varNMPC.Tcp_ub-varNMPC.epsilon);
            eqn5 = beta_s(1) == varNMPC.beta1;
            
            sol = solve([eqn1 eqn2 eqn3 eqn4 eqn5]);
            sol = double([sol.alpha1 sol.alpha2 sol.beta1 sol.beta2 sol.beta3]);
            
            varNMPC.alpha = sol(1:2);
            varNMPC.beta = sol(3:5);
        end
    end
end