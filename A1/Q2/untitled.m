regions = [
    400, 456, 1;
    112, 466, 4;
    509, 566, 5;
    559, 495, 15;
    354, 612, 6;
    59,  357, 7;
    187, 554, 8;
    243, 554, 9;
    771, 525, 10;
    466, 333, 16;
    183, 659, 12;
    289, 412, 13;
    170, 215, 14;
    613, 343, 17;
    722, 124, 2;
    420, 597, 3
 ]

bgrow = false;
bgimg = false;
for i = 1:16
    r = regions(i, :);
    img = results{r(3)}.image(r(2):(r(2)+49), r(1):(r(1)+49), :);
    if ~bgimg
       bgimg = img; 
    else
       bgimg = cat(2, bgimg, img);
    end
    
    if mod(i, 4) == 0
        if ~bgrow
            bgrow = bgimg;
        else
            bgrow = cat(1, bgrow, bgimg);
        end
        bgimg = false;
    end
end
clf;
imwrite(bgrow, "figs/bgpx.jpg");