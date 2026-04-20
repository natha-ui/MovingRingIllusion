import os
import glob
import numpy as np
from PIL import Image

SAFARI_ROOT = '.'
NPY_ROOT    = 'safari_npy'
OUT_DIR     = 'data'
TARGET_SIZE = (256, 256)    # resize to match your PredNet --size argument
GRAYSCALE   = False          # True = 1 channel, False = 3 channel RGB
                            # must match --channels in your training command
MAX_FRAMES  = None          # set e.g. 400000 to cap total frames, None = all

SPLITS = {
    'train' : r'C:\Users\Nathan\Documents\Files\ReProj\safari_data\sa_fari_train',
    'test'  : os.path.join(SAFARI_ROOT, 'sa_fari_test',  'JPEGImages_6fps'),
}

os.makedirs(OUT_DIR, exist_ok=True)

for split_name, src_root in SPLITS.items():

    if not os.path.exists(src_root):
        print(f'Skipping {split_name} — folder not found: {src_root}')
        continue

    npy_split_dir = os.path.join(NPY_ROOT, split_name)
    os.makedirs(npy_split_dir, exist_ok=True)

    # collect all video folders, sorted for reproducibility
    video_dirs = sorted([
        d for d in glob.glob(os.path.join(src_root, '*'))
        if os.path.isdir(d)
    ])

    print(f'\n{split_name}: {len(video_dirs)} videos found in {src_root}')

    all_npy_paths = []
    total = 0

    for vid_dir in video_dirs:
        vid_id = os.path.basename(vid_dir)

        # get frames in temporal order
        jpg_files = sorted(glob.glob(os.path.join(vid_dir, '*.jpg')) +
                           glob.glob(os.path.join(vid_dir, '*.jpeg')) +
                           glob.glob(os.path.join(vid_dir, '*.JPEG')))

        for jpg_path in jpg_files:

            if MAX_FRAMES and total >= MAX_FRAMES:
                break

            frame_name = os.path.splitext(os.path.basename(jpg_path))[0]
            npy_fname  = f'{vid_id}_{frame_name}.npy'
            npy_path   = os.path.join(npy_split_dir, npy_fname)

            if not os.path.exists(npy_path):   # skip if already converted
                img = Image.open(jpg_path)
                img = img.resize(TARGET_SIZE, Image.BILINEAR)

                if GRAYSCALE:
                    img = img.convert('L')
                    arr = np.array(img, dtype=np.uint8)
                    arr = arr[np.newaxis, :, :]     # (1, H, W)
                else:
                    img = img.convert('RGB')
                    arr = np.array(img, dtype=np.uint8)
                    arr = np.transpose(arr, (2, 0, 1))  # (3, H, W)

                np.save(npy_path, arr)

            all_npy_paths.append(os.path.abspath(npy_path))
            total += 1

        if MAX_FRAMES and total >= MAX_FRAMES:
            print(f'  Reached MAX_FRAMES={MAX_FRAMES}, stopping.')
            break

        if total % 10000 == 0 and total > 0:
            print(f'  {total:,} frames converted...', flush=True)

    # write list file
    list_path = os.path.join(OUT_DIR, f'safari_{split_name}_list.txt')
    with open(list_path, 'w') as f:
        for p in all_npy_paths:
            f.write(p.replace('\\', '/') + '\n')

    print(f'  Total: {total:,} frames')
    print(f'  Written: {list_path}')

print('  python main.py -i data/safari_train_list.txt --channels 3,48,96,192 --size 256,256 --batchsize 1 --device cuda --useamp --lr 0.001')
