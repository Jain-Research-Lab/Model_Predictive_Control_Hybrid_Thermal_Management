Gulewicz_Inyang-Udoh_Bird_Jain_IEEE_TCST_2024 READ ME
Demetrius Gulewicz 05/06/26
__________________________________________

This folder is divided into four parts:

1. Experiment_Simulation_Data
2. Figures
3. MPC_Code
4. Latex_Source_Code
To generate all figures used in this paper, you can simply run main.m. 
You should run this file while in the folder: "IEEE_TCST_2024". 
If you are in a different folder, the code might not work.
__________________________________________

The function Experiment_Simulation_Data/main_parse.m takes an experimentally collected dataset, and converts into an organized struct.

There are two experimental datasets:
1. hybrid: The hybrid dataset is the data collected when running the MPC with the TES.
2. nonhybrid: The nonhybrid dataset is the data collected when running the MPC without the TES.
__________________________________________

The function MPC_Code/main_EXP.m simulates the hybrid system with the same initial conditions as the experiment.

The folder "MPC_Code" is largely a minimal example of running a NMPC, except for 4 files:
1. ServerAsControllerEXP.vi: this is the VI I ran in the windows computer to execute the controller.
2. main_EXP_LABview.m: this is the file I run to initialize the MPC when the vi first starts running.
3. MPC_EXP_LABview.m: this is the MPC function, execution time measures how long this function takes to execute.
4. outputs.m: this function computes the state of charge given the TES temperatures, and it is not used in the MPC.
__________________________________________

The function Experiment_Simulation_Data/main_plot.m generates .svg and .pdf of the 9 figures presented in the paper.
A figure checklist and colorbank are included.

All relevent latex code is found in the folder 'LaTeX_Source_Code'.
This includes each section in the manuscript, but also the bibliograpy and template files.

All figures used in the manuscript can be found in the folder named Figures.
All figures are pdfs. svg varients can be found in Experiment_Simulation_data/svgs
