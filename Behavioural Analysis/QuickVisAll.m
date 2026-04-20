%QuickVisAll.m
%  Boxplots of PSE & Slope — 6 Conditions Across Subjects
%  + Arrow probability bar chart

clear; clc; close all;

data_dir     = '.';
subject_nums = [4 5 6 7 8 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 26 28 29 30 31 32 33 34 35 36];

PSE_col   = 1;
slope_col = 2;

x_levels = [0.54 0.63 0.72 0.81 0.90 0.99];

condition_labels = { ...
    'Edge Size', 'Edge Contrast', ...
    'Rotation Speed', 'Wheel Contrast', ...
    'Arrow Congruent', 'Arrow Incongruent' ...
};

cond_colors = [ ...
    0.20 0.45 0.75; ...
    0.55 0.75 0.95; ...
    0.15 0.65 0.35; ...
    0.60 0.88 0.60; ...
    0.85 0.25 0.25; ...
    0.95 0.65 0.55; ...
];

n_cond     = 6;
pse_data   = cell(1, n_cond);
slope_data = cell(1, n_cond);
for c = 1:n_cond
    pse_data{c}   = [];
    slope_data{c} = [];
end
 
% LOAD
subjects_loaded = {};

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
        fprintf('  S%02d: unexpected structure. Top-level fields:\n', s);
        disp(fieldnames(S))
        continue
    end

    ok = true;

    try
        p = double(B.EdgeSizeContrast.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pse_data{1}(end+1)   = p(PSE_col);
        slope_data{1}(end+1) = p(slope_col);
    catch ME
        fprintf('  S%02d Edge Size failed: %s\n', s, ME.message); ok = false;
    end

    try
        p = double(B.EdgeSizeContrast.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        pse_data{2}(end+1)   = p(PSE_col);
        slope_data{2}(end+1) = p(slope_col);
    catch ME
        fprintf('  S%02d Edge Contrast failed: %s\n', s, ME.message); ok = false;
    end

    try
        p = double(B.EdgeSpeedWheel.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pse_data{3}(end+1)   = p(PSE_col);
        slope_data{3}(end+1) = p(slope_col);
    catch ME
        fprintf('  S%02d Rotation Speed failed: %s\n', s, ME.message); ok = false;
    end

    try
        p = double(B.EdgeSpeedWheel.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        pse_data{4}(end+1)   = p(PSE_col);
        slope_data{4}(end+1) = p(slope_col);
    catch ME
        fprintf('  S%02d Wheel Contrast failed: %s\n', s, ME.message); ok = false;
    end

    try
        probs = B.ArrowSizeAndCongruence.PsychometricProbabilitiesConditionsA_and_B;
        pse_data{5}(end+1) = mean(probs(1,:));  % mean prob across 6 levels (Congruent)
        pse_data{6}(end+1) = mean(probs(2,:));  % mean prob across 6 levels (Incongruent)
        p_con   = double(B.ArrowSizeAndCongruence.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        p_incon = double(B.ArrowSizeAndCongruence.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        slope_data{5}(end+1) = p_con(slope_col);
        slope_data{6}(end+1) = p_incon(slope_col);
    catch ME
        fprintf('  S%02d Arrow failed: %s\n', s, ME.message); ok = false;
    end

    if ok
        subjects_loaded{end+1} = sprintf('S%02d', s);
    end
end

fprintf('\nLoaded %d subjects: %s\n', numel(subjects_loaded), strjoin(subjects_loaded, ', '));
if isempty(subjects_loaded)
    error('No subjects loaded — check data_dir and field names.');
end


% STANDARDISE PSE AND SLOPE ACROSS CONDITIONS
%   z-score each condition independently across subjects
%   Raw values preserved in pse_data / slope_data
%   Standardised values in pse_z / slope_z

pse_z   = cell(1, n_cond);
slope_z = cell(1, n_cond);

fprintf('\n--- Standardisation (z-score per condition) ---\n');
for c = 1:n_cond
    v = pse_data{c}(isfinite(pse_data{c}));
    if numel(v) > 1
        pse_z{c} = (pse_data{c} - mean(v)) / std(v);
    else
        pse_z{c} = pse_data{c};
    end

    v = slope_data{c}(isfinite(slope_data{c}));
    if numel(v) > 1
        slope_z{c} = (slope_data{c} - mean(v)) / std(v);
    else
        slope_z{c} = slope_data{c};
    end

    fprintf('  Cond %d (%s): PSE mean=%.3f SD=%.3f | Slope mean=%.3f SD=%.3f\n', ...
        c, condition_labels{c}, mean(pse_data{c},'omitnan'), std(pse_data{c},'omitnan'), ...
        mean(slope_data{c},'omitnan'), std(slope_data{c},'omitnan'));
end


%  FIGURE 1: PSE boxplot — conditions 1-4 (raw)

figure('Color','w','Position',[50 400 850 460]);
hold on;

vals_pse = []; grp_pse = [];
for c = 1:4
    v = pse_data{c}(isfinite(pse_data{c}));
    vals_pse = [vals_pse; v(:)];
    grp_pse  = [grp_pse;  repmat(c, numel(v), 1)];
end

boxplot(vals_pse, grp_pse, ...
    'Labels',    condition_labels(1:4), ...
    'Positions', 1:4, ...
    'Widths',    0.5, ...
    'Symbol',    '', ...
    'Colors',    'k');

h = findobj(gca, 'Tag', 'Box');
for c = 1:numel(h)
    idx = numel(h) - c + 1;
    patch(get(h(c),'XData'), get(h(c),'YData'), cond_colors(idx,:), ...
        'FaceAlpha', 0.6, 'EdgeColor', 'k');
end

for c = 1:4
    v = pse_data{c}(isfinite(pse_data{c}));
    rng(c*13);
    jit = (rand(numel(v),1)-0.5)*0.2;
    scatter(c+jit, v(:), 30, cond_colors(c,:), 'filled');
end

plot([0.4 4.6], [0.5 0.5], 'k--', 'LineWidth', 1.2);
ylim([0 1]); xlim([0.4 4.6]);
set(gca, 'XTick',1:4, 'XTickLabel',condition_labels(1:4), ...
    'XTickLabelRotation',15, 'FontSize',11);
ylabel('PSE', 'FontSize',13);
title('PSE by Condition (raw)', 'FontSize',14, 'FontWeight','bold');
grid on; box off; hold off;

%  FIGURE 2: PSE — standardised (z-scored)

figure('Color','w','Position',[50 400 850 460]);
hold on;

vals_pse_z = []; grp_pse_z = [];
for c = 1:4
    v = pse_z{c}(isfinite(pse_z{c}));
    vals_pse_z = [vals_pse_z; v(:)];
    grp_pse_z  = [grp_pse_z;  repmat(c, numel(v), 1)];
end

boxplot(vals_pse_z, grp_pse_z, ...
    'Labels',    condition_labels(1:4), ...
    'Positions', 1:4, ...
    'Widths',    0.5, ...
    'Symbol',    '', ...
    'Colors',    'k');

h = findobj(gca, 'Tag', 'Box');
for c = 1:numel(h)
    idx = numel(h) - c + 1;
    patch(get(h(c),'XData'), get(h(c),'YData'), cond_colors(idx,:), ...
        'FaceAlpha', 0.6, 'EdgeColor', 'k');
end

for c = 1:4
    v = pse_z{c}(isfinite(pse_z{c}));
    rng(c*13);
    jit = (rand(numel(v),1)-0.5)*0.2;
    scatter(c+jit, v(:), 30, cond_colors(c,:), 'filled');
end

plot([0.4 4.6], [0 0], 'k--', 'LineWidth', 1.2);
xlim([0.4 4.6]);
set(gca, 'XTick',1:4, 'XTickLabel',condition_labels(1:4), ...
    'XTickLabelRotation',15, 'FontSize',11);
ylabel('PSE (z-score)', 'FontSize',13);
title('PSE by Condition (standardised)', 'FontSize',14, 'FontWeight','bold');
grid on; box off; hold off;


%  FIGURE 3: Slope scatter — conditions 1-4 (raw, Winsorised display)
% Winsorise at 3 SD for display only — raw values used in statistics
outlier_thresh = 1;   % SD threshold for Winsorisation

figure('Color','w','Position',[50 200 850 460]);
hold on;

% Compute display limits across all 4 conditions combined
all_slope_vals = [];
for c = 1:4
    all_slope_vals = [all_slope_vals, slope_data{c}(isfinite(slope_data{c}))];
end
gm = mean(all_slope_vals); gs = std(all_slope_vals);
y_lo = gm - outlier_thresh*gs;
y_hi = gm + outlier_thresh*gs;

n_outliers_total = 0;
for c = 1:4
    v   = slope_data{c}(isfinite(slope_data{c}));
    n_v = numel(v);

    % Flag outliers for annotation
    is_out = v < y_lo | v > y_hi;
    n_outliers_total = n_outliers_total + sum(is_out);

    % Winsorise for display
    v_disp = max(min(v, y_hi), y_lo);

    rng(c*11);
    jit = (rand(n_v,1)-0.5)*0.25;

    % Plot non-outliers normally, outliers as open circles
    scatter(c+jit(~is_out), v_disp(~is_out), 40, cond_colors(c,:), 'filled');
    if any(is_out)
        scatter(c+jit(is_out), v_disp(is_out), 50, cond_colors(c,:), ...
            'LineWidth', 1.5);   % open circle = winsorised outlier
    end

    % Mean and SEM on RAW values
    m   = mean(v);
    sem = std(v)/sqrt(n_v);
    scatter(c, m, 100, 'k', 'filled');
    plot([c c],          [m-sem m+sem], 'k-', 'LineWidth', 2.5);
    plot([c-0.12 c+0.12],[m-sem m-sem], 'k-', 'LineWidth', 1.5);
    plot([c-0.12 c+0.12],[m+sem m+sem], 'k-', 'LineWidth', 1.5);
end

plot([0.4 4.6], [0 0], 'k--', 'LineWidth', 1.2);
ylim([y_lo - 0.05*abs(y_lo), y_hi + 0.05*abs(y_hi)]);
xlim([0.4 4.6]);
set(gca, 'XTick',1:4, 'XTickLabel',condition_labels(1:4), ...
    'XTickLabelRotation',15, 'FontSize',11);
ylabel('Slope (raw)', 'FontSize',13);
title(sprintf('Slope by Condition (mean±SEM, outliers Winsorised at ±%d SD, n=%d capped)', ...
    outlier_thresh, n_outliers_total), 'FontSize',11, 'FontWeight','bold');
grid on; box off; hold off;


%  FIGURE 4: Slope scatter — standardised (z-scored, Winsorised display)

figure('Color','w','Position',[50 200 850 460]);
hold on;

% z-score limits are symmetric by definition — use ±3
y_lo_z = -outlier_thresh;
y_hi_z =  outlier_thresh;

n_outliers_z = 0;
for c = 1:4
    v   = slope_z{c}(isfinite(slope_z{c}));
    n_v = numel(v);

    is_out = v < y_lo_z | v > y_hi_z;
    n_outliers_z = n_outliers_z + sum(is_out);
    v_disp = max(min(v, y_hi_z), y_lo_z);

    rng(c*11);
    jit = (rand(n_v,1)-0.5)*0.25;

    scatter(c+jit(~is_out), v_disp(~is_out), 40, cond_colors(c,:), 'filled');
    if any(is_out)
        scatter(c+jit(is_out), v_disp(is_out), 50, cond_colors(c,:), 'LineWidth', 1.5);
    end

    m   = mean(v);
    sem = std(v)/sqrt(n_v);
    scatter(c, m, 100, 'k', 'filled');
    plot([c c],          [m-sem m+sem], 'k-', 'LineWidth', 2.5);
    plot([c-0.12 c+0.12],[m-sem m-sem], 'k-', 'LineWidth', 1.5);
    plot([c-0.12 c+0.12],[m+sem m+sem], 'k-', 'LineWidth', 1.5);
end

plot([0.4 4.6], [0 0], 'k--', 'LineWidth', 1.2);
ylim([y_lo_z - 0.1, y_hi_z + 0.1]);
xlim([0.4 4.6]);
set(gca, 'XTick',1:4, 'XTickLabel',condition_labels(1:4), ...
    'XTickLabelRotation',15, 'FontSize',11);
ylabel('Slope (z-score)', 'FontSize',13);
title(sprintf('Slope by Condition (standardised, outliers Winsorised at ±%d SD)', ...
    outlier_thresh), 'FontSize',11, 'FontWeight','bold');
grid on; box off; hold off;


%  FIGURE 5: Arrow boxplot — Congruent vs Incongruent

arrow_labels = {'Congruent','Incongruent'};
arrow_colors = cond_colors(5:6,:);

figure('Color','w','Position',[500 200 480 460]);
hold on;

vals_arr = []; grp_arr = [];
for c = 1:2
    v = pse_data{4+c}(isfinite(pse_data{4+c}));
    vals_arr = [vals_arr; v(:)];
    grp_arr  = [grp_arr;  repmat(c, numel(v), 1)];
end

boxplot(vals_arr, grp_arr, ...
    'Labels',    arrow_labels, ...
    'Positions', 1:2, ...
    'Widths',    0.5, ...
    'Symbol',    '', ...
    'Colors',    'k');

h2 = findobj(gca, 'Tag', 'Box');
for c = 1:numel(h2)
    idx = numel(h2) - c + 1;
    patch(get(h2(c),'XData'), get(h2(c),'YData'), arrow_colors(idx,:), ...
        'FaceAlpha', 0.6, 'EdgeColor', 'k');
end

for c = 1:2
    v = pse_data{4+c}(isfinite(pse_data{4+c}));
    rng(c*17);
    jit = (rand(numel(v),1)-0.5)*0.2;
    scatter(c+jit, v(:), 35, arrow_colors(c,:), 'filled');
end

plot([0.4 2.6], [0.5 0.5], 'k--', 'LineWidth', 1.2);
ylim([0 1]); xlim([0.4 2.6]);
set(gca, 'XTick',1:2, 'XTickLabel',arrow_labels, ...
    'XTickLabelRotation',15, 'FontSize',12);
ylabel('Response Probability', 'FontSize',13);
title('Arrow: Congruent vs Incongruent', 'FontSize',13, 'FontWeight','bold');
grid on; box off; hold off;

fprintf('Done — five figures open.\n');


%% FUNCTION


function pse = fit_pse_cumgauss(x, probs)
    x     = double(x(:));
    probs = double(probs(:));
    probs = max(min(probs, 1-1e-4), 1e-4);
    p0    = [mean(x), std(x) + eps];
    obj   = @(p) sum((normcdf(x, p(1), abs(p(2))) - probs).^2);
    opts  = optimset('Display', 'off', 'TolX', 1e-8, 'TolFun', 1e-8);
    pfit  = fminsearch(obj, p0, opts);
    pse   = pfit(1);
end

%%
%  STATISTICS — run on RAW values
%  (z-scores are for visualisation only, not statistics)



fprintf('  STATISTICAL ANALYSES (raw values)\n');


cond_names_4 = {'Edge Size','Edge Contrast','Rotation Speed','Wheel Contrast'};
pairs        = nchoosek(1:4, 2);
n_pairs      = size(pairs, 1);


% 1. RM-ANOVA — raw PSE across 4 conditions

fprintf('\n--- Repeated Measures ANOVA: PSE (4 conditions, raw) ---\n');

n_subs    = numel(pse_data{1});
pse_mat   = NaN(n_subs, 4);
for c = 1:4
    v = pse_data{c}(:);
    if numel(v) == n_subs; pse_mat(:,c) = v; end
end
complete_rows = all(isfinite(pse_mat), 2);
pse_mat       = pse_mat(complete_rows, :);
n_complete    = sum(complete_rows);
fprintf('Subjects with complete PSE data: %d\n', n_complete);

if n_complete >= 3
    t_pse  = array2table(pse_mat, ...
        'VariableNames', {'EdgeSize','EdgeContrast','RotationSpeed','WheelContrast'});
    within = table({'EdgeSize';'EdgeContrast';'RotationSpeed';'WheelContrast'}, ...
        'VariableNames', {'Condition'});
    rm     = fitrm(t_pse, 'EdgeSize-WheelContrast ~ 1', 'WithinDesign', within);
    rmt    = ranova(rm, 'WithinModel', 'Condition');
    fprintf('\nRM-ANOVA results (PSE):\n'); disp(rmt);
    SS_cond = rmt.SumSq(1); SS_err = rmt.SumSq(2);
    fprintf('Partial eta-squared: %.3f\n', SS_cond/(SS_cond+SS_err));

    fprintf('\nPost-hoc pairwise comparisons (Bonferroni corrected):\n');
    fprintf('%-20s vs %-20s   t      df    p        p_bonf   sig\n','Cond A','Cond B');
    fprintf('%s\n', repmat('-',1,75));
    for pp = 1:n_pairs
        a = pairs(pp,1); b = pairs(pp,2);
        [~,p_val,~,stats] = ttest(pse_mat(:,a), pse_mat(:,b));
        p_bonf = min(p_val*n_pairs,1);
        sig = '';
        if p_bonf < 0.001; sig = '***'; elseif p_bonf < 0.01; sig = '**'; elseif p_bonf < 0.05; sig = '*'; end
        fprintf('%-20s vs %-20s   %.3f  %d   %.4f   %.4f   %s\n', ...
            cond_names_4{a}, cond_names_4{b}, stats.tstat, stats.df, p_val, p_bonf, sig);
    end
end


% 2. RM-ANOVA — raw Slope across 4 conditions

fprintf('\n--- Repeated Measures ANOVA: Slope (4 conditions, raw) ---\n');

n_subs     = numel(slope_data{1});
slope_mat  = NaN(n_subs, 4);
for c = 1:4
    v = slope_data{c}(:);
    if numel(v) == n_subs; slope_mat(:,c) = v; end
end
complete_rows = all(isfinite(slope_mat), 2);
slope_mat     = slope_mat(complete_rows, :);
n_complete    = sum(complete_rows);
fprintf('Subjects with complete Slope data: %d\n', n_complete);

if n_complete >= 3
    t_sl   = array2table(slope_mat, ...
        'VariableNames', {'EdgeSize','EdgeContrast','RotationSpeed','WheelContrast'});
    within = table({'EdgeSize';'EdgeContrast';'RotationSpeed';'WheelContrast'}, ...
        'VariableNames', {'Condition'});
    rm     = fitrm(t_sl, 'EdgeSize-WheelContrast ~ 1', 'WithinDesign', within);
    rmt    = ranova(rm, 'WithinModel', 'Condition');
    fprintf('\nRM-ANOVA results (Slope):\n'); disp(rmt);
    SS_cond = rmt.SumSq(1); SS_err = rmt.SumSq(2);
    fprintf('Partial eta-squared: %.3f\n', SS_cond/(SS_cond+SS_err));

    fprintf('\nPost-hoc pairwise comparisons (Bonferroni corrected):\n');
    fprintf('%-20s vs %-20s   t      df    p        p_bonf   sig\n','Cond A','Cond B');
    fprintf('%s\n', repmat('-',1,75));
    for pp = 1:n_pairs
        a = pairs(pp,1); b = pairs(pp,2);
        [~,p_val,~,stats] = ttest(slope_mat(:,a), slope_mat(:,b));
        p_bonf = min(p_val*n_pairs,1);
        sig = '';
        if p_bonf < 0.001; sig = '***'; elseif p_bonf < 0.01; sig = '**'; elseif p_bonf < 0.05; sig = '*'; end
        fprintf('%-20s vs %-20s   %.3f  %d   %.4f   %.4f   %s\n', ...
            cond_names_4{a}, cond_names_4{b}, stats.tstat, stats.df, p_val, p_bonf, sig);
    end
end


% 3. PAIRED T-TEST — Arrow Congruent vs Incongruent (response probability)

fprintf('\n--- Paired t-test: Arrow Congruent vs Incongruent ---\n');

con   = pse_data{5}(:);
incon = pse_data{6}(:);
n_min = min(numel(con), numel(incon));
con   = con(1:n_min); incon = incon(1:n_min);
valid = isfinite(con) & isfinite(incon);
con   = con(valid);   incon = incon(valid);
fprintf('Subjects with both Arrow conditions: %d\n', numel(con));

if numel(con) >= 3
    [~,p_arr,ci_arr,stats_arr] = ttest(con, incon);
    d_arr = mean(con-incon) / std(con-incon);
    fprintf('\nCongruent:   mean = %.4f,  SD = %.4f\n', mean(con),   std(con));
    fprintf('Incongruent: mean = %.4f,  SD = %.4f\n', mean(incon), std(incon));
    fprintf('t(%d) = %.3f,  p = %.4f\n', stats_arr.df, stats_arr.tstat, p_arr);
    fprintf('95%% CI of difference: [%.4f, %.4f]\n', ci_arr(1), ci_arr(2));
    fprintf('Cohen''s d = %.3f\n', d_arr);
    if p_arr < 0.001;    fprintf('Result: *** p < 0.001\n');
    elseif p_arr < 0.01; fprintf('Result: **  p < 0.01\n');
    elseif p_arr < 0.05; fprintf('Result: *   p < 0.05\n');
    else;                fprintf('Result: ns  p = %.4f\n', p_arr);
    end
end

fprintf('\n========================================\n');
fprintf('  ANALYSIS COMPLETE\n');
fprintf('========================================\n');
