require_dependency 'auth_sources_controller'

module OsxAuthSourcesControllerPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      alias_method :new_without_osx, :new unless method_defined?(:new_without_osx)
      alias_method :new, :new_with_osx
      alias_method :create_without_osx, :create unless method_defined?(:create_without_osx)
      alias_method :create, :create_with_osx
      helper :auth_sources_osx
    end
  end
  
  module ClassMethods
    # nothing for now
  end
  
  module InstanceMethods
  
    def new_with_osx
      if params[:type] == "AuthSourceOsx"
        @auth_source = AuthSourceOsx.new
      else
        new_without_osx
      end
    end

    def create_with_osx
      if params[:auth_source][:type] == "AuthSourceOsx"
        @auth_source = AuthSourceOsx.new(params[:auth_source])
        if @auth_source.save
          flash[:notice] = l(:notice_successful_create)
          redirect_to :action => 'list'
        else
          render :action => 'new'
        end
      else
        create_without_osx
      end
    end
    
  end
end
