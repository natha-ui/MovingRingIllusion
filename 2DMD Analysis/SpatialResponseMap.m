% Script Name:  SpatialResponseMap.m
% Authors:      K22007681
% Date:         March 2026
% Version:      2.0
% Purpose:      Compare the spatial distribution of top EMD magnitude
%               responses between the minimum (level 1) and maximum
%               (level 6) of each condition dimension, across four time
%               points (0.1, 0.2, 0.3, 0.4 s).
%
%               Layout per figure (one figure per condition):
%                 Row 1: minimum condition — overlay at t1 t2 t3 t4
%                 Row 2: maximum condition — overlay at t1 t2 t3 t4
%                 Row 3: difference (max minus min response magnitude)
%                        red = max responds more strongly
%                        blue = min responds more strongly
%
%               No blur. Pixel colour encodes relative response magnitude
%               within the selected set (yellow = strongest, red = weakest
%               of selected set). A fifth figure shows the reference.
%
% Requires: emd in workspace

%% Check have params
if ~exist('emd','var'), TwoDCorrMotDetBaseParamsA; end

szDim     = 256;
numSeg    = 4;
radVec    = [0.45 0.70];
motionDir = 1;
Hz        = 120;
nFrames   = round(0.75 * Hz);

dPhi     = 16;    % replace with best_dPhi
tau      = 2;    % replace with best_tau
GlobProp = 0.30;
RThr     = 0.01;
emd.filtparams.prepro = 0;

tPoints_s = [0.1  0.2  0.3  0.4];
tFrames   = round(tPoints_s * Hz);
nTP       = numel(tPoints_s);
overlayAlpha = 0.70;

edgeSizCond  = [0.01 0.02 0.04 0.06 0.08 0.10];
edgeConCond  = [0.25 0.30 0.35 0.40 0.45 0.50];
speedCond    = [0.004 0.006 0.008 0.010 0.020 0.040];
wheelConCond = [0.25 0.30 0.35 0.40 0.45 0.50];

mnConEdge  = mean(edgeConCond(3:4));
mnConWhl   = mean(wheelConCond(3:4));
edgeSzRef  = mean(edgeSizCond(3:4));
radSpdRef  = mean(speedCond(3:4));
baseGryRef = [0.5-mnConWhl 0.5+mnConWhl 0.5-mnConEdge 0.5+mnConEdge];

dummyFlt   = DoFilterArray(zeros(szDim,szDim,2,'uint8'), dPhi, emd);
[~, ExBin] = ExclReg(dummyFlt(:,:,1), emd.Default.MM);
IncInd     = find(ExBin == 0);
ExBin_logi = logical(reshape(ExBin, szDim, szDim));


condDefs = {
    'Edge size',      'edgeSiz';
    'Edge contrast',  'edgeCon';
    'Rotation speed', 'speed';
    'Wheel contrast', 'wheelCon';
};
nConds = size(condDefs,1);


for ci = 1:nConds
    condLabel = condDefs{ci,1};
    condType  = condDefs{ci,2};
    fprintf('Condition: %s\n', condLabel);

    % Build min and max stimuli
    IM_lv = cell(1,2);
    lvIdx = [1 6];
    for li = 1:2
        lv = lvIdx(li);
        switch condType
            case 'edgeSiz'
                IM_lv{li} = WheelSpinRadialb(szDim,numSeg,radVec, ...
                    edgeSizCond(lv),baseGryRef,nFrames,radSpdRef,motionDir);
            case 'edgeCon'
                bG = [0.5-mnConWhl 0.5+mnConWhl ...
                      0.5-edgeConCond(lv) 0.5+edgeConCond(lv)];
                IM_lv{li} = WheelSpinRadialb(szDim,numSeg,radVec, ...
                    edgeSzRef,bG,nFrames,radSpdRef,motionDir);
            case 'speed'
                IM_lv{li} = WheelSpinRadialb(szDim,numSeg,radVec, ...
                    edgeSzRef,baseGryRef,nFrames,speedCond(lv),motionDir);
            case 'wheelCon'
                bG = [0.5-wheelConCond(lv) 0.5+wheelConCond(lv) ...
                      0.5-mnConEdge 0.5+mnConEdge];
                IM_lv{li} = WheelSpinRadialb(szDim,numSeg,radVec, ...
                    edgeSzRef,bG,nFrames,radSpdRef,motionDir);
        end
    end

    % Filter + EMD
    oR_lv = cell(1,2);
    for li = 1:2
        fImg = DoFilterArray(uint8(IM_lv{li}*255), dPhi, emd);
        [~,~,oR_tmp,~] = DoEMDArrays(fImg, tau, dPhi, emd);
        oR_lv{li} = oR_tmp;
    end

    % Figure
    figure(10+ci); clf;
    set(gcf,'Color','k','Position',[10 10 1350 800]);

    rowLabels = {sprintf('Min  (level 1: %.3g)', ...
                          eval([condType 'Cond(1)'])), ...
                 sprintf('Max  (level 6: %.3g)', ...
                          eval([condType 'Cond(6)']))};

    % Use condition-specific value for row labels without eval
    switch condType
        case 'edgeSiz'
            rowLabels = {sprintf('Min (%.4f)', edgeSizCond(1)), ...
                         sprintf('Max (%.4f)', edgeSizCond(6))};
        case 'edgeCon'
            rowLabels = {sprintf('Min (%.2f)', edgeConCond(1)), ...
                         sprintf('Max (%.2f)', edgeConCond(6))};
        case 'speed'
            rowLabels = {sprintf('Min (%.4f)', speedCond(1)), ...
                         sprintf('Max (%.4f)', speedCond(6))};
        case 'wheelCon'
            rowLabels = {sprintf('Min (%.2f)', wheelConCond(1)), ...
                         sprintf('Max (%.2f)', wheelConCond(6))};
    end

    for tp = 1:nTP
        fr = min(tFrames(tp), nFrames);

        compPair = cell(1,2);
        magCleanPair = zeros(szDim,szDim,2);

        for li = 1:2
            stimFrame = IM_lv{li}(:,:,fr);
            magClean  = oR_lv{li}(:,:,fr);
            magClean(ExBin_logi) = 0;
            magCleanPair(:,:,li) = magClean;

            % Select top GlobProp above RThr
            magVec = magClean(IncInd);
            abvThr = magVec > RThr;
            magAbv = magVec(abvThr);
            idxAbv = IncInd(abvThr);

            if isempty(magAbv)
                compPair{li} = repmat(stimFrame,[1 1 3]);
                continue
            end
            nSel = max(1,round(GlobProp*numel(magAbv)));
            [magSort,sOrd] = sort(magAbv,'descend');
            topIdx = idxAbv(sOrd(1:nSel));
            topMag = magSort(1:nSel);

            if max(topMag) > min(topMag)
                topMagNorm = (topMag-min(topMag))/(max(topMag)-min(topMag));
            else
                topMagNorm = ones(size(topMag));
            end

            % Yellow (strongest) to red (weakest of selected)
            stimRGB = repmat(stimFrame,[1 1 3]);
            rCh = zeros(szDim,szDim); gCh = zeros(szDim,szDim);
            rCh(topIdx) = 1.0;
            gCh(topIdx) = topMagNorm;
            oRGB  = cat(3,rCh,gCh,zeros(szDim,szDim));
            oMask = zeros(szDim,szDim); oMask(topIdx) = overlayAlpha;
            oMask3 = repmat(oMask,[1 1 3]);
            compPair{li} = stimRGB.*(1-oMask3) + oRGB.*oMask3;
        end

        % Row 1: min
        ax = subplot(3, nTP, tp);
        imshow(compPair{1}, 'Parent', ax);
        title(ax, sprintf('t = %.1f s', tPoints_s(tp)), 'Color','w','FontSize',9);
        if tp==1; ylabel(ax, rowLabels{1}, 'Color','w','FontSize',8,'FontWeight','bold'); end

        % Row 2: max
        ax = subplot(3, nTP, nTP+tp);
        imshow(compPair{2}, 'Parent', ax);
        if tp==1; ylabel(ax, rowLabels{2}, 'Color','w','FontSize',8,'FontWeight','bold'); end

        % Row 3: difference map (max - min), overlaid on darkened stimulus
        diffMap  = magCleanPair(:,:,2) - magCleanPair(:,:,1);
        maxAbsDiff = max(abs(diffMap(:)));
        if maxAbsDiff > 1e-8
            diffNorm = diffMap / maxAbsDiff;
        else
            diffNorm = zeros(szDim,szDim);
        end

        % Red where max > min, blue where min > max
        % Intensity encodes magnitude of difference
        diffRGB = zeros(szDim,szDim,3);
        diffRGB(:,:,1) = max(diffNorm, 0);           % red = max stronger
        diffRGB(:,:,3) = max(-diffNorm, 0);          % blue = min stronger

        % Blend with darkened stimulus for spatial context
        bgStim  = repmat(IM_lv{2}(:,:,fr)*0.35, [1 1 3]);
        diffRGB = min(diffRGB + bgStim, 1);

        ax = subplot(3, nTP, 2*nTP+tp);
        imshow(diffRGB, 'Parent', ax);
        if tp==1; ylabel(ax,'Difference (max-min)','Color','w','FontSize',8,'FontWeight','bold'); end
        if tp==nTP
            text(ax, szDim*1.05, szDim*0.3, 'Red: max > min', ...
                 'Color','r','FontSize',7,'Units','data');
            text(ax, szDim*1.05, szDim*0.6, 'Blue: min > max', ...
                 'Color','c','FontSize',7,'Units','data');
        end
    end

    sgtitle(sprintf('%s — min vs max  |  dPhi=%d tau=%d GP=%.2f RThr=%.2f', ...
            condLabel, dPhi, tau, GlobProp, RThr), ...
            'Color','w','FontSize',10,'FontWeight','bold');
end


%% Reference figure

fprintf('Reference\n');
IM_ref = WheelSpinRadialb(szDim,numSeg,radVec, ...
         edgeSzRef,baseGryRef,nFrames,radSpdRef,motionDir);
fImg_ref = DoFilterArray(uint8(IM_ref*255), dPhi, emd);
[~,~,oR_ref,~] = DoEMDArrays(fImg_ref, tau, dPhi, emd);

figure(20); clf;
set(gcf,'Color','k','Position',[10 10 1300 360]);
for tp = 1:nTP
    fr = min(tFrames(tp), nFrames);
    stimFrame = IM_ref(:,:,fr);
    magClean  = oR_ref(:,:,fr); magClean(ExBin_logi) = 0;
    magVec    = magClean(IncInd);
    abvThr    = magVec > RThr;
    magAbv    = magVec(abvThr);
    idxAbv    = IncInd(abvThr);

    if ~isempty(magAbv)
        nSel = max(1,round(GlobProp*numel(magAbv)));
        [magSort,sOrd] = sort(magAbv,'descend');
        topIdx = idxAbv(sOrd(1:nSel)); topMag = magSort(1:nSel);
        if max(topMag)>min(topMag)
            tmn = (topMag-min(topMag))/(max(topMag)-min(topMag));
        else; tmn = ones(size(topMag)); end
        sRGB = repmat(stimFrame,[1 1 3]);
        rCh = zeros(szDim,szDim); gCh = zeros(szDim,szDim);
        rCh(topIdx)=1; gCh(topIdx)=tmn;
        oRGB = cat(3,rCh,gCh,zeros(szDim,szDim));
        oM = zeros(szDim,szDim); oM(topIdx)=overlayAlpha;
        oM3 = repmat(oM,[1 1 3]);
        comp = sRGB.*(1-oM3)+oRGB.*oM3;
    else; comp = repmat(stimFrame,[1 1 3]); end

    ax = subplot(1,nTP,tp);
    imshow(comp,'Parent',ax);
    title(ax,sprintf('t = %.1f s',tPoints_s(tp)),'Color','w','FontSize',10);
    if tp==1; ylabel(ax,'Reference','Color','w','FontSize',9,'FontWeight','bold'); end
end
sgtitle(sprintf('Reference  |  dPhi=%d tau=%d GP=%.2f RThr=%.2f', ...
        dPhi,tau,GlobProp,RThr),'Color','w','FontSize',10,'FontWeight','bold');
