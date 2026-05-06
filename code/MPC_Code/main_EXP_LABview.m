%% Load Prediction Model Parameter Set
nx_MPC = 3;
ny_MPC = 4;
nms_MPC = 4;
nmp_MPC = 1;
[varTMS, vTMS]  = varModel(nx_MPC, ny_MPC, nms_MPC, nmp_MPC);   % define TMS variable class

%% Load MPC Parameter Set
[varNMPC, vEXP]   = varController(varTMS); % define Controller variable class

%% Simulation Timing 
dt_SIM   = varTMS.dt;	  % unit discrete-time interval (s)

%% Initial Conditions
x0 = varTMS.T0_ALL;     % Initial Conditions for States
U0 = varNMPC.U0;     % Initial Conditions for Control Actions

%% Boundary Conditions
Q_HF = vTMS.Q_HF;  % Power Input from high frequency heater [W]
T_CF = vTMS.T_CF;  % Chiller Inlet Temperature [K]
m_CF = varTMS.m_CF; % Chiller mass flow rate [kg/s]

%% MPC Horizon
Npx = varNMPC.Npx;     % Number of states to use for evaluate cost function

%% Initialize Tracking Variables
nSIM = varTMS.nSIM;           % length of time, all time steps [count]
d_EXP   = zeros(nSIM,varNMPC.nd);     % All disturbances applied to system
toc_EXP = zeros(nSIM,1);  % All timing for MPC function execution
output_EXP.iteration       = zeros(nSIM,1);
output_EXP.funcCount       = zeros(nSIM,1);
output_EXP.lssteplength    = zeros(nSIM,1);
output_EXP.constrviolation = zeros(nSIM,1);
output_EXP.stepsize        = zeros(nSIM,1);
output_EXP.firstorderopt   = zeros(nSIM,1);
output_EXP.flag            = zeros(nSIM,1);
J_EXP                      = zeros(nSIM,1);

%% Configure Optimizer
TypicalX = repmat([0.05;0.05],25,1);

optionsMPC = optimoptions('fmincon','Algorithm','sqp','Display','none', ...
	'SpecifyObjectiveGradient',true,'CheckGradients',false, ...
	'ConstraintTolerance',2e-3,'OptimalityTolerance',5e-3, ...
    'StepTolerance',1e-3,'UseParallel',false, ...
    'TypicalX',TypicalX,'ScaleProblem',true);