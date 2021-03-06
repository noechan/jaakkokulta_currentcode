clear all
% Define paths and init variables
data_path='/Volumes/LASA/Aphasia_project/Acoustic_analysis/singing_stimuli/FJ_Model/Martin/';
code_path='/Volumes/LASA/Aphasia_project/Acoustic_analysis/code/jaakkokulta_currentcode/';
addpath(code_path)
addpath(fullfile(code_path,'yin'))
fileExtension = '.mp3'; % replace this with e.g. 'wav' if needed
jaakkokultatemp=[0 0 2 2 4 4 0 0 0 0 2 2 4 4 0 0 4 4 5 5 7 7 7 7 4 4 5 5 7 7 7 7 7 9 7 5 4 4 0 0 7 9 7 5 4 4 0 0 0 0 -5 -5 0 0 0 0 0 0 -5 -5 0 0 0 0];
cd (data_path)
d = dir('*kulta.mp3');
i = 1;
for k = 2:numel(d)
    if contains(d(k).name,fileExtension)
        fname = d(k).name;
        out{i} = melodymatching(fname, jaakkokultatemp);
        out{i}.filename = d(k).name;
        i = i+1;
    end
end
for k = 1:numel(out)
    rhythmerror(k,:) = out{k}.rhythmerror;
    pitcherror(k,:) = out{k}.pitcherror;
    filename{k} = out{k}.filename;
end

figure
tiledlayout('flow')
for k = 1:size(out,2)
    nexttile
    plot(out{k}.pitch{5})
    title(strrep(out{k}.filename,fileExtension,''))
    hold on
    plot(out{k}.temp{5})
    title(strrep(out{k}.filename,fileExtension,''))
    axis tight
end
lg = legend({'pitch curve','template'},'Orientation','Horizontal');
lg.Layout.Tile = 'North'; % <-- Legend placement with tiled layout



cf = corr([pitcherror rhythmerror]);
pitlab = "melody matching pitch " + string(1:size(pitcherror,2));
rhylab = "melody matching rhythm ";
cf(tril(cf) == 0) = NaN;
figure
im = imagesc(cf);
[im.Parent.XTick im.Parent.YTick] = deal(1:length(cf));
xticklabels([pitlab rhylab])
yticklabels([pitlab rhylab])
colorbar
title('correlation between features')

disp('Feature values')
disp(sortrows([table(string(filename'),'VariableNames',{'filename'}),array2table(pitcherror),array2table(mean(pitcherror,2),'VariableNames',{'mean'})],'mean'))
disp(sortrows([table(string(filename'),'VariableNames',{'filename'}),array2table(rhythmerror),array2table(mean(rhythmerror,2),'VariableNames',{'mean'})],'mean'))

rmpath('yin')
