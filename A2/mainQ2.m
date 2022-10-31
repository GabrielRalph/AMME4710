clc;
clear;
SC = SceneClassifier();

[data, y] = SceneClassifier.getDataset("dataset");


%% Revision 1
SC = SC.setRevision("SceneClassifier/Revision 1");
SC.featrparams.K = 5;
SC = SC.makeModel(x, y);

%% Revision 2
SC = SC.setRevision("SceneClassifier/Revision 2");

%% Revision 3
SC = SC.setRevision("SceneClassifier/Revision 3");

%% Revision 4
SC = SC.setRevision("SceneClassifier/Revision 4");
SC.featrparams.colorDim = 6;

%% EXTRACT
fprintf("extracting");
x = SC.extractFeatureSpace(data);
fprintf("\n\ndone\n");

fprintf("training ..\n");
SC.kfolds = 350;
SC = SC.makeModel(x, y);
fprintf("\n\ndone\n");

[conf, ktop] = SC.getValidationData();
confusionchart(conf, SceneClassifier.Scenes);

res = SC.modelEvaluation();
fprintf("%s\n", res);
%% FINAL MODEL
SC = SC.setRevision("SceneClassifier/Revision 3");
fprintf("extracting");
x = SC.extractFeatureSpace(data);
fprintf("\n\ndone\n");
model = fitcecoc(x, y);

