%%

N = 450;  % image size
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
thinWidth = 0.015 * ring_width;  % thickness of inner/outer rings

% Define rings masks
mainRingMask = (r >= r_inner) & (r <= r_outer);
innerRingInner = r_inner - thinWidth;
innerRingOuter = r_inner;
innerRingMask = (r >= innerRingInner) & (r < innerRingOuter);
outerRingInner = r_outer;
outerRingOuter = r_outer + thinWidth;
outerRingMask = (r >= outerRingInner) & (r < outerRingOuter);

% Base grayscale values for segments
grayVals1 = [0.3 0.7 0.3 0.7 0.3 0.7 0.3 0.7]; % alternating dark/light
grayVals2 = [0.4 0.6 0.4 0.6 0.4 0.6 0.4 0.6]; % alternating dark/light
grayValsInverted1 = 1-grayVals1;  % inverted for inner ring
grayValsInverted2 = 1-grayVals2;  % inverted for inner ring


length = 40;
framerefresh = .1; % number of animation frames

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
    I1 = ones(N,N) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        I1(mask) = grayVals1(k+1);
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexInner == k) & innerRingMask;
        I1(mask) = grayValsInverted1(k+1);
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        I1(mask) = grayVals1(k+1);
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        I2(mask) = grayVals2(k+1);
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        I2(mask) = grayVals2(k+1);
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        I2(mask) = grayValsInverted2(k+1);
    end

    canvas(:,1:N) = I1;
    canvas(:, N+1 : 2*N) = I2;

    imshow(canvas, []);
    colormap gray;
    drawnow;
end

%% aa
for frame = 1:length
    % Phase shift for clockwise rotation (subtract increasing angle)
    phaseShift = -2*pi * (frame-1) * framerefresh; % one full rotation over numFrames
    
    % Shifted theta for each ring
    thetaMain = mod(theta_orig + phaseShift, 2*pi);
    thetaInner = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % inner ring rotated half segment more
    thetaOuter = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % outer ring same as inner
    
    % Initialize image
    canvas = ones(totalHeight,totalWidth)*0.5;
    I1 = ones(N,N) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        I1(mask) = grayVals(k+1);
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexInner == k) & innerRingMask;
        I1(mask) = grayVals(k+1);
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        I1(mask) = grayValsInverted(k+1);
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        I2(mask) = grayVals(k+1);
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        I2(mask) = grayValsInverted(k+1);
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        I2(mask) = grayVals(k+1);
    end

    canvas(:,1:N) = I1;
    canvas(:, N+1 : 2*N) = I2;

    imshow(canvas, []);
    colormap gray;
    drawnow;
end

%% Directional - Left Right
%adjust gray vals - direction going to = double light outer, double dark
%inner
%I think it needs arrows?

grayValsdir = [0.7 0.7 0.3 0.7 0.3 0.3 0.7 0.3];
grayValsdirInverted = 1-grayValsdir;  % inverted for inner ring


for frame = 1:length
    % Phase shift for clockwise rotation (subtract increasing angle)
    phaseShift = -2*pi * (frame-1) * framerefresh; % one full rotation over numFrames
    
    % Shifted theta for each ring
    thetaMain = mod(theta_orig + phaseShift, 2*pi);
    thetaInner = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % inner ring rotated half segment more
    thetaOuter = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % outer ring same as inner
    
    % Initialize image
    I1 = ones(N,N) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        I1(mask) = grayVals(k+1);
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner == k) & innerRingMask;
        I1(mask) = grayValsdirInverted(k+1);
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        I1(mask) = grayValsdir(k+1);
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        I2(mask) = grayVals(k+1);
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        I2(mask) = grayValsdir(k+1);
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        I2(mask) = grayValsdirInverted(k+1);
    end 
    canvas(:,1:N) = I1;
    canvas(:, N+1 : N+N) = I2;
    
    
    imshow(canvas, []);
    colormap gray;
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
    I1 = ones(N,N) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        I1(mask) = grayVals(k+1);
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner == k) & innerRingMask;
        I1(mask) = grayValsdir(k+1);
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        I1(mask) = grayValsdirInverted(k+1);
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        I2(mask) = grayVals(k+1);
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        I2(mask) = grayValsdirInverted(k+1);
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        I2(mask) = grayValsdir(k+1);
    end

    canvas(:,1:N) = I1;
    canvas(:, N+1 : N+N) = I2;

    imshow(canvas, []);
    colormap gray;
    drawnow;
end

%% Directional - Up Down
%adjust gray vals - direction going to = half dark, half light
lengthUD = 50;
framerefreshUD = .1;
grayValsdir = [0.7 0.7 0.7 0.7 0.3 0.3 0.3 0.3];
grayValsdirInverted = 1-grayValsdir;  % inverted for inner ring


for frame = 1:lengthUD
    % Phase shift for clockwise rotation (subtract increasing angle)
    phaseShift = -2*pi * (frame-1) * framerefreshUD; % one full rotation over numFrames
    
    % Shifted theta for each ring
    thetaMain = mod(theta_orig + phaseShift, 2*pi);
    thetaInner = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % inner ring rotated half segment more
    thetaOuter = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi); % outer ring same as inner
    
    % Initialize image
    canvas = ones(totalHeight,totalWidth)*0.5;
    I1 = ones(N,N) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        I1(mask) = grayVals(k+1);
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner == k) & innerRingMask;
        I1(mask) = grayValsdirInverted(k+1);
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        I1(mask) = grayValsdir(k+1);
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        I2(mask) = grayVals(k+1);
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        I2(mask) = grayValsdir(k+1);
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        I2(mask) = grayValsdirInverted(k+1);
    end

    canvas(:,1:N) = I1;
    canvas(:, N+1 : N+N) = I2;

    imshow(canvas, []);
    colormap gray;
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
    I1 = ones(N,N) * 0.5;

    % Main ring segments
    segmentIndexMain = floor(thetaMain / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain == k) & mainRingMask;
        I1(mask) = grayVals(k+1);
    end
    
    % Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner == k) & innerRingMask;
        I1(mask) = grayValsdir(k+1);
    end
    
    % Outer ring segments
    segmentIndexOuter = floor(thetaOuter / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter == k) & outerRingMask;
        I1(mask) = grayValsdirInverted(k+1);
    end
    
    
    thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    
    I2 = ones(N,N)*0.5;

    segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    for k = 0:numSegments-1
        mask = (segmentIndexMain2 == k) & mainRingMask;
        I2(mask) = grayVals(k+1);
    end

    segmentIndexInner2 = floor(thetaInner2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexInner2 == k) & innerRingMask;
        I2(mask) = grayValsdirInverted(k+1);
    end

    segmentIndexOuter2 = floor(thetaOuter2 / segmentWidthDir);
    for k = 0:numSegmentsDir-1
        mask = (segmentIndexOuter2 == k) & outerRingMask;
        I2(mask) = grayValsdir(k+1);
    end

    canvas(:,1:N) = I1;
    canvas(:, N+1 : N+N) = I2;

    imshow(canvas, []);
    colormap gray;
    drawnow;
end