require_dependency 'application_controller'

module OsxApplicationControllerPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      alias_method :find_current_user_without_osx, :find_current_user unless method_defined?(:find_current_user_without_osx)
      alias_method :find_current_user, :find_current_user_with_osx
    end
  end
  
  module ClassMethods
    # nothing for now
  end
  
  module InstanceMethods
  
    def find_current_user_with_osx
      if session[:user_id]
        find_current_user_without_osx
      else
        # either auto-login or rss key authentication
        user = find_current_user_without_osx
        user.update_external_users unless user.nil?
        user
      end
    end
        
  end
end

unless ApplicationController.included_modules.include? OsxApplicationControllerPatch
  ApplicationController.send(:include, OsxApplicationControllerPatch)
end


