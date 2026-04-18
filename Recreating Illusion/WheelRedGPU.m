%Title: WheelRedGPU.m
%Date: 04/11/25
%Version: 1
%Author: Nathan Masters
%Notes: GPU access

%Title: Wheel_redesign.m
%Date: 04/11/25
%Version: 7
%Author: Nathan Masters
%Notes: Using rings instead of filled circles to see both patterns

clc; clear; close all

%% Check GPU availability
if gpuDeviceCount>0
 cGPU = 1;
else
 cGPU = 0;
end

%% Parameters
f = 2; %freq of main sq wave
f2 = 4; %freq of surrounding sq wave
Nstep = 8000; %no. frames per rotation
onespin = linspace(0,17*pi, Nstep); %No. of rotations in approx 4.6 secs
t = linspace(0, 2*pi, 600); %pixels around the circle (angular resolution)

if cGPU == 1
    onespin = gpuArray(onespin);
    t = gpuArray(t);
end

%% Ring params
r_inner_main = 2.5; % inner edge of main ring
r_outer_main = 3.5; % outer edge of main ring

r_inner_outer = 3.5; % inner edge of outer ring (starts outside main)
r_outer_outer = 3.55; % outer edge of outer ring
r_inner_inner = 2.45;
r_outer_inner = 2.5;

%% Background settings
bgColor = [0.3 0.3 0.3];
figColor = [0.2 0.2 0.2];
greyColor = [0.5 0.5 0.5];

%% Precompute
cos_t = cos(t);
sin_t = sin(t);

% Main ring 
main_width = r_outer_main - r_inner_main;
r1 = r_inner_main + main_width * (1 + square(f*t + onespin'))/2;
r2 = r_inner_main + main_width * (1 + square(f*t + pi + onespin'))/2;


% Outer ring 
outer_width = r_outer_outer - r_inner_outer;
Or1 = r_inner_outer + outer_width * (1 + square(f2*t + onespin' + pi))/2;
Or2 = r_inner_outer + outer_width * (1 + square(f2*t + 2*pi + onespin'))/2;


% Inner ring   
inner_width = r_outer_inner - r_inner_inner;
Ir1 = r_inner_inner + inner_width * (1 + square(f2*t + onespin'))/2;
Ir2 = r_inner_inner + inner_width * (1 + square(f2*t + pi + onespin'))/2;


% grey center
grey_radius = r_inner_inner;
x_grey = grey_radius * cos_t;
y_grey = grey_radius * sin_t;

%% Fig setup
figure('Color', figColor, 'Renderer', 'opengl');
ax = axes('Color', bgColor, 'XColor', 'none', 'YColor', 'none', ...
'Position', [0 0 1 1], 'DataAspectRatio', [1 1 1]);
hold on;

%% Circle setup - draw from outside to inside
% External rings
h3 = fill(Or1(1,:).*cos_t, Or1(1,:).*sin_t, 'k', 'EdgeColor', 'none');
h4 = fill(Or2(1,:).*cos_t, Or2(1,:).*sin_t, 'w', 'EdgeColor', 'none');


% Main rings
h1 = fill(r1(1,:).*cos_t, r1(1,:).*sin_t, 'k', 'EdgeColor', 'none');
h2 = fill(r2(1,:).*cos_t, r2(1,:).*sin_t, 'w', 'EdgeColor', 'none');

h5 = fill(Ir1(1,:).*cos_t, Ir1(1,:).*sin_t, 'k', 'EdgeColor', 'none');
h6 = fill(Ir2(1,:).*cos_t, Ir2(1,:).*sin_t, 'w', 'EdgeColor', 'none');
% Grey center
h_grey = fill(x_grey, y_grey, bgColor, 'EdgeColor', 'none');

axis equal;
xlim([-5.5 5.5]);
ylim([-5.5 5.5]);

%% Adjust speeds
fi = mod(2*(1:Nstep) - 1, Nstep) + 1;   
si = mod(floor((1:Nstep-1)/2), Nstep) + 1;      % half speed

%% Animation loop
tic
for i = 1:Nstep
    % Update external rings
    set(h3, 'XData', Or1(fi(i),:).*cos_t, 'YData', Or1(fi(i),:).*sin_t);
    set(h4, 'XData', Or2(fi(i),:).*cos_t, 'YData', Or2(fi(i),:).*sin_t);
    set(h5, 'XData', Ir1(fi(i),:).*cos_t, 'YData', Ir1(fi(i),:).*sin_t);
    set(h6, 'XData', Ir2(fi(i),:).*cos_t, 'YData', Ir2(fi(i),:).*sin_t);
     % Update main rings
    set(h1, 'XData', r1(i,:).*cos_t, 'YData', r1(i,:).*sin_t);
    set(h2, 'XData', r2(i,:).*cos_t, 'YData', r2(i,:).*sin_t);

    drawnow limitrate nocallbacks;
end
toc