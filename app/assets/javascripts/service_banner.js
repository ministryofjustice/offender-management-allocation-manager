document.addEventListener("turbolinks:load", function() {
    var buttons = document.getElementsByClassName('close-service-notification');

    for (var i = 0; i < buttons.length; i++) {
        if (localStorage.getItem(buttons[i].id)) {
            cancelThisNotification(buttons[i]);
        }
    }
});

function cancelThisNotification(element){
    var id = element.id;
    var parent = element.parentElement;

    parent.style.display = 'none';

    if (localStorage.getItem(id) === null) {
        localStorage.setItem(id, 'hidden');
    }
}
