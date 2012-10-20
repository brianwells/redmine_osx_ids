// dynamic edit of groups edit view
jQuery(function() {
  // insert menu for auth_source
  var select = $('<select>', {'name': 'group[auth_source_id]', 'id': 'group_auth_source_id'})
  auth_sources.forEach( function(s) {
    select.append(new Option(s[0],s[1]));
  });
  select.val(auth_source_id);
  var para = $('<p>');
  para.append($('<label>',{'for': 'group_auth_source_id'}).text(auth_source_label));
  para.append(select);
  $('#group_name').closest('p').after(para);
  // don't let user edit users in group if auth_source involved
  if (auth_source_id) {
    // remove user edit/delete buttons
    $('table.users thead th:eq(' + $('table.users tbody td.buttons:first').index() + ')').remove();
    $('table.users tbody td.buttons').remove();
    // remove user add form
    $('#tab-content-users div.splitcontentright form.edit_group').remove();
    // put in notice
    $('#tab-content-users div.splitcontentright').append($('<p>').append(auth_source_managed));
  }
});
