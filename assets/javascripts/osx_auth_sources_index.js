// dynamic edit of auth_sources index view
jQuery(function() {
  // inject :econtains function
  $.expr[":"].econtains = function(obj, index, meta, stack){
    return (obj.textContent || obj.innerText || $(obj).text() || "").toLowerCase() == meta[3].toLowerCase();
  }
  // remove existing link(s)
  $('div.contextual a[href="' + auth_source_new_path.replace(/([ #;&,.+*~\':"!^$[\]()=>|\/@])/g, '\\$1') + '"]').remove();
  // insert form in place of link
  var form = $('<form>', {'name': 'auth_source_new', 'action': auth_source_new_path, 'method': 'get'});
  form.append($('<a>', {'class': 'icon icon-add', 'href': 'javascript: document.auth_source_new.submit();'}).text(auth_source_new_label));
  var select = $('<select>', {'style': 'margin-left: 10px; margin-bottom: 4px;', 'name': 'type'});
  auth_source_classes.forEach( function(c) {
    select.append(new Option(c[0],c[1]));
  });
  form.append(select);
  $('div.contextual').append(form);
  // update Hosts column name
  var thead = $('table.list thead');
  thead.find('th:econtains("' + auth_source_host_label.replace(/([ #;&,.+*~\':"!^$[\]()=>|\/@])/g, '\\$1') + '")').text(auth_source_hostnode_label);
  // insert groups column header
  thead.find('th:last').before($('<th>').text(auth_source_groups_label));
  // insert groups column data and disable delete as appropriate
  auth_sources.forEach( function(s) {
    $('table.list #auth-source-'+ s[0] + ' td:last').before($('<td>', {'align': 'center'}).text(s[1]));
    if (s[2]) {
      var link = $('table.list #auth-source-'+ s[0] + ' a[data-method="delete"]');
      var name = link.text();
      link.replaceWith($('<span>',{'class': 'icon icon-del', 'style': 'padding-right: 0.6em; color: #999;'}).text(name));
    }
  });
});
