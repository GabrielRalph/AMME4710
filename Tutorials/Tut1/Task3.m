% Task 3

image = imread("./chess/apples.jpg");

[height, width, dim] = size(image);

res = segmentRedGreen(image);


subplot(2,6,[1,2,3]);
imshow(image);
title("Original Image");

subplot(2,6,[4,5,6]);
imshow(res{1});
title("Segmented Image");

subplot(2,6,[7,8]);
imshow(res{2});
title("Red Segment");

subplot(2,6,[9,10]);
imshow(res{3});
title("Green Segment");

subplot(2,6,[11,12]);
imshow(res{4});
title("Background Segment");



function result = segmentRedGreen(image)
    background_threshold = 0.5;
    % multithresh and quantize hue, saturation and value layers
    layers = [3, 2, 3];
    imageHSV = rgb2hsv(image);
    for i = 1:length(layers)
        n = layers(i);
        if (n > 0) 
            layer = imageHSV(:, :, i);
            thresh = multithresh(layer, n);
            quant = imquantize(layer, thresh, [0 thresh(2:end) 1]);
            imageHSV(:, :, i) = quant;
        end
    end
    
    % take the background as value * saturation and quantize that 
    bg = imageHSV(:,:,2)  .* imageHSV(:, :, 3);
    bg = imquantize(bg, [background_threshold], [0 1]);
    
    % rotate hues to get red and green channels
    hues = imageHSV(:,:,1);
    red = imquantize(mod(hues + 0.99, 1), 0.9, [0,1]) .* bg;
    green = imquantize(mod(hues + 2/3, 1), 0.9, [0, 1]) .* bg;
    
    % combine red, green and background channels to create result image
    I = ones(size(image), "uint8");
    bg = uint8(255 - bg * 255);
    red = uint8(red * 255);
    green = uint8(green * 255);
    for i = 1:3
        channel = bg;
        if (i == 1) 
            channel = channel + red;
        elseif (i == 2)
            channel = channel + green;
        end

        I(:,:,i) = channel;

    end
    result = {I, red, green, bg};
end