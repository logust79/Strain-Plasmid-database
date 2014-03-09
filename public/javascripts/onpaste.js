//为每个text控件定义“获得输入焦点”和“失去焦点”时的样式
$("textarea").focus(function(){
                              $(this).css({"background-color":"#FFFFE0"});
                              }).blur(function(){
                                      $(this).css({"background-color":"white"});
                                      });
//jquery中未对onpaste事件(即粘贴事件)进行封装，只好采用js原有的方式为每个text控件绑定onpaste事件
$.each($("textarea"),function(obj,index){
       this.onpaste = readClipboardData;
       });

//获取剪切板数据 函数
function getClipboard() {
    if (window.clipboardData) {
        return (window.clipboardData.getData('Text'));
    }
    else if (window.netscape) {
        netscape.security.PrivilegeManager.enablePrivilege('UniversalXPConnect');
        var clip = Components.classes['@mozilla.org/widget/clipboard;1'].createInstance(Components.interfaces.nsIClipboard);
        if (!clip) return;
        var trans = Components.classes['@mozilla.org/widget/transferable;1'].createInstance(Components.interfaces.nsITransferable);
        if (!trans) return;
        trans.addDataFlavor('text/unicode');
        clip.getData(trans, clip.kGlobalClipboard);
        var str = new Object();
        var len = new Object();
        try {
            trans.getTransferData('text/unicode', str, len);
        }
        catch (error) {
            return null;
        }
        if (str) {
            if (Components.interfaces.nsISupportsWString) strstr = str.value.QueryInterface(Components.interfaces.nsISupportsWString);
            else if (Components.interfaces.nsISupportsString) strstr = str.value.QueryInterface(Components.interfaces.nsISupportsString);
            else str = null;
        }
        if (str) {
            return (str.data.substring(0, len.value / 2));
        }
    }
    return null;
}

//读取剪切板数据，并将剪切板数据存放于各table cell中
function readClipboardData() {
    var str = getClipboard(); //获取剪切板数据
    document.getElementById("1").value = str;
    return false; //防止onpaste事件起泡
}
