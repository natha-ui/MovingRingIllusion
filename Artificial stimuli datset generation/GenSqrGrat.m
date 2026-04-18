function IM = GenSqrGrat(nRows, nCols, nFrames, nLevels, hparams, vparams)
% GenSqrGrat  Generate a drifting square-wave grating stimulus.
%
% Usage:
%   IM = GenSqrGrat(nRows, nCols, nFrames, nLevels, hparams, vparams)
%
% Inputs:
%   nRows    - image height in pixels
%   nCols    - image width  in pixels
%   nFrames  - number of frames to generate
%   nLevels  - number of grey levels (e.g. 256 for 8-bit)
%   hparams  - [SF_h, spd_h]  horizontal spatial frequency (cycles/image)
%                              and drift speed (pixels per frame, signed)
%   vparams  - [SF_v, spd_v]  vertical spatial frequency and speed
%                              (set to [0 0] for a purely horizontal grating)
%
% Output:
%   IM       - [nRows x nCols x nFrames] double array, values in [0, nLevels-1]
%
% Notes:
%   • Square-wave grating = sign(sin(…)), so pixel values are either 0 or
%     nLevels-1, giving maximum Michelson contrast.
%   • Phase advances identically to GenGratDrift — the two functions are
%     directly comparable (sine vs square).
%   • Positive speed → rightward / downward drift.
%
% Example (from CodeTestScriptD.m):
%   hparams = [8, 2];  vparams = [0, 0];
%   IM = GenSqrGrat(256, 256, 32, 256, hparams, vparams);
%
% Authors: [Your Name] — interface compatible with CodeTestScriptD.m
% -------------------------------------------------------------------------

    % --- unpack params ---------------------------------------------------
    sf_h  = hparams(1);   spd_h = hparams(2);
    sf_v  = vparams(1);   spd_v = vparams(2);

    % --- spatial coordinate grids  (normalised 0…1) ----------------------
    x = (0:nCols-1) / nCols;
    y = (0:nRows-1) / nRows;
    [X, Y] = meshgrid(x, y);

    % --- phase step per frame --------------------------------------------
    phase_step_h = 2*pi * sf_h * spd_h / nCols;
    phase_step_v = 2*pi * sf_v * spd_v / nRows;

    lo  = 0;                % dark bar luminance
    hi  = nLevels - 1;      % bright bar luminance  (255 for 8-bit)

    IM = zeros(nRows, nCols, nFrames);

    for t = 1:nFrames
        phase_t = (t - 1) * (phase_step_h + phase_step_v);
        sine_wave = sin(2*pi * (sf_h*X + sf_v*Y) + phase_t);
        % Binarise: positive half-cycle → bright, negative → dark
        sqr_wave = sign(sine_wave);          % values in {-1, 0, +1}
        % Map  -1 → lo,  +1 → hi  (treat 0 (rare) as lo)
        IM(:,:,t) = lo + (sqr_wave > 0) .* (hi - lo);
    end

    % Already at [0, nLevels-1] by construction, but clamp for safety
    IM = max(0, min(nLevels - 1, IM));

end
