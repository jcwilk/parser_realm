require 'sinatra'
require 'pry'
require 'open-uri'
require 'rest-client'
require 'json'
require 'time'

ID_MAP = {
  2592 => 'def',
  2591 => 'att',
  2593 => 'spd',
  2636 => 'dex',
  2613 => 'wis',
  2612 => 'vit',
  2794 => 'mana',
  2793 => 'life'
}

FP_400_PLUS = (-103...-108).to_a
TREASURES = (3184...3199).to_a
ALL_DESIRED = FP_400_PLUS+TREASURES

def map_if_exist(id)
  return ID_MAP[id] if ID_MAP[id]
  return id.to_s+"treasure" if TREASURES.include?(id)
  return id.to_s+"fp" if FP_400_PLUS.include?(id)
  id
end

get '/*' do
  rows = []
  ALL_DESIRED.each do |id|
    page = RestClient.get('http://www.realmeye.com/offers-to/sell/'+id.to_s)
    trade_table_json = page.match(/renderOffersTable\("[^"]*",(\[[^)]*?)\)/)[1]
    rows+= JSON.parse(trade_table_json)
  end
  preamble = "<html>
<head>
<style type='text/css'>
td {
  border-right: 1px solid black;
  border-top: 1px solid black;
}
</style>
<body>
<table style='border-top: 1; border-right: 1'>
<thead><th>slingin</th><th>cravin</th><th>brobocop</th><th>thrown up</th><th>last spotted</th></thead>
<tbody>"
  content = rows.map do |row_data|
    sell_quantities = row_data[1]
    sell_descriptions = []

    row_data[0].each_with_index do |item,i|
      sell_descriptions << sell_quantities[i].to_s+"x"+map_if_exist(item).to_s
    end

    buy_quantities = row_data[3]
    buy_descriptions = []

    row_data[2].each_with_index do |item,i|
      buy_descriptions << buy_quantities[i].to_s+"x"+map_if_exist(item).to_s
    end

    added = (Time.parse(row_data[6]).to_s rescue nil)
    last_seen = (Time.parse(row_data[7]).to_s rescue nil)

    "<tr><td>"+sell_descriptions.join('</br>')+"</td><td>"+buy_descriptions.join('</br>')+"</td><td><a href='http://www.realmeye.com/offers-by/"+row_data[5]+"'>"+row_data[5]+"</a></td><td>"+added.to_s+"</td><td>"+last_seen.to_s+"</td></tr>"
  end
  postamble = "</tbody></table></body></html>"


  #binding.pry

  preamble+content.join+postamble
end
