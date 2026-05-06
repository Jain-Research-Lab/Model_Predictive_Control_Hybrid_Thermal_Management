%% Plot Checklist
% 01. Each dataset has a distinct color, but not a light color like yellow
% 02. Each curve dataset has a distinct line style
% 03. Each scatter dataset has a distinct marker
% 04. The x,y,z axis are labeled using latex format where appropriate
% 05. The font size is large enough to read (at least 14pt if possible)
% 06. Legend is present, descriptive, and in the optimal location
% 07. Figure is saved as a PDF with 300 dpi using save_pdf function
% 08. Patch function is used to distinguish distinct regions of a figure
% 09. Data used to generate a set of plots is saved in a .mat file
% 10. Default plot settings are defined before making any figures
% 11. xlim,ylim,zlim used to set axis scale
% 12. The size of each figure is set appropirately using fig.position
% 13. Figures clearly show which curve is larger in magnitude
% 14. Use solid lines for simulation results, and dotted for experimental
% 15. No boxes around legends
% 16. Do not have the units italisized
% 17. save source (.svg) and pdf versions of each figure
% 
%% Color Bank
% Dark Colors             |  Light Colors   |  Super Light Colors
% Grey           #2C2C2C  |  #808080        |
% Old Gold:      #CEB888  |                 |
% Orange:        #EA640B  |  #FBC891        |  #FEEED4
% Red:           #D7031C  |  #EF9978        |  #FBD4C2
% Pink:          #E2006C  |  #F3A4BF        |  #FADBE9
% Purple-Pink:   #A90C5D  |  #DF99B5        |  #F5D6E4
% Purple:        #7F378B  |  #C1A3C9        |  #E5D6E9
% Blue-Purple:   #503A8D  |  #AD9CC8        |  #D5D1E8
% Blue:          #006BB3  |  #8AB1DA        |  #CEDFF1
% Marine Blue:   #14ACDE  |  #ACDAF2        |  #CCEAF8
% Marine Green:  #06A199  |  #A9D8D2        |  #DDEFEF
% Green:         #32A42B  |  #B5D498        |  #E1EED3
% Lime Green:    #B4CB01  |  #E1E699        |  #F5F6D6
% Yellow:        #FFE401  |  #FEF6A3        |  #FFFBD8
%
%% Setup
% Set Defaults
set(0,'defaultLineLineWidth', 2)
set(0,'defaultAxesFontName' , 'Times')
set(0,'defaultTextFontName' , 'Times')
set(0,'defaultAxesFontSize' , 16)
set(0,'defaultTextFontSize' , 16)
set(0,'defaultAxesGridLineStyle','-.')
set(groot, 'defaultLegendBox', 'off')

% Load Simulated Data
load data_EXP.mat

% Load Experimental Data
load sysMPC_Hybrid.mat
load sysMPC_NonHybrid.mat

% Define Colors
CP_Color = "black";
TES_Color = "#006BB3";
HX_Color = "#32A42B";

sim_Color = "black";
exp_Color = "#006BB3";

% set time range
N = length(data_EXP.time);
xrange = [0 450];

% get data
time_MPC = data_EXP.time;
time_MAIN = sysMPC_Hybrid.data50.time;

mp_sim_exp = data_EXP.u(:,1) + data_EXP.u(:,2);

mp_exp = sysMPC_Hybrid.data50.u(:,1);
mp_exp_small = sysMPC_NonHybrid.data50.u(:,1);

mtes_sim_exp = data_EXP.u(:,2);
mtes_exp = sysMPC_Hybrid.data50.u(:,2);

tcp_sim_exp = data_EXP.x(:,2) - 273.15;
tcp_exp = sysMPC_Hybrid.data50.x(:,2);
tcp_exp_small = sysMPC_NonHybrid.data50.x(:,2);

Qcp_sim_exp = data_EXP.d(1,1:N);
Qcp_exp = sysMPC_Hybrid.data50.d(:,1);
Qcp_expT = sysMPC_Hybrid.data50.dT(:,1);
QTES_exp = sysMPC_Hybrid.data50.y(:,5);
QHX_exp = sysMPC_Hybrid.data50.y(:,6);

t_sim = data_EXP.t;
t_exp = sysMPC_Hybrid.data50.t;

soc_exp = mean(sysMPC_Hybrid.data50.y(:,1:4),2);

%% Figure 1: Heat Load
figure(1)

plot(time_MPC,Qcp_sim_exp,"Color","black","LineStyle","-")

xlim(xrange)
xlabel("Time (s)")
ylabel("Heat Input (W)")
ylim([0 6000])

%% Figure 2: Simulation Flow and Temperature
figure(2);
colororder({'#32A42B','black'})
xlim(xrange)

yyaxis left
plot(time_MPC,mp_sim_exp,"Color",HX_Color,"LineStyle","-.")
hold on;
plot(time_MPC,mtes_sim_exp,"Color",TES_Color,"LineStyle","--")
xlabel("Time (s)");
ylabel("Mass Flow Rate (kg $\cdot$ s$^{-1}$)","Interpreter","latex")
ylim([0 0.12])

yyaxis right
plot(time_MPC,tcp_sim_exp,"Color",CP_Color,"LineStyle",":")
hold on
line(xrange,[45 45],"Color","#b9b0b0")

ylabel(['Cold Plate Wall Temperature (', char(0176), 'C)'])
ylim([0 50])

lgd = legend("Total Flow","TES Flow","CP Temp","Location","southeast");
lgd.Units = 'normalized'; % Use normalized units (0 to 1)
lgd.Position = [0.675, 0.175, 0.2, 0.1]; % [left, bottom, width, height]

%% Figure 3: Execution Time
figure(3)

plot(time_MPC,t_sim,"Color",sim_Color,"LineStyle","-")
hold on
plot(time_MPC,t_exp,"Color",exp_Color,"LineStyle","--")

xlim(xrange)

xlabel("Time (s)")
ylabel("Controller Execution Time (s)")
ylim([0 0.5])

legend("Simulation", "Experiment", "location","best")

%% Figure 4: Experimental Flow and Temperature
figure(4);
colororder({'#32A42B','black'})
xlim(xrange)

yyaxis left
plot(time_MAIN,mp_exp,"Color",HX_Color,"LineStyle","-.")
hold on;
plot(time_MAIN,mtes_exp,"Color",TES_Color,"LineStyle","--")
xlabel("Time (s)");
ylabel("Mass Flow Rate (kg $\cdot$ s$^{-1}$)","Interpreter","latex")
ylim([0 0.12])

yyaxis right
plot(time_MAIN,tcp_exp,"Color",CP_Color,"LineStyle",":")
hold on
line(xrange,[45 45],"Color","#b9b0b0")
ylabel(['Cold Plate Wall Temperature (', char(0176), 'C)'])
ylim([0 50])

lgd = legend("Total Flow","TES Flow","CP Temp","Location","southeast");
lgd.Units = 'normalized'; % Use normalized units (0 to 1)
lgd.Position = [0.675, 0.175, 0.2, 0.1]; % [left, bottom, width, height]

%% Figure 5: Heat Rates
figure(5)

plot(time_MAIN,Qcp_exp, "Color",CP_Color,"LineStyle","-")
hold on
plot(time_MAIN,QTES_exp,"Color",TES_Color,"LineStyle","--")
hold on
plot(time_MAIN,QHX_exp,"Color",HX_Color,"LineStyle",":")

xlim(xrange)

xlabel("Time (s)")
ylabel("Heat Transfer Rate (W)")
ylim([-500 6000])

legend("CP", "TES", "HX")

%% Figure 6: TES Contribution
figure (6)

plot(time_MAIN, max(min(QTES_exp ./ QHX_exp,0.5),-0.5),"Color","black","LineStyle","--")
grid minor

xlim(xrange)

xlabel("Time (s)")
ylabel("TES Contribution $\frac{\dot{Q}_{TES}}{\dot{Q}_{HX}}$","Interpreter","latex")
xlim([0,450])
ylim([-0.5 0.5])

%% Figure 7: CP Temperature With and Without TES
figure(7)

plot(time_MAIN,tcp_exp_small, "Color",sim_Color,"LineStyle","-.")
hold on
plot(time_MAIN,tcp_exp, "Color",TES_Color,"LineStyle","--")
hold on
line(xrange,[45 45],"Color","#b9b0b0")

xlim(xrange)

xlabel("Time (s)")
ylabel(['Cold Plate Temperature (', char(0176), 'C)'])
legend("No TES","TES", "Location","best")

%% Figure 8: Primary flow with and without TES
figure(8)

plot(time_MAIN, mp_exp_small,"Color",sim_Color,"LineStyle","-.")
hold on
plot(time_MAIN, mp_exp,"Color",TES_Color,"LineStyle","--")

xlim(xrange)

xlabel("Time (s)")
ylabel("Primary Mass Flow Rate (kg $\cdot$ s$^{-1}$)","Interpreter","latex")
legend("No TES", "TES", "location", "best")

%% Figure 9: SOC
figure(9)

plot(time_MAIN,soc_exp,"Color","black","LineStyle","--")

xlim(xrange)

xlabel("Time (s)")
ylabel("Average SOC")
ylim([0 1.2])

%% Save as SVGs
svg_folder = "results/svgs/";

svg_list = ["heat_load_plain", "sim_dash", "timing", "exp_dash", "qdot_exp", ...
    "tes_contribution", "tcp_tes_vs_small","mp_tes_vs_small", "est_soc"];

n = length(svg_list);

for i = 1:n
    print(figure(i), svg_folder + svg_list(i) + '.svg','-dsvg');
end

%% Save as PDFs
pdf_folder = "results/Figures/";

pdf_list = ["heat_load_plain", "sim_dash", "timing", "exp_dash", "qdot_exp", ...
    "tes_contribution", "tcp_tes_vs_small", "mp_tes_vs_small", "est_soc"];

for i = 1:n
    exportgraphics(figure(i),pdf_folder+pdf_list(i)+'.pdf');
end