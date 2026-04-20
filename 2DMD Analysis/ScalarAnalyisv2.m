% Script Name:  ScalarAnalysisv2.m
% Authors:      k22007681
% Date:         March 2026
% Version:      4.0

% Single unified readout for all conditions:
%   diff_whole — mean of top GlobProp fraction of above-RThr EMD magnitude
%                responses across all valid image pixels, differential
%                (test minus reference), frame-collapsed.

% Speed is accepted as the least well-fitted condition. Parameters are
% set to the values from ModelParameterSearch that best trade off edge
% size, edge contrast, and wheel contrast.

% Outputs: strengthFinal [6x6], strengthFinalNorm [6x6]

%check have initial params
if ~exist('emd','var'), TwoDCorrMotDetBaseParamsA; end
if ~exist('psychData','var')
    error('psychData not found — run LoadPsychometricData first.');
end

szDim     = 256;
numSeg    = 4;
radVec    = [0.45 0.70];
motionDir = 1;
nFrames   = round(0.75 * 120);   % 90 frames
nLevels   = 6;
nSweep    = 6;

%% MODEL PARAMS
% Replace with values from ModelParameterSearch output:
%   dPhi = best_dPhi; tau = best_tau;
%   GlobProp = best_GlobProp; RThr = best_RThr;
dPhi     = 16;
tau      = 2;
GlobProp = 0.80;
RThr     = 0.01;
emd.filtparams.prepro = 0;

edgeSizCond  = [0.01 0.02 0.04 0.06 0.08 0.10];
edgeConCond  = [0.25 0.30 0.35 0.40 0.45 0.50];
speedCond    = [0.004 0.006 0.008 0.010 0.020 0.040];
wheelConCond = [0.25 0.30 0.35 0.40 0.45 0.50];
ArrSzCond    = [0.54 0.63 0.72 0.81 0.90 0.99];

mnConEdge  = mean(edgeConCond(3:4));
mnConWhl   = mean(wheelConCond(3:4));
edgeSzRef  = mean(edgeSizCond(3:4));
radSpdRef  = mean(speedCond(3:4));
baseGryRef = [0.5-mnConWhl 0.5+mnConWhl 0.5-mnConEdge 0.5+mnConEdge];

sweepLabels = {'Edge size','Edge contrast','Speed','Wheel contrast', ...
               'Arrow cong','Arrow incong'};


%% Valid pixel mask

dummyFlt = DoFilterArray(zeros(szDim,szDim,2,'uint8'), dPhi, emd);
[~, ExBin] = ExclReg(dummyFlt(:,:,1), emd.Default.MM);
IncInd = find(ExBin == 0);
fprintf('Valid pixels: %d of %d\n\n', numel(IncInd), szDim^2);


%% Test stimuli

strengthFinal = zeros(nSweep, nLevels);

for st = 1:nSweep
    fprintf('Sweep %d/%d: %s\n', st, nSweep, sweepLabels{st});

    for lv = 1:nLevels

        switch st
            case 1
                IM_u8 = uint8(WheelSpinRadialb(szDim,numSeg,radVec, ...
                    edgeSizCond(lv),baseGryRef,nFrames,radSpdRef,motionDir)*255);
            case 2
                bG = [0.5-mnConWhl 0.5+mnConWhl ...
                      0.5-edgeConCond(lv) 0.5+edgeConCond(lv)];
                IM_u8 = uint8(WheelSpinRadialb(szDim,numSeg,radVec, ...
                    edgeSzRef,bG,nFrames,radSpdRef,motionDir)*255);
            case 3
                IM_u8 = uint8(WheelSpinRadialb(szDim,numSeg,radVec, ...
                    edgeSzRef,baseGryRef,nFrames,speedCond(lv),motionDir)*255);
            case 4
                bG = [0.5-wheelConCond(lv) 0.5+wheelConCond(lv) ...
                      0.5-mnConEdge 0.5+mnConEdge];
                IM_u8 = uint8(WheelSpinRadialb(szDim,numSeg,radVec, ...
                    edgeSzRef,bG,nFrames,radSpdRef,motionDir)*255);
            case 5
                IM_u8 = uint8(WheelSpinRadialArrow(szDim,numSeg,radVec, ...
                    edgeSzRef,baseGryRef,nFrames,radSpdRef, ...
                    motionDir,motionDir,ArrSzCond(lv))*255);
            case 6
                IM_u8 = uint8(WheelSpinRadialArrow(szDim,numSeg,radVec, ...
                    edgeSzRef,baseGryRef,nFrames,radSpdRef, ...
                    motionDir,-motionDir,ArrSzCond(lv))*255);
        end

        fImg    = DoFilterArray(IM_u8, dPhi, emd);
        [~,~,oR,~] = DoEMDArrays(fImg, tau, dPhi, emd);

        runSum = 0;
        for fr = 1:nFrames
            v = oR(:,:,fr); v = v(IncInd); v = v(v > RThr);
            if ~isempty(v)
                s = sort(v,'descend');
                NoUse = max(1, round(GlobProp * numel(s)));
                runSum = runSum + motionDir * mean(s(1:NoUse));
            end
        end
        strengthFinal(st,lv) = runSum / nFrames;

    end
    fprintf('  Raw diff: %s\n', mat2str(round(strengthFinal(st,:),5)));
end

emd.filtparams.prepro = 0;

%% Normalise

strengthFinalNorm = zeros(nSweep, nLevels);
for c = 1:nSweep
    row   = strengthFinal(c,:);
    rng_c = max(row) - min(row);
    if rng_c > 1e-10
        strengthFinalNorm(c,:) = (row - min(row)) / rng_c;
    else
        strengthFinalNorm(c,:) = 0.5 * ones(1,nLevels);
    end
end


%% Statistics

yPsych = zeros(nSweep, nLevels);
for c = 1:nSweep
    if ~isempty(psychData.cond(c).meanProbs)
        yPsych(c,:) = psychData.cond(c).meanProbs;
    end
end

fprintf('\n%-16s  %-8s  %-8s  %-10s  %s\n','Condition','MSE','rho_S','Dir loss','Direction');
fprintf('%s\n', repmat('-',1,58));
for c = 1:nSweep
    mse_c  = mean((strengthFinalNorm(c,:) - yPsych(c,:)).^2);
    [rh,~] = corr(strengthFinalNorm(c,:)', yPsych(c,:)', 'Type','Spearman');
    dirLoss = mse_c + (1 - rh) / 2;
    if rh >= 0.5
        dirStr = 'CORRECT';
    elseif rh >= 0
        dirStr = 'weak positive';
    else
        dirStr = '*** INVERTED ***';
    end
    fprintf('%-16s  %-8.4f  %-8.3f  %-10.4f  %s\n', ...
            sweepLabels{c}, mse_c, rh, dirLoss, dirStr);
end
condW = [2.0 2.0 0.5 1.0] / 5.5;
dirLossAll = arrayfun(@(c) ...
    mean((strengthFinalNorm(c,:)-yPsych(c,:)).^2) + ...
    (1 - corr(strengthFinalNorm(c,:)',yPsych(c,:)','Type','Spearman'))/2, 1:4);
meanMSE_phys = mean(arrayfun(@(c) ...
    mean((strengthFinalNorm(c,:)-yPsych(c,:)).^2), 1:4));
weightedLoss = sum(condW .* dirLossAll);
fprintf('\nMean MSE (physical, conds 1-4):   %.4f\n', meanMSE_phys);
fprintf('Weighted direction-aware loss:     %.4f\n\n', weightedLoss);


%% PLOT
cond_colors = [0.20 0.45 0.75; 0.55 0.75 0.95; ...
               0.15 0.65 0.35; 0.60 0.88 0.60; ...
               0.85 0.25 0.25; 0.95 0.45 0.35];

figure(80); clf; set(gcf,'Color','w','Position',[20 20 1300 650]);

for c = 1:nSweep
    pd  = psychData.cond(c);
    ax  = subplot(2,3,c);
    if isempty(pd.meanProbs); axis off; continue; end
    col = cond_colors(c,:); xV = pd.x;
    hold(ax,'on');

    for si = 1:size(pd.allFitted,1)
        plot(ax,xV,pd.allFitted(si,:),'-','Color',[col 0.10],'LineWidth',0.6);
    end
    plot(ax,xV,pd.meanFitted,'-','Color',col,'LineWidth',2.5, ...
         'DisplayName','Psych fit');
    errorbar(ax,xV,pd.meanProbs,pd.semProbs,'o','Color',col, ...
             'MarkerFaceColor',col,'MarkerSize',6,'CapSize',5, ...
             'LineWidth',1.5,'DisplayName','Observed');
    plot(ax,xV,strengthFinalNorm(c,:),'s--','Color',[0 0 0], ...
         'LineWidth',1.8,'MarkerSize',7,'MarkerFaceColor',[0 0 0], ...
         'DisplayName','Model');
    yline(ax,0.5,'k:','LineWidth',0.8,'HandleVisibility','off');

    hold(ax,'off');
    mse_c = mean((strengthFinalNorm(c,:)-pd.meanProbs).^2);
    [rh,~] = corr(strengthFinalNorm(c,:)',pd.meanProbs','Type','Spearman');
    title(ax,sprintf('%s  MSE=%.4f  rho=%.2f',pd.label,mse_c,rh), ...
          'FontSize',9,'FontWeight','bold','Color',col);
    xlabel(ax,pd.label,'FontSize',9);
    ylabel(ax,'P(test chosen) / norm. strength','FontSize',8);
    set(ax,'YLim',[0 1],'Box','off','FontSize',8); grid(ax,'on');
end

sgtitle(sprintf('Absolute readout | dPhi=%d tau=%d GP=%.2f RThr=%.2f | MSE_{phys}=%.4f', ...
        dPhi, tau, GlobProp, RThr, meanMSE_phys), ...
        'FontSize',11,'FontWeight','bold');
