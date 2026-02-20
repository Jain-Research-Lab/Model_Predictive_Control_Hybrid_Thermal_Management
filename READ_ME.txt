Gulewicz_Inyang-Udoh_Bird_Jain_IEEE_TCST_2024 READ ME
Demetrius Gulewicz 12/10/25
__________________________________________

This branch consists of a case study comparing a high dimension thermal
energy storage (TES) prediction model with a low dimension TES prediction
model. These prediction models are compared by seeing what the closed loop
performance is if the MPC is sythesized with each of these prediction models.

As is shown, the low dimesion model yields a faster MPC solution, but the 
solution is suboptimal and in fact there are instances in which the state
trajectories diverge from one another.

Note: each step takes longer because of the simulation model, not because
the controller takes so long. The simulation model being used is 
discretized to 4x the model used in the controller. So the controller still
has 77 states, but the simulation model has 245 states. The higher discretization
makes the simulation align much closer to what would happen in an actual experiment.
__________________________________________
This folder is divided into three parts: 

1. Controllers_MASTER
2. Figures
3. Models_MASTER

The Controllers_MASTER contains the files for each MPC.
The Figures folder contains pdf and svg versions of each figure
The Models_MASTER contains the files for each prediction model

To re-generate all data and figures for this case study, simply run main.m
To re-generate the high dimension MPC data, run C_main_EXP_MPC.m
To re-generate the low dimension MPC data, run C_main_EXP_MPC_Simple.m
To re-generate the plots, run P_main_EXP_MPC.m
__________________________________________