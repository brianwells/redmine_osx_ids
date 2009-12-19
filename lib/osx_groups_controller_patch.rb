require_dependency 'groups_controller'

module OsxGroupsControllerPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      alias_method :new_without_osx, :new unless method_defined?(:new_without_osx)
      alias_method :new, :new_with_osx
      alias_method :create_without_osx, :create unless method_defined?(:create_without_osx)
      alias_method :create, :create_with_osx
      alias_method :edit_without_osx, :edit unless method_defined?(:edit_without_osx)
      alias_method :edit, :edit_with_osx
      alias_method :update_without_osx, :update unless method_defined?(:update_without_osx)
      alias_method :update, :update_with_osx
    end
  end
  
  module ClassMethods
    # nothing for now
  end
  
  module InstanceMethods
  
    def new_with_osx
      @auth_sources = AuthSource.find(:all)
      new_without_osx
    end
    
    def create_with_osx
      @auth_sources = AuthSource.find(:all)
      create_without_osx
    end

    def edit_with_osx
      @auth_sources = AuthSource.find(:all)
      edit_without_osx
    end

    def update_with_osx
      @auth_sources = AuthSource.find(:all)
      update_without_osx
    end
    
  end
end
