// dynamic edit of groups index view
jQuery(function() {
  // insert auth_source column header
  $('table.groups thead tr th:last').before($('<th>').text(auth_source_label));
  // insert auth_source column data
  auth_sources_groups.forEach( function(g) {
    $('table.groups td a[href="'+ g[0] + '"]').closest('tr').find('td:last').before($('<td>', {'align': 'center'}).text(g[1]));
  });
});
