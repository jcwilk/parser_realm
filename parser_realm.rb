require 'sinatra'
require 'pry'
require 'open-uri'
require 'rest-client'
require 'json'

get '/*' do
  page = RestClient.get('http://www.realmeye.com/offers-to/sell/'+params[:splat].first)
  trade_table_json = page.match(/renderOffersTable\("[^"]*",(\[[^)]*?)\)/)[1]
  rows = JSON.parse(trade_table_json)
  preamble = "<html>
<body>
<table>
<thead><th>items</th><th>dude</th></thead>
<tbody>"
  content = rows.map do |row_data|
    quantities = row_data[1]
    descriptions = []
    #binding.pry
    row_data[0].each_with_index do |item,i|
      descriptions << item.to_s+"x"+quantities[i].to_s
    end
    "<tr><td>"+descriptions.join(',')+"</td><td>"+row_data[5]+"</td></tr>"
  end
  postamble = "</tbody></table></body></html>"


  #binding.pry

  preamble+content.join+postamble
end
