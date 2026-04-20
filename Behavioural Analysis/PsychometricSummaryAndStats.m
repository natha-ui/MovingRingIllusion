%  PsychometricSummaryAndStats.m

%  1.  Group mean psychometric functions — max and min values
%  2.  Figure: PSE boxplots (4 intrinsic conditions, y = response
%      probability) + Sensitivity boxplots (all 6 conditions,
%      y = two versions of normalised gradient) as subplots
%  3.  PSE t-tests vs reference midpoint (4 conditions)
%  4.  Sensitivity RM-ANOVA across levels within each condition
%  5.  Sensitivity RM-ANOVA across all 6 conditions
%      + Bonferroni-corrected Wilcoxon pairwise
%  6.  Arrow response probability vs chance (paired t-tests)
%  7.  Congruent arrow responder classification (binomial)
%  8.  Spearman correlations between condition sensitivities


clear; clc; close all;

data_dir     = '.';
subject_nums = [4 5 6 7 8 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 26 28 29 30 31 32 33 34 35 36];

PSE_col   = 1;
slope_col = 2;
n_levels  = 6;

cond_names_4 = {'Edge Size','Edge Contrast','Rotation Speed','Wheel Contrast'};
cond_names_6 = {'Edge Size','Edge Contrast','Rotation Speed','Wheel Contrast', ...
                'Arrow Congruent','Arrow Incongruent'};

% Actual stimulus x-values — loaded from data during load loop below
% Initialised here with correct task-script values as fallback
stim_x = { ...
    [0.01  0.02  0.04  0.06  0.08  0.10 ], ...  % Edge Size (proportion)
    [0.25  0.30  0.35  0.40  0.45  0.50 ], ...  % Edge Contrast
    [0.004 0.006 0.008 0.010 0.020 0.040], ...  % Rotation Speed (rot/frame)
    [0.25  0.30  0.35  0.40  0.45  0.50 ], ...  % Wheel Contrast
    [0.54  0.63  0.72  0.81  0.90  0.99 ], ...  % Arrow Congruent
    [0.54  0.63  0.72  0.81  0.90  0.99 ]  ...  % Arrow Incongruent
};

x_labels = { ...
    'Edge Width (°)', 'Contrast', 'Rotation Speed (rot/s)', ...
    'Contrast', 'Arrow Size (prop)', 'Arrow Size (prop)' ...
};

col = [ ...
    0.20 0.45 0.75; ...
    0.55 0.75 0.95; ...
    0.15 0.60 0.35; ...
    0.55 0.85 0.55; ...
    0.85 0.25 0.25; ...
    0.95 0.60 0.45; ...
];


all_probs  = cell(1,6);   % raw observed probs per subject
all_fitted = cell(1,6);   % fitted probs (obs - resid) per subject
pse_data   = cell(1,6);
slope_data = cell(1,6);
arrow_probs_con   = [];
arrow_probs_incon = [];
ref_x = zeros(1,4);

for c=1:6
    all_probs{c}={}; all_fitted{c}={};
    pse_data{c}=[]; slope_data{c}=[];
end

%% Load
for s = subject_nums
    fname = fullfile(data_dir, sprintf('S%02d_BEHEyesAnonymMerge.mat',s));
    if ~isfile(fname); continue; end
    S = load(fname);
    if     isfield(S,'Data') && isfield(S.Data,'Behavioural');            B=S.Data.Behavioural;
    elseif isfield(S,'S') && isfield(S.S,'Data') && isfield(S.S.Data,'Behavioural'); B=S.S.Data.Behavioural;
    elseif isfield(S,'S') && isfield(S.S,'Behavioural');                  B=S.S.Behavioural;
    else; continue; end

    % Condition 1: Edge Size
    try
        x_ec = double(B.EdgeSizeContrast.StimulusParameters.CONDA_EdgeSizRange(:))';
        if numel(x_ec)==6; stim_x{1}=x_ec; end
        prob  = double(B.EdgeSizeContrast.PsychometricProbabilitiesConditionsA_and_B(1,:));
        resid = double(B.EdgeSizeContrast.PsychometricFitResidualsA_EdgeSize(:))';
        all_probs{1}{end+1}=prob; all_fitted{1}{end+1}=prob-resid;
        p=double(B.EdgeSizeContrast.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pse_data{1}(end+1)=p(PSE_col); slope_data{1}(end+1)=p(slope_col);
        if ref_x(1)==0; ref_x(1)=(x_ec(3)+x_ec(4))/2; end
    catch; end

    % Condition 2: Edge Contrast
    try
        x_ec2 = double(B.EdgeSizeContrast.StimulusParameters.CONDB_EdgeContrastRange(:))';
        if numel(x_ec2)==6; stim_x{2}=x_ec2; end
        prob  = double(B.EdgeSizeContrast.PsychometricProbabilitiesConditionsA_and_B(2,:));
        resid = double(B.EdgeSizeContrast.PsychometricFitResidualsA_EdgeContrast(:))';
        all_probs{2}{end+1}=prob; all_fitted{2}{end+1}=prob-resid;
        p=double(B.EdgeSizeContrast.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        pse_data{2}(end+1)=p(PSE_col); slope_data{2}(end+1)=p(slope_col);
        if ref_x(2)==0; ref_x(2)=(x_ec2(3)+x_ec2(4))/2; end
    catch; end

    % Condition 3: Rotation Speed
    try
        x_sp = double(B.EdgeSpeedWheel.StimulusParameters.CONDC_SpeedConditionRange(:))';
        if numel(x_sp)==6; stim_x{3}=x_sp; end
        prob  = double(B.EdgeSpeedWheel.PsychometricProbabilitiesConditionsA_and_B(1,:));
        resid = double(B.EdgeSpeedWheel.PsychometricFitResidualsA_EdgeSize(:))';
        all_probs{3}{end+1}=prob; all_fitted{3}{end+1}=prob-resid;
        p=double(B.EdgeSpeedWheel.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pse_data{3}(end+1)=p(PSE_col); slope_data{3}(end+1)=p(slope_col);
        if ref_x(3)==0; ref_x(3)=(x_sp(3)+x_sp(4))/2; end
    catch; end

    % Condition 4: Wheel Contrast
    try
        x_wh = double(B.EdgeSpeedWheel.StimulusParameters.CONDD_WheelContrastRange(:))';
        if numel(x_wh)==6; stim_x{4}=x_wh; end
        prob  = double(B.EdgeSpeedWheel.PsychometricProbabilitiesConditionsA_and_B(2,:));
        resid = double(B.EdgeSpeedWheel.PsychometricFitResidualsA_EdgeContrast(:))';
        all_probs{4}{end+1}=prob; all_fitted{4}{end+1}=prob-resid;
        p=double(B.EdgeSpeedWheel.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        pse_data{4}(end+1)=p(PSE_col); slope_data{4}(end+1)=p(slope_col);
        if ref_x(4)==0; ref_x(4)=(x_wh(3)+x_wh(4))/2; end
    catch; end

    % Conditions 5-6: Arrow
    try
        probs=double(B.ArrowSizeAndCongruence.PsychometricProbabilitiesConditionsA_and_B);
        prob5=probs(1,1:n_levels); prob6=probs(2,1:n_levels);
        res5=double(B.ArrowSizeAndCongruence.PsychometricFitResidualsA_EdgeSize(:))';
        res6=double(B.ArrowSizeAndCongruence.PsychometricFitResidualsA_EdgeContrast(:))';
        all_probs{5}{end+1}=prob5; all_fitted{5}{end+1}=prob5-res5;
        all_probs{6}{end+1}=prob6; all_fitted{6}{end+1}=prob6-res6;
        arrow_probs_con(end+1,:)   = prob5;
        arrow_probs_incon(end+1,:) = prob6;
        pc =double(B.ArrowSizeAndCongruence.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pin=double(B.ArrowSizeAndCongruence.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        slope_data{5}(end+1)=pc(slope_col);
        slope_data{6}(end+1)=pin(slope_col);
    catch; end
end

n_subj = numel(all_probs{1});
fprintf('Loaded %d subjects\n', n_subj);
for c=1:4; if ref_x(c)==0; ref_x(c)=NaN; end; end



%  1. GROUP MEAN PSYCH function max and min

fprintf('\n========================================\n');
fprintf('  GROUP MEAN PSYCHOMETRIC FUNCTION RANGE\n');
fprintf('========================================\n');
fprintf('  %-22s  Min (Lv1)   Max (Lv6)   Range\n','Condition');
fprintf('  %s\n',repmat('-',1,56));

grp_mean_fitted = cell(1,6);
for c=1:6
    if isempty(all_fitted{c}); continue; end
    fm = cell2mat(cellfun(@(v) v(:)', all_fitted{c}, 'UniformOutput',false)');
    grp_mean_fitted{c} = mean(fm, 1, 'omitnan');
    mn = min(grp_mean_fitted{c});
    mx = max(grp_mean_fitted{c});
    fprintf('  %-22s  %.4f      %.4f      %.4f\n', cond_names_6{c}, mn, mx, mx-mn);
end



%  COMPUTE SENSITIVITY METRICS

sens_A = cell(1,6);

for c=1:6
    vA = NaN(numel(all_fitted{c}),1);
    for si=1:numel(all_fitted{c})
        f=all_fitted{c}{si};
        if numel(f)>=6 && all(isfinite(f))
            vA(si) = (f(6)-f(1)) / 6;
        end
    end
    sens_A{c} = vA(isfinite(vA));
end



%  COMPUTE PSE AS NORMALISED PROPORTION
%  Log-space normalisation for log-spaced conditions
%  (Edge Size c=1, Rotation Speed c=3):
%    prop = (log(PSE) - log(xmin)) / (log(xmax) - log(xmin))
%  Linear normalisation for linearly-spaced conditions:
%    prop = (PSE - xmin) / (xmax - xmin)
%  Reference midpoint gets same treatment for t-test alignment.

use_log_norm = [true, false, true, false];  % c=1 EdSz, c=3 RtSp

pse_prob = cell(1,4);
ref_prop = 0.5 * ones(1,4);   % reference always maps to exactly 0.5

for c=1:4
    xr   = stim_x{c};
    xmin = xr(1); xmax = xr(end);
    ref  = ref_x(c);

    vals = NaN(numel(all_fitted{c}),1);
    for si=1:numel(all_fitted{c})
        f=all_fitted{c}{si}(:);
        x=xr(:);
        d05=f-0.5;
        cr=find(d05(1:end-1).*d05(2:end)<=0,1,'first');
        if ~isempty(cr)
            x0=x(cr); x1=x(cr+1); f0=f(cr); f1=f(cr+1);
            if abs(f1-f0)>1e-9
                pse_val = x0+(0.5-f0)*(x1-x0)/(f1-f0);
            else
                pse_val=(x0+x1)/2;
            end
            % Normalise: reference → 0.5 in appropriate space
            if use_log_norm(c) && pse_val>0 && ref>0
                log_range = log(xmax) - log(xmin);
                vals(si) = 0.5 + (log(pse_val) - log(ref)) / log_range;
            else
                lin_range = xmax - xmin;
                vals(si) = 0.5 + (pse_val - ref) / lin_range;
            end
        end
    end
    pse_prob{c} = vals(isfinite(vals));
end



%  FIGURE: PSE AND SENSITIVITY BOXPLOTS
% LEFT = PSE, RIGHT = SENSITIVITY

figure('Color','w','Position',[50 50 1300 530]);

% --- LEFT: PSE ---
ax1 = subplot(1,2,1);
hold(ax1,'on');

for c=1:4
    v = pse_prob{c};
    if numel(v)<2; continue; end
    draw_box(ax1, v, c, col(c,:), 0.35);
end

% Single reference line at 0.5 — applies to all conditions
plot(ax1,[0.4 4.7],[0.5 0.5],'k--','LineWidth',1.5);

set(ax1,'XTick',1:4,'XTickLabel',cond_names_4,'XTickLabelRotation',15, ...
    'FontSize',9,'Box','off','YLim',[-0.15 1.15],'YTick',-0.5:0.25:1.5);
ylabel(ax1,'PSE (normalised, reference = 0.5)','FontSize',11);
title(ax1,'Point of Subjective Equality','FontSize',12,'FontWeight','bold');
grid(ax1,'on'); hold(ax1,'off');


ax2 = subplot(1,2,2);
hold(ax2,'on');

for c=1:6
    vA = sens_A{c};
    if numel(vA)>=2; draw_box(ax2, vA, c, col(c,:), 0.35); end
end

plot(ax2,[0.4 6.6],[0 0],'k--','LineWidth',1.0);

set(ax2,'XTick',1:6,'XTickLabel',cond_names_6,'XTickLabelRotation',15, ...
    'FontSize',9,'Box','off');
ylabel(ax2,'Sensitivity (prob/level)','FontSize',11);
title(ax2,'Sensitivity','FontSize',12,'FontWeight','bold');
grid(ax2,'on'); hold(ax2,'off');

sgtitle('PSE and Sensitivity by Condition','FontSize',13,'FontWeight','bold');



%  PSYCHOMETRIC GRADIENT DESCRIPTIVES

fprintf('\n========================================\n');
fprintf('  PSYCHOMETRIC GRADIENT DESCRIPTIVES\n');
fprintf('  Sensitivity = (p6 - p1) / 6\n');
fprintf('========================================\n');
fprintf('\n  %-22s  N    Mean     SD       Median   IQR      Min      Max\n','Condition');
fprintf('  %s\n',repmat('-',1,80));
for c=1:6
    v=sens_A{c}(isfinite(sens_A{c}));
    if numel(v)<2; continue; end
    q=quantile(v,[0.25 0.50 0.75]);
    fprintf('  %-22s  %2d   %.4f   %.4f   %.4f   %.4f   %.4f   %.4f\n', ...
        cond_names_6{c},numel(v),mean(v),std(v),q(2),q(3)-q(1),min(v),max(v));
end



%  PSE DESCRIPTIVES

fprintf('  PSE DESCRIPTIVES (normalised, reference = 0.5)\n');
fprintf('\n  %-18s  N    Mean     SD       Median   IQR\n','Condition');
fprintf('  %s\n',repmat('-',1,60));
for c=1:4
    v=pse_prob{c}(isfinite(pse_prob{c}));
    if numel(v)<2; continue; end
    q=quantile(v,[0.25 0.50 0.75]);
    fprintf('  %-18s  %2d   %.4f   %.4f   %.4f   %.4f\n', ...
        cond_names_4{c},numel(v),mean(v),std(v),q(2),q(3)-q(1));
end


%  3. PSE T-TESTS vs REFERENCE MIDPOINT
fprintf('  SECTION 3: PSE T-TESTS vs REFERENCE\n');
fprintf('  (Log-space normalised for Edge Size, Rotation Speed)\n');
fprintf('\n  %-18s  Ref    N    Mean ± SD              t       df   p        sig\n','Condition');
fprintf('  %s\n',repmat('-',1,78));

for c=1:4
    v = pse_prob{c};
    v = v(isfinite(v));
    n_v = numel(v);
    if n_v<3; continue; end
    ref_p = ref_prop(c);
    [~,p_t,~,st] = ttest(v, ref_p);
    fprintf('  %-18s  %.3f  %2d   %.4f ± %.4f         %6.3f %3d  %.4f  %s\n', ...
        cond_names_4{c}, ref_p, n_v, mean(v), std(v), st.tstat, st.df, p_t, sig_str(p_t));
end



%  4. SENSITIVITY RM-ANOVA ACROSS LEVELS WITHIN EACH CONDITION
%  Uses raw observed response probabilities per level

fprintf('  SECTION 4: SENSITIVITY RM-ANOVA ACROSS LEVELS\n');

for c=1:6
    if isempty(all_probs{c}); continue; end
    pm = cell2mat(cellfun(@(v) v(:)', all_probs{c}, 'UniformOutput',false)');
    compl = all(isfinite(pm),2);
    pm_c  = pm(compl,:);
    n_c   = sum(compl);
    if n_c<3; continue; end

    vnames = arrayfun(@(i)sprintf('L%d',i),1:n_levels,'UniformOutput',false);
    t_l  = array2table(pm_c,'VariableNames',vnames);
    wdes = table((1:n_levels)','VariableNames',{'Level'});
    try
        rm  = fitrm(t_l,'L1-L6~1','WithinDesign',wdes);
        rmt = ranova(rm,'WithinModel','Level');
        F_l = rmt.F(3); p_l = rmt.pValue(3);
        df1 = rmt.DF(3); df2 = rmt.DF(4);
        eta2 = rmt.SumSq(3)/(rmt.SumSq(3)+rmt.SumSq(4));
        fprintf('\n%s (n=%d): F(%d,%d)=%.3f, p=%.4f %s, eta2p=%.3f\n', ...
            cond_names_6{c},n_c,df1,df2,F_l,p_l,sig_str(p_l),eta2);
        fprintf('  Level means: '); fprintf('%.3f ', mean(pm_c,1)); fprintf('\n');
    catch ME
        fprintf('\n%s: RM-ANOVA failed — %s\n',cond_names_6{c},ME.message);
    end
end



%  5. SENSITIVITY RM-ANOVA ACROSS ALL 6 CONDITIONS
%  + BONFERRONI WILCOXON PAIRWISE
%  Uses Version A sensitivity metric: (p6-p1)/6

fprintf('  SECTION 5: SENSITIVITY RM-ANOVA ACROSS CONDITIONS\n');

n_s = max(cellfun(@numel, sens_A));
smat = NaN(n_s,6);
for c=1:6; v=sens_A{c}(:); smat(1:numel(v),c)=v; end
compl = all(isfinite(smat),2);
smat_c = smat(compl,:); n_comp = sum(compl);
fprintf('Complete subjects: %d\n',n_comp);
fprintf('Median sensitivities (Version A):\n');
for c=1:6
    fprintf('  %-22s  Mdn=%.4f, IQR=%.4f\n',cond_names_6{c},median(smat_c(:,c)),iqr(smat_c(:,c)));
end

if n_comp>=3
    vnames6={'EdSz','EdCo','RtSp','WhCo','ArCo','ArIn'};
    t6=array2table(smat_c,'VariableNames',vnames6);
    w6=table(vnames6','VariableNames',{'Condition'});
    try
        rm6  = fitrm(t6,'EdSz-ArIn~1','WithinDesign',w6);
        rmt6 = ranova(rm6,'WithinModel','Condition');
        F6=rmt6.F(3); p6=rmt6.pValue(3); df16=rmt6.DF(3); df26=rmt6.DF(4);
        eta6=rmt6.SumSq(3)/(rmt6.SumSq(3)+rmt6.SumSq(4));
        fprintf('\nRM-ANOVA across conditions: F(%d,%d)=%.3f, p=%.4f %s, eta2p=%.3f\n', ...
            df16,df26,F6,p6,sig_str(p6),eta6);
    catch ME2
        fprintf('RM-ANOVA failed: %s\n',ME2.message);
    end

    pairs = nchoosek(1:6,2); n_pairs=size(pairs,1);
    fprintf('\nBonferroni-corrected pairwise Wilcoxon (n=%d):\n',n_pairs);
    fprintf('  %-22s vs %-22s  W        p        p_bonf   sig\n','A','B');
    fprintf('  %s\n',repmat('-',1,80));
    for pp=1:n_pairs
        a=pairs(pp,1); b=pairs(pp,2);
        d=smat_c(:,a)-smat_c(:,b); n_d=numel(d);
        [p_w,~,st_w]=signrank(d,0,'method','approximate');
        p_b=min(p_w*n_pairs,1);
        mu_w=n_d*(n_d+1)/4; sg_w=sqrt(n_d*(n_d+1)*(2*n_d+1)/24);
        z_w=(st_w.signedrank-mu_w)/sg_w;
        fprintf('  %-22s vs %-22s  W=%-6.0f  %.4f   %.4f   %s\n', ...
            cond_names_6{a},cond_names_6{b},st_w.signedrank,p_w,p_b,sig_str(p_b));
    end
end


%  6. ARROW RESPONSE PROBABILITY vs CHANCE (0.5)
%  Paired t-tests for congruent and incongruent separately
%  across all participants (mean prob at each level vs 0.5)

fprintf('  SECTION 6: ARROW PROB vs CHANCE\n');

for ac=1:2
    if ac==1; mat=arrow_probs_con;  lbl='Congruent';
    else;     mat=arrow_probs_incon; lbl='Incongruent'; end
    if isempty(mat); continue; end
    compl_a = all(isfinite(mat),2);
    mat_a = mat(compl_a,:);
    n_a = size(mat_a,1);
    fprintf('\n--- Arrow %s (n=%d) ---\n',lbl,n_a);
    fprintf('  %-8s  M       SD      t      df  p        sig\n','Level');
    for lv=1:n_levels
        v_lv = mat_a(:,lv);
        [~,p_lv,~,st_lv]=ttest(v_lv,0.5);
        fprintf('  Lv %-4d  %.4f  %.4f  %6.3f %3d %.4f   %s\n', ...
            lv,mean(v_lv),std(v_lv),st_lv.tstat,st_lv.df,p_lv,sig_str(p_lv));
    end
    % Overall mean across levels
    mean_all = mean(mat_a(:));
    [~,p_all,~,st_all]=ttest(mean(mat_a,2),0.5);
    fprintf('  Overall:  M=%.4f, t(%d)=%.3f, p=%.4f %s\n', ...
        mean_all,st_all.df,st_all.tstat,p_all,sig_str(p_all));
end

%  7. CONGRUENT RESPONDER CLASSIFICATION (BINOMIAL TEST)
%  Responder = mean response probability > 0.5 across all levels


fprintf('  SECTION 7: CONGRUENT RESPONDER CLASSIFICATION\n');


if ~isempty(arrow_probs_con)
    compl_r = all(isfinite(arrow_probs_con),2);
    mat_r   = arrow_probs_con(compl_r,:);
    n_r     = size(mat_r,1);
    mean_per_subj = mean(mat_r,2);
    n_responders  = sum(mean_per_subj > 0.5);
    fprintf('N = %d\n',n_r);
    fprintf('Responders (mean prob > 0.5): %d / %d (%.1f%%)\n', ...
        n_responders, n_r, 100*n_responders/n_r);
    % Binomial test: is proportion of responders > 0.5?
    p_binom = 2 * min(binocdf(n_responders,n_r,0.5), ...
                      1-binocdf(n_responders-1,n_r,0.5));  % two-tailed
    fprintf('Binomial test vs p=0.5: p=%.4f %s\n',p_binom,sig_str(p_binom));

    % Also per level
    fprintf('\nPer-level responder counts:\n');
    fprintf('  %-8s  Responders   %%     Binomial p\n','Level');
    for lv=1:n_levels
        n_resp_lv = sum(mat_r(:,lv)>0.5);
        p_bl = 2*min(binocdf(n_resp_lv,n_r,0.5),1-binocdf(n_resp_lv-1,n_r,0.5));
        fprintf('  Lv %-4d  %2d / %2d       %.1f%%   %.4f %s\n', ...
            lv,n_resp_lv,n_r,100*n_resp_lv/n_r,p_bl,sig_str(p_bl));
    end
end



%  8. SPEARMAN CORRELATIONS BETWEEN CONDITION SENSITIVITIES

fprintf('  SECTION 8: SPEARMAN CORRELATIONS (Sensitivity, Version A)\n');

if n_comp>=3
    [R_sp,P_sp]=corr(smat_c,'Type','Spearman');
    short={'EdSz','EdCo','RtSp','WhCo','ArCo','ArIn'};
    fprintf('\n  rho (lower triangle), * p<.05  ** p<.01  *** p<.001\n');
    fprintf('  %-6s',''); fprintf('%-12s',short{:}); fprintf('\n');
    fprintf('  %s\n',repmat('-',1,78));
    for i=1:6
        fprintf('  %-6s',short{i});
        for j=1:6
            if i==j; fprintf('%-12s','—');
            elseif j>i; fprintf('%-12s','');
            else
                s='';
                if P_sp(i,j)<0.001; s='***';
                elseif P_sp(i,j)<0.01; s='**';
                elseif P_sp(i,j)<0.05; s='*'; end
                fprintf('r=%.2f%-3s   ',R_sp(i,j),s);
            end
        end
        fprintf('\n');
    end
end


fprintf('\n========================================\n');
fprintf('  ALL ANALYSES COMPLETE\n');
fprintf('========================================\n');


%% =========================================================
%  LOCAL FUNCTIONS


function draw_box(ax, v, xpos, c, bw)
    % Strip chart + IQR box + median + mean±SEM
    % bw = box half-width
    v   = v(isfinite(v));
    n_v = numel(v);
    if n_v<2; return; end

    % Winsorise at ±2 SD
    vm=mean(v); vs=std(v);
    lo=vm-2*vs; hi=vm+2*vs;
    is_out=v<lo|v>hi;
    vd=max(min(v,hi),lo);

    rng(round(abs(xpos)*7+1));
    jit=(rand(n_v,1)-0.5)*bw*0.9;
    scatter(ax,xpos-bw*0.1+jit(~is_out),vd(~is_out),18,c,'filled', ...
        'MarkerFaceAlpha',0.45,'Parent',ax);
    if any(is_out)
        scatter(ax,xpos-bw*0.1+jit(is_out),vd(is_out),22,c,'LineWidth',1.2,'Parent',ax);
    end

    q=quantile(vd,[0.25 0.50 0.75]);
    q1=max(q(1),lo); q3=min(q(3),hi); q2=max(min(q(2),hi),lo);
    if q3>q1
        rectangle('Parent',ax,'Position',[xpos+bw*0.15, q1, bw*0.65, q3-q1], ...
            'FaceColor',[c 0.28],'EdgeColor',c*0.70,'LineWidth',1.4);
    end
    plot(ax,[xpos+bw*0.15 xpos+bw*0.80],[q2 q2],'-','Color',c*0.55,'LineWidth',2.2);

    v_in=v(~is_out);
    m=mean(v_in); sem=std(v_in)/sqrt(numel(v_in));
    md=max(min(m,hi),lo);
    plot(ax,xpos+bw*1.15,md,'o','MarkerSize',6,'MarkerFaceColor','w', ...
        'MarkerEdgeColor',c*0.55,'LineWidth',1.8,'Parent',ax);
    plot(ax,[xpos+bw*1.15 xpos+bw*1.15],[max(md-sem,lo) md+sem],'-', ...
        'Color',c*0.55,'LineWidth',1.8,'Parent',ax);
    plot(ax,[xpos+bw*0.90 xpos+bw*1.40],[max(md-sem,lo) max(md-sem,lo)],'-', ...
        'Color',c*0.55,'LineWidth',1.3,'Parent',ax);
    plot(ax,[xpos+bw*0.90 xpos+bw*1.40],[md+sem md+sem],'-', ...
        'Color',c*0.55,'LineWidth',1.3,'Parent',ax);
end

function s = sig_str(p)
    if p<0.001; s='***'; elseif p<0.01; s='**'; elseif p<0.05; s='*'; else; s='ns'; end
end
