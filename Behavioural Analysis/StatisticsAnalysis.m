%  StatisticsAnalysis.m
%
%  Sections:
%   0.  Load data
%   1.  Demographics
%   2.  Normality tests (Shapiro-Wilk, behavioural DVs only)
%   3.  PSE one-sample t-tests vs reference midpoint
%   4.  Sensitivity (slope) one-way RM-ANOVA across 6 conditions
%       + Bonferroni pairwise t-tests
%   5.  Arrow sensitivity: paired t-test congruent vs incongruent
%   6.  Arrow individual slopes: one-sample t-tests vs 0
%   7.  Pearson correlations between slopes of all 6 conditions
%   8.  Eye tracking: 2-way RM-ANOVA (Condition x Level)
%       for saccade amplitude, saccade count, gaze ratio


clear; clc;

data_dir     = '.';
subject_nums = [4 5 6 7 8 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 26 28 29 30 31 32 33 34 35 36];

PSE_col   = 1;
slope_col = 2;
n_levels  = 6;

cond_names_4 = {'Edge Size','Edge Contrast','Rotation Speed','Wheel Contrast'};
cond_names_6 = {'Edge Size','Edge Contrast','Rotation Speed','Wheel Contrast','Arrow Congruent','Arrow Incongruent'};

% Eye tracking sub-condition mapping
eye_subcond_names = { ...
    {'Arrow Congruent',  'Arrow Incongruent'}, ...
    {'Edge Size',        'Edge Contrast'    }, ...
    {'Rotation Speed',   'Wheel Contrast'   }  ...
};
eye_cond_fields = {'AW','EC','SW'};
n_eye_conds = 3;
idx_A = 1:2:12;
idx_B = 2:2:12;

% Reference midpoint values (mean of levels 3 & 4 in actual stimulus units)
% Loaded from data below — defined here as fallback
ref_x_fallback = [mean([0.072 0.107]), mean([0.70 0.80]), ...
                  mean([1.39  2.37 ]), mean([0.70 0.80])];


pse_data   = cell(1,6);
slope_data = cell(1,6);
arrow_probs_con   = [];
arrow_probs_incon = [];
ref_x      = zeros(1,4);

% Eye tracking: {cond, subcond}(subj, level)
sacc_amp = cell(n_eye_conds,2);
sacc_n   = cell(n_eye_conds,2);
gaze_rat = cell(n_eye_conds,2);
for ec=1:n_eye_conds; for sc=1:2
    sacc_amp{ec,sc}=[]; sacc_n{ec,sc}=[]; gaze_rat{ec,sc}=[];
end; end

for c=1:6; pse_data{c}=[]; slope_data{c}=[]; end

ages=[]; females=0; right_handed=0; left_handed=0; ambidextrous=0;
subj_labels={}; subj_labels_eye={};


% LOAD

for s = subject_nums
    fname = fullfile(data_dir, sprintf('S%02d_BEHEyesAnonymMerge.mat',s));
    if ~isfile(fname); continue; end
    S = load(fname);

    if     isfield(S,'Data') && isfield(S.Data,'Behavioural');            B=S.Data.Behavioural;
    elseif isfield(S,'S') && isfield(S.S,'Data') && isfield(S.S.Data,'Behavioural'); B=S.S.Data.Behavioural;
    elseif isfield(S,'S') && isfield(S.S,'Behavioural');                  B=S.S.Behavioural;
    else; continue; end

    subj_labels{end+1} = sprintf('S%02d',s);

    % Demographics
    try
        P=S.S.ParticipantInfoAnonymised;
        try; ages(end+1)=double(P.Age); catch; end
        try; if strcmpi(strtrim(char(P.Sex)),'F'); females=females+1; end; catch; end
        try
            h=strtrim(char(P.Handedness));
            if strcmpi(h,'R'); right_handed=right_handed+1;
            elseif strcmpi(h,'L'); left_handed=left_handed+1;
            else; ambidextrous=ambidextrous+1; end
        catch; end
    catch; end

    % Behavioural
    try
        p=double(B.EdgeSizeContrast.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pse_data{1}(end+1)=p(PSE_col); slope_data{1}(end+1)=p(slope_col);
        if ref_x(1)==0
            x=double(B.EdgeSizeContrast.StimulusParameters.CONDA_EdgeSizRange(:))';
            ref_x(1)=(x(3)+x(4))/2;
        end
    catch; end
    try
        p=double(B.EdgeSizeContrast.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        pse_data{2}(end+1)=p(PSE_col); slope_data{2}(end+1)=p(slope_col);
        if ref_x(2)==0
            x=double(B.EdgeSizeContrast.StimulusParameters.CONDB_EdgeContrastRange(:))';
            ref_x(2)=(x(3)+x(4))/2;
        end
    catch; end
    try
        p=double(B.EdgeSpeedWheel.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pse_data{3}(end+1)=p(PSE_col); slope_data{3}(end+1)=p(slope_col);
        if ref_x(3)==0
            x=double(B.EdgeSpeedWheel.StimulusParameters.CONDC_SpeedConditionRange(:))';
            ref_x(3)=(x(3)+x(4))/2;
        end
    catch; end
    try
        p=double(B.EdgeSpeedWheel.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        pse_data{4}(end+1)=p(PSE_col); slope_data{4}(end+1)=p(slope_col);
        if ref_x(4)==0
            x=double(B.EdgeSpeedWheel.StimulusParameters.CONDD_WheelContrastRange(:))';
            ref_x(4)=(x(3)+x(4))/2;
        end
    catch; end
    try
        probs=double(B.ArrowSizeAndCongruence.PsychometricProbabilitiesConditionsA_and_B);
        arrow_probs_con(end+1,:)   = probs(1,1:n_levels);
        arrow_probs_incon(end+1,:) = probs(2,1:n_levels);
        pc =double(B.ArrowSizeAndCongruence.PsychometricFitParametersA_EdgeSize_PSE_Slope(:));
        pi2=double(B.ArrowSizeAndCongruence.PsychometricFitParametersA_EdgeContrast_PSE_Slope(:));
        slope_data{5}(end+1)=pc(slope_col);
        slope_data{6}(end+1)=pi2(slope_col);
    catch; end

    % Eye tracking
    try
        if     isfield(S,'S') && isfield(S.S,'Data') && isfield(S.S.Data,'EyeMovements'); E=S.S.Data.EyeMovements;
        elseif isfield(S,'Data') && isfield(S.Data,'EyeMovements'); E=S.Data.EyeMovements;
        else; E=[]; end
        if ~isempty(E)
            subj_labels_eye{end+1}=sprintf('S%02d',s);
            ns_eye=numel(subj_labels_eye);
            for ec=1:n_eye_conds
                cf=eye_cond_fields{ec};
                if ~isfield(E,cf); continue; end
                cd2=E.(cf);
                for sc=1:2
                    si_vec = sc:2:2*n_levels;
                    sacc_amp{ec,sc}(ns_eye,:) = NaN;
                    sacc_n{ec,sc}(ns_eye,:)   = NaN;
                    gaze_rat{ec,sc}(ns_eye,:) = NaN;
                    for lv=1:n_levels
                        k=si_vec(lv);
                        try; sacc_amp{ec,sc}(ns_eye,lv)=double(cd2.Saccades(k).MeanAmplitude); catch; end
                        try; sacc_n{ec,sc}(ns_eye,lv)  =double(cd2.Saccades(k).NumberRecorded); catch; end
                        try
                            hm=double(cd2.GazeMap(k).Heatmap);
                            half=floor(size(hm,2)/2);
                            gaze_rat{ec,sc}(ns_eye,lv)=sum(sum(hm(:,half+1:end)))/(sum(hm(:))+eps);
                        catch; end
                    end
                end
            end
        end
    catch; end
end

n_beh = numel(subj_labels);
n_eye = numel(subj_labels_eye);
fprintf('Loaded %d behavioural, %d eye tracking subjects\n', n_beh, n_eye);
% Use fallback reference if not loaded from data
for c=1:4; if ref_x(c)==0; ref_x(c)=ref_x_fallback(c); end; end


%% 
%  SECTION 1 — DEMOGRAPHICS

fprintf('  SECTION 1: DEMOGRAPHICS\n');
fprintf('N = %d\n', n_beh);
if ~isempty(ages)
    fprintf('Age:        M = %.1f, SD = %.1f, range %d-%d\n', ...
        mean(ages),std(ages),min(ages),max(ages));
    fprintf('Female:     %d / %d (%.0f%%)\n', females, n_beh, 100*females/n_beh);
    fprintf('Handedness: R=%d, L=%d, Ambidextrous=%d\n', right_handed,left_handed,ambidextrous);
end


%% 
%  SECTION 2 — NORMALITY TESTS (Shapiro-Wilk)
%  Behavioural DVs only: PSE x4, slope x6, arrow probs x2


fprintf('  SECTION 2: NORMALITY TESTS (Anderson-Darling)\n');
fprintf('  %-35s  n      p        normal?\n','Variable');
fprintf('  %s\n',repmat('-',1,62));

norm_vars={};  norm_labels={};

for c=1:4
    v=pse_data{c}(isfinite(pse_data{c}));
    norm_vars{end+1}=v(:);
    norm_labels{end+1}=sprintf('PSE — %s',cond_names_4{c});
end
for c=1:6
    v=slope_data{c}(isfinite(slope_data{c}));
    norm_vars{end+1}=v(:);
    norm_labels{end+1}=sprintf('Slope — %s',cond_names_6{c});
end
if ~isempty(arrow_probs_con)
    norm_vars{end+1}=mean(arrow_probs_con,  2,'omitnan');
    norm_labels{end+1}='Arrow Cong mean prob';
    norm_vars{end+1}=mean(arrow_probs_incon,2,'omitnan');
    norm_labels{end+1}='Arrow Incong mean prob';
end

n_non=0;
fprintf('  Note: values beyond ±3 SD excluded before testing (failed fits).\n\n');
for ni=1:numel(norm_vars)
    v=norm_vars{ni}(isfinite(norm_vars{ni}));
    if numel(v)<3; fprintf('  %-35s  too few\n',norm_labels{ni}); continue; end

    % Remove values beyond ±3 SD (failed psychometric extrapolations)
    n_raw    = numel(v);
    v_clean  = v(abs(v - mean(v)) <= 3*std(v));
    n_excl   = n_raw - numel(v_clean);
    if numel(v_clean)<3
        fprintf('  %-35s  too few after exclusion\n',norm_labels{ni}); continue;
    end

    try
        [~, p_ad] = adtest(v_clean);
        flag='yes';
        if p_ad<0.05; flag='NO *';  n_non=n_non+1; end
        if p_ad<0.01; flag='NO **'; end
        excl_note = '';
        if n_excl>0; excl_note=sprintf(' (excl. %d)',n_excl); end
        fprintf('  %-35s  n=%-3d  p=%.4f   %s%s\n', ...
            norm_labels{ni}, numel(v_clean), p_ad, flag, excl_note);
    catch ME3
        fprintf('  %-35s  adtest failed: %s\n',norm_labels{ni},ME3.message);
    end
end
fprintf('\n  %d / %d variables depart from normality (p<.05)\n',n_non,numel(norm_vars));
fprintf('  Non-normal → Wilcoxon / Friedman / Spearman alternatives\n');


%% 
%  SECTION 3 — PSE ONE-SAMPLE T-TESTS vs REFERENCE MIDPOINT

fprintf('  SECTION 3: PSE T-TESTS vs REFERENCE MIDPOINT\n');
fprintf('\n  %-18s  Ref       N   M ± SD               t       df   p        sig\n','Condition');
fprintf('  %s\n',repmat('-',1,82));
for c=1:4
    v=pse_data{c}(isfinite(pse_data{c}));
    n=numel(v);
    if n<3; continue; end
    [~,p,~,st]=ttest(v,ref_x(c));
    fprintf('  %-18s  %.4f  %2d  %.4f ± %.4f   %7.3f %3d  %.4f  %s\n',...
        cond_names_4{c},ref_x(c),n,mean(v),std(v),st.tstat,st.df,p,sig_str(p));
end


%% 
%  SECTION 4 — SENSITIVITY: ONE-WAY RM-ANOVA (6 CONDITIONS)
%  + BONFERRONI PAIRWISE T-TESTS

fprintf('  SECTION 4: SLOPE RM-ANOVA + PAIRWISE COMPARISONS\n');


% Build subject x 6 slope matrix
n_s = n_beh;
slope_mat = NaN(n_s,6);
for c=1:6
    v=slope_data{c}(:);
    slope_mat(1:numel(v),c)=v;
end
complete = all(isfinite(slope_mat),2);
slope_c  = slope_mat(complete,:);
n_comp   = sum(complete);
fprintf('Complete subjects: %d\n',n_comp);

% Descriptives
fprintf('\nSlope descriptives:\n');
fprintf('  %-22s  M = %.4f, SD = %.4f\n');
for c=1:6
    fprintf('  %-22s  M=%.4f, SD=%.4f\n',cond_names_6{c},mean(slope_c(:,c)),std(slope_c(:,c)));
end

if n_comp>=3
    t_sl=array2table(slope_c,'VariableNames',{'EdSz','EdCo','RtSp','WhCo','ArCo','ArIn'});
    within=table({'EdSz';'EdCo';'RtSp';'WhCo';'ArCo';'ArIn'},'VariableNames',{'Condition'});
    rm=fitrm(t_sl,'EdSz-ArIn ~ 1','WithinDesign',within);
    rmt=ranova(rm,'WithinModel','Condition');
    fprintf('\nRM-ANOVA (Slope, 6 conditions):\n'); disp(rmt);
    SS_c=rmt.SumSq(1); SS_e=rmt.SumSq(2);
    fprintf('Partial eta-squared: %.3f\n',SS_c/(SS_c+SS_e));

    pairs=nchoosek(1:6,2); n_pairs=size(pairs,1);
    fprintf('\nBonferroni pairwise t-tests (n=%d comparisons):\n',n_pairs);
    fprintf('  %-22s vs %-22s  t      df   p        p_bonf   sig\n','Cond A','Cond B');
    fprintf('  %s\n',repmat('-',1,80));
    for pp=1:n_pairs
        a=pairs(pp,1); b=pairs(pp,2);
        [~,p_v,~,st]=ttest(slope_c(:,a),slope_c(:,b));
        p_b=min(p_v*n_pairs,1);
        fprintf('  %-22s vs %-22s  %6.3f %3d  %.4f   %.4f   %s\n',...
            cond_names_6{a},cond_names_6{b},st.tstat,st.df,p_v,p_b,sig_str(p_b));
    end
end


%% 
%  SECTION 5 — ARROW SENSITIVITY: PAIRED T-TEST CONG vs INCONG

fprintf('  SECTION 5: ARROW SLOPE — CONGRUENT vs INCONGRUENT\n');

sc5=slope_data{5}(:); sc6=slope_data{6}(:);
n_min=min(numel(sc5),numel(sc6));
sc5=sc5(1:n_min); sc6=sc6(1:n_min);
valid=isfinite(sc5)&isfinite(sc6);
sc5=sc5(valid); sc6=sc6(valid);
fprintf('n = %d\n',numel(sc5));
fprintf('Congruent:   M=%.4f, SD=%.4f\n',mean(sc5),std(sc5));
fprintf('Incongruent: M=%.4f, SD=%.4f\n',mean(sc6),std(sc6));
[~,p_ci,ci_ci,st_ci]=ttest(sc5,sc6);
d_ci=mean(sc5-sc6)/std(sc5-sc6);
fprintf('Paired t-test: t(%d)=%.3f, p=%.4f %s\n',st_ci.df,st_ci.tstat,p_ci,sig_str(p_ci));
fprintf('95%% CI: [%.4f, %.4f], Cohen''s d=%.3f\n',ci_ci(1),ci_ci(2),d_ci);


%% 
%  SECTION 6 — ARROW INDIVIDUAL SLOPES: ONE-SAMPLE T-TEST vs 0
%  Slope fitted to each participant's 6-level probability profile

fprintf('  SECTION 6: INDIVIDUAL ARROW SLOPES vs ZERO\n');

arrow_labels={'Congruent','Incongruent'};
arrow_mats={arrow_probs_con, arrow_probs_incon};
x_c=((1:n_levels)'-mean(1:n_levels));

for ac=1:2
    mat=arrow_mats{ac};
    if isempty(mat); continue; end
    valid_r=all(isfinite(mat),2);
    mat=mat(valid_r,:);
    n_r=size(mat,1);
    ind_slopes=NaN(n_r,1);
    for si=1:n_r
        y=mat(si,:)';
        ind_slopes(si)=x_c\(y-mean(y));
    end
    fprintf('\n--- Arrow %s (n=%d) ---\n',arrow_labels{ac},n_r);
    fprintf('  M=%.4f, SD=%.4f, range [%.4f, %.4f]\n',...
        mean(ind_slopes),std(ind_slopes),min(ind_slopes),max(ind_slopes));
    [~,p_sl,ci_sl,st_sl]=ttest(ind_slopes,0);
    fprintf('  vs zero: t(%d)=%.3f, p=%.4f %s\n',st_sl.df,st_sl.tstat,p_sl,sig_str(p_sl));
    fprintf('  95%% CI: [%.4f, %.4f]\n',ci_sl(1),ci_sl(2));
end


%% 
%  SECTION 7 — PEARSON CORRELATIONS BETWEEN SLOPES (6 CONDITIONS)

fprintf('  SECTION 7: SLOPE CORRELATIONS (Pearson r)\n');

if n_comp>=3
    [R,P]=corr(slope_c,'Type','Pearson');
    short={'EdSz','EdCo','RtSp','WhCo','ArCo','ArIn'};
    fprintf('\n  r values (lower triangle) with significance:\n');
    fprintf('  %-6s','['); 
    fprintf(']%-10s',short{:}); fprintf('\n');
    fprintf('  %s\n',repmat('-',1,68));
    for i=1:6
        fprintf('  %-6s',short{i});
        for j=1:6
            if i==j; fprintf('%-10s','—');
            elseif j>i; fprintf('%-10s','');
            else
                s='';
                if P(i,j)<0.001; s='***'; elseif P(i,j)<0.01; s='**'; elseif P(i,j)<0.05; s='*'; end
                fprintf('r=%.2f%s   ',R(i,j),s);
            end
        end
        fprintf('\n');
    end
end



%  SECTION 8 — EYE TRACKING: 2-WAY RM-ANOVA
%  Condition x Level for saccade amplitude, count, gaze ratio
%  Conditions mapped: EC→{Edge Size, Edge Contrast}
%                     SW→{Rotation Speed, Wheel Contrast}
%                     AW→{Arrow Congruent, Arrow Incongruent}

fprintf('  SECTION 8: EYE TRACKING RM-ANOVAs\n');

dv_names  = {'Saccade Amplitude','Saccade Count','Gaze Ratio'};
dv_cells  = {sacc_amp, sacc_n, gaze_rat};

for dv=1:3
    data_all=dv_cells{dv};
    fprintf('\n--- %s ---\n',dv_names{dv});

    for ec=1:n_eye_conds
        for sc=1:2
            cname=eye_subcond_names{ec}{sc};
            matA=data_all{ec,sc};
            if isempty(matA); continue; end

            % For 2-way RM-ANOVA we need sub-cond as second within factor
            % Here: one condition (sc) x 6 levels
            % Build subjects x 6 matrix
            n_s2=size(matA,1);
            compl=all(isfinite(matA),2);
            mat_c=matA(compl,:);
            n_c2=sum(compl);
            if n_c2<3; continue; end

            fprintf('\n  %s (n=%d):\n',cname,n_c2);
            fprintf('  Level means: ');
            fprintf('%.2f ', mean(mat_c,1,'omitnan')); fprintf('\n');

            % One-way RM-ANOVA across levels
            vnames=arrayfun(@(i)sprintf('L%d',i),1:n_levels,'UniformOutput',false);
            t_e=array2table(mat_c,'VariableNames',vnames);
            within_lv=table((1:n_levels)','VariableNames',{'Level'});
            try
                rm_e=fitrm(t_e,'L1-L6~1','WithinDesign',within_lv);
                rmt_e=ranova(rm_e,'WithinModel','Level');
                % Extract Level effect (row 3 = (Intercept):Level)
                F_lv=rmt_e.F(3); p_lv=rmt_e.pValue(3);
                df1=rmt_e.DF(3); df2=rmt_e.DF(4);
                ss_f=rmt_e.SumSq(3); ss_e2=rmt_e.SumSq(4);
                eta2=ss_f/(ss_f+ss_e2);
                fprintf('  Level effect: F(%d,%d)=%.3f, p=%.4f %s, eta2p=%.3f\n',...
                    df1,df2,F_lv,p_lv,sig_str(p_lv),eta2);
            catch ME2
                fprintf('  RM-ANOVA failed: %s\n',ME2.message);
            end
        end
    end
end



fprintf('  ALL ANALYSES COMPLETE\n');



%% 
%  LOCAL FUNC

function s = sig_str(p)
    if p<0.001; s='***'; elseif p<0.01; s='**'; elseif p<0.05; s='*'; else; s='ns'; end
end

function [p, W] = sw_test(x)
    % Shapiro-Wilk test (Royston 1992 approximation, n=3 to 5000)
    x  = sort(x(:));
    n  = numel(x);
    m  = norminv(((1:n)'-0.375)/(n+0.25));
    c  = m/sqrt(m'*m);
    W  = max(0, min(1, (c'*x)^2 / sum((x-mean(x)).^2)));
    if n<=11
        mu    = polyval([0.0038915 -0.083751 -0.31082 -1.5861], log(n));
        sigma = exp(polyval([0.00135823 -0.0006714 -0.0020322 0.13086], log(n)));
    else
        mu    = polyval([0.00001118 -0.0023987 -0.12668 0.68448], log(log(n)));
        sigma = exp(polyval([0.00001353 -0.0048021 0.056576 0.0], log(n)));
    end
    z = (log(1-W+eps)-mu)/sigma;
    p = max(0, min(1, 1-normcdf(z)));
end
