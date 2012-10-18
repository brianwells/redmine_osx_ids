
class OsxAuthSourcesIndexViewHook < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context={})
    cc = context[:controller]
    if cc.controller_name == 'auth_sources' && cc.action_name == 'index'
      unless @auth_source_classes
        # load models
        Dir["#{Rails.root}/app/models/*.rb","#{Rails.root}/plugins/*/app/models/*.rb"].map do |f|
          File.basename(f, '.*').camelize.constantize
        end
      end
      @auth_source_classes ||= AuthSource.descendants.sort { |a,b| a.new.auth_method_name <=> b.new.auth_method_name }
      code = []
      code << "var auth_source_host_label = '#{l(:field_host)}';"
      code << "var auth_source_hostnode_label = '#{l(:field_host)}/#{l(:field_osx_node_name)}';"
      code << "var auth_source_groups_label = '#{l(:label_group_plural)}';"
      code << "var auth_source_new_path = '#{cc.new_auth_source_path}';"
      code << "var auth_source_new_label = '#{l(:label_auth_source_new)}';"
      code << "var auth_source_classes = new Array();"
      for source_class in @auth_source_classes
        code << "auth_source_classes.push(new Array('#{source_class.new.auth_method_name}','#{source_class.name}'));"
      end
      code << "var auth_sources = new Array();"
      for source in AuthSource.all
        code << "auth_sources.push(new Array(#{source.id},#{source.groups.count},#{source.users.any? || source.groups.any?}));"
      end
      data = javascript_tag code.join("\n")
      script = javascript_include_tag 'osx_auth_sources_index', :plugin => 'redmine_osx_ids'
      "#{data}#{script}"
    end
  end
end
