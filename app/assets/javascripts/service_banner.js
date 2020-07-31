document.addEventListener("turbolinks:load", function() {
    let buttons = document.getElementsByClassName('close-service-notification');

    for (let item of buttons) {
        if(localStorage.getItem(item.id)) {
            cancelThisNotification(item);
        }
    }
});

function cancelThisNotification(element){
    let id = element.id;
    let parent = element.parentElement;

    parent.style.display = 'none';

    if (localStorage.getItem(id) === null) {
        localStorage.setItem(id, 'hidden');
    }
}
