classdef StereoVision
    %STEREOVISION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rightimgs
        leftimgs
        posedata
        parameters
        n
        points
        pointcloud
        pointcolors
        terrain
        zrange
        
        max_delta
        max_ransac_dist
        tol
        
        % Evaluation metrics
        nfeatures   % number of features detected in left and right images
        nmatches
        ninliers 
        
        impoints        % matched feature points for left and right images (x, y, 1)
        pimages         % processed images left grayscale, right grayscale and left color
         
    end
    
    methods
        %% Constructor
        % Load data and parameters from the provided directory. Directory
        % must contain the following
        %   /images_left          (a folder containing left images)
        %   /image_right          (a folder containing right images)
        %   camera_pos_data.mat   (R, t, left_images, right_images)
        %   stereo_calib.mat      (stereoParameters)
        %   terrain.mat           (X, Y, height_grid)
        function obj = StereoVision(data_filepath)
            % load matlab files
            pdata = load(sprintf("%s/camera_pose_data.mat", data_filepath)).camera_poses;
            obj.parameters = load(sprintf("%s/stereo_calib.mat", data_filepath)).stereoParams;
            obj.terrain = load(sprintf("%s/terrain.mat", data_filepath));
            n = length(pdata.left_images);
            
            % load all images
            rimgs = cell(n, 1);
            limgs = cell(n, 1);
            for i = 1:n
                rimgs{i} = imread(sprintf("%s/images_right/%s", data_filepath, pdata.right_images{i}));
                limgs{i} = imread(sprintf("%s/images_left/%s", data_filepath, pdata.left_images{i}));
            end
            obj.posedata = pdata;
            obj.rightimgs = rimgs;
            obj.leftimgs = limgs;
            obj.n = n;
            
            obj.max_delta = 0.003;
            obj.max_ransac_dist = 0.15;
            obj.tol = 1e-3;
            
            % z range of supplied terrain
            obj.zrange = [min(obj.terrain.height_grid, [], 'all'), max(obj.terrain.height_grid, [], 'all')];
            
            % space allocation
            obj.points = cell(n, 1);
            obj.pointcolors = cell(n, 1);
            obj.pimages = cell(n, 3);
            obj.nfeatures = zeros(n, 2);
            obj.nmatches = zeros(n, 1);
            obj.ninliers = zeros(n, 1);
            obj.impoints = cell(n, 2); % x0, x1 for each input
        end
        
        %% Algorithm Steps
        
        % Get processed images returns the ith pair of images 
        % as grayscale undistorted images as well as the undistored color
        % image point color extraction.
        function obj = processImages(obj, i)
            img0 = double(obj.leftimgs{i}) / 255; %normalise
            img1 = double(obj.rightimgs{i}) / 255;    
            
            % remove camera distortion
            img0 = undistortImage(img0, obj.parameters.CameraParameters1);
            img1 = undistortImage(img1, obj.parameters.CameraParameters2);
            
            img0color = StereoVision.minowski(img0);

            obj.pimages(i, :) = {rgb2gray(img0), img1, imgaussfilt(img0color, 9)};
        end
        
        % Finds a set of matched features given a pair of input images
        function [x0, x1, fcount, mcount] = extractMatchedFeatures(obj, i)
            img0 = obj.pimages{i, 1};
            img1 = obj.pimages{i, 2};
            
            % extraction using surf detection
            sp0 = detectSURFFeatures(img0);
            sp1 = detectSURFFeatures(img1);
            fcount = [sp0.Count, sp1.Count];
            
            % Match features
            [f0,fp0] = extractFeatures(img0, sp0);
            [f1,fp1] = extractFeatures(img1, sp1);
            [ipairs, ~] = matchFeatures(f0, f1);
            mfp0 = fp0(ipairs(:, 1));
            mfp1 = fp1(ipairs(:, 2));
            
            % screen points of matched features (x, y, 1)
            mcount = mfp0.Count;
            x0 = cat(2, mfp0.Location, ones(mcount, 1));
            x1 = cat(2, mfp1.Location, ones(mcount, 1));
        end
        
        % Given a set of matched features, finds the set of feature point pairs
        % for which the deviation calculated using the fundamental matrix
        % is less than std_max std from 0.
        function [lx0, lx1] = getInlierPointPairs(obj, x0, x1) 
            % delta detween points calculated using fundamental matrix
            F = obj.parameters.FundamentalMatrix;
            delta = x1 * F * (x0');
            delta = delta(logical(eye(length(x0)))); % extract diagonal
            
            % we will remove pairs for which the delta is more than std_max
            % deviation from 0
            inlier = abs(delta) < obj.max_delta;
            lx0 = x0(inlier, :);
            lx1 = x1(inlier, :);
        end
        
        % Given a set of matched feature points computes the location of
        % each feature in 3D space with respect to the first camera
        function p_wrt_w = triangulatePointCloud(obj, i, x0, x1)
            p_wrt_w = [];
            [np, ~] = size(x0);
            if np > 0
                params = obj.parameters;
                f0 = [params.CameraParameters1.FocalLength, 1];
                p0 = [params.CameraParameters1.PrincipalPoint, 0];
                f1 = [params.CameraParameters2.FocalLength, 1];
                p1 = [params.CameraParameters2.PrincipalPoint, 0];

                t = params.TranslationOfCamera2';
                Rc2 = params.RotationOfCamera2;

                % Solving equations on week 5 lecture slide 43 for all inlier
                % matching feature points
                Rt = repmat((Rc2') * t, 1, np);

                v0 = (x0 - p0) ./ f0;
                r = v0(:, 1).^2 + v0(:, 2).^2 + v0(:, 3).^3;
                v0 = (v0 ./ r)';

                v1 = (x1 - p1) ./ f1;
                r = v1(:, 1).^2 + v1(:, 2).^2 + v1(:, 3).^3;
                v1 = v1 ./ r;
                v1 = (Rc2') * v1';

                T1 = cross(-Rt, v1);
                T2 = cross(v0, v1);
                T3 = T2(1, :).^2 + T2(2, :).^2 + T2(3, :).^2;
                d0 = dot(T1, T2) ./ T3;

                T4 = cross(Rt, v0);
                T5 = cross(v1, v0);
                T6 = T5(1, :).^2 + T5(2, :).^2 + T5(3, :).^2;
                d1 = dot(T4, T5) ./ T6;

                p_wrt_c1 = (1/2) * (d0 .* v0 + d1 .* v1 - Rt);

                Rc1 = obj.posedata.R(:, :, i);
                tc1 = obj.posedata.t(:, i);

                p_wrt_w = Rc1' * (p_wrt_c1 - tc1);
                p_wrt_w(3, :) = p_wrt_w(3, :) * -1; % z reflection
                p_wrt_w = p_wrt_w';
            end
        end
        
        function pc = filterPointCloud(obj) 
            nempty = ~cellfun(@isempty,obj.points);
            pc = pointCloud(cell2mat(obj.points(nempty)), 'Color', cell2mat(obj.pointcolors(nempty)));
%             [~, idx] = pcfitplane(pc, obj.max_ransac_dist);
%              pc = select(pc, idx);
        end
        
        %% Algorithm Methods
        % Computes the point cloud for the ith input pair, information from
        % each step will be stored
        function obj = computePointCloud(obj, i)
            fprintf("%i ", i);
            
            % process images
            obj = obj.processImages(i);
            
            % extract matching features
            [x0, x1, obj.nfeatures(i, :), obj.nmatches(i)] = obj.extractMatchedFeatures(i);
    
            % get inlier points
            [lx0,lx1] = obj.getInlierPointPairs(x0, x1);
            obj.impoints(i, :) = {lx0, lx1};
            obj.ninliers(i) = length(lx0);
            
            % compute point cloud
            p_wrt_w = obj.triangulatePointCloud(i, lx0, lx1);
            obj.points{i} = p_wrt_w;
            obj.pointcolors{i} = StereoVision.getColorsAt(lx0, obj.pimages{i, 3});

%             fprintf(" done.\n");
        end
        
        % Computes the point cloud for every input pair
        function obj = computePointCloudAll(obj)
            for i = 1:obj.n
                obj = obj.computePointCloud(i); 
            end
            fprintf(" done.\n");
            obj.pointcloud = obj.filterPointCloud();
        end
        
       
        
        %% Plot Methods
        function plotPointCloud(obj)
            x = flip(obj.terrain.X);
            mesh(x, obj.terrain.Y,obj.terrain.height_grid);
            pc = obj.pointcloud;
            hold on;
            pcshow(pc, 'MarkerSize', 75);
        end
        
        function plotInputPair(obj, i)
            imgc = cat(2, obj.pimages{i, 1} , obj.pimages{i, 2});   
            imshow(imgc);
        end
        
        function plotFeaturePoints(obj, i)
            x0 = obj.impoints{i, 1};
            x1 = obj.impoints{i, 2};
            p = obj.points{i};
            
            [~, w, ~] = size(obj.pimages{i, 1});
            x1(:, 1) = x1(:, 1) + w;
            
            % make color map orange - blue
            zr = obj.zrange;
            cr = 0.7;
            z = p(:, 3);
            z_n = (1 - cr) / 2 + cr * (z - zr(1)) / (zr(2) - zr(1));
            z_n(z_n < 0) = 0;
            z_n(z_n > 1) = 1;
            z_c = hsv2rgb(cat(2, z_n, ones(length(z_n), 1), ones(length(z_n), 1)));
            
            for i = 1:length(x0)
                hold on;
                plot([x0(i, 1), x1(i, 1)], [x0(i, 2), x1(i, 2)], '.', 'Color', z_c(i, :));
            end
        end
        
        %% Evaluation Methods
        function featureEvaluation(obj)
            nm = obj.nmatches;
            nf = obj.nfeatures;
            nfs = [mean(nf); std(nf)];
            
            rj = (nm - obj.ninliers);
            
            fprintf("\nfeature evaluation:");
            fprintf("\n\tfeatures found:\n\t\tleft %.f [%.f]\n\t\tright %.f [%.f]", nfs(:, 1), nfs(:, 2));
            fprintf("\n\tmatches found:\n\t\t%.f [%.f]", mean(nm), std(nm));
            fprintf("\n\trejected:\n\t\t%.f [%.f]\n", mean(rj), std(rj));
        end
        
   
        function ep = pointCloudEvaluation(obj)
            t = obj.tol;
            ap = cell2mat(obj.points(~cellfun(@isempty, obj.points)));
            
            % Area of entire point cloud is the number of unique x y pairs
            a1 = length(unique(round(ap(:, 1:2)/t), 'rows')) * (t^2);
            
            % Interpolate the selected points onto the terrain using cubic
            % method
            pc = obj.pointcloud.Location;
            x = flip(obj.terrain.X);
            iz = interp2(x, obj.terrain.Y, obj.terrain.height_grid, pc(:, 1), pc(:, 2), 'cubic');
            
            % Remove points not above the terrain
            nonnan = ~isnan(iz);
            iz = iz(nonnan);
            pc_nn = pc(nonnan, :);
            
            % Area of valid selected point cloud 
            a2 = length(unique(round(pc_nn(:, 1:2) / t), 'rows')) * (t^2);
            
            % compute residual error
            z_resids = pc_nn(:, 3) - iz;
            zr_std = sqrt(sum(z_resids.^2)/(length(z_resids) - 2));
            
            fprintf("\nterrain evaluation:\n\ttotal point area %.1fcm^2\n\tselected point area %.1fcm^2", a1*1e4, a2*1e4);
            fprintf("\n\tz height residual error %.3f\n", zr_std);
            
            ep = [a2*1e4, zr_std];
        end
        
    end
    
    methods (Static)
        %% Static Algorithm Steps
        
        % Given a point cloud and the feature point pairs it was calculated
        % from returns the indecies of all points that where not rejected. 
        function idxs = getFinalInlierIndecies(pc, x0, x1)
            idxs = logical(ones(length(pc), 1));
        end
    
        % Given the rgb image, returns a grayscale image that will be used
        % to find features.
        function rgb = minowski(img, p)
            if ~exist("p", "var"), p = 9; end
            
            % kwoski gray world
            img = double(img)/255;
            [h, w, ~] = size(img);
            rgb = zeros(h, w, 3);
            for i = 1:3, rgb(:, :, i) = img(:, :, i) / (sum(img(:,:,i).^p, 'all')/(h*w)).^(1/p); end

        end
    
        %% Other Helpful methods
        function colors = getColorsAt(xy, img)
            colors = zeros(0, 3);
            
            if ~isempty(xy)
                r = img(:, :, 1);
                g = img(:, :, 2);
                b = img(:, :, 3);

                sz = size(r);

                x = round(xy(:, 1));
                y = round(xy(:, 2));

                r = r(sub2ind(sz, y, x));
                g = g(sub2ind(sz, y, x));
                b = b(sub2ind(sz, y, x));
           
                colors = cat(2, r, g, b);
            end
        end
    end
end

