// dynamic edit of users edit view
jQuery(function() {
  auth_source_groups.forEach( function(g) {
    $('#tab-content-groups #user_group_ids_[value="' + g + '"]').prop("disabled", true);
  });
});
