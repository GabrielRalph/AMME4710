% Task 4 Spot the Difference
images = imread("chess/spot_the_difference.png");



[height, twidth, dim] = size(images);
width = twidth / 2;

imgA = images(:, 1:width, :);
imgB = images(:, (width + 1):twidth, :);



diffs = spotTheDifferences(imgA, imgB);
n = length(diffs);
fprintf("%i differences\n", n);

rows = floor(sqrt(n * 2));
cols = floor(2 * n / rows) + 1;
rows = rows + 2;
mid = round(cols/2);
f = subplot(rows, cols, 1:mid)
imshow(images);
pos = f.Position;
% s = pos(1:2) - pos(3:4)
pos = pos .* [1, 1, 1.1, 1.1];
f.Position = pos - pos .* [0.04, 0.04 0 0];


for i = 1:n
    box = diffs{i};
    
    diffA = imgA(box.min(2):box.max(2), box.min(1):box.max(1), :);
    diffB = imgB(box.min(2):box.max(2), box.min(1):box.max(1), :);
    
    f = subplot(rows, cols, cols + i * 2 - 1);
    imshow(diffA);
    f.Position = f.Position + [0.01 0 0 0];
    
    f = subplot(rows, cols, cols + i * 2);
    imshow(diffB);
    f.Position = f.Position - [0.01 0 0 0];
    
    
    imgA = box.draw(imgA, 3, [255, 0, 100]);
    imgB = box.draw(imgB, 3, [255, 0, 100]);
end
subplot(rows, cols, (mid+1):cols)

imshowpair(imgA, imgB, "montage");



function diffs = spotTheDifferences(imgA, imgB, level, size_threshold, merge_threshold)
     % Default Parameters
     if ~exist('level','var')
       level = 20 / 255;   % luminosity
     end
     if ~exist('size_threshold','var')
       size_threshold = 20;% pixels
     end
     if ~exist('merge_threshold','var')
       merge_threshold = 20;% pixels
     end

    % Compute the differences between the images then binarize them to 
    % black and white images.
    imgDiffA = imbinarize(rgb2gray(imgA - imgB), level);
    imgDiffB = imbinarize(rgb2gray(imgB - imgA), level);
    imgDiff = imgDiffA + imgDiffB;
    
    % Find the bounding boxes of all connected components of size (number
    % of pixels) greater than the given size threshold.
    bboxes = BBox.findBWConCompBBoxes(imgDiff, size_threshold);
    
    % Merge all bounding boxes that are no further than the given merge
    % threshold.
    diffs = BBox.mergeBBoxesByDistance(bboxes, merge_threshold);
end