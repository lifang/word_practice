function read_or(){
    var which_one=$(":checked").val();
    var content="此模式只需要学习单词与词义，确定要进入吗？";
    if (which_one=="1"){
        content="此模式要学习单词与词义还有更好的拼读训练，确定要进入吗？";
    }
    if(confirm(content)){
        window.location.href="/words?action="+which_one;
    }else{
        $(":checked").attr("checked",null);
    }
}

