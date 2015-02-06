require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'live_life_abroad' 


helpers do 
 
  def calculate_total(cards) # cards will appear as nested array
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "ACE"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    # Correct for aces
    arr.select{|element| element == "ACE"}.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end

  def to_image(card)
   card[0].downcase+"_"+card[1].to_s
  end

end

before do 
  @hit_or_stay_displayed = true
end

get '/' do 
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/new_player' do 
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Please enter your name."
    halt erb (:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do 
  erb :bet
end

post '/bet' do 
  session[:total_cash] = params[:total_cash]
  redirect 'game'
end

get '/game' do 
    SUITS = ['HEARTS', 'DIAMONDS', 'SPADES', 'CLUBS']
    CARDS = ['ACE', 2, 3, 4, 5, 6, 7, 8, 9, 10, 'JACK', 'QUEEN', 'KING']
    # deck 
    session[:deck] = SUITS.product(CARDS).shuffle!
    # deal cards

    session[:dealer_cards] = []
    session[:player_cards] = []
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop

  if calculate_total(session[:player_cards]) == 21
    @success = "You hit blackjack!"
    @hit_or_stay_displayed = false
  end

  erb :game
end


post '/game/hit' do
  unless calculate_total(session[:player_cards]) >= 21
    session[:player_cards] << session[:deck].pop
  end

  if calculate_total(session[:player_cards]) > 21
    @error = "You bust."
    @hit_or_stay_displayed = false
  elsif calculate_total(session[:player_cards]) == 21
    @success = "You hit blackjack."
    @hit_or_stay_displayed = false
  end
  erb :game
end

post '/game/stay' do
  @hit_or_stay_displayed = false
  @success = "You chose to stay."
  @dealer_turn = true
  erb :game
end

get '/game/dealer' do
  @hit_or_stay_displayed = false

  if calculate_total(session[:dealer_cards]) > 21
    @success = "The Dealer Bust, you win !"
    @dealer_turn = false
  elsif calculate_total(session[:dealer_cards]) == 21
    @error = "The Dealer hit Blackjack, you lose !"
    @dealer_turn = false
  elsif calculate_total(session[:dealer_cards]) > calculate_total(session[:player_cards])  
    @error = "The Dealer beat you."
    @dealer_turn = false
  elsif calculate_total(session[:dealer_cards]) < 21
    @dealer_turn = true
  end

  erb :game
end

post '/game/dealer' do 
  @hit_or_stay_displayed = false
  unless @dealer_turn == false
    session[:dealer_cards] << session[:deck].pop
  end

  redirect '/game/dealer'
end

get '/reset' do 
  session.clear
  redirect '/'
end