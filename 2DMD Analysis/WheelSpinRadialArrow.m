% Script Name:  WheelSpinRadialArrow.m
% Author:       Andrew Isaac Meso, Nathan Masters & Chat GPT
% Date:         08/02/2026
% Version:      3.0
% Purpose:      To create a single function that generates a modifiable
% wheelspin stimulus that can be used for modelling or for the experimental
% task. This version should either expand or contract.
% Notes:        This version adds an arrow to the generation in order to carry out the experimental task on contexts 

function    WheelStimMat = WheelSpinRadialArrow(ImSiz, numSeg, radVec, edgePropSz, baseGry, nFrames, radSpd, dir, aDir, aSz)
%% A. Function inputs and outputsv
% INPUTS
% ImSiz: Size of the image dimensions in pixels e.g. 128 (by 128), or 256
% (by 256)
% numSeg: number of conical segments in the stimulus (default 4, 6, 8 etc.)
% radVec: vector of inner radius in proportions of circle, [ 0.45, 0.70 ]
% edgePropSz: The size of the edges in the stimulus as a propotion of width e.g. 0.03 
% baseGry: the grey levels by default for the two sections dark and light and edges, 
% sets contrast separately first for wheeel sectors then edges [ 0.3 0.7 0.3 0.7]      
% nFrames: Number of stimulus frames generated, e.g. at 120 Hz, for 500ms,
% 60 frames
% radSpd: rotation rate, in angular speed.
% dir: movement direction either inwards or outwards for the motion
% direction. 1 or -1
% aDir: This is the arrow direction, inwards or outwards for  the rotation
% etc
% aSz: Size of the arrow to determine how much impact it has on perception.

% OUTPUTS
% WheelStimMat: This is a three dimensional matrix with the image frames in
% sequence

%% B. Function pre definitions for matrix calculations
% ImSiz = 256;  % image size, formerly N
% spacing = 10;

%imWidth = 2*N + spacing;
%imHeight = N;

% B.1 Define grids
[x, y] = meshgrid(linspace(-1,1,ImSiz)); %  Cartesial grid of positions
[theta_orig, r] = cart2pol(x, y);           % Polar coordinate grids
theta_orig = mod(theta_orig, 2*pi);         % normalize angle always 0 to 2pi
WheelStimMat = zeros(ImSiz,ImSiz,nFrames);   % Matrix holding output image initialised blank

% B.2 For expansion and contraction, tested with  
% numSegments = 4;          % number of segments per ring
numSegDir = numSeg*2;       % number of segments for the boundary areas
segWidth = 2*pi / numSeg;
segWidthDir = 2*pi / numSegDir;

% B.3 Rings' radii
r_inner = radVec(1);                    % main ring inner radius
r_outer = radVec(2);                    % main ring outer radius
ring_width = r_outer - r_inner;
thinWidth = edgePropSz * ring_width;    % thickness of inner/outer rings

% B.4 Define rings masks indeces for the three separate sections of the
% stimulus
mainRingMask = (r >= r_inner) & (r <= r_outer); %
innerRingInner = r_inner - thinWidth;
innerRingOuter = r_inner;

innerRingMask = (r >= innerRingInner) & (r < innerRingOuter);
outerRingInner = r_outer;

outerRingOuter = r_outer + thinWidth;
outerRingMask = (r >= outerRingInner) & (r < outerRingOuter);

% B.5 Base grayscale values for segments, for expansion/contraction
grayVals = []; grayValsEdg = [];
for ii = 1:numSegDir
    % odd cases 
    if ii ~= (round(ii/2)*2)
        grayVals = [ grayVals baseGry(1) ]; % dark colour wheel
        grayValsEdg = [ grayValsEdg baseGry(3) ]; % edge
    end
    % even cases
    if ii == (round(ii/2)*2)
        grayVals = [ grayVals baseGry(2) ]; % light colour
        grayValsEdg = [ grayValsEdg baseGry(4) ]; % edge
    end
end
%grayVals = [ 0.3 0.7 0.3 0.7 0.3 0.7 0.3 0.7 ]; % alternating dark/light
grayValsInverted = grayVals(end:-1:1);  % inverted for inner ring
grayValsInvertedEdg = grayValsEdg(end:-1:1);  %

% B.6 FrameInformation
% length = 20; nFrames = 20
% framerefresh = .1; % number of animation frames, radSpd = 0.05;

%% C Generate Frames
%% Radially expanding/contracting stimulus
for ii = 1:nFrames
    % Phase shift for clockwise rotation (subtract increasing angle)
    phaseShift = -2*pi * (ii-1) * radSpd; % one full rotation over numFrames
    
    % C.1 Shifted theta for each ring
    thetaMain = mod(theta_orig + phaseShift, 2*pi);
    thetaInner = mod(theta_orig + phaseShift + segWidth/2, 2*pi); % inner ring rotated half segment more
    thetaOuter = mod(theta_orig + phaseShift + segWidth/2, 2*pi); % outer ring same as inner
    
    % C.2 Initialize image
    %canvas = ones(totalHeight,totalWidth)*0.5;  % default background Grey
    I1 = ones(ImSiz,ImSiz) * 0.5; % 0.5 is mid grey

    % C.3 Main ring segments
    segmentIndexMain = floor(thetaMain / segWidth);
    for kk = 0:(numSeg-1)
        mask = (segmentIndexMain == kk) & mainRingMask;
        I1(mask) = grayVals(kk+1);
    end
    
    % C.4 Inner ring segments (inverted colors)
    segmentIndexInner = floor(thetaInner / segWidth);
    for kk = 0:numSeg-1
        mask = (segmentIndexInner == kk) & innerRingMask;
        if dir == 1
            I1(mask) = grayValsInvertedEdg(kk+1);
        elseif dir == -1
            I1(mask) = grayValsEdg(kk+1);
        end
    end
    
    % C.5 Outer ring segments, critical for the motion.. 
    segmentIndexOuter = floor(thetaOuter / segWidth);
    for kk = 0:numSeg-1
        mask = (segmentIndexOuter == kk) & outerRingMask;
        if dir == 1
            I1(mask) = grayValsEdg(kk+1);
        elseif dir == -1
            I1(mask) = grayValsInvertedEdg(kk+1);
        end
    end
    
    % % C.5 
    % thetaMain2 = mod(theta_orig + phaseShift, 2*pi);
    % thetaInner2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    % thetaOuter2 = mod(theta_orig + phaseShift + segmentWidth/2, 2*pi);
    % 
    % I2 = ones(N,N)*0.5;
    % 
    % segmentIndexMain2 = floor(thetaMain2 / segmentWidth);
    % for k = 0:numSegments-1
    %     mask = (segmentIndexMain2 == k) & mainRingMask;
    %     I2(mask) = grayVals(k+1);
    % end
    % 
    % segmentIndexInner2 = floor(thetaInner2 / segmentWidth);
    % for k = 0:numSegments-1
    %     mask = (segmentIndexInner2 == k) & innerRingMask;
    %     I2(mask) = grayVals(k+1);
    % end
    % 
    % segmentIndexOuter2 = floor(thetaOuter2 / segmentWidth);
    % for k = 0:numSegments-1
    %     mask = (segmentIndexOuter2 == k) & outerRingMask;
    %     I2(mask) = grayValsInverted(k+1);
    % end
    
    % C.6 Output image matrix creation.. in this case with the arrow included 
    if aDir == -1
        I1 = GenArrow(I1, 'in',aSz); % inwards
    elseif aDir == 1
        I1 = GenArrow(I1, 'out',aSz); % outwards
    end
    WheelStimMat(1:ImSiz,1:ImSiz,ii) = I1; % fill in image pixel values for the current frame 
end

% end of stimulus production

end