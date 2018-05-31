module TableShowUtils

function printtable(io::IO, source, typename::AbstractString; force_unknown_rows=false)
    T = eltype(source)

    if force_unknown_rows
        rows = nothing
        data = Iterators.take(source, 10) |> collect
    elseif Base.iteratorsize(source)==Base.HasLength()
        rows = length(source)
        data = Iterators.take(source, 10) |> collect
    else
        data_plus_one = Iterators.take(source, 11) |> collect
        if length(data_plus_one)<11
            rows = length(data_plus_one)
            data = data_plus_one
        else
            rows = nothing
            data = data_plus_one[1:10]
        end
    end

    cols = length(T.parameters)

    println(io, "$(rows===nothing ? "?" : rows)x$(cols) $typename")

    colnames = String.(fieldnames(eltype(source)))

    data = [r==0 ? colnames[c] : isa(data[r][c], AbstractString) ? data[r][c] : sprint(io->showcompact(io,data[r][c])) for r in 0:length(data), c in 1:cols]

    maxwidth = [maximum(length.(data[:,c])) for c in 1:cols]

    available_heigth, available_width = displaysize(io)
    available_width -=1 

    shortened_rows = Set{Int}()

    while sum(maxwidth) + (size(data,2)-1) * 3 > available_width
        if size(data,2)==1
            for r in 1:size(data,1)
                if length(data[r,1])>available_width
                    data[r,1] = data[r,1][1:chr2ind(data[r,1],available_width-2)] * "\""
                    push!(shortened_rows, r)
                end
            end
            maxwidth[1] = available_width
            break
        else
            data = data[:,1:end-1]

            maxwidth = [maximum(length.(data[:,c])) for c in 1:size(data,2)]
        end
    end

    for c in 1:size(data,2)
        print(io, rpad(colnames[c], maxwidth[c]))
        if c<size(data,2)
            print(io, " │ ")
        end
    end
    println(io)
    for c in 1:size(data,2)
        print(io, repeat("─", maxwidth[c]))
        if c<size(data,2)
            print(io, "─┼─")
        end
    end      
    for r in 2:size(data,1)
        println(io)
        for c in 1:size(data,2)
            
            if r in shortened_rows
                print(io, data[r,c],)
                print(io, "…")
            else
                print(io, rpad(data[r,c], maxwidth[c]))
            end
            if c<size(data,2)
                print(io, " │ ")
            end
        end
    end        

    if rows===nothing
        row_post_text = "more rows"
    elseif rows > size(data,1)-1
        extra_rows = rows - 10
        row_post_text = "$extra_rows more $(extra_rows==1 ? "row" : "rows")"
    else
        row_post_text = ""
    end

    if size(data,2)!=cols
        extra_cols = cols-size(data,2)
        col_post_text = "$extra_cols more $(extra_cols==1 ? "column" : "columns"): "
        col_post_text *= Base.join([colnames[cols-extra_cols+1:end]...], ", ")
    else
        col_post_text = ""
    end

    if !isempty(row_post_text) || !isempty(col_post_text)
        println(io)
        print(io,"... with ")
        if !isempty(row_post_text)
            print(io, row_post_text)
        end
        if !isempty(row_post_text) && !isempty(col_post_text)
            print(io, ", and ")
        end
        if !isempty(col_post_text)
            print(io, col_post_text)
        end
    end
end

function printHTMLtable(io, source; force_unknown_rows=false)
    colnames = String.(fieldnames(eltype(source)))

    max_elements = 10

    if force_unknown_rows
        rows = nothing
    elseif Base.iteratorsize(source)==Base.HasLength()
        rows = length(source)
    else
        count_needed_plus_one =  Iterators.count(i->true, Iterators.take(source, max_elements+1))
        rows = count_needed_plus_one<max_elements+1 ? count_needed_plus_one : nothing
    end

    haslimit = get(io, :limit, true)
    
    # Header
    print(io, "<table>")
    print(io, "<thead>")
    print(io, "<tr>")
    for c in colnames
        print(io, "<th>")
        print(io, c)
        print(io, "</th>")
    end
    print(io, "</tr>")
    print(io, "</thead>")    

    # Body
    print(io, "<tbody>")
    count = 0
    for r in Iterators.take(source, max_elements)
        count += 1
        print(io, "<tr>")
        for c in values(r)
            print(io, "<td>")
            Base.Markdown.htmlesc(io, sprint(i->showcompact(i,c)))
            print(io, "</td>")
        end
        print(io, "</tr>")
    end    

    if rows==nothing
        row_post_text = "... with more rows."            
    elseif rows > max_elements
        extra_rows = rows - max_elements
        row_post_text = "... with $extra_rows more $(extra_rows==1 ? "row" : "rows")."
    else
        row_post_text = ""
    end

    if !isempty(row_post_text)
        print(io, "<tr>")
        for c in colnames
            print(io, "<td>&vellip;</td>")
        end
        print(io, "</tr>")
    end

    print(io, "</tbody>")

    print(io, "</table>")

    if !isempty(row_post_text)
        print(io, "<p>")
        Base.Markdown.htmlesc(io, row_post_text)
        print(io, "</p>")
    end
end

end # module
