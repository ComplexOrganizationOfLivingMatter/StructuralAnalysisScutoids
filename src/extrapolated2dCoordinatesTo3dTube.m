function [xTubeCoord,yTubeCoord,zTubeCoord] = extrapolated2dCoordinatesTo3dTube(radius,radiusBasal,widthLimit,xCoord,yCoord)


    %pixels relocation from cylinder angle
    angleOfCoordLocation=(360/widthLimit)*xCoord;
    
    %% Cylinder coord position: x=R*cos(angle); y=R*sin(angle);
    xTubeCoord = radius*cosd(angleOfCoordLocation)+radiusBasal;
    yTubeCoord = radius*sind(angleOfCoordLocation)+radiusBasal;
    zTubeCoord = yCoord;
end


