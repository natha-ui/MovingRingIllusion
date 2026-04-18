%%

N = 300;  % image size
spacing = 10;

totalWidth = N/2;
totalHeight = N;

[x, y] = meshgrid(linspace(-1,1,N));
[theta_orig, r] = cart2pol(x, y);
theta_orig = mod(theta_orig, 2*pi); % normalize angle

numSegments = 4;          % number of segments per ring
numSegmentsDir = 8;
segmentWidth = 2*pi / numSegments;
segmentWidthDir = 2*pi / numSegmentsDir;

% Rings' radii
r_inner = 0.4;            % main ring inner radius
r_outer = 0.6;            % main ring outer radius
ring_width = r_outer - r_inner;

thinWidth = 0.03 * ring_width; %CHANGE LATER
thinnerWidth = 0.015 * ring_width;  % thickness of inner/outer rings
% Define rings masks
mainRingMask = (r >= r_inner) & (r <= r_outer);
innerRingInner = r_inner - thinWidth;
innerRingInnerS = r_inner - thinnerWidth;
innerRingOuter = r_inner;
innerRingMask = (r >= innerRingInner) & (r < innerRingOuter);
outerRingInner = r_outer;
outerRingOuter = r_outer + thinWidth;
outerRingMask = (r >= outerRingInner) & (r < outerRingOuter);

%updated for 3D - required for inserting arrow
% Base grayscale values for segments
%grayVals = [0.3 0.7 0.3 0.7 0.3 0.7 0.3 0.7]; % alternating dark/light
%grayValsInverted = 1-grayVals;  % inverted for inner ring
colours = [
    0, 0, 0;
    1, 1, 1;
    0, 0, 0;
    1, 1, 1
    ];
coloursInv = 1 - colours;

length = 60;
framerefresh = 0.1; % number of animation frames 

%% in and out
for frame = 1:length
    % Phase shift for clockwise rotation (subtract increasing angle)
    phaseShift = -2*pi * (frame-1) * framerefresh; % one full rotation over numFrames
    
    % Shifted theta for each ring
    thetaMain = mod(theta_orig + phaseShift, 2*pi);
    thetaInner = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % inner ring rotated half segment more
    thetaOuter = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % outer ring same as inner
    
    % Initialize image
    canvas = ones(totalHeight,totalWidth)*0.5;
    I1 = ones(N,N,3) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = colours(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexInner == k) & innerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = coloursInv(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = colours(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N,3)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = colours(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = colours(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = coloursInv(k+1,d);
            I2(:,:,d) = dim;
        end
    end
    
    
    canvas = ones(N, 2*N, 3) *0.5;
    I1arr = genarrowsize(I1, 'out');
    I2arr = genarrowsize(I2, 'in');
    canvas(:,1:N,:) = I1;
    canvas(:,1:N,:) = I1arr;
    canvas(:, N+1 : 2*N, :) = I2;
    canvas(:, N+1 : 2*N, :) = I2arr;

    imshow(imgaussfilt(canvas,0.5), []);
    drawnow;
    pause(0.01); %60fps?
end

for frame = 1:length
    % Phase shift for clockwise rotation (subtract increasing angle)
    phaseShift = -2*pi * (frame-1) * framerefresh; % one full rotation over numFrames
    
    % Shifted theta for each ring
    thetaMain = mod(theta_orig + phaseShift, 2*pi);
    thetaInner = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % inner ring rotated half segment more
    thetaOuter = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % outer ring same as inner
    
    % Initialize image
    canvas = ones(totalHeight,totalWidth)*0.5;
    I1 = ones(N,N,3) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = colours(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexInner == k) & innerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = colours(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = coloursInv(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N,3)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = colours(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = coloursInv(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = colours(k+1,d);
            I2(:,:,d) = dim;
        end
    end
    
    canvas = ones(N, 2*N, 3) *0.5;
    I1arr = genarrowsize(I1, 'in');
    I2arr = genarrowsize(I2, 'out');
    canvas(:,1:N,:) = I1;
    canvas(:,1:N,:) = I1arr;
    canvas(:, N+1 : 2*N, :) = I2;
    canvas(:, N+1 : 2*N, :) = I2arr;
    
    imshow(imgaussfilt(canvas,0.5), []); %smoothed a bit
    drawnow;
    pause(0.01)
end

%% Directional - Left Right
%adjust gray vals - direction going to = double light outer, double dark
%inner
%I think it needs arrows?

%0.7 0.7 0.3 0.7 0.3 0.3 0.7 0.3
coloursdir = [
    0, 0, 0; 
    0, 0, 0; 
    1, 1, 1;
    1, 1, 1;
    0, 0, 0;
    1, 1, 1;
    0, 0, 0;
    0, 0, 0
    ];

coloursInvdir = 1-coloursdir;  % inverted for inner ring


for frame = 1:length
    % Phase shift for clockwise rotation (subtract increasing angle)
    phaseShift = -2*pi * (frame-1) * framerefresh; % one full rotation over numFrames
    
    % Shifted theta for each ring
    thetaMain = mod(theta_orig + phaseShift, 2*pi);
    thetaInner = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % inner ring rotated half segment more
    thetaOuter = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % outer ring same as inner
    
    % Initialize image
    I1 = ones(N,N,3) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = colours(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner == k) & innerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = coloursInvdir(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = coloursdir(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N,3)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = colours(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = coloursdir(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = coloursInvdir(k+1,d);
            I2(:,:,d) = dim;
        end
    end
    
    
    canvas = ones(N, 2*N, 3) *0.5;
    I1arr = genarrowdir(I1, 'left');
    I2arr = genarrowdir(I2, 'right');
    canvas(:,1:N,:) = I1;
    canvas(:,1:N,:) = I1arr;
    canvas(:, N+1 : 2*N, :) = I2;
    canvas(:, N+1 : 2*N, :) = I2arr;
    
    imshow(canvas, []);
    drawnow;
end

for frame = 1:length
    % Phase shift for clockwise rotation (subtract increasing angle)
    phaseShift = -2*pi * (frame-1) * framerefresh; % one full rotation over numFrames
    
    % Shifted theta for each ring
    thetaMain = mod(theta_orig + phaseShift, 2*pi);
    thetaInner = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % inner ring rotated half segment more
    thetaOuter = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % outer ring same as inner
    
    % Initialize image
    canvas = ones(totalHeight,totalWidth)*0.5;
    I1 = ones(N,N,3) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = colours(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner == k) & innerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = coloursdir(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = coloursInvdir(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N,3)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = colours(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = coloursInvdir(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = coloursdir(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    canvas = ones(N, 2*N, 3) *0.5;
    I1arr = genarrowdir(I1, 'right');
    I2arr = genarrowdir(I2, 'left');
    canvas(:,1:N,:) = I1;
    canvas(:,1:N,:) = I1arr;
    canvas(:, N+1 : 2*N, :) = I2;
    canvas(:, N+1 : 2*N, :) = I2arr;

    imshow(canvas, []);
    drawnow;
end

%% Directional - Up Down
%adjust gray vals - direction going to = half dark, half light
%grayValsdir = [0.7 0.7 0.7 0.7 0.3 0.3 0.3 0.3];

coloursUDdir = [
    0, 0, 0;
    0, 0, 0;
    0, 0, 0;
    0, 0, 0;
    1, 1, 1;
    1, 1, 1;
    1, 1, 1;
    1, 1, 1
    ];
coloursUDInvdir = 1-coloursUDdir;  % inverted for inner ring


for frame = 1:length
    % Phase shift for clockwise rotation (subtract increasing angle)
    phaseShift = -2*pi * (frame-1) * framerefresh; % one full rotation over numFrames
    
    % Shifted theta for each ring
    thetaMain = mod(theta_orig + phaseShift, 2*pi);
    thetaInner = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % inner ring rotated half segment more
    thetaOuter = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % outer ring same as inner
    
    % Initialize image
    canvas = ones(totalHeight,totalWidth)*0.5;
    I1 = ones(N,N,3) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = colours(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner == k) & innerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = coloursUDInvdir(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = coloursUDdir(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N,3)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = colours(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = coloursUDdir(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = coloursUDInvdir(k+1,d);
            I2(:,:,d) = dim;
        end
    end
    
    
    canvas = ones(N, 2*N, 3) *0.5;
    I1arr = genarrowdir(I1, 'up');
    I2arr = genarrowdir(I2, 'down');
    canvas(:,1:N,:) = I1;
    canvas(:,1:N,:) = I1arr;
    canvas(:, N+1 : 2*N, :) = I2;
    canvas(:, N+1 : 2*N, :) = I2arr;

    imshow(canvas, [])
    drawnow;
end

for frame = 1:length
    % Phase shift for clockwise rotation (subtract increasing angle)
    phaseShift = -2*pi * (frame-1) * framerefresh; % one full rotation over numFrames
    
    % Shifted theta for each ring
    thetaMain = mod(theta_orig + phaseShift, 2*pi);
    thetaInner = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % inner ring rotated half segment more
    thetaOuter = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % outer ring same as inner
    
    % Initialize image
    canvas = ones(totalHeight,totalWidth)*0.5;
    I1 = ones(N,N,3) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = colours(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner == k) & innerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = coloursUDdir(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        for d = 1:3
            dim = I1(:,:,d);
            dim(mask) = coloursUDInvdir(k+1,d);
            I1(:,:,d) = dim;
        end
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N,3)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = colours(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = coloursUDInvdir(k+1,d);
            I2(:,:,d) = dim;
        end
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        for d = 1:3
            dim = I2(:,:,d);
            dim(mask) = coloursUDdir(k+1,d);
            I2(:,:,d) = dim;
        end
    end
    
    canvas = ones(N, 2*N, 3) *0.5;
    I1arr = genarrowdir(I1, 'down');
    I2arr = genarrowdir(I2, 'up');
    canvas(:,1:N,:) = I1;
    canvas(:,1:N,:) = I1arr;
    canvas(:, N+1 : 2*N, :) = I2;
    canvas(:, N+1 : 2*N, :) = I2arr;

    imshow(canvas, []);
    drawnow;
end