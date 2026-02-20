%% Add path to all subfolders
addpath(genpath(pwd))

%% Load Simulation System Parameter Set
xrange = [0 500];

nx_SIM = 6;
ny_SIM = 8;
nms_SIM = 4;
nmp_SIM = 1;
[varTMS, vTMS]  = varModel(nx_SIM, ny_SIM, nms_SIM, nmp_SIM);   % define TMS variable class

%% Load MPC Parameter Set
[varNMPC, vMPC]   = varController(varTMS); % define Controller variable class

%% Setup
% Set Defaults
set(0,'defaultLineLineWidth', 2)
set(0,'defaultAxesFontName' , 'Times')
set(0,'defaultTextFontName' , 'Times')
set(0,'defaultAxesFontSize' , 16)
set(0,'defaultTextFontSize' , 16)
set(0,'defaultAxesGridLineStyle','-.')
set(groot, 'defaultLegendBox', 'off')

% Define Colors
CP_Color = "black";
TES_Color = "#006BB3";
HX_Color = "#32A42B";

sim_Color = "black";
exp_Color = "#006BB3";

%% Load Data
data_EXP = load('Controllers_MASTER/Data/MPC_EXP.mat').data;
data_EXP_Simple = load('Controllers_MASTER/Data/MPC_EXP_Simple.mat').data;

%% Figure 1: Simulation Flow and Temperature High Dimension
figure(1);
colororder({'#32A42B','black'})
xlim(xrange)

plot(data_EXP.time,sum(data_EXP.u,1),"Color",HX_Color,"LineStyle","-.")
hold on;
plot(data_EXP.time,data_EXP.u(2,:),"Color",TES_Color,"LineStyle","--")
hold on
patch([150 150 250 250], [0 0.12 0.12 0],"c",'FaceAlpha', 0.1, "EdgeColor","none")

xlabel("Time (s)");
ylabel("Mass Flow Rate (kg $\cdot$ s$^{-1}$)","Interpreter","latex")
ylim([0 0.12])

lgd1 = legend("Total Flow","TES Flow", "Location","southeast");
lgd1.Units = 'normalized'; % Use normalized units (0 to 1)
lgd1.Position = [0.72, 0.175, 0.05, 0.1]; % [left, bottom, width, height]

%% Figure 2: Simulation Flow and Temperature Low Dimension
figure(2);
colororder({'#32A42B','black'})
xlim(xrange)

plot(data_EXP_Simple.time,sum(data_EXP_Simple.u,1),"Color",HX_Color,"LineStyle","-.")
hold on;
plot(data_EXP_Simple.time,data_EXP_Simple.u(2,:),"Color",TES_Color,"LineStyle","--")
hold on
patch([150 150 250 250], [0 0.12 0.12 0],"c",'FaceAlpha', 0.1, "EdgeColor","none")

xlabel("Time (s)");
ylabel("Mass Flow Rate (kg $\cdot$ s$^{-1}$)","Interpreter","latex")
ylim([0 0.12])

%% Figure 3: Execution Time High and Low Dimension
figure(3)

plot(data_EXP.time,data_EXP.t,"Color",sim_Color,"LineStyle","-")
hold on
plot(data_EXP.time,data_EXP_Simple.t,"Color",exp_Color,"LineStyle","--")

xlim(xrange)

xlabel("Time (s)")
ylabel("Controller Execution Time (s)")
ylim([0 0.13])

legend("High Dimension", "Low Dimension", "location","best")

%% Figure 4: SOC
figure(4)

plot(data_EXP.time,mean(data_EXP.ys(1:4,:),1),"Color",sim_Color,"LineStyle","-")
hold on
plot(data_EXP_Simple.time,mean(data_EXP_Simple.ys(1,:),1),"Color",exp_Color,"LineStyle","--")
hold on
patch([150 150 250 250], [0 1.2 1.2 0],"c",'FaceAlpha', 0.1, "EdgeColor","none")

xlim(xrange)

xlabel("Time (s)")
ylabel("Average SOC")
ylim([0 1.2])

legend("High Dimension", "Low Dimension", "location","southeast")

%% Figure 5: Cost function #1
figure(5)

plot(data_EXP.time,data_EXP.J_High_Fidelity,"Color",sim_Color,"LineStyle","-")
hold on
plot(data_EXP_Simple.time,data_EXP_Simple.J_High_Fidelity,"Color",exp_Color,"LineStyle","--")
hold on
patch([25 25 60 60], [0 60 60 0],"c",'FaceAlpha', 0.1, "EdgeColor","none")
hold on
patch([290 290 375 375], [0 60 60 0],"c",'FaceAlpha', 0.1, "EdgeColor","none")

xlim(xrange)

xlabel("Time (s)")
ylabel("Objective Function Value")

lgd5 = legend("High Dimension", "Low Dimension", "location","best");
lgd5.Units = 'normalized'; % Use normalized units (0 to 1)
lgd5.Position = [0.30, 0.7, 0.2, 0.1]; % [left, bottom, width, height]

%% Figure 6: Cost function #2
figure(6)

plot(data_EXP.time,data_EXP.J_High_Fidelity,"Color",sim_Color,"LineStyle","-")
hold on
plot(data_EXP_Simple.time,data_EXP_Simple.J_High_Fidelity,"Color",exp_Color,"LineStyle","--")
hold on
patch([25 25 60 60], [0 0.6 0.6 0],"c",'FaceAlpha', 0.1, "EdgeColor","none")
hold on
patch([290 290 375 375], [0 0.6 0.6 0],"c",'FaceAlpha', 0.1, "EdgeColor","none")

xlim(xrange)
ylim([0 0.6])

xlabel("Time (s)")
ylabel("Objective Function Value")

lgd6 = legend("High Dimension", "Low Dimension", "location","southeast");
lgd6.Units = 'normalized'; % Use normalized units (0 to 1)
lgd6.Position = [0.30, 0.17, 0.2, 0.1]; % [left, bottom, width, height]

%% Figure 7: Cold plate temperature
figure(7)

plot(data_EXP.time, data_EXP.xs(2,:)-273.15,"Color",sim_Color,"LineStyle","-")
hold on
plot(data_EXP_Simple.time, data_EXP_Simple.xs(2,:)-273.15,"Color",exp_Color,"LineStyle","--")
hold on
patch([25 25 60 60], [0 50 50 0],"c",'FaceAlpha', 0.1, "EdgeColor","none")
hold on
patch([290 290 375 375], [0 50 50 0],"c",'FaceAlpha', 0.1, "EdgeColor","none")
hold on
line(xrange,[45 45],"Color","#b9b0b0")

xlim(xrange)
ylim([0 50])

xlabel("Time (s)")
ylabel(['Cold Plate Wall Temperature (', char(0176), 'C)'])

lgd7 = legend("High Dimension", "Low Dimension", "location","southeast");
lgd7.Units = 'normalized'; % Use normalized units (0 to 1)
lgd7.Position = [0.30, 0.17, 0.2, 0.1]; % [left, bottom, width, height]

%% Save as PDFs
pdf_folder = "Figures/pdf/";

pdf_list = ["high_dash", "Low_dash", "timing_final", "SOC", "J", "J_zoomed", "cold_plate"];

n = length(pdf_list);

for i = 1:n
    exportgraphics(figure(i),pdf_folder+pdf_list(i)+'.pdf');
end

%% Save as SVGs
svg_folder = "Figures/svg/";

svg_list = ["high_dash", "Low_dash", "timing_final", "SOC", "J", "J_zoomed", "cold_plate"];

for i = 1:n
    print(figure(i), svg_folder + svg_list(i) + '.svg','-dsvg');
end