function peice = getPeice(p)
   p = rgb2gray(p);
   [width, height] = size(p);
   
   n = width * height;
   
   res = imhist(p);
   black = res(1);
   white = res(256);
   
   peice = "empty";
   if (white > black + 10) 
   	peice = "white";
   elseif (black > white + 10) 
    peice = "black";
   end 
   
end