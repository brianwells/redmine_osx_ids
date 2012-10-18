
# make sure RubyInline puts compiled code with Redmine
if Rails.env.production?
  ENV['INLINEDIR'] =  Rails.root.join("tmp").to_s
end

require_dependency 'open_directory'

ActionDispatch::Callbacks.to_prepare do
  # use require_dependency if you plan to utilize development mode
  require_dependency 'osx_application_controller_patch'
  require_dependency 'osx_account_controller_patch'
  require_dependency 'osx_auth_sources_controller_patch'
  require_dependency 'osx_auth_source_patch'
  require_dependency 'osx_user_patch'
  require_dependency 'osx_group_patch'
end

require_dependency 'osx_auth_sources_index_view_patch'
require_dependency 'osx_groups_index_view_patch'
require_dependency 'osx_groups_edit_view_patch'
require_dependency 'osx_users_edit_view_patch'


Redmine::Plugin.register :redmine_osx_ids do
  name 'OS X Open Directory plugin'
  author 'Brian D. Wells'
  author_url 'http://www.briandwells.com'
  description 'A plugin for authenticating with Mac OS X Open Directory'
  version '2.0.0'
  requires_redmine :version_or_higher => '2.0.0'
  url 'https://github.com/brianwells/redmine_osx_ids'
  menu :admin_menu, :external_authentication, { :controller => 'auth_sources', :action => 'index'}, :caption => :label_external_authentication, :html => { :class => 'server_authentication' }, :after => :ldap_authentication
  delete_menu_item :admin_menu, :ldap_authentication
end

# patches to Redmine
Rails.configuration.to_prepare do

end
