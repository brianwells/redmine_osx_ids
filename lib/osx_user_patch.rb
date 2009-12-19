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
          ref = model.auth_source.reference_for_user_name(value)
          if ref
            model.auth_source_ref = ref
          else
              model.errors.add(attr, l(:user_not_found))
          end
        else
          # fix auth_source_ref
          model.auth_source_ref = nil
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
