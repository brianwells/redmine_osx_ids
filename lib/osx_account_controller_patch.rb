require_dependency 'account_controller'

module OsxAccountControllerPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      alias_method :successful_authentication_without_osx, :successful_authentication unless method_defined?(:successful_authentication_without_osx)
      alias_method :successful_authentication, :successful_authentication_with_osx
    end
  end
  
  module ClassMethods
    # nothing for now
  end
  
  module InstanceMethods
  
    def successful_authentication_with_osx(user)
      # check to see if access is resticted
      if user.auth_source && user.auth_source.restrict_access? && user.groups.empty? && !user.admin?
        # no soup for you!
        flash.now[:error] = l(:notice_account_no_groups)
      else
        successful_authentication_without_osx(user)
      end
    end
        
  end
end
