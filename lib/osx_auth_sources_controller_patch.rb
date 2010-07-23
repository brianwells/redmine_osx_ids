require_dependency 'auth_sources_controller'

module OsxAuthSourcesControllerPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      alias_method :index_without_osx, :index unless method_defined?(:index_without_osx)
      alias_method :index, :index_with_osx
      helper :auth_sources_osx
    end
  end
  
  module ClassMethods
    # nothing for now
  end
  
  module InstanceMethods
  
    def index_with_osx
      @auth_source_name = auth_source_class.new.auth_method_name
      index_without_osx
    end

  end
end
