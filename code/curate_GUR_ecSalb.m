%script that performs sensitivity analysis on Kcats over acetate production 
load('ecModel_GEM_salb_naringenin.mat')
model = ecModel;
constrained = set_salb_media(model,1);
sol = solveLP(constrained);
objValue = sol.x(find(model.c));
%find objective 
bioPos = find(model.c);


targetRxn = find(contains(model.rxns,'EX_glc__D_e'));
expValue  = 1;
enzMetPos = find(startsWith(model.mets,'prot_WP'));
rxns = 1:numel(model.rxns);
metRxns = find(~startsWith(model.rxns,'usage_prot_') & ~startsWith(model.rxns,'prot_pool_exchange'));
enzRxns = find(startsWith(model.rxns,'usage_prot_') | startsWith(model.rxns,'prot_pool_exchange'));
rxns = setdiff(rxns,enzRxns);
enzymes = model.ec.enzymes;
enzymes = unique(enzymes);
coefficients = zeros(numel(enzymes),numel(rxns));
perturbation = 0.01;
for i=1:(numel(enzymes))
    enz_i_pos = find(contains(model.metNames,enzymes{i}));
    enz_i_pos = enz_i_pos(1);
    enz_i_rxns= find(model.S(enz_i_pos,:));
    enz_i_rxns = setdiff(enz_i_rxns,enzRxns);
    temp = constrained;
    for j=1:numel(enz_i_rxns)
        previousCoeff = temp.S(enz_i_pos,enz_i_rxns(j));
        temp = setParam(temp,'obj',targetRxn,1);
        temp.lb(bioPos) = 0.9999*objValue;
        temp.ub(bioPos) = objValue;
        sol_prev = solveLP(temp);
        temp.S(enz_i_pos,enz_i_rxns(j)) = previousCoeff/perturbation;
        sol_j = solveLP(temp);
        if ~isempty(sol_prev.x) & ~isempty(sol_j.x)
        sensitivity = (sol_j.x(targetRxn)-sol_prev.x(targetRxn))/(perturbation*sol_prev.x(targetRxn));
        if sensitivity>1E-3
            coefficients(i,enz_i_rxns(j)) = sensitivity;
        end
        end
    end
end
