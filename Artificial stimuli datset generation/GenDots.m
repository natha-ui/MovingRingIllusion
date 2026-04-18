function IM = GenDots(nRows, nCols, nFrames, nLevels, aparams, bparams)
% GenDots  Generate a moving random-dot kinematogram (RDK) stimulus.
%
% Usage:
%   IM = GenDots(nRows, nCols, nFrames, nLevels, aparams, bparams)
%
% Inputs:
%   nRows    - image height in pixels
%   nCols    - image width  in pixels
%   nFrames  - number of frames to generate
%   nLevels  - number of grey levels (e.g. 256)
%   aparams  - [nDots, xSpd, ySpd, dotRadius]  first  dot population
%   bparams  - [nDots, xSpd, ySpd, dotRadius]  second dot population
%
% Output:
%   IM       - [nRows x nCols x nFrames] double array, values in [0, nLevels-1]
%
% Notes:
%   • Background luminance = nLevels/2  (mid-grey).
%   • Dots are filled white circles (luminance = nLevels-1).
%   • Dots wrap toroidally at image boundaries.
%   • Rendering is fully vectorised — no per-dot loop.
%
% Authors: [Your Name] — interface compatible with CodeTestScriptD.m
% -------------------------------------------------------------------------

    % --- unpack params ---------------------------------------------------
    nDots_a = aparams(1);  xSpd_a = aparams(2);
    ySpd_a  = aparams(3);  rad_a  = aparams(4);

    nDots_b = bparams(1);  xSpd_b = bparams(2);
    ySpd_b  = bparams(3);  rad_b  = bparams(4);

    mid     = (nLevels - 1) / 2;
    dot_lum = nLevels - 1;

    % --- pixel coordinate grids  [nRows x nCols] -------------------------
    [Xg, Yg] = meshgrid(1:nCols, 1:nRows);

    % Flatten to column vectors for broadcasting  [nPixels x 1]
    Xg_flat = Xg(:);
    Yg_flat = Yg(:);
    nPix    = nRows * nCols;

    % --- random initial positions ----------------------------------------
    pos_ax = rand(1, nDots_a) * nCols;   % [1 x nDots_a]
    pos_ay = rand(1, nDots_a) * nRows;
    pos_bx = rand(1, nDots_b) * nCols;
    pos_by = rand(1, nDots_b) * nRows;

    IM = zeros(nRows, nCols, nFrames);

    for t = 1:nFrames

        canvas = false(nPix, 1);   % logical mask — any dot present?

        % --- population A  [nPixels x nDots_a] --------------------------
        dx_a = min(abs(Xg_flat - pos_ax), nCols - abs(Xg_flat - pos_ax));
        dy_a = min(abs(Yg_flat - pos_ay), nRows - abs(Yg_flat - pos_ay));
        canvas = canvas | any(dx_a.^2 + dy_a.^2 <= rad_a^2, 2);

        % --- population B  [nPixels x nDots_b] --------------------------
        dx_b = min(abs(Xg_flat - pos_bx), nCols - abs(Xg_flat - pos_bx));
        dy_b = min(abs(Yg_flat - pos_by), nRows - abs(Yg_flat - pos_by));
        canvas = canvas | any(dx_b.^2 + dy_b.^2 <= rad_b^2, 2);

        % --- compose frame -----------------------------------------------
        frame          = mid * ones(nPix, 1);
        frame(canvas)  = dot_lum;
        IM(:,:,t)      = reshape(frame, nRows, nCols);

        % --- advance positions (wrap toroidally) -------------------------
        pos_ax = mod(pos_ax + xSpd_a, nCols);
        pos_ay = mod(pos_ay + ySpd_a, nRows);
        pos_bx = mod(pos_bx + xSpd_b, nCols);
        pos_by = mod(pos_by + ySpd_b, nRows);

    end

    IM = max(0, min(nLevels - 1, IM));

end
