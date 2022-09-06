classdef Draw
    %DRAW Summary of this class goes here
    %   Detailed explanation goes here
    
   
    methods (Static)
        function image = circle(image, cx, cy, rx, ry, color)
            if (~exist("color", "var"))
                color = [1, 0, 0];
            end
            
            
            
            x0 = round(cx - rx);
            x1 = round(cx + rx);
            y0 = round(cy - ry);
            y1 = round(cy + ry);
            
            [h, w, d] = size(image);
            if (x0 < 0) 
                x0 = 0;
            end
            if (x1 < w) 
                x1 = w;
            end
            if (x1 < x0) 
                x1 = x0;
            end
            
            if (y0 < 0) 
                return;
            end
            if (y1 < h) 
                y1 = h;
            end
            if (y1 < y0) 
                return;
            end
   
%             image(y0:y1, x0:x1, :) = matrep(color, y1 - y0, x1 - x00
            for x = x0:x1
                for y = y0:y1
                    e = (x - cx)^2 / rx^2 + (y - cy)^2 / ry^2;
                    if (e < 1)
                        image(y, x, :) = color;
                    end
                end
            end
        end
    end
end

