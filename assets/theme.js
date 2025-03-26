document.addEventListener('DOMContentLoaded', () => {
  const themeToggle = document.querySelector('#theme-toggle');
  themeToggle?.addEventListener('change', (e) => {
    document.body.dataset.theme = e.target.value;
  });
});
