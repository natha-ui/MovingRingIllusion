# png_to_npy.py
# Converts existing PNG frames in dataset/ to .npy files in dataset_npy/
# Much faster than re-exporting from MATLAB.
#
# Usage:
#   python png_to_npy.py
#
# Input:  dataset/train/grating/frame_000001.png  ...
# Output: dataset_npy/grating/frame_000001.npy    ...

import os
import glob
import numpy as np
from PIL import Image

PNG_ROOT  = 'dataset/train'
NPY_ROOT  = 'dataset_npy'
SEG_ORDER = ['moving_dots','motion_cloud']

for seg in SEG_ORDER:
    src_dir = os.path.join(PNG_ROOT, seg)
    dst_dir = os.path.join(NPY_ROOT, seg)
    os.makedirs(dst_dir, exist_ok=True)

    png_files = sorted(glob.glob(os.path.join(src_dir, '*.png')))
    print(f'{seg}: {len(png_files):,} files', flush=True)

    for i, src_path in enumerate(png_files):
        fname    = os.path.splitext(os.path.basename(src_path))[0] + '.npy'
        dst_path = os.path.join(dst_dir, fname)

        img = np.array(Image.open(src_path).convert('L').resize((160,120), Image.BILINEAR), dtype=np.uint8)
        img = img[np.newaxis, :, :]  
        np.save(dst_path, img)

        if (i + 1) % 10000 == 0:
            print(f'  {i+1:,} / {len(png_files):,}', flush=True)

    print(f'  Done.\n')

print('All segments converted.')
