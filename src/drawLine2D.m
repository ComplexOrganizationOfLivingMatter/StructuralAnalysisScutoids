function [xyCoordinates]=drawLine2D(x0,y0,x1,y1,spacedQuery)

    distanceEdge = sqrt((x0- x1)^2 + (y0-y1)^2);
    nSteps =round(distanceEdge/spacedQuery);
    xyCoordinates=zeros(nSteps+1,2);
    c = 1;
    for n = 0:1/nSteps:1 
        xyCoordinates(c,:) = [(x0 +(x1 - x0)*n),(y0 +(y1 - y0)*n)]; 
        c=c+1;
    end

end