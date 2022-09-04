clear;
clc;
clf;

load("./week2_facedata/facedata_yaleB05");

% compute albedo
model = Photometric(im_array, light_dirs);
model = model.solve_model_basic();

subplot(2, 2, 1);
model.plot_surface(3);
 

model = model.solve_residuals();

subplot(2,2, 2);
model.plot_residuals()
a1 = model.albedo;
% 
model = model.solve_model_outlier_rejection();
subplot(2,2, 3);
model.plot_surface(3)
% 
subplot(2,2,4);
imshowpair(a1, a1 - model.albedo, "montage");