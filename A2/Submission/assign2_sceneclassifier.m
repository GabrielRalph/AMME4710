function class_labels = assign2_sceneclassifier(image_path)
    load("classifier_model.mat", "model");
    addpath("SCRevisions/Revision 3");
    
    x = extract_feature_point(imread(image_path));
    [~, pp] = predict(model, x);
    [~, idxs] = sort(pp, 2, 'descend');
    class_labels = SceneClassifier.Scenes(idxs)';
end

