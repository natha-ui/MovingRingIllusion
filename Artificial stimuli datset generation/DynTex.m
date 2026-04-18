classdef DynTex < handle
    %MOTIONCLOUD Summary of this class goes here
    %   Detailed explanation goes here
    properties (SetObservable)
        over_samp = 5;
        size_im = 256;
        fps = 50;
        px_per_cm = 50;
        ave_lum = 128.0;
        contrast = 35.0;
        dev = 'cpu'; 
        dt = 0.02;
        verbose = 0;
        frame0 = 0;
        frame1 = 0;
        frame2 = 0;
        spatial_frame = 0;
        frame_count = 0;
        seed = 0;
        hist_len = 10;
        frame_hist = zeros(10, 256, 256);
        
        tau = 0.01;
        
        x;y;R;Theta;
        
        rdm_stream;
        al;be;
        kernel_params;
        kernel = 1;
        run;
        fig;
    end
    methods
        function obj = DynTex(size_im, ave_lum, contrast, adv_params)
            % create a dyntex object
            % 
            if nargin==1
                obj.size_im = size_im;
            elseif nargin==2
                obj.size_im = size_im;
                obj.ave_lum = ave_lum;
            elseif nargin==3
                obj.size_im = size_im;
                obj.ave_lum = ave_lum;
                obj.contrast = contrast;
            elseif nargin==4
                fnames = fieldnames(adv_params);
                obj.fps = adv_params.(fnames{1});
                obj.over_samp = adv_params.(fnames{2});
                obj.px_per_cm = adv_params.(fnames{3});
                obj.hist_len = adv_params.(fnames{4});
                obj.dev = adv_params.(fnames{5});
                obj.seed = adv_params.(fnames{6});
                obj.verbose = adv_params.(fnames{7});
            end
            
            if strcmp(obj.dev,'gpu')
                obj.rdm_stream = parallel.gpu.RandStream('Philox',...
                                                         'Seed',...
                                                         obj.seed);
            elseif strcmp(obj.dev,'cpu')
                obj.rdm_stream = RandStream('Philox', 'Seed', obj.seed);
            end
            
            obj.fig = figure;
            close(obj.fig);
            addlistener(obj,'size_im','PostSet',@obj.setFrameHist);
            addlistener(obj,'hist_len','PostSet',@obj.setFrameHist);
        end
        
        % main parameters
        %
        function set.size_im(obj,size_im)
            obj.size_im = size_im;
        end
        
        function set.ave_lum(obj,ave_lum)
            obj.ave_lum = ave_lum;
        end
        
        function set.contrast(obj,contrast)
            obj.contrast = contrast;
        end
        
        %
        
        % advanced parameters 
        %
        
        function set.fps(obj,fps)
            obj.fps = fps;
        end

        function set.over_samp(obj,over_samp)
            obj.over_samp = over_samp;
        end        
        
        function set.px_per_cm(obj,px_per_cm)
            obj.px_per_cm = px_per_cm;
        end
        
        function set.hist_len(obj,hist_len)
            obj.hist_len = hist_len;
        end
        
        function set.dev(obj,dev)
            obj.dev = dev;
        end
        
        function set.seed(obj,seed)
            obj.seed = seed;
        end
                
        function set.verbose(obj,verbose)
            obj.verbose = verbose;
        end
                
        function dt = get.dt(obj)
           dt = 1/(obj.fps*obj.over_samp); 
        end
        
        % frame hist array
        function setFrameHist(obj, src, evnt)
            obj.frame_hist = zeros(obj.hist_len, obj.size_im, obj.size_im);
        end
        
        function obj = setGrids(obj)
            % set the cartesian and polar grids
            %
            %
            %
            lx_sup = linspace(-floor(obj.size_im/2),-1,floor(obj.size_im/2));
            lx_inf = linspace(0,floor(obj.size_im/2)-1,floor(obj.size_im/2));
            Lx = cat(2,lx_inf,lx_sup);
            [obj.x,obj.y] = meshgrid(Lx,Lx);
            obj.x=obj.x/obj.size_im; obj.y=obj.y/obj.size_im;
            obj.R = sqrt(obj.x.^2+obj.y.^2);
            obj.R(1,1) = 1e-6;
            obj.Theta = atan2(obj.y,obj.x);
            if gpuDeviceCount > 0 && strcmp(obj.dev,'gpu')
                fprintf('Using GPU !\n');
                obj.x = gpuArray(obj.x);
                obj.y = gpuArray(obj.y);
                obj.R = gpuArray(obj.R);
                obj.Theta = gpuArray(obj.Theta);
            elseif gpuDeviceCount == 0 && strcmp(obj.dev,'gpu')
                %fprintf('You do not have a Nvidia GPU or '+...
                %        'Matlab does not detect your Nvidia GPU.\n');
                fprintf(strcat('You do not have a Nvidia GPU or ',...
                               'Matlab does not detect your ',...
                               'Nvidia GPU.\n'));
            elseif strcmp(obj.dev,'cpu')
                fprintf(strcat('Using CPU ! (can be slow ',...
                               'for real time stimulation)\n'));
            end            
        end

        function obj = setArCoeffs(obj)
            % CAR coefficients / critical regime
            one_over_tau=1/obj.tau;
            a=2*one_over_tau;
            b=one_over_tau.^2;

            % AR coefficients
            obj.al=(2-obj.dt*a-obj.dt^2*b);
            obj.be=(-1+obj.dt*a);
        end
        
        
        function frame = getFrame(obj, adjust)
            % to compute the next frame from the last two frames
            %
            %
            for i=1:obj.over_samp
                cnoise = randn(obj.rdm_stream, obj.size_im, obj.size_im)+...
                         1i*randn(obj.rdm_stream, obj.size_im, obj.size_im);
                % AR(2) recursion in Fourier domain
                obj.frame0 = obj.al.*obj.frame1...
                           + obj.be.*obj.frame2...
                           + obj.kernel.*cnoise;
                % update values
                obj.frame2 = obj.frame1;
                obj.frame1 = obj.frame0;
            end
            % ifft
            obj.spatial_frame = obj.size_im^2*real(ifft2(obj.frame0));

            if adjust
                obj.spatial_frame = obj.spatial_frame./...
                                        std(obj.spatial_frame(:),0);
                                       %std(std(obj.spatial_frame, 0), 0);
                obj.spatial_frame = obj.contrast*obj.spatial_frame+...
                                        obj.ave_lum;
            else
                obj.spatial_frame = obj.spatial_frame;
            end

            frame = obj.spatial_frame;

            if obj.frame_count<size(obj.frame_hist,1)
                obj.frame_hist(end-obj.frame_count,:,:) = obj.frame0;
            else
                obj.frame_hist(2:end, :, :) =...
                                obj.frame_hist(1:end-1, :, :);
                obj.frame_hist(1,:,:) = obj.frame0;
            end
            obj.frame_count = obj.frame_count + 1;
                
            
        end
        
        function spat_spectrum = dispSpatSpectrum(obj, log_scale)
             spat_spectrum = squeeze(mean(abs(obj.frame_hist).^2,1));
             if log_scale
                 M = max(max(log(spat_spectrum)));
                 imshow(fftshift(log(spat_spectrum)), [M-11.5, M])
             else
                 M = max(max(spat_spectrum));
                 imshow(fftshift(spat_spectrum), [1e-1*M, M])
             end
        end
        
        function temp_spectrum = dispTempSpectrum(obj, log_scale)
             temp_spectrum = squeeze(mean(abs(...
                                    fft(obj.frame_hist,obj.size_im,1)).^2,2));
             temp_spectrum = fftshift(temp_spectrum);
             %temp_spectrum = temp_spectrum(obj.size_im/4-1:3*obj.size_im/4,...
             %                              obj.size_im/4-1:3*obj.size_im/4);
             if log_scale
                 M = max(max(log(temp_spectrum)));
                 imshow(log(temp_spectrum), [M-11.5, M])
             else
                 M = max(max(temp_spectrum));
                 imshow(temp_spectrum, [1e-1*M, M])
             end
        end
        
        

        function callbackStop(obj,src,event)
            obj.run = 0;
        end
        
        function callbackPlay(obj,src,event)
            if obj.run==0
                obj.movieDisplay();
            end
        end
        
        function callbackClose(obj,src,event)
            obj.run = 0;
            close(obj.fig);
        end
        
        function callbackSpatialFreq(obj,src,event)
            obj.run = 1;
        end
        
    end
end
