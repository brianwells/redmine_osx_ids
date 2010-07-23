require 'redmine'

# Patches to the Redmine core
require 'dispatcher'
Dispatcher.to_prepare :redmine_osx_ids do
  require 'osx_application_controller_patch'
  ApplicationController.send(:include, OsxApplicationControllerPatch)
  require 'osx_account_controller_patch'
  AccountController.send(:include, OsxAccountControllerPatch)
  require 'osx_auth_sources_controller_patch'
  AuthSourcesController.send(:include, OsxAuthSourcesControllerPatch)
  require 'osx_auth_source_patch'
  AuthSource.send(:include, OsxAuthSourcePatch)
  require 'osx_user_patch'
  Principal.send(:include, OsxPrincipalPatch)
  User.send(:include, OsxUserPatch)
  require 'osx_group_patch'
  Group.send(:include, OsxGroupPatch)
  require 'osx_groups_controller_patch'
  GroupsController.send(:include, OsxGroupsControllerPatch)
end

# Hook Listeners
# require 'some_hook'

Redmine::Plugin.register :redmine_osx_ids do
  name 'Mac OS X Identity Services plugin'
  author 'Brian D. Wells'
  author_url 'http://www.briandwells.com'
  description 'A plugin for authenticating with Mac OS X Identity Services'
  version '1.1.0'
  requires_redmine :version_or_higher => '1.0.0'

    menu :admin_menu, :auth_source_osx, { :controller => 'osx_auth_sources', :action => 'index'}, :caption => :label_auth_source_osx }
end
