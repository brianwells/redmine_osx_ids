require_dependency 'auth_sources_controller'

module OsxAuthSourcesControllerPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      menu_item :external_authentication
      helper :auth_source_osx
    end
  end
  
  module ClassMethods
    # nothing for now
  end
  
  module InstanceMethods
    # nothing for now
  end
end

unless AuthSourcesController.included_modules.include? OsxAuthSourcesControllerPatch
  AuthSourcesController.send(:include, OsxAuthSourcesControllerPatch)
end
  