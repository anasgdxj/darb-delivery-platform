(() => {
  const root = document.documentElement;
  const themeToggle = document.getElementById('themeToggle');
  const themeIcon = document.getElementById('themeIcon');

  const getStoredTheme = () => {
    try {
      return localStorage.getItem('dazrevo-site-theme') || localStorage.getItem('darb-site-theme');
    } catch {
      return null;
    }
  };

  const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;

  function setTheme(dark) {
    root.classList.toggle('dark', dark);
    root.setAttribute('data-theme', dark ? 'dark' : 'light');
    if (themeToggle) {
      themeToggle.setAttribute('aria-pressed', String(dark));
      themeToggle.setAttribute('aria-label', dark ? 'تفعيل المظهر الفاتح' : 'تفعيل المظهر الداكن');
    }
    if (themeIcon) {
      themeIcon.innerHTML = dark
        ? '<path d="M20.5 15.5A8.5 8.5 0 0 1 8.5 3.5 8.5 8.5 0 1 0 20.5 15.5Z"/>'
        : '<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.93 4.93l1.42 1.42m11.3 11.3 1.42 1.42M2 12h2m16 0h2M4.93 19.07l1.42-1.42m11.3-11.3 1.42-1.42"/>';
    }
    try {
      localStorage.setItem('dazrevo-site-theme', dark ? 'dark' : 'light');
      localStorage.setItem('darb-site-theme', dark ? 'dark' : 'light');
    } catch {}
  }

  const stored = getStoredTheme();
  setTheme(stored ? stored === 'dark' : prefersDark);
  if (themeToggle) {
    themeToggle.addEventListener('click', () => setTheme(!root.classList.contains('dark')));
  }

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
    damascus: {
      name: 'دمشق',
      code: 'DAMASCUS / SY',
      description: 'نقطة انطلاق شبكة دازريفو ومسارات التوصيل الحضرية.'
    },
    aleppo: {
      name: 'حلب',
      code: 'ALEPPO / SY',
      description: 'متاجر محلية نشطة، توصيل مستقل، وعروض سائقين مباشرة.'
    },
    homs: {
      name: 'حمص',
      code: 'HOMS / SY',
      description: 'ربط الطلبات المحلية بمسارات المناديب بين الأحياء.'
    },
    hama: {
      name: 'حماة',
      code: 'HAMA / SY',
      description: 'توصيل مرن من نقطة إلى نقطة بحسب جاهزية الخدمة.'
    },
    latakia: {
      name: 'اللاذقية',
      code: 'LATAKIA / SY',
      description: 'امتداد شبكة دازريفو نحو مدن الساحل السوري.'
    }
  };

  const cityButtons = document.querySelectorAll('[data-city]');
  const cityName = document.getElementById('cityName');
  const cityCode = document.getElementById('cityCode');
  const cityDescription = document.getElementById('cityDescription');
  cityButtons.forEach((button) => {
    button.addEventListener('click', () => {
      const city = cities[button.dataset.city];
      if (!city) return;
      cityButtons.forEach((item) => item.setAttribute('aria-pressed', String(item === button)));
      if (cityName) cityName.textContent = city.name;
      if (cityCode) cityCode.textContent = city.code;
      if (cityDescription) cityDescription.textContent = city.description;
    });
  });

  const roles = {
    customer: {
      title: 'للعملاء: اطلب من المتاجر أو أرسل طرداً مستقلاً',
      body: 'تصفح المتاجر القريبة، أو حدد نقطتي استلام وتسليم لتصلك عروض أجرة السائقين، أو اكتب طلبك بالعربية لمساعد دازريفو الذكي.',
      points: [
        'الدفع نقداً عند الاستلام مع ملخص رسوم واضح قبل التأكيد',
        'تتبّع مباشر لموقع المندوب عبر الخريطة وإشعارات فورية لكل مرحلة',
        'صياغة ذكية للطلبات النصية وتحويلها إلى مسودة جاهزة'
      ]
    },
    driver: {
      title: 'للمناديب المستقلين: رحلات مرنة بدراجة أو سيارة',
      body: 'استقبل طلبات التوصيل في مدينتك، قدّم أجرة التوصيل المناسبة للمسافة، وتابع مهامك اليومية وأرباحك من واجهة سائق واحدة.',
      points: [
        'دعم الدراجة الهوائية، الدراجة النارية، والسيارة مع مراجعة الحساب',
        'تقديم عروض أسعار تنافسية وسحب أو تعديل العرض قبل القبول',
        'سجل أرباح ورحلات حقيقي ومباشر داخل لوحة السائق'
      ]
    },
    merchant: {
      title: 'للمتاجر المحلية: استقبل الطلبات ونظّم منتجاتك',
      body: 'أضف منتجات متجرك بأسعارها والمخزون المتوفر، استقبل طلبات العملاء خطوة بخطوة، واطلب المندوب فور جاهزية الطلب.',
      points: [
        'تحديث حالة التجهيز من القبول حتى الجاهزية للاستلام',
        'إدارة الأصناف والتصنيفات وحالة فتح المتجر بضغطة واحدة',
        'مساعد ذكي لمراجعة مبيعات اليوم وتلخيص الأولويات التشغيلية'
      ]
    }
  };

  const roleButtons = document.querySelectorAll('[data-role]');
  const roleTitle = document.getElementById('roleTitle');
  const roleBody = document.getElementById('roleBody');
  const rolePoints = document.getElementById('rolePoints');
  roleButtons.forEach((button) => {
    button.addEventListener('click', () => {
      const role = roles[button.dataset.role];
      if (!role) return;
      roleButtons.forEach((item) => item.setAttribute('aria-pressed', String(item === button)));
      if (roleTitle) roleTitle.textContent = role.title;
      if (roleBody) roleBody.textContent = role.body;
      if (rolePoints) {
        rolePoints.innerHTML = '';
        role.points.forEach((point) => {
          const item = document.createElement('div');
          item.textContent = point;
          rolePoints.appendChild(item);
        });
      }
    });
  });

  document.querySelectorAll('[data-faq-trigger]').forEach((trigger) => {
    trigger.addEventListener('click', () => {
      const expanded = trigger.getAttribute('aria-expanded') === 'true';
      const panelId = trigger.getAttribute('aria-controls');
      const panel = panelId ? document.getElementById(panelId) : null;
      trigger.setAttribute('aria-expanded', String(!expanded));
      if (panel) panel.hidden = expanded;
    });
  });

  const yearEl = document.getElementById('year');
  if (yearEl) {
    yearEl.textContent = String(new Date().getFullYear());
  }
  const downloadStatus = document.getElementById('downloadStatus');
  const downloadButton = document.getElementById('downloadBtn');
  if (downloadStatus || downloadButton) {
    fetch('./app-update.json', { cache: 'no-store', headers: { accept: 'application/json' } })
      .then((response) => {
        if (!response.ok) throw new Error('Release metadata unavailable');
        return response.json();
      })
      .then((release) => {
        const officialApk = 'https://github.com/anasgdxj/darb-delivery-platform/releases/download/latest/app-release.apk';
        if (release.apkUrl !== officialApk || !Number.isInteger(Number(release.versionCode)) || !/^1\\./.test(String(release.versionName || ''))) return;
        if (downloadButton) downloadButton.href = officialApk;
        if (downloadStatus) downloadStatus.textContent = 'الإصدار الرسمي ' + release.versionName + ' · تحديث DAZREVO';
      })
      .catch(() => {
        if (downloadStatus) downloadStatus.textContent = 'إصدار دازريفو الرسمي لأجهزة أندرويد';
      });
  }

})();