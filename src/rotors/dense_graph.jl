function dense_graph(g, d)
    
    @showprogress for v in vertices(g)
        for u in neighborhood(g, v, d)
            add_edge!(g, u, v, d)
        end
    end

end
