import os
import shutil

LOG_FILE   = 'log_t.txt'
MODELS_DIR = 'models'
OUT_DIR    = 'models'

SEGMENTS = [
    ('safari', 0, 999999999),   # one segment covering entire training run
]

if not os.path.exists(LOG_FILE):
    raise FileNotFoundError(
        f'{LOG_FILE} not found. Check the log filename with: dir *.txt *.log *.csv')

entries = []
with open(LOG_FILE, 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            parts     = line.split(',')
            iteration = int(float(parts[0].strip()))
            loss      = float(parts[1].strip())
            entries.append((iteration, loss))
        except (ValueError, IndexError):
            continue

if not entries:
    raise ValueError('No valid entries found in log file.')

print(f'Loaded {len(entries)} log entries.\n')

# find best per segment
for seg_name, seg_start, seg_end in SEGMENTS:

    seg_entries = [(it, loss) for it, loss in entries
                   if seg_start <= it <= seg_end]

    if not seg_entries:
        print(f'{seg_name:20s}  no log entries found yet')
        continue

    best_it, best_loss = min(seg_entries, key=lambda x: x[1])

    # find closest available .pth file to best_it
    pth_files = []
    for fname in os.listdir(MODELS_DIR):
        if fname.endswith('.pth'):
            try:
                it = int(os.path.splitext(fname)[0])
                pth_files.append(it)
            except ValueError:
                continue

    if not pth_files:
        print(f'{seg_name:20s}  no .pth files found in {MODELS_DIR}/')
        continue

    closest_it = min(pth_files, key=lambda x: abs(x - best_it))
    src_path   = os.path.join(MODELS_DIR, f'{closest_it}.pth')
    dst_name   = f'best_{seg_name}.pth'
    dst_path   = os.path.join(OUT_DIR, dst_name)

    shutil.copy2(src_path, dst_path)

    print(f'{seg_name:20s}  best loss {best_loss:>12.2f}  '
          f'at iter {best_it:>7d}  →  saved as {dst_name}  '
          f'(using checkpoint {closest_it})')

print('\nDone.')
