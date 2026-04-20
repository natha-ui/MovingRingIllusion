% Script Name:  WheelStimAll2DMD.m
% Authors:      K22007681
% Date:         March 2026
% Version:      1.0
% Purpose:      Generate wheel spin stimuli across all levels of each
%               experimental condition and run the full 2DMD pipeline for
%               each. EMD outputs (magnitude oEMDiiR and direction
%               oEMDiiThet) are stored in cell arrays indexed by condition
%               type and level, ready for analysis scripts A, B and C.
%
% Condition sweep types:
%   1 — Edge size          (edgeSizCond, 6 levels)
%   2 — Edge contrast      (edgeConCond, 6 levels)
%   3 — Rotation speed     (speedCond,   6 levels)
%   4 — Wheel contrast     (wheelConCond,6 levels)
%   5 — Arrow size, congruent     (ArrSzCond, 6 levels, aDir == dir)
%   6 — Arrow size, incongruent   (ArrSzCond, 6 levels, aDir == -dir)
%
% Each condition dimension is swept independently; all other parameters
% are held at their mid-range reference values (mean of levels 3 and 4),
% matching the task design in MotionIllusionTaskDevB.
%
% Outputs (in workspace and optionally saved):
%   EMD_R     — cell {nSweepTypes x nLevels}, each cell [szDim x szDim x nFrames]
%   EMD_Th    — same structure, direction in radians
%   IncInd    — valid pixel index vector (same for all conditions, same image size)
%   condMeta  — struct storing all parameter values for reference

%% A. Initialise model parameters
TwoDCorrMotDetBaseParamsA;  % loads emd struct with all 2DMD defaults

%% B. Shared stimulus and model parameters
szDim    = 256;             % image size in pixels (square)
numSeg   = 4;               % number of wheel segments
radVec   = [0.45  0.70];   % inner/outer ring radii, normalised
dir      = 1;               % motion direction: 1 = expansion, -1 = contraction
Hz       = 120;             % display refresh rate
PresTime = 0.75;            % stimulus duration in seconds
nFrames  = round(PresTime * Hz);  % 90 frames at 120 Hz

% 2DMD parameters
dPhi     = 5;       % spatial sampling base in pixels (filter scale)
tau      = 3;       % EMD temporal delay in intermediate steps
RThr     = 0.01;    % magnitude threshold applied before readout
GlobProp = 0.05;    % proportion of strongest responses used in global readout
MM       = emd.Default.MM;  % filter border size = 65 pixels

% B.1 Condition vectors (six levels each)
edgeSizCond  = [0.01  0.02  0.04  0.06  0.08  0.10];
edgeConCond  = [0.25  0.30  0.35  0.40  0.45  0.50];
speedCond    = [0.004 0.006 0.008 0.010 0.020 0.040];
wheelConCond = [0.25  0.30  0.35  0.40  0.45  0.50];
ArrSzCond   = [0.54  0.63  0.72  0.81  0.90  0.99];
nLevels      = 6;

% B.2 Reference (mid-range) values used when a dimension is not being swept
mnConEdge   = mean(edgeConCond(3:4));   % 0.375
mnConWhl    = mean(wheelConCond(3:4));  % 0.375
edgeSzRef   = mean(edgeSizCond(3:4));  % 0.05
radSpdRef   = mean(speedCond(3:4));    % 0.009
baseGryRef  = [0.5-mnConWhl  0.5+mnConWhl  0.5-mnConEdge  0.5+mnConEdge];
% = [0.125  0.875  0.125  0.875] at the default mid-range values

nSweepTypes = 6;

%% C. Pixel exclusion mask (same for all conditions, image size fixed)
% Run a dummy filter pass on a blank image to extract IncInd.
dummyIM    = zeros(szDim, szDim, 2, 'uint8');
dummyFilt  = DoFilterArray(dummyIM, dPhi, emd);
tIM_dummy  = dummyFilt(:,:,1);
[~, ExBinIM] = ExclReg(tIM_dummy, MM);
IncInd = find(ExBinIM == 0);   % valid pixel indices, reused for all conditions
nValidPx = numel(IncInd);
fprintf('Valid pixels after edge exclusion: %d of %d total\n', nValidPx, szDim^2);

%% D. Storage allocation
% Cell arrays: outer index = sweep type (1-6), inner index = condition level (1-6)
EMD_R  = cell(nSweepTypes, nLevels);   % magnitude  [szDim x szDim x nFrames]
EMD_Th = cell(nSweepTypes, nLevels);   % direction  [szDim x szDim x nFrames]

%% E. Condition metadata struct for reference later
condMeta.edgeSizCond  = edgeSizCond;
condMeta.edgeConCond  = edgeConCond;
condMeta.speedCond    = speedCond;
condMeta.wheelConCond = wheelConCond;
condMeta.ArrSzCond    = ArrSzCond;
condMeta.refValues.mnConEdge  = mnConEdge;
condMeta.refValues.mnConWhl   = mnConWhl;
condMeta.refValues.edgeSzRef  = edgeSzRef;
condMeta.refValues.radSpdRef  = radSpdRef;
condMeta.refValues.baseGryRef = baseGryRef;
condMeta.modelParams.dPhi     = dPhi;
condMeta.modelParams.tau      = tau;
condMeta.modelParams.RThr     = RThr;
condMeta.modelParams.GlobProp = GlobProp;
condMeta.modelParams.szDim    = szDim;
condMeta.modelParams.nFrames  = nFrames;
condMeta.modelParams.dir      = dir;
condMeta.sweepLabels = {'Edge size', 'Edge contrast', 'Speed', ...
                         'Wheel contrast', 'Arrow (cong.)', 'Arrow (incong.)'};

%% F. Main loop: sweep each condition type across all levels
for st = 1:nSweepTypes
    fprintf('\n=== Sweep type %d: %s ===\n', st, condMeta.sweepLabels{st});

    for lv = 1:nLevels

        % F.1 Set parameters for this condition level -------------------
        % Defaults (reference values for all non-swept dimensions)
        edgePropSzTst = edgeSzRef;
        baseGryTst    = baseGryRef;
        radSpdTst     = radSpdRef;
        aDir          = dir;    % arrow direction (congruent by default)
        aSz           = mean(ArrSzCond(3:4));  % mid-range arrow size
        useArrow      = false;

        switch st
            case 1  % Edge size sweep
                edgePropSzTst = edgeSizCond(lv);
                cLabel = sprintf('edgeSiz=%.3f', edgeSizCond(lv));

            case 2  % Edge contrast sweep
                cuConEdge  = edgeConCond(lv);
                cuConWhl   = mnConWhl;
                baseGryTst = [0.5-cuConWhl  0.5+cuConWhl ...
                               0.5-cuConEdge  0.5+cuConEdge];
                cLabel = sprintf('edgeCon=%.3f', edgeConCond(lv));

            case 3  % Speed sweep
                radSpdTst = speedCond(lv);
                cLabel = sprintf('speed=%.4f', speedCond(lv));

            case 4  % Wheel contrast sweep
                cuConEdge  = mnConEdge;
                cuConWhl   = wheelConCond(lv);
                baseGryTst = [0.5-cuConWhl  0.5+cuConWhl ...
                               0.5-cuConEdge  0.5+cuConEdge];
                cLabel = sprintf('wheelCon=%.3f', wheelConCond(lv));

            case 5  % Arrow size, congruent (aDir == dir)
                useArrow = true;
                aDir     = dir;
                aSz      = ArrSzCond(lv);
                cLabel   = sprintf('arrSz(cong)=%.3f', ArrSzCond(lv));

            case 6  % Arrow size, incongruent (aDir == -dir)
                useArrow = true;
                aDir     = -dir;
                aSz      = ArrSzCond(lv);
                cLabel   = sprintf('arrSz(incong)=%.3f', ArrSzCond(lv));
        end

        fprintf('  Level %d/%d: %s\n', lv, nLevels, cLabel);

        % F.2 Generate stimulus -----------------------------------------
        tic;
        if useArrow
            IM = WheelSpinRadialArrow(szDim, numSeg, radVec, edgePropSzTst, ...
                                      baseGryTst, nFrames, radSpdTst, dir, aDir, aSz);
        else
            IM = WheelSpinRadialb(szDim, numSeg, radVec, edgePropSzTst, ...
                                   baseGryTst, nFrames, radSpdTst, dir);
        end
        fprintf('    Generated (%.2fs)\n', toc);

        % F.3 Spatial filtering -----------------------------------------
        % WheelSpinRadialb returns grayscale values in [0,1]; scale to
        % uint8 [0,255] for DoFilterArray (expects integer pixel values)
        IM_u8 = uint8(IM * 255);
        tic;
        fImage = DoFilterArray(IM_u8, dPhi, emd);
        fprintf('    Filtered  (%.2fs)\n', toc);

        % F.4 EMD correlation -------------------------------------------
        tic;
        [~, ~, oEMDiiR, oEMDiiThet] = DoEMDArrays(fImage, tau, dPhi, emd);
        fprintf('    EMD done  (%.2fs)\n', toc);

        % F.5 Store outputs ---------------------------------------------
        EMD_R{st, lv}  = oEMDiiR;   % [szDim x szDim x nFrames]
        EMD_Th{st, lv} = oEMDiiThet;

    end % level loop
end % sweep type loop

fprintf('\nAll conditions complete. EMD_R and EMD_Th ready for analysis.\n');

%% G. Save Outputs
%save('WheelEMD_Outputs.mat', 'EMD_R', 'EMD_Th', 'IncInd', 'condMeta', '-v7.3');
%fprintf('Saved to WheelEMD_Outputs.mat\n');
