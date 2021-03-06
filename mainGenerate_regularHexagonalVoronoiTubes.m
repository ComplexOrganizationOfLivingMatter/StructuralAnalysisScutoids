clear all

addpath(genpath('src'))

%Theoretical SR in with basal get a rotated but regular tessellation of
%hexagons

%% First we define several parameters of our hexagonal tubes:
%sideHexagon -> length of hexagons edges in the inner surface. As they are
%regular, all the sides are going to be the same in terms of length.
%nRowsSeeds -> number of hexagonal rows along the longitudinal axis
%nColumnsSeeds -> number of hexagonal columns along the trasversal axis
%angleRot -> rotation angles of the hexagons. The hexagons can rotate
%between 0º a 30º.
sideHexagon = 5;nRowsSeeds=4;nColumnsSeeds=4;angleRot=0;

%% Parameters to define the density of the cell solids
%ppaDefault -> points per unit of area (density of point cloud)
ppaDefault=10;
%spacedQueryEdges -> density of cell edges
spacedQueryEdges=sideHexagon/200;

%numberOfSrSpaces -> number of intermediate layers between inner and outer cylindrical surfaces
numberOfSrSpaces = 150;%200

%% Define final surface ratio (Outer radius / Inner radius)
%Outer surface ratio. 8/3 is just the theoretica SR when hexagonal lattice
%get rotated 90 from apical base, being perfect regular hexagonal pieces
srFinal=8/3;

%% Get regular placed seeds to define the limits of the unrolled cylindrical plane
%get initial seeds only to get Voronoi limits
[rotSeedsInit,~] =generateSeedsOfRegularVoronoiHexagonalLattice(sideHexagon,nRowsSeeds,nColumnsSeeds-1,angleRot);
%x distances
uniqXPos = unique(rotSeedsInit(:,1));
widthLimits = [min(rotSeedsInit(:,1)),max(rotSeedsInit(:,1))+(uniqXPos(2)-uniqXPos(1))];
heightLimits = [min(rotSeedsInit(:,2)),max(rotSeedsInit(:,2))];

%% Get again the Voronoi seeds with one extra row up and another down (it is a trick to build the Voronoi cells in the borders)
[rotSeeds,~] =generateSeedsOfRegularVoronoiHexagonalLattice(sideHexagon,nRowsSeeds+2,nColumnsSeeds-1,angleRot);
distancesYseeds = (max(rotSeeds(:,2))-heightLimits(2))/2;
rotSeeds(:,2)=rotSeeds(:,2)-distancesYseeds;

%% triplicate seeds laterally (along the trasverse axis) to mimick the cylindrical topology.
triSeeds = [rotSeeds; [rotSeeds(:,1)+widthLimits(2),rotSeeds(:,2)];[rotSeeds(:,1)+widthLimits(2)*2,rotSeeds(:,2)]];

widthFinal = widthLimits(2)*srFinal;
radiusBasal=widthFinal/(2*pi);

%filtering only central cells (it is just to locate which are going to be
%interesting later for us.
cellsToStudyX = find(round(triSeeds(:,1),3)>=round(widthLimits(2),3) & round(triSeeds(:,1),3)<=round(widthLimits(2)*2,3));
cellsToStudyY = find(round(triSeeds(:,2),3)>=round(heightLimits(1),3) & round(triSeeds(:,1),3)<=round(heightLimits(2),3));
cellsToStudy =intersect(cellsToStudyX,cellsToStudyY);

%define cell to save pointCloud
coordCellsVoronoi = cell(max(cellsToStudy),1);
coordCellsFrusta = cell(max(cellsToStudy),1);


%% Construct Voronoi layers iteratively from SR = 1 to outer layer surface ratio (srFinal)
for SR = 1:(srFinal-1)/numberOfSrSpaces:srFinal

    %modify the X position (trasverse axis) of the seeds in relation to the
    %value of the surface ratio.
    triSeedsPerSR = [triSeeds(:,1)*SR,triSeeds(:,2)];

%     %Voronoi diagram
%     [vx,vy]=voronoi(triSeedsPerSR(:,1),triSeedsPerSR(:,2));
%     ylim(heightLimits)
%     updatedWidthLimits = [widthLimits(2)*SR,(widthLimits(2)*2)*SR];
%     xlim(updatedWidthLimits)
%     axis equal

    % get Delaunay triangulation
    DT = delaunayTriangulation(triSeedsPerSR);

    %DT.circumcenter define the vertices of the
    %Voronoi cells. And DT.ConnectivityList the ID of the cells which are connecting.
    tri_Voronoi = DT.ConnectivityList;
    verticesTRI_Voronoi = DT.circumcenter;  
    
    if SR==1
        tri_frusta = tri_Voronoi;
        %here we defined the vertices of frusta, that only match with the
        %Voronoi tube in the initial SR.
        verticesTRI_frustaInit = verticesTRI_Voronoi;
        verticesTRI_frusta=verticesTRI_frustaInit;
    end
    
    %We update te vertices of frusta just multiplying the X coordinates
    %of their cell vertices (trasverse) per the SR value.
    verticesTRI_frusta(:,1)=verticesTRI_frustaInit(:,1)*SR;
    
    %this is just to augment the density of cell solid in the external layers
    if SR==1 || SR==srFinal
        ppa=ppaDefault*100;
    else
        ppa=ppaDefault;
    end
    
    %% We store the coordinates of the body cells individually
    for nCell = cellsToStudy(1):cellsToStudy(end)
        
        %get coordinates per cell slice, converting 2D to 3D coordinates
        coordsCellVor = storeCoordsPerSlices3DCells(nCell,tri_Voronoi,verticesTRI_Voronoi,widthLimits,heightLimits,SR,radiusBasal,ppa,spacedQueryEdges);
        coordsCellFrusta = storeCoordsPerSlices3DCells(nCell,tri_frusta,verticesTRI_frusta,widthLimits,heightLimits,SR,radiusBasal,ppa,spacedQueryEdges);

        %filtering only the coordinates of interest (central region)
        if nCell>size(rotSeeds,1)*2
            coordCellsVoronoi{nCell-size(rotSeeds,1)*2}=[vertcat(coordCellsVoronoi{nCell-size(rotSeeds,1)*2});coordsCellVor];
            coordCellsFrusta{nCell-size(rotSeeds,1)*2}=[vertcat(coordCellsFrusta{nCell-size(rotSeeds,1)*2});coordsCellFrusta];
        else
            if nCell<=size(rotSeeds,1)
                coordCellsVoronoi{nCell}= [vertcat(coordCellsVoronoi{nCell});coordsCellVor];
                coordCellsFrusta{nCell}=[vertcat(coordCellsFrusta{nCell});coordsCellFrusta];
            else
                coordCellsVoronoi{nCell-size(rotSeeds,1)}= [vertcat(coordCellsVoronoi{nCell-size(rotSeeds,1)});coordsCellVor];
                coordCellsFrusta{nCell-size(rotSeeds,1)}= [vertcat(coordCellsFrusta{nCell-size(rotSeeds,1)});coordsCellFrusta];
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

%%remove some non-valid cells in Voronoi
maxPoints=max(cellfun(@(x) size(x,1), coordCellsVoronoi));
idCell2Delete = cellfun(@(x) size(x,1)<maxPoints/5, coordCellsVoronoi);
coordCellsVoronoi(idCell2Delete)=[];

%%remove some non-valid cells in Frusta
maxPoints=max(cellfun(@(x) size(x,1), coordCellsFrusta));
idCell2Delete = cellfun(@(x) size(x,1)<maxPoints/5, coordCellsFrusta);
coordCellsFrusta(idCell2Delete)=[];

%% Save cells as ".ply"
coordCellsVoronoi_unique = cellfun(@(x) unique(x,'rows'),coordCellsVoronoi,'UniformOutput',false);
coordCellsFrusta_unique = cellfun(@(x) unique(x,'rows'),coordCellsFrusta,'UniformOutput',false);

path2save = fullfile('data','hexagonalVoronoiTube',['regularHexaTube_row' num2str(nRowsSeeds) '_column' num2str(nColumnsSeeds)]);
mkdir(path2save)

save(fullfile(path2save,'coordinatesIndCells_voronoi.mat'),'coordCellsVoronoi_unique')
save(fullfile(path2save,'coordinatesIndCells_frusta.mat'),'coordCellsFrusta_unique')
for nCell=1:length(coordCellsVoronoi_unique)
    if ~isempty(coordCellsVoronoi_unique{nCell})
        pcwrite(pointCloud(coordCellsVoronoi_unique{nCell}),fullfile(path2save,['cellID_' num2str(nCell) '_Voronoi.ply']))
        shp= alphaShape(coordCellsVoronoi_unique{nCell});
        [F,V]=shp.boundaryFacets;
        stlwrite(fullfile(path2save,['cellID_' num2str(nCell) 'onlySurface_Voronoi.stl']),F,V)
    end
    
    if ~isempty(coordCellsFrusta_unique{nCell})
        pcwrite(pointCloud(coordCellsFrusta_unique{nCell}),fullfile(path2save,['cellID_' num2str(nCell) '_Frusta.ply']))
        shp= alphaShape(coordCellsFrusta_unique{nCell});
        [F,V]=shp.boundaryFacets;
        stlwrite(fullfile(path2save,['cellID_' num2str(nCell) 'onlySurface_Frusta.stl']),F,V)
    end
end

