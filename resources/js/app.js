import './bootstrap';
import './championship-events';

// Small, dependency-free affordances shared by the administrative screens.
if (document.body?.classList.contains('admin-page')) {
  document.querySelectorAll('form').forEach((form) => {
    form.addEventListener('submit', (event) => {
      if (event.defaultPrevented) return;
      if (form.dataset.submitted === 'true') return;
      form.dataset.submitted = 'true';
      const submit = form.querySelector('button[type="submit"], button:not([type])');
      if (submit && !submit.disabled) {
        submit.dataset.originalLabel = submit.innerHTML;
        submit.disabled = true;
        submit.innerHTML = '<span class="spinner-border spinner-border-sm me-1" aria-hidden="true"></span>Guardando…';
      }
    });
  });

  document.querySelectorAll('.admin-section-nav a[href^="#"]').forEach((link) => {
    link.addEventListener('click', (event) => {
      const target = document.querySelector(link.getAttribute('href'));
      if (!target) return;
      event.preventDefault();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      history.replaceState(null, '', link.getAttribute('href'));
    });
  });

  const firstError = document.querySelector('.alert-danger');
  if (firstError && window.location.hash === '#errors') {
    firstError.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }
}
