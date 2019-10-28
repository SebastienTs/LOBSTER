%       function flags = PointsInEllipse(P,A,C,tol)
%       Returns flags for each point indicating whether it is inside (1)
%       or outside an ellipsoid
%
%       Input arguments
% P:    Points coordinates (columns by columns)
% A,C:  Ellispoid in normalized form
% tol:  Tolerance (added to normalized radius for test)

function flags = PointsInEllipse(P,A,C,tol)

    flags = diag((P-repmat(C,1,size(P,2)))'*A*(P-repmat(C,1,size(P,2)))) <= (1+tol)