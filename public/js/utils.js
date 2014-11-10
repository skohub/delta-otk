function new_act(type) {
	var orderid = document.getElementById('orderid').value;
	if(!orderid) {
		alert('Введите номер заказа');
	} else {
		window.location.href='/act/new/'+type+'/'+orderid;
	}	
}