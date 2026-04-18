% ExportFramesForPyTorch.m
% Purpose:  Convert the chunked .mat files produced by GenStimSequence400k
%           into a folder of PNG images that PyTorch's DataLoader can read directly.


clear; clc;

%% Configuration
SRC_DIR   = 'stim_output_dynamic';          % folder containing stim_*.mat files
DST_ROOT  = 'dataset';              % output root for PyTorch ImageFolder
SPLIT     = 'train';                % subfolder name (train / val / test)
FRAMES_PER_SEG = 250000;            % frames per stimulus class

% Class definitions — must match the segment order in GenStimSequence400k
classes = {'moving_dots', 'motion_cloud'};

VERBOSE   = true;

%% Build output folders 
for c = 1:numel(classes)
    d = fullfile(DST_ROOT, SPLIT, classes{c});
    if ~exist(d,'dir'), mkdir(d); end
end

%% Open CSV index file 
csv_path = fullfile(DST_ROOT, 'frame_index.csv');
fid = fopen(csv_path, 'w');
fprintf(fid, 'global_frame,filename,class_label,class_idx,segment\n');

%% Iterate over source chunks 
mat_files = dir(fullfile(SRC_DIR, 'stim_*.mat'));
[~, idx]  = sort({mat_files.name});
mat_files = mat_files(idx);

if isempty(mat_files)
    error('No stim_*.mat files found in %s', SRC_DIR);
end

global_frame = 0;
t_start      = tic;

for fi = 1:numel(mat_files)

    % load chunk — variable name is 'frames' [256 x 256 x chunk_size uint8]
    d      = load(fullfile(SRC_DIR, mat_files(fi).name));
    chunk  = d.frames;              % [H x W x N] uint8
    N      = size(chunk, 3);

    for n = 1:N

        global_frame = global_frame + 1;

        % determine class from global frame index
        class_idx   = ceil(global_frame / FRAMES_PER_SEG);
        class_idx   = min(class_idx, numel(classes));   % clamp at last
        class_label = classes{class_idx};
        seg_local   = global_frame - (class_idx-1)*FRAMES_PER_SEG;

        % build filename  e.g.  frame_000001.png
        fname    = sprintf('frame_%06d.png', global_frame);
        out_path = fullfile(DST_ROOT, SPLIT, class_label, fname);

        % write greyscale PNG
        imwrite(chunk(:,:,n), out_path);

        % write CSV row
        rel_path = fullfile(SPLIT, class_label, fname);
        fprintf(fid, '%d,%s,%s,%d,%d\n', ...
                global_frame, rel_path, class_label, class_idx-1, seg_local);
        % note: class_idx-1 → zero-based, matching PyTorch convention

    end

    if VERBOSE
        elapsed = toc(t_start);
        rate    = global_frame / elapsed;
        eta     = (400000 - global_frame) / max(rate,1);
        fprintf('Chunk %3d / %d  |  frame %7d  |  %.0f fr/s  |  ETA %.0f s\n', ...
                fi, numel(mat_files), global_frame, rate, eta);
    end
end

fclose(fid);

fprintf('\nDone. %d frames exported to %s/\n', global_frame, DST_ROOT);
fprintf('CSV index written to %s\n', csv_path);
