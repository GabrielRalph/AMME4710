clc;
clear;

classifier = open('classifier.mat').sClassifier;


idx = fscmrmr(classifier.features, classifier.groundTruthLabels);
mod(idx - 1, 10)

% classifier.trainModel()
%%

% classifier.testModel();


