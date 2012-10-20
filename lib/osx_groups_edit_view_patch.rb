class OsxGroupsEditViewHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context={})
    cc = context[:controller]
    if cc.controller_name == 'groups' && (cc.action_name == 'edit' || cc.action_name == 'new')
      auth_source = cc.instance_eval{ @group.auth_source }
      code = []
      code << "var auth_source_id = '#{auth_source ? auth_source.id : ""}';"
      code << "var auth_source_label = '#{l(:label_auth_source)}';"
      if auth_source
        auth_source_link = cc.view_context.link_to(auth_source.name, cc.view_context.edit_auth_source_path(auth_source))
        code << "var auth_source_managed = '#{l(:users_are_managed_with)} #{auth_source_link}';"
      end
      code << "var auth_sources = new Array();"
      code << "auth_sources.push(new Array('#{l(:label_internal)}',''));"
      for source in AuthSource.all
        code << "auth_sources.push(new Array('#{source.name}',#{source.id},'#{cc.view_context.edit_auth_source_path(source)}'));"
      end
      data = javascript_tag code.join("\n")
      script = javascript_include_tag 'osx_groups_edit', :plugin => 'redmine_osx_ids'
      "#{data}#{script}"
    end
  end
end