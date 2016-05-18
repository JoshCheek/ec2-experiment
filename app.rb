require 'sinatra/base'

App = Class.new(Sinatra::Base) { get('/') { <<HTML } }
<!doctype html>

<div id="display">
Not updated
</div>

<script>
var displayDiv = document.getElementById('display');

navigator.geolocation.getCurrentPosition(function(gp) {
displayDiv.textContent = "!Got the position!";
})
</script>
HTML
