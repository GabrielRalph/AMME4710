classdef SceneClassifier

    properties
<<<<<<< HEAD
        model;  % computed model
        kfolds; % number of folds
        valmat; % validation matrix [confusion; top-k]
        
        trainparams;
        validparams;
        featrparams;
        
        revision; %
=======
        images;
        groundTruthLabels;
        model;
        features;
        testidx
>>>>>>> 72d05b5737bd13b9b0f2773adf8aa0de0a14a2f8
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
<<<<<<< HEAD
        function obj = SceneClassifier()
            obj.kfolds = 8;
        end
        
        function obj = setRevision(obj, r)
            if ~strcmp(obj.revision, r)
                restoredefaultpath
                addpath(r);
                obj.revision = r;
            end
        end
        

        function [confmat, topk] = getValidationData(obj)
            confmat = obj.valmat(1:(end-1), :);
            topk = obj.valmat(end, :);
        end
        
        %% main model creation steps
        function x = extractFeatureSpace(obj, data)
            if ~iscell(data)
                data = {data};
            end
    
            n = length(data);
            x = [];
            if n > 0
                fp = extract_feature_point(data{1}, obj);
                x = zeros(n, length(fp));
                x(1, :) = fp;
                for i = 2:n
                    fprintf(".");
                    x(i, :) = extract_feature_point(data{i}, obj);
                end
            end
        end

        function obj = makeModel(obj, x, y)
            n = length(y);
            
            rand_idxs = randperm(n);
            x = x(rand_idxs, :);
            y = y(rand_idxs, :);
            
            % train and validate data for k folds
            k = obj.kfolds;
            folds = round(linspace(1, n, k + 1));
            partion = ones(n, 1);
            svmat = [];
            for pi = 1:k
                partion(:) = 1;
                si = folds(pi);
                if pi > 1, si = si + 1; end
                partion(si:folds(pi + 1)) = 0;
                fprintf("fold %f\n", pi);
                
                xtrain = x(partion == 1);
                ytrain = y(partion == 1);
                xval = x(partion == 0);
                yval = y(partion == 0);
                
                mdl = train_model(xtrain, ytrain, obj);
                
                vmat = SceneClassifier.getValidationMatrix(mdl, xval, yval);
                if isempty(svmat), svmat = zeros(size(vmat)); end
                svmat = vmat + svmat;
            end
            obj.valmat = svmat;
%             obj.model = train_model(x, y, obj);
        end
       
        function results = modelEvaluation(obj) 
            [confmat, topk] = obj.getValidationData();
            scenes = SceneClassifier.Scenes;
            ns = length(scenes);
            n = sum(confmat, 'all');
            
            tp = sum(confmat .* eye(ns)); % True positives for each class
            % i.e. [tp_1, tp_2, ..., tp_i] number of times class i was
            % correectly guessed
            fpn = confmat .* ~eye(ns);
            fn = sum(fpn);      % False Negatives for classes
            % i.e. the number of times class i was not choosen despite
            % being the correct answer
            fp = sum(fpn, 2)';  % False positives for classes
            % i.e. the number of times class was choosen but was not the
            % correct class
            
            tn = n - tp - fn - fp; % True negatives
            % The number times class i was correctly not choosen
            
            % compute accuracy, precision, recall and f1 scores for each
            % class
            ac = (tp + tn) ./ n;
            pr = (tp) ./ (tp + fp);
            rc = (tp) ./ (tp + fn);
            f1 = 2 * (pr .* rc) ./ (pr + rc);
            
            scenes = "\text{" + scenes + "}";
            
            pc = round(255 *confmat ./ sum(confmat, 2));
            colors = ones(ns, ns, 3) * 255;
            colors(:, :, 1:2) = colors(:, :, 1:2) - pc .* eye(ns);
            colors(:, :, 2:3) = colors(:, :, 2:3) - pc .* ~eye(ns);
            colors = "rgb(" + colors(:, :, 1) + "," + colors(:, :, 2) + "," + colors(:,:,3) + ")";
            conf = "\cellcolor{" + colors + "} " + confmat;
            conf = [
                "", scenes';
                scenes, conf;
            ];
            
            
            % Format stat information table
            stats = [ac; pr; rc; f1];
            stats(isnan(stats)) = 0;
            stats = [stats, mean(stats, 2)] * 100;
            stats = round(stats, 1);
            stats = stats + "\%";
            stats = [("\text{" + ["Accuracy"; "Precision"; "Recall"; "F1"] + "}"), stats];
            stats = [["", scenes', "mean"]; stats];
            
            % Format Top K Table
            rg = 1:5;
            topk = round(100 * topk(rg) / n, 1) + "\%";
            topk = [
                ["", ("\text{Top " + rg + "}")];
                ["\text{Accuracy}", topk];
            ];
            
            % Format Results
            ctex = mat2textable(conf);
            stex = mat2textable(stats);
            ktex = mat2textable(topk);
            
            results = sprintf("Results from %.f folds validation\nConfussion Matrix\n$%s$\n\nAccuracy Metrics\n$%s$\n\nTop K Accuracy\n$%s$", obj.kfolds, ctex, stex, ktex);
        end

        
        function ypredict = classifie(obj, data)
            x = obj.extractFeatureSpace(data);
            ypredict = predict(obj.model, x);
        end
       
    end
    
    methods (Static)
        function vmat = getValidationMatrix(mdl, xval, yval)
            scenes = SceneClassifier.Scenes;
            nc = length(scenes);
            vmat = zeros(nc + 1, nc);

            [ypred, prob] = predict(mdl, xval);

            [~, orders] = sort(prob, 2, 'descend');
            oi = orders == yval;
            tks = cumsum(oi, 2);
            tk = sum(tks, 1);
            vmat(nc + 1, :) = tk;

            for i = 1:length(ypred)
                vmat(yval(i), ypred(i)) = vmat(yval(i), ypred(i)) + 1;
            end
        end
        
        function [data, ytruth] = getDataset(root) 
            labels = SceneClassifier.Scenes;
            ytruth = [];
=======
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
>>>>>>> 72d05b5737bd13b9b0f2773adf8aa0de0a14a2f8
            filenames = [];
            for i = 1:7
                scene = labels(i);
                files = dir(sprintf("%s/%s/*.jpg", root, scene));
                for j = 1:length(files)
                    filename = sprintf("%s/%s/%s", root, scene, files(j).name);
                    filenames = cat(1, filenames, [filename]);
<<<<<<< HEAD
                    ytruth = cat(1, ytruth, [i]);
=======
                    gtlabels = cat(1, gtlabels, [labels(i)]);
>>>>>>> 72d05b5737bd13b9b0f2773adf8aa0de0a14a2f8
                end
            end

            n = length(filenames);
<<<<<<< HEAD
            data = cell(n, 1);
            for i = 1:n
                img = imread(filenames(i));
                data{i} = img;
            end

=======
            images = cell(n, 1);
            for i = 1:n
                img = imread(filenames(i));
                images{i} = img;
            end

            data.groundTruthLabels = gtlabels;
            data.images = images;
            save(data_filename, 'data');
>>>>>>> 72d05b5737bd13b9b0f2773adf8aa0de0a14a2f8
        end
    end
end

