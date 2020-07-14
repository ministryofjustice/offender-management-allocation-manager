$(document).on("turbolinks:load", function(){
    if ($("#team_autocomplete").length > 0) {
        var element = document.querySelector('#team_autocomplete');

        accessibleAutocomplete.enhanceSelectElement({
            selectElement: element
        });
    }

    if ($(".new_edit_case_information").length > 0){
        if((document.getElementById('edit_case_information_last_known_address_scotland').checked) ||
            (document.getElementById('edit_case_information_last_known_address_northern_ireland').checked)){
            $('.optional-case-info').hide();
        }
    }

    $('.hide-optional-case-info').click(function() {
        $('.optional-case-info').hide();
    });

    $('.show-optional-case-info').click(function() {
        $('.optional-case-info').show();
    });
});

function current_team() {
    if ($(".new_edit_case_information").length > 0){
        var team_name = document.getElementById("chosen_team").innerText;
        if (team_name !== '') {
            return team_name
        }
    }
    return ''
}

function team_names() {
    return $('.team_information').data('team')
}

function remove_team() {
    if (document.getElementById("chosen_team").innerText.length > 0) {
        document.getElementById("chosen_team").innerText = "";
        document.getElementsByName("input-autocomplete")[0].value = "";
    }
}
