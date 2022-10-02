cat = imread("download.jpeg");

% incv = 255 - cat;
% imshow(cat);
hsv = rgb2hsv(cat);
hsv(:, :, 2) = 1;
hsv(:, :, 3) = 1;
imshowpair(hsv2rgb(hsv), cat, "montage");

% for i = 1:100
%     br = rgb2hsv(cat);
%     br(:, :, 1) = mod(br(:, :, 1) + i/100, 1);
% 
%     imshowpair(cat, hsv2rgb(br), "montage");
%     pause(0.1);
% end

p1 = [3, 96/2];
p2 = [100-3, 96/2];
p3 = [50, 100-3];
a1 = 96 * 6;
a2 = a1;
a3 = 100 * 6;
pc = (p1 * a1 + p2 * a2 + p3 * a3) / (a1 + a2 + a3)
