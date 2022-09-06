load("./week2_facedata/facedata_yaleB01");
load("./week2_facedata/yaleB01_albedo_normals");


[h, w, N] = size(im_array);
rendered = zeros(h, w, N);

for y = 1:h
    for x = 1:w
       rendered(y, x, :) = albedo_image(y,x) * reshape(surface_normals(y,x,:),1,3) * light_dirs(:,:)';
    end
end

%%
subplot(1, 2, 1);
montage(im_array);
title("Actual image");
% 
subplot(1, 2, 2);
montage(rendered);
title("Computed shading");
