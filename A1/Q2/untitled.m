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
    420, 597, 3;
    772, 155, 11;
    821, 105, 7;
    821, 70, 4;
    84, 613, 14;
    878, 351, 6;
    81, 612, 2;
    500, 500, 5;
    823, 460, 8;
    901, 636, 13;
 ]


%%
bgrow = false;
bgimg = false;
for i = 1:25
    r = regions(i, :);
    img = results{r(3)}.filtered(r(2):(r(2)+49), r(1):(r(1)+49), :);
    if ~bgimg
       bgimg = img; 
    else
       bgimg = cat(2, bgimg, img);
    end
    
    if mod(i, 5) == 0
        if ~bgrow
            bgrow = bgimg;
        else
            bgrow = cat(1, bgrow, bgimg);
        end
        bgimg = false;
    end
end
% imwrite(bgrow, "figs/filt_bgpx.jpg");
%%
clf;
hsv = rgb2hsv(bgrow);
sv = round(squeeze(reshape(hsv(:, :, 2:3), [], 1, 2)) * 100);
[c, ia, ic] = unique(sv, 'rows');
bg = cat(3, ones(100), ones(100, 1) * (1:100), (1:100)' * ones(1, 100))/100;
imshow(hsv2rgb(bg));
hold on

for i = 1:length(c)
    count = sqrt(length(ic(ic == i)));
    f = count/45;
    r = 0.5 + f;
    rectangle('Position', [c(i, 1) - r/2, c(i, 2) - r/2, r, r], 'FaceColor', hsv2rgb([0.3, f, 1]), 'Curvature', [1, 1], 'LineStyle', 'none');
end

rectangle('Position', [15, 15, 200 - 30, 200 - 30], 'Curvature', [1, 1], 'EdgeColor', [0.5,0.6,1], 'LineWidth', 3);