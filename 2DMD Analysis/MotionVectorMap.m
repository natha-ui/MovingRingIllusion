% Script Name:  MotionVectorMap.m
% Authors:      K22007681
% Date:         March 2026
% Version:      2.0
% Purpose:      Compare motion vectors at the top GlobProp responding
%               pixels between the minimum (level 1) and maximum (level 6)
%               of each condition dimension, across four time points.
%
%               Layout per figure (one figure per condition):
%                 Row 1: min condition — composite overlay + vectors
%                 Row 2: max condition — composite overlay + vectors
%
%               Vectors drawn at cluster centroids (grid-binned top pixels).
%               Colour encodes signed radial projection of vector direction:
%                 Yellow = outward (expansion direction)
%                 Cyan   = tangential (rotation direction)
%                 Blue   = inward
%
%               Summary figure: mean radial projection vs time for
%               min and max of each condition.
%
% Requires: emd in workspace

%% Check have params
if ~exist('emd','var'), TwoDCorrMotDetBaseParamsA; end

szDim=256; numSeg=4; radVec=[0.45 0.70]; motionDir=1; Hz=120;
nFrames=round(0.75*Hz);
%dPhi=3; tau=2; GlobProp=0.05; RThr=0.02;
dPhi     = 5;    % replace with best_dPhi
tau      = 3;    % replace with best_tau
GlobProp = 0.05;
RThr     = 0.01;
emd.filtparams.prepro=0;
tPoints_s=[0.1 0.2 0.3 0.4]; tFrames=round(tPoints_s*Hz); nTP=4;
overlayAlpha=0.60; vecScale=12; clusterRad=8; minCluster=3;

edgeSizCond=[0.01 0.02 0.04 0.06 0.08 0.10];
edgeConCond=[0.25 0.30 0.35 0.40 0.45 0.50];
speedCond=[0.004 0.006 0.008 0.010 0.020 0.040];
wheelConCond=[0.25 0.30 0.35 0.40 0.45 0.50];
mnConEdge=mean(edgeConCond(3:4)); mnConWhl=mean(wheelConCond(3:4));
edgeSzRef=mean(edgeSizCond(3:4)); radSpdRef=mean(speedCond(3:4));
baseGryRef=[0.5-mnConWhl 0.5+mnConWhl 0.5-mnConEdge 0.5+mnConEdge];

dummyFlt=DoFilterArray(zeros(szDim,szDim,2,'uint8'),dPhi,emd);
[~,ExBin]=ExclReg(dummyFlt(:,:,1),emd.Default.MM);
IncInd=find(ExBin==0); ExBin_logi=logical(reshape(ExBin,szDim,szDim));
[xG,yG]=meshgrid(1:szDim,1:szDim);
phi_pix=atan2(yG-szDim/2, xG-szDim/2);


condDefs={'Edge size','edgeSiz'; 'Edge contrast','edgeCon';
          'Rotation speed','speed'; 'Wheel contrast','wheelCon'};
nConds=size(condDefs,1);
summaryRadProj=zeros(nConds,2,nTP);


for ci=1:nConds
    condLabel=condDefs{ci,1}; condType=condDefs{ci,2};
    fprintf('Vectors: %s\n',condLabel);

    IM_lv=cell(1,2); oH_lv=cell(1,2); oV_lv=cell(1,2); oR_lv=cell(1,2);
    for li=1:2
        lv=[1 6]; lv=lv(li);
        switch condType
            case 'edgeSiz'
                IM=WheelSpinRadialb(szDim,numSeg,radVec,edgeSizCond(lv),baseGryRef,nFrames,radSpdRef,motionDir);
            case 'edgeCon'
                bG=[0.5-mnConWhl 0.5+mnConWhl 0.5-edgeConCond(lv) 0.5+edgeConCond(lv)];
                IM=WheelSpinRadialb(szDim,numSeg,radVec,edgeSzRef,bG,nFrames,radSpdRef,motionDir);
            case 'speed'
                IM=WheelSpinRadialb(szDim,numSeg,radVec,edgeSzRef,baseGryRef,nFrames,speedCond(lv),motionDir);
            case 'wheelCon'
                bG=[0.5-wheelConCond(lv) 0.5+wheelConCond(lv) 0.5-mnConEdge 0.5+mnConEdge];
                IM=WheelSpinRadialb(szDim,numSeg,radVec,edgeSzRef,bG,nFrames,radSpdRef,motionDir);
        end
        IM_lv{li}=IM;
        fImg=DoFilterArray(uint8(IM*255),dPhi,emd);
        [oH_tmp,oV_tmp,oR_tmp,~]=DoEMDArrays(fImg,tau,dPhi,emd);
        oH_lv{li}=oH_tmp; oV_lv{li}=oV_tmp; oR_lv{li}=oR_tmp;
    end

    switch condType
        case 'edgeSiz'; rL={sprintf('Min (%.4f)',edgeSizCond(1)),sprintf('Max (%.4f)',edgeSizCond(6))};
        case 'edgeCon'; rL={sprintf('Min (%.2f)',edgeConCond(1)),sprintf('Max (%.2f)',edgeConCond(6))};
        case 'speed';   rL={sprintf('Min (%.4f)',speedCond(1)),sprintf('Max (%.4f)',speedCond(6))};
        case 'wheelCon';rL={sprintf('Min (%.2f)',wheelConCond(1)),sprintf('Max (%.2f)',wheelConCond(6))};
    end

    figure(30+ci); clf; set(gcf,'Color','k','Position',[10 10 1350 560]);
    gridSz=clusterRad*2; nGridX=ceil(szDim/gridSz);

    for tp=1:nTP
        fr=min(tFrames(tp),nFrames);
        for li=1:2
            stimFrame=IM_lv{li}(:,:,fr);
            magClean=oR_lv{li}(:,:,fr); magClean(ExBin_logi)=0;
            hFrame=oH_lv{li}(:,:,fr); vFrame=oV_lv{li}(:,:,fr);
            magVec=magClean(IncInd); abvThr=magVec>RThr;
            magAbv=magVec(abvThr); idxAbv=IncInd(abvThr);

            stimRGB=repmat(stimFrame,[1 1 3]);
            nKept=0; clCX=[]; clCY=[]; clVH=[]; clVV=[]; clRP=[];

            if ~isempty(magAbv)
                nSel=max(1,round(GlobProp*numel(magAbv)));
                [magSort,sOrd]=sort(magAbv,'descend');
                topIdx=idxAbv(sOrd(1:nSel)); topMag=magSort(1:nSel);
                if max(topMag)>min(topMag); tmn=(topMag-min(topMag))/(max(topMag)-min(topMag));
                else; tmn=ones(size(topMag)); end
                rCh=zeros(szDim,szDim); gCh=zeros(szDim,szDim);
                rCh(topIdx)=1; gCh(topIdx)=tmn;
                oRGB=cat(3,rCh,gCh,zeros(szDim,szDim));
                oMask=zeros(szDim,szDim); oMask(topIdx)=overlayAlpha;
                oM3=repmat(oMask,[1 1 3]);
                comp=stimRGB.*(1-oM3)+oRGB.*oM3;

                [rowIdx,colIdx]=ind2sub([szDim szDim],topIdx);
                hVals=hFrame(topIdx); vVals=vFrame(topIdx);
                cellX=ceil(colIdx/gridSz); cellY=ceil(rowIdx/gridSz);
                cellID=(cellY-1)*nGridX+cellX;
                uCells=unique(cellID); nCl=numel(uCells);
                clCX_all=zeros(nCl,1); clCY_all=zeros(nCl,1);
                clVH_all=zeros(nCl,1); clVV_all=zeros(nCl,1);
                clCt=zeros(nCl,1); clRP_all=zeros(nCl,1);
                for cc=1:nCl
                    msk=cellID==uCells(cc); clCt(cc)=sum(msk);
                    clCX_all(cc)=mean(colIdx(msk)); clCY_all(cc)=mean(rowIdx(msk));
                    clVH_all(cc)=mean(hVals(msk)); clVV_all(cc)=mean(vVals(msk));
                    phi_c=phi_pix(round(clCY_all(cc)),round(clCX_all(cc)));
                    vAng=atan2(clVV_all(cc),clVH_all(cc));
                    clRP_all(cc)=cos(vAng-phi_c);
                end
                keepCl=clCt>=minCluster;
                clCX=clCX_all(keepCl); clCY=clCY_all(keepCl);
                clVH=clVH_all(keepCl); clVV=clVV_all(keepCl);
                clRP=clRP_all(keepCl); nKept=sum(keepCl);
                if nKept>0; summaryRadProj(ci,li,tp)=mean(clRP); end
            else
                comp=stimRGB;
            end

            ax=subplot(2,nTP,(li-1)*nTP+tp);
            imshow(comp,'Parent',ax); hold(ax,'on');
            for cc=1:nKept
                mc=sqrt(clVH(cc)^2+clVV(cc)^2);
                if mc<1e-8; continue; end
                dx=clVH(cc)/mc*vecScale; dy=clVV(cc)/mc*vecScale;
                rp=clRP(cc);
                if rp>0.3; aC=[1 1 0]; elseif rp<-0.3; aC=[0 0.4 1]; else; aC=[0 1 1]; end
                quiver(ax,clCX(cc),clCY(cc),dx,dy,0,'Color',aC,'LineWidth',1.4,...
                       'MaxHeadSize',0.8,'AutoScale','off');
            end
            hold(ax,'off');
            if tp==1; ylabel(ax,rL{li},'Color','w','FontSize',8,'FontWeight','bold'); end
            title(ax,sprintf('t=%.1fs  rp=%.2f',tPoints_s(tp),summaryRadProj(ci,li,tp)),...
                  'Color','w','FontSize',8);
        end
    end
    sgtitle(sprintf('%s  |  Yellow=outward  Cyan=tangential  Blue=inward',condLabel),...
            'Color','w','FontSize',10,'FontWeight','bold');
end

%% Summary figure
figure(50); clf; set(gcf,'Color','w','Position',[100 100 700 420]);
cmap_c=lines(nConds);
condLabels_plot=condDefs(:,1);
for ci=1:nConds
    subplot(2,2,ci); hold on;
    plot(tPoints_s,squeeze(summaryRadProj(ci,1,:)),'o--',...
         'Color',cmap_c(ci,:)*0.6,'LineWidth',1.8,'MarkerSize',7,'DisplayName','Min (lv1)');
    plot(tPoints_s,squeeze(summaryRadProj(ci,2,:)),'o-',...
         'Color',cmap_c(ci,:),'LineWidth',1.8,'MarkerSize',7,'DisplayName','Max (lv6)');
    hold off;
    yline(0,'k--','LineWidth',1.0,'HandleVisibility','off');
    ylim([-1.1 1.1]); xlabel('Time (s)','FontSize',9); ylabel('Radial projection','FontSize',9);
    title(condLabels_plot{ci},'FontSize',10,'FontWeight','bold');
    legend('Location','best','FontSize',8,'Box','off'); grid on; box off;
end
sgtitle({'+1=outward (expansion)   0=tangential   -1=inward'},'FontSize',10);
