$(document).on("turbolinks:load", function(){
    if ($("#team_autocomplete").length > 0) {
        let element = document.querySelector('#team_autocomplete');

        accessibleAutocomplete.enhanceSelectElement({
            selectElement: element
        });
    }

    if ($(".new_edit_case_information").length > 0){
        if((document.getElementById('edit_case_information_last_known_address_scotland').checked) ||
            (document.getElementById('edit_case_information_last_known_address_northern_ireland').checked)){
                hide_element();
        }
    }
});

function hide_element() {
    $('.optional-case-info').hide();
}

function show_element() {
    $('.optional-case-info').show();
}

function remove_team() {
    if (document.getElementById("chosen_team").innerText.length > 0) {
        document.getElementById("chosen_team").innerText = "";
        document.getElementsByName("input-autocomplete")[0].value = "";
    }
}
