require_dependency 'auth_source'

module OsxAuthSourcePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      has_many :groups
    end
  end
  
  module ClassMethods
    # nothing for now
  end
  
  module InstanceMethods

    def guid_for_group_name(name)
      return nil
    end

    def guid_for_user_name(name)
      return nil
    end

    def user_in_group(user, group)
      return false
    end
    
  end
  
end

unless AuthSource.included_modules.include? OsxAuthSourcePatch
  AuthSource.send(:include, OsxAuthSourcePatch)
end
  
