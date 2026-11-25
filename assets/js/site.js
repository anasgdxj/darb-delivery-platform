(() => {
  const root = document.documentElement;
  const themeToggle = document.getElementById('themeToggle');
  const themeIcon = document.getElementById('themeIcon');
  const storedTheme = (() => {
    try {
      return localStorage.getItem('darb-site-theme');
    } catch {
      return null;
    }
  })();
  const prefersDark = window.matchMedia?.('(prefers-color-scheme: dark)').matches ?? false;

  function setTheme(dark) {
    root.classList.toggle('dark', dark);
    if (themeToggle) {
      themeToggle.setAttribute('aria-pressed', String(dark));
      themeToggle.setAttribute('aria-label', dark ? 'تفعيل المظهر الفاتح' : 'تفعيل المظهر الداكن');
    }
    if (themeIcon) {
      themeIcon.innerHTML = dark
        ? '<path d="M20.5 15.5A8.5 8.5 0 0 1 8.5 3.5 8.5 8.5 0 1 0 20.5 15.5Z"/>'
        : '<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.93 4.93l1.42 1.42m11.3 11.3 1.42 1.42M2 12h2m16 0h2M4.93 19.07l-1.42-1.42m11.3-11.3 1.42-1.42"/>';
    }
    try {
      localStorage.setItem('darb-site-theme', dark ? 'dark' : 'light');
    } catch {
      // Theme still works for this page when storage is unavailable.
    }
  }

  setTheme(storedTheme ? storedTheme === 'dark' : prefersDark);
  themeToggle?.addEventListener('click', () => setTheme(!root.classList.contains('dark')));

  const menuToggle = document.getElementById('menuToggle');
  const mobilePanel = document.getElementById('mobilePanel');
  if (menuToggle && mobilePanel) {
    menuToggle.addEventListener('click', () => {
      const open = mobilePanel.classList.toggle('open');
      menuToggle.setAttribute('aria-expanded', String(open));
      menuToggle.setAttribute('aria-label', open ? 'إغلاق القائمة' : 'فتح القائمة');
    });
    mobilePanel.querySelectorAll('a').forEach((link) => {
      link.addEventListener('click', () => {
        mobilePanel.classList.remove('open');
        menuToggle.setAttribute('aria-expanded', 'false');
      });
    });
  }

  const cities = {
    damascus: { name: 'دمشق', code: 'DAMASCUS / SY', description: 'نقطة انطلاق شبكة دازريفو ومساراتها.' },
    aleppo: { name: 'حلب', code: 'ALEPPO / SY', description: 'مسارات للمتاجر والتوصيل المستقل.' },
    homs: { name: 'حمص', code: 'HOMS / SY', description: 'ربط الطلبات المحلية بمسارات السائقين.' },
    hama: { name: 'حماة', code: 'HAMA / SY', description: 'تجربة توصيل مرنة بحسب توفر الخدمة.' },
    latakia: { name: 'اللاذقية', code: 'LATAKIA / SY', description: 'امتداد شبكة دازريفو نحو الساحل.' }
  };
  const cityButtons = document.querySelectorAll('[data-city]');
  cityButtons.forEach((button) => {
    button.addEventListener('click', () => {
      const city = cities[button.dataset.city];
      const name = document.getElementById('cityName');
      const code = document.getElementById('cityCode');
      const description = document.getElementById('cityDescription');
      if (!city || !name || !code || !description) return;
      cityButtons.forEach((item) => item.setAttribute('aria-pressed', String(item === button)));
      name.textContent = city.name;
      code.textContent = city.code;
      description.textContent = city.description;
    });
  });

  const year = document.getElementById('year');
  if (year) year.textContent = String(new Date().getFullYear());
})();
