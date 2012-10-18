class OsxGroupsIndexViewHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context={})
    cc = context[:controller]
    if cc.controller_name == 'groups' && cc.action_name == 'index'
      code = []
      code << "var auth_source_label = '#{l(:label_auth_source)}';"
      code << "var auth_sources_groups = new Array();"
      for group in Group.all
        code << "auth_sources_groups.push(new Array('#{cc.view_context.edit_group_path(group)}','#{group.auth_source ? group.auth_source.name : l(:label_internal)}'));"
      end
      data = javascript_tag code.join("\n")
      script = javascript_include_tag 'osx_groups_index', :plugin => 'redmine_osx_ids'
      "#{data}#{script}"
    end
  end
end