document.addEventListener("turbolinks:load", function() {
    document.querySelectorAll(".card--clickable").forEach(function(e) {
        null !== e.querySelector("a") && e.addEventListener("click", function() {
            e.querySelector("a").click();
        });
    });
});