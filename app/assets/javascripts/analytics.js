/**
 * Allow Google Tag Manager to track Turbolinks page views by pushing a custom event into the Data Layer.
 */
document.addEventListener("turbolinks:load", function() {
    dataLayer.push({ "event": "turbolinks:load" });
});
