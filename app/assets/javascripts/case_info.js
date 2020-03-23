$(document).on("turbolinks:load", function(){
    if ($("#team_autocomplete").length > 0) {
        let element = document.querySelector('#team_autocomplete');
        let id = 'autocomplete-default';

        accessibleAutocomplete({
            element: element,
            id: id,
            source: team_names(),
            onConfirm: (val) => {
                document.getElementById("chosen_team").innerHTML = val.bold();
            }
        });
    }

    if ($(".case_information.edit").length > 0){
        if((document.getElementById('case_information_probation_service_scotland').checked) ||
            (document.getElementById('case_information_probation_service_northern_ireland').checked)){
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

function team_names() {
    return $('.team_information').data('team')
}

function remove_team() {
    if (document.getElementById("chosen_team").innerText.length > 0) {
        document.getElementById("chosen_team").innerText = "";
        documeent.getElementById("autocomplete-default").innerText = "";
        // clear the value in id 'autocomplete-default'
    }
}
