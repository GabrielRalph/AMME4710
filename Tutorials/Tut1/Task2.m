% Tutorial 1.2
im1 = imread("./chess/fish001.jpg");
im2 = imread("./chess/fish002.png");
im3 = imread("./chess/underwater001.png");

subplot(2,2,1);
imshow(im1);
subplot(2, 2, 2);
sats = [
    [0.01, 0.7, 0]; % Red
    [0.01, 0.7, 0]; % Green
    [0.01, 0.7, 0]  % Blue
]
imshow(fixUnderwater(im1, sats));

% subplot(2, 2, 2);
% imshow(fixUnderwater(im1, 0.1, 0.9));
% 
% subplot(2, 2, 3);
% imshow(fixUnderwater(im1, 0.2, 0.8));
% 
% subplot(2, 2, 4);
% imshow(fixUnderwater(im1, 0.3, 0.7));