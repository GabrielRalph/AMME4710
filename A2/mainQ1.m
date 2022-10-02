clc;
clear;

data_directory = "stereodata";

% create an instance of the StereoVision algorithm loading relevant data
% from the given directory
%
svision = StereoVision(data_directory);
svision = svision.computePointCloudAll();
%%
clf;
svision.plotPointCloud();
set(gca,'color','w');

%% testing max delta
% max_deltas = linspace(0.0001, 0.05, 20);
% n = length(max_deltas);
% results = ones(n, 3);
% results(:, 1) = max_deltas';
% for i = 1:n
%     svision.max_delta = max_deltas(i);
%     svision = svision.computePointCloudAll();
%     results(i, 2:3) = svision.pointCloudEvaluation();
% end
% plot(results(:, 1), results(:, 2), results(:, 1), results(:, 3));