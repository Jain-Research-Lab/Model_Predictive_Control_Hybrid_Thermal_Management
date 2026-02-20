% Function/script description and use
% This function implements MPC for the hybrid TMS system. EXP integration
% scheme is used.
% 
% Parameters :  x0         - initial condition state vector     
%               U0         - previous time step optimal control actions
%               d_MPC      - disturbance vector 
%               vTMS       - model parameter struct
%               vMPC       - controller parameter struct
%               optionsMPC - options struct for fmincon
% 
% Return     :  U0 - optimal control actions
% 
% Original Author(s): Uduak Inyang-Udoh (uinyangu@purdue.edu)
%
% Revision Author(s): Demetrius Gulewicz (dgulewic@purdue.edu)
% 
% Created: Spring 2023
% Last Modified: 09/10/24
% 
% Version: MATLAB R2023a
% Dependencies: varModel.m
%               varController.m
%               Hybrid_TMS_Model_EXP.m
%               Hybrid_TMS_Model_EXP0.m
%               compute_hex_properties.m
%               compute_weight_vector.m
%               compute_weight_vector_E.m
% 
% Notes:

function [U0,J,flag,output] = MPC_EXP(x0,U0,d_MPC,vTMS,vMPC,optionsMPC)
%% Constants
P = vMPC.Npx;
ns = vTMS.ns;
nx = vTMS.nx;
nu = vMPC.nu;
E = vTMS.E;
dJdy = zeros(1,ns);
Z2 = zeros(2*nx,1);

%% Cost Function Parameters
Ru = vMPC.Ru;
Ru_m = vMPC.Ru_m;

Rdu = vMPC.Rdu;
Rdu_m = vMPC.Rdu_m;
R_dJ_dU = vMPC.RdJ_du_m;

C = vMPC.C;

%% Initial Guess for Control Action, Use Hotstart with Constant Last U
u0 = U0(1:nu);
U0(1:end-nu) = U0(nu+1:end);

%% Update b vector to set first u constraint
A = vMPC.A;
b = vMPC.b;
b(P+1:P+nu) = b(P+1:P+nu) + u0;
b((nu+1)*P+1:(nu+1)*P+nu) = b((nu+1)*P+1:(nu+1)*P+nu) - u0;

%% Bounds
lb = vMPC.lb;
ub = vMPC.ub;

%% construct objective function
fun = @(u)obj_EXP(u,x0,d_MPC,Ru,Ru_m,Rdu,Rdu_m,R_dJ_dU,P,nx,nu,vMPC,C,vTMS,E,dJdy,Z2);

%% find the most optimal trajectory
[U0,J,flag,output] = fmincon(fun,U0,A,b,[],[],lb,ub,[],optionsMPC);

%% Cost Function Definition
    function [J,dJ] = obj_EXP(ubig,x0,d_MPC,Ru,Ru_m,Rdu,Rdu_m,RdJ_dU,P,nx,nu,vMPC,C,vTMS,E,dJdy,Z2)
        accu_m = vMPC.accumulation_matrix;
        accu_v = vMPC.accumulation_vector;

        alpha = vMPC.alpha;
        beta = vMPC.beta;
        epsilon = vMPC.epsilon;

        % compute cost associated with control action
        pJpu = Ru_m*ubig;
        pJpdu = Rdu_m*ubig;
        dJddu = RdJ_dU*ubig; 

        J = 0.5*((Ru*dot(pJpu,pJpu))+Rdu*dot(pJpdu,pJpdu));

        % Extract Control Actions for the current time step
        ui = ubig(1:vMPC.nu);

        % Extract Disturbances for the current time step
        di = d_MPC(:,1);

        % evolve system for dt seconds
        [x0,~,Di0,Su] = Hybrid_TMS_Model_EXP0(x0,ui,di,vTMS,E);
        
        % add new control action sensitivity column
        accu_m(:,1:nu) = Su;

        % extract outputs
        y0 = [0; x0(2) - 273.15; 0; 0; 0; Z2; x0(6+2*nx:end)-273.15];

        % compute gradient of outputs
        if y0(2) >= (vMPC.Tcp_ub - epsilon)
            J = J + 0.5*(beta(1)*y0(2)^2 + beta(2)*y0(2) + beta(3) + C*sum((y0(6+2*nx:end) - di(2) + 273.15).^2));
            dJdy(2) = beta(1)*y0(2) + 0.5*beta(2);
        else
            J = J + 0.5*((alpha(1)/(vMPC.Tcp_ub - y0(2))) + alpha(2) + C*sum((y0(6+2*nx:end) - di(2) + 273.15).^2));
            dJdy(2) = 0.5*alpha(1)/((vMPC.Tcp_ub - y0(2))^2);
        end
        dJdy(6+2*nx:end) = C*(y0(6+2*nx:end) - di(2) + 273.15);

        % accumulate gradient vector
        accu_v = accu_v + (dJdy*accu_m)';

        for i = 1:P
            % Extract Control Actions for the current time step
            ui = ubig((i-1)*vMPC.nu+1:i*vMPC.nu);

            % Extract Disturbances for the current time step
            di = d_MPC(:,i);

            % evolve system for dt seconds
            [x0,Sx,Di0,Su] = Hybrid_TMS_Model_EXP(x0,ui,di,vTMS,Di0,E);

            % add new control action sensitivity column
            accu_m(:,(i-1)*nu + 1:i*nu) = Su;

            % accumulate gradients
            accu_m(:,1:(i-1)*nu) = Sx*accu_m(:,1:(i-1)*nu);

            % extract outputs
            y0 = [0; x0(2) - 273.15; 0; 0; 0; Z2; x0(6+2*nx:end)-273.15];

            % compute gradient of outputs
            if y0(2) >= (vMPC.Tcp_ub - epsilon)
                J = J + 0.5*(beta(1)*y0(2)^2 + beta(2)*y0(2) + beta(3) + C*sum((y0(6+2*nx:end) - di(2) + 273.15).^2));
                dJdy(2) = beta(1)*y0(2) + 0.5*beta(2);
            else
                J = J + 0.5*((alpha(1)/(vMPC.Tcp_ub - y0(2))) + alpha(2) + C*sum((y0(6+2*nx:end) - di(2) + 273.15).^2));
                dJdy(2) = 0.5*alpha(1)/((vMPC.Tcp_ub - y0(2))^2);
            end
            dJdy(6+2*nx:end) = C*(y0(6+2*nx:end) - di(2) + 273.15);

            % accumulate gradient vector
            accu_v = accu_v + (dJdy*accu_m)';
        end

        dJ = accu_v + (Ru*kron(pJpu,[1;1])) + Rdu*dJddu;
    end   
end