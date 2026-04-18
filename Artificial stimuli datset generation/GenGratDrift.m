function IM = GenGratDrift(nRows, nCols, nFrames, nLevels, hparams, vparams)
% GenGratDrift  Generate a drifting sinusoidal grating stimulus.
%
% Usage:
%   IM = GenGratDrift(nRows, nCols, nFrames, nLevels, hparams, vparams)
%
% Inputs:
%   nRows    - image height in pixels
%   nCols    - image width  in pixels
%   nFrames  - number of frames to generate
%   nLevels  - number of grey levels (e.g. 256 for 8-bit)
%   hparams  - [SF_h,  spd_h]  horizontal spatial frequency (cycles/image)
%                               and drift speed (pixels per frame, signed)
%   vparams  - [SF_v,  spd_v]  vertical   spatial frequency and speed
%                               (set to [0 0] for a purely horizontal grating)
%
% Output:
%   IM       - [nRows x nCols x nFrames] double array, values in [0, nLevels-1]
%
% Notes:
%   • Luminance is centred at nLevels/2 with full contrast (amplitude = nLevels/2).
%   • Phase is advanced by (2π * SF * speed / imageSize) per frame so that the
%     grating drifts at exactly `speed` pixels per frame.
%   • Positive speed → rightward / downward drift; negative → leftward / upward.
%
% Example (from CodeTestScriptD.m):
%   hparams = [8, -2];  vparams = [0, 0];
%   IM = GenGratDrift(256, 256, 32, 256, hparams, vparams);
%
% Authors: [Your Name] — interface compatible with CodeTestScriptD.m
% -------------------------------------------------------------------------

    % --- unpack params ---------------------------------------------------
    sf_h  = hparams(1);   spd_h = hparams(2);
    sf_v  = vparams(1);   spd_v = vparams(2);

    % --- spatial coordinate grids  (normalised 0…1) ----------------------
    x = (0:nCols-1) / nCols;          % 1 x nCols
    y = (0:nRows-1) / nRows;          % 1 x nRows
    [X, Y] = meshgrid(x, y);           % nRows x nCols

    % --- base spatial grating (no temporal phase yet) --------------------
    %   phase advances by  2π * sf * speed / imageSize  per frame
    %   which equals       2π * sf_h * spd_h / nCols   radians
    %   (since x is normalised, one full period spans nCols/sf_h pixels)
    phase_step_h = 2*pi * sf_h * spd_h / nCols;
    phase_step_v = 2*pi * sf_v * spd_v / nRows;

    mid   = (nLevels - 1) / 2;        % DC level  (127.5 for 256 levels)
    amp   = mid;                       % full contrast amplitude

    IM = zeros(nRows, nCols, nFrames);

    for t = 1:nFrames
        phase_t = (t - 1) * (phase_step_h + phase_step_v);
        % Grating: sum of horizontal and vertical components
        grat = sin(2*pi * (sf_h*X + sf_v*Y) + phase_t);
        IM(:,:,t) = mid + amp .* grat;
    end

    % Clamp to valid range  [0, nLevels-1]
    IM = max(0, min(nLevels - 1, IM));

end
