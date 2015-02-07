require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'live_life_abroad' 

BLACKJACK_AMOUNT = 21

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
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end

  def to_image(card)
   card[0].downcase+"_"+card[1].to_s
  end

  def winner!(msg)
    @success = "<strong>You won!</strong> #{msg}"
    @hit_or_stay_displayed = false
    @play_again_displayed  = true
    session[:turn]         = "game_over"
  end

  def loser!(msg)
    @error = "<strong>You lost!</strong> #{msg}"
    @hit_or_stay_displayed = false
    @play_again_displayed  = true
    session[:turn]         = "game_over"
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
  session[:turn] = "player"
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

  if calculate_total(session[:player_cards]) == BLACKJACK_AMOUNT
    winner!("You hit blackjack!")
  end

  erb :game
end


post '/game/hit' do
  unless calculate_total(session[:player_cards]) >= BLACKJACK_AMOUNT
    session[:player_cards] << session[:deck].pop
  end

  player_total = calculate_total(session[:player_cards]) 
  if player_total > BLACKJACK_AMOUNT
    loser!("You bust at #{player_total}")
  elsif player_total == BLACKJACK_AMOUNT
    winner!("You hit blackjack!")
  end
  erb :game
end

post '/game/stay' do
  @hit_or_stay_displayed = false
  @success = "You chose to stay."
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @hit_or_stay_displayed = false

  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])

  if dealer_total > BLACKJACK_AMOUNT
    winner!("The dealer bust at #{dealer_total}. Your total was #{player_total}.")
  elsif dealer_total == BLACKJACK_AMOUNT
    loser!("The dealer hit Blackjack, you lose !")
  elsif dealer_total > player_total
    loser!("The dealer beat you #{dealer_total} to #{player_total}.")
  elsif dealer_total < BLACKJACK_AMOUNT # This could also be 17 (if there were more players). For 1 on 1, better to go until bust.
  # If there are more players, will have to add the "compare hands" option here. No need since dealer will always bust or win now.
  end

  erb :game
end

post '/game/dealer' do 
  @hit_or_stay_displayed = false
  if session[:turn] == "dealer"
    session[:dealer_cards] << session[:deck].pop
  end

  redirect '/game/dealer'
end

get '/reset' do 
  session.clear
  redirect '/'
end

get '/goodbye' do 
  erb :goodbye
end