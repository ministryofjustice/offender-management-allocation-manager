$(document).on("turbolinks:load", function(){
    if ($("#team_autocomplete").length > 0) {
        var element = document.querySelector('#team_autocomplete');

        accessibleAutocomplete.enhanceSelectElement({
            selectElement: element
        });
    }
});
