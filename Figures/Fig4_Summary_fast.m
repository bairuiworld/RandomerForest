clear
close all
clc

t = readtable('/cis/home/ttomita/Data/data_idx.txt','ReadVariableNames',false,'ReadRowNames',false);
dirnames = t.Var1;

Results = struct('Lhat',struct,'Time',struct);
Results2 = struct('Lhat',struct,'Time',struct,'sp',struct,'tr',struct);
j = 1;
for i = 1:length(dirnames)
    dirname = dirnames{i};
    fname = dir(strcat('/cis/home/ttomita/Data/',dirname,'/',dirname,'.mat'));
    fname2 = dir(strcat('/cis/home/ttomita/Data/',dirname,'/',dirname,'2*.mat'));
    if isempty(fname) | isempty(fname2)
        fprintf('%s\n%s\n',fname.name,fname2.name)
        warning(sprintf('%s workspace file does not exist',dirname))
        rmidx(j) = i;
	j = j + 1;
    else
        load(fname.name,'Lhat','Time')
        Results.Lhat.(strrep(dirname,'-','__')) = Lhat;
        Results.Time.(strrep(dirname,'-','__')) = Time;
        load(fname2.name,'Lhat','Time','sp','tr')
        Results2.Lhat.(strrep(dirname,'-','__')) = Lhat;
        Results2.Time.(strrep(dirname,'-','__')) = Time;
	Results2.sp.(strrep(dirname,'-','__')) = sp;
	Results2.tr.(strrep(dirname,'-','__')) = tr;
    end
end

dirnames(rmidx) = [];

for i = 1:length(dirnames)
    dirname = dirnames{i};
    cd(dirname)
    if exist(strcat(dirname,'_train_R.dat'))
        FileName = strcat(dirname,'_train_R.dat');
    else
        FileName = strcat(dirname,'_R.dat');
    end
    X = dlmread(FileName,'\t',1,1);
    [n(i),d(i)] = size(X);
    cd ..
    tr_all(i) = Results2.tr.(strrep(dirname,'-','__'));
%    clnames = fieldnames(Results.Lhat.(strrep(dirname,'-','__')));
    clnames = {'rf','f2','f3','f4'};
    for j = 1:length(clnames)
        clname = clnames{j};
        Lhat_all.(clname)(i,:) = Results2.Lhat.(strrep(dirname,'-','__')).(clname);
        Time_all.(clname)(i,:) = Results2.Time.(strrep(dirname,'-','__')).(clname);
	sp_all.(clname)(i,:) = Results2.sp.(strrep(dirname,'-','__')).(clname);
    end
    clname = 'f1';
    Lhat_all.(clname)(i,:) = Results.Lhat.(strrep(dirname,'-','__')).(clname);
    Time_all.(clname)(i,:) = Results.Time.(strrep(dirname,'-','__')).(clname);
end

lspec = {'bs','rs','gs' 'cs' 'ms'};
facespec = {'b','r','g' 'c' 'm'};

clnames = {'rf','f1','f2','f3','f4'};
for i = 1:length(clnames)
    clname = clnames{i};
    if strcmp(clname,'rf')
        idx = 1;
    else
        idx = size(Lhat_all.(clname),2);
    end
    Lhat_mean.(clname) = mean(Lhat_all.(clname));
    Lhat_sem.(clname) = std(Lhat_all.(clname))/sqrt(length(dirnames));
    Time_mean.(clname) = mean(Time_all.(clname));
    Time_sem.(clname) = std(Time_all.(clname))/sqrt(length(dirnames));
    plot(Time_mean.(clname)(idx),Lhat_mean.(clname)(idx),lspec{i},'MarkerEdgeColor','k','MarkerFaceColor',facespec{i});
    hold on
end

xlabel('Training Time (sec)')
ylabel('Lhat')
legend('Random Forest','Sparse Randomer Forest','Sparse Randomer Forest w/ Mean Diff','Robust Sparse Randomer Forest w/ Mean Diff')

for i = 1:length(clnames)
    clname = clnames{i};
    if strcmp(clname,'rf')
        idx = 1;
    else
        idx = size(Lhat_all.(clname),2);
    end
    Mu = [Time_mean.(clname)(idx) Lhat_mean.(clname)(idx)];
    Sigma = cov(Time_all.(clname)(:,idx),Lhat_all.(clname)(:,idx));
    X_level_curve = bvn_level_curve(Mu,Sigma,0.1,200);
    plot(X_level_curve(:,1),X_level_curve(:,2),'--',...
         'Color',facespec{i},...
         'LineWidth',1.5)
    hold on
end

save('/cis/home/ttomita/Data/Fig4_Summary.mat','Results','Lhat_mean','Lhat_sem','Time_mean','Time_sem')
save_fig(gcf,'/cis/home/ttomita/Data/Fig4_Real_Data_Panel_A_fast')



figure(2)
XY = cat(2,Lhat_all.rf(:,1),Lhat_all.f4(:,end));
Dist = abs(XY*[-sqrt(2)/2;sqrt(2)/2]);
Dist_rank = passtorank(Dist);
N = length(Lhat_all.rf(:,1));
rgb = map2color(d','log');
sz = map2size(n',20,100,'log');
scatter(Lhat_all.rf(:,1),Lhat_all.f4(:,end),sz,rgb,'filled');
%r = cat(1,zeros(1000,1),transpose(linspace(0,1,1001)));
%g = cat(1,transpose(linspace(0,1,1001)),transpose(linspace(0.999,0,1000)));
%b = flipud(r);
rgb = map2color(transpose(linspace(1,1000,1000)),'log');
colormap([rgb(:,1) rgb(:,2) rgb(:,3)])
colorbar
caxis([min(d) max(d)])
hold on
plot([0 1],[0 1],'-k')
xlabel('Random Forest')
ylabel('Robust Randomer Forest')
title('Lhat')
save_fig(gcf,'/cis/home/ttomita/Data/Fig4_Real_Data_Panel_B_fast')

figure(3)
nd = n./d;
rgb = map2color(nd','log');
sz = map2size(n',36,100,'log');
scatter(Lhat_all.rf(:,1),Lhat_all.f4(:,end),sz,rgb,'filled');
%r = cat(1,zeros(1000,1),transpose(linspace(0,1,1001)));
%g = cat(1,transpose(linspace(0,1,1001)),transpose(linspace(0.999,0,1000)));
%b = flipud(r);
rgb = map2color(transpose(linspace(1,1000,1000)),'log');
colormap([rgb(:,1) rgb(:,2) rgb(:,3)])
colorbar
caxis([min(nd) max(nd)])
hold on
plot([0 1],[0 1],'-k')
xlabel('Random Forest')
ylabel('Robust Randomer Forest')
title('Lhat')
save_fig(gcf,'/cis/home/ttomita/Data/Fig4_Real_Data_Panel_B_fast2')

figure(4)
XY = cat(2,Lhat_all.rf(:,1),Lhat_all.f4(:,end));
rgb = map2color(d','log');
sz = map2size(n',20,100,'log');
scatter(tr_all,Lhat_all.rf(:,1)-Lhat_all.f4(:,end),sz,rgb,'filled');
%r = cat(1,zeros(1000,1),transpose(linspace(0,1,1001)));
%g = cat(1,transpose(linspace(0,1,1001)),transpose(linspace(0.999,0,1000)));
%b = flipud(r);
rgb = map2color(transpose(linspace(1,1000,1000)),'log');
colormap([rgb(:,1) rgb(:,2) rgb(:,3)])
colorbar
caxis([min(d) max(d)])
hold on
xlabel('Trace')
ylabel('Lhat(RF)-Lhat(RerF)')
title('trace')
save_fig(gcf,'/cis/home/ttomita/Data/Fig4_trace')

figure(5)
XY = cat(2,Lhat_all.rf(:,1),Lhat_all.f4(:,end));
Dist = abs(XY*[-sqrt(2)/2;sqrt(2)/2]);
Dist_rank = passtorank(Dist);
N = length(Lhat_all.rf(:,1));
rgb = map2color(d','log');
sz = map2size(n',20,100,'log');
scatter(sp_all.rf(:,1),sp_all.f2(:,end),sz,rgb,'filled')
rgb = map2color(transpose(linspace(1,1000,1000)),'log');
colormap([rgb(:,1) rgb(:,2) rgb(:,3)])
colorbar
caxis([min(d) max(d)])
hold on
xlabel('Random Forest')
ylabel('Robust Randomer Forest')
title('Sparsity')
save_fig(gcf,'/cis/home/ttomita/Data/Fig4_sparsity')
