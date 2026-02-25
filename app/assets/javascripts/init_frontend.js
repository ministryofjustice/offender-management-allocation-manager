// Frontend components initialisation
//
let frontendInitialised = false;

document.addEventListener('DOMContentLoaded', function() {
  initFrontend({ dispatchDomContentLoaded: false });
});
document.addEventListener('turbolinks:load', function() {
  initFrontend({ dispatchDomContentLoaded: true });
});
document.addEventListener('turbolinks:before-render', function() {
  frontendInitialised = false;
});

document.addEventListener('turbolinks:before-cache', function() {
  // On a normal turbolinks navigation the body is replaced with fresh server HTML,
  // so govuk-frontend's data-*-init markers are never present on new elements.
  // However, turbolinks also caches the current live DOM (with markers already set)
  // before navigating away, and may later restore that snapshot as a preview.
  // Stripping the markers here ensures initAll() can safely re-run against a
  // restored cache snapshot without govuk-frontend throwing InitError.
  document.querySelectorAll('[data-module]').forEach(function(el) {
    Array.from(el.attributes)
      .filter(function(attr) { return attr.name.endsWith('-init'); })
      .forEach(function(attr) { el.removeAttribute(attr.name); });
  });
});

function initFrontend(options) {
  if (frontendInitialised) {
    return;
  }

  // Prevent re-entrance if a synthetic DOMContentLoaded is dispatched.
  frontendInitialised = true;

  if (typeof window.GOVUKFrontend !== 'undefined') {
    window.GOVUKFrontend.initAll();
  }
  if (typeof window.MOJFrontend !== 'undefined') {
    window.MOJFrontend.initAll();
  }

  // The DPS header script registers initHeader via DOMContentLoaded,
  // which never re-fires on Turbolinks navigation. Dispatching a synthetic
  // DOMContentLoaded re-runs it against the fresh DOM on every navigation.
  if (options && options.dispatchDomContentLoaded && document.querySelector('.connect-dps-common-header')) {
    document.dispatchEvent(new Event('DOMContentLoaded'));
  }
}
