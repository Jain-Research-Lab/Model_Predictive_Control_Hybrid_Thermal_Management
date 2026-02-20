% Function/script description and use
% This class initializes all parameters in the variable class varModel
% In addition, a struct of all required 
%
% Original Author(s): Michael Shanks (shanks5@purdue.edu)
%            
% Revision Author(s): Demetrius Gulewicz (dgulewic@purdue.edu)
%                     Pandu Dewanatha (pdewanat@purdue.edu)
%
% Created: 06/21/22
% Last Modified: 01/17/24
%
% Version: MATLAB R2023a
% Dependencies: None
%
% Example of Usage: [varTMS, vTMS]  = varModel;
%
% Notes: 
%
% Assumptions
% 1. water flowing through the plate completely surrounds the water fins
% 2. PCM height is equal to PCM fin height
% 3. Isotropic material properties

%% Hybrid TMS Class
classdef varModel < handle
    %% Hybrid TMS Properties
    properties
    % SIMULATION TIMING   
        % Overall Simulation Configuration [Fundamental]
        dt;        % sample time of system solver [s]
        tf;        % final timestep of simulation [s]
        nODE;      % number of time steps returned from ODE solver for each simulation time step [count]

        % Simulation & ODE Time Vectors [Derived]
        tSIM;      % all time steps [s]
        tODE;      % time steps stored for each iteration of ODE solver [s]

        % Execution Count [Derived]
        nSIM;      % number of times that controller & ODE Solver will be executed [count]

    % HYBRID TMS SYSTEM DISCRETIZATION  
        % Overall Hybrid TMS System Configuration [Fundamental]
        nTMS; % number of states in non-hybrid TMS Model
        nms;   % number of TES modules in series
        nmp;   % number of TES modules in parallel
        nm;   % total number of TES modules

        % Vertex Count for a Single TES Module [Fundamental]
        np;   % per module number of polycarb control volumes in y-direction
        nw;   % per module number of water control volumes in y-direction
        na;   % per module number of aluminum control volumes in y-direction
        nh;   % per module number of composite (hexadecane + aluminum) control volumes in y-direction
        dnx;  % per module number of control volumes in x-direction

        % Edge Count [Fundamental]
        ne_TMS; % number of edges in non-hybrid TMS system

        % Vertex and Edge Count for All TES Modules [Derived]
        ny;   % number of TES control volumes in y-direction
        nx;   % number of TES control volumes in x-direction
        ne;   % total number of edges in the Hybrid TMS System Graph
        ne_u; % total number of edges in the Undirected Hybrid TMS System Graph
        nv;   % total number of control volumes in TES Modules Model
        n_hex_start; % first index when composite CV starts

        % Overall System Vertex Count [Derived]
        ns;    % total number of states for Hybrid TMS System
        nu;    % total number of control actions
        n_out; % total number of outputs

    % INTEGRATOR ACCURACY PARAMETERS
        num_steps_IRK;  % number of steps in the time step
        num_stage_IRK;  % number of terms in each step

        s_EXPM;         % 2^s, the scaling factor for matrix exponential
        b_EXPM;         % Pade coefficients for matrix exponential

        contol; % fmincon constraint tolerance
        opttol; % fmincon optimality tolerance
        stetol; % fmincon step tolerance

    % INITIAL CONDITIONS  
        % Non-Hybrid TMS Initial Conditions [Fundamental]
        T0_Ttf;   % Initial temperature of tank outlet water [K]
        T0_Thxf;  % Initial temperature of shell tube outlet water [K]
        T0_Thxw;  % Initial temperature of shell tube wall [K]
        T0_Tcpf;  % Initial temperature of High frequnecy heater outlet water [K]
        T0_Tcpw;  % Initial temperature of High frequnecy heater wall [K]

        % TES Modules Initial Conditions [Fundamental]
        T0_p;     % polycarbonate initial temperature [K]
        T0_w;     % water initial temperature [K]
        T0_a;     % aluminum plate initial temperature [K]
        T0_h;     % composite initial temperature [K]

        % Initial Condition Vectors [Derived]
        T0_TMS;   % Initial conditions of Non-Hybrid TMS states [K]
        T0_TES;   % Initial temperature of all TES control volumes [K]
        T0_ALL;   % Initial Conditions for all states in hybrid system [K]

    % BOUNDARY CONDITIONS
        % BC for Overall Hybrid TMS System Simulation [Fundamental]
        T_CF_t;   % Time vector of chiller inlet water temperature [s]
        T_CF_T;   % Temperature vector of chiller inlet water temperature [K]
        
        Q_HF_t;   % Time vector of high frequency heater power input [s]
        Q_HF_Q;   % Power vector of high frequency heater power input [W]

        m_CF_t;   % Time vector of chiller water flow rate [s]
        m_CF_m;   % Mass flow rate vector of chiller water flow rate [kg/s]

        % Discretized BC for Overall Hybrid TMS System Simulation [Derived]
        T_CF;     % Chiller inlet time and temperature discretized to use simulation sample rate [s; K]
        Q_HF;     % High frequency heater time and temperature discretized to use simulation sample rate [s; W]
        m_CF;     % Chiller inlet time and mass flow rate discretized to use simulation sample rate [kg/s]

        % Discretized BC for TES Modules System Simulation [Derived]
        T_Thxf;   % water inlet temperature to TES Modules [K]
        m_TES;    % mass flow rate to TES Modules [kg/s]      

    % MATERIAL PROPERTIES
        % Copper [Fundamental]
        rho_cu;         % nominal density of copper  [kg/m^3]
        cp_cu;          % nominal specific heat of copper [J/(kg*K)]
        k_cu;           % nominal thermal conductivity of copper [W/(m*K)]

        % Polycarbonate [Fundamental]
        rho_pc;         % nominal density of polycarbonate [kg/m^3]
        cp_pc;          % nominal specific heat of polycarbonate [J/(kg*K)]
        k_pc;           % nominal thermal conductivity of polycarbonate [W/(m*K)]

        % Water [Fundamental]
        rho_water;  	% nominal density of water [kg/m^3]
        cp_water;       % nominal specific heat capacity of water [J/(kg*K)]
        k_water;        % nominal thermal conductivity of water [W/(m*K)]
        mu_water;       % nominal water dynamic viscosity as saturated vapor, Pa*s

        % Aluminum [Fundamental]
        rho_al;     	% nominal density of aluminum plate [kg/m^3]
        cp_al;    	    % nominal specific heat capacity of aluminum plate [J/(kg*K)]
        k_al;       	% nominal conductivity of aluminum plate [W/(m*K)]
        
        % Hexadecane [Fundamental]
        rho_hex;        % nominal density of hexadecane [kg/m^3]
        cp_hex_solid;   % nominal specific heat capacity of solid hexadecane [J/(kg*K)]
        cp_hex_liquid;  % nominal specific heat capacity of liquid hexadecane [J/(kg*K)]
        k_hex_solid;    % nominal thermal conductivity of solid hexadecane [W/(m*K)]
        k_hex_liquid;   % nominal thermal conductivity of liquid hexadecane [W/(m*K)]
        e_hex_latent; 	% specific latent heat of Hexadecane [J/kg]

        T_hex_melt;  	% nominal melting temperature of hexadecane [K]
        T_hex_solidus;  % Hexadecane solidus temperature [K]
        T_hex_liquidus; % Hexadecane liquidus temperature [K]

        % Hexadecane [Derived]
        rho_hex_vec        % nominal density of hexadecane [kg/m^3]
        cp_hex_solid_vec   % nominal specific heat capacity of solid hexadecane [J/(kg*K)]
        cp_hex_liquid_vec  % nominal specific heat capacity of liquid hexadecane [J/(kg*K)]
        k_hex_solid_vec    % nominal thermal conductivity of solid hexadecane [W/(m*K)]
        k_hex_liquid_vec   % nominal thermal conductivity of liquid hexadecane [W/(m*K)]
        e_hex_latent_vec   % specific latent heat of Hexadecane [J/kg]

        T_hex_melt_vec  	% nominal melting temperature of hexadecane [K]
        T_hex_liquidus_vec % Hexadecane liquidus temperature [K]
        T_hex_solidus_vec  % Hexadecane solidus temperature [K]
        dT_hex             % +/- temperature defining fully melted and fully frozen
        Tmin               % temperature at fully solid
        Tmax               % temperature at fully liquid

        qmin               % enthalpy at fully solid
        qmax               % enthalpy at fully liquid

        f                  % fraction of composite that is aluminum

    % CHILLER FLUID PARAMETERS
        rho_water_cf;   % density of water in chiller [kg/m^3]
        k_water_cf;     % thermal conductivity of water in chiller [W/(m*K)]
        mu_water_cf;    % viscocity of water in chiller [Pa*s]
        cp_water_cf;    % specific heat of water in chiller [J/(kg*K)]

    % HIGH FREQUENCY HEATER GEOMETRY
        % initial channel dimension values
        D_chan;           % diameter, m
        L_chan;           % length, m
        N_chan;           % number of channels
        
        % cold plate dimension values
        D_chan_cp;        % cold plate channel diameter, m
        L_chan_cp;        % cold plate channel length, m
        N_chan_cp;        % cold plate number of channels
        % other
        cp_thickness;
        cp_width;
        cp_volume;
        
        % cold plate dimensions (old model)
        Accp; % pi/4*D_chan^2*N_chan; % cold plate tube cross sectional area, m^2
        As_HFH; % 0.05*0.05;%pi*D_chan*L_chan*N_chan; % cold plate tube surface area, m^2

        v_HFH_w;
        v_HFH_cu;

    % HEAT EXCHANGER PARAMETERS
        % Heat Exchanger Fundamental Geometric Parameters
        L_tube;        % length, m
        Nt;            % number of tubes
        Do_tube;       % tube outer diameter, m
        wt_rej_tube;   % wall thickness of heat rejection tube, m
        Ds_shell;      % shell diameter, m
        Pt;            % tube pitch, m
        B;             % base size, m
        Np;
        Din_tube;      % Inlet Tube Diameter [m]

        % Heat Exchanger Derived Parameters
        Di_tube;      % heat rejection tube inner diameter, m
        Ltot_r;       % heat rejection tube total length, m
        De_shell;     % 
        Chex;         %

        As_HX_id;     % heat rejection tube total inner surface area, m^2
        As_HX_od;     % heat rejection tube total outer surface area, m^2
        Ac_cool;
        Ac_ref;

        v_HX_w;       % heat rejection tube cross sectional area, m^2
        v_HX_cu;      % heat rejection wall volume, m^3

    % INDIVIDUAL TES MODULE GEOMETRY     
        % Material Heights [Fundamental]
        hp;    % total height of TES Module polycarbonate layer [m]
        hw;    % total height of TES Module water channel [m]
        ha;    % total height of TES Module aluminum plate [m]
        hh;    % total height of TES Module composite layer [m] 

        hf_w;  % height of fins submerged in water [m]

        % Material Lengths [Fundamental]
        Lx;    % length of the TES Module x-direction [m]
        xf_h;  % Length of a fin submerged in hexadecane [m]

        % Material Depths [Fundamental]
        b;     % depth of the TES Module z-direction [m] (treat as infinite)
        bf_w;  % depth of a fin submerged in water [m]

        % Fin Counts [Fundamental]
        nf_h;  % number of fins submerged in hexadecane per module
        nf_w;  % number of fins submerged in water per module

        % Control Volume Heights [Derived]
        dh_p;  % height of polycarbonate control volumes [m]
        dh_w;  % height of water control volumes [m]
        dh_a;  % height of aluminum plate control volumes [m]
        dh_h;  % height of hexadecane control volumes [m]

        % Control Volume Lengths [Derived]
        dx;    % length of control volume in the x-direction [m]
        dx_a;  % the x length in composite control volume that is aluminum [m]
        dx_h;  % the x length in composite control volume that is hexadecane [m]

        % Control Volume Depths [Derived]
        db_a;  % the z length in water control volume that is aluminum [m]
        db_w;  % the z length in water control volume that is water [m]

    % EMPIRICAL PARAMETERS
        % Heat Transfer Coefficients
        hA_cp; % Cold Plate Heat Transfer Coefficient 
        hA_hx; % Heater Exchanger Hot Side Heat Transfer Coefficient

        % Phase Change Parameters
        alphaT;       % constant in from of exponent for sigmoid function
        alpha_TES;      % Heat Transfer Coefficient for TES Module Water Fins

    % HYBRID SYSTEM MASS MATRIX
        % Non-Hybrid TMS Thermal Mass
        m_tank;     % mass of water in reservoir [kg]
        mcp_tank    % thermal mass of reservoir [J/K]

        m_HFH_s;    % high frequency heater solid mass [kg]
        mcp_HFH_s;  % thermal mass of high frequency heater solid [J/K] 

        m_HFH_w;    % mass of water in high frequency heater [kg]
        mcp_HFH_w;  % thermal mass of high frequency heater water [J/K]

        m_HX_cu;    % heat exchanger solid mass [kg]
        mcp_HX_cu;  % thermal mass of heat exchanger solid [J/K]

        m_HX_w;     % mass of water in heat exchanger [kg]
        mcp_HX_w;   % thermal mass of heat exchanger water [J/K]

        % TES Modules Thermal Mass
        m_p;        % mass of polycarbonate in each polycarbonate control volume [kg]
        mcp_p;      % thermal mass of polycarbonate in each polycarbonate control volume [J/K]

        m_w;        % mass of water in each water control volume [kg]
        mcp_w;      % thermal mass of water in each water control volume [J/K]

        m_a;        % mass of aluminum in each aluminum control volume [kg]
        mcp_a;      % thermal mass of aluminum in each pure aluminum control volume [J/K]

        m_a_composite;    % mass of aluminum in composite control volume [kg]
        mcp_al_composite;  % thermal mass of aluminum in composite control volume [J/K]

        m_hex_composite;  % mass of hexadecane in a composite control volume [kg]
        m_hex_composite_vec;

        % Thermal Mass Vectors
        Minv_TMS;   % Non-Hybrid TMS System Mass Matrix
        Minv_TES;   % TES Modules Mass Matrix
        Minv;       % Inverse of Hybrid System Mass Matrix

    % HYBRID TMS SYSTEM STATE MATRIX
        inv_r_HX;                       % Inverse of thermal resistance for HX between hot and cold water nodes [W/K]

        inv_r_al_al_h;                  % nominal inverse of horizontal conduction resistance of aluminum [W/K]
        inv_r_al_al_v2;                 % nominal inverse of vertical conduction resistance of aluminum [W/K]

        r_al_composite_h;               % nominal horizontal thermal resistance of aluminum for every control volume containing hexadecane [W/K]
        inv_r_al_composite_v;           % nominal inverse of vertical thermal resistance of aluminum for every control volume containing hexadecane [W/K]    

        W;                              % matrix to compute some weights in compute_weight_vector

        rTES_water_vector; % initialization of the inverse thermal resistance of water and aluminum in TES module

        I;     % Hybrid TMS System Incidence Matrix 
        It;    % Transpose of Hybrid TMS System Incidence Matrix

    % Hybrid System Gradients
        E;     % gradient of A matrix with respect to control actions

    % HYBRID TMS SYSTEM DISTURBANCE VECTOR
        d;     % Disturbances
        d_SDC; % SDC formulation for disturbances

    % HYBRID TMS SYSTEM GRAPH
        Gu;    % Graph of Hybrid TMS System with only undirected edges
        Gd;    % Graph of Hybrid TMS System with only directed edges
        G;     % Graph of Hybrid TMS System

        x_coords;   % x coordinate of each node in the HYBRID TMS system graph
        y_coords;   % y coordinate of each node in the HYBRID TMS system graph
    end
    
%% Hybrid TMS Methods
    methods
        %% Initialize Model Parameters
        function [varTMS, vTMS] = varModel(nx, ny, nms, nmp)
            varTMS = set_simulation_timing(varTMS);
            varTMS = set_system_discretization(varTMS, nx, ny, nms, nmp);
            varTMS = set_integrator_accuracy(varTMS);
            varTMS = set_initial_conditions(varTMS);
            varTMS = set_boundary_conditions(varTMS);
            varTMS = set_empirical_parameters(varTMS);
            varTMS = set_heat_exchanger_parameters(varTMS);
            varTMS = set_TES_module_geometry(varTMS);
            varTMS = set_material_properties(varTMS);

            varTMS = compute_mass_matrix(varTMS);
            varTMS = compute_state_matrix(varTMS);
            varTMS = initialize_matricies(varTMS);
            varTMS = compute_Su_E_matrix(varTMS);

            vTMS = construct_TMS_struct(varTMS);
        end

        %% Set Simulation Timing
        function varTMS = set_simulation_timing(varTMS)
        % SIMULATION TIMING   
            % Overall Simulation Configuration [Fundamental]
            varTMS.dt   = 1.0;     % sample time of system solver [s]
            varTMS.tf   = 500.0;   % final timestep of simulation [s]
            varTMS.nODE = 10;      % number of time steps returned from ODE solver for each simulation time step [count]
    
            % Simulation & ODE Time Vectors [Derived]
            varTMS.tSIM = (0:varTMS.dt:varTMS.tf)';      % all time steps [s]
            varTMS.tODE = linspace(0,varTMS.dt,varTMS.nODE);      % time steps stored for each iteration of ODE solver [s]
    
            % Execution Count [Derived]
            varTMS.nSIM = length(varTMS.tSIM);      % number of times that controller & ODE Solver will be executed [count]
        end

        %% Set Hybrid TMS System Discretization
        function varTMS = set_system_discretization(varTMS, nx, ny, nms, nmp)
        % HYBRID TMS SYSTEM DISCRETIZATION  
            % Overall Hybrid TMS System Configuration [Fundamental]
            varTMS.nTMS = 5; % number of states in non-hybrid TMS Model
            varTMS.nms  = nms; % number of TES modules in series
            varTMS.nmp  = nmp; % number of TES modules in parallel
    
            % Vertex Count for a Single TES Module [Fundamental]
            varTMS.np  = 0;  % per module number of polycarb control volumes in y-direction
            varTMS.nw  = 1;  % per module number of water control volumes in y-direction
            varTMS.na  = 1;  % per module number of aluminum control volumes in y-direction
            varTMS.nh  = ny;  % per module number of composite (hexadecane + aluminum) control volumes in y-direction
            varTMS.dnx = nx;  % per module number of control volumes in x-direction

            % Edge Count [Fundamental]
            varTMS.ne_TMS = 7; % number of edges in non-hybrid TMS system
    
            % Vertex and Edge Count for All TES Modules [Derived]
            varTMS.nm   = varTMS.nmp * varTMS.nms; % total number of TES modules
            varTMS.ny = (varTMS.nh + varTMS.nw + varTMS.na + varTMS.np);   % number of TES control volumes in y-direction
            varTMS.nx = varTMS.nm * varTMS.dnx;   % number of TES control volumes in x-direction
            varTMS.nv = varTMS.ny * varTMS.nx;   % total number of control volumes in TES Modules Model
    
            % Overall System Vertex Count [Derived]
            varTMS.ns = varTMS.nv + varTMS.nTMS;   % total number of states for Hybrid TMS System
            varTMS.nu = 2;
            varTMS.n_out = 2 + varTMS.nm;
            varTMS.n_hex_start = (varTMS.np+varTMS.nw+varTMS.na)*varTMS.nx + 1 + varTMS.nTMS;
        end

        % Set Integrator Accuracy
        function varTMS = set_integrator_accuracy(varTMS)
            % IRK Integrator
            varTMS.num_steps_IRK = 1;
            varTMS.num_stage_IRK = 1;

            % EXPM Integrator
            varTMS.s_EXPM = 0;
            varTMS.b_EXPM = [1 0.5 0.1 1/120];

            % fmincon
            varTMS.contol = 1e-3;
            varTMS.opttol = 1e-3;
            varTMS.stetol = 1e-3;
        end

        %% Set Initial Conditions
        function varTMS = set_initial_conditions(varTMS)
        % INITIAL CONDITIONS  
            % Non-Hybrid TMS Initial Conditions [Fundamental]
            varTMS.T0_Ttf  = 273.15+10;         % Initial temperature of tank outlet water [K]
            varTMS.T0_Tcpw = 273.15+10;         % Initial temperature of High frequnecy heater wall [K]
            varTMS.T0_Tcpf = 273.15+10;         % Initial temperature of High frequnecy heater outlet water [K]
            varTMS.T0_Thxw = 273.15+10;         % Initial temperature of shell tube wall [K]
            varTMS.T0_Thxf = 273.15+10;         % Initial temperature of shell tube outlet water [K]          
    
            % TES Modules Initial Conditions [Fundamental]
            varTMS.T0_p = 273.15+10;    % polycarbonate initial temperature [K]
            varTMS.T0_w = 273.15+10;    % water initial temperature [K]
            varTMS.T0_a = 273.15+10;    % aluminum plate initial temperature [K]
            varTMS.T0_h = 273.15+10;    % composite initial temperature [K]
    
            % Initial Condition Vectors [Derived]
            varTMS.T0_TMS = [varTMS.T0_Ttf; varTMS.T0_Tcpw; varTMS.T0_Tcpf; varTMS.T0_Thxw; varTMS.T0_Thxf];          % Initial conditions of Non-Hybrid TMS states [K]
            varTMS.T0_TES = [varTMS.T0_p*ones(varTMS.nx*varTMS.np,1); varTMS.T0_w*ones(varTMS.nx*varTMS.nw,1); varTMS.T0_a*ones(varTMS.nx*varTMS.na,1); varTMS.T0_h*ones(varTMS.nx*varTMS.nh,1)];          % Initial temperature of all TES control volumes [K]
            varTMS.T0_ALL = [varTMS.T0_TMS; varTMS.T0_TES];          % Initial Conditions for all states in hybrid system [K]
        end

        %% Set Boundary Conditions
        function varTMS = set_boundary_conditions(varTMS)
        % BOUNDARY CONDITIONS
            % BC for Overall Hybrid TMS System Simulation [Fundamental]
            varTMS.T_CF_t = [0];   % Time vector of chiller inlet water temperature [s]
            varTMS.T_CF_T = [273.15+8];   % Temperature vector of chiller inlet water temperature [K]
            
            % varTMS.Q_HF_t = [0,20,40,70,150,190,210,220,255,290,340,355,370];   % Time vector of high frequency heater power input [s]
            % varTMS.Q_HF_Q = 60*[0,78,65,0,45,70,0,0,55,0,70,13,0];   % Power vector of high frequency heater power input [W]

            varTMS.Q_HF_t = [0,28,55,106,145,180,209,230,270,295,310,360,375,400 500];   % Time vector of high frequency heater power input [s]
            varTMS.Q_HF_Q = 60*[0,85,0,65,0,60,45,0,60,62,62,62,0,0,0];   % Power vector of high frequency heater power input [W]

            varTMS.m_CF_t = [0];   % Time vector of chiller water flow rate [s]
            varTMS.m_CF_m = [0.06];   % Mass flow rate vector of chiller water flow rate [kg/s]

            % Discretized BC for Overall Hybrid TMS System Simulation [Derived]
            varTMS.T_CF = convert_BC_to_vector(varTMS,[varTMS.T_CF_t;varTMS.T_CF_T]);     % Chiller inlet time and temperature discretized to use simulation sample rate [s; K]
            varTMS.Q_HF = convert_BC_to_vector(varTMS,[varTMS.Q_HF_t;varTMS.Q_HF_Q]);     % High frequency heater time and temperature discretized to use simulation sample rate [s; W]
            varTMS.m_CF = convert_BC_to_vector(varTMS,[varTMS.m_CF_t;varTMS.m_CF_m]);     % Chiller inlet time and mass flow rate discretized to use simulation sample rate [kg/s]
        end

        %% Set Material Properties
        function varTMS = set_material_properties(varTMS)
        % MATERIAL PROPERTIES
            % Copper [Fundamental]
            varTMS.rho_cu = 8940;         % nominal density of copper  [kg/m^3]
            varTMS.cp_cu = 385;          % nominal specific heat of copper [J/(kg*K)]
            varTMS.k_cu = 400;           % nominal thermal conductivity of copper [W/(m*K)]
    
            % Polycarbonate [Fundamental]
            varTMS.rho_pc = 1210;         % nominal density of polycarbonate [kg/m^3]
            varTMS.cp_pc = 1200;          % nominal specific heat of polycarbonate [J/(kg*K)]
            varTMS.k_pc = 0.2;           % nominal thermal conductivity of polycarbonate [W/(m*K)]
    
            % Hybrid TMS Water [Fundamental]
            varTMS.rho_water = 998.2;  	 % nominal density of water [kg/m^3]
            varTMS.cp_water = 4185.6;    % nominal specific heat capacity of water [J/(kg*K)]
            varTMS.k_water = 0.6;        % nominal thermal conductivity of water [W/(m*K)]
            varTMS.mu_water = 1.2228e-5; % nominal water dynamic viscosity as saturated vapor, Pa*s

            % Chiller Water [Fundamental]
            varTMS.rho_water_cf = 9.977733415419543e+02; % refpropm('D','T',T_cool,'P',P_cool/1000,Ref); % density, kg/(m^3)
            varTMS.k_water_cf   = 0.601493524639642;     % refpropm('L','T',T_cool,'P',P_cool/1000,Ref); % thermal cond, W/(m*K) 
            varTMS.mu_water_cf  = 9.543962649175429e-04; % refpropm('V','T',T_cool,'P',P_cool/1000,Ref); % dynamic visc, Pa*s
            varTMS.cp_water_cf  = 4.182784286006386e+03; % refpropm('C','T',T_cool,'P',P_cool/1000,Ref); % spec. heat, J/(kg*K)
    
            % Aluminum [Fundamental]
            varTMS.rho_al = 2700;     	% nominal density of aluminum plate [kg/m^3]
            varTMS.cp_al = 896;    	    % nominal specific heat capacity of aluminum plate [J/(kg*K)]
            varTMS.k_al = 167;       	% nominal conductivity of aluminum plate [W/(m*K)]
            
            % Hexadecane [Fundamental]
            varTMS.rho_hex = [806 806 806 806 806 806];        % nominal density of hexadecane [kg/m^3]
            varTMS.cp_hex_solid = [1900 1900 1900 1900 1900 1900];   % nominal specific heat capacity of solid hexadecane [J/(kg*K)]
            varTMS.cp_hex_liquid = [2210 2210 2210 2210 2210 2210];  % nominal specific heat capacity of liquid hexadecane [J/(kg*K)]
            varTMS.k_hex_solid = [0.336 0.336 0.336 0.336 0.336 0.336];    % nominal thermal conductivity of solid hexadecane [W/(m*K)]
            varTMS.k_hex_liquid = [0.1406 0.1406 0.1406 0.1406 0.1406 0.1406];   % nominal thermal conductivity of liquid hexadecane [W/(m*K)]
            varTMS.e_hex_latent = [236890 236890 236890 236890 236890 236890];    	% specific latent heat of Hexadecane [J/kg]
    
            varTMS.T_hex_melt = 273.15 + [16.3 16.3 16.3 16.3 16.3 16.3];  	% nominal melting temperature of hexadecane [K]
            varTMS.T_hex_liquidus = 273.15 + [17.9 17.9 17.9 17.9 17.9 17.9];         % Hexadecane liquidus temperature [K]
            varTMS.T_hex_solidus = 273.15 + [14.7 14.7 14.7 14.7 14.7 14.7];         % Hexadecane solidus temperature [K]
            varTMS.dT_hex = 5;      % +/- temperature for max/min SOC

            % Hexadecane [Derived]
            varTMS.rho_hex_vec= TES_matprop_vectorize(varTMS,varTMS.rho_hex);        % nominal density of hexadecane [kg/m^3]
            varTMS.cp_hex_solid_vec= TES_matprop_vectorize(varTMS,varTMS.cp_hex_solid);   % nominal specific heat capacity of solid hexadecane [J/(kg*K)]
            varTMS.cp_hex_liquid_vec= TES_matprop_vectorize(varTMS,varTMS.cp_hex_liquid);  % nominal specific heat capacity of liquid hexadecane [J/(kg*K)]
            varTMS.k_hex_solid_vec= TES_matprop_vectorize(varTMS,varTMS.k_hex_solid);    % nominal thermal conductivity of solid hexadecane [W/(m*K)]
            varTMS.k_hex_liquid_vec= TES_matprop_vectorize(varTMS,varTMS.k_hex_liquid);   % nominal thermal conductivity of liquid hexadecane [W/(m*K)]
            varTMS.e_hex_latent_vec= TES_matprop_vectorize(varTMS,varTMS.e_hex_latent);    	% specific latent heat of Hexadecane [J/kg]
    
            varTMS.T_hex_melt_vec= TES_matprop_vectorize(varTMS,varTMS.T_hex_melt);  	% nominal melting temperature of hexadecane [K]
            varTMS.T_hex_liquidus_vec= TES_matprop_vectorize(varTMS,varTMS.T_hex_liquidus);         % Hexadecane liquidus temperature [K]
            varTMS.T_hex_solidus_vec= TES_matprop_vectorize(varTMS,varTMS.T_hex_solidus);         % Hexadecane solidus temperature [K]

            varTMS.Tmin = varTMS.T_hex_melt(1) - varTMS.dT_hex;
            varTMS.Tmax = varTMS.T_hex_melt(1) + varTMS.dT_hex;

            qmin1 = varTMS.cp_hex_solid(1).*(varTMS.Tmin-varTMS.T_hex_melt(1));
            qmin2 = (varTMS.cp_hex_liquid(1) - varTMS.cp_hex_solid(1))./varTMS.alphaT .* log(1 + exp(varTMS.alphaT.*(varTMS.Tmin-varTMS.T_hex_melt(1))));
            qmin3 = varTMS.e_hex_latent_vec(1)./2.*tanh(varTMS.alphaT./2.*(varTMS.Tmin-varTMS.T_hex_melt(1)));
            varTMS.qmin = (qmin1 + qmin2 + qmin3) .* varTMS.f .* varTMS.rho_hex(1) + varTMS.cp_al.*(varTMS.Tmin-varTMS.T_hex_melt(1)) .* (1 - varTMS.f) .* varTMS.rho_al;

            qmax1 = varTMS.cp_hex_solid(1).*(varTMS.Tmax-varTMS.T_hex_melt(1));
            qmax2 = (varTMS.cp_hex_liquid(1) - varTMS.cp_hex_solid(1))./varTMS.alphaT .* log(1 + exp(varTMS.alphaT.*(varTMS.Tmax-varTMS.T_hex_melt(1))));
            qmax3 = varTMS.e_hex_latent(1)./2.*tanh(varTMS.alphaT./2.*(varTMS.Tmax-varTMS.T_hex_melt(1)));
            varTMS.qmax = (qmax1 + qmax2 + qmax3) .* varTMS.f .* varTMS.rho_hex(1) + varTMS.cp_al.*(varTMS.Tmax-varTMS.T_hex_melt(1)) .* (1 - varTMS.f) .* varTMS.rho_al;
        end

        %% Set Empirical Parameters
        function varTMS = set_empirical_parameters(varTMS)
            % heat transfer coefficients
            varTMS.hA_cp = 180; % [W/K]
            varTMS.hA_hx = 375; % [W/K]
            varTMS.inv_r_HX = 1600; % [W/K]

            % Phase change function parameters    
            varTMS.alphaT  = 1;        % parameter to modify sigmoid function for hexadecane [K] 

            % Convection Coeffients for Hybrid TMS
            varTMS.alpha_TES = 7500.*ones(varTMS.nw*varTMS.nx,1);
        end

        %% Set Heat Exchanger Parameters
        function varTMS = set_heat_exchanger_parameters(varTMS)
        % Heat Exchanger Tube Dimensions
            varTMS.L_tube         = 10*0.0254;        % length, m
            varTMS.Nt             = 50;               % number of tubes
            varTMS.Do_tube        = 1/4*0.0254;       % tube outer diameter, m
            varTMS.wt_rej_tube    = 1/32*0.0254;      % wall thickness of heat rejection tube, m
            varTMS.Ds_shell       = 3*0.0254;         % shell diameter, m
            varTMS.Pt             = 3/8*0.0254;       % tube pitch, m
            varTMS.B              = 3/2*0.0254;       % base size, m
            varTMS.Np             = 1;
            varTMS.Din_tube       = 0.33*25.4/1000;   % Inlet Tube Diameter [m]

        % Heat Exchanger Volume Computation
            varTMS.Di_tube   = varTMS.Do_tube - 2*varTMS.wt_rej_tube;           % heat rejection tube inner diameter, m
            varTMS.Ltot_r    = varTMS.L_tube*varTMS.Nt;   % heat rejection tube total length, m
            varTMS.De_shell  = 4*varTMS.Pt^2/(pi*varTMS.Do_tube) - varTMS.Do_tube; 
            varTMS.Chex      = varTMS.Pt - varTMS.Do_tube;

        % Heat Exchanger Volume [Derived]
            varTMS.v_HX_w    = (pi/4*varTMS.Di_tube^2)*varTMS.Ltot_r;     % heat rejection tube cross sectional area, m^2
            varTMS.v_HX_cu   = varTMS.Ltot_r*pi/4*(varTMS.Do_tube^2-varTMS.Di_tube^2);  % heat rejection wall volume, m^3
            
            varTMS.As_HX_id  = varTMS.Ltot_r*pi*(varTMS.Di_tube);               % heat rejection tube total inner surface area, m^2
            varTMS.As_HX_od  = pi*varTMS.Do_tube*varTMS.Ltot_r;                 % heat rejection tube total outer surface area, m^2
            varTMS.Ac_cool   = pi*(varTMS.Din_tube/2)^2;
            varTMS.Ac_ref    = pi/4*varTMS.Di_tube^2*varTMS.Nt/varTMS.Np;
        end

        %% Set TES Module Geometry
        function varTMS = set_TES_module_geometry(varTMS)
        % TES MODULE GEOMETRY    
            % Material Heights [Fundamental]
            varTMS.hp = 0.5*0.0254;    % total height of TES Module polycarbonate layer [m]
            varTMS.hw = 0.0015;    % total height of TES Module water channel [m]
            varTMS.ha = 0.001;    % total height of TES Module aluminum plate [m]
            varTMS.hh = 0.0068;    % total height of TES Module composite layer [m]  
    
            varTMS.hf_w = 0.001;  % height of fins submerged in water [m]
            
            % Material Lengths [Fundamental]
            varTMS.Lx = 0.15;    % length of the TES Module x-direction [m]
            varTMS.xf_h = 0.00032;  % length of fins submerged in hexadecane [m]
    
            % Material Depths [Fundamental]
            varTMS.b = 0.1171;     % depth of the TES Module z-direction [m] (treat as infinite)
            varTMS.bf_w = 0.0005;  % depth of a fin submerged in water [m]
    
            % Fin Counts [Fundamental]
            varTMS.nf_h = 75; % number of fins submerged in hexadecane per module
            varTMS.nf_w = 78; % number of fins submerged in water per module
    
            % Control Volume Heights [Derived]
            varTMS.dh_p = varTMS.hp/varTMS.np;  % height of polycarbonate control volumes [m]
            varTMS.dh_w = varTMS.hw/varTMS.nw;  % height of water control volumes [m]
            varTMS.dh_a = varTMS.ha/varTMS.na;  % height of aluminum plate control volumes [m]
            varTMS.dh_h = varTMS.hh/varTMS.nh;  % height of composite control volumes [m]
    
            % Control Volume Lengths [Derived]
            varTMS.dx = varTMS.Lx/varTMS.dnx;    % length of control volume in the x-direction [m]
            varTMS.dx_a = (varTMS.nf_h*varTMS.xf_h)/varTMS.dnx;  % the x length in composite control volume that is aluminum [m]
            varTMS.dx_h = varTMS.dx - varTMS.dx_a;  % the x length in composite control volume that is hexadecane [m]
            
            % Control Volume Depths [Derived]
            varTMS.db_a = varTMS.nf_w*varTMS.bf_w;  % the z length in water control volume that is aluminum [m]
            varTMS.db_w = varTMS.b - varTMS.db_a;  % the z length in water control volume that is water [m]

            % Composite PCM Properties
            varTMS.f = (varTMS.xf_h*varTMS.nf_h) / varTMS.Lx;
        end
        
        %% Compute Hybrid System Mass Matrix
        function varTMS = compute_mass_matrix(varTMS)
        % THERMAL MASS
            % Tank Thermal Mass
            varTMS.m_tank = 1; % [kg]
            varTMS.mcp_tank = varTMS.m_tank*varTMS.cp_water;

            % High Frequency Heater Solid Thermal Mass
            varTMS.m_HFH_s   = 1.63; % high frequency heater mass [kg]
            varTMS.mcp_HFH_s = varTMS.m_HFH_s*varTMS.cp_al;

            % High Frequency Heater Water Thermal Mass
            varTMS.m_HFH_w = 0.06; % high frequency heater water mass [kg]
            varTMS.mcp_HFH_w = varTMS.m_HFH_w*varTMS.cp_water;

            % Heat Exchanger Solid Thermal Mass
            varTMS.m_HX_cu   = varTMS.rho_cu*varTMS.v_HX_cu;
            varTMS.mcp_HX_cu = varTMS.cp_cu*varTMS.m_HX_cu;

            % Heat Exchanger Water Thermal Mass
            varTMS.m_HX_w   = varTMS.rho_water*varTMS.v_HX_w;
            varTMS.mcp_HX_w = varTMS.cp_water*varTMS.m_HX_w;

            % Polycarbonate Control Volume Thermal Mass
            varTMS.m_p   = varTMS.rho_pc*varTMS.dx*varTMS.b*varTMS.hp;
            varTMS.mcp_p = varTMS.cp_pc*varTMS.m_p;
            
            % Water Control Volume Thermal Mass
            varTMS.m_w   = varTMS.rho_water*varTMS.dx*varTMS.b*varTMS.hw;
            varTMS.mcp_w = varTMS.cp_water*varTMS.m_w;
            
            % Aluminum Control Volume Thermal Mass
            varTMS.m_a   = varTMS.rho_al*varTMS.dx*varTMS.b*varTMS.ha;
            varTMS.mcp_a = varTMS.cp_al*varTMS.m_a;
            
            % Aluminum and Hexadecane Control Volume Thermal Mass
            varTMS.m_a_composite = varTMS.rho_al*varTMS.dx_a*varTMS.b*varTMS.dh_h;
            varTMS.mcp_al_composite = varTMS.cp_al*varTMS.m_a_composite;

            varTMS.m_hex_composite = varTMS.rho_hex*varTMS.dx_h*varTMS.b*varTMS.dh_h;
            varTMS.m_hex_composite_vec = TES_matprop_vectorize(varTMS,varTMS.m_hex_composite);

            % Non-Hybrid TMS System Inverse of Thermal Mass
            varTMS.Minv_TMS = 1./[varTMS.mcp_tank;varTMS.mcp_HFH_s;varTMS.mcp_HFH_w;varTMS.mcp_HX_cu;varTMS.mcp_HX_w];

            % TES Module Control Volume Inverse of Thermal Mass
            varTMS.Minv_TES = 1./([varTMS.mcp_p*ones(varTMS.nx*varTMS.np,1); varTMS.mcp_w*ones(varTMS.nx*varTMS.nw,1); varTMS.mcp_a*ones(varTMS.nx*varTMS.na,1); varTMS.mcp_al_composite*ones(varTMS.nx*varTMS.nh,1)]);
            
            % Hybrid TMS Inverse of Thermal Mass
            varTMS.Minv = [varTMS.Minv_TMS; varTMS.Minv_TES];
        end
        
        %% Compute Hybrid System State Matrix
        function varTMS = compute_state_matrix(varTMS)
        % Compute Constant Thermal Resistances for Hybrid TMS System
            varTMS.inv_r_al_al_h           = (ones(varTMS.na*(varTMS.nx-varTMS.nm),1)*varTMS.k_al*varTMS.dh_a*varTMS.b)/varTMS.dx;   % nominal inverse of horizontal conduction resistance of aluminum [W/K]
            varTMS.inv_r_al_al_v2          = (varTMS.k_al*varTMS.dx*varTMS.b)/varTMS.dh_a;   % nominal inverse of vertical conduction resistance of aluminum [W/K]

            varTMS.r_al_composite_h        = varTMS.dx_a/(varTMS.k_al*varTMS.b*varTMS.dh_h); % horizontal thermal resistance of aluminum for every control volume containing hexadecane [W/K]
            varTMS.inv_r_al_composite_v    = (2*varTMS.k_al*varTMS.b*varTMS.dx_a)/varTMS.dh_h; % inverse of vertical thermal resistance of aluminum for every control volume containing hexadecane [W/K]     

        % Compute graph & relevant matrix I (Incidence)
            varTMS = construct_TMS_graph(varTMS);

        % Compute Weight Vector
            % varTMS.W = [eye(varTMS.nx-1); zeros(varTMS.ny,varTMS.nx-1)];
            varTMS.W = eye(varTMS.nx-1);

            % for ODE
            for i = 1:varTMS.nm-1
                varTMS.W(varTMS.dnx*i-(i-1),:) = [];
            end
        end

        %% EXPM u Gradient [matrix version]
        function varTMS = compute_Su_E_matrix(varTMS)
            varTMS.E = zeros(varTMS.ns,varTMS.nu*varTMS.ns);

            nk = varTMS.ns-varTMS.nTMS-2*varTMS.dnx*varTMS.nm;
            nK = length(compute_weight_vector([0;0],zeros(nk,1),varTMS));
            nM = nK - (2*varTMS.nu + 1 + (varTMS.nu - 1)*length(varTMS.rTES_water_vector)) + 1;
            u_grad_in = diag(ones(varTMS.nu,1));
            for i = 1:varTMS.nu
                idx0 = 1+((i-1)*varTMS.ns);
                idx1 = idx0 + varTMS.ns - 1;

                Kj = compute_weight_vector(u_grad_in(i,:)',zeros(nk,1),varTMS);
                K = zeros(nK,1);
                K(nM:end) = Kj(nM:end);

                dA = -varTMS.I*(K.*varTMS.It);
                varTMS.E(:,idx0:idx1) = varTMS.Minv.*dA;
            end
        end

        %% Initialize Matricies
        function varTMS = initialize_matricies(varTMS)
            varTMS.d = zeros(varTMS.nv+varTMS.nTMS,1);
            varTMS.rTES_water_vector = ones(varTMS.nmp,varTMS.nw*((varTMS.nms*varTMS.dnx)-1));
        end

        %% Construct TMS Structure
        function vTMS = construct_TMS_struct(varTMS)
            % Overall System Matricies
            vTMS.d = varTMS.d;
            vTMS.Minv = varTMS.Minv;
            vTMS.I = varTMS.I;
            vTMS.It = varTMS.It;

            % Integrator Parameters
            vTMS.num_steps_IRK = varTMS.num_steps_IRK;
            vTMS.num_stage_IRK = varTMS.num_stage_IRK;

            vTMS.s_EXPM = varTMS.s_EXPM;
            vTMS.b_EXPM = varTMS.b_EXPM;

            % Hexadecane Material Properties
            vTMS.rho_hex_vec = varTMS.rho_hex_vec;
            vTMS.T_hex_melt_vec = varTMS.T_hex_melt_vec;
            vTMS.k_hex_liquid_vec = varTMS.k_hex_liquid_vec;
            vTMS.k_hex_solid_vec = varTMS.k_hex_solid_vec;
            vTMS.cp_hex_solid_vec = varTMS.cp_hex_solid_vec;
            vTMS.cp_hex_liquid_vec = varTMS.cp_hex_liquid_vec;
            vTMS.e_hex_latent_vec = varTMS.e_hex_latent_vec;
            vTMS.alphaT = varTMS.alphaT;

            % TES Module Discretization
            vTMS.dx_h = varTMS.dx_h;
            vTMS.dh_h = varTMS.dh_h;
            vTMS.b = varTMS.b;
            vTMS.dx = varTMS.dx;
            vTMS.nm = varTMS.nm;
            vTMS.nms = varTMS.nms;
            vTMS.nmp = varTMS.nmp;

            % HFH Parameters
            vTMS.hA_cp = varTMS.hA_cp;

            % HX Parameters
            vTMS.hA_hx = varTMS.hA_hx;
            vTMS.inv_r_HX = varTMS.inv_r_HX;

            % TES Module Parameters
            vTMS.alpha_TES = varTMS.alpha_TES;

            % mass matrix
            vTMS.mcp_al_composite = varTMS.mcp_al_composite;
            vTMS.m_hex_composite_vec = varTMS.m_hex_composite_vec;

            % indexing
            vTMS.n_hex_start = varTMS.n_hex_start;
            vTMS.nx = varTMS.nx;
            vTMS.nh = varTMS.nh;
            vTMS.dnx = varTMS.dnx;
            vTMS.ns = varTMS.ns;
            vTMS.nTMS = varTMS.nTMS;
            vTMS.nv = varTMS.nv;

            % properties
            vTMS.cp_water = varTMS.cp_water;

            % resistance
            vTMS.inv_r_al_al_h           = varTMS.inv_r_al_al_h;   % nominal inverse of horizontal conduction resistance of aluminum [W/K]
            vTMS.inv_r_al_al_v2          = varTMS.inv_r_al_al_v2;   % nominal inverse of vertical conduction resistance of aluminum [W/K]

            vTMS.r_al_composite_h        = varTMS.r_al_composite_h; % horizontal thermal resistance of aluminum for every control volume containing hexadecane [W/K]
            vTMS.inv_r_al_composite_v    = varTMS.inv_r_al_composite_v; % inverse of vertical thermal resistance of aluminum for every control volume containing hexadecane [W/K]     
            vTMS.rTES_water_vector       = varTMS.rTES_water_vector;

            vTMS.W = varTMS.W;
            vTMS.E = varTMS.E;

            % timing
            vTMS.dt = varTMS.dt;

            % Disturbances
            vTMS.Q_HF = varTMS.Q_HF;
            vTMS.T_CF = varTMS.T_CF;

            % initial conditions
            vTMS.T0_ALL = varTMS.T0_ALL;

            % initialization
            vTMS.Iuv = eye(vTMS.ns+1);
            vTMS.Z = zeros(1,vTMS.ns+1);
        end

        %% Compute Chiller Resistance
        function inv_r_HX = compute_inv_r_HX(varTMS)
            % shell flow characteristics for HTC calculation
            nu = varTMS.mu_water_cf/varTMS.rho_water_cf; % kinematic visc, m^2/s
            Pr = nu*varTMS.rho_water_cf*varTMS.cp_water_cf/varTMS.k_water_cf; % Prandtl number, (--)
            V = varTMS.m_CF_m/(varTMS.rho_water_cf*varTMS.Ac_cool); % shell fluid velocity, m/s
            Re = V*varTMS.De_shell/nu;  % Reynolds number, (--)
            Nu_shell = 0.36*(Re^0.55)*(Pr^(1/3)); % Nusselt number, (--)

            % shell heat transfer
            alpha_c    = Nu_shell*varTMS.k_water_cf/varTMS.De_shell; % W/(m^2*K)
            NTU        = alpha_c*varTMS.As_HX_od/(varTMS.m_CF_m*varTMS.cp_water);
            inv_r_HX = varTMS.m_CF_m*varTMS.cp_water*(1-exp(-NTU));
        end

        %% Compute System Graph Matrices
        function varTMS = construct_TMS_graph(varTMS)
            % Extract Simulation Discretization
            h = varTMS.nTMS;
            y = varTMS.ny;
            x = varTMS.nx;
            w = varTMS.nw;
            a = varTMS.na;
            c = varTMS.nh;
            m = varTMS.nm;
            v = varTMS.nv;
            p = varTMS.nmp;
            z = varTMS.nms;
            n = varTMS.dnx;

            % Construct Node Matricies
                % numbered list of all Non-Hybrid TMS nodes
                nh_TMS_nodes = 1:h;
            
                % numbered list of all water nodes
                water_nodes = nh_TMS_nodes(end)+1:nh_TMS_nodes(end)+(x*w);
                water_nodes_1 = reshape(water_nodes,[x/m,w*m]);
                water_nodes_2 = reshape(water_nodes,[x,w]);
                
                % numbered list of all aluminum nodes
                al_nodes = water_nodes(end)+1:water_nodes(end)+(x*a);
                al_nodes_1 = reshape(al_nodes,[x/m,a*m]);
                al_nodes_2 = reshape(al_nodes,[x,a]);
            
                % numbered list of all composite nodes
                composite_nodes = al_nodes(end)+1:al_nodes(end)+(x*c);
                composite_nodes_1 = reshape(composite_nodes,[x/m,c*m]);
                composite_nodes_2 = reshape(composite_nodes,[x,c]);

            % Construct Non-Hybrid TMS Undirected Edges
                nh_TMS_h1 = [2; 4];
                nh_TMS_h2 = [3; 5];
            
            % Construct Horizontal Undirected Edges
                % ordered pairs of horizontal alumiunum to alumiunum edges
                al_nodes_h1 = al_nodes_1(1:end-1,:);
                al_nodes_h2 = al_nodes_1(2:end,:);
            
                % ordered pairs of horizontal composite to composite edges
                composite_nodes_h1 = composite_nodes_1(1:end-1,:);
                composite_nodes_h2 = composite_nodes_1(2:end,:);
            
            % Construct Vertical Undirected Edges                       
                % ordered pairs of vertical water to aluminum edges
                water_al_edges_v1 = water_nodes_2(:,end);
                water_al_edges_v2 = al_nodes_2(:,1);
            
                % ordered pairs of vertical aluminum to composite edges
                al_composite_edges_v1 = al_nodes_2(:,end);
                al_composite_edges_v2 = composite_nodes_2(:,1);
            
                % ordered pairs of vertical aluminum to composite edges
                composite_edges_v1 = composite_nodes_2(:,1:end-1);
                composite_edges_v2 = composite_nodes_2(:,2:end);

            % Construct Non-Hybrid TMS Directed Edges
                % ordered pairs of non-hybrid TMS and inlet,outlet nodes
                input_nodes = (6+(0:1:(p-1)).*(n*z))';
                output_nodes = (6+(n*z)-1+(0:1:(p-1)).*(n*z))';

                tms_nodes_h1 = [1;3;5;5*ones(p,1);output_nodes];
                tms_nodes_h2 = [3;5;1;input_nodes;1*ones(p,1)];

                water_nodes_h1 = [];
                water_nodes_h2 = [];

                for i = 1:p
                    water_nodes_h1 = [water_nodes_h1; (input_nodes(i):1:output_nodes(i)-1)'];
                    water_nodes_h2 = [water_nodes_h2; (input_nodes(i)+1:1:output_nodes(i))'];
                end
            
            % Constuct Undirected System Graph
                tu = [nh_TMS_h1(:); al_nodes_h1(:); composite_nodes_h1(:); water_al_edges_v1(:); al_composite_edges_v1(:); composite_edges_v1(:)];
                su = [nh_TMS_h2(:); al_nodes_h2(:); composite_nodes_h2(:); water_al_edges_v2(:); al_composite_edges_v2(:); composite_edges_v2(:)];
            
                varTMS.Gu = graph(tu,su);

            % Construct Directed System Graph
                td = [tms_nodes_h1; water_nodes_h1];
                sd = [tms_nodes_h2; water_nodes_h2];

                varTMS.Gd = graph(td,sd);

            % Construct System Graph
                t = [tu; su; td];
                s = [su; tu; sd];

                varTMS.G = digraph(t,s);
                varTMS.ne = length([tu;td]);
                varTMS.ne_u = length(tu);
            
            % Reorder System Matrices to be in the desired order
                I_temp = incidence(varTMS.G);            
                edges = findedge(varTMS.G,t,s);
                varTMS.I = zeros(h+v,varTMS.ne);
            
                for i = 1:varTMS.ne+varTMS.ne_u
                    varTMS.I(:,i) = I_temp(:,edges(i));
                end

                varTMS.I = [varTMS.I(:,1:varTMS.ne_u) varTMS.I(:,2*varTMS.ne_u+1:end)];
            
                % Pre-Compute Transpose
                varTMS.It = varTMS.I';

                % For the edges that are directed, removed the negatives to
                % ensure correct computation of state matrix
                varTMS.I(:,varTMS.ne_u+1:end) = max(varTMS.I(:,varTMS.ne_u+1:end),0);

                varTMS.x_coords = [x x+1 x 0 1 repmat(1:x,1,y)];
                varTMS.y_coords = repmat(1:y,x,1);
                varTMS.y_coords = [0 -1 -1 0 0 varTMS.y_coords(:)'];

                % figure(420)
                % plot(varTMS.G,"XData",varTMS.x_coords,"YData",varTMS.y_coords);
        end

        %% Helper Function to Discretize Boundary Conditions
        function BC_vector = convert_BC_to_vector(varTMS,BC_scalar)
            time_BC = BC_scalar(1,end);
            time_SIM = varTMS.tf + 100;
            length_BC = round(max([time_BC time_SIM]) ./ varTMS.dt) + 1;
            BC_vector = zeros(1,length_BC);

            j = 1;
            for i = 1:length_BC
                if (j+1 < size(BC_scalar,2)) && ((i-1)*varTMS.dt >= BC_scalar(1,j+1))
                    j=j+1;
                end
                BC_vector(i) = BC_scalar(2,j);
            end
        end

        %% Helper Function to Vectorize TES Module Properties
        function TES_vec = TES_matprop_vectorize(varTMS,TES_scalar)
            num_modules = varTMS.nm;
            initial_mat = ones(varTMS.nh,varTMS.dnx);
            TES_mat = [];

            for i = 1:num_modules
                TES_mat = [TES_mat initial_mat*TES_scalar(i)];
            end

            TES_mat = TES_mat';
            TES_vec = TES_mat(:);
            
        end
    end
end