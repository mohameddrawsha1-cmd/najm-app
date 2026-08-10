(() => {
  const sidebar = document.querySelector('#sidebar');
  const overlay = document.querySelector('[data-overlay]');
  const close = () => {
    sidebar?.classList.remove('open');
    overlay?.classList.remove('show');
  };
  document.querySelector('[data-menu]')?.addEventListener('click', () => {
    sidebar?.classList.toggle('open');
    overlay?.classList.toggle('show');
  });
  overlay?.addEventListener('click', close);
  document.querySelector('[data-password-toggle]')?.addEventListener('click', (event) => {
    const input = document.querySelector('#password');
    if (!input) return;
    input.type = input.type === 'password' ? 'text' : 'password';
    event.currentTarget.textContent = input.type === 'password' ? 'إظهار' : 'إخفاء';
  });
  document.querySelectorAll('.alert').forEach((alert) => {
    setTimeout(() => alert.classList.add('fade'), 5500);
  });
})();
