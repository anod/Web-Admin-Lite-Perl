
$(function(){
	$("#terminal_command").keypress(function(e) {
		var code = (e.keyCode ? e.keyCode : e.which);
		if ( code != 13 ) {
			return true;
		}
		var cmd = this.value;
		var cmd_escaped = encodeURIComponent(cmd);
		$.ajax({
		   type: "POST",
		   url: "/terminal/execute",
		   data: "cmd="+cmd_escaped,
		   cache: false,
		   success: function(msg){
			 $("#terminal_window_ouput").append("&gt;"+cmd+"<br/>");
		     $("#terminal_window_ouput").append(nl2br(msg,false)+"<br/>")
		     $("#terminal_command").val("");
		     $("#terminal_window_ouput").scroll();
		   }
		});
		e.preventDefault();
		return false;
	});
});


function nl2br (str, is_xhtml) {
    // Converts newlines to HTML line breaks  
    // 
    // version: 1107.2516
    // discuss at: http://phpjs.org/functions/nl2br
    // +   original by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
    // +   improved by: Philip Peterson
    // +   improved by: Onno Marsman
    // +   improved by: Atli Þór
    // +   bugfixed by: Onno Marsman
    // +      input by: Brett Zamir (http://brett-zamir.me)
    // +   bugfixed by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
    // +   improved by: Brett Zamir (http://brett-zamir.me)
    // +   improved by: Maximusya
    // *     example 1: nl2br('Kevin\nvan\nZonneveld');
    // *     returns 1: 'Kevin\nvan\nZonneveld'
    // *     example 2: nl2br("\nOne\nTwo\n\nThree\n", false);
    // *     returns 2: '<br>\nOne<br>\nTwo<br>\n<br>\nThree<br>\n'
    // *     example 3: nl2br("\nOne\nTwo\n\nThree\n", true);
    // *     returns 3: '\nOne\nTwo\n\nThree\n'
    var breakTag = (is_xhtml || typeof is_xhtml === 'undefined') ? '' : '<br>';
 
    return (str + '').replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n)/g, '$1' + breakTag + '$2');
}