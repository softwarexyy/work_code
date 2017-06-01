<%@page language="java" contentType="text/html; charset=UTF-8"%>
<%@ include file="../head.jsp"%>
<%
	String branchID = (String)sessionCtx.getDataValue("session_branchId");
	branchID=branchID.substring(0,4);
%>
<html>
<head>
<%=utb.getCSS()%>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<script language="javascript" src="<%= webAppPath %>scripts/lib/prototype.js"></script>
<script language="javascript" src="<%= webAppPath %>scripts/lib/prototype_EMP.js"></script>
<script language="javascript" src="<%= webAppPath %>scripts/lib/window.js"></script>
<script language="javascript" src="<%= webAppPath %>scripts/lib/effects.js"></script>
<script language="javascript" src="<%= webAppPath %>scripts/public.js"></script>
<script language="javascript" src="<%= webAppPath %>scripts/money.js"></script>
<script language="javascript" src="<%= webAppPath %>scripts/window.js"></script>
<script language="javascript" src="<%= webAppPath %>scripts/stepflow.js"></script>
<script type="text/javascript">
var backup2Msg='0103';
var backup3Msg='';
var backup4Msg='';
var backup5Msg='';
var backup6Msg='';
var feeBalanace='';
var backup2MsgHot='';
//查询账户余额
function querySubAccount(){
	var subAccOption = document.getElementById("subAccountNo");
	while(subAccOption.options.length>0)
		subAccOption.removeChild(subAccOption.options[0]);
	if(trim(document.getElementById("payAcc").value) == ""){
		document.getElementById("txtTranAmt").value = "";
		subAccOption.appendChild(new function(){var tmp = document.createElement("option"); tmp.value=""; tmp.innerHTML="----请选择币种----"; return tmp;}());
		return;
	}
	var strSplit = $("payAcc").value;
	
	var splitStr = strSplit.split("|");
	var accountNo = splitStr[0];
	var currencyType = splitStr[3];
	var registMedium = splitStr[5];		//卡账号标志:2账号；1卡号
	var chkPwdFlg = '0';				//是否校验密码
	var params = '';
		params += 'accountNo=' + accountNo + '&checkPasswordFlag=' + chkPwdFlg;
	showQueryWait(true);
	//查询账户余额	ajax
	sendAjaxRequest("post", "<%=utb.getURL("subAccountQuery.do")%>", params, processResponse);	
}
function processResponse(contextData){
	var errorMessage = contextData.getValueAt("hostErrorMessage");
	if(errorMessage == null){
		var subAccOption = document.getElementById("subAccountNo");
		var icoll = contextData.getElement("iSubAccountInfos");
		for(var i=0;i<icoll.size();i++){
			var kcoll = icoll.getElementAt(i);
			if(kcoll.getValueAt("accountType")!='000')
				continue;
    <%
        if ("8700".equals(branchID)) {
    %>
            if (kcoll.getValueAt("accountStat") != "01" &&
            		kcoll.getValueAt("accountStat") != "02") {
                continue;
            }
    <%
        }
    %>
			var n = document.createElement("option");
			n.value = kcoll.getValueAt("accountNo")+"|"+kcoll.getValueAt("subAccountNo")+"|"+kcoll.getValueAt("currencyType")+"|"+contextData.getValueAt("accountNo")+"|"+kcoll.getValueAt("balanceAvailable")+"|"+kcoll.getValueAt("openNode")+"|"+kcoll.getValueAt("openNodeName");
			n.innerHTML = kcoll.getValueAt("currencyTypeShow")+" 可用余额:"+kcoll.getValueAt("balanceAvailableShow")+"";
			subAccOption.appendChild(n);
		}
		if(subAccOption.options.length<=0)
			subAccOption.appendChild(new function(){var tmp = document.createElement("option"); tmp.value=""; tmp.innerHTML="----无可用的子账户----"; return tmp;}());
	}else{
		alert(errorMessage);
	}
	showQueryWait(false);
}
function newOption(a,b){
	var n = document.createElement("option");
	n.value = a;
	n.innerHTML = b;
	return n;
}
//查询缴费项目
var feeCodeDescMapping = {};
function queryFeeCodeList(){
	var feeCodes = $('feeCode');
	while(feeCodes.options.length>0)
		feeCodes.removeChild(feeCodes.options[0]);
	feeCodes.appendChild(newOption("","正在查询缴费项目中..."));
	var params = '';
	if($('switchFeeType').value=="byArea"){
		var tmpProvince = $('provinceCode').value;
		var tmpCity = $('cityCode').value;
		if(tmpProvince!=undefined&&tmpProvince!="")
			params += "&provinceCode="+tmpProvince;
		if(tmpCity!=undefined&&tmpCity!="")
			params += "&cityCode="+tmpCity;
	}
	sendAjaxRequest("post", "<%=utb.getURL("006000_feeCodeQuery.do")%>", params, feeCodeResponse);
}
function feeCodeResponse(contextData){
	var errorMessage = contextData.getValueAt("hostErrorMessage");
	if(errorMessage == null){
		var feeCodes = $('feeCode');
		while(feeCodes.options.length>0)
			feeCodes.removeChild(feeCodes.options[0]);
		var icoll = contextData.getElement("iFeeCode");
		
		if(icoll.size()==0){
			feeCodes.appendChild(newOption("","---无可用的缴费项目---"));
		}else{
			feeCodes.appendChild(newOption("","---请选择缴费项目---"));
			for(var i=0;i<icoll.size();i++){	//显示缴费项目
				var kcoll = icoll.getElementAt(i);
				var n = document.createElement("option");
				var feeKey = kcoll.getValueAt("feeCode")+"_"+kcoll.getValueAt("provinceCode")+"_"+kcoll.getValueAt("cityCode");
				var op = newOption(feeKey,kcoll.getValueAt("feeCodeShow"));
				op.key = feeKey;
				feeCodes.appendChild(op);
				feeCodeDescMapping[feeKey] = {};
				for(var j = 1;j<=5;j++){
					feeCodeDescMapping[feeKey]["input"+j] = kcoll.getValueAt("input"+j);
					feeCodeDescMapping[feeKey]["type"+j] = kcoll.getValueAt("type"+j);
				}
			}
		}
	}else{
		alert(errorMessage);
	}
}
function getDescription(val,type){
	type = nvl(type,"");
	var result = "";
	var tp = "";
	var ix = type.indexOf("[");
	var iy = type.indexOf("]");
	if(ix<0){
		tp = type;
	}else{
		tp = type.substring(0,ix);
	}
	tp = tp.toUpperCase();
	var content = type.substring(ix+1,iy);
	var contentArr = content.split(";");
	if(tp=="RADIO"||tp=="CHECKBOX"||tp=="LIST"){
		for(var i=0;i<contentArr.length;i++){
			var tmp = contentArr[i].split(":");
			if(tmp[0]==val){
				result += tmp[1];
				break;
			}
		}
	}else{
		result += val;
	}
	return result;
}
function getValue(id,type){
	type = nvl(type,"");
	var result = "";
	var tp = "";
	var ix = type.indexOf("[");
	var iy = type.indexOf("]");
	if(ix<0){
		tp = type;
	}else{
		tp = type.substring(0,ix);
	}
	tp = tp.toUpperCase();
	if(tp=="CHECKBOX"){
		result += $(id).checked?$(id).checkedValue:$(id).uncheckedValue;
	}else if(tp=="RADIO"){
		result += getRadioValue(id);
	}else{
		result += $(id).value; 
	}
	return result;
}
function getInput(id,type){
	type = nvl(type,"");
	var result = "";
	var tp = "";
	var ix = type.indexOf("[");
	var iy = type.indexOf("]");
	if(ix<0){
		tp = type;
	}else{
		tp = type.substring(0,ix);
	}
	tp = tp.toUpperCase();
	var content = type.substring(ix+1,iy);
	var contentArr = content.split(";");
	if(tp=="AMOUNT"){
		result +=  '<input id="'+id+'" type="text" inputType="'+type+'" class="currency" size="32" onblur="checkMoney(this.id);"/>';
	}else if(tp=="RADIO"){
		for(var i=0;i<contentArr.length;i++){
			var tmp = contentArr[i].split(":");
			result += "<input id='"+id+"' name='"+id+"' type='radio' inputType='"+type+"' value='"+tmp[0]+"' />"+tmp[1];
		}
	}else if(tp=="CHECKBOX"){
		var tmp1 = contentArr[0].split(":");
		var tmp2 = contentArr[1].split(":");
		result += "<input id='"+id+"' type='checkbox' inputType='"+type+"' checkedValue='"+tmp1[0]+"' uncheckedValue='"+tmp2[0]+"' />";
	}else if(tp=="LIST"){
		result += "<select id='"+id+"' inputType='"+type+"'>";
		for(var i=0;i<contentArr.length;i++){
			var tmp = contentArr[i].split(":");
			result += "<option value='"+tmp[0]+"' />"+tmp[1];
		}
		result += "</select>";
	}else{
		result +=  '<input id="'+id+'" type="text" inputType="'+type+'" size="32" />';
	}
	return result;
}
//提交，验证数据
function submitData(){
	var branchID = <%=branchID%>;
	var feeFa=$('feeWay').value;
	var key = $('feeCode').value;
	var payAmount = parseFloat(getMoney('txtTranAmt'));
	if(!($('feeCode').value == '100091_000_0000' && branchID=='5200')){
 	var arrFee = document.getElementById('arrFee').value;
	var arrFee1 = arrFee.split("|")[3];
	}
	var temp = document.submitForm.Amountset.value;
	if((key=="100061_000_0000"||key=="100050_000_0000")&&branchID=="2200"){//辽宁自建电费
		if(payAmount<temp){
			alert("缴费金额应大于等于欠费金额");
			return;
		}
	}
	
	if(arrFee1<0){
		var arrFee2 = arrFee1.replace(/-/,"");
		if(payAmount<arrFee2){
			alert("缴费金额应大于欠费金额");
			return;
		}
if($('feeNo').value==""||$('feeNo').value==undefined){
		if(key=="100054_000_0000"){
			alert("请输入缴费识别码");
		}else{
			alert("请输入缴费号码");
		}
		return;

	}
	} 
	if($('subAccountNo').value==""||$('subAccountNo').value==undefined){
		alert("请选择活期账户");
		return;
	}
    if(key=="100090_000_0000"){
	

		if($('feeWay').value==""||$('feeWay').value==undefined){
			

			alert("请选择处罚决定书类别");
			return;
		}

		var feeAmount = $("feeAmount").innerHTML;
		if (feeAmount != payAmount) {
			alert("缴费金额应与需交费金额相等");
			return;
		}


	}
	var balance = $('subAccountNo').value.split("|")[4];

	if(balance<payAmount){
		$("txtTranAmtTip").innerHTML="<liana:I18N name='缴费金额大于账户余额' />";
		changeClass('txtTranAmtTip','tip_err');
		return false;
	}

	var payAccount = $('payAcc').value.split("|")[0];
	if(key=="100090_000_0000"){
		var feeNo = feeFa+$('feeNo').value;
	}else{
		var feeNo = $('feeNo').value;
	}
	var currencyType = $('subAccountNo').value.split("|")[2];
	var registMedium = $('payAcc').value.split("|")[5];
	
	var feeCode = "";
	var feeKey = $('feeCode').value;
	var tmpKey = nvl(feeKey,"").split("_");
	feeCode = tmpKey[0];
	var provinceCode = "";
	var cityCode = "";
	if(tmpKey.length>=2){
		provinceCode = tmpKey[1];
	}
	if(tmpKey.length>=3){
		cityCode = tmpKey[2];
	}

	document.submitForm.feeCode.value = feeCode;
	document.submitForm.feeNo.value = feeNo; 
	document.submitForm.payAccount.value = payAccount;
	document.submitForm.payAmount.value = getMoney('txtTranAmt');
	document.submitForm.currencyType.value = currencyType;
	document.submitForm.registMedium.value = registMedium;
	document.submitForm.provinceCode.value = provinceCode;
	document.submitForm.cityCode.value = cityCode;
	
	var msgDesc = document.submitForm.msgDesc.value;
	var msgValue = document.submitForm.msgValue.value;
	var descAppendence = "";
	var valueAppendence = "";

	for(var i=1;i<=5;i++){
		var tmpType = $("backup"+i).inputType;
		var tmpValue = getValue("backup"+i,tmpType);
		if(!(branchID=='5200'&&feeCode=='100091'))
		document.submitForm["backup"+i].value = tmpValue;
		if(!(feeCodeDescMapping[feeKey]["input"+i]==undefined||feeCodeDescMapping[feeKey]["input"+i]=="")){
			if(!(i==1&&(msgDesc==undefined||msgDesc==null||msgDesc==""))){
				descAppendence += "|";
				valueAppendence += "|";
			}
			descAppendence += feeCodeDescMapping[feeKey]["input"+i];
			valueAppendence += getDescription(tmpValue,tmpType);
		}
	}
	document.submitForm.msgDesc.value += descAppendence;
	document.submitForm.msgValue.value += valueAppendence;
	
	//新加缴学费提交数据验证验证
	if(feeCode=='100091'){
		var branchID = <%=branchID%>;
		if(branchID=='5200'){
			var schoolInfo =$('schoolInfo').options[$('schoolInfo').selectedIndex].value;
			if(feeNo==''||feeNo==null){
				$("feeNoTip").innerHTML="<liana:I18N name='学号不能为空' />";
				changeClass('feeNoTip','tip_err');
				return false;
			}
		document.submitForm.feeCode.value =  feeCode;
			document.submitForm.feeNo.value =  feeNo;
			document.submitForm.backup1.value =  schoolInfo;
			document.submitForm.remark.value =  $('schoolInfo').options[$('schoolInfo').selectedIndex].text;;
		}else{
		if(msgDesc==''){
				$("feeNoTip").innerHTML="<liana:I18N name='查询失败，请核对学校及学号是否正确' />";
				changeClass('feeNoTip','tip_err');
				return false;
		}
		if(payAmount>msgValue.split('|')[1]){
			$("txtTranAmtTip").innerHTML="<liana:I18N name='缴费金额不能大于应缴金额' />";
			changeClass('txtTranAmtTip','tip_err');





			return false;
		}
		var schoolN = $('schoolName').options[$('schoolName').selectedIndex].value;
		var schoolNameCN = $('schoolName').options[$('schoolName').selectedIndex].text;
		var schoolName = schoolN.split('|')[1];
		document.submitForm.backup1.value = schoolName+"|"+schoolNameCN;
		var a = msgValue.split("|")[0];
		var b = msgValue.split("|")[1];
		var d = msgValue.split("|")[3];
		var c = a+"|"+b+"|"+d;
		document.submitForm.backup2.value = c;
		var subAccOption = document.getElementById("subAccountNo").value;
		var branchId = subAccOption.split("|")[5];
		var branchName = subAccOption.split("|")[6];
		var backup5 = branchId+"|"+branchName;
		document.submitForm.backup5.value = backup5;
	}
}
	/*else if(feeCode=='100052'){
		var countyCodes = $('county').options[$('county').selectedIndex].value.split('|');
		document.submitForm.backup1.value = countyCodes[1];
		document.submitForm.backup2.value = countyCodes[0];
	}*/
	else if((feeCode=='100061'||feeCode=='100050')&&branchID=='2200'){//辽宁自建电费
		var cityCodeLN = "";
		if(feeCode=='100061') {
			cityCodeLN = $("cityValue_2200").value;
		}else {	
			cityCodeLN = $("cityValue_2200_100050").value;
			document.submitForm.backup3.value = msgValue.split("|")[0];
		}
		document.submitForm.backup1.value = cityCodeLN;	
		if (cityCodeLN=='2260'){
			document.submitForm.backup2.value = msgValue.split("|")[1];
		}
	}
	else if(feeCode=='100030'&&branchID=='2200'){
		var cityCodeLN = $("value_2200").value;
		var netType = $("feeType_2200").value;
		document.submitForm.backup1.value = cityCodeLN;
		document.submitForm.backup2.value = netType;
		document.submitForm.backup3.value = msgValue.split("|")[1];
	}
	else if(feeCode=='100020'&&branchID=='2200'){
		var cityCodeLN = $("value_2200").value;
		var netType = $("feeType_2201").value;
		document.submitForm.backup1.value = cityCodeLN;
		document.submitForm.backup2.value = netType;
		document.submitForm.backup3.value = msgValue.split("|")[1];
	}else if(branchID=='2400'&&key=="100080_000_0000"){//100080吉林有限电视费功能
		var signBank = $('SignBank').value;
		document.submitForm.backup1.value = signBank;
		document.submitForm.backup2.value = backup2Msg;
		document.submitForm.backup3.value = backup3Msg;
		//document.submitForm.backup4.value = backup4Msg;
		document.submitForm.backup4.value = backup4Msg+"|"+backup6Msg;
		document.submitForm.backup5.value = backup5Msg;
	}else if(branchID=='2400'&&key=="100073_000_0000"){
		var signBank = $('SignBank').value;
		if(signBank!='73000001'){
			if(signBank=='73000006'){
				document.submitForm.backup1.value = signBank;
				document.submitForm.backup2.value = backup2MsgHot;
				document.submitForm.backup3.value = backup3Msg;
			}else{
				document.submitForm.backup1.value = signBank;
			}
		}else{
			document.submitForm.backup1.value = signBank;
			document.submitForm.backup2.value = backup2MsgHot;
			document.submitForm.backup3.value = backup3Msg;
 			document.submitForm.backup4.value = backup4Msg;
			document.submitForm.backup5.value = backup5Msg;
		}
	}else if(branchID=='8700'&&key=="100101_000_0000"){//100101宁夏个人网银社保缴费功能
		var feeChargeType =$("feeChargeType").value;
		var codeWord =radioChecked();
		if(codeWord==''||codeWord==undefined){
			alert("请点选缴费信息");
			return false;
		}
		var moneyTemp = document.getElementById(codeWord).value;//金额种类
		if(moneyTemp==''||moneyTemp==undefined){
			moneyTemp = document.getElementById(codeWord).innerHTML;//金额种类
			var moeyTempSplit = moneyTemp.split('~');
			if(payAmount<moeyTempSplit[0]||payAmount>moeyTempSplit[1]){
				alert("输入金额应在可选择的缴费金额标准范围内");
				return false;
			};
			document.submitForm.backup1.value = feeChargeType;
			document.submitForm.backup2.value = codeWord;
		}else{
			if(payAmount!=moneyTemp){
				alert("输入金额应与可选择的缴费金额标准相同");
				return false;
			}
			document.submitForm.backup1.value = feeChargeType;
			document.submitForm.backup2.value = codeWord;
		}
		
	}else if(feeCode=='100054'){
		if(msgDesc==''){
			alert("缴费业务受理方返回缴费信息超时，请稍候再试");
			return false;
		}
		//如果是非税缴费，在后面增加付款账户户名
			document.submitForm.backup1.value = msgValue;
			document.submitForm.backup2.value = '<%=sessionCtx.getDataValue("session_customerNameCN") %>';
	}
	else{
		if(msgDesc==''){
			alert("缴费业务受理方返回缴费信息超时，请稍候再试");
			return false;
		}
		document.submitForm.backup1.value = msgValue;
	}
	if(branchID=='2400'&&key=="100060_000_0000"){
		var signBank = $('SignBank').value;
		document.submitForm.backup1.value = signBank;
	}
	if(feeCode=='100053'){
		if(document.submitForm.Amountset.value=='0.00'||document.submitForm.Amountset.value=='0')
		document.submitForm.backup2.value = '2';
		else document.submitForm.backup2.value = '0';
		document.submitForm.msgDesc.value = '';
	}
	document.submitForm.submit();
}
function newFeeDetail(key,value){
	var tr = document.createElement("tr");
	var title = document.createElement("td");
	var content = document.createElement("td");
	title.className = "title";
	title.innerHTML = key;
	if(value!=null&&value.nodeType!=undefined)
		content.appendChild(value);
	else
		content.innerHTML = value;
	tr.appendChild(title);
	tr.appendChild(content);
	return tr;
}
var feeDtailArr = new Array();
function queryFeeDetail(){
	<%if("6100".equals(branchID)){ %>
	$("WaterFee").style.display="none";
	<%} %>
	var branchID = <%=branchID%>;
	var feeNo = $('feeNo').value;
	
	var key = $('feeCode').value;
	var schoolN = $('schoolName').options[$('schoolName').selectedIndex].value;
	var schoolNameCN = $('schoolName').options[$('schoolName').selectedIndex].text;
	var schoolName = schoolN.split('|')[0];
	var tmpKey = nvl(key,"").split("_");
	if(key=="100090_000_0000"){
		$("feeFa").style.display = "";
	}else{
		$("feeFa").style.display = "none";
	}
	if(key=="100061_000_0000"&&branchID=="2200"){
		$("cityName_2200").style.display = "";
		$("communicationFee_2200").style.display = "none";
		$("communicationFee_2201").style.display = "none";
		$("name_2200").style.display = "none";
		$("cityName_2200_100050").style.display = "none";
		var wenxin ="<li>1.确认支付前，请您认真核对缴费号码、缴费金额，以防止由于错误输入给您带来的损失和不便。因号码输错，损失由您自行承担，缴费款项无法退回。</li><li>2.缴费到账时间取决于水务公司入账时间。</li><li>3.本缴费不提供正式发票，如需发票请到相应水务公司的营业网点办理。</li><li>4.建议您在账单'最后缴费日期'之前5日进行缴费；如果已经超过您的账单'最后缴费日期'，建议您直接到相应水务公司的营业网点缴费。</li>";
		$('wenxintishi').innerHTML = wenxin;
	}
	else if(key=="100050_000_0000"&&branchID=="2200"){//辽宁自建电费
		$("cityName_2200").style.display = "none";
		$("communicationFee_2200").style.display = "none";
		$("communicationFee_2201").style.display = "none";
		$("name_2200").style.display = "none";
		$("cityName_2200_100050").style.display = "";
		var wenxin ="<li>1.确认支付前，请您认真核对缴费号码、缴费金额，以防止由于错误输入给您带来的损失和不便。因号码输错，损失由您自行承担，缴费款项无法退回。</li><li>2.缴费到账时间取决于电力公司入账时间。</li><li>3.本缴费不提供正式发票，如需发票请到相应电力公司的营业网点办理。</li><li>4.建议您在账单'最后缴费日期'之前5日进行缴费；如果已经超过您的账单'最后缴费日期'，建议您直接到相应电力公司的营业网点缴费。</li>";
		$('wenxintishi').innerHTML = wenxin;
	}
	else if(key=="100030_000_0000"&&branchID=="2200"){
		$("communicationFee_2200").style.display = "";
		$("cityName_2200").style.display = "none";
		$("communicationFee_2201").style.display = "none";
		$("name_2200").style.display = "";
		$("cityName_2200_100050").style.display = "none";
	}else if(key=="100020_000_0000"&&branchID=="2200"){
		$("communicationFee_2200").style.display = "none";
		$("cityName_2200").style.display = "none";
		$("communicationFee_2201").style.display = "";
		$("name_2200").style.display = "";
		$("cityName_2200_100050").style.display = "none";
	}
	else{
		$("communicationFee_2200").style.display = "none";
		$("cityName_2200").style.display = "none";
		$("communicationFee_2200").style.display = "none";
		$("name_2200").style.display = "none";
		$("cityName_2200_100050").style.display = "none";
	}
	if(key=="100050_000_0000"&&branchID=="1990"){
		$("eleCompany_1990").style.display = "";
	}else{
		$("eleCompany_1990").style.display = "none";
	}
	if(key=="100091_000_0000"){
		$('feeNumber').style.display = "none";
		$('feeNumber2').style.display = "none";
		if(branchID=='6100'){
			$('school').style.display = "";
		}else if(branchID=='5200'){
			$("cityInfoTr").style.display = "";
			$("schoolInfoTr").style.display = "";
		}
		$('schoolNm').style.display = "";
		$('feeNo').value = '';
		$("nextButton").disabled = false;
		$("otherFee").style.display = "none";
		$("UserNm").style.display = "none";
		$("prefectureTr").style.display = "none";
		$("countyTr").style.display = "none";
		$("waterSupplyTr").style.display = "none";
		$('CustomerName2').style.display = "none";
		$('MeterAddress').style.display = "none";
		$('OweAmount').style.display = "none";
		$('BalanceAmount').style.display = "none";
		if(branchID=='6100'){
			$("schoolFee").style.display = "";
			$("TVFee").style.display="none";
			$("electricFee").style.display="none";
		}else if(branchID=='5200'){
			$("schoolFeeInfo").style.display = "";
		}
	}
	//lym add
	else if(key == "100052_000_0000"){
		$('feeNumber').style.display = "none";
		$('feeNumber2').style.display = "none";
		if(branchID=='6100'){
			$('school').style.display = "none";
		}else if(branchID=='5200'){
			$("cityInfoTr").style.display = "none";
			$("schoolInfoTr").style.display = "none";
		}
		$('schoolNm').style.display = "none";
		$('feeNo').value = '';
		$("otherFee").style.display = "none";
		$("UserNm").style.display = "";
		$("prefectureTr").style.display = "";
		$("countyTr").style.display = "";
		$("waterSupplyTr").style.display = "none";
		$('CustomerName2').style.display = "none";
		$('MeterAddress').style.display = "none";
		$('OweAmount').style.display = "none";
		$('BalanceAmount').style.display = "none";
		$('studentNameTr').style.display = "none";
		//$('txtTranAmt').disabled = true;
		if(branchID=='6100'){
			$("schoolFee").style.display = "none";
			$("TVFee").style.display="none";
			$("electricFee").style.display="";
		}else if(branchID=='5200'){
			$("schoolFeeInfo").style.display = "none";
		}
	}else if((key == "100060_000_0000"||key == "100080_000_0000")&&branchID=='2400'){//100080吉林有限电视费功能
		querySignBank();
		$("SignBankHotTr").style.display = "none";
		$("SignBankTr").style.display = "";
		$("txtTranAmt").disabled=false;
	}else if(key == "100073_000_0000"&&branchID=='2400'){
		querySignBank();
		$("SignBankTr").style.display = "none";
		$("SignBankHotTr").style.display = "";
		$("txtTranAmt").disabled=true;
	}else if(key == "100101_000_0000"&&branchID=='8700'){
		$("feeChargeTypeTr").style.display = "";
	}else if(key != "100101_000_0000"&&branchID=='8700'){
		$("feeChargeTypeTr").style.display = "none";
		cleanTableBody("detailTableBody");
	}
	else{
		if(branchID=='6100'){
			$('school').style.display = "none";
		}else if(branchID=='5200'){
			$("cityInfoTr").style.display = "none";
			$("schoolInfoTr").style.display = "none";
		}
		$('schoolNm').style.display = "none";
		if(key=="100054_000_0000"){
			$("nontax").style.display = "";
			$('feeNumber').style.display = "none";
		}else{
			$('feeNumber').style.display = "";
			$("nontax").style.display = "none";
		}
		$('feeNumber2').style.display = "none";
		$("UserNm").style.display = "none";
		$('feeNo').value = '';
		$("nextButton").disabled = false;
		$("otherFee").style.display = "";
		$("prefectureTr").style.display = "none";
		$("countyTr").style.display = "none";
		$("waterSupplyTr").style.display = "none";
		$('CustomerName2').style.display = "none";
		$('MeterAddress').style.display = "none";
		$('OweAmount').style.display = "none";
		$('BalanceAmount').style.display = "none";
		$('studentNameTr').style.display = "none";
		if(branchID=='6100'){
			$("schoolFee").style.display = "none";
			if(key == "100080_000_0000"){
				$("otherFee").style.display = "none";
				$("TVFee").style.display="";
			}else if(key == "100093_000_0000"){
				$("waterSupplyTr").style.display = "";

				$('feeNumber').style.display = "none";
				$('feeNumber2').style.display = "";
				$('otherFee').style.display = "none";
				$('CustomerName2').style.display = "";
				$('MeterAddress').style.display = "";
				$('OweAmount').style.display = "";
				$('BalanceAmount').style.display = "";
				$("WaterFee").style.display="";
			}
			else{
				$("TVFee").style.display="none";
			}
			$("electricFee").style.display="none";
		}else if(branchID=='5200'){
			$("schoolFeeInfo").style.display = "none";
		}
		//$('txtTranAmt').disabled = false;
	}
	var fc = tmpKey[0];
	var feeDetails = $('feeDetails');
	var feeFa=$('feeWay').value;
	if(branchID=='2400'){
		$('feeNo').value='';

	}
	var payNb = feeFa+$('feeNo').value;
	while(feeDtailArr.length>0)
		feeDetails.removeChild(feeDtailArr.pop());
	$("AmtFlagTr").style.display="none";


	if(payNb==undefined||payNb=="")
		return;
	

	$("feeAmount").innerHTML = "";
	document.submitForm.msgDesc.value = "";
	document.submitForm.msgValue.value = "";
	if(fc==undefined||fc=="")
		return;

	feeDtailArr.push(newFeeDetail("","正在查询缴费项目明细..."));
	feeDetails.appendChild(feeDtailArr[0]);
	if(key=="100091_000_0000"){
		var params = '&feeCode='+fc;
		 params += '&feeNo='+feeNo;
		 if(branchID=='5200'){
			 params  += '&backup1='+$('schoolInfo').options[$('schoolInfo').selectedIndex].value;
		 }else{			 
		 	params += '&backup1='+schoolName+"|"+schoolNameCN;
		 }
	}
	
	else{
		var params = '&feeCode='+fc;
		 params += '&feeNo='+payNb;
	}
	if(tmpKey.length>=2){
		params += '&provinceCode='+tmpKey[1];
	}
	if(tmpKey.length>=3){
		params += '&cityCode='+tmpKey[2];
	}
	if(key=="100090_000_0000"){
	   if(feeNo.length == 10 || feeNo.length == 16){
	    }
	   else{
		   alert("请选输入10位或16位的缴费号码");
		    return;
		   }
	}
	sendAjaxRequest("post", "<%=utb.getURL("getFeeDetail.do")%>", params, feeDetailResponse);
}
function queryFeeDetail1(){
	<%if("6100".equals(branchID)){ %>
	$("WaterFee").style.display="none";
	<%} %>

	var branchID = <%=branchID%>;
	var feeNo = $('feeNo').value;
	
	var key = $('feeCode').value;
	var schoolN = $('schoolName').options[$('schoolName').selectedIndex].value;
	var schoolNameCN = $('schoolName').options[$('schoolName').selectedIndex].text;
	var schoolName = schoolN.split('|')[0];
	var tmpKey = nvl(key,"").split("_");
	if(key=="100090_000_0000"){
		$("feeFa").style.display = "";
	}else{
		$("feeFa").style.display = "none";
	}
	
	if(key=="100091_000_0000"){
		$("waterSupplyTr").style.display = "none";
		$('feeNumber').style.display = "none";
		$('feeNumber2').style.display = "none";
		if(branchID=='6100'){
			$('school').style.display = "";
		}else if(branchID=='5200'){
			$('cityInfoTr').style.display = "";
			$('schoolInfoTr').style.display = "";
		}
		$('schoolNm').style.display = "";
		$("nextButton").disabled = false;
		$("otherFee").style.display = "none";
		$('CustomerName2').style.display = "none";
		$('MeterAddress').style.display = "none";
		$('OweAmount').style.display = "none";
		$('BalanceAmount').style.display = "none";
		if(branchID=='6100'){
			$("schoolFee").style.display = "";
		}
	}
	//lym add
	else if(key == "100052_000_0000"){
		$('feeNumber').style.display = "none";
		$('feeNumber2').style.display = "none";
		if(branchID=='6100'){
			$('school').style.display = "none";
		}else if(branchID=='5200'){
			$('cityInfoTr').style.display = "none";
			$('schoolInfoTr').style.display = "none";

		}
		$('schoolNm').style.display = "none";
		$("nextButton").disabled = false;
		$("otherFee").style.display = "none";
		$("UserNm").style.display = "";
		$("prefectureTr").style.display = "";
		$("countyTr").style.display = "";
		$("waterSupplyTr").style.display = "none";
		$('CustomerName2').style.display = "none";
		$('MeterAddress').style.display = "none";
		$('OweAmount').style.display = "none";
		$('BalanceAmount').style.display = "none";
		var countyCodesi = $('county').options[$('county').selectedIndex].value;
		if(countyCodesi == "" || countyCodesi==undefined){
			alert("请选择供电局");
			return;
		}
	}
	else{
		if(branchID=='6100'){
			$('school').style.display = "none";
		}else if(branchID=='5200'){
			$('cityInfoTr').style.display = "none";
			$('schoolInfoTr').style.display = "none";
		}
		$('schoolNm').style.display = "none";
        if(key == "100054_000_0000"){
			$('nontax').style.display = "";
			$('feeNumber').style.display = "none";
		}else{
			$('nontax').style.display = "none";
			$('feeNumber').style.display = "";
		}
	
		$('feeNumber2').style.display = "none";
		$("UserNm").style.display = "none";
		$("nextButton").disabled = false;
		$("otherFee").style.display = "";
		$("prefectureTr").style.display = "none";
		$("countyTr").style.display = "none";
		$("waterSupplyTr").style.display = "none";
		$('CustomerName2').style.display = "none";
		$('MeterAddress').style.display = "none";
		$('OweAmount').style.display = "none";
		$('BalanceAmount').style.display = "none";
		if(branchID=='6100'){
			$("schoolFee").style.display = "none";
			if(key == "100093_000_0000"){	
				$("WaterFee").style.display = "";
				$("waterSupplyTr").style.display = "";
				$('feeNumber2').style.display = "";
				$('feeNumber').style.display = "none";
				$('otherFee').style.display = "none";
				$('CustomerName2').style.display = "";
				$('MeterAddress').style.display = "";
				$('OweAmount').style.display = "";
				$('BalanceAmount').style.display = "";
			}
		}
	}
	var fc = tmpKey[0];
	var feeDetails = $('feeDetails');
	var feeFa=$('feeWay').value;
	var payNb = feeFa+$('feeNo').value;
	$("AmtFlagTr").style.display="none";
	//alert(payNb);
	
	if(payNb==undefined||payNb=="")
		return;
	while(feeDtailArr.length>0)
		feeDetails.removeChild(feeDtailArr.pop());
	$("feeAmount").innerHTML = "";
	document.submitForm.msgDesc.value = "";
	document.submitForm.msgValue.value = "";
	if(fc==undefined||fc=="")
		return;

	if(key=="100050_000_0000"&&branchID=="2200"){
		if(containSpecial(feeNo)){
			alert("缴费编号中不能包含空格或特殊字符");
			return false;
	     }
	}
	feeDtailArr.push(newFeeDetail("","正在查询缴费项目明细..."));
	feeDetails.appendChild(feeDtailArr[0]);
	if(key=="100091_000_0000"){
		var params = '&feeCode='+fc;
		 params += '&feeNo='+feeNo;
		 if(branchID=='5200'){
			 params  += '&backup1='+$('schoolInfo').options[$('schoolInfo').selectedIndex].value;
		 }else{			 
		 	params += '&backup1='+schoolName+"|"+schoolNameCN;
		 }
	}
	<!-- lym add -->
	else if(key == "100052_000_0000"){
		var params = '&feeCode='+fc;
		var countyCodes = $('county').options[$('county').selectedIndex].value.split('|');
		var countyName = $('county').options[$('county').selectedIndex].text;
		 params += '&feeNo='+feeNo;
		 params += '&backup1='+countyCodes[1];
		 params += '&backup2='+countyCodes[0];
	} else if(key=="100053_000_0000"){
		var backup1='NFDWDS';
		var params = '&feeCode='+fc+'&feeNo='+feeNo+'&backup1='+backup1;
	} else if((key=="100061_000_0000"||key=="100050_000_0000")&&branchID=="2200"){ //辽宁电费
		var backup1="";
		if(key=="100050_000_0000"){
			backup1=$("cityValue_2200_100050").value;
		}else {
			backup1=$("cityValue_2200").value;
		}
		var params = '&feeCode='+fc+'&feeNo='+feeNo+'&backup1='+backup1;
	}else if(key=="100030_000_0000"&&branchID=="2200"){
		var backup1=$("value_2200").value;
		var backup2=$("feeType_2200").value;
		var params = '&feeCode='+fc+'&feeNo='+feeNo+'&backup1='+backup1+'&backup2='+backup2;
	}else if(key=="100020_000_0000"&&branchID=="2200"){
		var backup1=$("value_2200").value;
		var backup2=$("feeType_2201").value;
		var params = '&feeCode='+fc+'&feeNo='+feeNo+'&backup1='+backup1+'&backup2='+backup2;
	}else if(key=="100050_000_0000"&&branchID=="1990"){
		var backup1=$("companyName_1990").value;
		var params = '&feeCode='+fc+'&feeNo='+feeNo+'&backup1='+backup1;
	}else{
		var params = '&feeCode='+fc;
		   params += '&feeNo='+payNb;
	}
	if(tmpKey.length>=2){
		params += '&provinceCode='+tmpKey[1];
	}
	if(tmpKey.length>=3){
		params += '&cityCode='+tmpKey[2];
	}
	if(key=="100090_000_0000"){
	   if(feeNo.length == 10 || feeNo.length == 16){
	   }
	   else{
		   alert("请选输入10位或16位的缴费号码");
		    return;
		   }
	}
	if(branchID=='2400'&&key=="100060_000_0000"){
		var signBank = $('SignBank').value;
		params += '&backup1='+signBank;

	}
	if(branchID=='2400'&&key=="100080_000_0000"){//100080吉林有限电视费功能
		var signBank = $('SignBank').value;
		var backup2 ='0503';
		params += '&backup1='+signBank +  '&backup2='+backup2;
	}
	if(branchID=='2400'&&key=="100073_000_0000"){
		var signBank = $('SignBank').value;
		params += '&backup1='+signBank;
	}
	if(branchID=='8700'&&key=="100101_000_0000"){//100101宁夏个人网银社保缴费功能
		var feeChargeType = $('feeChargeType').value;//feeChargeType
		//var backup2 ='0503';
		//params += '&backup1='+signBank +  '&backup2='+backup2;
		params += '&backup1='+feeChargeType +'&branchId='+branchID;
	}
	sendAjaxRequest("post", "<%=utb.getURL("getFeeDetail.do")%>", params, feeDetailResponse);
}
function feeDetailResponse(contextData){
	var feeDetails = $('feeDetails');
	var branchId="<%=branchID%>";
	while(feeDtailArr.length>0)
		feeDetails.removeChild(feeDtailArr.pop());
	var errorMessage = contextData.getValueAt("hostErrorMessage");
	if(errorMessage == null){
		var msgDesc = nvl(contextData.getValueAt("msgDesc"),"");
		var msgValue = nvl(contextData.getValueAt("msgValue"),"");
		if($('feeCode').value == '100091_000_0000' && branchId=='5200'){
			$("AmtFlagTr").style.display=""
			$("studentNameTr").style.display="";
			var flag=msgValue.replace(msgValue.substring(1,0),'*');
			$("studentName").innerHTML= flag;
			document.submitForm.flag.value =flag;
			$("feeAmount").innerHTML = contextData.getValueAt("payAmount");
			$("txtTranAmt").value = contextData.getValueAt("payAmount");
		}else{
			//if(branchId=='2400'&&$('feeCode').value == '100073_000_0000'){
			if(branchId=='2400'&&$('feeCode').value == '100073_000_0000'){
				
			var msgValueNew = msgValue.split("|");
			if(msgValueNew[5].indexOf(".")==msgValueNew[5].length-1){
				msgValueNew[5] = msgValueNew[5].substring(0,msgValueNew[5].length-1);
			}
			var msgValueNew5 = toCashWithCommaAndDot(msgValueNew[5]);
			msgValue ='';
			for(var i=0;i<msgValueNew.length;i++){
				if(i==0){
					msgValue+=msgValueNew[0];
				}else if(i==5){
					msgValue+="|"+msgValueNew5;
				}else{
					msgValue+="|"+msgValueNew[i];
				}
			}
		}
		
		document.submitForm.msgDesc.value = msgDesc;
		document.submitForm.msgValue.value = msgValue;
		document.getElementById('arrFee').value = msgValue;
		var msgDescArr = msgDesc.split("|");
		var msgValueArr = msgValue.split("|");
		if(branchId=='2400'&&$('feeCode').value == '100080_000_0000'){//100080吉林有限电视费功能
			backup3Msg=msgValueArr[2];
			backup4Msg=msgValueArr[4];
			backup5Msg=msgValueArr[6];
			backup6Msg=msgValueArr[3];

		}
		if(branchId=='2400'&&$('feeCode').value == '100073_000_0000'){
		backup4Msg=msgValueArr[2];
		backup5Msg=msgValueArr[8];
		backup2MsgHot=msgValueArr[6];
		feeBalance=msgValueArr[5];
			backup3Msg=msgValueArr[7];
		$('txtTranAmt').value=feeBalance;
			showChinese('txtTranAmt','bigChineseShow');
			checkMoney('txtTranAmt');
		}
		if($('feeCode').value == '100093_000_0000'){
 			$('CustomerNameIn').value = msgValueArr[0];
 			$('MeterAddressIn').value = msgValueArr[1];
 			$('OweAmountIn').value = msgValueArr[2];
 			$('BalanceAmountIn').value = msgValueArr[3];
		}
		else if(($('feeCode').value=='100020_000_0000'||$('feeCode').value=='100030_000_0000')&&branchId=='2200'){
			while(feeDtailArr.length>0)
				feeDetails.removeChild(feeDtailArr.pop());
			var nx1 = newFeeDetail(msgDescArr[2]+":",msgValueArr[2]);
			var payAmountValue = contextData.getValueAt("payAmount");
			if (payAmountValue != null){
				$("AmtFlagTr").style.display="";
				$("feeAmount").innerHTML = payAmountValue;
				document.submitForm.Amountset.value= payAmountValue;
			}
			feeDtailArr.push(nx1);
			feeDetails.appendChild(nx1);
		}
		else if($('feeCode').value=='100061_000_0000'&&$('cityValue_2200').value=='2260'){
			while(feeDtailArr.length>0)
				feeDetails.removeChild(feeDtailArr.pop());
			var nx1 = newFeeDetail(msgDescArr[0]+":",msgValueArr[0]);
			var payAmountValue = contextData.getValueAt("payAmount");
			if (payAmountValue != null){
				$("AmtFlagTr").style.display="";
				$("feeAmount").innerHTML = payAmountValue;
				document.submitForm.Amountset.value= payAmountValue;
			}
			feeDtailArr.push(nx1);
			feeDetails.appendChild(nx1);
		}
		else if($('feeCode').value=='100053_000_0000'){
			document.submitForm.Amountset.value=msgValueArr[6];
			var tranAmt = msgValueArr[6];
				if(tranAmt!="0.00"){
					document.getElementById("txtTranAmt").value=tranAmt;
					document.getElementById("txtTranAmt").disabled=true;
					document.getElementById("txtTranAmtTip").innerHTML="请缴完欠费后再存入预缴款";
					$("bigChineseShow").innerHTML = toChineseCash(tranAmt);
				}
			var nx1 = newFeeDetail(msgDescArr[3]+":",msgValueArr[3]);
			var nx2 = newFeeDetail(msgDescArr[2]+":",msgValueArr[2]);
			var nx3 = newFeeDetail(msgDescArr[4]+":",msgValueArr[4]);
			var nx4 = newFeeDetail(msgDescArr[6]+":",msgValueArr[6]);
			feeDetails.appendChild(nx1);feeDetails.appendChild(nx2);feeDetails.appendChild(nx3);feeDetails.appendChild(nx4);
		}else if($('feeCode').value=='100101_000_0000'&&branchId=='8700'){//100101宁夏个人网银社保缴费功能
			var icoll = contextData.getElement("feeChargeQry_NX");
			var number ='1';
			for ( var i=0; i < icoll.size() ; i++ )
			{
				var kcoll = icoll.getElementAt(i);			
				insertRow(kcoll,i,number);
				number+=1;
			}
		}else{
			if($('feeCode').value == '100091_000_0000' && branchID=='5200'){
				$("AmtFlagTr").style.display=""
				$("studentNameTr").style.display="";
					document.submitForm.backup2.value = msgValue;
				$("studentName").innerHTML=msgValue.replace(msgValue.substring(1,0),'*');
				$("feeAmount").innerHTML = contextData.getValueAt("payAmount");
				$("txtTranAmt").value = contextData.getValueAt("payAmount");
			}else{
				
			var msgValueArrBuff = "";
		for(var i=0;i<msgDescArr.length;i++){
//			 如果是非税缴费，只显示到缴款状态说明（msgDescArr[7]）
			if("100054_000_0000"==$('feeCode').value && i==7){
				break;
			} 
			var tmp = msgDescArr[i];
			if(tmp!=null&&tmp!=undefined&&tmp!=""){
				if("100050_000_0000"==$('feeCode').value && branchId=='2200') {
					if(tmp=="用户名称"){
						var visiable = "";
						var valueUser = "" ;
						if(msgValueArr[i].length<=2) {
							msgValueArr[i] = "*"+ msgValueArr[i].substr(1,1);
						}else if(msgValueArr[i].length >=3 ) {
							valueUser = "" ;
							for(var a= 1; a< msgValueArr[i].length-1;a++) {
								valueUser +="*";
							}
							msgValueArr[i] = msgValueArr[i].substr(0,1)+valueUser + msgValueArr[i].substr(msgValueArr[i].length-1,1) ;


						}
					}
					if(tmp=="用电地址"){
						//msgValueArr[i] = msgValueArr[i].substr(0,5) + "*****";
						var visiable= "";
						var valueAdd ="";
						for(var a= 0; a< msgValueArr[i].length-9;a++) {
							valueAdd +="*";
						}
						msgValueArr[i] = valueAdd + msgValueArr[i].substr(msgValueArr[i].length-8,msgValueArr[i].length-1);
					}
					if(i!=0){
						msgValueArrBuff += "|"+msgValueArr[i];	
					}else{
						msgValueArrBuff+=msgValueArr[i];
					}
				}
				var nx = newFeeDetail(tmp+"：",msgValueArr[i] );
				feeDtailArr.push(nx);
				feeDetails.appendChild(nx);	
			}
	}
		if(msgValueArrBuff!=null&&msgValueArrBuff!=""){
			if("100050_000_0000"==$('feeCode').value && branchId=='2200') {
				document.submitForm.msgValue.value = msgValueArrBuff;
			}
		}
		var externDetail = feeCodeDescMapping[contextData.getValueAt("feeCode")+"_"+contextData.getValueAt("provinceCode")+"_"+contextData.getValueAt("cityCode")];
		for(var i=1;i<=5;i++){
			var tmp = externDetail["input"+i];
			if(tmp!=null&&tmp!=undefined&&tmp!=""){
				var tmpNode = getInput("backup"+i,externDetail["type"+i]);
				nx = newFeeDetail(tmp+"：",tmpNode);
				feeDtailArr.push(nx);
				feeDetails.appendChild(nx);
			}
		}
		var payAmountValue = contextData.getValueAt("payAmount");
		if (payAmountValue != null){
			$("AmtFlagTr").style.display="";
			$("feeAmount").innerHTML = contextData.getValueAt("payAmount");
			document.submitForm.Amountset.value= payAmountValue;
            if(contextData.getValueAt("feeCode")=="100090"){
    			$("txtTranAmt").value = contextData.getValueAt("payAmount");         
            }
		}
		/*if($('feeCode').value == '100095_000_0000'){
			var balInfo = $('subAccountNo').value;
			var balArr = balInfo.split('|');
			var bal = balArr[4];
			$("txtTranAmtTip").value = payAmountValue;
			if(payAmountValue != null){
				if(bal < payAmountValue){
					alert("缴费金额大于账户余额");
					$("nextButton").disabled = true;
				}
			}
			else{
				$("nextButton").disabled = true;
			}
		}*/
				}
			}
		}
	}else{
		if($('feeCode').value=='100091_000_0000'){
			if(branchId!='5200'){	
			$("feeNoTip").innerHTML="<liana:I18N name='查询失败，请核对学校及学号是否正确' />";
			changeClass('feeNoTip','tip_err');
			$("nextButton").disabled = true;
			return false;
			}else{
				alert(errorMessage);
			}
		}
		else if($('feeCode').value=='100050_000_0000' && branchId =="2200"){
			$("nextButton").disabled = true;
			alert("您输入的格式有误，请重新输入!");
		}
		else if(branchId=="2200"){
			$("nextButton").disabled = true;
			alert("您输入的格式有误，请重新输入!");
		}else{
			$("nextButton").disabled = true;
			alert(errorMessage);
			
		}
	}
	parent.sizeChange();
}
function switchFeeType(){
	var o = $("switchFeeType");
	if(o.value=="byArea"){
		o.value = "byBranch";
		$("provinceTr").style.display = "none";
		$("cityTr").style.display = "none";
		$("provinceCode").style.display = "none";
		$("cityCode").style.display = "none";
		o.innerHTML = o.byArea;
		queryFeeCodeList();
	}else{
		o.value = "byArea";
		$("provinceTr").style.display = "";
		$("cityTr").style.display = "";
		$("provinceCode").style.display = "";
		$("cityCode").style.display = "";
		o.innerHTML = o.byBranch;
		queryCityCode();
	}
	$("provinceCode").selectedIndex = 0;
	$("cityCode").selectedIndex = 0;
	parent.sizeChange();
}
function queryCityCode(){
	var cityCodes = $('cityCode');
	while(cityCodes.childNodes.length>0)
		cityCodes.removeChild(cityCodes.childNodes[0]);
	var tmpProvince = $('provinceCode').value;
	if(tmpProvince==undefined||tmpProvince==""){
		cityCodes.appendChild(newOption("","---请选择所属城市---"));
		queryFeeCodeList();
		return;
	}
	cityCodes.appendChild(newOption("","正在查询城市列表..."));
	var params = "";
	params +=  '&provinceCode='+tmpProvince;
	sendAjaxRequest("post", "<%=utb.getURL("getCityCodes.do")%>", params, responseCityCode);
}
function responseCityCode(contextData){
	var cityCodes = $('cityCode');
	while(cityCodes.childNodes.length>0)
		cityCodes.removeChild(cityCodes[0]);
	var errorMessage = contextData.getValueAt("hostErrorMessage");
	if(errorMessage == null){
		var icoll = contextData.getElement("iCityInfo");
		cityCodes.appendChild(newOption("","---请选择所属城市---"));
			for(var i=0;i<icoll.size();i++){
				var kcoll = icoll.getElementAt(i);
				cityCodes.appendChild(newOption(kcoll.getValueAt("cityCode"),kcoll.getValueAt("cityName")));
			}
		queryFeeCodeList();
	}else{
		alert(errorMessage);
	}
	parent.sizeChange();
}

// lym add
//获取广西县级市
function queryCountyList(){
	$('feeNo').value = '';
	var cityCode = $('prefecture').options[$('prefecture').selectedIndex].value;
	if(cityCode == undefined||cityCode == ""||cityCode==null){
		var county = $('county');
		while(county.options.length>0)
			county.removeChild(county.options[0]);
		county.appendChild(newOption("","---请选择县级供电局---"));
		return;
	}
	var params = "";
	params +=  '&cityCode='+cityCode;
	sendAjaxRequest("post", "<%=utb.getURL("getCountyCodes.do")%>", params, responseCountyCode);
}
function responseCountyCode(contextData){
	var errorMessage = contextData.getValueAt("hostErrorMessage");
	if(errorMessage == null){
		var county = $('county');
		while(county.options.length>0)
			county.removeChild(county.options[0]);
		var icoll = contextData.getElement("iCityInfo");
		
		if(icoll.size()==0){
			county.appendChild(newOption("","---无可缴费的供电局---"));
		}else{
			for(var i=0;i<icoll.size();i++){
				var kcoll = icoll.getElementAt(i);
				var op = newOption(kcoll.getValueAt("cityCode"),kcoll.getValueAt("cityName"));
				county.appendChild(op);
			}
		}
	}else{
		alert(errorMessage);
	}
}

function querySignBank(){
	var feeCode = document.getElementById("feeCode").value.substr(0,6);
	var branchId = <%=branchID%>;
	var params = "";
	params +=  '&feeCode='+feeCode + '&branchId='+branchId;
	sendAjaxRequest("post", "<%=utb.getURL("querySignBank.do")%>", params, responseCountyCode1);
}
function responseCountyCode1(contextData){
	var errorMessage = contextData.getValueAt("hostErrorMessage");
	var feeCode = contextData.getValueAt("feeCode");
	if(errorMessage == null){
		var SignBank = $('SignBank');
		while(SignBank.options.length>0)
			SignBank.removeChild(SignBank.options[0]);
		var icoll = contextData.getElement("ifeeSignBank");
			for(var i=0;i<icoll.size();i++){
				var kcoll = icoll.getElementAt(i);
				var op = newOption(kcoll.getValueAt("SignBankCode"),kcoll.getValueAt("SignBankName"));
				SignBank.appendChild(op);
			}
	}else{
		alert(errorMessage);
	}
}
function queryCityInfo(){
	$('feeNo').value = '';
	var feeCode = "100091";
	var params = "";
	params +=  '&feeCode='+feeCode;
	sendAjaxRequest("post", "<%=utb.getURL("006001_queryCityInfo.do")%>", params, responseQueryCityInfo);
}
function responseQueryCityInfo(contextData){
	var errorMessage = contextData.getValueAt("hostErrorMessage");
	if(errorMessage == null){
		var cityInfo = $('cityInfo');
		var icoll = contextData.getElement("iCityInfos");
		if(icoll.size()==0){
			cityInfo.appendChild(newOption("","---无可选缴费地区---"));
		}else{
			for(var i=0;i<icoll.size();i++){
				var kcoll = icoll.getElementAt(i);
				var op = newOption(kcoll.getValueAt("cityCode"),kcoll.getValueAt("cityName"));
				cityInfo.appendChild(op);
			}
		}
		queryschoolInfo();
	}else{
		alert(errorMessage);
	}
}
function queryschoolInfo(){
	$('feeNo').value = '';
	var feeCode = "100091";
	var cityInfo = $('cityInfo').options[$('cityInfo').selectedIndex].value;
	var params = "";
	params +=  '&cityCode='+cityInfo+
				'&feeCode='+feeCode;
	sendAjaxRequest("post", "<%=utb.getURL("006001_querySchoolInfo.do")%>", params, responseQuerySchoolInfo);
}
function responseQuerySchoolInfo(contextData){
	var errorMessage = contextData.getValueAt("hostErrorMessage");
	if(errorMessage == null){
		var schoolInfo = $('schoolInfo');
		var icoll = contextData.getElement("iCityInfos");
		if(icoll.size()==0){
			schoolInfo.appendChild(newOption("","---无可缴费的学校---"));
		}else{
			for(var i=0;i<icoll.size();i++){
				var kcoll = icoll.getElementAt(i);
				var op = newOption(kcoll.getValueAt("chargeItem"),kcoll.getValueAt("companyName"));
				schoolInfo.appendChild(op);
			}
		}
	}else{
		alert(errorMessage);
	}
}
function init(){
	validate("feeCode","feeCodeTip","inputForm");
	validate("feeNo","feeNoTip","inputForm");
	validate("payAcc","payAccTip","inputForm");
	validate("txtTranAmt","txtTranAmtTip","inputForm");
	//switchFeeType(); //未使用，选择其它城市的缴费项目
	var branchID = <%=branchID%>;
	queryFeeCodeList();		//查询费种
	defaultAccountSelection("payAcc");
	querySubAccount();		//查询账户余额
	queryCountyList();
	if(branchID=='5200'){
		queryCityInfo();
	}
	$("feeNumber").style.display = "";
	$("otherFee").style.display = "";
	$("txtTranAmt").value = "";
	//$("nextButton").disabled = "true";
	//queryFeeDetail();
}
function rechargeable(){
	 
	window.top.doTranDispatch("006501_showMobileRecharge.do");
}
function insertRow(k,i,number){//宁夏个人网银社保缴费功能返回内容添加
	$("resultTable").style.display = "";
	var payAmount =  k.getValueAt("payAmount");
	var msgDesc =  k.getValueAt("msgDesc");
	var msgValue =  k.getValueAt("msgValue");
	
	var msgDescSplit = msgDesc.split("|");
	var msgValueSplit = msgValue.split("|");
	
	var tbody = document.getElementById("detailTableBody");
	var rowIndex = tbody.rows.length + 1;
	
	var row = document.createElement("TR");
	row.className = "list_table_content";
	
	setTrStyle(row,i);
	//alert(msgDescSplit.length+"---"+msgValueSplit.length);
    var branchId = '<%= branchID %>';
    if(number=='1'){
    	var row_header = document.createElement("TR");
    	row_header.className = "list_table_content";
	    for(j=0;j<msgDescSplit.length;j++){
	    	var cell_header = document.createElement("TD");
	    	var temp = msgDescSplit[j];
	    	cell_header.innerHTML = temp;
	    	row_header.appendChild(cell_header);
    	}
	    var cell_header = document.createElement("TD");
		cell_header.innerHTML =  "操作";
		row_header.appendChild(cell_header);
		tbody.appendChild(row_header);
    }
    	for(j=0;j<msgValueSplit.length;j++){
    		if(j=='5'){
		    	var cell = document.createElement("TD");
		    	if(msgValueSplit[j].indexOf("(")>-1){
		    		var moneyType = msgValueSplit[j].substring(msgValueSplit[j].indexOf("(")+1,msgValueSplit[j].indexOf(")"));//取()中间值
		    		var moneyTypeSplit = moneyType.split(",");
			    	var selectMoney = document.createElement("select");
			    	selectMoney.id=msgValueSplit[2];
			    	selectMoney.options.add(new Option(moneyTypeSplit[0],moneyTypeSplit[0]));
			    	selectMoney.options.add(new Option(moneyTypeSplit[1],moneyTypeSplit[1]));
			    	cell.appendChild(selectMoney);
		    		
		    	}else{
		    		var moneyType = msgValueSplit[j].substring(msgValueSplit[j].indexOf("[")+1,msgValueSplit[j].indexOf("]"));//取[]中间值
		    		var moneyTypeSplit = moneyType.split(",");

			    	var cell = document.createElement("TD");
			    	cell.id = msgValueSplit[2];
			    	var temp = moneyTypeSplit[0]+"~"+moneyTypeSplit[1];
			    	cell.innerHTML = temp;
			    	row.appendChild(cell);
		    	}
		    	row.appendChild(cell);
    		}else{
		    	var cell = document.createElement("TD");
		    	var temp = msgValueSplit[j];
		    	cell.innerHTML = temp;
		    	row.appendChild(cell);
    		}
    	}
		    var cell = document.createElement("TD");
		    cell.innerHTML =  "<input type='radio' name='codeWord' id='codeWord' value='"+msgValueSplit[2]+"' />";
			row.appendChild(cell);
			tbody.appendChild(row);
}

/*
        表格每行加入颜色显示
   row为表格tr，i为行数
 */


function setTrStyle(row,i){
/* 	if(i=='0'){
		return;
	} */
	if(i%2)
		row.className = row.className+" bg1";
	else
		row.className = row.className+" bg2";
	
	var temp_f = row.onmouseover+"";
	if(temp_f.indexOf('{')!=-1){
		var temp_start=temp_f.indexOf('{')+1;
		var temp_end=temp_f.length-1;
		temp_f=temp_f.substring(temp_start,temp_end);
	}
	row.onmouseover = Function('if(this.getAttribute("prevStyle")==undefined)this.setAttribute("prevStyle",this.className);this.className = this.className+" bg3";'+temp_f);
	temp_f = row.onmouseout+"";
	if(temp_f.indexOf('{')!=-1){
		var temp_start=temp_f.indexOf('{')+1;
		var temp_end=temp_f.length-1;
		temp_f=temp_f.substring(temp_start,temp_end);
	}
	row.onmouseout = Function('this.className = this.getAttribute("prevStyle");'+temp_f);

}
	
function radioChecked(){
		var radioTemp = document.getElementsByName("codeWord");
		for(j=0;j<radioTemp.length;j++){
			if(radioTemp[j].checked){
				var codeWord = radioTemp[j].value;
			}
		};
		return codeWord;
};
</script>
</head>
<body onload="init();">
<div id="main">
	<form id="inputForm">
		<div class="text_title"><%= utb.getPosition() %></div>	
		<div class="step_nav_area">
			<span class="step_nav_title"><liana:I18N name="自助缴费流程" />：</span>
			<span class="step_nav_item"><liana:I18N name="选择缴费项目" /></span>
			<span class="step_nav_item"><liana:I18N name="选择付款账户" /></span>
			<span class="step_nav_item"><liana:I18N name="填写缴费信息" /></span>
			<span class="step_nav_item" skipped="true"><liana:I18N name="确认缴费信息" /></span>
		</div>
		<div class="step_flow_area">
			<div class="step_flow_title"><liana:I18N name="第一步" />:<liana:I18N name="选择缴费项目" /></div>
			
			<table width="100%" border="0" cellspacing="0" cellpadding="0" class="input_table">
				<col width="25%" />
				<col width="75%" />
				<tr>
					<td class="title"><span class="text_important">*</span><liana:I18N name="缴费项目" />：</td>
					<td>	
						<div id="feeCodeTip"></div>
						<select id="feeCode" onchange="queryFeeDetail(this.value)">
							<option value="">----<liana:I18N name="请选择缴费项目" />----</option>
						</select>　
						<a style="display:none" href="javascript:switchFeeType()" id="switchFeeType" byBranch="<liana:I18N name="选择开户行缴费项目" />" byArea="<liana:I18N name="选择其它地区缴费项目" />" value="byArea" ></a>
					</td>
				</tr>
				<tr style="display:none" id="feeFa">
					<td class="title"><span class="text_important">*</span><liana:I18N name="处罚决定书类别" />：</td>
					<td>
						<div id="feeFaTip"></div>
						<select id="feeWay" >
						     <option value="">----<liana:I18N name="请选择处罚决定书类别" />----</option>
							<option value="1"><liana:I18N name="简易程序处罚决定书" /></option>
							<option value="2"><liana:I18N name="行政处罚决定书" /></option>
						</select>
					</td>
				</tr>
				<tr style="display:none" id="school">
					<td class="title"><span class="text_important">*</span><liana:I18N name="缴费内容" />：</td>
					<td>
						<div id="feeFaTip1"></div>
						<select id="schoolName" onchange="queryFeeDetail1()">
						     <%= utb.getSelectOpt("PB_SCHOOL_NAME") %>
						</select>
					</td>
				</tr>
				<tr style="display:none" id="cityName_2200">
					<td class="title"><span class="text_important">*</span><liana:I18N name="缴费城市" />：</td>

					<td>
						<select id="cityValue_2200" style="width:135px">
							<%= utb.getSelectOpt("PB_CITY_2200") %>			<!-- 水费（鞍山、丹东、凤城） -->


						</select>
					</td>
				</tr>
				<tr style="display:none" id="cityName_2200_100050">
					<td class="title"><span class="text_important">*</span><liana:I18N name="缴费城市" />：</td>
					<td>
						<select id="cityValue_2200_100050" style="width:135px">
							<%= utb.getSelectOpt("PB_CITY_2200_100050") %>			<!-- 电费（阜新） -->

						</select>
					</td>
				</tr>
				<tr style="display:none" id="name_2200">
					<td class="title"><span class="text_important">*</span><liana:I18N name="缴费城市" />：</td>

					<td>
						<select id="value_2200" style="width:135px">
							<%= utb.getSelectOpt("PB_CITY_2201") %>		<!-- 电信、联通(沈阳、铁岭) -->
						</select>
					</td>
				</tr>
				<tr style="display:none" id="communicationFee_2200">
					<td class="title"><span class="text_important">*</span><liana:I18N name="业务号码类型" />：</td>
					<td>
						<select id="feeType_2200" style="width:135px">
						     <option value="G">手机</option>
						     <option value="F">固话</option>
						</select>
					</td>
				</tr>
				
				<tr style="display:none" id="communicationFee_2201">
					<td class="title"><span class="text_important">*</span><liana:I18N name="业务号码类型" />：</td>
					<td>
						<select id="feeType_2201" style="width:135px">
						     <option value="G">手机</option>
						     <option value="D">宽带</option>
						     <option value="F">固话</option>
						</select>
					</td>
				</tr>
				<tr style="display:none" id="eleCompany_1990">
					<td class="title"><span class="text_important">*</span><liana:I18N name="供电局" />：</td>
					<td>
						<select id="companyName_1990" style="width:135px">
						     <%= utb.getSelectOpt("COMPANYNAME_1990") %>
						</select>
					</td>

				</tr>
				<!-- lym add --> 
				<tr style="display:none" id="prefectureTr">
					<td class="title"><span class="text_important">*</span><liana:I18N name="所属地市" />：</td>
					<td>
						<div id="cityCodeTip"></div>
						<select id="prefecture" onchange="queryCountyList()">
							<option value="">----<liana:I18N name="请选择地市级" />----</option>
							<%= utb.getSelectOpt("PB_GX_CITY") %>
						</select>
					</td>
				</tr>
				<tr style="display:none" id="countyTr">
					<td class="title"><span class="text_important">*</span><liana:I18N name="供电局" />：</td>
					<td>
						<div id="cityCodeTip"></div>
						<select id="county" onchange="queryFeeDetail()">
							<option value="">----<liana:I18N name="请选择供电局"/>----</option>
						</select>
					</td>
				</tr>
		
				<tr style="display:none" id="waterSupplyTr">
					<td class="title"><span class="text_important">*</span><liana:I18N name="供水公司" />：</td>

					<td>
						<div id="waterSupplyTip"></div>
						<select id="waterSupply">
							<option value="">----<liana:I18N name="请选择供水公司" />----</option>
							<option value="1"><liana:I18N name="绿城水务" /></option>
							<option value="1"><liana:I18N name="淡村水厂" /></option>
						</select>
					</td>
				</tr>	
				<tr style="display:none" id="cityInfoTr">
					<td class="title"><span class="text_important">*</span><liana:I18N name="缴费地区" />：</td>
					<td>
						<div id="cityInfoip"></div>
						<div id="cityInfoTip"></div>
						<select id="cityInfo" onchange="querycityInfo()">
						</select>
					</td>
				</tr>		
				<tr style="display:none" id="schoolInfoTr">
					<td class="title"><span class="text_important">*</span><liana:I18N name="学校" />：</td>

					<td>
						<div id="schoolInfoTip"></div>
						<div id="schoolInfoTip"></div>
						<select id="schoolInfo">

						</select>
					</td>
				</tr>		
	<% if(branchID.equals("2400")){%>
				<tr >
					<td id="SignBankTr" class="title"><span class="text_important">*</span><liana:I18N name="请选择签约行" />：</td>
					<td id="SignBankHotTr" style="display:none" class="title"><span class="text_important">*</span><liana:I18N name="请选供热公司" />：</td>
					<td>
						<div id="SignBankTip"></div>
						<select id="SignBank" onchange="queryFeeDetail1()">
							<option value="">----<liana:I18N name="请选择签约行"/>----</option>
						</select>
					</td>
				</tr>
				<%} %>
				<tr id="feeChargeTypeTr" style="display:none">
					<td class="title"><span class="text_important">*</span><liana:I18N name="缴费方式" />：</td>
					<td>
						<div id="feeChargeTypeTip"></div>
						<select id="feeChargeType">
							<option value="0"><liana:I18N name="社会保障号"/></option>
							<option value="1"><liana:I18N name="核定单缴费"/></option>
						</select>
					</td>
				</tr>
				<!-- lym add end -->
				<tr>
					<td class="title" style="display:none" id="schoolNm"><span class="text_important">*</span><liana:I18N name="学号" />：</td>
					<td class="title" style="display:none" id="feeNumber"><span class="text_important">*</span><liana:I18N name="缴费号码" />：</td>
					<td class="title" style="display:none" id="feeNumber2"><span class="text_important">*</span><liana:I18N name="用户号" />：</td>
					<td class="title" style="display:none" id="UserNm"><span class="text_important">*</span><liana:I18N name="用电户号" />：</td>
					<td class="title" style="display:none" id="nontax"><span class="text_important">*</span><liana:I18N name="缴费识别码" />：</td>
					<td>
						<div id="feeNoTip"></div>
						<input id="feeNo" type="text" size="32" maxlength="32" onchange="queryFeeDetail1()"/>
					</td>	
				
				</tr>
				<tr style="display:none" id="provinceTr">
					<td class="title"><liana:I18N name="所属省份" />：</td>
					<td>
						<div id="provinceCodeTip"></div>
						<select id="provinceCode" onchange="queryCityCode()">
							<option value="">----<liana:I18N name="请选择所属省份" />----</option>
									<%= utb.getSelectOpt("PROVINCE_CODE") %>
						</select>
					</td>
				</tr>
				<tr style="display:none" id="cityTr">
					<td class="title"><liana:I18N name="所属城市" />：</td>
					<td>
						<div id="cityCodeTip"></div>
						<select id="cityCode" onchange="queryFeeCodeList()">
							<option value="">----<liana:I18N name="请选择所属城市" />----</option>
						</select>
					</td>
				</tr>
				<tr style="display:none" id="CustomerName2">
					<td class="title"><liana:I18N name="客户名称" />：</td>
					<td>
						<div id="CustomerName2Tip"></div>
						<input id="CustomerNameIn" type="text" size="32" maxlength="32" disabled="disabled"/>
					</td>
				</tr>
				<tr style="display:none" id="MeterAddress">
					<td class="title"><liana:I18N name="装表地址" />：</td>
					<td>
						<div id="MeterAddressTip"></div>
						<input id="MeterAddressIn" type="text" size="32" maxlength="32" disabled="disabled"/>
					</td>
				</tr>
				<tr style="display:none" id="OweAmount">	
					<td class="title"><liana:I18N name="总欠金额" />：</td>
					<td>
						<div id="OweAmountTip"></div>
						<input id="OweAmountIn" type="text" size="32" maxlength="32" disabled="disabled"/>
					</td>
				</tr>
				<tr style="display:none" id="BalanceAmount">	
					<td class="title"><liana:I18N name="结存余额" />：</td>
					<td>
						<div id="BalanceAmountTip"></div>
						<input id="BalanceAmountIn" type="text" size="32" maxlength="32" disabled="disabled"/>
					</td>
				</tr>	
				<tr></tr>
			</table>
		</div>
		<div class="step_flow_area">
			<div class="step_flow_title"><liana:I18N name="第二步" />:<liana:I18N name="选择付款账户" /></div>
			<table width="100%" border="0" cellspacing="0" cellpadding="0" class="input_table">
				<col width="25%" />
				<col width="75%" />
				<tr align="left">
					<td class="title"><span class="text_important">*</span><liana:I18N name="付款人账户" />：</td>
					<td class="left">
						<div id="payAccTip"></div>
						<select id="payAcc" onchange="querySubAccount(this);">
							<option value="">----<liana:I18N name="请选择付款账号" />----</option>
						<%IndexedCollection ic = utb.fetchAccList().keep("accountType","00[02]").keep("signFlag","2").keep("registMedium","2").icoll(); %>
						<%=utb.fetchAccList().keep("signFlag","2").keep("registMedium","1").merge(ic).format("<OPTION value='$accountNo|$accountType|$security|$currencyType|$openBranch|$registMedium'> $maskedAccountNo [$accountAlias]") %>
						</select>
					</td>
				</tr>
				<tr>
					<td class="title"><span class="text_important">*</span><liana:I18N name="余额" />：</td>
					<td>
						<div id="ajaxQueryLoadingDiv" style="float:right;display:none;">正在查询中，请您稍候......</div>
						<select id="subAccountNo" style="width:350px">
						<option value="">----<liana:I18N name="请选择账户币种" />----</option>
						</select>
					</td>
				</tr>
			</table>
		</div>
		<div class="step_flow_area">
			<div class="step_flow_title"><liana:I18N name="第三步" />: <liana:I18N name="填写缴费信息" /></div>
			<table width="100%"  border="0" cellspacing="0" cellpadding="0" class="input_table">
				<col width="25%" />
				<col width="75%" />
				<tbody  id="feeDetails">

				<tr id="AmtFlagTr" style="display:none">
					<td class="title"><liana:I18N name="需要缴费金额" />：</td>
					<td>
						<div id="feeAmount"></div>

					</td>
				</tr>
				<tr id="studentNameTr" style="display:none">
					<td class="title"><liana:I18N name="学生姓名" />：</td>
					<td>
						<div id="studentName"></div>
					</td>
				</tr>
				<tr>
					<td class="title"><span class="text_important">*</span><liana:I18N name="缴费金额" />：</td>
					<td>
						<div id="txtTranAmtTip"></div>
						<input id="txtTranAmt" type="text" class="currency" size="32" maxlength="18" onkeyup="showChinese('txtTranAmt','bigChineseShow')" onblur="checkMoney(this.id);showChinese('txtTranAmt','bigChineseShow')"/>
					</td>
					<td class="title" style="display:none" id="arrFee"></td>
				</tr>
				<tr>
					<td class="title"><liana:I18N name="付款金额大写" />：</td>
					<td>
						<span id="bigChineseShow"></span>
					</td>
				</tr>
			<table id="resultTable" name="resultTable" class="list_table" width = "100%" style="display:none"><!-- 宁夏个人网银社保缴费功能 -->
				<caption id="accountInfo"></caption>
					<tr class="list_table_header" align="center"  style="cursor: pointer">
<%--  					    <td width="20%" nowrap><liana:I18N name="产品名称" /></td>
						<td width="10%" nowrap><liana:I18N name="份额" /></td>
						<td width="25%" nowrap><liana:I18N name="账号" /></td>
					    <td width="10%" nowrap><liana:I18N name="起息日" /></td>
		                <td width="10%" nowrap><liana:I18N name="结束日" /></td>
						<td width="10%" nowrap><liana:I18N name="操作" /></td>	 --%>								 			
					</tr>
				<tbody id="detailTableBody" align="right" >
				</tbody>
			</table>
				</tbody>
			</table>
		</div>
		<div align="center">
			<%= utb.getButton("nextButton","下一步","javascript:if(validateOnSubmit('inputForm'))submitData()") %>
		</div>
	</form>
	</div>
	<div id="otherFee" style="display:none">
	<%=TipsUtil.getHtmlTips(request,(String)sessionCtx.getDataValue("session_branchId")) %>
	</div>
	<div id="schoolFeeInfo" style="display:none">






		<div id='tips_sty'>
			<ul>
				<li><span>温馨提示：</span></li>
				<li>1.如需发票，请与缴费学校联系。</li>
				<li>2.因学号输错导致的损失由客户承担，缴费款项无法退回。</li>

			</ul>
		</div>
	</div>
	<%if("6100".equals(branchID)){ %>
	<div id="schoolFee" style="display:none">
		<div id='tips_sty'>
			<ul>
				<li><span>提示：</span></li>
				<li>1.请在下拉列表中选择缴费项目，输入缴费号码；</li>
				<li>2.请仔细核对缴费号码；</li>
				<li>3.应缴金额是应缴费用总额，不会因为对此项缴费内容进行过缴费而改变，如果您是分期缴款，请确认分期缴款的总额不要大于应缴金额。</li>
			</ul>
		</div>
	</div>
	<div id="ElectricFee" style="display:none">

		<div id='tips_sty'>
			<ul>
				<li><span>提示：</span></li>
				<li>1.请选择您所在的地市与供电局；</li>
				<li>2.用电户号是供电局提供给您的客户编号，如有疑问请咨询当地供电局；</li>
				<li>3.如页面提示“供电局交易失败！”，请确认用电户号输入是否正确。</li>
			</ul>
		</div>
	</div>
	<div id="TVFee" style="display:none">
		<div id="WaterFee" style="display:none">
		<div id='tips_sty'>
			<ul>
				<li><span>提示：</span></li>
				<li>1.缴费号码是您机顶盒的编号，有卡标清机的编号由16位数字或字母组成，字母区分大小写，在您机顶盒IC卡条形码下方；无卡标清机以及高清机编号为11位纯数字，在机顶盒后方的白色标签上；</li>
				<li>2.缴费金额为10元-2000元。</li>

			</ul>
		</div>
	</div>
	<div id="WaterFee" style="display:none">
		<div id='tips_sty'>
			<ul>
				<li><span>提示：</span></li>
				<li>1.缴费号码是供水公司提供给您的客户编号，如有疑问请咨询供水公司。</li>

			</ul>
		</div>
	</div>
	<%} %>
	<%if("8700".equals(branchID)){ %>
			<div id='tips_sty'>
				<ul>
					<li><span>温馨提示：</span></li>
					<li>1.本功能下的通讯缴费为实时缴费，只支持本地固话或手机号码缴费，如需为外地手机号充值，请使用<a href="javascript:rechargeable();">"乐享生活---全国手机充值"</a>功能。</li>
					<li>2.交通罚款只支持缴纳编号以"64"开头的处罚决定书。</li>
				</ul>
			</div>
	<%}%>
	<%if("2200".equals(branchID)){ %>

			<div id='tips_sty'>
			<span><liana:I18N name="温馨提示" />：</span>
				<ul id ="wenxintishi">
					<li>1.确认支付前，请您认真核对缴费号码、缴费金额，以防止由于错误输入给您带来的损失和不便。</li>
					<li>2.为固话号码缴费时，请您输入区号+固话号码。</li>
					<li>3.宽带缴费前，请您咨询当地联通、电信营业厅，确认您宽带套餐的类型和资费情况。</li>
				</ul>
			</div>
	<%} %>
	<form name="submitForm" action="006001_feeChargeCfm.do" method="post">
		<%=utb.getRequiredHtmlFields(false)%> 
		<input name="feeCode" type="hidden" />
		<input name="feeNo" type="hidden" />
		<input name="payAccount" type="hidden" />
		<input name="customerName" type="hidden"  value="<%=sessionCtx.getDataValue("session_customerNameCN") %>" />
		<input name="payAmount" type="hidden" />
		<input name="currencyType" type="hidden" />
		<input name="registMedium" type="hidden" />
		<input name="branchId" type="hidden" value="<%=sessionCtx.getDataValue("session_branchId")%>" />
		<input name="cityCode" type="hidden" />
		<input name="cityName" type="hidden" />
		<input name="provinceCode" type="hidden" />
		<input name="provinceName" type="hidden" />
		<input name="backup1" type="hidden" />
		<input name="backup2" type="hidden" />
		<input name="backup3" type="hidden" />
		<input name="backup4" type="hidden" />
		<input name="backup5" type="hidden" />
		<input name="msgDesc" type="hidden" value="" />
		<input name="msgValue" type="hidden"  value=""/>
		<input name="Amountset" type="hidden"/>
		<input name="flag" type="hidden" />
		<input name="remark" type="hidden" />
	</form>
</body>
</html>


WITH RPL(BRH_PARENTID, BRH_ID, BRH_NAME, BRH_LEVEL,INIT_BRANCHID) AS ( SELECT ROOT.BRH_PARENTID, ROOT.BRH_ID, ROOT.BRH_NAME, ROOT.BRH_LEVEL, ROOT.BRH_ID FROM IM_BRANCH ROOT WHERE ROOT.BRH_ID = ? UNION  ALL SELECT CHILD.BRH_PARENTID, CHILD.BRH_ID, CHILD.BRH_NAME, CHILD.BRH_LEVEL, PARENT.INIT_BRANCHID FROM RPL PARENT, IM_BRANCH CHILD WHERE PARENT.BRH_PARENTID = CHILD.BRH_ID AND  (CHILD.BRH_LEVEL<PARENT.BRH_LEVEL)) select a.*,b.PIF_NAME,c.CIT_NAME from (select * from PB_FEE_CODE_RELATION where FCR_EXCLUSIVE='0' and FCR_BRANCH_ID in (select BRH_ID from RPL) and ((FCR_PROVINCE='000' or FCR_PROVINCE=?) and (FCR_CITY='0000' or FCR_CITY=?)) union all select * from PB_FEE_CODE_RELATION where (FCR_EXCLUSIVE='1' and (FCR_BRANCH_ID=? and ((FCR_PROVINCE='000' or FCR_PROVINCE=?) and (FCR_CITY='0000' or FCR_CITY=?))))) a left join PUB_PROVINCEINFO b on a.FCR_BRANCH_ID=b.PIF_CODE left join PUB_CITYINFO c on a.FCR_BRANCH_ID=c.CIT_NAME




自助缴费添加缴费项目 脚本：

22378(刘俊丽) 11:29:53
--自建电费缴费公司相关信息初始化
insert into pb_fee_relation values ('4900','491105160201','100050','2','0','1','济源市电业局','4911','济源市','0','');
insert into pb_fee_relation values ('4900','511005165011','100050','2','0','1','确山县供电公司','5110','驻马店市','0','');
insert into pb_fee_relation values ('4900','513005168671','100050','2','0','1','淅川县供电公司','5130','南阳市','0','');
insert into pb_fee_relation values ('4900','513005168701','100050','2','0','1','桐柏县供电公司','5130','南阳市','0','');
insert into pb_fee_relation values ('4900','493005166621','100050','2','0','1','伊川县供电公司','4930','洛阳市','0','');
insert into pb_fee_relation values ('4900','505005160911','100050','2','0','1','渑池县供电公司','5050','三门峡市','0','');
insert into pb_fee_relation values ('4900','502005163161','100050','2','0','1','濮阳市供电公司','5020','濮阳市','0','');
commit;

--自建燃气费缴费公司相关信息初始化
insert into pb_fee_relation values ('4900','491007160061','100070','3','0','1','荥阳市燃气公司','4910','郑州市','0','');
commit;


insert into pb_fee_relation values ('1600','123456789','100050','2','0','1','yancy供电公司','9999','yancy市','0','');
commit;
