document.addEventListener('turbolinks:load', function() {
  document.querySelectorAll('[data-reallocation-case-selection]').forEach(function(form) {
    const selectAll = form.querySelector('[data-reallocation-select-all]');
    const checkboxes = Array.from(form.querySelectorAll('[data-reallocation-case-checkbox]'));
    const continueButton = form.querySelector('[data-reallocation-continue-button]');

    if (form.dataset.reallocationCaseSelectionInitialised === 'true' || !selectAll || checkboxes.length === 0) {
      return;
    }

    form.dataset.reallocationCaseSelectionInitialised = 'true';

    function syncSelectionState() {
      const allChecked = checkboxes.every(function(checkbox) { return checkbox.checked; });
      const anyChecked = checkboxes.some(function(checkbox) { return checkbox.checked; });

      selectAll.checked = allChecked;
      selectAll.indeterminate = anyChecked && !allChecked;

      if (continueButton) {
        continueButton.disabled = !anyChecked;
      }
    }

    selectAll.addEventListener('change', function() {
      checkboxes.forEach(function(checkbox) {
        checkbox.checked = selectAll.checked;
      });

      syncSelectionState();
    });

    checkboxes.forEach(function(checkbox) {
      checkbox.addEventListener('change', syncSelectionState);
    });

    syncSelectionState();
  });
});
