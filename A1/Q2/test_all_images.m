clear;
clc;

% Get image names from directory
directory  = "lego_brick_images/";
image_query = join([directory, "*.jpg"], "");
files = dir(image_query);

% solve algorithm on all images in the directory
n = length(files);
results = cell(n, 1);
times = zeros(n, 6);
for i = 1:n
    image = imread(append(directory, files(i).name));
    
    results{i} = findLegoBricks(image);
    times(i, :) = results{i}.runtimes;
end

avgtimes = mean(times);
avgtime = round(sum(avgtimes) * 1000);
avgtimes = 100 * avgtimes / sum(avgtimes);

 fprintf("solver took %.0fms on average (max freq %.0fHz)\nfiltering: %.0f%%\ngrayscale: %.0f%%\nedge morthology: %.0f%%\nfind conncomps: %.0f%%\nfilter conncomps: %.0f%%\nget colours: %0.f%%\n", avgtime, 1000/avgtime, avgtimes);
%% Display validated results
clf;
load("lego_brick_images/legobrick_validation");
n = length(results);

s = ceil(sqrt(n));
ovdata = 0;
for i = 1:n
    result = results{i};
    
    subplot(s, s, i);
    vdata = result.plotResults(validation_data(i), false);
    if ~ovdata
        ovdata = vdata;
    else
        ovdata = cat(1, ovdata, vdata);
    end
end

avg = mean(ovdata);
dev = std(ovdata);
fprintf("avg center delta %.1fpx (std = %.1fpx), avg size delta %.1f%% (std = %.1f%%)\n", avg(1), dev(1), avg(2), dev(2));



