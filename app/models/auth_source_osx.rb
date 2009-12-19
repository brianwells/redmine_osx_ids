require 'osx/cocoa'
OSX.require_framework 'Collaboration'

class AuthSourceOsx < AuthSource 

  unloadable

  AUTHORITY_DEFAULT   = "default"
  AUTHORITY_MANAGED   = "managed"
  AUTHORITY_LOCAL     = "local"
  
  AUTHORITIES = { AUTHORITY_DEFAULT => { :name => :label_osx_auth_default, :order => 1 },
                  AUTHORITY_MANAGED => { :name => :label_osx_auth_managed, :order => 2 },
                  AUTHORITY_LOCAL   => { :name => :label_osx_auth_local,   :order => 3 },
                }.freeze

  validates_presence_of :osx_identity_authority
  validates_length_of :name, :maximum => 60, :allow_nil => false

  def authenticate(login, password)
    return nil if login.blank? || password.blank?
    attrs = []
    # get authority
    authority = authority_for_name!(self.osx_identity_authority)
    # search for user
    identity = OSX::CBIdentity.identityWithName_authority(login, authority)
    return nil if identity.nil? || !identity.is_a?(OSX::CBUserIdentity)
    # get attributes if creating new user
    if onthefly_register?
      first, last = fullname_to_first_last(fullname_for_identity(identity))
      attrs = [:firstname => first,
               :lastname => last,
               :mail => mail_for_identity(identity),
               :auth_source_id => self.id]
    end
    # authenticate user
    return nil unless identity.authenticateWithPassword(password)
    # return attributes
    attrs
  end

  def auth_method_name
    "Mac OS X Identity Services"
  end

  def test_connection
    authority = authority_for_name!(self.osx_identity_authority)
    # also check groups
    self.groups.each do |group|
      if self.reference_for_group_name(group.lastname).nil?
        raise "Identity Services Group \"#{group.lastname}\" not found"
      end  
    end
  end
  
  def reference_for_group_name(name)
    group = OSX::CBIdentity.identityWithName_authority(name, authority_for_name!(self.osx_identity_authority))
    group.is_a?(OSX::CBGroupIdentity) ? Base64.encode64(group.persistentReference.rubyString) : nil
  end
  
  def reference_for_user_name(name)
    user = OSX::CBIdentity.identityWithName_authority(name, authority_for_name!(self.osx_identity_authority))
    user.is_a?(OSX::CBUserIdentity) ? Base64.encode64(user.persistentReference.rubyString) : nil
  end
  
  def user_in_group(user, group)
    user_identity = nil
    group_identity = nil
    
    if user.auth_source_ref
      user_identity = OSX::CBIdentity.identityWithPersistentReference_(
                        OSX::NSData.dataWithBytes_length(
                          Base64.decode64(user.auth_source_ref)))
    end
    unless user_identity
      user_identity = OSX::CBIdentity.identityWithName_authority(user.login,
                        authority_for_name(self.osx_identity_authority))
    end
  
    if group.auth_source_ref
      group_identity = OSX::CBIdentity.identityWithPersistentReference_(
                         OSX::NSData.dataWithBytes_length(
                           Base64.decode64(group.auth_source_ref)))
    end
    unless group_identity
      group_identity = OSX::CBIdentity.identityWithName_authority(group.lastname,
                         authority_for_name(self.osx_identity_authority))
    end
    
    user_identity.is_a?(OSX::CBUserIdentity) && 
    group_identity.is_a?(OSX::CBGroupIdentity) &&
    user_identity.isMemberOfGroup_(group_identity)
  end

  private

  def group_for_name!(group_name, authority)
    group = group_for_name(group_name, authority)
    raise "Identity Services Group \"#{group_name}\" not found" if group.nil?
    group
  end

  def group_for_name(group_name, authority)
      group = OSX::CBIdentity.identityWithName_authority(group_name, authority)
      group.is_a?(OSX::CBGroupIdentity) ? group : nil
  end
  
  def authority_for_name!(auth_name)
    authority = authority_for_name(auth_name)
    raise "Identity Services Authority \"#{auth_name}\" not found" if authority.nil?
    authority
  end
  
  def authority_for_name(auth_name)
    case auth_name
    when AUTHORITY_DEFAULT: OSX::CBIdentityAuthority.defaultIdentityAuthority
    when AUTHORITY_MANAGED: OSX::CBIdentityAuthority.managedIdentityAuthority
    when AUTHORITY_LOCAL: OSX::CBIdentityAuthority.localIdentityAuthority
    else nil
    end
  end
  
  def fullname_for_identity(identity)
    fullname = identity.fullName
    fullname && fullname.to_ruby 
  end
  
  def mail_for_identity(identity)
    email = identity.emailAddress
    return nil if email.nil?
    preferred_email = email.to_ruby
    if self.prefer_local_email       # try for local address if possible
      user_aliases = identity.aliases.to_ruby
      host_parts = Socket.gethostname.split(".")
      while host_parts.size > 1
        suffix = "@" + host_parts.join(".")
        user_aliases.each do |a|
          if a[-suffix.length, suffix.length] == suffix
            preferred_email = a
            break
          end
        end
        host_parts.delete_at(0)
      end
    end
    preferred_email
  end  

  def part_is_suffix(part)
    @@suffixes ||= [ "JR.", "SR.", "JR", "SR", "II", "III", "3RD","IV", "V", "VI", "VII" ]
    @@suffixes.include?(part.upcase)
  end

  def part_is_lastname(part)
    @@lastnames ||= [ "DE", "DER", "DI", "LA", "LE", "MAC", "MC", "VAN", "VON", "PONCE" ]
    @@lastnames.include?(part.upcase)
  end

  def fullname_to_first_last(fullname)
    return [nil, nil] if fullname.nil?
    
    suffix = nil
    firstname = ""
    lastname = ""
    
    # split on comma
    parts = fullname.split(",").map { |i| i.strip }
    
    # got at least one comma - check for suffix
    if parts.size > 1 && part_is_suffix(parts[-1])
      suffix = ", " + parts.slice!(-1)
    end

    if parts.size == 1
      firstparts = []
      lastparts = []
      # need to determine where first and last name splits
      parts = parts.first.split(" ")
      if parts.size == 1
        firstname = parts.first
      else
        # take care of suffix (if any)
        if parts.size > 1 && part_is_suffix(parts[-1])
          suffix = " " + parts.slice!(-1)
        end
        # last name
        if parts.size > 0
          lastparts.unshift(parts.slice!(-1))
        end
        # first name
        if parts.size > 0
          firstparts.push(parts.slice!(0))
        end
        # all the rest
        while parts.size > 0 && part_is_lastname(parts.slice(-1))
          lastparts.unshift(parts.slice!(-1))
        end
        # make strings
        firstparts.push(parts) if parts.size > 0
        firstname = firstparts.join(" ")
        firstname += suffix unless suffix.nil?
        lastname = lastparts.join(" ")
      end
    elsif parts.size > 1
      # now have last, first
      lastname = parts.slice!(0)
      firstname = parts.join(", ")
      firstname += suffix unless suffix.nil?
    end
    [firstname, lastname]
  end

end
