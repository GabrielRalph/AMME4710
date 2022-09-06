function display_face_model(albedo_image, height_map)

% display_face_model - Shows a 3D surface model of a heightmap, coloured by
% the matrix albedo_image
%
% albedo_image: h-by-w matrix of albedo values, values between 0 and 1
% height_map: h-by-w matrix of height values (any range)
%

[h,w] = size(height_map);
[X,Y] = meshgrid(1:w, 1:h);

figure
mesh(X, Y, height_map, albedo_image);
axis equal;

xlabel('X')
ylabel('Y')
zlabel('Z')
title('Height Map')
set(gca, 'XTick', []);
set(gca, 'YTick', []);
set(gca, 'ZTick', []);
set(gca, 'XDir', 'reverse')

colormap(gray)
