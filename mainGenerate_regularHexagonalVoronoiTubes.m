clear all

addpath(genpath('src'))

%Theoretical SR in with basal get a rotated but regular tessellation of
%hexagons
sideHexagon = 10;nRowsSeeds=9;nColumnsSeeds=5;angleRot=0;

numberOfSrSpaces = 30;
%basal surface ratio. 8/3 is just the theoretica SR when hexagonal lattice
%get rotated 90 from apical base, being perfect regular hexagonal pieces
srFinal=8/3;

[rotSeeds,indCentralSeed] =generateSeedsOfRegularVoronoiHexagonalLattice(sideHexagon,nRowsSeeds,nColumnsSeeds-1,angleRot);

%x distances
unXPos = unique(rotSeeds(:,1));
widthLimits = [min(rotSeeds(:,1)),max(rotSeeds(:,1))+(unXPos(2)-unXPos(1))];
heightLimits = [min(rotSeeds(:,2)),max(rotSeeds(:,2))];

%triplicate seeds laterally
triSeeds = [rotSeeds; [rotSeeds(:,1)+widthLimits(2),rotSeeds(:,2)];[rotSeeds(:,1)+widthLimits(2)*2,rotSeeds(:,2)]];

widthFinal = widthLimits(2)*srFinal;
radiusBasal=widthFinal/(2*pi);

cellsToStudy = find(round(triSeeds(:,1),3)>=round(widthLimits(2),3) & round(triSeeds(:,1),3)<=round(widthLimits(2)*2,3));

SRtoStudy = 1:(srFinal-1)/numberOfSrSpaces:srFinal;
coordCells = cell(size(rotSeeds,1),length(SRtoStudy));

%points per unit of area (density of point cloud)
ppa=10;
spacedQueryEdges=sideHexagon/100;
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
    tri = DT.ConnectivityList;
    verticesTRI = DT.circumcenter; 

    %select only central region
    idTRI = round(verticesTRI(:,1),3)>=round(widthLimits(2)*SR,3) & round(verticesTRI(:,1),3)<=round(widthLimits(2)*2*SR,3);
    verticesIN = verticesTRI(idTRI,:);
    triOfInterestIN = tri(idTRI,:);  
    
    % voronoi(triSeeds(:,1),triSeeds(:,2));hold on
    

    for nCell = cellsToStudy(1):cellsToStudy(end)
        idTriIN=any(triOfInterestIN==nCell,2);
        if sum(idTriIN)>2
            verticesCell=verticesIN(idTriIN,:);
            %%get spaced points between all the vertices
            k = convhull(verticesCell(:,1),verticesCell(:,2));
            newVertOrder = verticesCell(k,:);
            xyCoord=cell(sum(idTriIN),1);
            inPoints = polygrid( newVertOrder(:,1), newVertOrder(:,2), ppa);
            for nEdges = 1:sum(idTriIN)
               xyCoord{nEdges} = drawLine2D(newVertOrder(nEdges,1),newVertOrder(nEdges,2),newVertOrder(nEdges+1,1),newVertOrder(nEdges+1,2),spacedQueryEdges);
            end

            pointsIntoCell =[verticesCell;inPoints;vertcat(xyCoord{:})];
            pointsIntoCell(:,1) = pointsIntoCell(:,1)-(widthLimits(2)*SR);
    %         plot(pointsIntoCell(:,1),pointsIntoCell(:,2),'*')

            radius=(widthLimits(2)*SR)/(2*pi);
            [xTubeCoord,yTubeCoord,zTubeCoord] = extrapolated2dCoordinatesTo3dTube(radius,radiusBasal,widthLimits(2)*SR,pointsIntoCell(:,1),pointsIntoCell(:,2));
%             plot3(xTubeCoord,yTubeCoord,zTubeCoord,'*')
%             hold on
           
            if nCell>size(rotSeeds,1)*2
                coordCells{nCell-size(rotSeeds,1)*2}=[vertcat(coordCells{nCell-size(rotSeeds,1)*2});[xTubeCoord,yTubeCoord,zTubeCoord]];
            else
                if nCell<=size(rotSeeds,1)
                    coordCells{nCell}= [vertcat(coordCells{nCell});[xTubeCoord,yTubeCoord,zTubeCoord]];
                else
                    coordCells{nCell-size(rotSeeds,1)}= [vertcat(coordCells{nCell-size(rotSeeds,1)});[xTubeCoord,yTubeCoord,zTubeCoord]];
                end
            end
        end

    end

end

%% Save cells as ".ply"
path2save = fullfile('data','hexagonalVoronoiTube');
for nCell=1:length(coordCells)
    if ~isempty(coordCells{nCell})
        pcwrite(pointCloud(coordCells{nCell}),fullfile(path2save,['cellID_' num2str(nCell) '.ply']))
    end
end
