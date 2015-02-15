$(document).ready(function() {
  player_hits();
  player_stays();
  dealer_hits();
}); 

function player_hits() {
  $(document).on('click', '#hit_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/game/hit',
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });
}

function player_stays() {
  $(document).on('click', '#stay_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/game/stay',
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });
}

function dealer_hits() {
  $(document).on('click', '#dealer_hit_form input', function() {
    $.ajax({
      type: 'POST',
      url: '/game/dealer',
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });
}
 