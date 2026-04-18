% Generateframes.m
% based on CodeTestScriptD.m, DynTex.m, MotionCloud.m
%           by Andrew I Meso, Jonathan Vacher et al.
% Purpose:  Generate a 500,000-frame artificial stimulus sequence for DNN
%           neuroscience experiments. Stimuli known to drive V1 are used as
%           artificial analogues to natural motion sequences.

% Transitions: cosine-ramp crossfade over the last 100 frames of segment N
%              and the first 100 frames of segment N+1.

% Dependencies:   GenGratDrift.m, GenDots.m, GenSqrGrat.m
%                 DynTex.m, MotionCloud.m  (on MATLAB path)

szDim        = 160;          % frame size (pixels, square)
szDimH       = 120;
bitsIm       = 256;          % grey levels  (2^8)
TOTAL_FRAMES = 500000;       % total frames to generate
N_SEGS       = 4;            % number of stimulus segments
FRAMES_PER_SEG = TOTAL_FRAMES / N_SEGS;   % 100 000 per segment
FADE_LEN     = 1000;          % crossfade length (frames) at each boundary
SAVE_CHUNK   = 1000;         % frames per output .mat file
OUT_DIR      = 'stim_output';% output folder (created if absent)
VERBOSE      = true;         % print progress to command window

% Grating (InNo 2) 
grat_hparams = [8, -2];      % [SF cycles/image, speed px/frame]
grat_vparams = [0,  0];

% Moving dots (InNo 3)
dot_aparams  = [32, -3,  0, 5];   % [nDots, xSpd, ySpd, dotSz]
dot_bparams  = [32, -3,  0, 5];

% Square-wave grating (InNo 4) 
sqr_hparams  = [8,  2];
sqr_vparams  = [0,  0];

% Motion Cloud (moving-ball Gaussian envelope)
mc_ave_lum   = 128;
mc_contrast  = 35;
mc_adv.fps        = 50;
mc_adv.over_samp  = 5;
mc_adv.px_per_cm  = 50;
mc_adv.hist_len   = 10;
mc_adv.dev        = 'gpu';   % change to 'gpu' if available
mc_adv.seed       = 42;
mc_adv.verbose    = 0;

mc_kp.sf        = 1.0;       % cycles / cm  — low SF → large blob
mc_kp.sf_bdw    = 1.5;       % bandwidth (octaves)
mc_kp.th        = 0.0;       % orientation (0 = vertical)
mc_kp.th_sig    = 180.0;     % very wide → isotropic / ball-like
mc_kp.speed     = [2.0, 0.5];% [horiz cm/s, vert cm/s] → lateral drift
mc_kp.speed_sig = 20.0;      % temporal bandwidth
mc_kp.octa      = 1;

if ~exist(OUT_DIR, 'dir')
    mkdir(OUT_DIR);
    if VERBOSE, fprintf('Created output directory: %s\n', OUT_DIR); end
end

% Pre-build a cosine fade-out weight vector  (length FADE_LEN)
% fade_out(1)=~1, fade_out(end)=~0
t_fade     = linspace(0, pi/2, FADE_LEN)';      % 0 … π/2
fade_out   = cos(t_fade);                        % 1 → 0
fade_in    = sin(t_fade);                        % 0 → 1

    function fr_u8 = toUint8(fr_dbl)
        fr_dbl = max(0, min(255, fr_dbl));
        fr_u8  = uint8(fr_dbl);
    end


CHUNK_GEN = 512;   % internal generation block size (must be > FADE_LEN)


%% SEGMENT GENERATORS
%  Each generator is a function handle:
%    frame = gen_fn(absolute_frame_index_within_segment)
%  For periodic stimuli (gratings, dots) we generate one tile of CHUNK_GEN
%  frames and index cyclically.


if VERBOSE, fprintf('Pre-generating stimulus tiles …\n'); end

% Segment 2: moving dots
tile_dots = GenDots(szDimH, szDim, CHUNK_GEN, bitsIm, ...
                    dot_aparams, dot_bparams);
tile_dots = double(tile_dots);
gen_dots  = @(k) tile_dots(:, :, mod(k-1, CHUNK_GEN) + 1);

% Segment 4: Motion Cloud (moving ball) 
%  The MC object generates frames online — we wrap getFrame in a closure.
MC = MotionCloud(szDim, mc_ave_lum, mc_contrast, mc_adv);
MC.setParams(mc_kp);
gen_mc = @(~) imresize(MC.getFrame(1), [szDimH, szDim]);

% Segment 1: drifting sine-wave grating 
tile_grat = GenGratDrift(szDimH, szDim, CHUNK_GEN, bitsIm, ...
                         grat_hparams, grat_vparams);
tile_grat = double(tile_grat);
gen_grat  = @(k) tile_grat(:, :, mod(k-1, CHUNK_GEN) + 1);


% Segment 3: square-wave grating
tile_sqr  = GenSqrGrat(szDimH, szDim, CHUNK_GEN, bitsIm, ...
                       sqr_hparams, sqr_vparams);
tile_sqr  = double(tile_sqr);
gen_sqr   = @(k) tile_sqr(:, :, mod(k-1, CHUNK_GEN) + 1);

if VERBOSE, fprintf('Stimulus tiles ready.\n\n'); end


%% GEN LOOP

%  Crossfade formula for frame i in the overlap region:
%    blended = w_out * frame_outgoing  +  w_in * frame_incoming
%  where w_out + w_in ≠ 1 by design — cosine ramp is power-normalised.


generators = {gen_sqr, gen_grat, gen_mc, gen_dots};
seg_names  = {'SqrWaveGrating', 'Grating', 'MotionCloud', 'MovingDots'};

% Global write buffer
write_buf   = zeros(szDimH, szDim, SAVE_CHUNK, 'uint8');
buf_pos     = 0;    % frames currently in buffer (0-based pointer)
file_count  = 0;    % number of .mat files written

total_written = 0;
t_start       = tic;

for seg = 1:N_SEGS

    seg_start = (seg-1)*FRAMES_PER_SEG + 1;   % global frame index
    seg_end   =  seg   *FRAMES_PER_SEG;

    gen_curr = generators{seg};
    if seg < N_SEGS
        gen_next = generators{seg+1};
    else
        gen_next = [];
    end

    if VERBOSE
        fprintf('=== Segment %d / %d : %s  (frames %d – %d) ===\n', ...
                seg, N_SEGS, seg_names{seg}, seg_start, seg_end);
    end

    for k = 1:FRAMES_PER_SEG   % k = local frame index within segment

        global_k = seg_start + k - 1;

        % --- determine frame pixel values --------------------------------
        fr_curr = gen_curr(k);   % always generate the current stimulus

        if k <= FADE_LEN && seg > 1
            % ---- fade IN from previous segment -------------------------
            % The "previous" fade-out frames were already written; here we
            % need to OVERWRITE the last FADE_LEN entries of the buffer
            % with the blended result.  However, because we write/flush
            % sequentially, we handle the blend by keeping the last
            % FADE_LEN frames of the PREVIOUS segment in a small overlap
            % cache, and building the blend at this point.
            %
            % Implementation: we do the blending *inside* the outgoing
            % segment's last FADE_LEN frames (see below), so here we
            % simply emit fr_curr with weight fade_in(k).  The
            % contribution from the outgoing stimulus was already baked in
            % during the previous segment's loop.  Therefore:
            %   At the crossfade point we REPLACE the cached frames.
            %
            % Simpler approach chosen here: at the end of each segment
            % (the last FADE_LEN frames) we blend with the NEXT segment.
            % So we just emit fr_curr normally for the first FADE_LEN
            % frames of each segment — the blending is done in the
            % OUTGOING segment loop below.
            frame = fr_curr;

        elseif k > FRAMES_PER_SEG - FADE_LEN && ~isempty(gen_next)
            % ---- fade OUT into next segment ----------------------------
            fade_k   = k - (FRAMES_PER_SEG - FADE_LEN);  % 1 … FADE_LEN
            w_out    = fade_out(fade_k);
            w_in     = fade_in(fade_k);
            fr_next  = gen_next(fade_k);                  % prime next gen
            frame    = w_out .* fr_curr + w_in .* fr_next;
        else
            % ---- normal frame ------------------------------------------
            frame = fr_curr;
        end

        % --- accumulate into write buffer --------------------------------
        buf_pos = buf_pos + 1;
        write_buf(:, :, buf_pos) = toUint8(frame);

        % --- flush buffer when full -------------------------------------
        if buf_pos == SAVE_CHUNK
            file_count   = file_count + 1;
            out_fname    = fullfile(OUT_DIR, ...
                           sprintf('stim_%06d.mat', file_count));
            frames       = write_buf;          %#ok<NASGU> — saved variable
            save(out_fname, 'frames', '-v7.3');
            total_written = total_written + SAVE_CHUNK;
            buf_pos       = 0;
            write_buf     = zeros(szDimH, szDim, SAVE_CHUNK, 'uint8');

            if VERBOSE
                elapsed  = toc(t_start);
                rate_fps = total_written / elapsed;
                eta_s    = (TOTAL_FRAMES - total_written) / max(rate_fps, 1);
                fprintf('  Saved %s  |  total %7d / %d  |  %.0f fps  |  ETA %.0f s\n', ...
                        out_fname, total_written, TOTAL_FRAMES, rate_fps, eta_s);
            end
        end

    end % k (frames within segment)

end % seg

% --- flush any remaining frames ------------------------------------------
if buf_pos > 0
    file_count = file_count + 1;
    out_fname  = fullfile(OUT_DIR, sprintf('stim_%06d.mat', file_count));
    frames     = write_buf(:, :, 1:buf_pos);  %#ok<NASGU>
    save(out_fname, 'frames', '-v7.3');
    total_written = total_written + buf_pos;
    if VERBOSE
        fprintf('  Saved remainder → %s  (%d frames)\n', out_fname, buf_pos);
    end
end

elapsed_total = toc(t_start);
fprintf('\n>>> Done.  %d frames written to %d files in %.1f s (%.0f fps avg).\n', ...
        total_written, file_count, elapsed_total, total_written/elapsed_total);

% =========================================================================
%% Visualize sequence if wanted

%all_files = dir(fullfile(OUT_DIR,'stim_*.mat'));
%all_frames = zeros(szDim, szDim, TOTAL_FRAMES, 'uint8');
%ptr = 1;
%for fi = 1:numel(all_files)
%    d = load(fullfile(OUT_DIR, all_files(fi).name));
%    n = size(d.frames, 3);
%    all_frames(:,:,ptr:ptr+n-1) = d.frames;
%    ptr = ptr + n;
%end

