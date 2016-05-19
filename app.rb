require 'sinatra/base'
require 'pp'
require 'erb'

App = Class.new(Sinatra::Base) { get('/') { erb <<HTML } }
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

<pre><%= ERB::Util.h env.pretty_inspect %></pre>
HTML
