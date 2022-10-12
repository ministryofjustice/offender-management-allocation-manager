function copyToClipboard(elementId) {
  navigator.clipboard.writeText(document.getElementById(elementId).innerText)
}