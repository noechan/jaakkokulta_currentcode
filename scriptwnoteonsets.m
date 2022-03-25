clear all,clc
fileExtension = '.mp3'; % replace this with e.g. 'wav' if needed
addpath('yin')
jaakkokultatemp=[0 0 2 2 4 4 0 0 0 0 2 2 4 4 0 0 4 4 5 5 7 7 7 7 4 4 5 5 7 7 7 7 7 9 7 5 4 4 0 0 7 9 7 5 4 4 0 0 0 0 -5 -5 0 0 0 0 0 0 -5 -5 0 0 0 0];
jaakkokultaonsets=[1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 0 0 1 0 1 0 1 0 0 0 1 1 1 1 1 0 1 0 1 1 1 1 1 0 1 0 1 0 1 0 1 0 0 0 1 0 1 0 1 0 0 0];
 % Plot template and note onsets
plot (jaakkokultatemp); hold on
n=1;
for i=1:length(jaakkokultaonsets)
    if jaakkokultaonsets(i)==1
        xline(i)
        n=n+1;
    end
end

d = dir(pwd);
i = 1;
for k = 1:numel(d)
    if contains(d(k).name,fileExtension)
        fname = d(k).name;
        out{i} = melodymatching(fname, jaakkokultatemp,'onset',jaakkokultaonsets);
        out{i}.filename = d(k).name;
        i = i+1;
    end
end
for k = 1:numel(out)
    rhythmerror(k,:) = out{k}.rhythmerror;
    pitcherror(k,:) = out{k}.pitcherror;
    filename{k} = out{k}.filename;
end

figure,tiledlayout('flow'),for k = 1:size(out,2),nexttile,plot(out{k}.pitch{5}),title(strrep(out{k}.filename,fileExtension,'')),hold on,plot(out{k}.temp{5}),title(strrep(out{k}.filename,fileExtension,'')),axis tight,end
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
