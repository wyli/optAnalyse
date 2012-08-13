%orthogonalize rows of a matrix. 

function Wort=orthogonalizerows(W)

try
	Wort = real((W*W')^(-0.5))*W;
catch exp
	W(isnan(W)||isinf(W)) = 0; %%convert the weights to zero
	Wort = orthogonalizerows(W);
end
return;
