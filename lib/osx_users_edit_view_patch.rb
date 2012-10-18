class OsxUsersEditViewHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context={})
    cc = context[:controller]
    if cc.controller_name == 'users' && cc.action_name == 'edit'
      code = []
      code << "var auth_source_groups = new Array();"
      for group in Group.joins(:auth_source)
        code << "auth_source_groups.push(#{group.id});"
      end
      data = javascript_tag code.join("\n")
      script = javascript_include_tag 'osx_users_edit', :plugin => 'redmine_osx_ids'
      "#{data}#{script}"

    end
  end
end
