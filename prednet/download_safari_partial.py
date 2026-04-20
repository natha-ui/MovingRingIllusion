# download_safari_partial.py
# Downloads only enough SA-FARI videos to reach TARGET_FRAMES.
# Uses gsutil to download one video folder at a time.
#
# Usage:
#   python download_safari_partial.py
#
# Run from your safari_data/ folder or wherever you want the data saved.

import os
import json
import subprocess
from huggingface_hub import hf_hub_download

TARGET_FRAMES = 600000
OUT_DIR       = 'sa_fari_train'   # local folder to download into
GCS_BASE      = 'gs://cxl-public-camera-trap/sa_fari/sa_fari_train/JPEGImages_6fps'

# ---- load annotation to get video list and frame counts -----------------
print('Loading annotation...')
path = hf_hub_download(repo_id='facebook/SA-FARI', repo_type='dataset',
                       filename='annotation/sa_fari_train.json')
with open(path) as f:
    data = json.load(f)

videos = data['videos']   # already in order
print(f'Total videos available: {len(videos):,}')
print(f'Total frames available: {sum(v["length"] for v in videos):,}')

# ---- select just enough videos ------------------------------------------
selected = []
total    = 0
for v in videos:
    if total >= TARGET_FRAMES:
        break
    selected.append(v)
    total += v['length']

print(f'\nVideos to download: {len(selected):,}')
print(f'Expected frames:    {total:,}')
print(f'Starting download into {OUT_DIR}/\n')

os.makedirs(OUT_DIR, exist_ok=True)

# ---- download each video folder -----------------------------------------
for i, v in enumerate(selected):
    vid_name  = v['video_name']
    local_dir = os.path.join(OUT_DIR, vid_name)

    # skip if already downloaded
    if os.path.exists(local_dir) and len(os.listdir(local_dir)) >= v['length']:
        print(f'[{i+1}/{len(selected)}] {vid_name} already exists, skipping.')
        continue

    gcs_path = f'{GCS_BASE}/{vid_name}'
    cmd      = ['gsutil', '-m', 'cp', '-r', gcs_path, OUT_DIR]

    print(f'[{i+1}/{len(selected)}] Downloading {vid_name} ({v["length"]} frames)...',
          end=' ', flush=True)

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode == 0:
        print('done')
    else:
        print(f'FAILED\n{result.stderr}')

print(f'\nDownload complete. {len(selected):,} videos in {OUT_DIR}/')
print('Now run: python safari_to_prednet.py')
