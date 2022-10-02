classdef SceneClassifier

    properties
        images;
        groundTruthLabels;
        model;
        features;
        testidx
    end
    
    properties (Constant)
        Scenes =  [
            "urban";
            "snow";
            "sky";
            "road";
            "park";
            "desert";
            "ball_pit"
        ]; 
    end
    
    methods
        function obj = SceneClassifier(data_filepath, model_filepath)
            data = load(data_filepath).data;
            obj.images = data.images;
            obj.groundTruthLabels = data.groundTruthLabels;
            obj.model = load(model_filepath);
        end
        
        function obj = getFeatures(obj, feature_method_path, tuning_params)
            addpath(feature_method_path);
            imgs = obj.images;
            n = length(imgs);
            f = [];
            if n > 0
                dim = length(get_feature_space(imgs{1}, tuning_params));
                f = zeros(n, dim);
                for i = 1:length(imgs)
                    f(i, :) = get_feature_space(imgs{i}, tuning_params);
                    fprintf("i = %.0f\n\n", i);
                end
            end
            obj.features = f;
        end
        
        function obj = trainModel(obj)
            gtl = obj.groundTruthLabels;
            f = obj.features;
            n = length(gtl);
            
            ridx = randperm(n);
            midi = ceil(n/2);
            aidx = ridx(1:midi);
            bidx = ridx((midi + 1):end);
            
            x = f(aidx, :);
            y = gtl(aidx)';
            
            % train model
            mdl = fitcecoc(x, y);
         
   
            obj.model = mdl;
            obj.testidx = bidx;
        end
        
        function testModel(obj)
            tx = obj.features(obj.testidx, :);
            ty = obj.groundTruthLabels(obj.testidx);
            
            
            [~, pintv] = predict(obj.model, tx);
            [~, order] = sort(pintv, 2);
            fprintf("\nModel Results\n");
            for j = 1:7
                correct = (repmat(ty, 1, 7) == order) & (order == j);
                topk = cumsum(sum(correct));
                topk = topk * 100 / topk(end);

                fprintf("Top K Correct for Scene %s\n", SceneClassifier.Scenes(j))
                for k = 1:4
                    fprintf("\ttop-%.0f accuracy = %.2f%%\n", k, topk(k));
                end
            end
            correct = (repmat(ty, 1, 7) == order);
            topk = cumsum(sum(correct));
            topk = topk * 100 / topk(end);
            fprintf("Total Top K Correct\n")
            for k = 1:4
                fprintf("\ttop-%.0f accuracy = %.2f%%\n", k, topk(k));
            end
        end
    end
    
    methods (Static)
        function data = makeDataset(root, data_filename) 
            labels = SceneClassifier.Scenes;
            gtlabels = [];
            filenames = [];
            for i = 1:7
                scene = labels(i);
                files = dir(sprintf("%s/%s/*.jpg", root, scene));
                for j = 1:length(files)
                    filename = sprintf("%s/%s/%s", root, scene, files(j).name);
                    filenames = cat(1, filenames, [filename]);
                    gtlabels = cat(1, gtlabels, [labels(i)]);
                end
            end

            n = length(filenames);
            images = cell(n, 1);
            for i = 1:n
                img = imread(filenames(i));
                images{i} = img;
            end

            data.groundTruthLabels = gtlabels;
            data.images = images;
            save(data_filename, 'data');
        end
    end
end

