document.addEventListener("click", function(event) {
  if (event.defaultPrevented || event.target.closest("a")) {
    return;
  }

  const card = event.target.closest(".card--clickable");
  const link = card && card.querySelector("a");
  if (link) {
    link.click();
  }
});
