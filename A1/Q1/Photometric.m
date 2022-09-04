classdef Photometric
    %STEREOSCOPIC Summary of this class goes here
    %   Detailed explanation goes here
    

    properties (Access=private)
        img_array;
        light_dirs;
    end
    properties
        albedo;
        g;
        residuals;
        surface;
        w;
        h;
        n;
    end
    
    methods 
        function obj = Photometric(img_array, light_dirs)
            [ih, iw, in] = size(img_array);
            [dn, d3] = size(light_dirs);
            if (in ~= dn) 
               error("there must be the same number of images as light directions");
            end
            if (d3 ~= 3) 
                error("light directions must be a 3 column vector");
            end
            obj.img_array = double(img_array) / 255;
            obj.light_dirs = light_dirs;
            obj.w = iw;
            obj.h = ih;
            obj.n = in;
            
            obj.residuals = zeros(ih, iw, in);
            obj.albedo = zeros(ih, iw);
            obj.g = zeros(ih, iw, 3);
            obj.surface = zeros(ih, iw);

        end
        
        function obj = solve_residuals(obj)
            for y = 1:obj.h
                for x = 1:obj.w
                    p = obj.light_dirs * reshape(obj.g(y, x, :), [3, 1]);
                    res =  p - reshape(obj.img_array(y, x, :), [], 1);
                    obj.residuals(y, x, :) = res / std(res);
                end
            end
            
        end
        
        function obj = solve_model_outlier_rejection(obj)
            % For every pixel xy
            for y = 1:obj.h
                for x = 1:obj.w 
                    % Take the set of light directions and pixels for which 
                    % residuals no greater than 2 stds for 0
                    valid = find(abs(obj.residuals(y, x, :)) < 2);
                    I_xy = reshape(obj.img_array(y, x, :), [], 1);
                    I_xy = I_xy(valid);
                    S = obj.light_dirs(valid, :);
                    
                    % Solve the g vector and compute the albedo using
                    % filtered pixel and direction set
                    g_xy = S \ I_xy;
                    obj.g(y, x, :) = g_xy;
                    obj.albedo(y, x) = norm(g_xy);
                end
            end
        end
        
        function obj = solve_model_basic(obj)
            % For every pixel xy
            for y = 1:obj.h
                for x = 1:obj.w 
                    I_xy = reshape(obj.img_array(y, x, :), [obj.n, 1]);
                    
                    % solve the g vector and compute the albedo
                    g_xy = obj.light_dirs \ I_xy;
                    obj.g(y, x, :) = g_xy;
                    obj.albedo(y, x) = norm(g_xy);
                end
            end
        end
        
        function obj = solve_surface_height(obj, method)
            if (~exist("method", "var")) 
                method = 3;
            end
            dx_f = obj.g(:, :, 1) ./ obj.g(:, :, 3); % g_x / g_z
            dy_f = obj.g(:, :, 2) ./ obj.g(:, :, 3); % g_y / g_z

            hsum = cumsum(dx_f, 2); % sum along the horizontal
            vsum = cumsum(dy_f, 1); % sum along the vertical
            
            method1 = hsum + repmat(vsum(:, 1), 1, obj.w);
            method2 = vsum + repmat(hsum(1, :), obj.h, 1);
            
            switch (method)
                case 1
                    obj.surface = method1;
                case 2
                    obj.surface = method2;
                case 3
                    obj.surface = (method2 + method1) / 2;
            end
        end
        
            
        function obj = plot_surface(obj, method)
            obj = obj.solve_surface_height(method);
            s = surf(obj.surface, repmat(obj.albedo, 1, 1, 3));
            s.EdgeColor = "none";
            s.FaceColor = "texturemap";
            s.FaceLighting = "flat";
        end
        
        function plot_residuals(obj)
            R = obj.residuals;
            [H, W, N] = size(R);
            
            cols = round(sqrt(N));
            rows = ceil(N/cols);
            
            pimage = zeros(rows * H, cols * W, 3);
            
            for i = 1:N 
                c = mod((i - 1), cols) * W + 1;
                r = floor((i - 1) / cols) * H + 1;

                % Generate image
                im = repmat(obj.img_array(:, :, i), 1, 1, 3);
                % color residuals > 2 std red
                im(:, :, 1) = im(:, :, 1) + (R(:, :, i) .* (R(:, :, i)>2));
                % color residuals < 2 std blue
                im(:, :, 3) = im(:, :, 3) + (-1 * R(:, :, i) .* (R(:, :, i)<-2));

                % Add to image montage
                pimage(r:(r+H-1), c:(c+W-1), :) = im;
            end
            
            imshow(pimage);
        end
    end
end

