classdef MotionCloud < DynTex & matlab.mixin.SetGet
% Motion Clouds Object for stimulus generation,
% parameter exploration and psychophysics
% Version for peer testing V2.0, 02/12/2021 by ©Jonathan Vacher
    
    properties (SetObservable)
        sf;sf_bdw;sf_mode;rho;rho_sig;
        th;th_sig;th_rad;th_rad_sig;
        speed;speed_sig;tf;speed_pxpf;speed_sig_pxpf;
        octa;
        one_over_tau;
        offset_duration;
    end
    
    methods
        function obj = MotionCloud(varargin)                   
            % Basic MotionCloud bandpass power spectrum
            %
            % set user params
            % size_im, ave_lum, contrast, adv_params
            
            obj = obj@DynTex(varargin{:});
            
        end        
        
        function obj = setParams(obj,kernel_params)
            % MotionCloud parameters
            % sf, sf_bdw, th, th_sig, speed, speed_sig, octa
            % AIM, note for JV - Nov 2022, this use of fnames{i} too
            % restrictive? Check... all need to be in strict order! 
            if nargin==2
                fnames = fieldnames(kernel_params);
                obj.sf = kernel_params.(fnames{1});
                obj.sf_bdw = kernel_params.(fnames{2});
                obj.th = kernel_params.(fnames{3});
                obj.th_sig = kernel_params.(fnames{4});
                obj.speed = kernel_params.(fnames{5});
                obj.speed_sig = kernel_params.(fnames{6});
                obj.octa = kernel_params.(fnames{7});
            elseif nargin==1
                obj.sf = 2.5;
                obj.sf_bdw = 1.0;
                obj.th = 0;
                obj.th_sig = 10;
                obj.speed = [0.0, 0.0];
                obj.speed_sig = 50.0;
                obj.octa = 1; 
            end
            % parametrization by time constant ?? (also check dependency)
            % obj.tf = kernel_params.(fnames{6});            
            
            
            % set grids, AR coeffs and kernel
            obj.setAll();
            obj.burnout();
               
            addlistener(obj,'size_im','PostSet',@obj.setAll);
            
            addlistener(obj,'speed_sig','PostSet',...
                        @obj.setArCoeffsAndKernel);
            
            addlistener(obj,'speed','PostSet',@(~,~)obj.setArCoeffs());
            %addlistener(obj,'speed','PostSet',@obj.setArCoeffs);
            
            addlistener(obj,'sf','PostSet',@obj.setKernel);
            addlistener(obj,'sf_bdw','PostSet',@obj.setKernel);
            addlistener(obj,'th','PostSet',@obj.setKernel);
            addlistener(obj,'th_sig','PostSet',@obj.setKernel);   
        end
        
        
        % kernel params
        function set.sf(obj,sf)
            obj.sf = sf;
        end
        
        function set.sf_bdw(obj,sf_bdw)
            obj.sf_bdw = sf_bdw;
        end
        
        function set.th(obj,th)
            obj.th = th;
        end
        
        function set.th_sig(obj,th_sig)
            obj.th_sig = th_sig;
        end
        
        function set.speed(obj,speed)
            obj.speed = speed;
        end
        
        function set.speed_sig(obj,speed_sig)
            obj.speed_sig = speed_sig;
        end

        function set.tf(obj,tf)
            obj.tf = tf;
        end
        
        function set.octa(obj,octa)
            obj.octa = octa;
        end
        
        % dependent params
        function th_rad = get.th_rad(obj)
            th_rad = obj.th*pi/180;
        end
        
        function th_rad_sig = get.th_rad_sig(obj)
            th_rad_sig = obj.th_sig*pi/180;
        end
        
        function sf_mode = get.sf_mode(obj)
            sf_mode = obj.sf/obj.px_per_cm;
        end
        
        function rho_sig = get.rho_sig(obj)
            if obj.octa==1
                rho_sig = sqrt(exp((obj.sf_bdw*...
                                        sqrt(log(2)/8))^2)-1);
            elseif obj.octa==0
                rho_sig = roots([1,0,3,0, 3,0,1,0,...
                        -(obj.sf_bdw/obj.px_per_cm)^2/obj.sf_mode^2]);
                rho_sig = rho_sig(real(rho_sig)>0 &...
                                  imag(rho_sig)==0);
            end
        end
        
        function rho = get.rho(obj)
            rho = obj.sf_mode*(1+obj.rho_sig^2);
        end
        
        function speed_pxpf = get.speed_pxpf(obj)
            % px per frame
            speed_pxpf = obj.speed*obj.px_per_cm/obj.fps;
        end

        function speed_sig_pxpf = get.speed_sig_pxpf(obj)
            % px per frame
            speed_sig_pxpf = obj.speed_sig*obj.px_per_cm/obj.fps;
            
            % safety factor to ensure convergence beyond
            % numerical issues    
            safety_const = 1.0;
            if obj.verbose
                if speed_sig_pxpf>safety_const*(4-2*sqrt(2))/(obj.dt)
                    fprintf('speed_sig=%f must be lower than %f \n',...
                            [obj.speed_sig,...
                             safety_const*(((4-2*sqrt(2)))*obj.fps...
                             /(obj.dt*obj.px_per_cm))])
                else
                    fprintf('Correct parameters speed_sig = %f < %f \n',...
                            [obj.speed_sig,...
                             safety_const*(((4-2*sqrt(2)))*obj.fps...
                             /(obj.dt*obj.px_per_cm))])
                end
            elseif speed_sig_pxpf>safety_const*(4-2*sqrt(2))/(obj.dt)
                fprintf('speed_sig=%f must be lower than %f \n',...
                        [obj.speed_sig,...
                         safety_const*(((4-2*sqrt(2)))*obj.fps...
                         /(obj.dt*obj.px_per_cm))])
            end
        end
               
        function offset_duration = get.offset_duration(obj)
            offset_duration = 3/(obj.rho*obj.speed_sig*...
                                    obj.px_per_cm/obj.fps);
        end

%         function speed_sig = get.speed_sig(obj)
%             speed_sig = obj.tf/obj.rho;
%             if obj.verbose
%                 % 0.9 is a safety factor to ensure convergence beyond
%                 % numerical issues
%                 if speed_sig>0.9*(4-2*sqrt(2))/(obj.dt)
%                     fprintf('tf=%f must be lower than %f \n',...
%                             [obj.tf, 0.9*(((4-2*sqrt(2)))*obj.rho...
%                             /(obj.dt))])
%                 else
%                     fprintf('Correct parameters tf = %f < %f \n',...
%                             [obj.tf, 0.9*(((4-2*sqrt(2)))*obj.rho...
%                             /(obj.dt))])
%                 end
%             end
%         end
                
        function obj = setArCoeffs(obj)
            % CAR coefficients
            obj.one_over_tau=obj.speed_sig_pxpf*obj.R;
            a=2*obj.one_over_tau;
            b=obj.one_over_tau.^2;

            % AR coefficients
            obj.al=(2-obj.dt*a-obj.dt^2*b).*...
                exp(2*pi*1j*(obj.speed_pxpf(1)*obj.x+...
                             obj.speed_pxpf(2)*obj.y));
            obj.be=(-1+obj.dt*a).*...
                exp(2*2*pi*1j*(obj.speed_pxpf(1)*obj.x+...
                               obj.speed_pxpf(2)*obj.y));
        end
        
        function obj = setKernel(obj, src, event)
            % Spatial kernel
            angular=exp(cos(2*(obj.Theta-obj.th_rad))...
                            /(4*obj.th_rad_sig^2));
            
            radial = exp(-(log(obj.R/obj.rho).^2/...
                           log(1+obj.rho_sig^2))/2).*(1.0./obj.R);
            obj.kernel = angular.*radial.*(1.0./obj.R).^2;
            C = 1.0/sum(sum(obj.kernel));
            obj.kernel = 4*obj.kernel.*(obj.one_over_tau*obj.dt).^3.0;

            % Compute normalization constant
            obj.kernel = sqrt(C*obj.kernel);
        end
        
        function burnout(obj)
            N = int64(obj.offset_duration*obj.fps);
            for i=1:N
                obj.getFrame(0);
            end     
        end
        
        function obj = setAll(obj, src, event)
           obj.setGrids();
           obj.setArCoeffs();
           obj.setKernel();
        end

        function obj = setArCoeffsAndKernel(obj, src, event)
           obj.setArCoeffs();
           obj.setKernel();
        end

        function movieDisplay(obj)
            % display an MC movie as it is generated 
            % with play, stop, close buttons
            %
            %
            %
            if ishghandle(obj.fig)==0
                obj.fig = figure();
            end
            % play button
            uicontrol(...
                'Style','pushbutton', 'String', 'Play',...
                'Units','Normalized', 'Position', [0.05 0.8 0.18 0.05],...
                'Callback', @obj.callbackPlay);
            % stop button
            uicontrol(...
                'Style','pushbutton', 'String', 'Stop',...
                'Units','Normalized', 'Position', [0.05 0.75 0.18 0.05],...
                'Callback', @obj.callbackStop);
            % close button
            uicontrol(...
                'Style','pushbutton', 'String', 'Close',...
                'Units','Normalized', 'Position', [0.05 0.7 0.18 0.05],...
                'Callback', @obj.callbackClose);
            
            % slider sf
            % text {Units?}
            uicontrol(...
                'style','text','BackgroundColor',[0.95 0.95 0.95],...
                'Units','Normalized','Position',...
                 [0.14,0.22,0.4,0.05],'string','Spatial Freq.(c/cm)',...
                'fontsize',12,'fontweight','bold');
            % slider
            hs_sf = uicontrol(...
                'Style','slider','Value', obj.sf,...
                'Min',0.5,'Max',7.5,...
                'SliderStep',[0.1 0.2],...
                'Units','Normalized', 'Position', [0.185 0.17 0.3 0.05]);
            % slider value
            ht_sf = uicontrol('style','edit',...
                           'Units','Normalized',...
                           'String',num2str(hs_sf.Value),...
                           'Position',[0.11,0.17,0.07,0.05]);
            % update value
            update_sf_txt = @(~,e)set(ht_sf,'String',...
                            num2str(get(e.AffectedObject,'Value')));
            % update stim
            update_sf = @(~,e) set(obj,'sf',get(e.AffectedObject,'Value'));
            % listener for updates
            addlistener(hs_sf, 'Value', 'PostSet', update_sf_txt);
            addlistener(hs_sf, 'Value', 'PostSet', update_sf);
            
            % slider sf_sig
            uicontrol(...
                'style','text','BackgroundColor',[0.95 0.95 0.95],...
                'Units','Normalized','Position',...
                 [0.6,0.22,0.3,0.05],'string','S Freq. Bdw (Oct)',...
                'fontsize',12,'fontweight','bold');
            hs_sf_bdw = uicontrol(...
                'Style','slider','Value', obj.sf_bdw,...
                'Min',0.5,'Max',5.5,...
                'SliderStep',[0.1 0.2],...
                'Units','Normalized', 'Position', [0.585 0.17 0.3 0.05]);
            ht_sf_bdw = uicontrol('style','edit',...
                           'Units','Normalized',...
                           'String',num2str(hs_sf_bdw.Value),...
                           'Position',[0.51,0.17,0.07,0.05]);
            % update value
            update_sf_bdw_txt = @(~,e)set(ht_sf_bdw,'String',...
                            num2str(get(e.AffectedObject,'Value')));
            % update stim
            update_sf_bdw = @(~,e) set(obj,'sf_bdw',...
                            get(e.AffectedObject,'Value'));

            addlistener(hs_sf_bdw, 'Value', 'PostSet', update_sf_bdw_txt);
            addlistener(hs_sf_bdw, 'Value', 'PostSet', update_sf_bdw);
            
            % slider th
            uicontrol(...
                'style','text','BackgroundColor',[0.95 0.95 0.95],...
                'Units','Normalized','Position',...
                 [0.18,0.10,0.3,0.05],'string','Orientation (deg)',...
                'fontsize',12,'fontweight','bold');
            hs_th = uicontrol(...
                'Style','slider','Value', obj.th,...
                'Min',0.0,'Max',180,...
                'SliderStep',[1/18 1/9],...
                'Units','Normalized', 'Position', [0.185 0.05 0.3 0.05]);
            ht_th = uicontrol('style','edit',...
                           'Units','Normalized',...
                           'String',num2str(hs_th.Value),...
                           'Position',[0.11,0.05,0.07,0.05]);
            % update value
            update_th_txt = @(~,e)set(ht_th,'String',...
                            num2str(get(e.AffectedObject,'Value')));
            % update stim
            update_th = @(~,e) set(obj,'th',...
                            get(e.AffectedObject,'Value'));

            addlistener(hs_th, 'Value', 'PostSet', update_th_txt);
            addlistener(hs_th, 'Value', 'PostSet', update_th);

            % slider th_sig
            uicontrol(...
                'style','text','BackgroundColor',[0.95 0.95 0.95],...
                'Units','Normalized','Position',...
                 [0.6,0.10,0.3,0.05],'string','Ori. Bdw (deg)',...
                'fontsize',12,'fontweight','bold');
            hs_th_sig = uicontrol(...
                'Style','slider','Value', obj.th_sig,...
                'Min',0.5,'Max',51.5,...
                'SliderStep',[0.1 0.2],...
                'Units','Normalized', 'Position', [0.585 0.05 0.3 0.05]);
            ht_th_sig = uicontrol('style','edit',...
                           'Units','Normalized',...
                           'String',num2str(hs_th_sig.Value),...
                           'Position',[0.51,0.05,0.07,0.05]);
            % update value
            update_th_sig_txt = @(~,e)set(ht_th_sig,'String',...
                            num2str(get(e.AffectedObject,'Value')));
            % update stim
            update_th_sig = @(~,e) set(obj,'th_sig',...
                            get(e.AffectedObject,'Value'));            
            addlistener(hs_th_sig, 'Value', 'PostSet', update_th_sig_txt);
            addlistener(hs_th_sig, 'Value', 'PostSet', update_th_sig);
                    
                        
            % Axes
            ax = axes(...
                'Units','Normalized',...
                'OuterPosition', [0 0.2 1 0.8]);

            obj.run = 1;
            while obj.run
                image(obj.getFrame(1)); axis image; axis off;
                colormap gray(256);
                drawnow;
            end
        end

        
    end
end

