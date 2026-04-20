% Script Name:      WheelStimTestc.m
% Author:           Andrew Isaac Meso
% Date:             08/02/2026
% Purpose:          Code to test the wheelspin generating stimuli, viewing
% results
% Version:          3.0
% Notes:            Version adapted to better control of stimulus contrast
% separating the edge contrast from the rotating wheel contrast.

%% A. WheelSpinRadialb(ImSiz, numSeg, radVec, edgePropSz, baseGry, nFrames, radSpd, dir)
% Notes on the variables
% ImSiz: Size of the image dimensions in pixels e.g. 128 (by 128), or 256
% (by 256)
% numSeg: number of conical segments in the stimulus (default 4, 6, 8 etc.)
% radVec: vector of inner radius in proportions of circle, [ 0.45, 0.70 ]
% edgePropSz: The size of the edges in the stimulus as a propotion of width e.g. 0.03 
% baseGry: the gret levels by default for the two sections dark and light, sets contrast [ 0.3 0.7]      
% nFrames: Number of stimulus frames generated, e.g. at 120 Hz, for 500ms,
% 60 frames
% radSpd: rotation rate, in angular speed.
% dir: movement direction either inwards or outwards for the motion
% direction. 1 or -1

% A.1 Setting variable values
ImSiz = 256;
numSeg = 4;
radVec = [ 0.45 0.70 ];
edgePropSz = 0.15; % 0.18 
baseGry = [ 0.0 1.0 0.3 0.7 ]; % wheel and edge contrasts
nFrames = 60; % at 
radSpd = 0.05; 
dir = 1;

close all;  % ensure all windows are closed before testing

% A.2 Now run the stimulus to be tested
StimCase = 1;       % 1 - expansion, 2: translation.. 

% A.3 Generate Test Stimuli, of different types
% A.3.1 Expansion/Contraction
% test timings with tic toc
tic
% radial motion
if StimCase == 1
    WheelStimMat = WheelSpinRadialb(ImSiz, numSeg, radVec, edgePropSz, baseGry, nFrames, radSpd, dir);
end 

% translating motion not working excellently
if StimCase == 2
    WheelStimMat = WheelSpinTranslate(ImSiz, numSeg, radVec, edgePropSz, baseGry, nFrames, radSpd, dir);
end 

% radial with an arrow inside
if StimCase == 3
    aDir = 1; aSz = 0.99; % aDir should be -1 or +1
    WheelStimMat = WheelSpinRadialArrow(ImSiz, numSeg, radVec, edgePropSz, baseGry, nFrames, radSpd, dir, aDir, aSz);
end
toc


% A.4 show outputs
for ii = 1:nFrames
    cIM = squeeze(WheelStimMat(:,:,ii)); % extract current frame for showing
    %imshow(cIM, []); contrast normalised to maximum
    imshow(cIM); % contrast adjusted for input
    colormap gray;
    drawnow;
end 

disp(['Run through frames completed for stimulus #', num2str(StimCase) ', thank you!']);


