function ObjsInds = WanderLnks(Indx,Lnks)

    Queue = [Lnks{Indx}];    
    ObjsInds = [Indx Queue];

    while ~isempty(Queue)
        NxtInds  = unique([Lnks{Queue}]);
        Queue = setdiff(NxtInds,ObjsInds);
        ObjsInds = [ObjsInds Queue];
    end
    
    ObjsInds = sort(ObjsInds);
    
end