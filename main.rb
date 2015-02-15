require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'live_life_abroad' 

BLACKJACK_AMOUNT = 21

helpers do 
 
  def calculate_total(cards) # cards will appear as nested array
    cards_value = cards.map{|element| element[1]}

    total = 0
    cards_value.each do |value|
      if value == "ACE"
        total += 11
      else
        total += value.to_i == 0 ? 10 : value.to_i
      end
    end

    # Correct for aces
    cards_value.select{|element| element == "ACE"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end

  def to_image(card)
   card_file_name = card[0].downcase+"_"+card[1].to_s

   return "<img class='card' src='/images/cards/#{card_file_name}.jpg'/>"
  end

  def end_of_game
    @hit_or_stay_displayed = false
    @play_again_displayed  = true
    session[:turn]         = "game_over"
  end

  def winner!(msg)
    win_bet
    @winner = "<strong>You won #{session[:bet_amount]}$ !</strong> #{msg}"
    end_of_game
  end

  def loser!(msg)
    lose_bet
    @loser = "<strong>You lost #{session[:bet_amount]}$ !</strong> #{msg}"
    end_of_game
  end

  def win_bet
    session[:total_cash] += session[:bet_amount]
  end

  def lose_bet
    session[:total_cash] -= session[:bet_amount]
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
  session[:total_cash] = 500
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Please enter your name."
    halt erb (:new_player)
  end

  session[:player_name] = params[:player_name]
  # If a new player is added, then his total_cash is reset to 500$
  redirect '/bet'
end

get '/bet' do 
  erb :bet
end

post '/bet' do 
  if params[:bet_amount].to_i == 0
    @error = "Please enter your bet. No playing for free here."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:total_cash]
    @error = "Wait a minute, you're trying to play with more than you have in the bank!"
    halt erb(:bet)
  end

  session[:bet_amount] = params[:bet_amount].to_i
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
    winner!("You hit Blackjack!")
  end

  erb :game
end


post '/game/hit' do
  unless calculate_total(session[:player_cards]) >= BLACKJACK_AMOUNT
    session[:player_cards] << session[:deck].pop
  end

  player_total = calculate_total(session[:player_cards]) 
  if player_total > BLACKJACK_AMOUNT
    loser!("You bust at #{player_total}.")
  elsif player_total == BLACKJACK_AMOUNT
    winner!("You hit Blackjack!")
  end
  erb :game, layout: false
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
  bet_amount   = session[:bet_amount] 

  if dealer_total > BLACKJACK_AMOUNT
    winner!("The dealer bust at #{dealer_total}. Your total was #{player_total}.")
  elsif dealer_total == BLACKJACK_AMOUNT
    loser!("The dealer hit Blackjack !")
  elsif dealer_total > player_total
    loser!("The dealer beat you #{dealer_total} to #{player_total}.")
  elsif dealer_total < 21 # This could also be 17 (if there were more players). For 1 on 1, better to go until bust.
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