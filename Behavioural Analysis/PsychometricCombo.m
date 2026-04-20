%  PsychometricCombo.m
%  Psychometric Function Plots
%  Plot 1: One subplot per subject, all 6 conditions
%  Plot 2: Combined across subjects, one subplot per condition
%
%  Fitted curve = observed probabilities - residuals
%  X axis uses actual stimulus values from StimulusParameters

clear; clc; close all;


data_dir     = '.';
subject_nums = [4 5 6 7 8 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 26 28 29 30 31 32 33 34 35 36];

cond_names  = {'Edge Size','Edge Contrast','Rotation Speed','Wheel Contrast','Arrow Congruent','Arrow Incongruent'};
cond_colors = [ ...
    0.20 0.45 0.75; ...
    0.55 0.75 0.95; ...
    0.15 0.65 0.35; ...
    0.60 0.88 0.60; ...
    0.85 0.25 0.25; ...
    0.95 0.45 0.35; ...
];


n_cond     = 6;
all_x      = cell(1, n_cond);
all_probs  = cell(1, n_cond);
all_fitted = cell(1, n_cond);
for c = 1:n_cond
    all_x{c}      = {};
    all_probs{c}  = {};
    all_fitted{c} = {};
end

subj_labels = {};
subj_data   = {};
s_count     = 0;

%% Load
for s = subject_nums
    fname = fullfile(data_dir, sprintf('S%02d_BEHEyesAnonymMerge.mat', s));
    if ~isfile(fname)
        fprintf('Skipping (not found): %s\n', fname);
        continue
    end

    S = load(fname);

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
    sd = struct();
    sd.x      = cell(1, n_cond);
    sd.probs  = cell(1, n_cond);
    sd.fitted = cell(1, n_cond);
    for c = 1:n_cond
        sd.x{c} = []; sd.probs{c} = []; sd.fitted{c} = [];
    end

    % Condition 1: Edge Size 
    try
        x     = double(B.EdgeSizeContrast.StimulusParameters.CONDA_EdgeSizRange(:))';
        prob  = double(B.EdgeSizeContrast.PsychometricProbabilitiesConditionsA_and_B(1,:));
        resid = double(B.EdgeSizeContrast.PsychometricFitResidualsA_EdgeSize(:))';
        sd.x{1} = x; sd.probs{1} = prob; sd.fitted{1} = prob - resid;
        all_x{1}{end+1} = x; all_probs{1}{end+1} = prob; all_fitted{1}{end+1} = prob - resid;
    catch ME; fprintf('  S%02d Edge Size failed: %s\n', s, ME.message); end

    % Condition 2: Edge Contrast
    try
        x     = double(B.EdgeSizeContrast.StimulusParameters.CONDB_EdgeContrastRange(:))';
        prob  = double(B.EdgeSizeContrast.PsychometricProbabilitiesConditionsA_and_B(2,:));
        resid = double(B.EdgeSizeContrast.PsychometricFitResidualsA_EdgeContrast(:))';
        sd.x{2} = x; sd.probs{2} = prob; sd.fitted{2} = prob - resid;
        all_x{2}{end+1} = x; all_probs{2}{end+1} = prob; all_fitted{2}{end+1} = prob - resid;
    catch ME; fprintf('  S%02d Edge Contrast failed: %s\n', s, ME.message); end

    % Condition 3: Rotation Speed
    try
        x     = double(B.EdgeSpeedWheel.StimulusParameters.CONDC_SpeedConditionRange(:))';
        prob  = double(B.EdgeSpeedWheel.PsychometricProbabilitiesConditionsA_and_B(1,:));
        resid = double(B.EdgeSpeedWheel.PsychometricFitResidualsA_EdgeSize(:))';
        sd.x{3} = x; sd.probs{3} = prob; sd.fitted{3} = prob - resid;
        all_x{3}{end+1} = x; all_probs{3}{end+1} = prob; all_fitted{3}{end+1} = prob - resid;
    catch ME; fprintf('  S%02d Rotation Speed failed: %s\n', s, ME.message); end

    % Condition 4: Wheel Contrast
    try
        x     = double(B.EdgeSpeedWheel.StimulusParameters.CONDD_WheelContrastRange(:))';
        prob  = double(B.EdgeSpeedWheel.PsychometricProbabilitiesConditionsA_and_B(2,:));
        resid = double(B.EdgeSpeedWheel.PsychometricFitResidualsA_EdgeContrast(:))';
        sd.x{4} = x; sd.probs{4} = prob; sd.fitted{4} = prob - resid;
        all_x{4}{end+1} = x; all_probs{4}{end+1} = prob; all_fitted{4}{end+1} = prob - resid;
    catch ME; fprintf('  S%02d Wheel Contrast failed: %s\n', s, ME.message); end

    % Condition 5: Arrow Congruent
    try
        x     = double(B.ArrowSizeAndCongruence.StimulusParameters.CONDE_ArrowSizePropotions(:))';
        prob  = double(B.ArrowSizeAndCongruence.PsychometricProbabilitiesConditionsA_and_B(1,:));
        resid = double(B.ArrowSizeAndCongruence.PsychometricFitResidualsA_EdgeSize(:))';
        sd.x{5} = x; sd.probs{5} = prob; sd.fitted{5} = prob - resid;
        all_x{5}{end+1} = x; all_probs{5}{end+1} = prob; all_fitted{5}{end+1} = prob - resid;
    catch ME; fprintf('  S%02d Arrow Congruent failed: %s\n', s, ME.message); end

    % Condition 6: Arrow Incongruent 
    try
        x     = double(B.ArrowSizeAndCongruence.StimulusParameters.CONDE_ArrowSizePropotions(:))';
        prob  = double(B.ArrowSizeAndCongruence.PsychometricProbabilitiesConditionsA_and_B(2,:));
        resid = double(B.ArrowSizeAndCongruence.PsychometricFitResidualsA_EdgeContrast(:))';
        sd.x{6} = x; sd.probs{6} = prob; sd.fitted{6} = prob - resid;
        all_x{6}{end+1} = x; all_probs{6}{end+1} = prob; all_fitted{6}{end+1} = prob - resid;
    catch ME; fprintf('  S%02d Arrow Incongruent failed: %s\n', s, ME.message); end

    subj_data{s_count} = sd;
end

fprintf('Loaded %d subjects: %s\n', s_count, strjoin(subj_labels,', '));


%  PLOT 1: One subplot per subject

n_cols = 6;
n_rows = ceil(s_count / n_cols);

figure('Color','w','Position',[20 20 1600 900]);

for si = 1:s_count
    ax = subplot(n_rows, n_cols, si);
    hold(ax, 'on');
    sd = subj_data{si};

    for c = 1:n_cond
        if isempty(sd.x{c}) || isempty(sd.probs{c}); continue; end
        x = sd.x{c};

        % Raw data points
        plot(ax, x, sd.probs{c}, 'o', ...
            'Color', cond_colors(c,:), ...
            'MarkerFaceColor', cond_colors(c,:), ...
            'MarkerSize', 3, 'LineWidth', 0.5);

        % Fitted curve
        if ~isempty(sd.fitted{c})
            plot(ax, x, sd.fitted{c}, '-', ...
                'Color', cond_colors(c,:), 'LineWidth', 1.2);
        end
    end

    plot(ax, [min(cellfun(@(v) min(v), sd.x(~cellfun(@isempty,sd.x)))) ...
              max(cellfun(@(v) max(v), sd.x(~cellfun(@isempty,sd.x))))], ...
         [0.5 0.5], 'k:', 'LineWidth', 0.5);

    set(ax, 'FontSize', 7, 'YLim', [0 1], 'Box', 'off');
    title(ax, subj_labels{si}, 'FontSize', 8, 'FontWeight', 'bold');
    if mod(si-1, n_cols) == 0; ylabel(ax, 'Prob.', 'FontSize', 7); end
    if si > (n_rows-1)*n_cols;  xlabel(ax, 'Stimulus', 'FontSize', 7); end
    hold(ax, 'off');
end

% Legend in spare subplot
if s_count < n_rows*n_cols
    ax_leg = subplot(n_rows, n_cols, s_count+1);
    hold(ax_leg,'on'); axis(ax_leg,'off');
    for c = 1:n_cond
        plot(ax_leg, NaN, NaN, '-o', 'Color', cond_colors(c,:), ...
            'MarkerFaceColor', cond_colors(c,:), 'LineWidth', 1.5, ...
            'DisplayName', cond_names{c});
    end
    legend(ax_leg, 'show', 'FontSize', 7, 'Box','off', 'Location','west');
    hold(ax_leg,'off');
end

try
    sgtitle('Psychometric Functions — Individual Subjects', 'FontSize',13,'FontWeight','bold');
catch
    annotation('textbox',[0 0.96 1 0.04],'String','Psychometric Functions — Individual Subjects',...
        'HorizontalAlignment','center','EdgeColor','none','FontSize',13,'FontWeight','bold');
end


%  PLOT 2: Individual subjects — standardised x-axis (1-6)

x_std = 1:6;

figure('Color','w','Position',[20 20 1600 900]);

for si = 1:s_count
    ax = subplot(n_rows, n_cols, si);
    hold(ax, 'on');
    sd = subj_data{si};

    for c = 1:n_cond
        if isempty(sd.probs{c}); continue; end

        % Raw data points at standardised positions
        plot(ax, x_std, sd.probs{c}, 'o', ...
            'Color', cond_colors(c,:), ...
            'MarkerFaceColor', cond_colors(c,:), ...
            'MarkerSize', 3, 'LineWidth', 0.5);

        % Fitted curve at standardised positions
        if ~isempty(sd.fitted{c})
            plot(ax, x_std, sd.fitted{c}, '-', ...
                'Color', cond_colors(c,:), 'LineWidth', 1.2);
        end
    end

    plot(ax, [0.5 6.5], [0.5 0.5], 'k:', 'LineWidth', 0.5);

    set(ax, 'FontSize', 7, 'YLim', [0 1], 'XLim', [0.5 6.5], ...
        'XTick', x_std, 'XTickLabel', {'1','2','3','4','5','6'}, 'Box', 'off');
    title(ax, subj_labels{si}, 'FontSize', 8, 'FontWeight', 'bold');
    if mod(si-1, n_cols) == 0; ylabel(ax, 'Prob.', 'FontSize', 7); end
    if si > (n_rows-1)*n_cols;  xlabel(ax, 'Stimulus Level', 'FontSize', 7); end
    hold(ax, 'off');
end

% Legend in spare subplot
if s_count < n_rows*n_cols
    ax_leg = subplot(n_rows, n_cols, s_count+1);
    hold(ax_leg,'on'); axis(ax_leg,'off');
    for c = 1:n_cond
        plot(ax_leg, NaN, NaN, '-o', 'Color', cond_colors(c,:), ...
            'MarkerFaceColor', cond_colors(c,:), 'LineWidth', 1.5, ...
            'DisplayName', cond_names{c});
    end
    legend(ax_leg, 'show', 'FontSize', 7, 'Box','off', 'Location','west');
    hold(ax_leg,'off');
end

try
    sgtitle('Psychometric Functions — Individual Subjects (standardised 1-6)', ...
        'FontSize',13,'FontWeight','bold');
catch
    annotation('textbox',[0 0.96 1 0.04], ...
        'String','Psychometric Functions — Individual Subjects (standardised 1-6)', ...
        'HorizontalAlignment','center','EdgeColor','none','FontSize',13,'FontWeight','bold');
end




%  PLOT 2: Combined across subjects — one subplot per condition

figure('Color','w','Position',[20 20 1400 700]);

for c = 1:n_cond
    ax = subplot(2, 3, c);
    hold(ax, 'on');

    n_s = numel(all_probs{c});
    if n_s == 0; continue; end

    % Use first subject's x values as reference (assumed same across subjects)
    x_ref = all_x{c}{1};

    % Individual subject fitted curves (thin, faint)
    for si = 1:n_s
        if isempty(all_fitted{c}{si}); continue; end
        x_si = all_x{c}{si};
        plot(ax, x_si, all_fitted{c}{si}, '-', ...
            'Color', [cond_colors(c,:), 0.15], 'LineWidth', 0.8);
    end

    % Individual raw data points (very faint)
    for si = 1:n_s
        x_si = all_x{c}{si};
        plot(ax, x_si, all_probs{c}{si}, 'o', ...
            'Color', [cond_colors(c,:), 0.12], ...
            'MarkerSize', 3, 'LineWidth', 0.5);
    end

    % Stack matrices (assumes same x levels across subjects)
    prob_mat   = cell2mat(cellfun(@(v) v(:)', all_probs{c},  'UniformOutput',false)');
    fitted_mat = cell2mat(cellfun(@(v) v(:)', all_fitted{c}, 'UniformOutput',false)');

    mean_probs  = mean(prob_mat,   1);
    sem_probs   = std(prob_mat,  0, 1) / sqrt(size(prob_mat,  1));
    mean_fitted = mean(fitted_mat, 1);

    % Mean fitted curve (thick)
    plot(ax, x_ref, mean_fitted, '-', 'Color', cond_colors(c,:), 'LineWidth', 2.5);

    % Mean observed ± SEM
    errorbar(ax, x_ref, mean_probs, sem_probs, 'o', ...
        'Color', cond_colors(c,:), ...
        'MarkerFaceColor', cond_colors(c,:), ...
        'MarkerSize', 6, 'LineWidth', 1.5, 'CapSize', 6);

    % 0.5 reference line
    plot(ax, [min(x_ref) max(x_ref)], [0.5 0.5], 'k--', 'LineWidth', 1);

    set(ax, 'FontSize', 9, 'YLim',[0 1], 'Box','off');
    title(ax, cond_names{c}, 'FontSize',11, 'FontWeight','bold', 'Color', cond_colors(c,:));
    ylabel(ax, 'Response Probability', 'FontSize',9);
    xlabel(ax, 'Stimulus Value',        'FontSize',9);
    grid(ax, 'on');
    hold(ax, 'off');
end

try
    sgtitle('Psychometric Functions — Combined Across Subjects (mean ± SEM)', ...
        'FontSize',13,'FontWeight','bold');
catch
    annotation('textbox',[0 0.96 1 0.04], ...
        'String','Psychometric Functions — Combined Across Subjects (mean ± SEM)', ...
        'HorizontalAlignment','center','EdgeColor','none','FontSize',13,'FontWeight','bold');
end

fprintf('Done — two figures open.\n');
