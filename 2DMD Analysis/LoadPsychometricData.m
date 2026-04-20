% Script Name:  LoadPsychometricData.m
% Authors:      K22007681
% Date:         March 2026
% Version:      1.0
% Purpose:      Load the already-processed psychometric data from the
%               anonymised merged .mat files (same format as
%               PsychometricCombo.m) and extract group-level summary
%               statistics — mean observed proportions, mean fitted
%               curve, SEM — for each of the six condition dimensions.
%               Output is a single struct (psychData) ready for use in
%               CompareModelToPsych.m.
%
% The fitted curve stored in the data files is (observed - residual),
% i.e. the psychometric function evaluated at the six stimulus levels.
% No additional fitting is performed here; the PSE for each condition
% is estimated by linear interpolation of the fitted curve at P = 0.5.
%
% Output struct fields (one entry per condition, indexed 1-6):
%   psychData.cond(c).label      — condition name string
%   psychData.cond(c).x          — [1x6] physical stimulus values
%   psychData.cond(c).meanProbs  — [1x6] mean observed P(test chosen)
%   psychData.cond(c).semProbs   — [1x6] SEM across subjects
%   psychData.cond(c).meanFitted — [1x6] mean fitted curve
%   psychData.cond(c).semFitted  — [1x6] SEM of fitted values
%   psychData.cond(c).PSE        — scalar, interpolated from mean fitted
%   psychData.cond(c).allProbs   — [nSubj x 6] individual subject probs
%   psychData.cond(c).allFitted  — [nSubj x 6] individual subject fitted
%   psychData.nSubjects          — number of subjects successfully loaded
%   psychData.subjectLabels      — cell array of subject ID strings

%% A. Settings — match PsychometricCombo exactly
data_dir     = 'C:\Users\Nathan\Documents\Files\ReProj\Summary EyesPlusBehaviour';
subject_nums = [4 5 6 7 8 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 26 28 29 30 31 32 33 34 35 36];

cond_names = {'Edge Size','Edge Contrast','Rotation Speed', ...
              'Wheel Contrast','Arrow Congruent','Arrow Incongruent'};
n_cond = 6;

%% B. Storage — raw arrays accumulated across subjects
raw_x      = cell(1, n_cond);   % cell of [1x6] x vectors
raw_probs  = cell(1, n_cond);   % cell of [1x6] proportion vectors
raw_fitted = cell(1, n_cond);   % cell of [1x6] fitted curve vectors
for c = 1:n_cond
    raw_x{c} = {}; raw_probs{c} = {}; raw_fitted{c} = {};
end

subj_labels = {};
s_count     = 0;

%% C. Load loop — identical field access to PsychometricCombo
for s = subject_nums
    fname = fullfile(data_dir, sprintf('S%02d_BEHEyesAnonymMerge.mat', s));
    if ~isfile(fname)
        fprintf('Skipping (not found): S%02d\n', s);
        continue
    end
    S = load(fname);

    % Resolve B struct — handles the three nesting variants in the data
    if isfield(S,'Data') && isfield(S.Data,'Behavioural')
        B = S.Data.Behavioural;
    elseif isfield(S,'S') && isfield(S.S,'Data') && isfield(S.S.Data,'Behavioural')
        B = S.S.Data.Behavioural;
    elseif isfield(S,'S') && isfield(S.S,'Behavioural')
        B = S.S.Behavioural;
    else
        fprintf('S%02d: unexpected structure — skipping\n', s);
        continue
    end

    s_count = s_count + 1;
    subj_labels{end+1} = sprintf('S%02d', s);

    % C.1 Condition 1: Edge Size
    try
        x     = double(B.EdgeSizeContrast.StimulusParameters.CONDA_EdgeSizRange(:))';
        prob  = double(B.EdgeSizeContrast.PsychometricProbabilitiesConditionsA_and_B(1,:));
        resid = double(B.EdgeSizeContrast.PsychometricFitResidualsA_EdgeSize(:))';
        raw_x{1}{end+1} = x; raw_probs{1}{end+1} = prob;
        raw_fitted{1}{end+1} = prob - resid;
    catch ME
        fprintf('  S%02d Edge Size failed: %s\n', s, ME.message);
    end

    % C.2 Condition 2: Edge Contrast
    try
        x     = double(B.EdgeSizeContrast.StimulusParameters.CONDB_EdgeContrastRange(:))';
        prob  = double(B.EdgeSizeContrast.PsychometricProbabilitiesConditionsA_and_B(2,:));
        resid = double(B.EdgeSizeContrast.PsychometricFitResidualsA_EdgeContrast(:))';
        raw_x{2}{end+1} = x; raw_probs{2}{end+1} = prob;
        raw_fitted{2}{end+1} = prob - resid;
    catch ME
        fprintf('  S%02d Edge Contrast failed: %s\n', s, ME.message);
    end

    % C.3 Condition 3: Rotation Speed
    try
        x     = double(B.EdgeSpeedWheel.StimulusParameters.CONDC_SpeedConditionRange(:))';
        prob  = double(B.EdgeSpeedWheel.PsychometricProbabilitiesConditionsA_and_B(1,:));
        resid = double(B.EdgeSpeedWheel.PsychometricFitResidualsA_EdgeSize(:))';
        raw_x{3}{end+1} = x; raw_probs{3}{end+1} = prob;
        raw_fitted{3}{end+1} = prob - resid;
    catch ME
        fprintf('  S%02d Rotation Speed failed: %s\n', s, ME.message);
    end

    % C.4 Condition 4: Wheel Contrast
    try
        x     = double(B.EdgeSpeedWheel.StimulusParameters.CONDD_WheelContrastRange(:))';
        prob  = double(B.EdgeSpeedWheel.PsychometricProbabilitiesConditionsA_and_B(2,:));
        resid = double(B.EdgeSpeedWheel.PsychometricFitResidualsA_EdgeContrast(:))';
        raw_x{4}{end+1} = x; raw_probs{4}{end+1} = prob;
        raw_fitted{4}{end+1} = prob - resid;
    catch ME
        fprintf('  S%02d Wheel Contrast failed: %s\n', s, ME.message);
    end

    % C.5 Condition 5: Arrow Congruent
    try
        x     = double(B.ArrowSizeAndCongruence.StimulusParameters.CONDE_ArrowSizePropotions(:))';
        prob  = double(B.ArrowSizeAndCongruence.PsychometricProbabilitiesConditionsA_and_B(1,:));
        resid = double(B.ArrowSizeAndCongruence.PsychometricFitResidualsA_EdgeSize(:))';
        raw_x{5}{end+1} = x; raw_probs{5}{end+1} = prob;
        raw_fitted{5}{end+1} = prob - resid;
    catch ME
        fprintf('  S%02d Arrow Congruent failed: %s\n', s, ME.message);
    end

    % C.6 Condition 6: Arrow Incongruent
    try
        x     = double(B.ArrowSizeAndCongruence.StimulusParameters.CONDE_ArrowSizePropotions(:))';
        prob  = double(B.ArrowSizeAndCongruence.PsychometricProbabilitiesConditionsA_and_B(2,:));
        resid = double(B.ArrowSizeAndCongruence.PsychometricFitResidualsA_EdgeContrast(:))';
        raw_x{6}{end+1} = x; raw_probs{6}{end+1} = prob;
        raw_fitted{6}{end+1} = prob - resid;
    catch ME
        fprintf('  S%02d Arrow Incongruent failed: %s\n', s, ME.message);
    end

end % subject loop

fprintf('Loaded %d subjects.\n', s_count);

%% D. Aggregate into group-level summary struct
psychData.nSubjects     = s_count;
psychData.subjectLabels = subj_labels;

for c = 1:n_cond
    n_s = numel(raw_probs{c});

    if n_s == 0
        warning('No subjects loaded for condition %d (%s).', c, cond_names{c});
        psychData.cond(c).label      = cond_names{c};
        psychData.cond(c).x          = [];
        psychData.cond(c).meanProbs  = [];
        psychData.cond(c).semProbs   = [];
        psychData.cond(c).meanFitted = [];
        psychData.cond(c).semFitted  = [];
        psychData.cond(c).PSE        = NaN;
        psychData.cond(c).allProbs   = [];
        psychData.cond(c).allFitted  = [];
        continue
    end

    % Stack into matrices [nSubj x 6]
    prob_mat   = cell2mat(cellfun(@(v) v(:)', raw_probs{c},  'UniformOutput',false)');
    fitted_mat = cell2mat(cellfun(@(v) v(:)', raw_fitted{c}, 'UniformOutput',false)');

    meanProbs  = mean(prob_mat,   1);
    semProbs   = std(prob_mat,  0, 1) / sqrt(n_s);
    meanFitted = mean(fitted_mat, 1);
    semFitted  = std(fitted_mat, 0, 1) / sqrt(n_s);

    % Use x values from the first successfully loaded subject
    % (assumed identical across subjects as they come from StimulusParameters)
    x = raw_x{c}{1};

    % D.1 PSE: x at which mean fitted curve crosses P = 0.5
    % Linear interpolation; returns NaN if 0.5 is outside the fitted range
    if min(meanFitted) < 0.5 && max(meanFitted) > 0.5
        PSE = interp1(meanFitted, x, 0.5, 'linear');
    else
        PSE = NaN;  % curve does not cross chance in this condition range
        fprintf('  Condition %d (%s): mean fitted curve does not cross P=0.5\n', ...
                c, cond_names{c});
    end

    psychData.cond(c).label      = cond_names{c};
    psychData.cond(c).x          = x;
    psychData.cond(c).meanProbs  = meanProbs;
    psychData.cond(c).semProbs   = semProbs;
    psychData.cond(c).meanFitted = meanFitted;
    psychData.cond(c).semFitted  = semFitted;
    psychData.cond(c).PSE        = PSE;
    psychData.cond(c).allProbs   = prob_mat;    % [nSubj x 6]
    psychData.cond(c).allFitted  = fitted_mat;  % [nSubj x 6]

    fprintf('  Condition %d (%s): N=%d, PSE=%.4f\n', c, cond_names{c}, n_s, PSE);
end

fprintf('\npsychData ready. Run CompareModelToPsych.m next.\n');
