$(document).on('turbolinks:load', function() {
  if (window.location.hash && window.location.hash.includes('!top')) {
    window.location.hash = window.location.hash.replace('!top', '');

    // Let the browser handle the hash first (important for tabs),
    // then we take over and scroll to the top (so any banner is seen)
    setTimeout(function() {
      window.scrollTo({top: 0, behavior: 'instant'});
    }, 10);
  }
});
