clear;
clc;

%% Solve all joined bricks
files = dir("lego_brick_images_joined/*.jpg");
n = length(files);
results1 = cell(n, 1);
for i = 1:n
    image = imread(append("lego_brick_images_joined/", files(i).name));
    results1{i} = findLegoBricksJoined(image);
end

%% Solve all normal bricks
files = dir("lego_brick_images/*.jpg");
n = length(files);
results2 = cell(n, 1);
for i = 1:n
    image = imread(append("lego_brick_images/", files(i).name));
    results2{i} = findLegoBricks(image);
end


%%
bbm = 158;
sf = 1;

allresults = cat(1, results1, results2);
n = length(allresults);
allresults = allresults(randperm(n));
img = imshow(allresults{1}.image);
pause(2)
for i = 1:n
    allresults{i}.animate(60 / bbm, img);
end
%%
clf;
og = cat(2, results1{3}.image, results1{12}.image);
f = cat(2, results1{3}.filtered, results1{12}.filtered);
imwrite(cat(1, og, f), "filtering.jpg");