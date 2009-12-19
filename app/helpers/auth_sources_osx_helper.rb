module AuthSourcesOsxHelper

  def collection_for_identity_authority_select
    values = AuthSourceOsx::AUTHORITIES
    values.keys.sort{|x,y|
      values[x][:order] <=> values[y][:order]
    }.collect{|k| 
      [l(values[k][:name], :local_host => Socket.gethostname.split(".").first ), k]
    }
  end

  def name_for_identity_authority(ref)
    values = AuthSourceOsx::AUTHORITIES
    name = (values[ref][:name])
    name.nil? ? "Unknown" : l(name, :local_host => Socket.gethostname.split(".").first )
  end

end
