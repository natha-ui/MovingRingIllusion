%  NonParametricAnalysis.m
%  FAILED normality → non-parametric:
%    PSE (Edge Size, Edge Contrast, Rotation Speed)
%    Slope (all 6 conditions)
%    → Wilcoxon signed-rank instead of t-test
%    → Friedman instead of RM-ANOVA
%    → Spearman instead of Pearson
%
%  PASSED normality → parametric (unchanged):
%    PSE (Wheel Contrast)
%    Arrow mean probability (Congruent, Incongruent)
%    → one-sample t-test
%    → paired t-test
%
%  Sections:
%   1.  Load data (same as StatisticsAnalysis.m)
%   2.  PSE: Wilcoxon signed-rank vs reference midpoint
%            (one-sample t-test for Wheel Contrast only)
%   3.  Sensitivity: Friedman test across 6 conditions
%       + Wilcoxon pairwise with Bonferroni correction
%   4.  Arrow sensitivity: Wilcoxon signed-rank cong vs incong
%   5.  Arrow individual slopes vs 0: Wilcoxon signed-rank
%   6.  Spearman correlations between slopes (all 6 conditions)
% =========================================================

clear; clc;

data_dir     = 'C:\Users\Nathan\Documents\Files\ReProj\Summary EyesPlusBehaviour';
subject_nums = [4 5 6 7 8 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 26 28 29 30 31 32 33 34 35 36];

PSE_col   = 1;
slope_col = 2;
n_levels  = 6;

cond_names_4 = {'Edge Size','Edge Contrast','Rotation Speed','Wheel Contrast'};
cond_names_6 = {'Edge Size','Edge Contrast','Rotation Speed','Wheel Contrast', ...
                'Arrow Congruent','Arrow Incongruent'};

% Which PSE conditions passed normality (parametric ok)
pse_normal = [false, false, false, true];   % Wheel Contrast passed

% Reference midpoints (mean of levels 3 & 4)
ref_x = zeros(1,4);

pse_data   = cell(1,6);
slope_data = cell(1,6);
arrow_probs_con   = [];
arrow_probs_incon = [];
for c=1:6; pse_data{c}=[]; slope_data{c}=[]; end

% LOAD

for s = subject_nums
    fname = fullfile(data_dir, sprintf('S%02d_BEHEyesAnonymMerge.mat',s));
    if ~isfile(fname); continue; end
    S = load(fname);
    if     isfield(S,'Data') && isfield(S.Data,'Behavioural');            B=S.Data.Behavioural;
    elseif isfield(S,'S') && isfield(S.S,'Data') && isfield(S.S.Data,'Behavioural'); B=S.S.Data.Behavioural;
    elseif isfield(S,'S') && isfield(S.S,'Behavioural');                  B=S.S.Behavioural;
    else; continue; end

    try
        p=double(B.EdgeSizeContrast.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pse_data{1}(end+1)=p(PSE_col); slope_data{1}(end+1)=p(slope_col);
        if ref_x(1)==0; x=double(B.EdgeSizeContrast.StimulusParameters.CONDA_EdgeSizRange(:))'; ref_x(1)=(x(3)+x(4))/2; end
    catch; end
    try
        p=double(B.EdgeSizeContrast.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        pse_data{2}(end+1)=p(PSE_col); slope_data{2}(end+1)=p(slope_col);
        if ref_x(2)==0; x=double(B.EdgeSizeContrast.StimulusParameters.CONDB_EdgeContrastRange(:))'; ref_x(2)=(x(3)+x(4))/2; end
    catch; end
    try
        p=double(B.EdgeSpeedWheel.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pse_data{3}(end+1)=p(PSE_col); slope_data{3}(end+1)=p(slope_col);
        if ref_x(3)==0; x=double(B.EdgeSpeedWheel.StimulusParameters.CONDC_SpeedConditionRange(:))'; ref_x(3)=(x(3)+x(4))/2; end
    catch; end
    try
        p=double(B.EdgeSpeedWheel.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        pse_data{4}(end+1)=p(PSE_col); slope_data{4}(end+1)=p(slope_col);
        if ref_x(4)==0; x=double(B.EdgeSpeedWheel.StimulusParameters.CONDD_WheelContrastRange(:))'; ref_x(4)=(x(3)+x(4))/2; end
    catch; end
    try
        probs=double(B.ArrowSizeAndCongruence.PsychometricProbabilitiesConditionsA_and_B);
        arrow_probs_con(end+1,:)   = probs(1,1:n_levels);
        arrow_probs_incon(end+1,:) = probs(2,1:n_levels);
        pc =double(B.ArrowSizeAndCongruence.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pin=double(B.ArrowSizeAndCongruence.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        slope_data{5}(end+1)=pc(slope_col);
        slope_data{6}(end+1)=pin(slope_col);
    catch; end
end

fprintf('Data loaded.\n');
for c=1:4; if ref_x(c)==0; ref_x(c)=NaN; end; end


%% 
%  SECTION 2 — PSE TESTS vs REFERENCE MIDPOINT


fprintf('\n========================================\n');
fprintf('  SECTION 2: PSE vs REFERENCE MIDPOINT\n');
fprintf('========================================\n');
fprintf('  (Wilcoxon signed-rank for non-normal; t-test for Wheel Contrast)\n\n');
fprintf('  %-18s  Ref       N    Median     Test statistic    p        sig\n','Condition');
fprintf('  %s\n',repmat('-',1,78));

for c = 1:4
    v   = pse_data{c}(isfinite(pse_data{c}));
    n_v = numel(v);
    if n_v < 3; continue; end
    ref = ref_x(c);

    if ~pse_normal(c)
        % Wilcoxon signed-rank: test median vs reference
        diffs = v(:) - ref;
        [p_w, h_w, stats_w] = signrank(diffs, 0, 'method','exact');
        fprintf('  %-18s  %.4f  %2d   %.4f     W=%-8.0f         %.4f   %s  [Wilcoxon]\n', ...
            cond_names_4{c}, ref, n_v, median(v), stats_w.signedrank, p_w, sig_str(p_w));
    else
        % Parametric t-test (Wheel Contrast passed normality)
        [~,p_t,~,st] = ttest(v, ref);
        fprintf('  %-18s  %.4f  %2d   %.4f     t(%d)=%.3f        %.4f   %s  [t-test]\n', ...
            cond_names_4{c}, ref, n_v, median(v), st.df, st.tstat, p_t, sig_str(p_t));
    end
end


%% 
%  SECTION 3 — SENSITIVITY: FRIEDMAN TEST (6 CONDITIONS)
%  + WILCOXON PAIRWISE WITH BONFERRONI CORRECTION

fprintf('  SECTION 3: SLOPE — FRIEDMAN + PAIRWISE WILCOXON\n');

% Build n x 6 slope matrix, complete cases only
n_s = max(cellfun(@numel, slope_data));
slope_mat = NaN(n_s, 6);
for c=1:6
    v=slope_data{c}(:);
    slope_mat(1:numel(v),c)=v;
end
complete  = all(isfinite(slope_mat),2);
slope_c   = slope_mat(complete,:);
n_comp    = sum(complete);
fprintf('Complete subjects: %d\n\n', n_comp);

fprintf('Slope medians:\n');
for c=1:6
    fprintf('  %-22s  Mdn=%.4f, IQR=%.4f\n', cond_names_6{c}, ...
        median(slope_c(:,c)), iqr(slope_c(:,c)));
end

if n_comp >= 3
    % Friedman test
    [p_fr, tbl_fr, stats_fr] = friedman(slope_c, 1, 'off');
    chi2_fr = tbl_fr{2,5};
    df_fr   = tbl_fr{2,3};
    fprintf('\nFriedman test: chi2(%d, n=%d) = %.3f, p = %.4f %s\n', ...
        df_fr, n_comp, chi2_fr, p_fr, sig_str(p_fr));

    % Effect size: Kendall W
    SS_t  = tbl_fr{2,2};
    SS_e  = tbl_fr{3,2};
    W_ken = chi2_fr / (n_comp * (6-1));
    fprintf('Kendall W = %.3f\n', W_ken);

    % Pairwise Wilcoxon with Bonferroni correction
    pairs   = nchoosek(1:6, 2);
    n_pairs = size(pairs,1);
    fprintf('\nBonferroni-corrected pairwise Wilcoxon signed-rank (n=%d comparisons):\n', n_pairs);
    fprintf('  %-22s vs %-22s  W          p        p_bonf   sig\n','Cond A','Cond B');
    fprintf('  %s\n', repmat('-',1,82));
    for pp = 1:n_pairs
        a = pairs(pp,1); b = pairs(pp,2);
        diffs = slope_c(:,a) - slope_c(:,b);
        [p_pw, ~, st_pw] = signrank(diffs, 0, 'method','approximate');
        p_bonf = min(p_pw * n_pairs, 1);
        fprintf('  %-22s vs %-22s  W=%-8.0f  %.4f   %.4f   %s\n', ...
            cond_names_6{a}, cond_names_6{b}, st_pw.signedrank, p_pw, p_bonf, sig_str(p_bonf));
    end
end


%% 
%  SECTION 4 — ARROW: WILCOXON SIGNED-RANK CONG vs INCONG
%  (Slopes non-normal → Wilcoxon instead of paired t-test)

fprintf('  SECTION 4: ARROW SLOPE — CONGRUENT vs INCONGRUENT\n');
fprintf('  (Wilcoxon signed-rank, slopes non-normal)\n');

sc5 = slope_data{5}(:);
sc6 = slope_data{6}(:);
n_m = min(numel(sc5), numel(sc6));
sc5 = sc5(1:n_m); sc6 = sc6(1:n_m);
valid = isfinite(sc5) & isfinite(sc6);
sc5 = sc5(valid); sc6 = sc6(valid);

fprintf('n = %d\n', numel(sc5));
fprintf('Congruent:   Mdn=%.4f, IQR=%.4f\n', median(sc5), iqr(sc5));
fprintf('Incongruent: Mdn=%.4f, IQR=%.4f\n', median(sc6), iqr(sc6));
diffs_ci = sc5 - sc6;
[p_ci, ~, st_ci] = signrank(diffs_ci, 0, 'method','approximate');
n_ci   = numel(diffs_ci);
mu_w   = n_ci*(n_ci+1)/4;
sig_w  = sqrt(n_ci*(n_ci+1)*(2*n_ci+1)/24);
z_ci   = (st_ci.signedrank - mu_w) / sig_w;
r_ci   = abs(z_ci) / sqrt(n_ci);
fprintf('Wilcoxon: W=%.0f, z=%.3f, p=%.4f %s\n', st_ci.signedrank, z_ci, p_ci, sig_str(p_ci));
fprintf('Effect size r = %.3f\n', r_ci);

%%
%  SECTION 5 — ARROW INDIVIDUAL SLOPES vs ZERO
%  Wilcoxon signed-rank (slopes non-normal)

fprintf('  SECTION 5: INDIVIDUAL ARROW SLOPES vs ZERO\n');
fprintf('  (Wilcoxon signed-rank, slopes non-normal)\n');


arrow_labels = {'Congruent','Incongruent'};
arrow_mats   = {arrow_probs_con, arrow_probs_incon};
x_c          = ((1:n_levels)' - mean(1:n_levels));

for ac = 1:2
    mat = arrow_mats{ac};
    if isempty(mat); continue; end
    valid_r = all(isfinite(mat), 2);
    mat     = mat(valid_r,:);
    n_r     = size(mat,1);
    ind_slopes = NaN(n_r,1);
    for si = 1:n_r
        y = mat(si,:)';
        ind_slopes(si) = x_c \ (y - mean(y));
    end
    fprintf('\n--- Arrow %s (n=%d) ---\n', arrow_labels{ac}, n_r);
    fprintf('  Mdn=%.4f, IQR=%.4f, range [%.4f, %.4f]\n', ...
        median(ind_slopes), iqr(ind_slopes), min(ind_slopes), max(ind_slopes));
    [p_sl, ~, st_sl] = signrank(ind_slopes, 0, 'method','approximate');
    mu_ws  = n_r*(n_r+1)/4;
    sig_ws = sqrt(n_r*(n_r+1)*(2*n_r+1)/24);
    z_sl   = (st_sl.signedrank - mu_ws) / sig_ws;
    r_sl   = abs(z_sl) / sqrt(n_r);
    fprintf('  vs zero: W=%.0f, z=%.3f, p=%.4f %s, r=%.3f\n', ...
        st_sl.signedrank, z_sl, p_sl, sig_str(p_sl), r_sl);
end


%% 
%  SECTION 6 — SPEARMAN CORRELATIONS BETWEEN SLOPES
%  (All slope variables non-normal → Spearman instead of Pearson)


fprintf('  SECTION 6: SLOPE CORRELATIONS (Spearman rho)\n');


if n_comp >= 3
    [R_sp, P_sp] = corr(slope_c, 'Type','Spearman');
    short = {'EdSz','EdCo','RtSp','WhCo','ArCo','ArIn'};
    fprintf('\n  rho values (lower triangle) with significance:\n');
    fprintf('  %-6s',''); fprintf('%-12s', short{:}); fprintf('\n');
    fprintf('  %s\n', repmat('-',1,78));
    for i = 1:6
        fprintf('  %-6s', short{i});
        for j = 1:6
            if i==j;  fprintf('%-12s','—');
            elseif j>i; fprintf('%-12s','');
            else
                s='';
                if P_sp(i,j)<0.001; s='***'; elseif P_sp(i,j)<0.01; s='**'; elseif P_sp(i,j)<0.05; s='*'; end
                fprintf('r=%.2f%s     ', R_sp(i,j), s);
            end
        end
        fprintf('\n');
    end
end



fprintf('  ALL NON-PARAMETRIC ANALYSES COMPLETE\n');



%% 
%  LOCAL FUNC
function s = sig_str(p)
    if p<0.001; s='***'; elseif p<0.01; s='**'; elseif p<0.05; s='*'; else; s='ns'; end
end
