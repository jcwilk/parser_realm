require 'action_view'
require 'sinatra'
require 'pry'
require 'open-uri'
require 'rest-client'
require 'json'
require 'time'


include ActionView::Helpers::DateHelper

POT_MAP = {
  2592 => 'Def',
  2591 => 'Att',
  2593 => 'Spd',
  2636 => 'Dex',
  2613 => 'Wis',
  2612 => 'Vit',
  2794 => 'Mana',
  2793 => 'Life'
}

TREASURE_MAP = {
  3184 => "Ankh (400)",
  3185 => "Eye (550)",
  3186 => "Mask (700)",
  3187 => "Cockle (450)",
  3188 => "Conch (550)",
  3189 => "Horn (650)",
  3190 => "Nut (450)",
  3191 => "Bolt (550)",
  3192 => "Femur (450)",
  3193 => "Ribcage (500)",
  3194 => "Skull (650)",
  3195 => "Candelabra (450)",
  3196 => "Cross (500)",
  3197 => "Necklace (400)",
  3198 => "Chalice (500)",
  3199 => "Ruby (600)"
}

FP_MAP = {
  -103 => "(400)",
  -104 => "(450)",
  -105 => "(500)",
  -106 => "(550)",
  -107 => "(600)",
  -108 => "(650)"
}

FP_600_PLUS = [-107,-108]
TREASURES_600_PLUS = [3186,3189,3194,3199]
ALL_DESIRED = FP_600_PLUS+TREASURES_600_PLUS

def sort_value(row)
  first = (Time.parse(row[7]).to_s rescue '00000')
  second = (Time.parse(row[6]).to_s rescue '00000')
  first+'|'+second
end

def map_if_exist(id, quantity)
  name = if POT_MAP[id]
      POT_MAP[id]
    elsif TREASURE_MAP[id]
      TREASURE_MAP[id]
    elsif FP_MAP[id]
      FP_MAP[id]
    else
      'misc'
    end

  return "#{quantity}x #{name}"
end

get '/*' do
  rows = []
  failed_urls = {}
  ALL_DESIRED.each do |id|
    url = 'http://www.realmeye.com/offers-to/sell/'+id.to_s
    begin
      page = RestClient.get(url)
      trade_table_json = page.match(/renderOffersTable\("[^"]*",(\[[^)]*?)\)/)[1]
      rows+= JSON.parse(trade_table_json)
    rescue RestClient::RequestFailed
      failed_urls[url] = $!.to_s
    end
  end
  preamble = "<html>
<head>
<style type='text/css'>
td {
  border-right: 1px solid black;
  border-top: 1px solid black;
}

html, body {
    width: 100%;
}
table {
    margin: 0 auto;
}
</style>
</head>
<body>
<table style='border-top: 1; border-right: 1'>
<thead><th>slingin</th><th>cravin</th><th>brobocop</th><th>thrown up</th><th>last spotted</th></thead>
<tbody>"
  error_content = []
  failed_urls.each do |url,error|
    error_content << "<tr><td colspan=5><a href='#{url}'>#{url}</a> failed with #{error.to_s.inspect}</td></tr>"
  end
  content = rows.sort_by{|row| sort_value(row) }.reverse.map do |row_data|
    sell_quantities = row_data[1]
    sell_descriptions = []

    row_data[0].each_with_index do |item,i|
      sell_descriptions << map_if_exist(item, sell_quantities[i])
    end

    buy_quantities = row_data[3]
    buy_descriptions = []

    row_data[2].each_with_index do |item,i|
      buy_descriptions << map_if_exist(item, buy_quantities[i])
    end

    added = (distance_of_time_in_words(Time.now,Time.parse(row_data[6])) rescue nil)
    last_seen = (distance_of_time_in_words(Time.now,Time.parse(row_data[7])) rescue nil)

    "<tr><td>"+sell_descriptions.join('</br>')+"</td><td>"+buy_descriptions.join('</br>')+"</td><td><a href='http://www.realmeye.com/offers-by/"+row_data[5]+"'>"+row_data[5]+"</a></td><td>"+added.to_s+"</td><td>"+last_seen.to_s+"</td></tr>"
  end
  postamble = "</tbody></table></body></html>"


  #binding.pry

  preamble+error_content.join+content.join+postamble
end
