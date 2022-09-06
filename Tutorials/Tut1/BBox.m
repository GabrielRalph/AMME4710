classdef BBox
    %BBOX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        min (1,2) double
        max (1,2) double
        id;
    end
    
    properties (Access = private)
        is_set;
    end
    
    
    methods
        function obj = BBox() 
            obj.is_set = 0;
        end
        
        function value = get.is_set(obj)
            value = obj.is_set;
        end
  
        function obj = addPixelIndecies(obj, pidxs, height)
            for i = 1:length(pidxs)
                pidx = pidxs(i); 
                obj = obj.add([floor(pidx / height) + 1, mod(pidx, height) + 1]);
            end
        end
        
        function obj = add(obj, vec)
            if (class(vec) == "BBox")
                obj = obj.add(vec.min);
                obj = obj.add(vec.max);
            elseif (~obj.is_set)
                obj.min = vec;
                obj.max = vec;
                obj.is_set = 1;
            else 
                if vec(1) < obj.min(1)
                    obj.min(1) = vec(1);
                elseif (vec(1) > obj.max(1))
                    obj.max(1) = vec(1);
                end
                
                if vec(2) < obj.min(2)
                    obj.min(2) = vec(2);
                elseif (vec(2) > obj.max(2))
                    obj.max(2) = vec(2);
                end
            end 
        end
        
        function dist = distance(obj, bbox)
            if (~obj.is_set|| ~bbox.is_set)
                dist = 0;
            else
                oMinX = obj.min(1);
                oMinY = obj.min(2);
                oMaxX = obj.max(1);
                oMaxY = obj.max(2);
                bMinX = bbox.min(1);
                bMinY = bbox.min(2);
                bMaxX = bbox.max(1);
                bMaxY = bbox.max(2);
               

                dx = 0;
                dy = 0;
                if (bMinX > oMaxX)
                   dx = bMinX - oMaxX;
                elseif (bMaxX < oMinX)
                   dx = oMinX - bMaxX;
                end

                if (bMinY > oMaxY)
                   dy = bMinY - oMaxY;
                elseif (bMaxY < oMinY)
                   dy = oMinY - bMaxY;
                end

                dist = sqrt(dx^2 + dy^2);
            end
        end
        
        function img = draw(obj, img, th, color)
            if (~exist("color", "var"))
                color = uint8([255, 0, 0]);
            end
            
            
            minX = obj.min(1);
            minY = obj.min(2);
            maxX = obj.max(1);
            maxY = obj.max(2);
            
       
            th = th - 1;
            img(minY:(minY + th), minX:maxX, :) = colors([th + 1, maxX - minX + 1], color);
            img((maxY - th):maxY, minX:maxX, :) = colors([th + 1, maxX - minX + 1], color);
            img(minY:maxY, minX:(minX + th), :) = colors([maxY - minY + 1, th + 1], color);
            img(minY:maxY, (maxX - th):maxX, :) = colors([maxY - minY + 1, th + 1], color);
        end
    end
    
    methods(Static)
        
        % Find connected components as bounding boxes
        function bboxes = findBWConCompBBoxes(BW, size_threshold)
            if ~exist('size_threshold','var')
               size_threshold = 9;% pixels
            end
             
             % Find connected components
            CCs = bwconncomp(BW);

            % Find all BBoxes for each component above the threshold size
            [height, ~] = size(BW);
            bboxes = {};
            for cell = CCs.PixelIdxList
                component = cell{1, 1};
                n = length(component);
                if n > size_threshold
                    boxa = BBox.fromPixelIndecies(component, height);
                    bboxes{end+1} = boxa;
                end
            end
        end
        
        % Merge bboxes that are no closer than the given threshold distance.
        function merged = mergeBBoxesByDistance(bboxes, threshold)
            nb = length(bboxes);
            merged = {};
            
            unmerged = bboxes;
            
            % Whilst their ar still unmerged boxes
            while (length(unmerged) > 1)
                
                % Select the first box
                boxa = unmerged{1};

                % For every other box
                n_unmerged = {};
                for j = 2:length(unmerged)
                    boxb = unmerged{j};
                    
                    % If the distance between the boxes is less than the
                    % given threshold then the boxes are merged
                    dist = boxa.distance(boxb)
                    if (dist < threshold)
                        boxa = boxa.add(boxb);
                    % otherwise the box is added to the next unmerged list
                    else 
                        n_unmerged{end+1} = boxb;
                    end
                end
                
                % Add the selected box to the merged boxes list
                merged{end+1} = boxa;
                unmerged = n_unmerged;
            end
            
            if (length(unmerged) == 1) 
                merged{end+1} = unmerged{1};
            end
        end
        
        function bbox = fromPixelIndecies(pidxs, width)
           bbox = BBox();
           bbox = bbox.addPixelIndecies(pidxs, width);
       end
    end
end

