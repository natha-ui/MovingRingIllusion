import os, glob, pickle, math
import numpy as np
import cv2, h5py
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import scipy.stats as stats_lib
import torch, torch.nn as nn
from torch.nn import Parameter, functional as F
from torch.nn.modules.utils import _pair

PREDNET_PKL  = 'prednet_wheel_results/prednet_results.pkl'
EMD_MAT      = 'WheelEMD_Outputs.mat'
STIM_DIR     = 'prednet_stimuli'
WEIGHTS_PATH = 'models/fpsi136_410000.pth'
OUT_DIR      = 'spatial_flow_analysis'
os.makedirs(OUT_DIR, exist_ok=True)

TARGET_W, TARGET_H = 160, 120
EMD_SZ = 256
Hz     = 120

# Aligned time points: MATLAB frames 17,27,36 = npy indices 0,10,19
TPOINTS_MATLAB = [17, 27, 36]
TPOINTS_NPY    = [0,  10, 19]
TPOINTS_S      = [round(f/Hz, 3) for f in TPOINTS_MATLAB]

COND_PAIRS = [
    ('edgeSiz_low',  'edgeSiz_high',  'Edge Size'),
    ('edgeCon_low',  'edgeCon_high',  'Edge Contrast'),
    ('speed_low',    'speed_high',    'Rotation Speed'),
    ('wheelCon_low', 'wheelCon_high', 'Wheel Contrast'),
]
COND_TO_EMD = {
    'edgeSiz_low' :(0,0),'edgeSiz_high' :(0,5),
    'edgeCon_low' :(1,0),'edgeCon_high' :(1,5),
    'speed_low'   :(2,0),'speed_high'   :(2,5),
    'wheelCon_low':(3,0),'wheelCon_high':(3,5),
    'arrow_cong_low'   :(4,0),'arrow_cong_high'   :(4,5),
    'arrow_incong_low' :(5,0),'arrow_incong_high' :(5,5),
}

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# load
print('Loading PredNet results...')
with open(PREDNET_PKL, 'rb') as fh:
    results = pickle.load(fh)
pretrained = results.get('pretrained', {})

print('Loading 2DMD outputs...')
f_mat  = h5py.File(EMD_MAT, 'r')
EMD_R  = f_mat['EMD_R']
EMD_Th = f_mat['EMD_Th']


# GET EMD FRAME
def get_emd_frame(st, lv, frame_idx_matlab):
    """
    Extract EMD magnitude and direction at a specific MATLAB frame (1-indexed).

    h5py reads MATLAB [H, W, nFrames] as [nFrames, W, H] due to Fortran→C
    transposition. So the array in Python is shape (nFrames, W, H).
    We index frame_idx_matlab-1 on axis 0, then transpose to get (H, W).
    """
    try:
        mag_full  = np.array(f_mat[EMD_R[st, lv]])
        dirs_full = np.array(f_mat[EMD_Th[st, lv]])
        fi = frame_idx_matlab - 1   # 0-indexed

        if mag_full.ndim == 3:
            # h5py shape is (nFrames, W, H) — frame on axis 0
            fi = min(fi, mag_full.shape[0] - 1)
            mag  = mag_full[fi].T    # transpose (W,H) → (H,W)
            dirs = dirs_full[fi].T
        else:
            # 2D — already spatial, no frame index needed
            mag  = mag_full.T if mag_full.shape[0] != mag_full.shape[1] else mag_full
            dirs = dirs_full.T if dirs_full.shape[0] != dirs_full.shape[1] else dirs_full

        return mag.astype(np.float32), dirs.astype(np.float32)
    except Exception as e:
        print(f'  EMD frame error (st={st}, lv={lv}, f={frame_idx_matlab}): {e}')
        return None, None


# ── Shared helpers ────────────────────────────────────────────────────────
def norm_map(m):
    mn, mx = float(m.min()), float(m.max())
    if mx - mn < 1e-10:
        return np.zeros_like(m, dtype=np.float32)
    return (m.astype(np.float32) - mn) / (mx - mn)


def radial_proj(x_pts, y_pts, vx, vy, cx, cy):
    dx = x_pts - cx; dy = y_pts - cy
    dist = np.sqrt(dx**2 + dy**2)
    valid = dist > 2.0
    rp = np.full(len(x_pts), np.nan)
    if valid.sum() == 0:
        return rp
    rp[valid] = (vx[valid]*(dx[valid]/dist[valid]) +
                 vy[valid]*(dy[valid]/dist[valid]))
    return rp


def arrow_color_rp(v):
    if np.isnan(v): return 'grey'
    if v >  0.3: return '#FFD700'
    if v < -0.3: return '#4477FF'
    return '#888888'


def draw_rp_arrows(ax, bg_rgb, x_pts, y_pts, vx, vy, rp, scale=6.0):
    ax.imshow(bg_rgb, interpolation='nearest', aspect='auto')
    ax.axis('off')
    if len(x_pts) == 0:
        return
    mag = np.sqrt(vx**2 + vy**2)
    for i in range(len(x_pts)):
        m = mag[i] if i < len(mag) else 1.0
        if m < 1e-6: continue
        col = arrow_color_rp(rp[i] if i < len(rp) else np.nan)
        ax.annotate('', xy=(x_pts[i]+(vx[i]/m)*scale, y_pts[i]+(vy[i]/m)*scale),
                    xytext=(x_pts[i], y_pts[i]),
                    arrowprops=dict(arrowstyle='->', color=col,
                                   lw=0.9, mutation_scale=6),
                    annotation_clip=True)


# ── Overlay builders ──────────────────────────────────────────────────────
def make_overlay(gt_u8, err_n, emd_n, thresh=0.12):
    """
    Dark background from gt_frame + red=PredNet error + green=EMD mag.
    All inputs in same coordinate space (256x256).
    """
    if gt_u8 is not None:
        bg = (gt_u8.mean(axis=2) if gt_u8.ndim==3 else gt_u8).astype(np.float32)/255.0
    else:
        bg = np.zeros((err_n.shape[0], err_n.shape[1]), dtype=np.float32)
    rgb = np.stack([bg*0.28]*3, axis=2)
    em = err_n > thresh
    rgb[:,:,0] = np.where(em, err_n, rgb[:,:,0])
    rgb[:,:,1] = np.where(em, 0,     rgb[:,:,1])
    rgb[:,:,2] = np.where(em, 0,     rgb[:,:,2])
    emd_m = emd_n > thresh
    rgb[:,:,1] = np.maximum(rgb[:,:,1], np.where(emd_m, emd_n, 0))
    return np.clip(rgb, 0, 1)


def make_split(gt_u8, err_n, emd_n):
    """Left=EMD green, right=PredNet red, on dark background."""
    if gt_u8 is not None:
        bg = (gt_u8.mean(axis=2) if gt_u8.ndim==3 else gt_u8).astype(np.float32)/255.0
    else:
        bg = np.zeros((err_n.shape[0], err_n.shape[1]), dtype=np.float32)
    rgb = np.stack([bg*0.28]*3, axis=2)
    mid = err_n.shape[1] // 2
    rgb[:, :mid, 1] = emd_n[:, :mid]
    rgb[:, mid:, 0] = err_n[:, mid:]
    return np.clip(rgb, 0, 1)


#SPATIAL OVERLAP OF STRONGEST MAGNITUDE AND ERROR
print('\nAnalysis 1: spatial overlap...')

overlap_r    = {}
overlap_diff = {}

COND_LEVEL_LABELS = {
    'edgeSiz_low'  : 'Edge Size\nlow (0.01)',
    'edgeSiz_high' : 'Edge Size\nhigh (0.10)',
    'edgeCon_low'  : 'Edge Contrast\nlow (0.25)',
    'edgeCon_high' : 'Edge Contrast\nhigh (0.50)',
    'speed_low'    : 'Speed\nlow (0.004)',
    'speed_high'   : 'Speed\nhigh (0.040)',
    'wheelCon_low' : 'Wheel Contrast\nlow (0.25)',
    'wheelCon_high': 'Wheel Contrast\nhigh (0.50)',
}

CELL1 = 2.6
fig1 = plt.figure(figsize=(CELL1*4 + 1.4, CELL1*3 + 0.8))
gs1  = gridspec.GridSpec(3, 4, figure=fig1, hspace=0.08, wspace=0.05,
                          left=0.16, right=0.97, top=0.88, bottom=0.03)
fig1.suptitle(
    'Spatial Overlap: EMD Magnitude (green) vs PredNet Error (red)  |  t = 0.30s',
    fontsize=11, fontweight='bold')

row_hdrs = [
    'Low level',
    'High level',
    'Difference (High \u2212 Low)\ngreen=EMD\u2191  red=PredNet\u2191  blue=PredNet\u2193',
]
for ri, hdr in enumerate(row_hdrs):
    fig1.text(0.02, 0.88 - (ri+0.5)*(0.85/3),
              hdr, ha='center', va='center', fontsize=8,
              fontweight='bold', rotation=90)


cond_data = {}
for cond_low, cond_high, _ in COND_PAIRS:
    for cond in [cond_low, cond_high]:
        rd  = pretrained.get(cond, {})
        err = rd.get('error_map', None)
        gt  = rd.get('gt_frame',  None)
        if err is None or cond not in COND_TO_EMD:
            cond_data[cond] = None; continue
        st, lv = COND_TO_EMD[cond]
        mag_raw, _ = get_emd_frame(st, lv, 36)
        if mag_raw is None:
            cond_data[cond] = None; continue
        emd_n   = norm_map(mag_raw)
        err_256 = cv2.resize(norm_map(err).astype(np.float32),
                             (EMD_SZ, EMD_SZ), interpolation=cv2.INTER_LINEAR)
        if gt is not None:
            gt_f = (gt if gt.ndim==2 else gt.mean(axis=2)).astype(np.float32)
            gt_256_u8 = cv2.resize(gt_f, (EMD_SZ, EMD_SZ),
                                   interpolation=cv2.INTER_LINEAR).astype(np.uint8)
        else:
            gt_256_u8 = None
        r, _ = stats_lib.pearsonr(emd_n.ravel(), err_256.ravel())
        overlap_r[cond] = r
        cond_data[cond] = (emd_n, err_256, gt_256_u8)

for ci, (cond_low, cond_high, pair_label) in enumerate(COND_PAIRS):
    d_low  = cond_data.get(cond_low)
    d_high = cond_data.get(cond_high)

    # Column header
    fig1.text(0.16 + (ci+0.5)*(0.81/4), 0.905,
              pair_label, ha='center', va='bottom',
              fontsize=9, fontweight='bold')

    # Row 0 — Low
    ax = fig1.add_subplot(gs1[0, ci])
    if d_low:
        emd_n, err_256, gt_u8 = d_low
        ax.imshow(make_overlay(gt_u8, err_256, emd_n),
                  interpolation='nearest', aspect='auto')
        ax.set_title(COND_LEVEL_LABELS.get(cond_low,'').split('\n')[1], fontsize=6.5, color='white', pad=1)
    ax.axis('off')

    # Row 1 — High
    ax = fig1.add_subplot(gs1[1, ci])
    if d_high:
        emd_n, err_256, gt_u8 = d_high
        ax.imshow(make_overlay(gt_u8, err_256, emd_n),
                  interpolation='nearest', aspect='auto')
        ax.set_title(COND_LEVEL_LABELS.get(cond_high,'').split('\n')[1], fontsize=6.5, color='white', pad=1)
    ax.axis('off')

    # Row 2 — Diff
    ax = fig1.add_subplot(gs1[2, ci])
    if d_low and d_high:
        emd_diff = d_high[0] - d_low[0]
        err_diff = d_high[1] - d_low[1]
        bg_ref   = d_high[2]
        bg_f = (bg_ref.astype(np.float32)/255.0) if bg_ref is not None \
               else np.zeros((EMD_SZ, EMD_SZ), dtype=np.float32)
        diff_img = np.stack([bg_f*0.18]*3, axis=2)
        diff_img[:,:,0] = np.maximum(diff_img[:,:,0], np.clip( err_diff*3, 0, 1))
        diff_img[:,:,2] = np.maximum(diff_img[:,:,2], np.clip(-err_diff*3, 0, 1))
        diff_img[:,:,1] = np.maximum(diff_img[:,:,1], np.clip( emd_diff*3, 0, 1))
        ax.imshow(np.clip(diff_img,0,1), interpolation='nearest', aspect='auto')
        r_diff, _ = stats_lib.pearsonr(emd_diff.ravel(), err_diff.ravel())
        overlap_diff[pair_label] = r_diff
    ax.axis('off')

out1 = os.path.join(OUT_DIR, 'spatial_overlap.png')
plt.savefig(out1, dpi=180, facecolor='white')
plt.show()
print(f'Saved: {out1}')


# PredNet architecture + loaders 
import math
class ConvLSTMCell(nn.Module):
    def __init__(self,inc,outc,ks,stride=1,padding=1,dilation=1,groups=1,bias=True):
        super().__init__()
        from torch.nn.modules.utils import _pair as _p
        ks=_p(ks);stride=_p(stride);padding=_p(padding);dilation=_p(dilation)
        self.in_channels=inc;self.out_channels=outc;self.kernel_size=ks
        self.stride=stride;self.padding=padding
        self.padding_h=tuple(k//2 for k,s,p,d in zip(ks,stride,padding,dilation))
        self.dilation=dilation;self.groups=groups
        self.weight_ih=Parameter(torch.Tensor(4*outc,inc//groups,*ks))
        self.weight_hh=Parameter(torch.Tensor(4*outc,outc//groups,*ks))
        self.weight_ch=Parameter(torch.Tensor(3*outc,outc//groups,*ks))
        self.bias_ih=Parameter(torch.Tensor(4*outc))
        self.bias_hh=Parameter(torch.Tensor(4*outc))
        self.bias_ch=Parameter(torch.Tensor(3*outc))
        self.register_buffer('wc_blank',torch.zeros(1,1,1,1))
        self.reset_parameters()
    def reset_parameters(self):
        n=4*self.in_channels
        for k in self.kernel_size: n*=k
        s=1./math.sqrt(n)
        for w in [self.weight_ih,self.weight_hh,self.weight_ch,
                  self.bias_ih,self.bias_hh,self.bias_ch]: w.data.uniform_(-s,s)
    def forward(self,x,hx):
        h0,c0=hx
        wx=F.conv2d(x,self.weight_ih,self.bias_ih,self.stride,self.padding,self.dilation,self.groups)
        wh=F.conv2d(h0,self.weight_hh,self.bias_hh,self.stride,self.padding_h,self.dilation,self.groups)
        wc=F.conv2d(c0,self.weight_ch,self.bias_ch,self.stride,self.padding_h,self.dilation,self.groups)
        wxhc=wx+wh+torch.cat((wc[:,:2*self.out_channels],
            self.wc_blank.expand(wc.size(0),wc.size(1)//3,wc.size(2),wc.size(3)),
            wc[:,2*self.out_channels:]),dim=1)
        i=torch.sigmoid(wxhc[:,:self.out_channels])
        f=torch.sigmoid(wxhc[:,self.out_channels:2*self.out_channels])
        g=torch.tanh(wxhc[:,2*self.out_channels:3*self.out_channels])
        o=torch.sigmoid(wxhc[:,3*self.out_channels:])
        c1=f*c0+i*g; h1=o*torch.tanh(c1)
        return h1,(h1,c1)

class SatLU(nn.Module):
    def __init__(self,lo=0,hi=255): super().__init__(); self.lo=lo; self.hi=hi
    def forward(self,x): return F.hardtanh(x,self.lo,self.hi)

class PredNetModel(nn.Module):
    def __init__(self,R,A):
        super().__init__()
        self.r_channels=R; self.a_channels=A; self.n_layers=len(R)
        ra=R[1:]+(0,)
        for l in range(self.n_layers):
            setattr(self,f'cell{l}',ConvLSTMCell(2*A[l]+ra[l],R[l],ks=3))
        for l in range(self.n_layers):
            conv=nn.Sequential(nn.Conv2d(R[l],A[l],3,padding=1),nn.ReLU())
            if l==0: conv.add_module('satlu',SatLU())
            setattr(self,f'conv{l}',conv)
        self.mp=nn.MaxPool2d(2,2); self.up=nn.Upsample(scale_factor=2)
        for l in range(self.n_layers-1):
            setattr(self,f'uA{l}',nn.Sequential(nn.Conv2d(2*A[l],A[l+1],3,padding=1),self.mp))
        for l in range(self.n_layers): getattr(self,f'cell{l}').reset_parameters()
    def forward(self,x):
        B,T=x.size(0),x.size(1); H,W=x.size(-2),x.size(-1); dv=x.device
        E=[torch.zeros(B,2*self.a_channels[l],H//2**l,W//2**l,device=dv) for l in range(self.n_layers)]
        R=[torch.zeros(B,  self.r_channels[l],H//2**l,W//2**l,device=dv) for l in range(self.n_layers)]
        Hs=[None]*self.n_layers; fp=None
        for t in range(T):
            A=x[:,t].float()
            for l in reversed(range(self.n_layers)):
                hx=Hs[l] if Hs[l] is not None else(R[l],R[l])
                li=E[l] if l==self.n_layers-1 else torch.cat([E[l],self.up(R[l+1])],dim=1)
                R[l],Hs[l]=getattr(self,f'cell{l}')(li,hx)
            for l in range(self.n_layers):
                Ah=getattr(self,f'conv{l}')(R[l])
                if l==0: fp=Ah
                E[l]=torch.cat([F.relu(Ah-A),F.relu(A-Ah)],dim=1)
                if l<self.n_layers-1: A=getattr(self,f'uA{l}')(E[l])
        return fp

def load_prednet():
    m=PredNetModel((3,48,96,192),(3,48,96,192))
    ckpt=torch.load(WEIGHTS_PATH,map_location=device)
    sd=ckpt.get('model_state_dict',ckpt.get('state_dict',ckpt))
    sd={k.replace('module.',''):v for k,v in sd.items()}
    m.load_state_dict(sd,strict=False)
    return m.to(device).eval()

def load_npy_frames(cond):
    npy_files=sorted(glob.glob(os.path.join(STIM_DIR,cond,'*.npy')))
    if not npy_files: return None
    frames=[np.load(p).astype(np.float32) for p in npy_files]
    if frames[0].shape[0]==1: frames=[np.repeat(f,3,axis=0) for f in frames]
    return torch.from_numpy(np.stack(frames)).unsqueeze(0).to(device)

def tensor_to_u8(t):
    arr=t.squeeze().cpu().numpy()
    if arr.ndim==3: arr=arr.transpose(1,2,0)
    return np.clip(arr,0,255).astype(np.uint8)


print('  Loading model...')
model = load_prednet()

# Run PredNet at 3 time points for both speed conditions
print('  Running temporal inference...')
temporal = {}
for cond in ['speed_low','speed_high']:
    temporal[cond] = []
    inp = load_npy_frames(cond)
    if inp is None:
        temporal[cond] = [(None,None,None)]*3
        continue
    for npy_idx in TPOINTS_NPY:
        with torch.no_grad():
            pred = model(inp[:, :npy_idx+1])
        gt_t    = inp[:, npy_idx]
        err     = torch.abs(pred-gt_t).squeeze().cpu().numpy()
        err_map = err.mean(axis=0) if err.ndim==3 else err
        temporal[cond].append((tensor_to_u8(inp[:,npy_idx]),
                               tensor_to_u8(pred),
                               err_map))

del model
if torch.cuda.is_available(): torch.cuda.empty_cache()

#FIGURE 2

CELL2 = 2.5
fig2 = plt.figure(figsize=(CELL2*3 + 3.5, CELL2*4 + 1.0))
gs2  = gridspec.GridSpec(4, 4, figure=fig2,
                          width_ratios=[CELL2, CELL2, CELL2, 3.0],
                          hspace=0.07, wspace=0.07,
                          left=0.10, right=0.97, top=0.93, bottom=0.06)
fig2.suptitle(
    'Temporal Radial Flow  |  Speed condition\n'
    'Yellow = outward  |  Blue = inward  |  Grey = tangential',
    fontsize=10, fontweight='bold')

total_img_w = CELL2*3
for ci, t_s in enumerate(TPOINTS_S):
    fig2.text(0.10 + (ci+0.5)*(total_img_w/(total_img_w+3.5))*0.87,
              0.955, f't = {t_s:.3f}s',
              ha='center', va='bottom', fontsize=9, fontweight='bold')
fig2.text(0.10 + (total_img_w + 1.5)/(total_img_w+3.5)*0.87,
          0.955, 'Mean outward\nradial projection',
          ha='center', va='bottom', fontsize=8, fontweight='bold')

row_labels_f2 = [
    '2DMD\nSpeed LOW (0.004)',
    'LK flow GT frames\nSpeed LOW',
    '2DMD\nSpeed HIGH (0.040)',
    'LK flow GT frames\nSpeed HIGH',
]
for ri, lbl in enumerate(row_labels_f2):
    fig2.text(0.005, 0.93 - (ri+0.5)*(0.87/4),
              lbl, ha='left', va='center', fontsize=7,
              fontweight='bold', rotation=90)

mean_rp_emd  = {'speed_low':[], 'speed_high':[]}
mean_rp_pred = {'speed_low':[], 'speed_high':[]}

for speed_i, cond in enumerate(['speed_low','speed_high']):
    st, lv   = COND_TO_EMD[cond]
    row_emd  = speed_i * 2
    row_lk   = speed_i * 2 + 1

    # Load all GT frames for consecutive LK
    npy_files = sorted(glob.glob(os.path.join(STIM_DIR, cond, '*.npy')))
    gt_frames_all = []
    for p in npy_files:
        arr = np.load(p).astype(np.float32)
        if arr.shape[0] == 1:
            arr = np.repeat(arr, 3, axis=0)
        gt_frames_all.append(np.clip(arr.transpose(1,2,0), 0, 255).astype(np.uint8))

    for ti, (matlab_frame, t_s, npy_idx) in enumerate(
            zip(TPOINTS_MATLAB, TPOINTS_S, TPOINTS_NPY)):

        # 2DMD
        ax = fig2.add_subplot(gs2[row_emd, ti])
        mag, dirs = get_emd_frame(st, lv, matlab_frame)
        if mag is not None:
            mag_r  = cv2.resize(mag,  (TARGET_W,TARGET_H), interpolation=cv2.INTER_LINEAR)
            dirs_r = cv2.resize(dirs, (TARGET_W,TARGET_H), interpolation=cv2.INTER_LINEAR)
            flat_idx = np.argsort(mag_r.ravel())[::-1][:60]
            row_i, col_i = np.unravel_index(flat_idx, mag_r.shape)
            x_e = col_i.astype(float); y_e = row_i.astype(float)
            d_e = dirs_r.ravel()[flat_idx]
            vx_e = np.cos(d_e); vy_e = np.sin(d_e)
            rp_e = radial_proj(x_e, y_e, vx_e, vy_e, TARGET_W/2, TARGET_H/2)
            bg = np.zeros((TARGET_H,TARGET_W,3), dtype=np.float32)
            bg[:,:,1] = norm_map(mag_r) * 0.7
            draw_rp_arrows(ax, (bg*255).astype(np.uint8), x_e,y_e,vx_e,vy_e,rp_e)
            mrp = float(np.nanmean(rp_e))
            mean_rp_emd[cond].append(mrp)
            ax.text(0.04,0.04,f'RP={mrp:+.2f}',transform=ax.transAxes,
                    fontsize=6.5,color='white',va='bottom',
                    bbox=dict(boxstyle='round,pad=0.2',facecolor='black',alpha=0.5))
        else:
            ax.axis('off'); mean_rp_emd[cond].append(np.nan)

        # LK on consecutive GT frames
        ax = fig2.add_subplot(gs2[row_lk, ti])
        if npy_idx > 0 and npy_idx < len(gt_frames_all):
            gt_curr = gt_frames_all[npy_idx]
            gt_prev = gt_frames_all[npy_idx - 1]
            ax.imshow(gt_curr, interpolation='nearest', aspect='auto')
            ax.axis('off')
            ga = cv2.cvtColor(gt_prev, cv2.COLOR_RGB2GRAY)
            gb = cv2.cvtColor(gt_curr, cv2.COLOR_RGB2GRAY)
            pts = cv2.goodFeaturesToTrack(ga, 300, 0.01, 4)
            if pts is not None:
                pts2, st_lk, _ = cv2.calcOpticalFlowPyrLK(
                    ga, gb, pts, None, winSize=(15,15), maxLevel=3,
                    criteria=(cv2.TERM_CRITERIA_EPS|cv2.TERM_CRITERIA_COUNT,30,0.03))
                old_p = pts[st_lk==1]; new_p = pts2[st_lk==1]
                if len(old_p) > 0:
                    vx_p = new_p[:,0]-old_p[:,0]
                    vy_p = new_p[:,1]-old_p[:,1]
                    mag_p = np.sqrt(vx_p**2+vy_p**2)
                    rp_p = radial_proj(old_p[:,0],old_p[:,1],vx_p,vy_p,
                                       TARGET_W/2,TARGET_H/2)
                    for i in range(len(old_p)):
                        m = mag_p[i]
                        if m < 0.3: continue
                        col = arrow_color_rp(rp_p[i] if i<len(rp_p) else np.nan)
                        sc = min(m*3, 8.0)
                        ax.annotate('',
                            xy=(old_p[i,0]+(vx_p[i]/m)*sc,
                                old_p[i,1]+(vy_p[i]/m)*sc),
                            xytext=(old_p[i,0], old_p[i,1]),
                            arrowprops=dict(arrowstyle='->',color=col,
                                           lw=0.9,mutation_scale=6),
                            annotation_clip=True)
                    mrp = float(np.nanmean(rp_p))
                    mean_rp_pred[cond].append(mrp)
                    ax.text(0.04,0.04,f'RP={mrp:+.2f}',transform=ax.transAxes,
                            fontsize=6.5,color='white',va='bottom',
                            bbox=dict(boxstyle='round,pad=0.2',
                                      facecolor='black',alpha=0.5))
                    continue
            mean_rp_pred[cond].append(np.nan)
        elif npy_idx == 0 and len(gt_frames_all) > 0:
            ax.imshow(gt_frames_all[0], interpolation='nearest', aspect='auto')
            ax.axis('off')
            mean_rp_pred[cond].append(np.nan)
        else:
            ax.axis('off'); mean_rp_pred[cond].append(np.nan)

# Summary line plot spanning all rows in col 3
ax_s = fig2.add_subplot(gs2[:, 3])
colours = {'speed_low':'#4C9BE8', 'speed_high':'#E87B4C'}
for cond, col in colours.items():
    lbl = 'Slow (0.004)' if 'low' in cond else 'Fast (0.040)'
    ax_s.plot(TPOINTS_S, mean_rp_emd[cond],  'o-',  color=col, lw=2,
              label=f'2DMD {lbl}', markersize=7)
    ax_s.plot(TPOINTS_S, mean_rp_pred[cond], 's--', color=col, lw=1.5,
              label=f'GT LK {lbl}', markersize=5, alpha=0.8)
ax_s.axhline(0, color='grey', lw=0.8, ls='--')
ax_s.set_xlabel('Time (s)', fontsize=9)
ax_s.set_ylabel('Mean outward radial projection', fontsize=9)
ax_s.legend(fontsize=7, loc='best')
ax_s.set_ylim(-1.1, 1.1)
ax_s.spines[['top','right']].set_visible(False)
ax_s.grid(axis='y', alpha=0.3)
ax_s.set_xticks(TPOINTS_S)

out2 = os.path.join(OUT_DIR, 'temporal_flow.png')
plt.savefig(out2, dpi=180, facecolor='white')
plt.show()
print(f'Saved: {out2}')

# PRINT
print('\n── Spatial overlap Pearson r ───────────────────────────────────')
for cond, r in sorted(overlap_r.items()):
    print(f'  {cond:22s}  r = {r:+.4f}')

print('\n── Diff correlation (High−Low) ─────────────────────────────────')
for pair_label, r_diff in overlap_diff.items():
    print(f'  {pair_label:20s}  r_diff = {r_diff:+.4f}')

print(f'\nOutputs saved to {OUT_DIR}/')
