function coordsCell = storeCoordsPerSlices3DCells(nCell,triangulations,verticesTri,widthLimits,heightLimits,SR,radiusBasal,ppa,spacedQueryEdges)

        idTriIN=any(triangulations==nCell,2);
        verticesCell=verticesTri(idTriIN,:);
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
%         coordxOut = (pointsIntoCell(:,1)>widthLimits(2)*SR) | (pointsIntoCell(:,1)<widthLimits(1)*SR) ;
        coordyOut = (pointsIntoCell(:,2)>heightLimits(2)) | (pointsIntoCell(:,2)<heightLimits(1)) ;
        pointsIntoCell(coordyOut,:) = [];
        
%         plot(pointsIntoCell(:,1),pointsIntoCell(:,2),'*')

        %Convert to tubular coordinates
        radius=(widthLimits(2)*SR)/(2*pi);
        [xTubeCoord,yTubeCoord,zTubeCoord] = extrapolated2dCoordinatesTo3dTube(radius,radiusBasal,widthLimits(2)*SR,pointsIntoCell(:,1),pointsIntoCell(:,2));
%         plot3(xTubeCoord,yTubeCoord,zTubeCoord,'*')
%         hold on

        coordsCell = [xTubeCoord,yTubeCoord,zTubeCoord];
        

end

