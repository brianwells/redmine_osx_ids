require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

module OsxPrincipalPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
    end
  end
  
  module ClassMethods
    # nothing for now
  end
  
  module InstanceMethods
    # nothing for now
  end
end

module OsxUserPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable

      validates_each :login do |model, attr, value|
        if model.auth_source
          # check to see if auth_source recognizes the user
          guid = model.auth_source.guid_for_user_name(value)
          if guid
            model.osx_record_guid = guid
          else
              model.errors.add(attr, l(:user_not_found))
          end
        else
          # fix osx_record_guid
          model.osx_record_guid = nil
        end
      end

      after_save :update_external_users

    end
  end
  
  module ClassMethods
    
  end
  
  module InstanceMethods

    # user should not be in any auth_source groups that it is not a member
    def update_external_users
      Group.all(:joins => :auth_source ).each do |g|
        g.update_external_users([ self ])
      end
    end

  end
  
end

unless Principal.included_modules.include? OsxPrincipalPatch
  Principal.send(:include, OsxPrincipalPatch)
end
unless User.included_modules.include? OsxUserPatch
  User.send(:include, OsxUserPatch)
end
