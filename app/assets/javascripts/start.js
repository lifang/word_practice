
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


function loaded() {
    myScroll = new iScroll('wrapper');
}
document.addEventListener('touchmove', function (e) {
    e.preventDefault();
}, false)
document.addEventListener('DOMContentLoaded', function () {
    setTimeout(loaded, 200);
}, false);


function rollback(){
    $("#step"+step).hide();
    step = 5;
    $("#step5").show();
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
}

function next_step(){
    $("#step"+step).hide();
    step += 1;
    $("#step"+step).show();
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
}

function answer_correct(){
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
    $("#mask").show();
    $("#correct").show();
    correct_sum += 1;
    if(correct_sum>=4){
        $("#after_four_correct").show();
    }
}

function answer_mistake(){
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
    $("#error").val("error");
    $("#mask").show();
    $("#mistake").show();
}

function ignore_mistake(){
    $("#error").val("ignore");
}

function click_knowwell(){
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
    $("#mask").show();
    $("#knowwell").show();
}

function hide_mask(ele){
    $(ele).hide();
    $("#mask").hide();
}

function check_step4_input(){
    if($("#step4_input").length==0 || $("#step4_input").val().trim()==word_name){
        answer_correct();
    }else{
        answer_mistake();
    }
}

//继续学习
function ajax_next_word(){
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
    var error = $("#error").val();
    $('#ajax_loading').load("/words/ajax_next_word?word_id="+word_id+"&type="+web_type+"&error="+error);
}

//已经掌握
function ajax_know_well(){
    $('#scroller').css('-webkit-transform','translate3d(0px,0px,0px)');
    $('#ajax_loading').load("/words/ajax_know_well?word_id="+word_id+"&type="+web_type);
}


