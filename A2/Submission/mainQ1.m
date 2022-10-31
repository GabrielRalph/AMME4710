clc;
clear;
data_directory = "/stereodata";
svision = StereoVision(data_directory);

%% Revision 1
svision.revision = 1;
svision.max_delta = 0.5;
svision.featureDetector = @detectSURFFeatures;

svision = svision.computePointCloud(true);
svision.featureEvaluation();
svision.pointCloudEvaluation();
svision.plotPointCloud();

%% Revision 2 Tuning delta max
svision.revision = 2;
svision.featureDetector = @detectSURFFeatures;

max_deltas = linspace(0.0001, 0.05, 20);
n = length(max_deltas);
results = ones(n, 4);
results(:, 1) = max_deltas';
svision.max_ransac_dist = -1;
for i = 1:n
    svision.max_delta = max_deltas(i);
    svision = svision.computePointCloud(true);
    results(i, 2:4) = svision.pointCloudEvaluation();
end
plot(results(:, 1), results(:, 2), results(:, 1), results(:, 3));

%% Revision 2 Tuned
svision.revision = 2;
svision.max_delta = 0.003;
svision.featureDetector = @detectSURFFeatures;

svision = svision.computePointCloud();
svision.pointCloudEvaluation();
svision.plotPointCloud();

%% Revision 3 Tuning d max
svision.revision = 3;
svision.featureDetector = @detectSURFFeatures;
d_max = linspace(0.001, 2, 2000);
n = length(d_max);
results = ones(n, 4);
results(:, 1) = d_max';
for i = 1:n
    svision.max_ransac_dist = d_max(i);
    svision = svision.computePointCloud();
    results(i, 2:4) = svision.pointCloudEvaluation();
end
subplot(3, 1, 1);
plot(results(:, 1), results(:, 2));
title("d_{max} vs A");
xlabel("d_{max}");
ylabel("A (cm^2)");

subplot(3, 1, 2);
plot(results(:, 1), results(:, 3) * 100);
title("d_{max} vs \epsilon_z");
xlabel("d_{max}");
ylabel("\epsilon_z (cm)");

subplot(3, 1, 3);
plot(results(:, 1), results(:, 4));
title("d_{max} vs n_{NaN}");
xlabel("d_{max}");
ylabel("n_{NaN}");

%% Revision 3 Tuned
svision.revision = 3;
svision.max_delta = 0.003;
svision.max_ransac_dist = 0.414;
svision.featureDetector = @detectSURFFeatures;
svision = svision.computePointCloud();
svision.plotPointCloud();

%% Final revision multiple detection methods
svision.revision = 3;
svision.max_delta = 0.003;
svision.max_ransac_dist = 0.414;

fdetectors = {@detectMinEigenFeatures, @detectHarrisFeatures, @detectBRISKFeatures, @detectSURFFeatures, @detectKAZEFeatures};
nf = length(fdetectors);

pc = [];
pcs = cell(nf, 1);
sts = zeros(nf, 12);
for fi = 1:nf
    svision.featureDetector = fdetectors{fi};
    tic;
    sv = svision.computePointCloud(true);
    sts(fi, 12) = toc;
    pcs{fi} = sv.pointcloud;
    sts(fi, 1:11) = sv.evaluate();
    if isempty(pc), pc = sv.pointcloud;
    else, pc = pcmerge(pc, sv.pointcloud, sv.tol); end
end
svision.pointcloud = pc;
total = sum(sts);
total(9:11) = svision.pointCloudEvaluation();
stats = cat(2, ["MinEig"; "Harris"; "BRISK"; "SURF"; "KAZE"; "Total"], cat(1, sts, total));

svision.plotPointCloud();

%%
load("pcs.mat");
allpc = pcmerge(pcs{1}, pcs{2}, 0.001);
for i = 3:5
    allpc = pcmerge(allpc, pcs{i}, 0.001);
end
pcshow(allpc);
