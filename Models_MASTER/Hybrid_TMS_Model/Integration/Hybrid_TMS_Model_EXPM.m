%% Function Description
% This is a discretization function that directly solves for x(t0+dt) given
% states, control actions, and disturbances at t=t0.
% 
% Input      :  x - current states
%               u - current control actions
%               d - current disturbances
%               vTMS - struct of all required Hybrid TMS Variables
%               E - the gradient matrix dU/dx
% 
% Return     :  xn - states after dt interval
%               phi - temperature gradient matrix dxn/dx
%               dXdU - the gradient vector dxn/du

%% References
% This system takes the form of x_dot(t) = Ax(t)+B, where:
% x_dot: state derivatives n by 1
% x    : all the states, n by 1
% A    : State matrix, n by n
% B    : constant disturbance matrix n by 1
%
% Note: n is by definition the number of states
%
% This system may be solved by using a matrix exponential. In general, the
% system Ax+B may be solved for a future state x by taking the matrix
% exponential of modified state matrix, namely:
%                                 |  A  B  |
%                                 |  0  0  |
%
% This matrix is nothing but a matrix concatenation of the A and B
% matricies so that the resulting matrix is a square matrix n+m by n+m.
% Details of matrix exponentials may be found online at MIT:
% https://ocw.mit.edu/courses/18-03sc-differential-equations-fall-2011/pages/unit-iv-first-order-systems/matrix-exponentials/
%
% Also, additional clarification may be found at:
% https://math.stackexchange.com/questions/658276/integral-of-matrix-exponential#:~:text=The%20general%20formula%20is%20the%20power%20series%20%E2%88%ABT,I%20%3D%20e%20A%20T%20is%20always%20satisfied.
%
% Note: the answer by Gabriel Gleizer is especially elucidating from the
% link above!
%
% Even more supplementary content can be found at Utah:
% https://www.math.utah.edu/~gustafso/2250matrixexponential.pdf#:~:text=Announced%20here%20and%20proved%20below%20are%20various%20formulae,%3D%20I%20Where%200%20is%20the%20zero%20matrix.
%
% In addition, this function makes use of graph theory to compute the state
% matrix. Matlab has some good documentation of how graph theory works. Some
% details can be found at the following links:
% https://www.mathworks.com/help/matlab/math/directed-and-undirected-graphs.html
% https://www.mathworks.com/help/matlab/ref/digraph.html
% https://www.mathworks.com/help/matlab/ref/graph.html
%
% The formulation used here to compute A, -I*(K.*It) is basically the
% weighted laplacian of the Hybrid TMS. The weighted Laplacian is nothing
% but the state matrix, if one is careful to define I and It properly.
%
% A  - State matrix, as conventionally defined [W/K]
% I  - System Directed Incidense Matrix [unitless]
% It - Transpose of System Undirected Incidense Matrix [unitless]
% K  - Weight Vector, weights of all graph edges [W/K]
% M  - Mass (capacitance) vector [J/K]
%
% For more information on the Laplacian, see this answer:
% https://www.quora.com/Whats-the-intuition-behind-a-Laplacian-matrix-Im-not-so-much-interested-in-mathematical-details-or-technical-applications-Im-trying-to-grasp-what-a-laplacian-matrix-actually-represents-and-what-aspects-of-a-graph-it-makes-accessible/answer/Muni-Sreenivas-Pydi

%% General Function Information
% Original Author(s):  Darin Lin
%                      Henry Lewis
%                      Austin Nash
%                      Michael Shanks (shanks5@purdue.edu)
%
% Revision Author(s):  Demetrius Gulewicz (dgulewic@purdue.edu)
%
% Created: Summer 2021
% Last Modified: 09/10/24
%
% Version: MATLAB R2023a
% Dependencies: compute_hex_properties.m
%               compute_weight_vector.m
%               varModel.m

function [xn,phi,dXdU] = Hybrid_TMS_Model_EXPM(x,u,d,vTMS,E)
%% State Space Matrix
[Mi, A, d] = Hybrid_TMS_Model_SS(x,u,d,vTMS);
At = (vTMS.dt.*Mi).*[A d; vTMS.Z];

%% High Precision Maxtrix Exponential
eAB = expm(At);

%% Compute Solution
ns = vTMS.ns;
phi = eAB(1:ns,1:ns);
xn = phi*x + eAB(1:ns,end);

%% inaccurate Frechet Derivative
dXdU = vTMS.dt.*(phi*(E*kron([1 0; 0 1],x)));

end