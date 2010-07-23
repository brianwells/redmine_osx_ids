class OsxAuthSourcesController < AuthSourcesController
  unloadable
    
  protected
    
  def auth_source_class
    AuthSourceOsx
  end
    
end
