testPhotometric(1);

function testPhotometric(fileIdx)
    files = dir("week2_facedata/facedata*.mat");
    data = load(sprintf("./week2_facedata/%s", files(fileIdx).name));
    
    model1 = Photometric(data.im_array, data.light_dirs);
    model1 = model1.solveModelBasic();
    
    for i = 1:3
        subplot(2, 3, i);
        model1.plotSurface(i);
        title(sprintf("Method %i", i));
    end
    
    model2 = model1.solveResiduals();
    subplot(2, 3, 4);
    imshow(model2.getResidualImage());
    title("Residuals");
    
    subplot(2, 3, 5);
    imshow(cat(2, model1.albedo, model2.albedo));
    title("Albedo (no rejection vs outlier rejection)");
    
    model2 = model2.solveModelOutlierRejection();
    subplot(2, 3, 6);
    model2.plotSurface(3);
    title("Model 3 (outlier rejection)");
    
end