module AuthSourcesOsxHelper

  def collection_for_identity_authority_select
    values = AuthSourceOsx::AUTHORITIES
    values.keys.sort{|x,y|
      values[x][:order] <=> values[y][:order]
    }.collect{|k| 
      [l(values[k][:name], :local_host => Socket.gethostname.split(".").first ), k]
    }
  end

end
