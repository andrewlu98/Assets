$(document).ready(function() {
	$('#addStock').click(function(event) {
		var stock = $('input[name=stock]').val();
		$('table').append('<td>' + stock + '</td><td>price</td><td>price</td><td>volume</td>');
	});
	$('#addPrice').click(function(event) {
		var price = $('input[name=price]').val();
		$('table').append('<td>Date</td><td>' + price + '</td><td>price</td><td>volume</td>');
	});
	$('#addDate_Submit').click(function(event) {
		var date = $('input[name=date]').val();
		$('table').append('<td>Date</td><td>price</td><td>' + date + '</td><td>volume</td>');
	});
});

/*$(document).ready(function() {
	$('#addStock').click(function(event) {
		var stock = $('input[name=stock]').val();
		///$('table').append('<tr><td>' + stock + '</td><td>price</td><td>price</td><td>volume</td></tr>');
	});
	$('#addPrice').click(function(event) {
		var price = $('input[name=price]').val();
		//$('table').append('<tr><td>Date</td><td>' + price + '</td><td>price</td><td>volume</td></tr>');
	});
	$('#addDate_Submit').click(function(event) {
		var date = $('input[name=date]').val();
		$('table').append('<tr><td>' + stock + '</td><td>p' + price + '</td><td>' + date + '</td><td>volume</td></tr>');
	});
});*/