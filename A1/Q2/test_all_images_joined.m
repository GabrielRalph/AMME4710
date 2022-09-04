clear;
clc;

% Get image names from directory
directory  = "lego_brick_images_joined/";
image_query = join([directory, "*.jpg"], "");
files = dir(image_query);
% files = files(4:8);
% solve algorithm on all images in the directory
n = length(files);
results = cell(n, 1);
run_sum = 0;
for i = 1:n
    image = imread(append(directory, files(i).name));
    tic;
    results{i} = findLegoBricksJoined(image);
    run_sum = run_sum + toc;
end

fprintf("solver took %fms on average (max freq %dHz)\n", round(1000 * run_sum/n), round(1/(run_sum/n)));

%% Display validated results
clf;
load(join([directory, "/legobrickjoined_validation"], ""));
dresults = results; %(1:4);
n = length(dresults);

s = ceil(sqrt(n));
tdc = 0;
tds = 0;
for i = 1:n
    result = dresults{i};

    subplot(s, s, i);
    [dc, ds] = result.plotResults(validation_data_joined(i));
    tdc = tdc + dc;
    tds = tds + ds;
end
fprintf("avg dc %ipx, avg ds %.1f%%\n\n", round(tdc / n), (tds/n));

