% Script Name:      MotionIllusionTaskDevB.m
% Author Name:      Andrew Isaac Meso
% Date:             08/02/2026
% Purpose:          Task development and testing for NM, YC & JW final year
% projects. Testing the spinning wheel illusion
% Version:          2.0
% Notes:            The task has been completed and tested to include a
% context condition with congruent or incongruent arrow directions inside 
% the wheel stimulus. 

%% A. first prepare psychtoolbox by closing everything that is open and clearing the memory
close all; clear all; Screen('CloseAll');

StartDir = cd;  % Store initial directory to come back to later

% A.1 get some Psychtoolbox parameters to  make sure we can call on them within
% the task... 
WhichScreens = Screen('Screens');   
screenID = max(WhichScreens); % i.e. expecting two screens, the second screen, 2
HideCursor;                     

SRes = Screen(screenID, 'Rect');% Resolution 
W = RectWidth(SRes);            % screen width
H = RectHeight(SRes);           % screen height
Cx = W/2;     % centre coordinates.... 
Cy = H/2;
Hz = Screen(screenID,'FrameRate');  % Expected to be 120Hz on Display++

pi = 3.14159265; % pi to 8 decimal places... 

% Display++ Parameters
PixPerCm = 27.10;         % Check this before starting experiments
ScreenEyeDistCm = 57;    % Always ensure these are correct
% ppd = PixPerDeg(PixPerCm,ScreenEyeDistCm);

% Some trig for Display++ Screen calculations
% Screen pixels: Tan(theta) = opp/adj = 1080/1920 = 0.5625
% hyp = Diagonal pix = sqrt(opp^2 + adj^2) = sqrt(1080^2 + 1920^2) = 2,202.9
% hyp = 32inch = 32*2.54 = 81.28cm; sin(theta) = opp/hyp = 1080/2202.9
% cos(theta) = 1920/2,202.9; pixPercm = 2202.9/81.28 = 27.10

ScreenDistanceCm = ScreenEyeDistCm; % depends on set up, in marseille, 57.3 in Bournemouth P111 73cm 
dT = 1/Hz; % this will be the time in seconds of each frame... 
CpixPerDeg = PixPerDeg(PixPerCm,ScreenEyeDistCm); % Screen pixels per degree

% On lab computer the data directory will the this one below for this task:
DataDir = 'C:\LabExperiments\MesoAI\Psychophysics and Models Matlab\StudentPsychophysics\KingsCollegeLondonProjects\BSc UndergraduateProjects\2026\MotionIllusion RotatingWindmills FJ NM KYC\Data';
%DataDir = 'C:\LabExperiments\Data\GravityNoise'; % Lab TO4, KCL IOPPN adapt
echo off
Screen('Preference', 'SkipSyncTests', 1);

InfEnt = 0;     % testing mode, 

% A.2 Some stimulus specific characteristics
StimuliSize = 384;                  % 512 reduced from 900 pixel square area... 
StimSzDeg = StimuliSize/CpixPerDeg; % for storage, the stimulus size in degrees... 

% to be removed...
DotRad = 6; % this is the dot size in pixels, in this case it is twice the size
% YSp = 4; % this is the starting y-offset of each trial. [1 degree/s of visual angle...]

% A.2.3 in these experiments, radius of fixation spot is specified by the
% experimenter
WindCon = 0; % do we want to apply a restrictive fixation window for each trial yes: 1, no: 0
FixRad = 2.5; % this means # degrees..., no this can't be in degrees... 

% A.2.4 re-set by Meso AI Feb 2023, multiple noise conditions and two speeds... 
NTrials = 192; %test at various values, standard is two conditions of 6 * 16 trials ()
% SpeedCond = [ 8 9 10 11 ] ; % speed condition numbers, four speeds in x direction
% BounceCond = [ 0.98 0.98  ]; % to be fixed. 
edgeConCond = [ 0.25 0.30 0.35 0.40 0.45 0.50 ] ; % to be added or subtracted from 0.5
%edgeSizCond = [ 0.03 0.06 0.09 0.12 0.15 0.18 ] ; % range to be tested...
% adjusted cases, Feb 2026
edgeSizCond = [ 0.01 0.02 0.04 0.06 0.08 0.10 ] ; %

%speedCond = [ 0.01 0.02 0.04 0.08 0.16 0.32 ];
speedCond = [ 0.004 0.006 0.008 0.01 0.02 0.04 ];

wheelConCond = [ 0.25 0.30 0.35 0.40 0.45 0.50 ]; % 
ArrSzCond = [ 0.54 0.63 0.72 0.81 0.90 0.99 ]; % range of proportional arrow sizes for use... 

% conditions -> A. edge con, edge size  B. speed, wheel contrast C.
% Contextual factors

% A.2.5 Other task factors for the illusion stimulus 
%ImSiz = 256;
numSeg = 4;
radVec = [ 0.45 0.70 ];
StmAr = 2.25; % stimulus area around fixation...

DirCond = [ -1 1 ]; 
%NoDots = 256;                % Number of background dots to be tested
%DotSz = 6;                      % dot size if this can be changed
StimParams.CONDA_EdgeSizRange = edgeSizCond;
StimParams.CONDB_EdgeContrastRange = edgeConCond;
StimParams.CONDC_SpeedConditionRange = speedCond;
StimParams.CONDD_WheelContrastRange = wheelConCond;
StimParams.CONDE_ArrowSizePropotions = ArrSzCond;
%BackCond = [ 1 2 3 4 ];    % 1: Blank; 2: Symm-V; 3: Symm-H; 
% 4: Asymm.

%SpDegPerFr = SpeedCond./Hz; % this is a matrix with the degrees per frame... 
% these speed figures should be in pixels per second instead of pixels per
% frame, to be corrected 16/02/2023 Check all speeds from scratch
%SpPixPerS = SpDegPerFr.*(CpixPerDeg*Hz); % now same as above in pixels per sec
%StimParams.SpeedParams.DegPerFr = SpDegPerFr;
%StimParams.SpeedParams.PixPerSec = SpPixPerS;

%YSp = YSp*CpixPerDeg;  % adjust to acceleration in pixels/s2... 
%Gr = Gr*CpixPerDeg;  % above three should now be pixels per second.

PresTime = 0.75; % presentation time in seconds... test, 0.5, real, 3
FrameNo = round(PresTime/dT); % number of frames needed for the display in question.
PDrift = 0.333333; % proportions of trial before drift corrections....  
BefStimS = 0.300;    % Time pause before stimulus                
PostStimS = 0.400;   % after
StimParams.PreStimulusPauseTimeS = BefStimS;
StimParams.PostStimulusPauseTimeS = PostStimS;

HalfStimuliSize = round(StimuliSize/2);
WidthStimuli = (-HalfStimuliSize) : HalfStimuliSize-1;
StdDev = (35/60)*StimuliSize; % standard deviation of Gaussian window (if used)
% Use Gaussian window, insert code here... 

radius = round(HalfStimuliSize);
nDrift = round(NTrials*PDrift); % number of trials between periodic drift corrections (eg 1 in 5 is 0.2)

% set and store randomisation.... 
SetSeed = SetRandomSeed(1); % use the clock to initialize the randomisation for later storage...

%enable keyboard button presses...
KbName('UnifyKeyNames')
rightKey = KbName('RightArrow'); %input response keys
leftKey = KbName('LeftArrow'); % last of 2AFC options, detection symmetrical (left) or not (
downKey = KbName('DownArrow'); %input response keys, if ball stops bouncing 
stopkey=KbName('space'); % make sure this is used in case an escape is needed... 

[keyIsDown ctime keycodes] = KbCheck;

time_start = clock; %this is when the experiment starts, a vector with all various parts of the time measure
%-----------------------
%% B. Now start the task program by entering the experiment and participant details... 
% B.1 Some pre-requisite information for saving the tasks
if InfEnt == 0 
    % for the purposes of testing, use Gravity condition
    testType = 1; % for this condition, we have test type of gravity...
    %Gr = Gr*DirCond(testType); % set up the direction of gravity as up or down...
    %YSp = YSp*-DirCond(testType); % adjust the starting y direction opposite to gravity... 

    %testType = 2; % for this condition, we have test type of gravity...
    %Gr = Gr*DirCond(testType); % set up the direction of gravity as up or down...
    %YSp = YSp*-DirCond(testType); % adjust the starting y direction opposite to gravity...

    % presets for ease
    sbjnum = 'TT01'; sbjinit = 'TT'; sbjage = 99; current_RepNo = 1; EyeAcuityScore = 11;
    EyeChart = 'A'; sbjsex = 'B';
else
    sbjnum = input('Number (ID) of Participant in single quotes e.g. S01: ');
    while isempty(sbjnum), sbjnum = input('Number (ID) of Participant no quotes e.g. S01: '); end
    
    sbjinit = input('Initials of the Participant XX in quotes: ');
    if isempty(sbjinit), sbjinit = 'XX'; disp('default initials set to XX') ; end
    
    sbjage = input('Age, NO quotes: ');
    if isempty(sbjage), sbjage = 00; end

    sbjsex = input('Participant Sex, F, M or O (Other) in quotes: ');
    if isempty(sbjsex), sbjsex = 'B'; end
    
    sbhand = input('Handedness L or R, in single quotes: ');
    if isempty(sbhand), sbhand = 'R'; end

    current_RepNo = input('If you have repeated this measure, what no is this (no quotes, first/default 1): ');
    if isempty(current_RepNo), current_RepNo = 1; disp('Rep No set as 1'); end
    
    testType = input('Test type? 1. Edge Con/Edge Size (default); 2. Speed/Wheel Con; 3. Arrow/surround: ');
    if isempty(testType), testType = 1; disp('Type set to Edge Con/EdgeSize'); end
    
    EyeAcuityScore = input('Please enter the score on the eye acuity chart (1-11): ');
    if isempty(EyeAcuityScore), EyeAcuityScore = 0; disp('No Acuity Score Selected!'); end % set a default zero if blank
    
    % EyeChart = input('Which eyechart did you use? (A/B, in quotes):');
    % if isempty(EyeChart), 
    %EyeChart = 'A.Serifs';  % Alternative B has no serifs... 'B. Sans Serifs'  
    EyeChart = 'B. Sans Serifs'; % edited 27/02/2023

    %***************************************************** FEB 2024, G/A Conds save     
    switch testType
        case    1           % Edge Contrast and Size
        ResultsFilename = strcat('EdCnSzMI',num2str(sbjnum),sbjinit,'_',num2str(current_RepNo));
        edfFile=['EC',num2str(sbjnum),sbjinit,num2str(current_RepNo)];
        case    2           % Speed and Wheel contrast
        ResultsFilename = strcat('EdSpWhMI',num2str(sbjnum),sbjinit,'_',num2str(current_RepNo));
        edfFile=['SW',num2str(sbjnum),sbjinit,num2str(current_RepNo)];
        case    3           % Arrows or Surrounding Halo
        ResultsFilename = strcat('ArHaMI',num2str(sbjnum),sbjinit,'_',num2str(current_RepNo));
        edfFile=['AH',num2str(sbjnum),sbjinit,num2str(current_RepNo)];

    end % end of generation of filenames
    
    if length(edfFile)>8, edfFile(9:end) = []; % make sure the name is not too long for eyelink
    end % end of if condition...
    
    % set Gravity and speed directions accordingly
    % Gr = Gr*DirCond(testType); % set up the direction of gravity as up or down...
    % YSp = YSp*-DirCond(testType); % adjust the starting y direction opposite to gravity... 
end % end of if condition checking whether testing is being ran


%--------------------------
% B.2 prepare a mask in case it is needed... this will limit screen to circular space 
% AssertOpenGL;
% [x y] = meshgrid(WidthStimuli, WidthStimuli);
% circularGaussianMaskMatrix = exp(-((x .^ 2) + (y .^ 2)) / (StdDev ^ 2));
% 
% % insert a threshold to the Gaussian window, display in circular aperture...
% indices = find(abs(circularGaussianMaskMatrix)<0.5);             % exterior
% indicesb = find(abs(circularGaussianMaskMatrix)>0.499999999999); % interior
% circularGaussianMaskMatrix(indices) = 0.0;
% circularGaussianMaskMatrix(indicesb) = 1.0;

% B.3 In this task we set the conditions for the illusion perception task...  

[ TskCons ConType Dir Hemis ] = BalanceTrials(NTrials, 1, 1:6, 1:2, 1:2, 1:2 ); % Edge Con/Size

ResFile = zeros(NTrials,8); % Check the entries and confirm Feb 2024 
% [] % RESFILE ENTRIES

% Some luminance defaults that we need for the noise calculation
white = 256;
black = 1;
gray = 128;

%  B.3.1 Standard params (Spatial pixels, 8-bit luminance, RMS contrast)
size_im = StimuliSize;      % pixels, x and y dimensions (256)
ave_lum = gray;              % mid level 8-bit luminance range, 0 to 255

oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
oldSuppressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);

%NoiseIm = zeros(StimuliSize,StimuliSize);
%----------------------------------       
    inc = 255; %abs(white-gray); % updated to full contrast Feb 2023
    %StimuliA(1:StimuliSize,1:StimuliSize) = gray; % this is the basic blank to be thrown up before each refresh
    % ddX = Cx - CSx; % difference between stimulus area and screen edges
    % ddY = Cy - CSy;
    %Screen('Preference','SkipSyncTests', 0);
%     s = Screen(screenID, 'Rect');
%     W = RectWidth(s);
%     H = RectHeight(s);
%     Cx = W/2;
%     Cy = H/2;
    
    %% C. Now start to prepare the actual task...
    [win, winRect] = Screen('OpenWindow', screenID, gray);

     %----------------------------------
    % C.1 Set up eyelink for recordings... (initializations, filenames etc)    
    disp('... setting up eye link connection');
    textOut = 1;
    if EyelinkInit() ~= 1 % this should work, but new version might do strange things Nov 2016
       error('Problems with Eyelink connection!');
       return;
    end
    el = EyelinkInitDefaults(win);
    
    % C.2 During testing, we need a temporary edf file... 
    if InfEnt == 1
        % Do Nothing... this has been taken care of earlier
    else 
    % Only while testing 
        edfFile=['GT',num2str(1),'_',num2str(2),num2str(3),'.edf'];
        ResultsFilename = strcat('TestGrNo',num2str(sbjnum),sbjinit,'_',num2str(current_RepNo));
    end

    % C.3 Prepare the edf file and set some values for eye recording and
    % calibration settings
    Eyelink('Openfile', edfFile);
    eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
    if eye_used == -1
        eye_used = el.RIGHT_EYE;
    end  % make it so that the right eye data structure can be accessed!
    Eyelink('command','link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    Eyelink('command','link_sample_data = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,STATUS,INPUT'); 
    Eyelink('command', 'saccade_velocity_threshold = 20');
    Eyelink('command', 'saccade_acceleration_threshold = 4000');  
    Eyelink('command', 'calibration_type = HV9');
    
    % C.4 set up eye tracker calibration procedures, 65% of screen
    Eyelink('command', 'calibration_area_proportion = 0.55 0.55'); % x and y validation areas 
    Eyelink('command', 'validation_area_proportion = 0.55 0.55');
    
    % C.5 more about calibration element size... smaller for Display++ 
    calTarSz = 1 ; % element size as a % of the screen size
    calTarInteriorSz = 1/3 ; %
    el.calibrationtargetsize = calTarSz; % size of calibration target 
    el.calibrationtargetwidth = calTarSz*calTarInteriorSz; % surrounding area, I think.
    EyelinkUpdateDefaults(el);    
    StimInfo.CalibrationInfo.TargetPropotionalSize = calTarSz;
    StimInfo.CalibrationInfo.TargetSmallestRegionProp = calTarInteriorSz;

    % C.6 confirm screen colours.
    EyelinkDoTrackerSetup(el);
    el.backgroundcolour = gray;
    el.foregroundcolour = black;

    % probably don't need all this.... but check.
    if Eyelink('IsConnected')~=1 && ~dummymode
       cleanup;
       return;
    end;
 
disp( ['... starting the ' num2str(NTrials) ' trials' ]);

% C.7 Some reference trial factors
edgePropSzRef = mean(edgeSizCond(3:4)); % mean of the size condition range... in the middle
mnConEdge = mean(edgeConCond(3:4)); mnConWhl = mean(wheelConCond(3:4));
baseGryRef = [ 0.5-mnConWhl 0.5+mnConWhl 0.5-mnConEdge 0.5+mnConEdge ] ; % wheel and edge contrasts
radSpdRef = mean(speedCond(3:4));
StimParams.ReferenceParams.EdgeSize = edgePropSzRef;
StimParams.ReferenceParams.BaslineGreyValuesWheelEdges = baseGryRef;
StimParams.ReferenceParams.SpeedAngularPerFrame = radSpdRef; % check units... 

%% D. Start the loop of task trials kk
kk = 0; % trial number!
while kk<NTrials
    clear field imageMatrix grayScaleImageMatrix 
    Screen('close'); % clear screen memory [avoid overloading memory]
    PreComputeTime = GetSecs; % check the clock before all the computation....
    % Conditions..., trial prep etc
    % [ FasSlo BounCon Dir  ]
    
    % D.1 Setting up the conidtions for the task... 
    TCs = TskCons(kk+1); % 1 to 6 from high to low values of the test variable...  
    CTp = ConType(kk+1); % [ 1, 2 ] % one of two test settings...  
    Di = DirCond(Dir(kk+1)); % direction (1-2) - clockwise/anticlockwise generate -1 or 1
    Hem = Hemis(kk+1); % hemisphere, left or right... 

    savedRes = 0; % initialize these to null values, for actual response
    RT = 0.00; % initialize these to null values for reaction time
    testRes = 0; % whether the test has been chosen  

    % D.0 Generate stimuli for the two intervals... 
    WheelStimMatRef = WheelSpinRadialb(StimuliSize, numSeg, radVec, edgePropSzRef, baseGryRef, ...
        FrameNo, radSpdRef, Di); % check this in lab... 
    
    if testType == 1  % Edge size and contrast parameters 1 and 1  
        % Tested conditions
        if CTp == 1 % edge size
            edgePropSzTst = edgeSizCond(TCs) ; % Condition 1
            cuConEdge = mnConEdge; cuConWhl = mnConWhl; % for conditions 2
        elseif CTp == 2 % edge contrast
            edgePropSzTst = edgePropSzRef ; % Condition 1
            cuConEdge = edgeConCond(TCs); cuConWhl = mnConWhl; %
        end
        baseGryTst = [ 0.5-cuConWhl 0.5+cuConWhl 0.5-cuConEdge 0.5+cuConEdge ] ;        
        
        % Constant conditions
        radSpdTst = radSpdRef;
        
        % store values in REF file
        ResFile(kk+1,1) = TCs; % setting for the first condition... 
        ResFile(kk+1,2) = CTp; % setting for the second condition..
        % test stimulus generation below:
        WheelStimMatTst = WheelSpinRadialb(StimuliSize, numSeg, radVec, edgePropSzTst, baseGryTst, ...
        FrameNo, radSpdTst, Di);

    elseif testType == 2        % Speed and Wheel contrast
        % fixed conditions
        edgePropSzTst = edgePropSzRef;
        
        % test conditions... 
        if CTp == 1 % speed
            cuConEdge = mnConEdge; cuConWhl = mnConWhl; % for conditions 2
            baseGryTst = [ 0.5-cuConWhl 0.5+cuConWhl 0.5-cuConEdge 0.5+cuConEdge ] ;
            radSpdTst = speedCond(TCs);
        elseif CTp == 2 % wheel contrast
            cuConEdge = mnConEdge; cuConWhl = wheelConCond(TCs); % for conditions 2
            baseGryTst = [ 0.5-cuConWhl 0.5+cuConWhl 0.5-cuConEdge 0.5+cuConEdge ] ;
            radSpdTst = radSpdRef;
        end
        % store ref conditions
        ResFile(kk+1,1) = TCs; % setting for the first condition... 
        ResFile(kk+1,2) = CTp; % setting for the second condition..
        % test stimulus generation below:
        WheelStimMatTst = WheelSpinRadialb(StimuliSize, numSeg, radVec, edgePropSzTst, baseGryTst, ...
        FrameNo, radSpdTst, Di);

    elseif testType == 3        % arrows, context - 
        edgePropSzTst = edgePropSzRef;
        cuConEdge = mnConEdge; cuConWhl = mnConWhl; %
        baseGryTst = [  0.5-cuConWhl 0.5+cuConWhl 0.5-cuConEdge 0.5+cuConEdge ];
        radSpdTst = radSpdRef;
        
        % arrow size conditions - arrow direction (CTp) and arrow size 
        aSz = ArrSzCond(TCs); % size condition on this trial
        if CTp == 1     % in this case the congruent condition, aligning direction with arrows
            WheelStimMatTst = WheelSpinRadialArrow(StimuliSize, numSeg, radVec, edgePropSzTst, baseGryTst, ...
             FrameNo, radSpdTst, Di, Di, aSz); % Coherent with direction, both arrow and direction Di
        elseif CTp == 2     % incogruent condition, expansion direction opposite from arrow direction. 
            WheelStimMatTst = WheelSpinRadialArrow(StimuliSize, numSeg, radVec, edgePropSzTst, baseGryTst, ...
             FrameNo, radSpdTst, Di, -Di, aSz); %
        end

        % store ref conditions
        ResFile(kk+1,1) = TCs; % setting for the first condition... 
        ResFile(kk+1,2) = CTp; % setting for the second condition..
    end    
    

    % D.1 Results file first four entries F/S, Bounce, Dir, yVelocity, Responded?, RT
    ResFile(kk+1,1) = TCs; % setting for the parameter step... 
    ResFile(kk+1,2) = CTp; % setting for the condition number 1 or 2.. 

    ResFile(kk+1,3) = Di; % rotation direction clockwise vs anticlockwise... 
    ResFile(kk+1,4) = Hem; % hemisphere of appearance...
    
    if rem((kk),nDrift)==0
         % do a periodic driftcorrection, should be five times per block
         disp('Drift Check now....'); % let experimenter know we are running drift check
         EyelinkDoDriftCorrection(el);
    end
    
    % D.2 Set up what info from trials, task etc is going into the edf file...
    Eyelink('command', 'record_status_message "TRIAL no:%d/%d sNo %d Typ %d" ', kk+1, NTrials,TCs, CTp);
       
    trialInfo = sprintf('%d. sNo: %d Typ: %d', kk+1, TCs, CTp);
    Eyelink('message', 'TrialInfo: %s', trialInfo);
    % WARNING: THE FOLLOWING LINE IS IMPORTANT TO AVOID BLANKS IN THE
    % RECORDINGS
    Eyelink('Command', 'set_idle_mode'); %it puts the tracker into offline mode 
    WaitSecs(0.005); % it waits for 10ms before calling the startRecording funct
    
    % D.3 Start recording and test that it works
    Eyelink('StartRecording');
    WaitSecs(0.001);
    
    test_error = Eyelink('CheckRecording');
    CurrentTime0 = GetSecs;
    while(test_error~=0)
           CurrentTime = GetSecs;
           EL_blackout_dur = CurrentTime - CurrentTime0;
           
           if EL_blackout_dur > 0.5
               save([sbjresultpath,ResultsFilename],'ResFDet');
               
               %cd(sbjresultpath);
               fprintf('Receiving data file ''%s''\n', edfFile ); %stampa in command window cosa sta facendo
               status=Eyelink('ReceiveFile');%ReceiveFile ? una funzione del toolbox
               if status > 0
                    fprintf('ReceiveFile status %d\n', status);
               end
               if 2==exist(edfFile, 'file')
                   fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
               end
       
               error('Problems with Eyelink!');
           end
           test_error=Eyelink('CheckRecording');
   end
   WaitSecs(0.001); % very short wait time just so things don't fall over
        
   % D.4 start readiness for keyboard inputs.. 
    % prepare keyboard for inputs... wait for choice or end task...
    [keyIsDown,secs,keyCode] = KbCheck;
            
    % Grey Screen....
    Screen('FillRect', win, gray);
    Screen('Flip', win);
    WaitSecs(0.010); % additional 10ms Grey, was initially 250ms
    
    % Fixation Spot....
    Screen('FillRect', win, gray);
    Screen('FillOval', win, [1 1 1], [Cx-3 Cy-3 Cx+3 Cy+3]); % small fixation spot
    Screen('Flip', win);
    WaitSecs(BefStimS); % 250ms Fixation, from an original 250ms
    
    % D.5 Perhaps there should be a fixation window criteria over here... [Not in use 2024]
    % check for presence of a new sample update
    if WindCon == 0 
        FixMade = 1;
        WaitSecs(0.0010); %
    else FixMade = 0; % initialize a function which checks if eye is within a fixation window 
    end
    
    CurrentTime0 = GetSecs;
    while FixMade ~= 1 
        %this should get sample and check if it is inside the window size FixRad...
        if Eyelink( 'NewFloatSampleAvailable') > 0
            % get the sample in the form of an event structure
             evt = Eyelink( 'NewestFloatSample');
             xeye = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
             yeye = evt.gy(eye_used+1);

                %% do we have valid data and is the pupil visible?
                 if xeye~=el.MISSING_DATA && yeye~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                    % if data is valid, compare gaze position with
                    % the
                    % limits of the tolerance window
                    diffx = abs(xeye - Cx); % fixation with x offset
                    diffy = abs(yeye - Cy);

                    if (diffx > CpixPerDeg*FixRad || diffy > CpixPerDeg*FixRad) % window size is one degree of vis angle
                        Eyelink('message', 'OutsideFixSqr');
                        WaitSecs(0.010); % short wait before next sample
                        CurrentTime0 = GetSecs;
                    end

                    if (diffx < CpixPerDeg*FixRad && diffy < CpixPerDeg*FixRad) % ||  FixWindowCh == 0
                        WaitSecs(0.001); % short wait 1ms before next sample
                        CurrentTime = GetSecs;
                        FixCount = CurrentTime - CurrentTime0;
                        if FixCount> 0.01   % make sure fixation is held for a continuous 10ms
                            Eyelink('message', 'CFixSqr');
                            FixMade = 1; %
                        end
                    end

                 end % end of if condition testing if there is a new sample
                 
                 % check keyboard here for escape during fixation loop...
                 % stopkey
                if keyCode(stopkey) 
                    disp('you have used the space key to stop experiment during fixation attempt.');
                    disp(['Current trial: ' num2str(kk+1) ]);
                    Eyelink('message', 'ExperimentStopped');
                    Eyelink('StopRecording');  
                    sca();
                    return;
                end             
                
        end  % end of check through samples...
    end % end of while loop through sample positions to check if inside the window...
    
    % D.6 Actual trial start.... 
    % code to put up the ball on the screen in a given frame
    Screen('FillRect', win, gray); % get rid of initial fixation spot
    
    BallFixVerts = [Cx-DotRad Cy-DotRad Cx+DotRad Cy+DotRad]; % defines the ball, centred on zero
    CurrX = 0 ; % current position with offsets if needed...
    CurrY = 0 ;
    BallCurrVerts = BallFixVerts + [ CurrX CurrY CurrX CurrY ] ; 
    Screen('FillOval', win, [0.1 0.1 0.1], BallCurrVerts); % Stimulus... ball fixation spot, assuming 0.1 is colour
    Screen('Flip', win);
    %**************************************************************
    
    Eyelink('message', 'StimulusOn');
    StimulusOnsetTime = GetSecs;  % get time of start of stimulus display...
    PreTrialDur = StimulusOnsetTime - PreComputeTime;         % store this
    
    % D.7 if a button is pressed, evaluate choices accordingly
    curr_time = 0;
    PrevFrame = 0;      % initiate the previous frame to zero for comparison... 
    shownFrames = NaN;    % Check if all expected frames were eventuall shown              
    
    % D.7.1 for the current trial, create the symmetrical stimulus if
    % needed...
    %cStimRef = squeeze(WheelStimMatRef()); 
    %cStimTst = squeeze(WheelStimMatTst());                
    cStimBoth = ones(round(StimuliSize*StmAr),StimuliSize)*0.5;
    lftInd = 1:StimuliSize;
    rgtInd = round((StmAr-1)*StimuliSize) + lftInd;

    %cStim = ones(size_im,size_im).*gray;   % initialise to grey screen    
    while curr_time<PresTime
        CurrentTime = GetSecs; % get time from the clock
        elapsed_time = CurrentTime - StimulusOnsetTime;
        CurrFrame = round(FrameNo*elapsed_time/PresTime); % calculate current frame number...
        [keyIsDown,secs,keyCode] = KbCheck;
                
        if PrevFrame ~= CurrFrame && CurrFrame>0 && CurrFrame<=FrameNo  % if it is time to add a new frame but frames are less than maximum no.
            % get current frame image
            cStimRef = squeeze(WheelStimMatRef(:,:,CurrFrame)); % should be REF 
            cStimTst = squeeze(WheelStimMatTst(:,:,CurrFrame)); % should be test
            % direction placed condition..
            if Hem == 1   % Reference on the left, Test on the right
                cStimBoth(lftInd,lftInd) = cStimRef; 
                cStimBoth(rgtInd,lftInd) = cStimTst;
            elseif Hem == 2 % Reference on the right, test on the left
                cStimBoth(lftInd,lftInd) = cStimTst; 
                cStimBoth(rgtInd,lftInd) = cStimRef;    
            end
            
            % 1. current frame for the reference
            Screen('PutImage', win, cStimBoth'*255);
            Screen('FillOval', win, [0.1 0.1 0.1], BallCurrVerts); %
            if CurrFrame == 1, shownFrames = 0; end

            Screen('Flip', win); 
            shownFrames = shownFrames + 1; % count frames if needed
            %**************************************************************            
            %Eyelink('message', 'FrameChange');
        end
        
        % stopkey
        if keyCode(stopkey) 
            disp('you have used the space key to stop the experiment.');
            disp(['Current trial: ' num2str(kk+1) ]);
            Eyelink('message', 'ExperimentStopped');
            Eyelink('StopRecording');
            sca();
            return;
        end
      
        curr_time = elapsed_time + 0.001; 
        PrevFrame = CurrFrame;        
    end % at this point out of trial without response
    
    % next lines happen outside the stimulus display, there is a grey
    % screen
    if RT==0.0, DrawFormattedText(win, 'left <- or right -> stronger illusion?', 'center', 'center'); end
    Screen('flip',win);  % tested at the end of program at present
    Eyelink('message', 'StimulusOff');
    
    while RT==0.0    % no reaction recorded, need to step out of this RT loop 
        CurrentTime = GetSecs; % get time from the clock
        elapsed_time = CurrentTime - StimulusOnsetTime; 
        [keyIsDown,secs,keyCode] = KbCheck;
        
        % Left Selected as stronger
        if keyCode(leftKey) && RT == 0.0 % slower case (Feb 2026)
            RT = elapsed_time;  % -            
            savedRes = 1;       % 2 for faster, 1 for slower... 
            % check whether test is chosen over reference
            if Hem == 2
                testRes = 1; % i.e. the Test is chosen over reference 
            else
                testRes = 0; %
            end
        end

        % Right selected as Stronger
        if keyCode(rightKey) && RT == 0.0 % faster case (Feb 2026)
            RT = elapsed_time;  % -            
            savedRes = 2;       % 2 for faster, 1 for slower... 
            % check whether test is chosen over reference
            if Hem == 1
                testRes = 1; % i.e. the Test is chosen over reference 
            else
                testRes = 0; %
            end
        end
        
        % Down response, should not be used... 
        if keyCode(downKey) && RT == 0.0 % faster case (Feb 2026)
            RT = elapsed_time;  % -            
            savedRes = 0;       % 0 for blank... 
        end


        % stopkey
        if keyCode(stopkey) 
            disp('you have used the space key to stop the experiment.');
            disp(['Current trial: ' num2str(kk+1) ]);
            Eyelink('message', 'ExperimentStopped');
            Eyelink('StopRecording');  
            sca();
            return;
        end
        %curr_time = elapsed_time + 0.001; % approximation of what will have lapsed during a frame...  
    
    end
    %End of trial
    Screen('Flip', win);
    Screen('FillRect', win, gray);
    Screen('Flip', win);
    Eyelink('message', 'ResponseGreyOn');
    WaitSecs(0.025); % grey....
    Eyelink('StopRecording');        
    
    %******************************   % April 2015... to have a store of
    %input images...
    %S.ImageStore(kk+1).CurrIm = grayScaleImageMatrix; % store image of the current trial...
    %*********************************
    
    % Factors going into Resfile: F/S, Bounce, Dir, yVelocity, Responded?, RT
    if RT > 0
        ResFile(kk+1,5) = savedRes; % choice (correct/ incorrect...)
        ResFile(kk+1,6) = RT; % Reaction time in task, possibly useful...
        ResFile(kk+1,7) = testRes; % Whether the test was chosen over the reference 
        ResFile(kk+1,8) = shownFrames/FrameNo; % proportion of frames shown in task        
    end 
    
    kk = kk+1; % trial increment...         
    disp(num2str(kk));
    % at the end of the trials, close everything down and stop recording...
    if kk == NTrials
        perc_text=['End of this block, your participation is appreciated...\n'];
        DrawFormattedText(win, perc_text, 'center', 'center');
        Screen('flip',win);  % tested at the end of program at present
        Eyelink('CloseFile');
        cd(DataDir); %
        fprintf('Receiving data file ''%s''\n', edfFile ); % block end info
           status=Eyelink('ReceiveFile');%ReceiveFile ? una funzione del toolbox
           if status > 0
               fprintf('ReceiveFile status %d\n', status);
           end
           if 2==exist(edfFile, 'file')
               fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
           end
        Eyelink('ShutDown');
        
    end 
end
    time_end = clock;
    % save data files with all the useful info in them
    %Screen_resolution = Screen('Resolution', screenID);
    
    % Psychometrici calculation... 
    ShowPsychM = 0; % do you want to show the psychometric function from the task?
    psyProbs = zeros(2,6); % to store psychometric function... 
    ConIndx = ResFile(:,2); % numbers 1 and 2
    for ii = 1:6
        % Extract current cond 1 probabilities  
        cResF = ResFile((ConIndx==1),:); % first condition
        StimIndx = cResF(:,1); % index of numbers 1-6
        cPr = squeeze(cResF((StimIndx==ii),7)); % 
        cProbs(1,ii) = sum(cPr)/length(cPr);  % proportion of test chosen...

        % extract condition 2 probabilities
        cResF = ResFile((ConIndx==2),:); % first condition
        StimIndx = cResF(:,1); % index of numbers 1-6
        cPr = squeeze(cResF((StimIndx==ii),7)); % 
        cProbs(2,ii) = sum(cPr)/length(cPr);  % proportion of test chosen...
    end
    
    % show plot of psychometric function...
    if ShowPsychM == 1
        % pick condition 
        xRng = 1:6;
        plot(xRng,cProbs(1,:),'bo-');
        hold on
            plot(xRng,cProbs(2,:),'go-');
        hold off
        line([ 0 7 ],[ 0.5 0.5 ],'LineStyle','--'); % chance line, both selected the same
        line([ 3.5 3.5 ],[ 0 1 ],'LineStyle','--'); %
        xlabel('Condition range');
        ylabel('Test Prob');
        axis([0 7 0 1.0]); % display range... 
    end

    %sca();
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSuppressAllWarnings);
    %catch
    %Save results/data structure file...
    
    S.ResFile = ResFile; % an array storing the different experimental conditions
    
    S.TaskDescription = 'In this task, participants will be presented with trials in which there is a ball moving across the screen bouncing off against an invisible wall and floors. They indicate when it stops bouncing.';
    S.StimuliSize = StimuliSize; % the diameter of the stimulus in pixels..
    S.NTrials = NTrials; % number of trials being tested
    
    S.PresTime = PresTime; % presentation time in seconds... test, 0.5, real, 3, 2
    S.Age = sbjage; % recorded age 
    S.Sex = sbjsex; % record biological sex
    S.Handedness = sbhand; % Participant handedness
    S.Initials = sbjinit; % recorded initials in case needed
    S.Screen_Spatialresolution = SRes; %screen resolution
    S.ScreenRefreshRate = Hz;
    S.DistanceToTaskScreenCm = ScreenDistanceCm;
    S.PixelsPerDegreeViewingAngle = CpixPerDeg; 
    S.InterFrameDurationInS = dT;
    S.StimulusSizeDegrees = StimSzDeg;
    S.FixationToleranceWindowDeg = FixRad;
    S.PropOfTrialsPerDriftCorrection = PDrift;
    
    S.StimulusParameters = StimParams;
    S.NumberOfDisplayFrames = FrameNo; 
    S.SetRandomisationSeed = SetSeed;
    S.StimulusInfoForEachTrial = StimInfo;
    S.StimulusInfoMoreGeneral = StimParams; 

    S.EyeAcuityScore = EyeAcuityScore;
    S.EyeChartUsed = EyeChart;
    S.SpeedConditionsDegPerSec = speedCond;
    
    % [year month day hour minute seconds]
    S.time_end = [ 'Ended at ' num2str(time_end(4)) ':' num2str(time_end(5)) ',' ...
                    num2str(time_end(6)) 's'  ] ; % record of experiment end time...
    S.time_start = [ 'Started at ' num2str(time_start(4)) ':' num2str(time_start(5)) ',' ...
                    num2str(time_start(6)) 's'  ] ; % % record of experiment end time...
    S.date = date;
    disp(S.time_start);
    disp(S.time_end);
    
    cd(DataDir); % go to specific data directory
    save(ResultsFilename, '-struct','S');
    cd(StartDir);
    % test
        
    sca();
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSuppressAllWarnings);
    psychrethrow(psychlasterror);   
