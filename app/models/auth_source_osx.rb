
class AuthSourceOsx < AuthSource

  unloadable

  validates_presence_of :osx_node_name
  before_save :set_host_name

  FN = "dsAttrTypeStandard:FirstName"
  LN = "dsAttrTypeStandard:LastName"
  EM = "dsAttrTypeStandard:EMailAddress"

  def authenticate(login, password)
    return nil if login.blank? || password.blank?
    attrs = {}
    # find user
    guid = OpenDirectory.userGUID(login,self.osx_node_name)
    return nil if guid.nil?
    # get attributes if creating new user
    if onthefly_register?
        attr_types = [FN,LN,EM]
        od_attrs = OpenDirectory.userAttributes(guid,attr_types,self.osx_node_name)
        attrs = {:firstname => (od_attrs.include?(FN) ? od_attrs[FN].first : ""),
                 :lastname => (od_attrs.include?(LN) ? od_attrs[LN].first : ""),
                 :mail => (od_attrs.include?(EM) ? od_attrs[EM].first : ""),
                 :osx_record_guid => guid,
                 :auth_source_id => self.id}
    end
    #authenticate user
    return nil unless OpenDirectory.authenticatedUser(guid,password,self.osx_node_name)
    # return attributes
    attrs
  end
  
  def auth_method_name
    "Mac OS X"
  end

  def test_connection
    if OpenDirectory.nodeDetails(self.osx_node_name).nil?
        raise "Open Directory Node \"#{self.osx_node_name}\" not found"
    end
    # also check groups
    self.groups.each do |group|
      if OpenDirectory.groupGUID(group.lastname).nil?
        raise "Open Directory Group \"#{group.lastname}\" not found"
      end  
    end
  end
  
  def self.allow_password_changes?
    false
  end

  def guid_for_group_name(name)
    OpenDirectory.groupGUID(name,self.osx_node_name)
  end

  def guid_for_user_name(name)
    OpenDirectory.userGUID(name,self.osx_node_name)
  end

  def user_in_group(user, group)
    OpenDirectory.groupContainsUser(group.osx_record_guid || group.login, user.osx_record_guid || user.login, self.osx_node_name)
  end

  private
  
  def set_host_name
    self.host = self.osx_node_name
  end

end
