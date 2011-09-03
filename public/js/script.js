
$("#terminal_command").keypress(function(event) {
	if ( event.which != 13 ) {
		return true;
	}
	$.ajax({
	   type: "POST",
	   url: "/terminal/execute",
	   data: "cmd="+(this.value),
	   cache: false,
	   success: function(msg){
	     alert( "Data Saved: " + msg );
	   }
	});
	event.preventDefault();
	return false;
});

