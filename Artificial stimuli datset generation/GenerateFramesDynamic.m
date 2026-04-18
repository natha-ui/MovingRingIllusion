% GenerateFramesDynamic.m
% Generates 500,000 frames of two dynamic stimuli for DNN training.

% Segment 1 (250,000 frames): Moving Dots
%   - Dot size, speed, direction drawn from N(mu, sigma) every 8 frames
%   - mu itself shifts slightly every 80 frames (drawn from a wider dist)
%   - Dots disappear per-dot with probability p per 8-frame block
%   - Minimum dot count enforced — disappeared dots respawn at random pos

% Segment 2 (250,000 frames): Motion Cloud
%   - sf_bdw = 3 octaves (wide frequency range)
%   - Speed (x and y independently) follows Ornstein-Uhlenbeck process
%   - OU process gives momentum: speed increases/decreases in bursts
%   - Every 8 frames: OU step applied to speed
%   - Every 80 frames: OU mean (mu) drifts slightly

% Transition: 1000-frame cosine crossfade at the segment boundary


szDim        = 160;
szDimH       = 120;
bitsIm       = 256;
TOTAL_FRAMES = 500000;
N_SEGS       = 2;
FRAMES_PER_SEG = TOTAL_FRAMES / N_SEGS;   % 250,000 each
FADE_LEN     = 1000;
SAVE_CHUNK   = 1000;
OUT_DIR      = 'stim_output_dynamic';
VERBOSE      = true;

% Dots params
DOT_N_MIN      = 8;        % minimum number of dots (floor)
DOT_N_MAX      = 64;       % maximum number of dots
DOT_N_INIT     = 32;       % initial number of dots

% Dot size distribution (wide range)
DOT_SZ_MU_INIT = 8;        % initial mean dot radius (px)
DOT_SZ_SIG     = 4;        % std of fast (8-frame) draw
DOT_SZ_MU_SIG  = 2;        % std of slow (80-frame) mu drift
DOT_SZ_CLIP    = [2, 20];  % hard clip on radius

% Dot speed distribution
DOT_SPD_MU_INIT = 3.0;     % initial mean speed magnitude (px/frame)
DOT_SPD_SIG     = 1.5;     % std of fast draw
DOT_SPD_MU_SIG  = 1.0;     % std of slow mu drift
DOT_SPD_CLIP    = [0.5, 8];% hard clip on speed magnitude

% Dot disappearance
DOT_DISAPPEAR_PROB = 0.10; % probability each dot disappears per 8-frame block

% Motion Cloud params
MC_SF          = 1.0;
MC_SF_BDW      = 3.0;      % 3 octave bandwidth (wide frequency range)
MC_TH          = 0.0;
MC_TH_SIG      = 180.0;    % isotropic
MC_OCTA        = 1;

% OU process parameters for speed (x and y independently)
% dx(t) = theta*(mu - x(t))*dt + sigma*dW
% theta = mean reversion rate (higher = faster return to mean)
% sigma = noise amplitude (higher = more volatile speed changes)
OU_THETA       = 0.08;     % mean reversion rate per frame
OU_SIGMA       = 0.03;     % noise amplitude per frame
OU_SPD_CLIP    = [-1.5, 1.5];  % clip speed components (cm/s)

% Initial OU state
OU_MU_X_INIT   = 1.0;      % initial mean speed x (cm/s)
OU_MU_Y_INIT   = 0.3;      % initial mean speed y (cm/s)
OU_MU_DRIFT_SIG = 0.1;     % std of slow (80-frame) mu drift

% MC advanced params
mc_adv.fps        = 50;
mc_adv.over_samp  = 3;
mc_adv.px_per_cm  = 50;
mc_adv.hist_len   = 10;
mc_adv.dev        = 'gpu';
mc_adv.seed       = 42;
mc_adv.verbose    = 0;

%% Initialisation
if ~exist(OUT_DIR, 'dir')
    mkdir(OUT_DIR);
end

t_fade   = linspace(0, pi/2, FADE_LEN)';
fade_out = cos(t_fade);
fade_in  = sin(t_fade);

function fr_u8 = toUint8(fr_dbl)
    fr_dbl = max(0, min(255, fr_dbl));
    fr_u8  = uint8(fr_dbl);
end

% Initialise dot positions
n_dots   = DOT_N_INIT;
pos_x    = rand(1, DOT_N_MAX) * szDim;   % x positions (all slots)
pos_y    = rand(1, DOT_N_MAX) * szDimH;  % y positions
alive    = [true(1, n_dots), false(1, DOT_N_MAX - n_dots)]; % alive mask

% Current fast-draw parameters
dot_sz_mu  = DOT_SZ_MU_INIT;
dot_spd_mu = DOT_SPD_MU_INIT;
dot_sz     = max(DOT_SZ_CLIP(1), min(DOT_SZ_CLIP(2), ...
             dot_sz_mu + DOT_SZ_SIG * randn(1, DOT_N_MAX)));
dot_spd    = max(DOT_SPD_CLIP(1), min(DOT_SPD_CLIP(2), ...
             dot_spd_mu + DOT_SPD_SIG * abs(randn(1, DOT_N_MAX))));
dot_dir    = rand(1, DOT_N_MAX) * 2 * pi;   % direction in radians
dot_vx     = dot_spd .* cos(dot_dir);
dot_vy     = dot_spd .* sin(dot_dir);

% Pixel grids
[Xg, Yg]   = meshgrid(1:szDim, 1:szDimH);
Xg_flat    = Xg(:);
Yg_flat    = Yg(:);
mid_lum    = bitsIm / 2;
dot_lum    = bitsIm - 1;

function frame = renderDots(pos_x, pos_y, dot_sz, alive, ...
                            Xg_flat, Yg_flat, szDim, szDimH, mid_lum, dot_lum)
    canvas = false(szDim * szDimH, 1);
    idx    = find(alive);
    if ~isempty(idx)
        cx = pos_x(idx);   % [1 x nAlive]
        cy = pos_y(idx);
        r2 = dot_sz(idx).^2;
        dx = min(abs(Xg_flat - cx), szDim  - abs(Xg_flat - cx));
        dy = min(abs(Yg_flat - cy), szDimH - abs(Yg_flat - cy));
        canvas = any(dx.^2 + dy.^2 <= r2, 2);
    end
    fr            = mid_lum * ones(szDim * szDimH, 1);
    fr(canvas)    = dot_lum;
    frame         = reshape(fr, szDimH, szDim);
end

%% Motion cloud generator state

% Initialise OU process state
ou_x   = OU_MU_X_INIT;    % current speed x (cm/s)
ou_y   = OU_MU_Y_INIT;    % current speed y (cm/s)
ou_mu_x = OU_MU_X_INIT;   % current mean x
ou_mu_y = OU_MU_Y_INIT;   % current mean y

mc_kp.sf        = MC_SF;
mc_kp.sf_bdw    = MC_SF_BDW;
mc_kp.th        = MC_TH;
mc_kp.th_sig    = MC_TH_SIG;
mc_kp.speed     = [ou_x, ou_y];
mc_kp.speed_sig = 10.0;
mc_kp.octa      = MC_OCTA;

MC = MotionCloud(szDim, 128, 15, mc_adv);
MC.setParams(mc_kp);

%% Buffer

write_buf   = zeros(szDimH, szDim, SAVE_CHUNK, 'uint8');
buf_pos     = 0;
file_count  = 0;
total_written = 0;
t_start       = tic;

%% Generate frames
for seg = 1:N_SEGS

    seg_start = (seg-1)*FRAMES_PER_SEG + 1;
    seg_end   =  seg   *FRAMES_PER_SEG;

    if VERBOSE
        if seg == 1
            fprintf('=== Segment 1: Moving Dots (frames %d – %d) ===\n', ...
                    seg_start, seg_end);
        else
            fprintf('=== Segment 2: Motion Cloud (frames %d – %d) ===\n', ...
                    seg_start, seg_end);
        end
    end

    for k = 1:FRAMES_PER_SEG

        global_k = seg_start + k - 1;

        % Parameter update every 8 frames
        if mod(k, 8) == 1

            if seg == 1
                % Dots: 
                % Disappearance: each alive dot disappears with prob p
                for d = 1:DOT_N_MAX
                    if alive(d) && rand() < DOT_DISAPPEAR_PROB
                        alive(d) = false;
                    end
                end
                % Enforce minimum — respawn random dead slots if needed
                n_alive = sum(alive);
                if n_alive < DOT_N_MIN
                    dead_idx = find(~alive);
                    need     = DOT_N_MIN - n_alive;
                    respawn  = dead_idx(randperm(numel(dead_idx), min(need, numel(dead_idx))));
                    alive(respawn)  = true;
                    pos_x(respawn) = rand(1, numel(respawn)) * szDim;
                    pos_y(respawn) = rand(1, numel(respawn)) * szDimH;
                end

                % Redraw size and speed from current mu
                dot_sz  = max(DOT_SZ_CLIP(1),  min(DOT_SZ_CLIP(2), ...
                          dot_sz_mu  + DOT_SZ_SIG  * randn(1, DOT_N_MAX)));
                dot_spd = max(DOT_SPD_CLIP(1), min(DOT_SPD_CLIP(2), ...
                          dot_spd_mu + DOT_SPD_SIG * abs(randn(1, DOT_N_MAX))));
                dot_dir = rand(1, DOT_N_MAX) * 2 * pi;
                dot_vx  = dot_spd .* cos(dot_dir);
                dot_vy  = dot_spd .* sin(dot_dir);

            else
                % Motion Cloud: OU step 
                ou_x = ou_x + OU_THETA*(ou_mu_x - ou_x) + OU_SIGMA*randn();
                ou_y = ou_y + OU_THETA*(ou_mu_y - ou_y) + OU_SIGMA*randn();
                ou_x = max(OU_SPD_CLIP(1), min(OU_SPD_CLIP(2), ou_x));
                ou_y = max(OU_SPD_CLIP(1), min(OU_SPD_CLIP(2), ou_y));
                set(MC, 'speed', [ou_x, ou_y]);
            end
        end

        % Slow parameter drift every 80 frames
        if mod(k, 80) == 1

            if seg == 1
                % Shift dot parameter means
                dot_sz_mu  = max(DOT_SZ_CLIP(1),  min(DOT_SZ_CLIP(2), ...
                             dot_sz_mu  + DOT_SZ_MU_SIG  * randn()));
                dot_spd_mu = max(DOT_SPD_CLIP(1), min(DOT_SPD_CLIP(2), ...
                             dot_spd_mu + DOT_SPD_MU_SIG * randn()));
            else
                % Drift OU mean
                ou_mu_x = ou_mu_x + OU_MU_DRIFT_SIG * randn();
                ou_mu_y = ou_mu_y + OU_MU_DRIFT_SIG * randn();
                ou_mu_x = max(OU_SPD_CLIP(1), min(OU_SPD_CLIP(2), ou_mu_x));
                ou_mu_y = max(OU_SPD_CLIP(1), min(OU_SPD_CLIP(2), ou_mu_y));
            end
        end

       
        if seg == 1
            % Advance dot positions
            pos_x = mod(pos_x + dot_vx, szDim);
            pos_y = mod(pos_y + dot_vy, szDimH);
            fr_curr = renderDots(pos_x, pos_y, dot_sz, alive, ...
                                 Xg_flat, Yg_flat, szDim, szDimH, ...
                                 mid_lum, dot_lum);
        else
            % Reset MC internal state every 2000 frames to prevent divergence
            if mod(k, 2000) == 0
                mc_sz = MC.size_im;
                MC.frame0 = zeros(mc_sz, mc_sz);
                MC.frame1 = zeros(mc_sz, mc_sz);
                MC.frame2 = zeros(mc_sz, mc_sz);
            end
            fr_curr = imresize(MC.getFrame(1), [szDimH, szDim]);
        end

        % Fade out fade in
        if k > FRAMES_PER_SEG - FADE_LEN && seg == 1
            % Fade out dots, fade in MC
            fade_k    = k - (FRAMES_PER_SEG - FADE_LEN);
            w_out     = fade_out(fade_k);
            w_in      = fade_in(fade_k);
            fr_next   = imresize(MC.getFrame(1), [szDimH, szDim]);
            frame     = w_out .* fr_curr + w_in .* fr_next;
        else
            frame = fr_curr;
        end

        % Buffer and save
        buf_pos = buf_pos + 1;
        write_buf(:, :, buf_pos) = toUint8(frame);

        if buf_pos == SAVE_CHUNK
            file_count  = file_count + 1;
            out_fname   = fullfile(OUT_DIR, sprintf('stim_%06d.mat', file_count));
            frames      = write_buf;   %#ok<NASGU>
            save(out_fname, 'frames', '-v7.3');
            total_written = total_written + SAVE_CHUNK;
            buf_pos     = 0;
            write_buf   = zeros(szDimH, szDim, SAVE_CHUNK, 'uint8');

            if VERBOSE
                elapsed  = toc(t_start);
                rate_fps = total_written / elapsed;
                eta_s    = (TOTAL_FRAMES - total_written) / max(rate_fps, 1);
                fprintf('  Saved %s  |  %7d / %d  |  %.0f fps  |  ETA %.0f s\n', ...
                        out_fname, total_written, TOTAL_FRAMES, rate_fps, eta_s);
            end
        end

    end % k
end % seg

% Flush remainder
if buf_pos > 0
    file_count = file_count + 1;
    out_fname  = fullfile(OUT_DIR, sprintf('stim_%06d.mat', file_count));
    frames     = write_buf(:, :, 1:buf_pos);  %#ok<NASGU>
    save(out_fname, 'frames', '-v7.3');
    total_written = total_written + buf_pos;
end

elapsed_total = toc(t_start);
fprintf('\n>>> Done. %d frames in %.1f s (%.0f fps avg).\n', ...
        total_written, elapsed_total, total_written/elapsed_total);
