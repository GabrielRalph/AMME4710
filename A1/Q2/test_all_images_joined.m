clear;
clc;

% Get image names from directory
directory  = "lego_brick_images_joined/";
image_query = append(directory, "*.jpg");
files = dir(image_query);

% solve algorithm on all images in the directory
n = length(files);
results = cell(n, 1);
times = zeros(n, 6);
for i = 1:n
    image = imread(append(directory, files(i).name));
    results{i} = findLegoBricksJoined(image);
    times(i, :) = results{i}.runtimes;
end

avgtimes = mean(times);
avgtime = round(sum(avgtimes) * 1000);
avgtimes = 100 * avgtimes / sum(avgtimes);

fprintf("solver took %.0fms on average (max freq %.0fHz)\nfiltering: %.0f%%\nsegmentation: %.0f%%\nedge morthology: %.0f%%\nfind conncomps: %.0f%%\nfind blocks: %.0f%%\n", avgtime, 1000/avgtime, avgtimes(1:5));

%% Display validated results
clf;
load(append(directory, "/legobrickjoined_validation"));
n = length(results);

s = ceil(sqrt(n));
vals = zeros(n, 2);
for i = 1:n
    result = results{i};
    subplot(s, s, i);
    [dc, ds] = result.plotResults(validation_data_joined(i));
    vals(i, :) = [dc, ds];
end

m = mean(vals);
sd = std(vals);
fprintf("avg center delta %.1fpx (std = %.1f), avg delta size %.1f%%(std = %.1f)\n", round(m(1)), sd(1), m(2), sd(2));
