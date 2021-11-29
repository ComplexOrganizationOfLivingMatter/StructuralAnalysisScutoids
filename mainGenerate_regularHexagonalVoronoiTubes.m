clear all

addpath(genpath('src'))

%Theoretical SR in with basal get a rotated but regular tessellation of
%hexagons
sideHexagon = 10;nRowsSeeds=5;nColumnsSeeds=4;angleRot=0;

%points per unit of area (density of point cloud)
ppaDefault=10;
spacedQueryEdges=sideHexagon/200; %density of cell edges
numberOfSrSpaces = 100;%200
%basal surface ratio. 8/3 is just the theoretica SR when hexagonal lattice
%get rotated 90 from apical base, being perfect regular hexagonal pieces
srFinal=8/3;

%get initial seeds only to get Voronoi limits
[rotSeedsInit,~] =generateSeedsOfRegularVoronoiHexagonalLattice(sideHexagon,nRowsSeeds,nColumnsSeeds-1,angleRot);
%x distances
uniqXPos = unique(rotSeedsInit(:,1));
widthLimits = [min(rotSeedsInit(:,1)),max(rotSeedsInit(:,1))+(uniqXPos(2)-uniqXPos(1))];
heightLimits = [min(rotSeedsInit(:,2)),max(rotSeedsInit(:,2))];

%% Now we get again the Voronoi seeds with one extra row up and another down
[rotSeeds,~] =generateSeedsOfRegularVoronoiHexagonalLattice(sideHexagon,nRowsSeeds+2,nColumnsSeeds-1,angleRot);
distancesYseeds = (max(rotSeeds(:,2))-heightLimits(2))/2;
rotSeeds(:,2)=rotSeeds(:,2)-distancesYseeds;

%triplicate seeds laterally
triSeeds = [rotSeeds; [rotSeeds(:,1)+widthLimits(2),rotSeeds(:,2)];[rotSeeds(:,1)+widthLimits(2)*2,rotSeeds(:,2)]];

widthFinal = widthLimits(2)*srFinal;
radiusBasal=widthFinal/(2*pi);

%filtering only central cells
cellsToStudyX = find(round(triSeeds(:,1),3)>=round(widthLimits(2),3) & round(triSeeds(:,1),3)<=round(widthLimits(2)*2,3));
cellsToStudyY = find(round(triSeeds(:,2),3)>=round(heightLimits(1),3) & round(triSeeds(:,1),3)<=round(heightLimits(2),3));
cellsToStudy =intersect(cellsToStudyX,cellsToStudyY);

%define cell to save pointCloud
coordCellsVoronoi = cell(max(cellsToStudy),1);
coordCellsFrusta = cell(max(cellsToStudy),1);

for SR = 1:(srFinal-1)/numberOfSrSpaces:srFinal

    triSeedsPerSR = [triSeeds(:,1)*SR,triSeeds(:,2)];

%     %Voronoi diagram
%     [vx,vy]=voronoi(triSeedsPerSR(:,1),triSeedsPerSR(:,2));
%     ylim(heightLimits)
%     updatedWidthLimits = [widthLimits(2)*SR,(widthLimits(2)*2)*SR];
%     xlim(updatedWidthLimits)
%     axis equal

    DT = delaunayTriangulation(triSeedsPerSR);

    %get unique vertices
    tri_Voronoi = DT.ConnectivityList;
    verticesTRI_Voronoi = DT.circumcenter;  
    
%     if SR==1
%         tri_frusta = tri_Voronoi;
%         verticesTRI_frustaInit = verticesTRI_Voronoi;
%     end
%     verticesTRI_frusta(:,1)=verticesTRI_frustaInit(:,1)*SR;
    
    if SR==1 || SR==srFinal
        ppa=ppaDefault*100;
    else
        ppa=ppaDefault;
    end
    
    for nCell = cellsToStudy(1):cellsToStudy(end)
        
        %get coordinates per cell slice
        coordsCellVor = storeCoordsPerSlices3DCells(nCell,tri_Voronoi,verticesTRI_Voronoi,widthLimits,heightLimits,SR,radiusBasal,ppa,spacedQueryEdges);
%         coordsCellFrusta = storeCoordsPerSlices3DCells(nCell,tri_frusta,verticesTRI_frusta,widthLimits,heightLimits,SR,radiusBasal,ppa,spacedQueryEdges);

        if nCell>size(rotSeeds,1)*2
            coordCellsVoronoi{nCell-size(rotSeeds,1)*2}=[vertcat(coordCellsVoronoi{nCell-size(rotSeeds,1)*2});coordsCellVor];
%             coordCellsFrusta{nCell-size(rotSeeds,1)*2}=[vertcat(coordCellsFrusta{nCell-size(rotSeeds,1)*2});coordsCellFrusta];
        else
            if nCell<=size(rotSeeds,1)
                coordCellsVoronoi{nCell}= [vertcat(coordCellsVoronoi{nCell});coordsCellVor];
%                 coordCellsFrusta{nCell}=[vertcat(coordCellsFrusta{nCell});coordsCellFrusta];
            else
                coordCellsVoronoi{nCell-size(rotSeeds,1)}= [vertcat(coordCellsVoronoi{nCell-size(rotSeeds,1)});coordsCellVor];
%                 coordCellsFrusta{nCell-size(rotSeeds,1)}= [vertcat(coordCellsFrusta{nCell-size(rotSeeds,1)});coordsCellFrusta];
            end
        end
        
    end
end
% for nCell = 1:size(coordCells,1)
%     
%     if ~isempty(coordCells{nCell})
%         plot3(coordCells{nCell}(:,1),coordCells{nCell}(:,2),coordCells{nCell}(:,3),'*')
%         hold on
%     end
%     
% end

%%remove some non-valid cell
maxPoints=max(cellfun(@(x) size(x,1), coordCellsVoronoi));
idCell2Delete = cellfun(@(x) size(x,1)<maxPoints/5, coordCellsVoronoi);
coordCellsVoronoi(idCell2Delete)=[];

%% Save cells as ".ply"
path2save = fullfile('data','hexagonalVoronoiTube','regularHexaTube_row5_column4');
mkdir(path2save)

% save(fullfile(path2save,'coordinatesIndCells.mat'),'coordCellsVoronoi','coordCellsFrusta')

for nCell=1:length(coordCellsVoronoi)
    if ~isempty(coordCellsVoronoi{nCell})
        uniqCoordCell = unique(coordCellsVoronoi{nCell},'rows');
        pcwrite(pointCloud(uniqCoordCell),fullfile(path2save,['cellID_' num2str(nCell) '.ply']))
        shp= alphaShape(uniqCoordCell);
        [F,V]=shp.boundaryFacets;
%         solid = surf2solid(F,V,'thickness',-0.1);
%         stlwrite(fullfile(path2save,['cellID_' num2str(nCell) '.stl']),solid.faces,solid.vertices)
        stlwrite(fullfile(path2save,['cellID_' num2str(nCell) 'onlySurface.stl']),F,V)
    end
end

