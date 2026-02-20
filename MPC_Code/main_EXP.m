function data = main_EXP(varTMS, vTMS)
    %% Load MPC Parameter Set
    [varNMPC, vMPC]   = varController(varTMS); % define Controller variable class
    
    %% Model Definition
    fmpc  = @MPC_EXP;                % controller function
    fsim  = @Hybrid_TMS_Model_ODE;   % ground truth for states
    fout_SIM  = @outputs;            % output for SIM
    
    %% Simulation Timing 
    tSIM = varTMS.tSIM;	      % all simulation time steps (s)
    tODE = varTMS.tODE;	      % all simulation time steps (s)
    k    = varTMS.nSIM;       % number of simulation times steps to compute control action
    
    %% Boundary Conditions
    Q_HF = varTMS.Q_HF;      % Power Input from high frequency heater [W]
    T_CF = varTMS.T_CF;      % Chiller Inlet Temperature [K]
    m_CF = varTMS.m_CF;    % Chiller mass flow rate [kg/s]
    d_SYS = [Q_HF; T_CF; m_CF];  % all disturbances
    
    %% Initial Conditions
    x0_SIM = varTMS.T0_ALL;  % Initial Conditions for States
    U0_MPC = varNMPC.U0;     % Initial Conditions for Control Actions
    u0 = U0_MPC(1:2);
    
    %% Variable Count
    Npx = vMPC.Npx;     % Number of states to use for evaluate cost function
    
    nu       = varTMS.nu;   % total number of control actions in both Models
    nx_SIM   = varTMS.ns;   % total number of states in Simulation Model
    ny_SIM   = varTMS.n_out;    % total number of outputs in Simulation Model
    
    %% Initialize Tracking Variables
    nSIM = varTMS.nSIM;      % length of time, all time steps [count]
    
    u_SYS   = zeros(nSIM,nu);       % All controls in simulation
    x_SYS   = zeros(nSIM,nx_SIM);   % All states in simulation
    y_SYS   = zeros(nSIM,ny_SIM);   % All outputs in simulation
    
    t_MPC                 = zeros(nSIM,1);      % MPC execution time
    J_MPC                 = zeros(nSIM,1);      % MPC cost function
    U_MPC                 = zeros(nu,Npx,nSIM); % MPC control trajectory
    D_MPC                 = zeros(3,Npx,nSIM);  % MPC disturbance trajectory
    o_MPC.iteration       = zeros(nSIM,1);
    o_MPC.funcCount       = zeros(nSIM,1);
    o_MPC.lssteplength    = zeros(nSIM,1);
    o_MPC.constrviolation = zeros(nSIM,1);
    o_MPC.stepsize        = zeros(nSIM,1);
    o_MPC.firstorderopt   = zeros(nSIM,1);
    o_MPC.flag            = zeros(nSIM,1);
    
    %% Configure ODE Solver
    optionsODE = odeset('MaxStep',0.5);
    
    %% Configure Optimizer
    TypicalX = repmat(ones(nu,1)*varNMPC.u_ub(1)/2,Npx,1);
    
    optionsMPC = optimoptions('fmincon','Algorithm','sqp','Display','none', ...
	    'SpecifyObjectiveGradient',true,'CheckGradients',false, ...
	    'ConstraintTolerance',2e-3,'OptimalityTolerance',5e-3,'StepTolerance',1e-3, ...
	    'UseParallel',false,'MaxSQPIter',5,'TypicalX',TypicalX,'ScaleProblem',true);
    
    %% Do Closed Loop Simulation of MPC
    for i = 1:k
        % define disturbance input 
        d0_MPC = d_SYS(:,i:i+Npx-1);
        d0_SYS = d_SYS(:,i);
    
        % compute simulation output
        y0_SIM = fout_SIM(x0_SIM, u0, varTMS);
    
        % save state and output data for simulation
        x_SYS(i,:) = x0_SIM;
        y_SYS(i,:) = y0_SIM;
    
        % sample the controller
        tic;
        [U0_MPC,J,f,o] = fmpc(x0_SIM,U0_MPC,d0_MPC,vTMS,vMPC,optionsMPC);
        u0 = U0_MPC(1:2);
        t_MPC(i)= toc;
    
        % save controller outputs
        u_SYS(i,:) = u0;
        U_MPC(:,:,i) = reshape(U0_MPC,nu,Npx);
        D_MPC(:,:,i) = d0_MPC;
        J_MPC(i) = J;
    
        o_MPC.iteration(i)       = o.iterations;
        o_MPC.funcCount(i)       = o.funcCount;
        o_MPC.lssteplength(i)    = o.lssteplength;
        o_MPC.constrviolation(i) = o.constrviolation;
        o_MPC.stepsize(i)        = o.stepsize;
        o_MPC.firstorderopt(i)   = o.firstorderopt;
        o_MPC.flag(i)            = f;
        
        % sample the plant using ZOH and ode solver to integrate
        x0_SIM = fsim(tODE,x0_SIM,u0,d0_SYS,vTMS,optionsODE);
    
        disp(i)
    end
    
    %% Package Output
    data.time = tSIM; % simulation time
    
    % raw simulation results
    data.x = x_SYS; % system states
    data.y = y_SYS; % system outputs
    data.u = u_SYS; % system controls
    data.d = d_SYS; % system disturbances
    
    data.U = U_MPC; % predicted control sequence
    data.D = D_MPC; % applied disturbance sequence
    
    data.t = t_MPC; % optimization time
    data.j = J_MPC; % fmincon cost
    data.o = o_MPC; % fmincon output
end