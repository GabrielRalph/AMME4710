function tex = mat2textable(mat)
    [r, c] = size(mat);
    
    tex = "";
    for ri = 1:r
        row = convertStringsToChars(sprintf(" %s &", mat(ri, :)));
        row = row(1:(end-1));
        tex = sprintf("%s \\hline %s \\\\", tex, row);
    end
    
    bdp = repmat('|c', 1, c);
    tex = sprintf("\\begin{array}{%s|} %s \\hline \\end{array}", bdp, tex);
end

