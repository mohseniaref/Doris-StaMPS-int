% Script created to perform pca analysis on output data generated by
% StaMPS. All time series are analysed and compressed into their principle
% components. The first plot consists of the explained variance with
% subsequent plots showing scores for their corresponding components.
% 
%   Created by: Teije van der Horst
%       2016-11-17
%

clearvars
close all
%%
comp1 = 6; %The amount of components shown by PCA
comp2 = 3; %The amount of components shown by a zoom on PCA
%% This section loads the StaMPS output data
load('phuw2')
load('ps2')
load('parms','lambda')
scla=load('scla2','C_ps_uw');
ph_uw=ph_uw - repmat(scla.C_ps_uw,1,size(ph_uw,2)); %substract master atmosphere
lon = lonlat(:,1);
lat = lonlat(:,2);
f_ph2d = -lambda*1000/4/pi;
clearvars bperp calconst day_ix ll0 master_day master_ix msd n_ifg n_image lonlat scla lambda

%% This section corrects for reference and prepares the t matrix in the correct format
dp = length(day);
ph_uw = ph_uw - repmat(ph_uw(:,1),1,dp);
t = ph_uw';
wid = 'stats:pca:ColRankDefX';
warning('off',wid)

% t is a matrix with different points per row and individual time series
% per row like this:
% t = [p1_t1, p1_t2, p1_t3, ..., p1_tn; ...
%      p2_t1, p2_t2, p2_t3, ..., p2,tn; ...
%          ...
%      pn_t1, pn_t2, pn_t3, ..., pn_tn];

%% APPLY PCA:
[coeff,score,latent,~,explained,mu] = pca(t,'Algorithm','svd'); %svd, eig, als (~ = tsquared)

%% Plot cumulative explained variance
close all

colorcombo = jet;

figure()
ex = cumsum(explained);
plot(ex)
hold on
plot([0,length(explained)],[100 100])
plot([0, comp1, comp1], [ex(comp1), ex(comp1), 0],'--k')
xlabel('Number of components')
ylabel('Percentage explained (%)')
title('Explained variance')
ylim([floor(explained(1))-1 101])

%% Plot a number of components
for PC = 1:comp1
    figure('units', 'normalized', 'position', [0.07 0.02 .86 .78])
    
    subplot(1,2,1);%PC*2-1)
    mval = max(abs(coeff(:,PC)));
    scatter( lon, lat, 2, coeff(:,PC)/mval, 'filled', 'MarkerEdgeColor', 'none');
    colorbar
    colormap( colorcombo(end:-1:1,:) )
    caxis([-1, 1])%caxis([-mval, mval])
    axis tight
    set(gca,'DataAspectRatio',[1/cos(17*pi/180) 1 1])
    title( {['Principal Component ' num2str(PC)];['explaining ' num2str(explained(PC), '%10.2f') ' % of the variance']} )

    
    subplot(1,2,2)%PC*2)
    plot(day, score(:,PC)*mval*f_ph2d)
    ylabel('mm displacement in LOS') %Specific for PCA
    datetick
    OP2 = get(gca, 'OuterPosition');
    OP2([2,4]) = [0.15 0.7];
    set(gca,'OuterPosition',OP2);
    
    subplot(1,2,1)%PC*2-1)
end
%% Possibly plot new pca of zoomed area
fn = input('Do you want to zoom in on an area? indicate the integer figure number or specify ''n'' for no: ','s');
switch fn
    case 'n'
        %do nothing
    otherwise
        f = str2double(fn);
        figure(f);
        uiwait(msgbox('Create polygon and double click it when finished'));
        h = impoly;
        pos = wait(h);
        delete(h)
        in = inpolygon(lon, lat, [pos(:,1);pos(1,1)], [pos(:,2);pos(1,2)]);
        %PCA2
        loncrop = lon(in);
        latcrop = lat(in);
        [coeffcr,scorecr,latentcr,~,explainedcr,mucr] = pca(t(:,in),'Algorithm','svd'); %svd, eig, als (~ = tsquared)
            figure()
            excr = cumsum(explainedcr);
            plot(excr)
            hold on
            plot([0,length(explained)],[100 100])
            plot([0, comp2, comp2], [excr(comp2), excr(comp2), 0],'--k')
            xlabel('Number of components')
            ylabel('Percentage explained (%)')
            title('Explained variance')
            ylim([floor(explainedcr(1))-1 101])
            %
            for PC = 1:comp2
                figure('units', 'normalized', 'position', [0.07 0.02 .86 .78])

                subplot(1,2,1);%PC*2-1)
                mval = max(abs(coeffcr(:,PC)));
                scatter( loncrop, latcrop, 2, coeffcr(:,PC)/mval, 'filled', 'MarkerEdgeColor', 'none');
                colorbar
                colormap( colorcombo(end:-1:1,:) )
                caxis([-1, 1])%caxis([-mval, mval])
                axis tight
                set(gca,'DataAspectRatio',[1/cos(17*pi/180) 1 1])
                title( {['Principal Component ' num2str(PC)];['explaining ' num2str(explainedcr(PC), '%10.2f') ' % of the variance']} )


                subplot(1,2,2)%PC*2)
                plot(day, scorecr(:,PC)*mval*f_ph2d)
                ylabel('mm displacement in LOS')
                datetick
                OP2 = get(gca, 'OuterPosition');
                OP2([2,4]) = [0.15 0.7];
                set(gca,'OuterPosition',OP2);

                subplot(1,2,1)%PC*2-1)
            end
end
warning('on',wid)
print = input('Do you want to save the figures? (y/n) ','s');
if strcmpi(print,'y') || strcmpi(print,'yes')
    fprintf('Printing figures to folder ./PCA/\n')
    PrintAll('PCA');
elseif strcmpi(print,'n') || strcmpi(print,'no')
    fprintf('No figures printed\n')
end
fprintf('Terminating ps_pca\n\n')
        
%% End of script
