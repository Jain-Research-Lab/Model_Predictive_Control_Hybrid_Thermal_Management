%% Add paths
addpath(genpath(pwd));

%% Load Plant/Prediction System Parameter Set
nx_MPC = 3;
ny_MPC = 4;
nms_MPC = 4;
nmp_MPC = 1;
[varTMS, vTMS]  = varModel(nx_MPC, ny_MPC, nms_MPC, nmp_MPC);   % define TMS variable class

%% Parse Experiment Data
date = "05_20_24";
data_folder = "data/hybrid_experiment_05_20_24_EXP";
data.id.ts = 0.1;                      % DAQ sample time, [s]
data.id.dt_input = 10;                 % Amount of time each input is applied [s]
data.p.R_HEATER = 60;                  % [Ohm]

data.id.first_valid_index = [49];       % First Index for each dataset
data.id.ns = [5000];                    % number of samples for each data set
data.id.data_delimiter = [50];         % unique id for each dataset

sysMPC_Hybrid = main_parse(date, data_folder, data, varTMS);
save("results/nums/sysMPC_Hybrid.mat","sysMPC_Hybrid");

date = "05_23_24";
data_folder = "data/nonhybrid_experiment_05_23_24_EXP";
data.id.ts = 0.1;                      % DAQ sample time, [s]
data.id.dt_input = 10;                 % Amount of time each input is applied [s]
data.p.R_HEATER = 60;                  % [Ohm]

data.id.first_valid_index = [49];      % First Index for each dataset
data.id.ns = [5000];                   % number of samples for each data set
data.id.data_delimiter = [50];         % unique id for each dataset

sysMPC_NonHybrid = main_parse(date, data_folder, data, varTMS);
save("results/nums/sysMPC_NonHybrid.mat","sysMPC_NonHybrid");

%% Run Simulation
data_EXP = main_EXP(varTMS, vTMS);
save("results/nums/data_EXP.mat","data_EXP")

%% Get Figures
main_plot;

%% Remove Path
rmpath(genpath(pwd))