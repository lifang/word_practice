
function sAlert(txt,width,height,dom){
	var eSrc=(document.all)?window.event.srcElement:arguments[1];
	var shield = document.createElement("DIV");
	shield.id = "shield";
	shield.style.position = "absolute";
	shield.style.left = "0px";
	shield.style.top = "0px";
	shield.style.width = "100%";
	shield.style.height = document.body.scrollHeight+"px";
	shield.style.background = "#333";
	shield.style.textAlign = "center";
	shield.style.zIndex = "10000";
	shield.style.filter = "alpha(opacity=0)";
	shield.style.opacity = 0;
	if(dom==null){
	  var alertFram = document.createElement("DIV");
	  alertFram.style.background = "#ccc";
	  alertFram.style.textAlign = "center";
	  strHtml  = "<div style=\"list-style:none;margin:0px;padding:0px;width:100%;height:100%;\">\n";
	  strHtml += "	<div style=\"background:#DD828D;text-align:left;padding-left:20px;font-size:14px;font-weight:bold;height:15%;padding:2px;border:1px solid #F9CADE;\">[系统提示]</div>\n";
	  strHtml += "	<div style=\"background:#fff;text-align:center;font-size:12px;height:70%;border-left:1px solid #F9CADE;padding:2px;border-right:1px solid #F9CADE;\">"+txt+"</div>\n";
	  strHtml += "	<div style=\"background:#FDEEF4;text-align:center;font-weight:bold;height:15%; padding:2px;\"><input type=\"button\" value=\"确 定\" onclick=\"javascript:doOk()\" /></div>\n";
	  strHtml += "</div>\n";
	  alertFram.innerHTML = strHtml;
	}else{
		var alertFram = dom;
	}
	alertFram.style.position = "absolute";
	alertFram.style.display = "none";
	alertFram.style.left = "50%";
	alertFram.style.top = "50%";
	alertFram.style.marginLeft = (-1)*width+"px" ;
	alertFram.style.marginTop = (-0.8)*height+document.documentElement.scrollTop+"px";
	alertFram.style.width = 2*width+"px";
	alertFram.style.height = 1.6*height+"px";
	alertFram.style.zIndex = "10002";
	document.body.appendChild(alertFram);
	document.body.appendChild(shield);
	
	this.setOpacity = function(obj,opacity){
		if(opacity>=1)opacity=opacity/100;
		try{ obj.style.opacity=opacity; }catch(e){}
		try{ 
			if(obj.filters.length>0 && obj.filters("alpha")){
				obj.filters("alpha").opacity=opacity*100;
			}else{
				obj.style.filter="alpha(opacity=\""+(opacity*100)+"\")";
			}
		}catch(e){}
	}
	var c = -1;
	var r_width = width;
	var r_height = height;
	
	this.doAlpha = function(){
	    // 颜色渐变的透明度
		if (c++ > 30){clearInterval(ad);return 3;}
		setOpacity(shield,c);
		alertFram.style.display = "block";
		var spd = 2*(30-c/2)/450;
		if(parseFloat(alertFram.style.width)>r_width){
		   var wid = parseFloat(alertFram.style.width)-r_width*(2-1)*spd;
		   var this_width = (wid >=r_width) ? wid : r_width;
	       alertFram.style.width = ""+this_width+"px";
	       alertFram.style.marginLeft = "-"+(parseFloat(alertFram.style.width)/2.0)+"px";
		}
		
		if(parseFloat(alertFram.style.height)>r_height){
		   var het = parseFloat(alertFram.style.height)-r_height*(1.6-1)*spd;
		   var this_height = (het >=r_height) ? het : r_height;
		   alertFram.style.height = ""+this_height+"px";
	       alertFram.style.marginTop = parseFloat(alertFram.style.height)*(-1)/2.0+document.documentElement.scrollTop+"px";
		}
	}
	var ad = setInterval("doAlpha()",1);
	this.doOk = function(){
	    clearInterval(ad);
		if(dom==null){
		   document.body.removeChild(alertFram);
		}else{
		   dom.style.display="none";
		}
		document.body.removeChild(shield);
		document.body.onselectstart = function(){return true;}
		document.body.oncontextmenu = function(){return true;}
	}
	document.body.onselectstart = function(){return false;}
	document.body.oncontextmenu = function(){return false;}
}