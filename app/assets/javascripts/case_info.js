$(document).on("turbolinks:load", function(){
    if ($(".edit_case_information").length > 0){
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




