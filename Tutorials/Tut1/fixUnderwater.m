function newImage = fixUnderwater(img, sats)
    
    newImage = 0;
    for c = 1:3
        channel = img(:, :, c);
        
        % Apply saturation to channel
        satLevels = sats(c, 1:2);
        channel = imadjust(channel, satLevels);
        
        %Apply image contrast enhancement using histogram equalization
        if (sats(c, 3) > 0)
            channel = histeq(channel, sats(c, 3));
        else 
            channel = adapthisteq(channel,'clipLimit',0.02,'Distribution','rayleigh'); 
        end
        
        
        
        
        if (newImage == 0) 
            newImage = channel;
        else
            newImage = cat(3, newImage, channel);
        end
    end
end