function createFunctionWithTimeout(callback, opt_timeout) {
    var called = false;
    function fn() {
      if (!called) {
        called = true;
        callback();
      }
    }
    setTimeout(fn, opt_timeout || 1000);
    return fn;
  }

function analytics_form_event(form_id, event_name, event_action) {
    var form = document.getElementById(form_id);
    form.addEventListener('submit', function(event) {
      event.preventDefault();
      gtag('send', 'event', event_name, event_action, {
        hitCallback: createFunctionWithTimeout(function() {
          form.submit();
        })
      });
    });
}



