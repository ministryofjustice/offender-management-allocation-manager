$(document).on("turbolinks:load", function(){
    if ($("#team_autocomplete").length > 0) {
        let element = document.querySelector('#team_autocomplete');
        let id = 'autocomplete-default';

        accessibleAutocomplete({element: element, id: id, source: team_names()});
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
