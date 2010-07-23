
ActionController::Routing::Routes.draw do |map|
    map.auth_source_osx "/osx_auth_sources/edit/:id", :controller => "osx_auth_sources", :action => "edit"
end
