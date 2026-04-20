%  EyeTrackingFigures.m

%  Figure 1: Saccade Amplitude — strip chart across all 6 conditions
%  Figure 2: Saccade Count    — strip chart across all 6 conditions
%  Figure 3: Gaze Heatmaps   — Level 1 vs Level 6 per condition
%            Each condition shown as a colour-blended overlay:
%            Level 1 = cool colour, Level 6 = warm colour
%            All 6 conditions in one figure (2 rows x 6 cols)



clear; clc; close all;

data_dir     = '.';
subject_nums = [4 5 6 7 8 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 26 28 29 30 31 32 33 34 35 36];

% Block fields and sub-condition mapping to actual conditions
block_fields = {'EC',         'EC',            'SW',             'SW',              'AW',              'AW'            };
block_sc     = [1,            2,               1,                2,                 1,                 2               ];
cond_names   = {'Edge Size',  'Edge Contrast', 'Rotation Speed', 'Wheel Contrast',  'Arrow Congruent', 'Arrow Incong.' };
cond_short   = {'EdSz',       'EdCo',          'RtSp',           'WhCo',            'ArCo',            'ArIn'          };

col = [ ...
    0.20 0.45 0.75; ...   % Edge Size
    0.55 0.75 0.95; ...   % Edge Contrast
    0.15 0.60 0.35; ...   % Rotation Speed
    0.55 0.85 0.55; ...   % Wheel Contrast
    0.85 0.25 0.25; ...   % Arrow Congruent
    0.95 0.60 0.45; ...   % Arrow Incongruent
];

n_cond   = 6;
n_levels = 6;
n_sets   = 12;
idx_A    = 1:2:n_sets;
idx_B    = 2:2:n_sets;

% Saccades per condition: subjects x levels
sacc_amp_cond = cell(1, n_cond);
sacc_n_cond   = cell(1, n_cond);
sacc_amp_lv1  = cell(1, n_cond);   % level 1 per subject
sacc_amp_lv6  = cell(1, n_cond);   % level 6 per subject
sacc_n_lv1    = cell(1, n_cond);
sacc_n_lv6    = cell(1, n_cond);
for c = 1:n_cond
    sacc_amp_cond{c}=[]; sacc_n_cond{c}=[];
    sacc_amp_lv1{c}=[]; sacc_amp_lv6{c}=[];
    sacc_n_lv1{c}=[];   sacc_n_lv6{c}=[];
end

% Heatmaps: {cond}(level) = group average heatmap
grp_hmap   = cell(n_cond, n_levels);
grp_hmap_n = zeros(n_cond, n_levels);

subj_labels = {};
n_subj      = 0;


% LOAD DATA
for s = subject_nums
    fname = fullfile(data_dir, sprintf('S%02d_BEHEyesAnonymMerge.mat', s));
    if ~isfile(fname); continue; end
    S = load(fname);

    if     isfield(S,'Data') && isfield(S.Data,'EyeMovements');           E=S.Data.EyeMovements;
    elseif isfield(S,'S') && isfield(S.S,'Data') && isfield(S.S.Data,'EyeMovements'); E=S.S.Data.EyeMovements;
    else;  fprintf('  S%02d: EyeMovements not found\n',s); continue; end

    n_subj = n_subj + 1;
    subj_labels{end+1} = sprintf('S%02d', s);

    for c = 1:n_cond
        bf = block_fields{c};
        sc = block_sc(c);
        if ~isfield(E, bf); continue; end
        cd = E.(bf);

        % Set indices for this sub-condition
        if sc == 1; set_indices = idx_A; else; set_indices = idx_B; end

        amp_row = NaN(1, n_levels);
        n_row   = NaN(1, n_levels);

        for lv = 1:n_levels
            k = set_indices(lv);

            % Saccades
            try
                amp_row(lv) = double(cd.Saccades(k).MeanAmplitude);
                n_row(lv)   = double(cd.Saccades(k).NumberRecorded);
            catch
                try
                    amp_row(lv) = double(cd.Saccades.MeanAmplitude(k));
                    n_row(lv)   = double(cd.Saccades.NumberRecorded(k));
                catch; end
            end

            % Heatmap
            try
                hm = double(cd.GazeMap(k).Heatmap);
                if isempty(grp_hmap{c,lv})
                    grp_hmap{c,lv} = hm;
                else
                    if ~isequal(size(hm), size(grp_hmap{c,lv}))
                        hm = imresize(hm, size(grp_hmap{c,lv}));
                    end
                    grp_hmap{c,lv} = grp_hmap{c,lv} + hm;
                end
                grp_hmap_n(c,lv) = grp_hmap_n(c,lv) + 1;
            catch; end
        end

        % Store per-level amplitude and count for this subject
        amp_row_full = amp_row;   % keep full 6-level row
        n_row_full   = n_row;

        if all(isfinite(amp_row))
            sacc_amp_cond{c}(end+1) = mean(amp_row);
            sacc_n_cond{c}(end+1)   = mean(n_row);
        end

        % Level 1 and level 6 means per subject
        if isfinite(amp_row(1));   sacc_amp_lv1{c}(end+1) = amp_row(1); end
        if isfinite(amp_row(end)); sacc_amp_lv6{c}(end+1) = amp_row(end); end
        if isfinite(n_row(1));     sacc_n_lv1{c}(end+1)   = n_row(1); end
        if isfinite(n_row(end));   sacc_n_lv6{c}(end+1)   = n_row(end); end
    end
end

fprintf('Loaded %d subjects\n', n_subj);

% Normalise group heatmaps
for c = 1:n_cond
    for lv = 1:n_levels
        if grp_hmap_n(c,lv) > 0
            grp_hmap{c,lv} = grp_hmap{c,lv} / grp_hmap_n(c,lv);
        end
    end
end



%%  SHARED STRIP-CHART HELPER

function draw_strip(ax, vals, xpos, c, outlier_sd)
    v   = vals(isfinite(vals));
    n_v = numel(v);
    if n_v < 2; return; end

    vm = mean(v); vs = std(v);
    lo = vm - outlier_sd*vs;
    hi = vm + outlier_sd*vs;
    is_out = v < lo | v > hi;
    vd     = max(min(v, hi), lo);

    rng(round(xpos) * 7);
    jit = (rand(n_v,1)-0.5)*0.22;

    scatter(ax, xpos-0.08+jit(~is_out), vd(~is_out), 26, c,'filled','MarkerFaceAlpha',0.55,'Parent',ax);
    if any(is_out)
        scatter(ax, xpos-0.08+jit(is_out), vd(is_out), 30, c,'LineWidth',1.5,'Parent',ax);
    end

    q   = quantile(vd,[0.25 0.50 0.75]);
    q1d = max(q(1),lo); q3d = min(q(3),hi); q2d = max(min(q(2),hi),lo);
    if q3d>q1d
        rectangle('Parent',ax,'Position',[xpos+0.05 q1d 0.16 q3d-q1d],...
            'FaceColor',[c 0.28],'EdgeColor',c*0.70,'LineWidth',1.5);
    end
    plot(ax,[xpos+0.05 xpos+0.21],[q2d q2d],'-','Color',c*0.55,'LineWidth',2.5);

    v_in  = v(~is_out);
    m     = mean(v_in);
    sem   = std(v_in)/sqrt(numel(v_in));
    md    = max(min(m,hi),lo);
    plot(ax, xpos+0.30, md,'o','MarkerSize',7,'MarkerFaceColor','w',...
        'MarkerEdgeColor',c*0.55,'LineWidth',2);
    plot(ax,[xpos+0.30 xpos+0.30],[max(md-sem,lo) md+sem],'-','Color',c*0.55,'LineWidth',2);
    plot(ax,[xpos+0.22 xpos+0.38],[max(md-sem,lo) max(md-sem,lo)],'-','Color',c*0.55,'LineWidth',1.5);
    plot(ax,[xpos+0.22 xpos+0.38],[md+sem md+sem],'-','Color',c*0.55,'LineWidth',1.5);
end




%  FIGURES 1+2: SACCADE AMPLITUDE AND COUNT — side-by-side subplots
%  Main strip: overall mean (across all levels) per condition
%  Level 1 mean: short horizontal tick in desaturated colour
%  Level 6 mean: short horizontal tick in full saturated colour

figure('Color','w','Position',[50 200 780 500]);

dv_labels  = {'Saccade Amplitude (°)', 'Saccade Count'};
dv_overall = {sacc_amp_cond, sacc_n_cond};
dv_lv1     = {sacc_amp_lv1,  sacc_n_lv1};
dv_lv6     = {sacc_amp_lv6,  sacc_n_lv6};

for dv = 1:2
    ax = subplot(1,2,dv);
    hold(ax,'on');

    for c = 1:n_cond
        v_all = dv_overall{dv}{c}(isfinite(dv_overall{dv}{c}));
        n_v   = numel(v_all);
        if n_v < 2; continue; end

        % Winsorise
        vm = mean(v_all); vs = std(v_all);
        lo = vm - 2*vs;   hi = vm + 2*vs;
        is_out = v_all < lo | v_all > hi;
        vd     = max(min(v_all, hi), lo);

        % Jittered dots (overall mean)
        rng(c * 7);
        jit = (rand(n_v,1)-0.5)*0.20;
        scatter(ax, c-0.08+jit(~is_out), vd(~is_out), 22, col(c,:),'filled','MarkerFaceAlpha',0.45);
        if any(is_out)
            scatter(ax, c-0.08+jit(is_out), vd(is_out), 26, col(c,:),'LineWidth',1.5);
        end

        % IQR box + median
        q   = quantile(vd,[0.25 0.50 0.75]);
        q1d = max(q(1),lo); q3d = min(q(3),hi); q2d = max(min(q(2),hi),lo);
        if q3d > q1d
            rectangle('Parent',ax,'Position',[c+0.04 q1d 0.14 q3d-q1d],...
                'FaceColor',[col(c,:) 0.25],'EdgeColor',col(c,:)*0.70,'LineWidth',1.4);
        end
        plot(ax,[c+0.04 c+0.18],[q2d q2d],'-','Color',col(c,:)*0.55,'LineWidth',2.2);

        % Overall mean ± SEM (open circle)
        v_in = v_all(~is_out);
        m   = mean(v_in); sem = std(v_in)/sqrt(numel(v_in));
        md  = max(min(m,hi),lo);
        plot(ax, c+0.27, md,'o','MarkerSize',6,'MarkerFaceColor','w',...
            'MarkerEdgeColor',col(c,:)*0.55,'LineWidth',1.8);
        plot(ax,[c+0.27 c+0.27],[max(md-sem,lo) md+sem],'-','Color',col(c,:)*0.55,'LineWidth',1.8);
        plot(ax,[c+0.21 c+0.33],[max(md-sem,lo) max(md-sem,lo)],'-','Color',col(c,:)*0.55,'LineWidth',1.3);
        plot(ax,[c+0.21 c+0.33],[md+sem md+sem],'-','Color',col(c,:)*0.55,'LineWidth',1.3);

    end

    set(ax,'XTick',1:n_cond,'XTickLabel',cond_names,'XTickLabelRotation',18,...
        'FontSize',8,'Box','off');
    ylabel(ax, dv_labels{dv},'FontSize',10);
    title(ax, dv_labels{dv},'FontSize',11,'FontWeight','bold');
    xlim(ax,[0.4 n_cond+0.5]);
    grid(ax,'on'); hold(ax,'off');
end

sgtitle('Saccade Measures by Condition','FontSize',11,'FontWeight','bold');



%% 
%  FIGURE 3: GAZE HEATMAPS — Level 1 vs Level 6
%  overlaid on the actual stimulus background
%
%  Background built from MotionIllusionTaskDevB.m parameters:
%  Overlay:
%    Level 1 gaze → desaturated condition colour (alpha blend)
%    Level 6 gaze → saturated condition colour  (alpha blend)
%  Both shown in same panel — where they overlap colours mix.



% --- Screen / stimulus geometry (MotionIllusionTaskDevB.m) ---
SCR_W = 1920; SCR_H = 1080;
StimSz  = 384;
StmAr   = 2.25;
radVec_bg = [0.45 0.70];
numSeg_bg = 4;
Hz_bg     = 120;
nFr_bg    = round(0.75 * Hz_bg);
frame_show = round(0.10 * Hz_bg);   % t = 0.10 s

edgeSizCond_bg  = [0.01 0.02 0.04 0.06 0.08 0.10];
edgeConCond_bg  = [0.25 0.30 0.35 0.40 0.45 0.50];
speedCond_bg    = [0.004 0.006 0.008 0.010 0.020 0.040];
wheelConCond_bg = [0.25 0.30 0.35 0.40 0.45 0.50];
mnConEdge_bg  = mean(edgeConCond_bg(3:4));
mnConWhl_bg   = mean(wheelConCond_bg(3:4));
edgeSzRef_bg  = mean(edgeSizCond_bg(3:4));
radSpdRef_bg  = mean(speedCond_bg(3:4));
baseGryRef_bg = [0.5-mnConWhl_bg 0.5+mnConWhl_bg ...
                 0.5-mnConEdge_bg 0.5+mnConEdge_bg];

% Combined stimulus layout (cStimBoth in task, then transposed)
% After transpose: (cmbH x cmbW) = (384 x 864), centred on screen
cmbH_px = StimSz;                    % 384
cmbW_px = round(StimSz * StmAr);    % 864
lftCols_scr = 1:StimSz;             % left stim cols in cStimBoth'
rgtCols_scr = round((StmAr-1)*StimSz) + lftCols_scr;  % 481:864

% Screen positions of stimulus centres
scr_xL = round(SCR_W/2 - cmbW_px/2) + StimSz/2;       % 720
scr_xR = round(SCR_W/2 - cmbW_px/2) + rgtCols_scr(1) + StimSz/2 - 1;  % 1200
scr_y  = SCR_H/2;                                        % 540

% Fixed display canvas resolution (16:9 preserves ring shape)
DISP_W = 960; DISP_H = 540;
dsx = DISP_W / SCR_W;   % 0.5
dsy = DISP_H / SCR_H;   % 0.5  (equal → no squish)

% Ring parameters in display canvas pixels
r_inner_d = radVec_bg(1) * StimSz/2 * dsx;   % 43.2 px
r_outer_d = radVec_bg(2) * StimSz/2 * dsx;   % 67.2 px
cxL_d     = scr_xL * dsx;   % 360
cxR_d     = scr_xR * dsx;   % 600
cy_d      = scr_y  * dsy;   % 270

% --- Build grey background canvas at DISP_W x DISP_H ---
bg_grey = ones(DISP_H, DISP_W) * 0.50;

% Generate actual stimulus (or fallback to ring outline)
stim_placed = false;
try
    IM_ref = WheelSpinRadialb(StimSz, numSeg_bg, radVec_bg, edgeSzRef_bg, ...
                               baseGryRef_bg, nFr_bg, radSpdRef_bg, 1);
    stim_fr = IM_ref(:,:,frame_show);   % 384x384, values 0-1

    % Place two copies into canvas (matches task layout after transpose)
    stim_d  = imresize(stim_fr, [round(StimSz*dsy), round(StimSz*dsx)]);
    % canvas rows and cols for each stimulus
    r1d = round(cy_d - size(stim_d,1)/2);
    r2d = r1d + size(stim_d,1) - 1;
    c1L = round(cxL_d - size(stim_d,2)/2);
    c2L = c1L + size(stim_d,2) - 1;
    c1R = round(cxR_d - size(stim_d,2)/2);
    c2R = c1R + size(stim_d,2) - 1;

    if r1d>=1 && r2d<=DISP_H && c1L>=1 && c2L<=DISP_W && c1R>=1 && c2R<=DISP_W
        bg_grey(r1d:r2d, c1L:c2L) = stim_d;
        bg_grey(r1d:r2d, c1R:c2R) = stim_d;
        stim_placed = true;
        fprintf('Stimulus placed on background.\n');
    end
catch ME
    fprintf('WheelSpinRadialb unavailable (%s) — using ring outlines.\n', ME.message);
end

if ~stim_placed
    % Fallback: draw ring annuli slightly lighter than background
    [XX_d, YY_d] = meshgrid(1:DISP_W, 1:DISP_H);
    dL = sqrt((XX_d-cxL_d).^2 + (YY_d-cy_d).^2);
    dR = sqrt((XX_d-cxR_d).^2 + (YY_d-cy_d).^2);
    ring_d = (dL>=r_inner_d & dL<=r_outer_d) | (dR>=r_inner_d & dR<=r_outer_d);
    bg_grey(ring_d) = 0.63;
end

% Fixation dot (small filled circle, like the task oval)
fix_r_d  = max(2, round(3 * dsx));
fcx_d = round(DISP_W/2); fcy_d = round(DISP_H/2);
[XX_d, YY_d] = meshgrid(1:DISP_W, 1:DISP_H);
fix_dot = sqrt((XX_d-fcx_d).^2 + (YY_d-fcy_d).^2) <= fix_r_d;
bg_grey(fix_dot) = 0.10;

% Convert to RGB
bg_R = bg_grey; bg_G = bg_grey; bg_B = bg_grey;

% Overlay colours — fixed contrasting pair for all conditions
lv1_rgb = [0.10, 0.78, 1.00];   % cyan
lv6_rgb = [1.00, 0.40, 0.05];   % orange
alpha_g = 0.75;

% Gaussian sigma for spreading gaze blobs — larger = more visible at small sizes
% Applied in heatmap native resolution before resizing
gaze_sigma = 1;   % pixels in native heatmap space; increase for larger blobs

% --- Build figure with tight manual axes layout ---
fig3 = figure('Color','w','Position',[50 50 1150 430]);
norm01 = @(x) (x-min(x(:)))/(max(x(:))-min(x(:))+eps);

% Manual tile layout: 2 rows x 3 cols, minimal gaps
n_r = 2; n_c = 3;
pad_l = 0.06;
pad_r = 0.01;
pad_t = 0.10;
pad_b = 0.04;
gap_x = 0.008;
gap_y = 0.06;

tile_w = (1 - pad_l - pad_r - (n_c-1)*gap_x) / n_c;
tile_h = (1 - pad_t - pad_b - (n_r-1)*gap_y) / n_r;

for c = 1:n_cond
    row   = floor((c-1)/n_c);
    col_i = mod(c-1, n_c);
    left_pos   = pad_l + col_i*(tile_w + gap_x);
    bottom_pos = (1 - pad_t) - (row+1)*tile_h - row*gap_y;

    ax = axes('Position',[left_pos bottom_pos tile_w tile_h], 'Parent',fig3); %#ok<LAXES>

    hm1 = grp_hmap{c,1};
    hm6 = grp_hmap{c,6};

    if isempty(hm1) || isempty(hm6)
        set(ax,'Color',[0.88 0.88 0.88]); axis(ax,'off');
        title(ax,cond_names{c},'FontSize',9,'Color',col(c,:)*0.7,'FontWeight','bold');
        continue;
    end

    % Smooth in native resolution to enlarge gaze blobs, then resize
    h1 = norm01(imresize(imgaussfilt(double(hm1), gaze_sigma), [DISP_H DISP_W]));
    h6 = norm01(imresize(imgaussfilt(double(hm6), gaze_sigma), [DISP_H DISP_W]));

    % Alpha-blend onto background
    a1    = alpha_g * h1;
    a6    = alpha_g * h6;
    a_tot = min(a1 + a6, 0.95);

    out_R = max(0,min(1, bg_R.*(1-a_tot) + lv1_rgb(1)*a1 + lv6_rgb(1)*a6));
    out_G = max(0,min(1, bg_G.*(1-a_tot) + lv1_rgb(2)*a1 + lv6_rgb(2)*a6));
    out_B = max(0,min(1, bg_B.*(1-a_tot) + lv1_rgb(3)*a1 + lv6_rgb(3)*a6));

    imshow(cat(3, out_R, out_G, out_B), 'Parent', ax);
    axis(ax,'image','off');
    title(ax, cond_names{c},'FontSize',9,'FontWeight','bold',...
        'Color',col(c,:)*0.75,'Interpreter','none');
end

% Shared colour key (left margin)
annotation('textbox',[0.001 0.54 0.055 0.06],'String','Lv 1',...
    'Color',lv1_rgb,'FontSize',10,'FontWeight','bold',...
    'EdgeColor','none','BackgroundColor','none');
annotation('textbox',[0.001 0.46 0.055 0.06],'String','Lv 6',...
    'Color',lv6_rgb,'FontSize',10,'FontWeight','bold',...
    'EdgeColor','none','BackgroundColor','none');
annotation('textbox',[0.10 0.97 0.80 0.025],...
    'String','Group Average Gaze Heatmaps — Level 1 (cyan) vs Level 6 (orange)',...
    'HorizontalAlignment','center','EdgeColor','none',...
    'FontSize',11,'FontWeight','bold','Color',[0.15 0.15 0.15]);

fprintf('\nDone — figures open.\n');
