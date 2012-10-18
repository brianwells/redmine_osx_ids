module AuthSourceOsxHelper

  def collection_for_nodes_select
    nodes = OpenDirectory.nodes.sort.reject{|x| x == "/Contacts" }
    if nodes.include?("/Search")
      nodes.delete("/Search")
      nodes.unshift("/Search")
    end
    nodes.map{|n| [n, n]}
  end
  
end
