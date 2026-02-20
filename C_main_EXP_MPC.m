%% Add path to all subfolders
addpath(genpath(pwd))

%% Load Prediction System Parameter Set
nx_MPC = 3;
ny_MPC = 4;
nms_MPC = 4;
nmp_MPC = 1;
[varTMS_MPC, vTMS_MPC]  = varModel(nx_MPC, ny_MPC, nms_MPC, nmp_MPC);   % define TMS variable class

%% Load Simulation System Parameter Set
nx_SIM = 2*nx_MPC;
ny_SIM = 2*ny_MPC;
nms_SIM = 4;
nmp_SIM = 1;
[varTMS_SIM, vTMS_SIM]  = varModel(nx_SIM, ny_SIM, nms_SIM, nmp_SIM);   % define TMS variable class

%% Load MPC Parameter Set
[varNMPC_MPC, vMPC_MPC]   = varController(varTMS_MPC); % define Controller variable class

%% Load High Dimension MPC Parameter Set
[varNMPC_SIM, vMPC_SIM]   = varController(varTMS_SIM); % define Controller variable class

%% Model Definition
fmpc  = @MPC_EXP;                % controller function
fsim  = @Hybrid_TMS_Model_ODE;   % ground truth for states
fout_MPC  = @outputs;            % output for MPC
fout_SIM  = @outputs;            % output for SIM
fcon  = @Hybrid_TMS_Lumped_Inverse_SE;  % convert sim to mpc model

%% Simulation Timing 
tSIM = varTMS_SIM.tSIM;	      % all simulation time steps (s)
tODE = varTMS_SIM.tODE;	      % all simulation time steps (s)
k    = varTMS_SIM.nSIM;       % number of simulation times steps to compute control action

%% Boundary Conditions
Q_HF = varTMS_SIM.Q_HF;      % Power Input from high frequency heater [W]
T_CF = varTMS_SIM.T_CF;      % Chiller Inlet Temperature [K]
m_CF = varTMS_SIM.m_CF;    % Chiller mass flow rate [kg/s]
d_SYS = [Q_HF; T_CF; m_CF];  % all disturbances

%% Initial Conditions
x0_SIM = varTMS_SIM.T0_ALL;  % Initial Conditions for States
U0_MPC = varNMPC_MPC.U0;     % Initial Conditions for Control Actions
u0 = U0_MPC(1:2);

%% Variable Count
Npx = vMPC_MPC.Npx;     % Number of states to use for evaluate cost function

nu       = varTMS_SIM.nu;   % total number of control actions in both Models
nx_SIM   = varTMS_SIM.ns;   % total number of states in Simulation Model
ny_SIM   = varTMS_SIM.n_out;    % total number of outputs in Simulation Model

nx_MPC   = varTMS_MPC.ns;   % total number of states in Simulation Model
ny_MPC   = varTMS_MPC.n_out;    % total number of outputs in Simulation Model

%% Initialize Tracking Variables
nSIM = varTMS_SIM.nSIM;      % length of time, all time steps [count]

u_SYS   = zeros(nu,nSIM);       % All controls in simulation
x_SYS   = zeros(nx_SIM,nSIM);   % All states in simulation
y_SYS   = zeros(ny_SIM,nSIM);   % All outputs in simulation

x_MPC   = zeros(nx_MPC,nSIM);   % All states in MPC
y_MPC   = zeros(ny_MPC,nSIM);   % All outputs in MPC

t_MPC                 = zeros(1,nSIM);      % MPC execution time
J_MPC                 = zeros(1,nSIM);      % MPC cost function
U_MPC                 = zeros(nu,Npx,nSIM); % MPC control trajectory
D_MPC                 = zeros(3,Npx,nSIM);  % MPC disturbance trajectory
o_MPC.iteration       = zeros(nSIM,1);
o_MPC.funcCount       = zeros(nSIM,1);
o_MPC.lssteplength    = zeros(nSIM,1);
o_MPC.constrviolation = zeros(nSIM,1);
o_MPC.stepsize        = zeros(nSIM,1);
o_MPC.firstorderopt   = zeros(nSIM,1);
o_MPC.flag            = zeros(nSIM,1);

J_High_Fidelity       = zeros(nSIM,1);

%% Configure ODE Solver
optionsODE = odeset('MaxStep',0.5);

%% Configure Optimizer
TypicalX = repmat(ones(nu,1)*varNMPC_MPC.u_ub(1)/2,Npx,1);

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
    y0_SIM = fout_SIM(x0_SIM, u0, varTMS_SIM);

    % save state and output data for simulation
    x_SYS(:,i) = x0_SIM;
    y_SYS(:,i) = y0_SIM;

    % convert plant states to controller states
    x0_MPC = fcon(x0_SIM, y0_SIM, varTMS_SIM, varTMS_MPC);

    % compute controller output
    y0_MPC = fout_MPC(x0_MPC, u0, varTMS_MPC);

    x_MPC(:,i) = x0_MPC;
    y_MPC(:,i) = y0_MPC;

    % sample the controller
    tic;
    [U0_MPC,J,f,o] = fmpc(x0_MPC,U0_MPC,d0_MPC,vTMS_MPC,vMPC_MPC,optionsMPC);
    u0 = U0_MPC(1:2);
    t_MPC(i)= toc;

    % cost high fidelity cost function
    [J_HF, ~] = get_J_EXP(x0_SIM,U0_MPC,d0_MPC,vTMS_SIM,vMPC_SIM);
    J_High_Fidelity(i) = J_HF;

    % save controller outputs
    u_SYS(:,i) = u0;
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
    [x0_SIM, Sx, Su] = fsim(tODE,x0_SIM,u0,d0_SYS,vTMS_SIM,optionsODE);

    disp(i)
end

%% Package Output
data.time = tSIM; % simulation time

% raw simulation results
data.u = u_SYS; % system controls

data.xs = x_SYS; % system states
data.ys = y_SYS; % system outputs
data.ds = d_SYS; % system disturbances

data.xc = x_MPC; % system states
data.yc = y_MPC; % system outputs

data.t = t_MPC; % optimization time
data.U = U_MPC; % predicted controls
data.D = D_MPC; % applied disturbances
data.j = J_MPC; % fmincon cost
data.o = o_MPC; % fmincon output

data.J_High_Fidelity = J_High_Fidelity;

save("Controllers_MASTER/Data/MPC_EXP.mat","data")

%% Remove Path
rmpath(genpath(pwd))

%% Plotting
figure(1)
plot(tSIM,t_MPC);
xlabel("Time (s)");
ylabel("Integration Execution Time (s)")

figure(2)
plot(tSIM,x_SYS(2,:)-273.15)
xlabel("Time (s)");
ylabel("Wall Temperature (deg C)")

figure(3)
plot(tSIM,mean(y_SYS(1:4,:),1))
xlabel("Time (s)");
ylabel("SOC")

figure(4)
plot(tSIM, u_SYS(1,:)+u_SYS(2,:))
hold on
plot(tSIM,u_SYS(2,:))
xlabel("Time (s)")
ylabel("Mass Flow Rate (kg/s)")
legend("Primary","TES")