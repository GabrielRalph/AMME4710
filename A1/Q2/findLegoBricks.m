classdef findLegoBricks
    properties
       image
       height
       width
       
       filtered
       grayscale
       morthology
       conncomps
       bricks
       
       runtimes
    end
    
    methods
        %% Constructor
        % given images finds all coloured bricks and stores
        % them in itself under the key bricks
        function obj = findLegoBricks(image)
            obj.image = double(image) / 255;
            [obj.height, obj.width, ~] = size(image);
            
            times = zeros(6, 1);
             
            tic;
            obj = obj.makeFiltered();
            times(1) = toc;
            tic;
            obj = obj.makeGrayscale(0.15);
            times(2) = toc;
            tic
            obj = obj.makeEdgeMorthology(1);
            times(3) = toc;
            tic
            obj = obj.findConnComps();
            times(4) = toc;
            tic
            obj = obj.filterConnComps(70, 200, 1.4, 0.15);
            times(5) = toc;
            tic
            obj = obj.findBricks(0.35, 0.2);
            times(6) = toc;
            
            obj.runtimes = times;
        end

        %% Main algorithm steps
        
        % makeFiltered filters the image using a gaussian filt
        function obj = makeFiltered(obj)
            obj.filtered = imgaussfilt(obj.image, 9);
        end
        
        % makeGrayscale creates a grayscale image based on how colourfull 
        % a pixel is in the filtered image
        function obj = makeGrayscale(obj, min_ts)
            color_rad = findLegoBricks.makeColorRad(obj.filtered);
            
            % set all pixels with values less than 0.15 to 0;
            obj.grayscale = color_rad .* (color_rad > min_ts);
        end
        
        % makeEdgeMorthology creates an edge morthology using the 
        % grayscale image
        function obj = makeEdgeMorthology(obj, open_rad)
            % perform canny edge detection on grayscale
            morth = edge(obj.grayscale, "Canny");
            
            % open the morthology
            se = strel("disk", open_rad);
            morth = imdilate(morth, se);
            morth = imerode(morth, se);
            
            obj.morthology = morth;
        end 
        
        % findConnComps finds all connected components in the morthology 
        % image and stores them in a cell struct array with fields:
        % position, aspectRatio, minDim, maxDim, pidxs
        function obj = findConnComps(obj)
            CC = bwconncomp(obj.morthology);
            pidxs_list = CC.PixelIdxList;
            n = length(pidxs_list);
        
            % store each components bounding box position and other
            % useful information
            comps = cell(n, 1);
            for i = 1:length(pidxs_list)
                pidxs = pidxs_list{i};
                [x, y, dx, dy] = obj.getPixelIdxsPosition(pidxs);
                minDim = min(dx, dy);
                maxDim = max(dx, dy);
                ratio = maxDim / minDim;
                
                % store relevant information
                comps{i}.position = [x, y, dx, dy];
                comps{i}.pixels = pidxs;
                comps{i}.minDim = minDim;
                comps{i}.maxDim = maxDim;
                comps{i}.aspectRatio = ratio;
            end
            
            obj.conncomps = comps;
        end
      
        % filterConnComps removes all components that do not fit within a
        % given size and aspect ratio then removes the smaller components
        % of all overlapping components such that no component shares
        % more than a given percentage of pixels (max_overlap) with another
        % component.
        function obj = filterConnComps(obj, min_size, max_size, max_aspect, max_overlap)
            % filter components by size
            right_size = cellfun(@(c) c.minDim > min_size & c.maxDim < max_size & c.aspectRatio < max_aspect, obj.conncomps, 'UniformOutput',false);
            right_size = logical(cell2mat(right_size));
            comps = obj.conncomps(right_size);
            
            n = length(comps);
    
            % remove overlapping components
            merged = zeros(n, 1);
            for i = 1:(n - 1)
                if ~merged(i)
                    compi = comps{i};
                    
                    % Check for any merges with following components
                    for j = (i + 1):n
                        compj = comps{j};
        
                        % get percentage of overlapping pixels
                        idxsi = obj.getPixelIdxsOfBoundingBox(compi);
                        idxsj = obj.getPixelIdxsOfBoundingBox(compj);
                        ni = length(idxsi);
                        nj = length(idxsj);
                        overlap = length(intersect(idxsi, idxsj)) / min(ni, nj);

                        % if an overlap occurs the largerst box will be
                        % choosen to remain in the set
                        if overlap > max_overlap
                            if nj > ni
                                merged(i) = 1;
                                compi = compj;
                            else
                                merged(j) = 1;
                            end
                        end
                    end
                end
            end
            
            obj.conncomps = comps(logical(~merged));
        end
       
        % findBricks finds coloured bricks from the list of connected
        % components stores them in a cell struct array with fields:             
        % center, size,  hue, color, position and image
        function obj = findBricks(obj, saturation_ts, value_ts)
            comps = obj.conncomps;
            n = length(comps);
            brcks = cell(n, 1);
            for i = 1:n
                p = comps{i}.position;
                x2 = p(1) + p(3);
                y2 = p(2) + p(4);
                
                % Get the block image
                rgb = obj.filtered(p(2):y2, p(1):x2, :);
                
                % Get most frequent color (hue 0-360) of pixels with saturation
                % and value greater than thresholds
                hsv = rgb2hsv(rgb);
                hue = hsv(:, :, 1);
                filter = (hsv(:,:,2) > saturation_ts) & (hsv(:,:,3) > value_ts);
                hue = mode(round(360 * hue(filter)));
                
                if ~isnan(hue)
                    % Determine color name from hue
                    if hue < 17 || hue > 300
                        color = "red";
                    elseif hue < 42
                        color = "orange";
                    elseif hue < 63
                        color = "yellow";
                    elseif hue < 108
                        color = "lightgreen";
                    elseif hue < 180
                        color = "darkgreen";
                    else
                        color = "blue";
                    end

                    % Store relavent information in struct
                    brcks{i}.center = [p(1), p(2)] + [p(3), p(4)] / 2;
                    brcks{i}.size = [p(3), p(4)];
                    brcks{i}.position = p;
                    brcks{i}.image = hsv2rgb(hsv);
                    brcks{i}.hue = hue;
                    brcks{i}.color = color;
                end
            end
            
            obj.bricks = brcks(~cellfun('isempty', brcks));
        end

        
        %% Helper and getter methods
        
        % getPicelIdxsOfBoundingBox, gets the pixel indecies contained in 
        % the bounding box of a given component
        function pixel_idxs = getPixelIdxsOfBoundingBox(obj, comp)
         
            % Compute pixel indecies of min and max points
            h = obj.height;
            p = comp.position;
            x2 = p(1) + p(3);
            y2 = p(2) + p(4);
            
            ci0 = (p(2) - 1) * h + p(1);
            ci1 = (y2 - 1) * h + x2;

            % all pixels between min and max pixels
            all_pixel_idxs = ci0:ci1;

            % remove pixels outside of the x bounds
            xs = mod(all_pixel_idxs - 1, h);
            pixel_idxs = all_pixel_idxs((xs > (p(1) - 1)) & (xs < (x2 - 1)));
        end
         
        % getPixelIdxsPosition, gets the position from the bounding box of 
        % a list of pixel indecies
        function [x, y, dx, dy] = getPixelIdxsPosition(obj, pidxs)
          
            ps = pidxs - 1;
            h = obj.height;
            locations = [floor(ps/h) + 1, mod(ps, h) + 1];
            if length(pidxs) < 2
                c0 = locations;
                c1 = c0;
            else 
               c0 = min(locations);
               c1 = max(locations);
            end
            
     
            delta = c1 - c0;
            dx = delta(1);
            dy = delta(2);
            x = c0(1);
            y = c0(2);
        end
        
        function [h, w] = getSize(obj)
            w = obj.width;
            h = obj.height;
        end

        %% Validation and display methods
        % Plots bricks as rectangles with text color labels if validation
        % data is provide then wrong color guesses will be shown in red
        function vdata = plotResults(obj, validation, show_stats)
            vdata = 0;
            validate = exist("validation", "var");
            if ~exist("show_stats", "var"), show_stats = false; end
            if validate, vdata = obj.validateBricks(validation); end
            
             imshow(obj.image);
             hold on
             
           
            brcks = obj.bricks;
            for i = 1:length(brcks)
                ecolor = 'w';
                
                if validate && vdata(i, 3); ecolor = 'r'; end

                rectangle('Position',brcks{i}.position,'LineWidth',2, 'EdgeColor', ecolor);
                p = brcks{i}.center;
                c = brcks{i}.size;
                name = brcks{i}.color;
                
                if validate && show_stats
                    text(p(1) + c(1)/2 + 8, p(2), sprintf("dc: %dpx\nds: %d%%", vdata(i,1), vdata(i,2)), 'Color', 'white');
                    name = sprintf("%s [%.0f]",brcks{i}.color,brcks{i}.hue);
                end
                color = hsv2rgb([brcks{i}.hue/360, 1, 1]);
                text(p(1), p(2) - c(2)/2 - 20, name, 'Color', color, 'HorizontalAlignment', 'center', 'FontSize',10);
            end
        end
        
        % Finds the closest bricks to the actual bricks position and maps
        % the information accordingly
        function vdata = validateBricks(obj, validation)
            vcenters = validation.center;
            brcks = obj.bricks;
            bcenters = cell2mat(cellfun(@(x) x.center, brcks, 'UniformOutput', false));

            [k, dist] = dsearchn(bcenters, vcenters);
            vdata = ones(length(brcks), 3);
            for i = 1:length(k)
                idx = k(i);
                block = brcks{idx};
                vdata(idx, 1) = round(dist(i));
                vsize = validation.box_size(i, :);
                vdata(k(i), 2) = round(100 * block.size(1) * block.size(2) / (vsize(1)*vsize(2))) - 100;
                vdata(k(i), 3) = ~strcmp(validation.colours{i}, block.color);
                vdata(idx, 4) = 0;
            end
        end
    end
    
    
    methods (Static)
        function color_rad = makeColorRad(image)
            % convert the hsv color space
            f_hsv = rgb2hsv(image);

            % for a given pixel k in hsv space with color (h_k, s_k, v_k) 
            % we will take the distance between the points (s_k, v_k) and
            % (1,1) to be the color radius of a given pixel
            f_color_rad = 1 - sqrt( (1 - f_hsv(:, :, 2)).^2 + (1 - f_hsv(:, :, 3)).^2 );

            % get the range of color radis
            rad_min = min(f_color_rad, [], "all");
            rad_max = max(f_color_rad, [], "all");
            if (rad_min < 0)
                rad_min = 0;
            end

            % the output grayscale will be relative to color radis scaled
            % to the range
            color_rad = imadjust(f_color_rad, [rad_min, rad_max]);
        end
    end
end

