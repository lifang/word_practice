// JavaScript Document
/*function tab_div(style) {
    //var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = $(window).height();
    var win_width = $(window).width();
    var z_layer_height = $(style).height();
    var z_layer_width = $(style).width();
    $(style).css('top',(win_height-z_layer_height)/2);
    $(style).css('left',(win_width-z_layer_width)/2);
    $(style).show();
}
$(document).ready(function(){
	tab_div('.t_area');
	//alert(0)
})

*/

//5秒钟定时器
var local_start_time = 5;
var local_timer = null;
var local_save_time = null;
function local_save_start() {
    local_save_time = new Date();
    local_timer = self.setInterval(function(){
        local_save();
    }, 100);
}

//5秒钟函数
function local_save() {
    var start_date = new Date();
    if (local_start_time <= 0) {
        window.clearInterval(local_timer);
        have_a_rest();
        return;
    }

    var end_date = new Date();
    if ((end_date - local_save_time) > 100 && (end_date - local_save_time) < 1000) {
        local_start_time = Math.round((local_start_time - (end_date - local_save_time)/1000)*10)/10;
    } else {
        local_start_time = Math.round((local_start_time - 0.1 - (end_date - start_date)/1000)*10)/10;
    }
    local_save_time = end_date;
}

//休息提示
function have_a_rest() {
    
}