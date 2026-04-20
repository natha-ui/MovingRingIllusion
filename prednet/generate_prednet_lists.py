# generate_prednet_lists.py
#
# Generates per-stimulus train and test lists for mixed PredNet training.
#
# Each stimulus type gets its own 90/10 train/test split, preserving
# temporal order within each type. The combined train list interleaves
# all stimulus types so the model sees all of them throughout training.
#
# Outputs:
#   data/train_grating.txt        data/test_grating.txt
#   data/train_moving_dots.txt    data/test_moving_dots.txt
#   data/train_sqr_grating.txt    data/test_sqr_grating.txt
#   data/train_motion_cloud.txt   data/test_motion_cloud.txt
#   data/train_all.txt            data/test_all.txt   (combined, temporally ordered)


import os
import glob

# ── CONFIG ──────────────────────────────────────────────────────────────────
NPY_ROOT   = 'dataset_npy'    # root folder containing one subfolder per stimulus
OUT_DIR    = 'data'
TRAIN_FRAC = 0.9

STIMULI = [
    ('moving_dots',  'moving_dots'),
    ('motion_cloud', 'motion_cloud'),
]
# ────────────────────────────────────────────────────────────────────────────

os.makedirs(OUT_DIR, exist_ok=True)


def write_list(paths, out_path):
    with open(out_path, 'w') as f:
        for p in paths:
            f.write(os.path.abspath(p) + '\n')
    print(f'  Written: {out_path}  ({len(paths):,} lines)')


all_train = []
all_test  = []

print('Per-stimulus splits:')
for label, folder in STIMULI:
    seg_dir = os.path.join(NPY_ROOT, folder)
    if not os.path.isdir(seg_dir):
        print(f'  WARNING: {seg_dir} not found — skipping {label}')
        continue

    paths = sorted(glob.glob(os.path.join(seg_dir, '*.npy')))
    if not paths:
        print(f'  WARNING: no .npy files found in {seg_dir} — skipping {label}')
        continue

    split      = int(len(paths) * TRAIN_FRAC)
    train_p    = paths[:split]
    test_p     = paths[split:]
    all_train += train_p
    all_test  += test_p

    print(f'\n  {label}  ({len(paths):,} frames)')
    write_list(train_p, os.path.join(OUT_DIR, f'train_{label}.txt'))
    write_list(test_p,  os.path.join(OUT_DIR, f'test_{label}.txt'))

print(f'\nCombined lists:')
write_list(all_train, os.path.join(OUT_DIR, 'train_all.txt'))
write_list(all_test,  os.path.join(OUT_DIR, 'test_all.txt'))

print(f'\nTotal  train: {len(all_train):,}  test: {len(all_test):,}')
print('\nDone.')
