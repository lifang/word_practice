$.fn.reorder = function() {
    //random array sort from
    //http://javascript.about.com/library/blsort2.htm
    function randOrd() {
        return(Math.round(Math.random())-0.5);
    }
    return($(this).each(function() {
        var $this = $(this);
        var $children = $this.children();
        var childCount = $children.length;

        if (childCount > 1) {
            $children.remove();

            var indices = new Array();
            for (i=0;i<childCount;i++) {
                indices[indices.length] = i;
            }
            indices = indices.sort(randOrd);
            $.each(indices,function(j,k) {
                $this.append($children.eq(k));
            });
        }
    }));
}

function rollback(){
    $("#face").hide();    
    $("#back").show();    
    //翻面学习清空倒计时
    reset_clock(answer_time);
    if (myScroll != null && myScroll != undefined) {
        myScroll.refresh();
    }else{
        myScroll = new iScroll('wrapper');
    }
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
}

function answer_correct(){
    answer_mark = true;
    show_mask($('#correct'));
    if((web_type=="recite" && step =="4")||(web_type=="review" && $("#error").val()!="error")){
        $("#after_four_correct").show();
    }
    reset_clock(last_time);
    local_save_start("correct");
}

function answer_mistake(){
    $("#error").val("error");
    show_mask($('#mistake'));
    reset_clock(last_time);
    local_save_start("mistake");
}

//继续
function goto_next(flag) {
    if (flag == "correct") {
        hide_mask($('#correct'));
        ajax_next_word();
        //开始下一步的倒计时
        reset_clock(answer_time);
    //local_save_start("clock");
    } else if (flag == "mistake") {
        hide_mask($('#mistake'));
        rollback();        
    } else if (flag == "treetrue") {
        $("#tishi_tt").hide();
        answer_mark = true;
        hide_mask($('#treetrue'));
        ajax_next_word();
    }
}

//按错了
function reset_answer() {
    $("#error").val("ignore");
    hide_mask($('#mistake'));
    reset_clock(answer_time);
    local_save_start("clock");
}

//翻面学习
function study_rollback() {
    hide_mask($('#correct'));
    rollback();
}

function click_knowwell(){
    hide_mask($('#correct'));
    show_mask($('#knowwell'));
    reset_clock(last_time);
}

function hide_mask(ele){
    $(ele).hide();
    $("#mask").hide();
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
}

function show_mask(ele){
    $("#mask").show();
    $(ele).show();
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
}

function check_step4_input(){
    if($("#step4_input").length==0 || $.trim($("#step4_input").val())==$.trim(word_name)){
        answer_correct();
    }else{
        answer_mistake();
    }
}

//继续学习
function ajax_next_word(){
    reset_clock(answer_time);
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
    var error = $("#error").val();
    if(error!="error"&&answer_mark==false){
        error = "pass"
    }
    $('#ajax_loading').load("/words/ajax_next_word?word_id="+word_id+"&type="+web_type+"&error="+error+"&time_flag="+time_flag);
}

//已经掌握
function ajax_know_well(){
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
    $('#ajax_loading').load("/words/ajax_know_well?word_id="+word_id+"&type="+web_type+"&time_flag="+time_flag);
}

//三连击，新词连续3次答正确，显示提示
function tree_times_true(is_error) {
    if (is_error == "false") {
        if ($("#treetrue").length > 0) {
            $("#tishi_tt").show();
            $("#treetrue").show();
            reset_clock(answer_time);
        }
    } else {
        answer_correct();
    }
}

function stopBubble(e){
    if(e && e.stopPropagation()){
        e.stopPropagation();
    } else {
        window.event.cancelBubble = true;
    }
}

function check_step4_drag(){
    var this_answer_arr = [];
    $(".drop_div").each(function(){
        this_answer_arr.push($(this).html());
    })
    var this_answer = this_answer_arr.join(" ");
    if(this_answer==true_answer){
        answer_correct();
    }else{
        answer_mistake();
    }
}

//不确认
function not_sure(){
    hide_mask($('#knowwell'));
    if(answer_mark == true){
        show_mask($('#correct'));
        reset_clock(last_time);
        local_save_start('correct');
    }else{
        reset_clock(answer_time);
        local_save_start("clock");
    }    
}
