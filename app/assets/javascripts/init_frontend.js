// Frontend components initialisation
//
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

document.addEventListener('turbolinks:load', function() {
  if (typeof window.GOVUKFrontend !== 'undefined') {
    window.GOVUKFrontend.initAll();
  }
  if (typeof window.MOJFrontend !== 'undefined') {
    window.MOJFrontend.initAll();
  }

  // The DPS header script registers initHeader via DOMContentLoaded,
  // which never re-fires on Turbolinks navigation. Dispatching a synthetic
  // DOMContentLoaded re-runs it against the fresh DOM on every navigation.
  if (document.querySelector('.connect-dps-common-header')) {
    document.dispatchEvent(new Event('DOMContentLoaded'));
  }
});
