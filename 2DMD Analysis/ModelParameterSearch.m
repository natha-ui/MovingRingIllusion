% Script Name:  ModelParameterSearch.m
% Authors:      K22007681
% Date:         March 2026
% Version:      5.0
%
% Single unified readout for all conditions:
%   diff_whole — mean of top GlobProp fraction of above-RThr EMD magnitude
%                responses across all valid image pixels, differential
%                (test minus reference), frame-collapsed.
%
% Speed is accepted as the least well-fitted condition. The search finds
% the parameter combination that best trades off edge size, edge contrast,
% and wheel contrast, with speed included in the loss.
%
% Parameters: dPhi [2 4 6 8 12], tau [1 2 3 4 6 8], GlobProp [5], RThr [5]
% Loss:       MSE against group mean P(test chosen), physical conds 1-4

%% Check have params
if ~exist('emd','var'), TwoDCorrMotDetBaseParamsA; end
if ~exist('psychData','var')
    error('psychData not found — run LoadPsychometricData first.');
end

%% INITIALIZE

szDim     = 128;
numSeg    = 4;
radVec    = [0.45 0.70];
motionDir = 1;
nFrames   = 20;
nLevels   = 6;
nSweep_s  = 4;
emd.filtparams.prepro = 0;

edgeSizCond  = [0.01 0.02 0.04 0.06 0.08 0.10];
edgeConCond  = [0.25 0.30 0.35 0.40 0.45 0.50];
speedCond    = [0.004 0.006 0.008 0.010 0.020 0.040];
wheelConCond = [0.25 0.30 0.35 0.40 0.45 0.50];

mnConEdge  = mean(edgeConCond(3:4));
mnConWhl   = mean(wheelConCond(3:4));
edgeSzRef  = mean(edgeSizCond(3:4));
radSpdRef  = mean(speedCond(3:4));
baseGryRef = [0.5-mnConWhl 0.5+mnConWhl 0.5-mnConEdge 0.5+mnConEdge];

sweepLabels = {'Edge size','Edge contrast','Speed','Wheel contrast'};

% Group mean proportions [4 x 6]
yPsych = zeros(nSweep_s, nLevels);
for c = 1:nSweep_s
    if ~isempty(psychData.cond(c).meanProbs)
        yPsych(c,:) = psychData.cond(c).meanProbs;
    end
end


%% Parameter vectors

dPhiVec     = [1  2  3  4  6  8  10  12  14  16];
tauVec      = [1  2  3  4  5  6  7  8];
GlobPropVec = [0.01 0.02 0.05 0.1 0.3 0.5 0.8 0.9 0.95];
RThrVec     = [0.01 0.02  0.04 0.06 0.08 0.10 0.15 0.2];

nDP  = numel(dPhiVec);
nTau = numel(tauVec);
nGP  = numel(GlobPropVec);
nRS  = numel(RThrVec);
nEMD_sets = nDP * nTau;
nStim     = nSweep_s * nLevels + 1;

fprintf('Single diff_whole readout search\n');
fprintf('Grid: dPhi(%d) x tau(%d) = %d EMD sets\n', nDP, nTau, nEMD_sets);
fprintf('Readout sweep: GlobProp(%d) x RThr(%d) = %d combos\n', nGP, nRS, nGP*nRS);
fprintf('Total EMD calls: %d  (~%d min)\n\n', ...
        nEMD_sets*nStim, round(nEMD_sets*nStim*3/60));


%% Cache stim

fprintf('Caching stimuli...\n'); tic;

IM_ref_u8 = uint8(WheelSpinRadialb(szDim,numSeg,radVec,edgeSzRef, ...
            baseGryRef,nFrames,radSpdRef,motionDir)*255);

IM_test = cell(nSweep_s, nLevels);
for lv = 1:nLevels
    IM_test{1,lv} = uint8(WheelSpinRadialb(szDim,numSeg,radVec, ...
        edgeSizCond(lv),baseGryRef,nFrames,radSpdRef,motionDir)*255);

    bG2 = [0.5-mnConWhl 0.5+mnConWhl ...
           0.5-edgeConCond(lv) 0.5+edgeConCond(lv)];
    IM_test{2,lv} = uint8(WheelSpinRadialb(szDim,numSeg,radVec, ...
        edgeSzRef,bG2,nFrames,radSpdRef,motionDir)*255);

    IM_test{3,lv} = uint8(WheelSpinRadialb(szDim,numSeg,radVec, ...
        edgeSzRef,baseGryRef,nFrames,speedCond(lv),motionDir)*255);

    bG4 = [0.5-wheelConCond(lv) 0.5+wheelConCond(lv) ...
           0.5-mnConEdge 0.5+mnConEdge];
    IM_test{4,lv} = uint8(WheelSpinRadialb(szDim,numSeg,radVec, ...
        edgeSzRef,bG4,nFrames,radSpdRef,motionDir)*255);
end
fprintf('  Done in %.1f s\n\n', toc);


%% Grid search

fprintf('Starting search...\n');

% Storage [nDP x nTau x nGP x nRS]
lossGrid      = NaN(nDP, nTau, nGP, nRS);
rhoGrid       = NaN(nDP, nTau, nGP, nRS);
lossGrid_cond = NaN(nDP, nTau, nGP, nRS, nSweep_s);

tSearch = tic;

for di = 1:nDP
    cDPhi = dPhiVec(di);

    % Valid pixel mask for this dPhi
    dummyFlt = DoFilterArray(zeros(szDim,szDim,2,'uint8'), cDPhi, emd);
    [~, ExBin] = ExclReg(dummyFlt(:,:,1), emd.Default.MM);
    IncInd = find(ExBin == 0);

    % Filter all stimuli once for this dPhi
    fImg_ref = DoFilterArray(IM_ref_u8, cDPhi, emd);
    fImg_test = cell(nSweep_s, nLevels);
    for st = 1:nSweep_s
        for lv = 1:nLevels
            fImg_test{st,lv} = DoFilterArray(IM_test{st,lv}, cDPhi, emd);
        end
    end

    for ti = 1:nTau
        cTau = tauVec(ti);

        % ----- Reference: EMD + accumulate per GlobProp x RThr -----
        [~,~,oR_ref,~] = DoEMDArrays(fImg_ref, cTau, cDPhi, emd);

        refSum = zeros(nGP, nRS);
        for fr = 1:nFrames
            v = oR_ref(:,:,fr); v = v(IncInd);
            for ri = 1:nRS
                vt = v(v > RThrVec(ri));
                if ~isempty(vt)
                    s = sort(vt,'descend');
                    for gi = 1:nGP
                        NoUse = max(1, round(GlobPropVec(gi)*numel(s)));
                        refSum(gi,ri) = refSum(gi,ri) + motionDir*mean(s(1:NoUse));
                    end
                end
            end
        end
        refSc = refSum / nFrames;   % [nGP x nRS]

        % ----- Test stimuli: EMD + accumulate -----
        testSc = zeros(nSweep_s, nLevels, nGP, nRS);
        for st = 1:nSweep_s
            for lv = 1:nLevels
                [~,~,oR_t,~] = DoEMDArrays(fImg_test{st,lv}, cTau, cDPhi, emd);
                tSum = zeros(nGP, nRS);
                for fr = 1:nFrames
                    v = oR_t(:,:,fr); v = v(IncInd);
                    for ri = 1:nRS
                        vt = v(v > RThrVec(ri));
                        if ~isempty(vt)
                            s = sort(vt,'descend');
                            for gi = 1:nGP
                                NoUse = max(1, round(GlobPropVec(gi)*numel(s)));
                                tSum(gi,ri) = tSum(gi,ri) + motionDir*mean(s(1:NoUse));
                            end
                        end
                    end
                end
                testSc(st,lv,:,:) = tSum / nFrames;
            end
        end

        % ----- GlobProp x RThr readout sweep -----
        for gi = 1:nGP
            for ri = 1:nRS
                % Differential strength [nSweep_s x nLevels]
                strFinal = squeeze(testSc(:,:,gi,ri)) - refSc(gi,ri);

                % Row-wise normalisation to [0,1]
                strNorm = zeros(nSweep_s, nLevels);
                for c = 1:nSweep_s
                    row   = strFinal(c,:);
                    rng_c = max(row) - min(row);
                    if rng_c > 1e-10
                        strNorm(c,:) = (row - min(row)) / rng_c;
                    else
                        strNorm(c,:) = 0.5 * ones(1,nLevels);
                    end
                end

                % Direction-aware loss per condition:
                %   loss_c = MSE_c + (1 - rho_c) / 2
                % (1-rho)/2: rho=+1->0, rho=0->0.5, rho=-1->1.0
                % Inversions penalised regardless of MSE shape.
                % Weights: edge size x2, edge contrast x2, speed x0.5, wheel x1
                condW = [2.0 2.0 0.5 1.0] / 5.5;

                mseVec  = zeros(1, nSweep_s);
                rhoVec  = zeros(1, nSweep_s);
                lossVec = zeros(1, nSweep_s);
                for c = 1:nSweep_s
                    mseVec(c) = mean((strNorm(c,:) - yPsych(c,:)).^2);
                    [r,~] = corr(strNorm(c,:)', yPsych(c,:)', 'Type','Spearman');
                    rhoVec(c)  = r;
                    lossVec(c) = mseVec(c) + (1 - r) / 2;
                end

                lossGrid(di,ti,gi,ri)        = sum(condW .* lossVec);
                rhoGrid(di,ti,gi,ri)         = mean(rhoVec);
                lossGrid_cond(di,ti,gi,ri,:) = lossVec;
            end
        end

        % Progress
        doneSoFar = (di-1)*nTau + ti;
        elapsed   = toc(tSearch);
        eta_s     = elapsed/doneSoFar * (nEMD_sets - doneSoFar);
        fprintf('  dPhi=%2d tau=%d | bestLoss=%.4f | ETA %.0f min\n', ...
                cDPhi, cTau, min(lossGrid(:),[],'omitnan'), eta_s/60);

    end % tau
end % dPhi

emd.filtparams.prepro = 0;
fprintf('\nSearch complete in %.1f min\n\n', toc(tSearch)/60);


%% Best params

[bestLoss, bestIdx] = min(lossGrid(:));
[b_di,b_ti,b_gi,b_ri] = ind2sub(size(lossGrid), bestIdx);

fprintf('Best params:\n');
fprintf('  dPhi=%d  tau=%d  GlobProp=%.2f  RThr=%.2f\n', ...
    dPhiVec(b_di), tauVec(b_ti), GlobPropVec(b_gi), RThrVec(b_ri));
fprintf('  Combined loss=%.4f  mean rho=%.3f\n', ...
    bestLoss, rhoGrid(b_di,b_ti,b_gi,b_ri));
fprintf('  Per-condition MSE [EdSz EdCon Spd WhlCon]:\n  ');
fprintf('%.4f  ', squeeze(lossGrid_cond(b_di,b_ti,b_gi,b_ri,:)));
fprintf('\n\n');

% Default comparison (dPhi=8,tau=6,GP=0.05,RThr=0.05)
def_di=find(dPhiVec==8,1); def_ti=find(tauVec==6,1);
def_gi=find(GlobPropVec==0.05,1); def_ri=find(RThrVec==0.05,1);
if ~isempty(def_di)&&~isempty(def_ti)&&~isempty(def_gi)&&~isempty(def_ri)
    defLoss = lossGrid(def_di,def_ti,def_gi,def_ri);
    fprintf('Default (dPhi=8 tau=6 GP=0.05 RThr=0.05): loss=%.4f\n',defLoss);
    fprintf('Improvement: %.1f%%\n\n', 100*(defLoss-bestLoss)/defLoss);
end

% Per-condition rho table
fprintf('%-16s  %-8s  %-8s\n','Condition','MSE','rho_S');
fprintf('%s\n',repmat('-',1,36));
for c = 1:nSweep_s
    fprintf('%-16s  %-8.4f  %-8.3f\n', sweepLabels{c}, ...
            lossGrid_cond(b_di,b_ti,b_gi,b_ri,c), ...
            rhoGrid(b_di,b_ti,b_gi,b_ri));
end


%% Plots


% F.1 Loss heatmap: dPhi x tau
figure(70); clf; set(gcf,'Color','w','Position',[30 30 700 500]);
lossMap = squeeze(min(min(lossGrid,[],4),[],3));   % min over GP and RThr
imagesc(tauVec, dPhiVec, lossMap);
colorbar; axis xy; colormap(flipud(hot));
xlabel('tau','FontSize',11); ylabel('dPhi','FontSize',11);
title('MSE loss: dPhi x tau  (min over GlobProp and RThr)','FontSize',10);
xticks(tauVec); yticks(dPhiVec);
hold on;
plot(tauVec(b_ti), dPhiVec(b_di), 'c*','MarkerSize',16,'LineWidth',2.5);
hold off; set(gca,'FontSize',10);

% F.2 Per-condition loss at best dPhi+tau, across GlobProp
figure(71); clf; set(gcf,'Color','w','Position',[50 50 900 360]);
cmap_c = lines(nSweep_s);

subplot(1,2,1);
hold on;
for c = 1:nSweep_s
    curve = squeeze(min(lossGrid_cond(b_di,b_ti,:,:,c),[],4));  % min over RThr
    plot(GlobPropVec, curve, 'o-', 'Color',cmap_c(c,:), ...
         'LineWidth',1.5, 'DisplayName',sweepLabels{c});
end
hold off;
legend('Location','best','FontSize',8,'Box','off');
xlabel('GlobProp','FontSize',10); ylabel('MSE loss','FontSize',10);
title('Per-condition loss vs GlobProp at best dPhi+tau','FontSize',10);
grid on; box off;

subplot(1,2,2);
hold on;
for c = 1:nSweep_s
    curve = squeeze(min(lossGrid_cond(b_di,b_ti,:,:,c),[],3));  % min over GP
    plot(RThrVec, curve, 'o-', 'Color',cmap_c(c,:), ...
         'LineWidth',1.5, 'DisplayName',sweepLabels{c});
end
hold off;
legend('Location','best','FontSize',8,'Box','off');
xlabel('RThr','FontSize',10); ylabel('MSE loss','FontSize',10);
title('Per-condition loss vs RThr at best dPhi+tau','FontSize',10);
grid on; box off;
sgtitle('Per-condition sensitivity to readout parameters','FontSize',11);


%% Save best parameters

best_dPhi     = dPhiVec(b_di);
best_tau      = tauVec(b_ti);
best_GlobProp = GlobPropVec(b_gi);
best_RThr     = RThrVec(b_ri);

fprintf('\nTo use in AnalysisA_Revised, set:\n');
fprintf('  dPhi     = %d\n',   best_dPhi);
fprintf('  tau      = %d\n',   best_tau);
fprintf('  GlobProp = %.2f\n', best_GlobProp);
fprintf('  RThr     = %.2f\n', best_RThr);

% save('SearchResults.mat','lossGrid','rhoGrid','lossGrid_cond',...
%      'dPhiVec','tauVec','GlobPropVec','RThrVec',...
%      'best_dPhi','best_tau','best_GlobProp','best_RThr');
