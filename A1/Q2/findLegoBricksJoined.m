classdef findLegoBricksJoined
   properties
       image
       height
       width
       
       filtered
       colours
       morthology
       conncomps
       block
       
       edges_from
       edges_to
       
    end
    
    methods
        %% Constructor
        % given images finds all coloured bricks and stores
        % them in itself under the key bricks
        function obj = findLegoBricksJoined(image)
            obj.image = double(image) / 255;
            [obj.height, obj.width, ~] = size(image);
            
            obj = obj.filterImage();
            
            obj = obj.segmentColours([
                300, 15; % red
                15, 42;  % orange
                42, 63;  % yellow
                108, 180;% dark green
                63, 108; % light green
                180, 300 % blue
            ], 0.15, 0.01);
            
            obj = obj.makeMorthology(11, 10);
            
            obj = obj.findConnComps(50, 200);
            
            obj = obj.findJoinedBricks(15, 75, 0.88);
        end
        
        %% Main Algorithm steps
        function obj = filterImage(obj) 
            obj.filtered = lin2rgb(obj.image);
        end
        
        
        function obj = segmentColours(obj, hue_thresh_degs, min_sat, min_val)
            % get hue channel from filtered image
            hsv = rgb2hsv(obj.filtered);
            hue = hsv(:,:,1);
            
            % remove if below min saturation or value
            colored = hsv(:, :, 2) > min_sat & hsv(:, :, 3) > min_val;
            
            % segment by hue thresholds
            n = length(hue_thresh_degs);
            thresh = hue_thresh_degs/360;
            colors = zeros(obj.height, obj.width, n);
            for i = 1:n
                mint = thresh(i, 1);
                maxt = thresh(i, 2);
                if mint > maxt
                    colors(:, :, i) = colored & (hue >= mint | hue < maxt);
                else
                    colors(:, :, i) = colored & (hue >= mint & hue < maxt);
                end
            end
          
            obj.colours = colors;
        end
        
        function obj = makeMorthology(obj, erossion, dilation)
            se1 = strel("disk", erossion);
            se2 = strel("disk", dilation);
            
            edges = imerode(obj.colours, se1);
            edges = imdilate(edges, se2);
            
            obj.morthology = edges;
        end
             
        function obj = findConnComps(obj, min_diag, max_diag)
            CC = bwconncomp(obj.morthology, 4);
            props = regionprops3(CC, "BoundingBox", "Centroid");
            deltas = props{:, "BoundingBox"}(:, 4:5);
            diag = sqrt(deltas(:, 1).^2 + deltas(:, 2).^2);
            obj.conncomps = props(diag > min_diag & diag < max_diag, :);
        end
        
        function obj = findJoinedBricks(obj, min_color_dist, max_color_dist, brick_aspect) 
            cnts = obj.conncomps{:, "Centroid"};
            cnts = sortrows(cnts, 3);
            
            % calculate average distance between colors between points
            dist = sqrt((cnts(:, 1) - cnts(:, 1)').^2 + (cnts(:, 2) - cnts(:, 2)').^2);
            dist = dist ./ (cnts(:, 3)' - cnts(:, 3)); % change in color
            D = (dist > min_color_dist & dist < max_color_dist); % only allow positive distances in range
            
            % find longest chain of points
            filter = findLegoBricksJoined.findLongestChain(D);
            p = cnts(filter, :);
            
            % get the straightest pair of points
            [pa, pb] = findLegoBricksJoined.findBestPair(p);
            
            % get average distance between colors
            dc = norm(p(1, 1:2) - p(end, 1:2)) / (p(end, 3) - p(1, 3));
            
            % get direction vetor of block
            d = pb(1:2) - pa(1:2);
            d = d / norm(d);
            
            % predict start and end block centers from straightest points
            c0 = pa(1:2) - d * dc * (pa(3) - 1);
            c1 = pb(1:2) + d * dc * (6 - pb(3));
            
            % solve the angle of the block
            if d(1) < 0, d = d * -1; end       
            theta = acos( dot(d, [1, 0]) / norm(d) ) * sign(d(2));
            
            % construct a rectangle in complex space
            dx = dc * 3;
            dy = 1i * dc * brick_aspect;
            rect = [-dx - dy, -dx + dy, dx + dy, dx - dy, -dx - dy];
            
            % rotate it by theta
            rect = rect * exp(1i*theta);
            
            % offset by the center
            cm = (c1 + c0) / 2;
            rect = rect + cm(1) + 1i * cm(2);
            
            % store all relavent information about the block
            x = real(rect);
            y = imag(rect);
            outline = cat(2, x', y');
            obj.block.position = [min(x), min(y), max(x) - min(x), max(y) - min(y)];
            obj.block.points = p;
            obj.block.start = c0;
            obj.block.end = c1;
            obj.block.pa = pa;
            obj.block.pb = pb;
            obj.block.center = cm;
            obj.block.angle = theta;
            obj.block.size = max(outline) - min(outline);
            obj.block.outline = outline;
        end
         
        
        function img = getMorthologyImage(obj)
            w = obj.width;
            h = obj.height;
            
            grad = repmat(reshape(linspace(0, 0.8, 6), 1, 1, 6), h, w);
            hue = sum(obj.morthology .* grad, 3);
            value = sum(obj.morthology, 3);
            hsv = cat(3, hue, ones(h, w, 1), value);
            
            img = hsv2rgb(hsv);
        end
        
        function animate(obj, dt, img)
            tf = 0.95;
            tic
            set(img, 'CData', obj.image);
            pause(tf * dt/2);
            
            set(img, 'CData', obj.filtered);
            pause(tf * dt/2);
            
            set(img, 'CData', obj.getMorthologyImage());
            hold on;
            pdata = plot(obj.conncomps{:, "Centroid"}(:, 1), obj.conncomps{:, "Centroid"}(:, 2), "*w");
            pause(tf * dt);
            delete(pdata);
            
            set(img, 'CData', obj.image);
            hold on
            pdata = plot(obj.block.points(:, 1), obj.block.points(:, 2), "*w");
            pause(tf * dt);
            delete(pdata);
            
            hold on
            pdata = [
                plot(obj.block.pa(1), obj.block.pa(2), "*w");
                plot(obj.block.pb(1), obj.block.pb(2), "*w");
                plot(obj.block.outline(:, 1), obj.block.outline(:, 2), "-w", 'LineWidth', 3);
                rectangle('Position', obj.block.position, 'LineWidth', 3, "EdgeColor", "w")
            ];
            pause(4 * dt - toc);
            delete(pdata);
        end
        
        function [cdelta, sdelta] = plotResults(obj, v)
            
            imshow(obj.filtered);
            
            hold on;
   
            b = obj.block;
            
            
            % plot bounding rectangles
%             plot(b.outline(:, 1), b.outline(:, 2), "-r", 'LineWidth', 1.5);
%             rectangle('Position', b.position, 'LineWidth', 1.5);
            
            % plot points of interest
%             sp = b.start;
%             ep = b.end;
            c = obj.conncomps{:, "Centroid"};
            plot(c(:, 1),c(:, 2), "*w");
            plot(b.points(:, 1), b.points(:, 2), "o", 'Color', [0,0,0], "LineWidth", 1.5);
%             plot(sp(:, 1), sp(:, 2), "o", 'Color', [0,0,0]);
%             plot(ep(:, 1), ep(:, 2), "o", 'Color', [0,0,0]);
%             text(sp(1) + 10, sp(2) - 10, "s", 'Color', [1, 1, 1]);
%             text(ep(1) + 10, ep(2) - 10, "e", 'Color', [1, 1, 1]);
%             plot(b.pa(:, 1), b.pa(:, 2), "ow");
%             plot(b.pb(:, 1), b.pb(:, 2), "ow");
            
            
            
            % get the error margins from the validation data and display it
            % in the title
            if exist("v", "var")
                cdelta = norm(b.center - v.center);
                sdelta = 100 * (b.size(1) * b.size(2) / (v.box_size(1)*v.box_size(2)) - 1);
            else
                cdelta = 0;
                sdelta = 0;
            end
%             t1 = sprintf("center delta = %dpx\nsize delta = %.1f%%\n", round(cdelta), sdelta);
%             title(t1);
        end
    end
    
    methods (Static) 
        function picked = findLongestChain(D)
            n = length(D);
            
            % Base case
            S = zeros(n, 1);
            lastpicked = ones(n, 1);
            
            % Solve using solution table for remaining cases
            for i = 2:n
                [pick, j] = max(S(1:(i-1)) + D(1:(i-1), i));
                nopick = S(i - 1);
                S(i) = max(pick, nopick);
                
                if nopick > pick, j = i - 1; end
                lastpicked(i) = j;
            end
            
            % Find points in solution set
            i = n;
            picked = zeros(n, 1);
            while i > 1
                ni = lastpicked(i);
                if S(i) > S(ni)
                    picked(i) = true;
                    picked(ni) = true;
                end
                i = ni;
            end
            picked = logical(picked);
        end
        
        function [pa, pb] = findBestPair(p)
            n = length(p);
            
            % Get deltas between every point and every other point
            dx = p(:, 1)' - p(:, 1);
            dx = reshape(dx(~eye(n)), n - 1, n); % remove diagonal
            dy = p(:, 2)' - p(:, 2);
            dy = reshape(dy(~eye(n)), n - 1, n);
    
            % Get the gradient angles of the deltas and constrain them to
            % the two right quadrants.
            grads = atan2(dy, dx);
            grads = grads - pi * (grads > pi/2);
            grads = grads + pi * (grads < -pi/2);
            
            % sort by standard diviation of the angles to find two points 
            [~, idx] = sort(std(grads));
            
            % pa color < pb color
            if p(idx(1), 3) > p(idx(2), 3)
                pa = p(idx(2), :);
                pb = p(idx(1), :);
            else
                pa = p(idx(1), :);
                pb = p(idx(2), :);
            end
        end
    end
end

