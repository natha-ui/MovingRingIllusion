# wheel_png_to_npy.py
# Converts PNG frames from WheelStimToPredNet.m output into .npy files
# for PredNet testing. Uses the same approach as png_to_npy.py.
#
# Input:  prednet_stimuli/<condition>/frame_0001.jpg ...
# Output: prednet_stimuli/<condition>/frame_0001.npy ...
#
# Usage:
#   python wheel_png_to_npy.py

import os
import glob
import numpy as np
from PIL import Image

STIM_DIR  = 'prednet_stimuli'
TARGET_W  = 160
TARGET_H  = 120

CONDITIONS = [
    'edgeSiz_low',    'edgeSiz_high',
    'edgeCon_low',    'edgeCon_high',
    'speed_low',      'speed_high',
    'wheelCon_low',   'wheelCon_high',
    'arrow_cong_low', 'arrow_cong_high',
    'arrow_incong_low','arrow_incong_high',
]

for cond in CONDITIONS:
    cond_dir = os.path.join(STIM_DIR, cond)
    if not os.path.exists(cond_dir):
        print(f'SKIP {cond} — folder not found')
        continue

    # find JPEGs or PNGs
    img_files = sorted(glob.glob(os.path.join(cond_dir, '*.jpg')) +
                       glob.glob(os.path.join(cond_dir, '*.png')))

    if not img_files:
        print(f'SKIP {cond} — no image files found')
        continue

    print(f'{cond}: {len(img_files)} files', flush=True)

    # write list file for PredNet
    list_path = os.path.join(STIM_DIR, f'list_{cond}.txt')
    list_lines = []

    for src_path in img_files:
        fname    = os.path.splitext(os.path.basename(src_path))[0] + '.npy'
        dst_path = os.path.join(cond_dir, fname)

        img = np.array(
            Image.open(src_path).convert('L').resize((TARGET_W, TARGET_H), Image.BILINEAR),
            dtype=np.uint8
        )
        img = img[np.newaxis, :, :]   # (1, 120, 160)
        np.save(dst_path, img)
        list_lines.append(os.path.abspath(dst_path).replace('\\', '/'))

    with open(list_path, 'w') as f:
        f.write('\n'.join(list_lines) + '\n')

    print(f'  Done. List written to {list_path}\n')

print('All conditions converted.')
