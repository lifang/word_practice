//5秒钟定时器
function local_save_start(flag) {
    local_save_time = new Date();    
    if (flag == "clock") {
        //alert(local_start_time);
        if (parseInt(local_start_time) == parseFloat(local_start_time)) {
            //alert("true");
            $(".count_down").html(local_start_time);
        }
    } else {
        if (parseInt(local_start_time) == parseFloat(local_start_time)) {
            $("#countdown_" + flag).html(local_start_time);
        }
    }
    local_timer = self.setInterval(function(){
        local_save(flag);
    }, 100);
}

//5秒钟函数
function local_save(flag) {
    var start_date = new Date();
    if (local_start_time <= 0) {
        if (flag == "clock") {
            if (parseInt(local_start_time) == parseFloat(local_start_time)) {
                $(".count_down").html(0);
            }
            window.clearInterval(local_timer);
            have_a_rest();
        } else {
            if (parseInt(local_start_time) == parseFloat(local_start_time)) {
                $("#countdown_" + flag).html(0);
            }
            window.clearInterval(local_timer);
            goto_next(flag);
        }
        return;
    }
    if (flag == "clock") {
        if (parseInt(local_start_time) == parseFloat(local_start_time)) {
            $(".count_down").html(local_start_time);
        }
    } else {
        if (parseInt(local_start_time) == parseFloat(local_start_time)) {
            $("#countdown_" + flag).html(local_start_time);
        }
    }
    var end_date = new Date();
    if ((end_date - local_save_time) > 100 && (end_date - local_save_time) < 1000) {
        local_start_time = Math.round((local_start_time - (end_date - local_save_time)/1000)*10)/10;
    } else {
        local_start_time = Math.round((local_start_time - 0.1 - (end_date - start_date)/1000)*10)/10;
    }
    local_save_time = end_date;
}

function have_a_rest() {
    $("#tishi_zz").show();
    $("#jizhong_tab").show();
}

function reset_clock(num) {
    window.clearInterval(local_timer);
    local_start_time = num;
    local_save_time = null;
}

function restart_clock() {
    $("#tishi_zz").hide();
    $("#jizhong_tab").hide();
    reset_clock(answer_time);
    local_save_start("clock");
}

function closeme(){
    $("#tishi_zz").hide();
    $("#jizhong_tab").hide();
    window.location.href="/words";
}

//定义两个全局变量用来记录答题定时的时间，和继续的定时时间
$(document).ready(function(){
    if ($(".count_down").length > 0) {
        local_start_time = answer_time;
        local_save_start("clock");
    }
    setTimeout(function(){
        if (myScroll != null && myScroll != undefined) {
            myScroll.refresh();
        }
    }, 300);
    if(myScroll!=null && $("#mark_iscroll_destroy").length>0){
        myScroll.destroy();
    }
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
})
