clear;
clc;

% Get image names from directory
directory  = "lego_brick_images/";
image_query = join([directory, "*.jpg"], "");
files = dir(image_query);

% solve algorithm on all images in the directory
n = length(files);
results = cell(n, 1);
run_sum = 0;
for i = 1:n
    image = imread(append(directory, files(i).name));
    tic;
    results{i} = findLegoBricks(image);
    run_sum = run_sum + toc;
end


fprintf("solver took %fms on average (max freq %dHz)\n", round(1000 * run_sum/n), round(1/(run_sum/n)));
%% Display validated results
clf;
load("lego_brick_images/legobrick_validation");
n = length(results);

s = ceil(sqrt(n));
for i = 1:n
    result = results{i};

    subplot(s, s, i);
    result.plotResults(validation_data(i), false);
end
