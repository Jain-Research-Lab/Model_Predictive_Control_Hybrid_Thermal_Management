%% Get High Dimension MPC Simulation Results
C_main_EXP_MPC;
close all

%% Get Low Dimension MPC Simulation Results
C_main_EXP_MPC_Simple;
close all

%% Plot Results
P_main_EXP_MPC;

%% Remove Path
rmpath(genpath(pwd))