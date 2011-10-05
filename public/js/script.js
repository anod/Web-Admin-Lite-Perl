
var history_position = 0;
var terminal_history = [];
var key_code = 
	{
		 arrow : {left: 37, up: 38, right: 39, down: 40 },
		 enter : 13
	}

$(function(){
	
	$('#terminal_command').keydown(function (e) {
	  var code = e.keyCode || e.which;
		 
	  switch (code) {
	  	case key_code.arrow.up:
	  		history('up');
	  		return false;
	    break;
	  	case key_code.arrow.down:
	  		history('down');
	  		return false;
	    break;
	  	case key_code.arrow.left:
	  	case key_code.arrow.right:
	    default:
	    	return true;
	  }
	});
		   
	$("#terminal_command").keypress(function(e) {
		var code = (e.keyCode ? e.keyCode : e.which);

		if (code != key_code.enter) {
			return true;
		}
       	execute(this.value);
		e.preventDefault();
		return false;
	});
	
	$("#custom_commands").change(function() {
		var cmd = $(this).val();
		if (cmd == "") {
			return;
		}
		set_command(cmd);
		$(this).val("");
	});
});


function set_command(cmd) {
	$("#terminal_command").val(cmd);
	$("#terminal_command").focus();	
}

function history(dir) {
	if (dir == 'down') {
		if (!terminal_history.length) {
			return;
		}
		if (history_position + 1 > terminal_history.length) {
			return;
		}
		history_position++;
		set_command(terminal_history[history_position]);
		return;
	}
	if (dir == 'up') {
		if (!terminal_history.length) {
			set_command("");
			return;
		}
		if (history_position <= 0) {
			set_command("");
			return;			
		}
		history_position--;
		set_command(terminal_history[history_position]);
		return;
	}
}

function execute(cmd) {
	terminal_history.push(cmd);
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
		 $("#terminal_window_ouput").scrollTop($("#terminal_window_ouput")[0].scrollHeight);
	   }
	});
}


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
