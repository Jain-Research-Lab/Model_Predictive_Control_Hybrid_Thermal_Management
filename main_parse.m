function data = main_parse(date, data_folder, data, varTMS)
    %% Define Testing Data Parameters
    data.id.n_sets = length(data.id.first_valid_index);    % number of datasets
    data.id.last_valid_index = data.id.first_valid_index + data.id.ns; % Last index for each dataset
    
    %% Set Folder and File Names
    data_tc_template = join([data_folder,"sysMPCxx_" + date + "_TC.xlsx"],"/");
    data_an_template = join([data_folder,"sysMPCxx_" + date + "_AN.xlsx"],"/");
    data_in_template = join([data_folder,"sysMPCxx_" + date + "_IN.txt"],"/");
    data_sdre_template = join([data_folder,"sysMPCxx_" + date + "_SDRE.csv"],"/");
    data_con_template = join([data_folder,"sysMPCxx_" + date + "_CON.csv"],"/");
    data_d_template = join([data_folder,"sysMPCxx_" + date + "_d.mat"],"/");
    data_j_template = join([data_folder,"sysMPCxx_" + date + "_j.mat"],"/");
    data_t_template = join([data_folder,"sysMPCxx_" + date + "_t.mat"],"/");
    data_o_template = join([data_folder,"sysMPCxx_" + date + "_o.mat"],"/");
    
    addpath(genpath(data_folder))
    
    %% Process Data
    dataset_name = cell(data.id.n_sets,1);
    
    for i = 1:data.id.n_sets
        % set DAQ file paths
        data.tc_path = replace(data_tc_template,"xx",num2str(data.id.data_delimiter(i)));
        data.an_path = replace(data_an_template,"xx",num2str(data.id.data_delimiter(i)));
        data.in_path = replace(data_in_template,"xx",num2str(data.id.data_delimiter(i)));
        data.sdre_path = replace(data_sdre_template,"xx",num2str(data.id.data_delimiter(i)));
        data.con_path = replace(data_con_template,"xx",num2str(data.id.data_delimiter(i)));
    
        % set MPC file paths
        data.d_path = replace(data_d_template,"xx",num2str(data.id.data_delimiter(i)));
        data.j_path = replace(data_j_template,"xx",num2str(data.id.data_delimiter(i)));
        data.t_path = replace(data_t_template,"xx",num2str(data.id.data_delimiter(i)));
        data.o_path = replace(data_o_template,"xx",num2str(data.id.data_delimiter(i)));
    
        % define struct entry
        dataset_name{i} = join(['data',num2str(data.id.data_delimiter(i))]);
    
        data.(dataset_name{i}) = process_experimental_data(data,i,varTMS);
    end
end

function data_struct = process_experimental_data(data,i,varTMS)
    %% Import TC Data
    opts = spreadsheetImportOptions("NumVariables", 64);
    opts.Sheet = "data";
    opts.DataRange = "A:BL";
    opts.VariableNames = ["TC1", "TC2", "TC3", "TC4", "TC5", "TC6", "TC7", "TC8", "TC9", "TC10", "TC11", "TC12", "TC13CP", "TC14F0", "TC15M1A", "TC16M1B", "TC17M1C", "TC18M1D", "TC19M1E", "TC20F1", "TC21M2A", "TC22M2B", "TC23M2C", "TC24M2D", "TC25M2E", "TC26F2", "TC27M3A", "TC28M3B", "TC29M3C", "TC30M3D", "TC31M3E", "TC32F3", "TC112", "TC21", "TC31", "TC41", "TC51", "TC61", "TC71", "TC81", "TC91", "TC101", "TC111", "TC121", "TC13CP1", "TC14F01", "TC15M1A1", "TC16M1B1", "TC17M1C1", "TC18M1D1", "TC19M4A", "TC20M4B", "TC21M4C", "TC22M4D", "TC23M4E", "TC24F4", "TC25M2E1", "TC26F21", "TC27M3A1", "TC28M3B1", "TC29M3C1", "TC30M3D1", "TC312M3E1", "TC32F31"];
    opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
    SYSID102623TCS1 = readtable(data.tc_path, opts, "UseExcel", false);
    SYSID102623TCS1 = table2array(SYSID102623TCS1);
    clear opts
    
    %% Import Analog Data
    opts = spreadsheetImportOptions("NumVariables", 16);
    opts.Sheet = "data";
    opts.DataRange = "A:P";
    opts.VariableNames = ["Var1", "Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "FM2", "FM3", "FM4", "Var13", "Var14", "PSVoltage", "PSCurrent"];
    opts.SelectedVariableNames = ["FM2", "FM3", "FM4", "PSVoltage", "PSCurrent"];
    opts.VariableTypes = ["char", "char", "char", "char", "char", "char", "char", "char", "char", "double", "double", "double", "char", "char", "double", "double"];
    opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "Var13", "Var14"], "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "Var13", "Var14"], "EmptyFieldRule", "auto");
    SYSID102623ANALOGS1 = readtable(data.an_path, opts, "UseExcel", false);
    SYSID102623ANALOGS1 = table2array(SYSID102623ANALOGS1);
    clear opts
    
    %% Import Disturbance Data
    opts = delimitedTextImportOptions("NumVariables", 10);
    opts.DataLines = [2, Inf];
    opts.Delimiter = ",";
    opts.VariableNames = ["time", "Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9", "coldPlate"];
    opts.SelectedVariableNames = ["time", "coldPlate"];
    opts.VariableTypes = ["double", "string", "string", "string", "string", "string", "string", "string", "string", "double"];
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    opts = setvaropts(opts, ["Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9"], "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["Var2", "Var3", "Var4", "Var5", "Var6", "Var7", "Var8", "Var9"], "EmptyFieldRule", "auto");
    sysID102623 = readtable(data.in_path, opts);
    sysID102623 = table2array(sysID102623);
    clear opts

    %% Import SDRE Data
    opts = delimitedTextImportOptions("NumVariables", 103);
    opts.DataLines = [2, Inf];
    opts.Delimiter = ",";
    opts.VariableNames = ["Var1", "SOC_1", "SOC_2", "SOC_3", "SOC_4", "KF1CV01", "KF1CV02", "KF1CV03", "KF1CV04", "KF1CV05", "KF1CV06", "KF1CV07", "KF1CV08", "KF1CV09", "KF1CV10", "KF1CV11", "KF1CV12", "KF1CV13", "KF1CV14", "KF1CV15", "KF1CV16", "KF1CV17", "KF1CV18", "KF2CV01", "KF2CV02", "KF2CV03", "KF2CV04", "KF2CV05", "KF2CV06", "KF2CV07", "KF2CV08", "KF2CV09", "KF2CV10", "KF2CV11", "KF2CV12", "KF2CV13", "KF2CV14", "KF2CV15", "KF2CV16", "KF2CV17", "KF2CV18", "KF3CV01", "KF3CV02", "KF3CV03", "KF3CV04", "KF3CV05", "KF3CV06", "KF3CV07", "KF3CV08", "KF3CV09", "KF3CV10", "KF3CV11", "KF3CV12", "KF3CV13", "KF3CV14", "KF3CV15", "KF3CV16", "KF3CV17", "KF3CV18", "KF4CV01", "KF4CV02", "KF4CV03", "KF4CV04", "KF4CV05", "KF4CV06", "KF4CV07", "KF4CV08", "KF4CV09", "KF4CV10", "KF4CV11", "KF4CV12", "KF4CV13", "KF4CV14", "KF4CV15", "KF4CV16", "KF4CV17", "KF4CV18", "Var78", "Var79", "Var80", "Var81", "Var82", "Var83", "Var84", "Var85", "Var86", "Var87", "Var88", "Var89", "Var90", "Var91", "Var92", "Var93", "Var94", "Var95", "Var96", "Var97", "Var98", "Var99", "Var100", "Var101", "Var102", "Var103"];
    opts.SelectedVariableNames = ["SOC_1", "SOC_2", "SOC_3", "SOC_4", "KF1CV01", "KF1CV02", "KF1CV03", "KF1CV04", "KF1CV05", "KF1CV06", "KF1CV07", "KF1CV08", "KF1CV09", "KF1CV10", "KF1CV11", "KF1CV12", "KF1CV13", "KF1CV14", "KF1CV15", "KF1CV16", "KF1CV17", "KF1CV18", "KF2CV01", "KF2CV02", "KF2CV03", "KF2CV04", "KF2CV05", "KF2CV06", "KF2CV07", "KF2CV08", "KF2CV09", "KF2CV10", "KF2CV11", "KF2CV12", "KF2CV13", "KF2CV14", "KF2CV15", "KF2CV16", "KF2CV17", "KF2CV18", "KF3CV01", "KF3CV02", "KF3CV03", "KF3CV04", "KF3CV05", "KF3CV06", "KF3CV07", "KF3CV08", "KF3CV09", "KF3CV10", "KF3CV11", "KF3CV12", "KF3CV13", "KF3CV14", "KF3CV15", "KF3CV16", "KF3CV17", "KF3CV18", "KF4CV01", "KF4CV02", "KF4CV03", "KF4CV04", "KF4CV05", "KF4CV06", "KF4CV07", "KF4CV08", "KF4CV09", "KF4CV10", "KF4CV11", "KF4CV12", "KF4CV13", "KF4CV14", "KF4CV15", "KF4CV16", "KF4CV17", "KF4CV18"];
    opts.VariableTypes = ["string", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string"];
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    opts = setvaropts(opts, ["Var1", "Var78", "Var79", "Var80", "Var81", "Var82", "Var83", "Var84", "Var85", "Var86", "Var87", "Var88", "Var89", "Var90", "Var91", "Var92", "Var93", "Var94", "Var95", "Var96", "Var97", "Var98", "Var99", "Var100", "Var101", "Var102", "Var103"], "WhitespaceRule", "preserve");
    opts = setvaropts(opts, ["Var1", "Var78", "Var79", "Var80", "Var81", "Var82", "Var83", "Var84", "Var85", "Var86", "Var87", "Var88", "Var89", "Var90", "Var91", "Var92", "Var93", "Var94", "Var95", "Var96", "Var97", "Var98", "Var99", "Var100", "Var101", "Var102", "Var103"], "EmptyFieldRule", "auto");
    sysMPC50110323SDRE = readtable(data.sdre_path, opts);
    sysMPC50110323SDRE = table2array(sysMPC50110323SDRE);
    clear opts

    %% Import Control Action Data
    opts = delimitedTextImportOptions("NumVariables", 3);
    opts.DataLines = [1, Inf];
    opts.Delimiter = ",";
    opts.VariableNames = ["Var1", "VarName2", "VarName3"];
    opts.SelectedVariableNames = ["VarName2", "VarName3"];
    opts.VariableTypes = ["string", "double", "double"];
    opts.ExtraColumnsRule = "ignore";
    opts.EmptyLineRule = "read";
    opts = setvaropts(opts, "Var1", "WhitespaceRule", "preserve");
    opts = setvaropts(opts, "Var1", "EmptyFieldRule", "auto");
    sysMPC50110323CON = readtable(data.con_path, opts);
    sysMPC50110323CON = table2array(sysMPC50110323CON);
    clear opts

    %% Import MPC Data
    eval("load " + data.d_path);
    eval("load " + data.j_path);
    eval("load " + data.t_path);
    eval("load " + data.o_path);
    
    %% Parameters
    x = 3; % number of x control volumes per TES module

    %% Extract Individual Data Streams
    time = (0:data.id.ts:(data.id.ns*data.id.ts))';
    raw_data_TC = SYSID102623TCS1(data.id.first_valid_index(i):data.id.last_valid_index(i),:);
    raw_data_ANALOG = SYSID102623ANALOGS1(data.id.first_valid_index(i):data.id.last_valid_index(i),:);
    raw_data_INPUT = sysID102623(2:end,:);
    raw_data_SDRE = sysMPC50110323SDRE(data.id.first_valid_index(i)-1:data.id.last_valid_index(i)-1,:);
    raw_data_CON = sysMPC50110323CON(data.id.first_valid_index(i)-1:data.id.last_valid_index(i)-1,:);
    
    % control
    mp_raw = raw_data_ANALOG(:,2); % measured Primary Mass Flow Rate [kg/s]
    mtes_raw = raw_data_ANALOG(:,3); % measured Mass Flow Rate [kg/s]
    u = [mp_raw mtes_raw]; % measured mass flow rate [kg/s]
    
    % temperature
    Ttank_raw = raw_data_TC(:,9);  % Tank Outlet Temperature [deg C]
    Tcp_raw = raw_data_TC(:,13);   % Cold Plate Wall Temperature [deg C]
    Tcpw_raw = raw_data_TC(:,3);   % Cold Plate Fluid outlet Temperature [deg C]
    Thx_raw = 0.25*raw_data_TC(:,3) + 0.25*raw_data_TC(:,4) + 0.25*raw_data_TC(:,10) + 0.25*raw_data_TC(:,11); % HX Wall Temperature [deg C]
    Thxw_raw = raw_data_TC(:,4);   % HX Fluid outlet Temperature [deg C]
    TES1_raw = raw_data_SDRE(:,5:22); % all TES 1 estimated temperatures [deg C]
    TES2_raw = raw_data_SDRE(:,23:40); % all TES 2 estimated temperatures [deg C]
    TES3_raw = raw_data_SDRE(:,41:58); % all TES 3 estimated temperatures [deg C]
    TES4_raw = raw_data_SDRE(:,59:76); % all TES 4 estimated temperatures [deg C]
    TES_raw = rearrange_TES(TES1_raw, TES2_raw, TES3_raw, TES4_raw, x); % reordered TES temperatures
    x = [Ttank_raw Tcp_raw Tcpw_raw Thx_raw Thxw_raw TES_raw]; % measured temperatures
    
    % disturbance
    q_in_input = raw_data_ANALOG(:,4).*raw_data_ANALOG(:,5).*data.p.R_HEATER;
    Thxc_in_raw = raw_data_TC(:,10); % chiller HX inlet temperature [deg C]
    Thxc_out_raw = raw_data_TC(:,11); % chiller HX outlet temperature [deg C]
    tc_raw = 0.5*(Thxc_out_raw + Thxc_in_raw); % chiller mean temperature
    ms_raw = raw_data_ANALOG(:,1); % measured Chiller Mass Flow Rate [kg/s]
    d = [q_in_input tc_raw ms_raw];

    % output
    SOC1_raw = raw_data_SDRE(:,1); % SOC for module 1
    SOC2_raw = raw_data_SDRE(:,2); % SOC for module 2
    SOC3_raw = raw_data_SDRE(:,3); % SOC for module 3
    SOC4_raw = raw_data_SDRE(:,4); % SOC for module 4
    SOC_raw = [SOC1_raw SOC2_raw SOC3_raw SOC4_raw]; % SOC for all modules

    PTES = u(:,2).*varTMS.cp_water.*(raw_data_TC(:,14) - raw_data_TC(:,38));
    PHX = u(:,1).*varTMS.cp_water.*(x(:,3)-x(:,5));

    y = [SOC_raw PTES PHX];

    % target control
    mp_con_raw = raw_data_CON(:,2); % Target Primary Mass Flow Rate [kg/s]
    mtes_con_raw = raw_data_CON(:,1); % Target TES Mass Flow Rate [kg/s]
    uT = [mp_con_raw mtes_con_raw];

    % target disturbance
    dT = d_EXP;

    % mpc
    t = toc_EXP;
    j = J_EXP;
    o = output_EXP;

    %% Package Output
    data_struct.time = time; % experiment time

    % raw experimental results
    data_struct.x = x; % measured states
    data_struct.y = y; % measured outputs
    data_struct.u = u; % measured controls
    data_struct.d = d; % measured disturbances

    data_struct.uT = uT; % target controls
    data_struct.dT = dT; % target disturbances

    data_struct.t = t; % measured execution time
    data_struct.j = j; % fmincon cost
    data_struct.o = o; % fmincon output
end

function ordered_TES = rearrange_TES(scrambled_TES1, scrambled_TES2, scrambled_TES3, scrambled_TES4, x)
    [M,N] = size(scrambled_TES1);
    num_col = N/x;
    ordered_TES = [];

    for i = 1:num_col
       ordered_TES =  [ordered_TES scrambled_TES1(:,1+(i-1)*x:i*x) scrambled_TES2(:,1+(i-1)*x:i*x) scrambled_TES3(:,1+(i-1)*x:i*x) scrambled_TES4(:,1+(i-1)*x:i*x)];
    end
end