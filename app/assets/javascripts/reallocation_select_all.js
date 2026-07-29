document.addEventListener('turbolinks:load', function() {
  document.querySelectorAll('[data-reallocation-case-selection]').forEach(function(form) {
    const selectAllCheckboxes = Array.from(form.querySelectorAll('[data-reallocation-select-all]'));
    const checkboxes = Array.from(form.querySelectorAll('[data-reallocation-case-checkbox]:not(:disabled)'));

    if (selectAllCheckboxes.length === 0 || checkboxes.length === 0) {
      return;
    }

    function syncSelectionState() {
      const allChecked = checkboxes.every(function(checkbox) { return checkbox.checked; });
      const anyChecked = checkboxes.some(function(checkbox) { return checkbox.checked; });

      selectAllCheckboxes.forEach(function(selectAll) {
        selectAll.checked = allChecked;
        selectAll.indeterminate = anyChecked && !allChecked;
      });
    }

    selectAllCheckboxes.forEach(function(selectAll) {
      selectAll.addEventListener('change', function() {
        checkboxes.forEach(function(checkbox) {
          checkbox.checked = selectAll.checked;
        });

        syncSelectionState();
      });
    });

    checkboxes.forEach(function(checkbox) {
      checkbox.addEventListener('change', syncSelectionState);
    });

    syncSelectionState();
  });
});
