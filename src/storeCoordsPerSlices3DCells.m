function coordsCell = storeCoordsPerSlices3DCells(nCell,triangulations,verticesTri,widthLimits,heightLimits,SR,radiusBasal,ppa,spacedQueryEdges)

        %Get Voronoi cells vertices
        idTriIN=any(triangulations==nCell,2);
        verticesCell=verticesTri(idTriIN,:);
        k = convhull(verticesCell(:,1),verticesCell(:,2));
        newVertOrder = verticesCell(k,:);
        
        %%get spaced points between all the vertices
        xyCoord=cell(sum(idTriIN),1);
        for nEdges = 1:sum(idTriIN)
           xyCoord{nEdges} = drawLine2D(newVertOrder(nEdges,1),newVertOrder(nEdges,2),newVertOrder(nEdges+1,1),newVertOrder(nEdges+1,2),spacedQueryEdges);
        end

        %Get vertices into de cells using a grid density
        inPoints = polygrid( newVertOrder(:,1), newVertOrder(:,2), ppa);

        pointsIntoCell =[verticesCell;inPoints;vertcat(xyCoord{:})];
        pointsIntoCell(:,1) = pointsIntoCell(:,1)-(widthLimits(2)*SR);
%         coordxOut = (pointsIntoCell(:,1)>widthLimits(2)*SR) | (pointsIntoCell(:,1)<widthLimits(1)*SR) ;
        coordyOut = (pointsIntoCell(:,2)>heightLimits(2)) | (pointsIntoCell(:,2)<heightLimits(1)) ;
        pointsIntoCell(coordyOut,:) = [];
        
%         plot(pointsIntoCell(:,1),pointsIntoCell(:,2),'*')

        %Convert X, Y coordinates to tubular coordinates (X, Y, Z)
        radius=(widthLimits(2)*SR)/(2*pi);
        [xTubeCoord,yTubeCoord,zTubeCoord] = extrapolated2dCoordinatesTo3dTube(radius,radiusBasal,widthLimits(2)*SR,pointsIntoCell(:,1),pointsIntoCell(:,2));
%         plot3(xTubeCoord,yTubeCoord,zTubeCoord,'*')
%         hold on

        coordsCell = [xTubeCoord,yTubeCoord,zTubeCoord];
        

end

